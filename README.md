lib_mysqludf_redis
==================
Provides UDF commands to access Redis from Mysql/MariaDB.

[English](README.md) | [繁體中文](README.hant.md) | [日本語](README.jp.md)


#### Table of Contents
* [Synopsis](#synopsis)
* [System Requirements](#system-requirements)
* [Compilation and Install Plugin Library](#compilation-and-install-plugin-library)
* [Register and Unregister UDF](#register-and-unregister-udf)
* [Usage](#usage)
* [TODO](#todo)
* [Copyright and License](#copyright-and-license)
* [See Also](#see-also)


Synopsis
--------
![Alt text](https://g.gravizo.com/source/figure01?https%3A%2F%2Fraw.githubusercontent.com%2FIdeonella-sakaiensis%2Flib_mysqludf_redis%2Fmaster%2FREADME.md?1)
<details>
<summary></summary>
figure01
  digraph G {
    
    rankdir = "LR";
    size ="8,8";

    edge [
        fontname = "Consolas"
        fontsize = 10
    ];
    MariaDB [
        label = "MariaDB\n(presistence)"
        shape = "box"
    ];
    Redis [
        label = "Redis\n(cached)"
        shape = "box"
    ];

    edge [
        fontcolor = "blue"
        color = "blue"
    ];
    writer;
    writer:e -> MariaDB [
        label="INSERT\nUPDATE\nDELETE"
    ];
    MariaDB -> Redis [
        label = "SET"
    ];

    edge [
        fontcolor = "red"
        color = "red"
    ];
    reader;
    reader:e -> MariaDB [
        label="SELECT"
    ];
    MariaDB -> Redis [
        label = "GET"
    ];
  }
figure01
</details>


[Back to TOC](#table-of-contents)


System Requirements
-------------------
linux 64bit, MariaDB 5.5+, Redis 1.2+

[Back to TOC](#table-of-contents)


Compilation and Install Plugin Library
--------------------------------------
To compile the plugin libraray just simply type `make` and `make install`.
```
$ make
$ make install
```
The compilation arguments can be use in `make`:
* `HIREDIS_MODULE_VER`

  The [hiredis](https://github.com/redis/hiredis) version to be compiled. If it is not specified, the default value is `0.13.3`.

* `CJSON_MODULE_VER`

  The [cJSON](https://github.com/DaveGamble/cJSON) version to be compiled. If it is not specified, the default value is `1.6.0`

* `INCLUDE_PATH`

  The MariaDB or Mysql c header path. If it is not specified, the default value is `/usr/include/mysql/server`.

* `PLUGIN_PATH`

  The MariaDB or Mysql plugin path. The value can be obtain via runing the sql statement `SHOW VARIABLES LIKE '%plugin_dir%';` in MariaDB/Mysql server. If it is not specified, will detect the plugin path with `/usr/lib/mysql/plugin` or `/usr/lib64/mysql/plugin`.

example:
```bash
# specify the plugin install path with /opt/mysql/plugin
$ make PLUGIN_PATH=/opt/mysql/plugin
$ make install
```
[Back to TOC](#table-of-contents)


Register and Unregister UDF
---------------------------
To register UDF, running the following sql statement:
```sql
mysql>  CREATE FUNCTION `redis` RETURNS STRING SONAME 'lib_mysqludf_redis.so';
```
To unregister UDF, running the following sql statement:
```sql
mysql>  DROP FUNCTION `redis`;
```

[Back to TOC](#table-of-contents)


Usage
-----
### `redis`(*$connection_string*,  *$command*,  [*$args...*])

Call a Redis command by specified `$connection_string`, `$command`, and individual arguments.

* **$connection_string** - a DSN connection string , must be one of following type:
  - **redis**://**@**_`<host>`_:_`<port>`_**/**_`<database>`_**/**
  - **redis**://**@**_`<host>`_**/**_`<database>`_**/**
* **$command**, **$args...** - the Redis command and arguments. See also [https://redis.io/commands](https://redis.io/commands) for further details.


The function Return JSON string indicating success or failure of the operation.
> the success output:
> ```json
> {
>    "out": "OK"
> }
> ```
> the failure output:
> ```json
> {
>    "err": "Connection refused"
> }
> ```

The following examples illustrate how to use the function contrast with `redis-cli` utility.
```sql
/*
  the following statement likes:

    $ redis-cli -h 127.0.0.1 -n 8 PING
    PONG
*/
mysql>  SELECT `redis`('redis://@127.0.0.1/8/', 'PING')\G
*************************** 1. row ***************************
`redis`('redis://@127.0.0.1/8/', 'PING'): {
        "out":  "PONG"
}
1 row in set (0.00 sec)



/*
    $ redis-cli -h 127.0.0.1 -p 80 -n 8 PING
    Could not connect to Redis at 127.0.0.1:80: Connection refused
*/
mysql>  SELECT `redis`('redis://@127.0.0.1:80/8/', 'PING')\G
*************************** 1. row ***************************
`redis`('redis://@127.0.0.1:80/8/', 'PING'): {
        "err":  "Connection refused"
}
1 row in set (0.00 sec)



/*
    $ redis-cli -h 127.0.0.1 -n 8 HMSET myhash field1 Hello field2 World
    OK
*/
mysql>  SELECT `redis`('redis://@127.0.0.1/8/', 'HMSET', 'myhash', 'field1', 'Hello', 'field2', 'World')\G
*************************** 1. row ***************************
`redis`('redis://@127.0.0.1/8/', 'HMSET', 'myhash', 'field1', 'Hello', 'field2', 'World'): {
        "out":  "OK"
}
1 row in set (0.00 sec)



/*
    $ redis-cli -h 127.0.0.1 -n 8 HGET myhash field1
    "Hello"
*/
mysql>  SELECT `redis`('redis://@127.0.0.1/8/', 'HGET', 'myhash', 'field1')\G
*************************** 1. row ***************************
`redis`('redis://@127.0.0.1/8/', 'HGET', 'myhash', 'field1'): {
        "out":  "Hello"
}
1 row in set (0.00 sec)



-- redis-cli -h 127.0.0.1 -n 0 SET foo bar
mysql>  SELECT `redis`('redis://@127.0.0.1/0/', 'SET', 'foo', 'bar')

-- redis-cli -h 127.0.0.1 -n 0 SCAN 0 MATCH prefix*
mysql>  SELECT `redis`('redis://@127.0.0.1/0/', 'SCAN', '0', 'MATCH', 'prefix*')
```

[Back to TOC](#table-of-contents)


TODO
----
- [ ] implement Redis Authentication
- [ ] add redis DSN string builder

[Back to TOC](#table-of-contents)


Copyright and License
-------------------
See [LICENSE](LICENSE) for further details.

[Back to TOC](#table-of-contents)


See Also
---------

[Back to TOC](#table-of-contents)
