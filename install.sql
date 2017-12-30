USE `mysql`;

DROP FUNCTION IF EXISTS `redis`;
CREATE FUNCTION `redis` RETURNS STRING SONAME 'lib_mysqludf_redis.so';
