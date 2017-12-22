lib_mysqludf_redis
==================
提供一組 UDF 指令於 Mysql/MariaDB 中存取 Redis。

[English](README.md) | [繁體中文](README.hant.md) | [日本語](README.jp.md)


#### 目錄
* [簡介](#%E7%B0%A1%E4%BB%8B)
* [系統需求](#%E7%B3%BB%E7%B5%B1%E9%9C%80%E6%B1%82)
* [編譯與安裝外掛元件](#%E7%B7%A8%E8%AD%AF%E8%88%87%E5%AE%89%E8%A3%9D%E5%A4%96%E6%8E%9B%E5%85%83%E4%BB%B6)
* [註冊與註銷 UDF](#%E8%A8%BB%E5%86%8A%E8%88%87%E8%A8%BB%E9%8A%B7-udf)
* [使用方式](#%E4%BD%BF%E7%94%A8%E6%96%B9%E5%BC%8F)
* [待完成事項](#%E5%BE%85%E5%AE%8C%E6%88%90%E4%BA%8B%E9%A0%85)
* [授權條款](#%E6%8E%88%E6%AC%8A%E6%A2%9D%E6%AC%BE)
* [相關連結](#%E7%9B%B8%E9%97%9C%E9%80%A3%E7%B5%90)


簡介
----
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


[回目錄](#%E7%9B%AE%E9%8C%84)


系統需求
--------
* 架構： Linux 64-bit(x64)
* 編譯器： GCC 4.1.2+
* MariaDB 5.5+
* Redis 1.2+
* 相依套件：
    * MariaDB development library 5.5+
    * hiredis 0.13.3+
    * cJSON 1.6+

[回目錄](#%E7%9B%AE%E9%8C%84)


編譯與安裝外掛元件
------------------
安裝相依套件
> CentOS
> ```bash
> # 安裝工具
> $ yum install -y make wget gcc git
>
> # 安裝 mariadb development tool
> $ yum install -y mariadb-devel
> ```

> Debain
> ```bash
> # 安裝工具
> $ apt-get install -y make wget gcc git
>
> # 安裝 mariadb development tool
> $ apt-get install -y libmariadb-dev
> ```

要編譯外掛元件最簡單的方式就是直接執行 `make` 與 `make install`.
```
$ make
$ make install
```
> **附記**：如果使用的 MariaDB developement library 版本是 5.5，請使用 `make INCLUDE_PAGE=/usr/include/mysql` 來編譯。

下面是編譯時的自訂參數，可以被使用在 `make`：
* `HIREDIS_MODULE_VER`

  要提供給元件編譯的 [hiredis](https://github.com/redis/hiredis) 版本。如果該值為空或未指定，其預設值為 `0.13.3`。

* `CJSON_MODULE_VER`

  要提供給元件編譯的 [cJSON](https://github.com/DaveGamble/cJSON)  版本。如果該值為空或未指定，其預設值為 `1.6.0`。

* `INCLUDE_PATH`

  指定要被參考的 MariaDB/Mysql C 標頭檔。如果該值為空或未指定，其預設值為 `/usr/include/mysql/server`。

* `PLUGIN_PATH`

  指定 MariaDB/Mysql 的外掛元件檔案路徑。這個值可以在 MariaDB/Mysql 中，經由 `SHOW VARIABLES LIKE '%plugin_dir%';` 指令取得。如果該值為空或未指定，將會探測 `/usr/lib/mysql/plugin` 或 `/usr/lib64/mysql/plugin` 來決定路徑位置。

範例:
```bash
# 指定 MariaDB/Mysql 的外掛元件檔案路徑為 /opt/mysql/plugin
$ make PLUGIN_PATH=/opt/mysql/plugin
$ make install
```
[回目錄](#%E7%9B%AE%E9%8C%84)


註冊與註銷 UDF
--------------
要註冊 UDF，執行下列 sql 陳述式：
```sql
mysql>  CREATE FUNCTION `redis` RETURNS STRING SONAME 'lib_mysqludf_redis.so';
```
要註銷 UDF，執行下列 sql 陳述式：
```sql
mysql>  DROP FUNCTION `redis`;
```

[回目錄](#%E7%9B%AE%E9%8C%84)


使用方式
--------
### `redis`(*$connection_string*,  *$command*,  [*$args...*])

呼叫 Redis 命令，藉由指定 `$connection_string`, `$command` 以及命令參數。

* **$connection_string** - 表示要連線的 Redis 主機，使用 DSN 連線字串表示，其內容必須是下列形式之一：
  - **redis**://**@**_`<host>`_:_`<port>`_**/**_`<database>`_**/**
  - **redis**://**@**_`<host>`_**/**_`<database>`_**/**
* **$command**, **$args...** - Redis 命令與其參數。請詳見 Redis 官網 [https://redis.io/commands](https://redis.io/commands)。


函式回傳 JSON 字串指示操作成功或失敗。
> 若成功則輸出：
> ```json
> {
>    "out": "OK"
> }
> ```
> 若失敗則輸出：
> ```json
> {
>    "err": "Connection refused"
> }
> ```

下列範例說明函式的使用方式，並且與 `redis-cli` 命令工具作對照。
```sql
/*
  下面的陳述式如同：

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

[回目錄](#%E7%9B%AE%E9%8C%84)


待完成事項
----------
- [ ] 實作 Redis 連線驗證機制。
- [ ] 補充 redis DSN 字串建構函式。

[回目錄](#%E7%9B%AE%E9%8C%84)


授權條款
--------
請參閱 [LICENSE](LICENSE)。

[回目錄](#%E7%9B%AE%E9%8C%84)


相關連結
--------

[回目錄](#%E7%9B%AE%E9%8C%84)
