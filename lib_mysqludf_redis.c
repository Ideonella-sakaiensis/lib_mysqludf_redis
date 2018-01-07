#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <stdbool.h>

#include <mysql.h>

#include <cjson/cJSON.h>
#include <hiredis/hiredis.h>

#define REDIS_HOST "127.0.0.1"
#define REDIS_PORT 6379
#define ushort     unsigned short
#define uint       unsigned int
#define TRUE       1
#define FALSE      0

typedef struct st_foreign_server {
	bool parsed;

	char *connection_string;
	char *scheme;
	char *hostname;
	char *username;
	char *password;
	char *database;
	char *table_name;
	ushort port;

	uint table_name_length, connect_string_length;
} FOREIGN_SERVER;


static void
freeServer(FOREIGN_SERVER *server) {
	if (server != NULL) {
		if (server->connection_string != NULL) {
			free(server->connection_string);
		}
		free(server);
	}
}


static int
parse_url(FOREIGN_SERVER *share) {
	share->port= 0;

	/*
	   No :// or @ in connection string. Must be a straight connection name of
	   either "servername" or "servername/tablename"
	*/
	if ( (!strstr(share->connection_string, "://") &&
	     (!strchr(share->connection_string, '@'))) ) {
		goto error;
	} else {
		share->parsed= TRUE;
		// Add a null for later termination of table name
		share->connection_string[share->connect_string_length]= 0;
		share->scheme= share->connection_string;

		/*
		   Remove addition of null terminator and store length
		   for each string  in share
		*/
		if (!(share->username= (char *)strstr(share->scheme, "://")))
			goto error;
		share->scheme[share->username - share->scheme]= '\0';

		if (strcmp(share->scheme, "redis"))
			goto error;

		share->username+= 3;

		if (!(share->hostname= (char *)strchr(share->username, '@')))
			goto error;
		*share->hostname++= '\0';

		if ((share->password= (char *)strchr(share->username, ':'))) {
			*share->password++= '\0';

			/* make sure there isn't an extra / or @ */
			if ((strchr(share->password, '/') || strchr(share->hostname, '@')))
				goto error;
			/*
			   Found that if the string is:
			   user:@hostname:port/db/table
			   Then password is a null string, so set to NULL
			*/
			if (share->password[0] == '\0')
				share->password= NULL;
		}

		/* make sure there isn't an extra / or @ */
		if ((strchr(share->username, '/')) || (strchr(share->hostname, '@')))
			goto error;

		if (!(share->database= (char *)strchr(share->hostname, '/')))
			goto error;
		*share->database++= '\0';

		char* port = NULL;
		if ((port= (char *)strchr(share->hostname, ':'))) {
			*port++= '\0';
			share->port= atoi(port);
		}

		if (!(share->table_name= (char *)strchr(share->database, '/')))
			goto error;
		*share->table_name++= '\0';

		share->table_name_length= strlen(share->table_name);

		/* make sure there's not an extra / */
		if ((strchr(share->table_name, '/')))
			goto error;

		if (share->hostname[0] == '\0')
			share->hostname= NULL;

	}
	if (!share->port) {
		share->port= REDIS_PORT;
	}
	if (!share->hostname) {
		share->hostname= REDIS_HOST;
	}

	return 0;

error:
	return -1;
}


static cJSON*
getJsonReply(redisReply *reply, cJSON *json) {
	cJSON *array = NULL;
	if (json == NULL) {
		json = cJSON_CreateObject();
	}

	switch (reply->type) {
	case REDIS_REPLY_STRING:
		cJSON_AddStringToObject(json, "out", reply->str);
		break;

	case REDIS_REPLY_ARRAY:
		array = cJSON_CreateArray();
		cJSON_AddItemToObject(json, "out", array);
		unsigned int i;
		for (i = 0; i < reply->elements; i++) {
			getJsonReply(reply->element[i], array);
		}
		break;

	case REDIS_REPLY_INTEGER:
		cJSON_AddNumberToObject(json, "out", reply->integer);
		break;

	case REDIS_REPLY_NIL:
		cJSON_AddNullToObject(json, "out");
		break;

	case REDIS_REPLY_STATUS:
		cJSON_AddStringToObject(json, "out", reply->str);
		break;

	case REDIS_REPLY_ERROR:
		cJSON_AddStringToObject(json, "err", reply->str);
		break;
	}

	return json;
}


static char*
getResultFromRedisReply(redisReply *reply) {
	char *result;
	cJSON *jsonReply = getJsonReply(reply, NULL);
	{
		result = cJSON_Print(jsonReply);
	}
	cJSON_Delete(jsonReply);
	return result;
}

static char*
getErrorResult(char *message) {
	char *result;
	cJSON *json = cJSON_CreateObject();
	cJSON_AddStringToObject(json, "err", message);
	{
		result = cJSON_Print(json);
	}
	cJSON_Delete(json);
	return result;
}


/**********************************
  redis
  
  redis(server, command, args...);
  
  RETURN json
*/

my_bool
redis_init(UDF_INIT *initid,
           UDF_ARGS *args,
           char     *message)
{
	if (args->arg_count < 2) {
		strcpy(message, "requires at last two arguments.");
		return EXIT_FAILURE;
	}
	if (args->args[0] == NULL || args->args[1] == NULL) {
		initid->ptr = NULL;
	} else {
		if (args->arg_type[0] != STRING_RESULT ||
		    args->arg_type[1] != STRING_RESULT) {
			strcpy(message, "invalid arguments.");
			return EXIT_FAILURE;
		}
	}
	
	initid->maybe_null = 1;
	return EXIT_SUCCESS;
}


void
redis_deinit(UDF_INIT *initid)
{
	if (initid->ptr != NULL) {
		free(initid->ptr);
	}
}


char*
redis(UDF_INIT      *initid,
      UDF_ARGS      *args,
      char          *result,
      unsigned long *length,
      char          *is_null,
      char          *error)
{
	// check arguments
	if (args->args[0] == NULL || args->args[1] == NULL) {
		*is_null = 1;
		return NULL;
	} else {
		if (args->arg_type[0] != STRING_RESULT ||
		    args->arg_type[1] != STRING_RESULT) {
			// invalid arguments
			*error   = 1;
			return NULL;
		}
	}

	FOREIGN_SERVER *server = NULL;
	redisContext   *ctx    = NULL;
	redisReply     *reply  = NULL;

	server = malloc(sizeof(FOREIGN_SERVER));
	if (server == NULL) {
		// out of memory
		*error = 1;
		goto final;
	}

	// import argument server 
	server->connection_string = strdup(args->args[0]);
	server->connect_string_length = (unsigned short)args->lengths[0];


	if (parse_url(server) != 0) {
		result = getErrorResult("invalid connection string");
		goto final;
	}

	// connection to redis
	ctx = redisConnect(server->hostname, server->port);
	if (ctx != NULL && ctx->err) {
		result = getErrorResult(ctx->errstr);
		goto final;
	}
	// send AUTH command to redis
	if (server->password != NULL) {
		reply = redisCommand(ctx, "AUTH %s", server->password);
		if (reply != NULL) {
			if (reply->type == REDIS_REPLY_ERROR) {
				result = getResultFromRedisReply(reply);
				goto final;
			}
			freeReplyObject(reply);
		}
	}
	// send SELECT dbnum to redis
	if (server->database != 0) {
		reply = redisCommand(ctx, "SELECT %s", server->database);
		if (reply != NULL) {
			if (reply->type == REDIS_REPLY_ERROR) {
				result = getResultFromRedisReply(reply);
				goto final;
			}
			freeReplyObject(reply);
		}
	}

	int  argc   = args->arg_count - 1;
	char **argv = ++args->args;
	reply = redisCommandArgv(ctx, argc, (const char**)argv, NULL);
	result = getResultFromRedisReply(reply);

final:
	if (reply  != NULL) freeReplyObject(reply);
	if (ctx    != NULL) redisFree(ctx);
	if (server != NULL) freeServer(server);

	if (result != NULL) {
		*length = strlen(result);
		initid->max_length = *length;
		initid->ptr = result;
	} else {
		*is_null = 1;
	}
	return result;
}
