lib_mysqludf_redis
==================
Mysql/MariaDBのRedisにアクセスするための一連のUDF命令を提供する。

[English](README.md) | [繁體中文](README.hant.md) | [日本語](README.jp.md)


#### ディレクトリ
* [はじめに](#%E3%81%AF%E3%81%98%E3%82%81%E3%81%AB)
* [システム要件](#%E3%82%B7%E3%82%B9%E3%83%86%E3%83%A0%E8%A6%81%E4%BB%B6)
* [プラグインコンポーネントのコンパイルとインストール](#%E3%83%97%E3%83%A9%E3%82%B0%E3%82%A4%E3%83%B3%E3%82%B3%E3%83%B3%E3%83%9D%E3%83%BC%E3%83%8D%E3%83%B3%E3%83%88%E3%81%AE%E3%82%B3%E3%83%B3%E3%83%91%E3%82%A4%E3%83%AB%E3%81%A8%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB)
* [UDF 登録とキャンセル](#udf-%E7%99%BB%E9%8C%B2%E3%81%A8%E3%82%AD%E3%83%A3%E3%83%B3%E3%82%BB%E3%83%AB)
* [使用方式](#%E4%BD%BF%E7%94%A8%E6%96%B9%E5%BC%8F)
* [完成するために](#%E5%AE%8C%E6%88%90%E3%81%99%E3%82%8B%E3%81%9F%E3%82%81%E3%81%AB)
* [ライセンス条項](#%E3%83%A9%E3%82%A4%E3%82%BB%E3%83%B3%E3%82%B9%E6%9D%A1%E9%A0%85)
* [関連リンク](#%E9%96%A2%E9%80%A3%E3%83%AA%E3%83%B3%E3%82%AF)


はじめに
--------
![Alt text](https://g.gravizo.com/source/figure01?https%3A%2F%2Fraw.githubusercontent.com%2FIdeonella-sakaiensis%2Flib_mysqludf_redis%2Fmaster%2FREADME.md?3)

[ディレクトリへ](#%E3%83%87%E3%82%A3%E3%83%AC%E3%82%AF%E3%83%88%E3%83%AA)


システム要件
------------
* オペレーティングシステム： Linux 64-bit(x64)
* コンパイラ： GCC 4.1.2+
* MariaDB 5.5+
* Redis 1.2+
* 依存キット：
    * MariaDB development library 5.5+
    * hiredis 0.13.3+
    * cJSON 1.6+

[ディレクトリへ](#%E3%83%87%E3%82%A3%E3%83%AC%E3%82%AF%E3%83%88%E3%83%AA)


プラグインコンポーネントのコンパイルとインストール
--------------------------------------------------
依存関係キットをインストールする
> CentOS
> ```bash
> # ツールをインストールする
> $ yum install -y make wget gcc git
>
> # mariadb development tool をインストールする
> $ yum install -y mariadb-devel
> ```

> Debain
> ```bash
> # ツールをインストールする
> $ apt-get install -y make wget gcc git
>
> # mariadb development tool をインストールする
> $ apt-get install -y libmariadb-dev
> ```

プラグインコンポーネントをコンパイルする最も簡単な方法は、プラグインコンポーネント `make` と `make install` を直接実行することです。
```
$ make
$ make install
```
> **注**：もし開発ライブラリバージは MariaDB developement library 5.5 を使用している場合、 `make INCLUDE_PAGE=/usr/include/mysql` をコンパイルしてください。

以下は、コンパイル時のカスタムパラメータであり、 `make` で使用できます:
* `HIREDIS_MODULE_VER`

  コンポーネントのコンパイルのために提供される [hiredis](https://github.com/redis/hiredis) バージョン。値が空であるか、または指定されていない場合、デフォルトは `0.13.3`です。

* `CJSON_MODULE_VER`

  コンポーネントのコンパイルのために提供される [cJSON](https://github.com/DaveGamble/cJSON)  バージョン。値が空であるか、または指定されていない場合、デフォルトは `1.6.0`です。

* `INCLUDE_PATH`

  参照するMariaDB / Mysql Cヘッダを指定します。 値が空白または指定されていない場合、デフォルトは `/usr/include/mysql/server`です。

* `PLUGIN_PATH`

  MariaDB/Mysql プラグインファイルのパスを指定する。この値はMariaDB/Mysqlのなかに，`SHOW VARIABLES LIKE '%plugin_dir%';`で取得。値が空であるか、または指定されていない場合、 `/usr/lib/mysql/plugin` または `/usr/lib64/mysql/plugin` を調べて、パスの場所を調べます。

例:
```bash
# MariaDB/Mysql を指定するプラグインのファイルパスは /opt/mysql/plugin です。 
$ make PLUGIN_PATH=/opt/mysql/plugin
$ make install
```
[ディレクトリへ](#%E3%83%87%E3%82%A3%E3%83%AC%E3%82%AF%E3%83%88%E3%83%AA)


UDF 登録とキャンセル
--------------------
UDFを登録するには、次のSQL文を実行します：
```sql
mysql>  CREATE FUNCTION `redis` RETURNS STRING SONAME 'lib_mysqludf_redis.so';
```
UDFをキャンセルするには、次のSQL文を実行します：
```sql
mysql>  DROP FUNCTION `redis`;
```

[ディレクトリへ](#%E3%83%87%E3%82%A3%E3%83%AC%E3%82%AF%E3%83%88%E3%83%AA)


使用方式
--------
### `redis`(*$connection_string*,  *$command*,  [*$args...*])

Redisコマンドを使用するため，`$ connection_string`、` $ command`とコマンドパラメータを指定すること。

* **$connection_string** - 接続するRedisホストを示します，DSN接続文字列表現を使用する，その内容は次のいずれかでなければなりません：
  - **redis**://**@**_`<host>`_:_`<port>`_**/**_`<database>`_**/**
  - **redis**://**@**_`<host>`_**/**_`<database>`_**/**
* **$command**, **$args...** - Redisコマンドとそのパラメータ。Redis公式サイトをご覧ください [https://redis.io/commands](https://redis.io/commands)。


この関数は、操作が成功したか失敗したかを示すJSON文字列を返します。
> 成功した場合：
> ```json
> {
>    "out": "OK"
> }
> ```
> 失敗した場合：
> ```json
> {
>    "err": "Connection refused"
> }
> ```

次の例では、関数の使用方法と `redis-cli`コマンドツールとの比較を示します。
```sql
/*
  次のステートメントは同じです：

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

[ディレクトリへ](#%E3%83%87%E3%82%A3%E3%83%AC%E3%82%AF%E3%83%88%E3%83%AA)


完成するために
--------------
- [ ] Redis 接続検証機構の実現。
- [ ] redis DSN文字列コンストラクタを補足する。

[ディレクトリへ](#%E3%83%87%E3%82%A3%E3%83%AC%E3%82%AF%E3%83%88%E3%83%AA)


ライセンス条項
--------------
[LICENSE](LICENSE) を参照してください。

[ディレクトリへ](#%E3%83%87%E3%82%A3%E3%83%AC%E3%82%AF%E3%83%88%E3%83%AA)


関連リンク
----------

[ディレクトリへ](#%E3%83%87%E3%82%A3%E3%83%AC%E3%82%AF%E3%83%88%E3%83%AA)
