# TTNXが使用するミドルウェア（SQL ServerとRedis）のDocker環境を構築する（Docker Composeを使用）

## 目的
- Docker Composeを使用して、Windows 10 Pro/EntのDocker上で動作するlinux版のSQL Server 2019とRedis環境を構築する。

## 前提条件
- Docker for Windowsを導入していること。
  - 導入方法は以下を参照
  - 「[Windows 10 Pro/EntでDockerを動かす方法](https://github.com/yamadakou/Docker-Learn/tree/master/How-to-Docker-on-Windows10)」
    - https://github.com/yamadakou/Docker-Learn/tree/master/How-to-Docker-on-Windows10

## Docker Compose ファイル
- SQL Serverの設定情報
  - ポート番号：14330
  - dataファイルのパス： `{Docker Compose ファイルのパス}/mssql/data`
  - logファイルのパス： `{Docker Compose ファイルのパス}/mssql/log`
- Redisの設定情報。
  - ポート番号：63790
  - dataファイルのパス： `{Docker Compose ファイルのパス}/redis/data`

```yaml
version: '3'

services:
  mssql:
    image: mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04
    container_name: 'mssql2019-linux'
    environment:
      - MSSQL_SA_PASSWORD={任意のパスワード}
      - ACCEPT_EULA=Y
      - MSSQL_PID=Developer # default: Developer
      # - MSSQL_PID=Express
      # - MSSQL_PID=Standard
      # - MSSQL_PID=Enterprise
      # - MSSQL_PID=EnterpriseCore
    ports:
      - 14330:1433
    volumes: # Mounting a volume does not work on Docker for Mac
      - ./mssql/log:/var/opt/mssql/log
      - ./mssql/data:/var/opt/mssql/data

  redis:
    image: "redis:latest"
    container_name: 'redis-linux'
    ports:
      - "63790:6379"
    volumes:
      - "./redis/data:/data"
```

### 作成したComposeファイルでDocker Composeを起動
```
$ docker-compose up

# 稼働状況を確認
$ docker-compose ps
```
#### SQL Serverの確認
- SSMSなどDBクライアントツールで `localhost,14330` に接続することで操作可能
  - 接続方法などの参考
    - https://docs.microsoft.com/ja-jp/sql/linux/sql-server-linux-configure-docker?view=sql-server-linux-ver15#connect-and-query
  - SSMS（SQL Server Management Studio）
    - 以下からダウンロード可能
      - https://docs.microsoft.com/ja-jp/sql/ssms/download-sql-server-management-studio-ssms
  - ADS（Azure Data Studio）
    - macOSやLinuxにも対応したMS製DBツール
    - 以下からダウンロード可能
      - https://docs.microsoft.com/ja-jp/sql/azure-data-studio/what-is

#### Redisの確認
- Redisのクライアントツール（redis-cli）で `localhost:63790` に接続することで操作可能
  - 接続方法など参考
    - https://shinshin86.hateblo.jp/entry/2019/05/31/070000

### Docker Composeで起動した環境を停止
```
$ docker-compose stop

# 稼働状況を確認
$ docker-compose ps
```

### Docker Composeで停止した起動した環境を再開
```
$ docker-compose start

# 稼働状況を確認
$ docker-compose ps
```

### DBの復元（SSMSを使用）
- TTNXのDBバックアップファイルを、Docker Compose の起動ディレクトリ配下の `\mssql\data` フォルダ内に配置
  - 「timetrackernx.bak」のパス
      - Berkley\src\Installer\TimeTrackerNX\Resource\Install Program\Berkley\App_Data\sample
- SSMSで `localhost,14330` に接続する。
- 以下を参考に、SSMSでオブジェクトエクスプローラーの「データベース」を右クリックしたメニューから「データベースの復元」をクリックし、「データベースの復元ダイアログ」にて「timetrackernx.bak」を復元する。
  - https://docs.microsoft.com/ja-jp/sql/relational-databases/backup-restore/restore-a-database-to-a-new-location-sql-server
- 復元したDB「TimeTrackerNX」に `SELECT` などで動作を確認する。

### TTNXの設定ファイル「web.config」の変更点
- RedisとSQL Serverの接続情報を変更
```xml
<?xml version="1.0" encoding="utf-8"?>
<!--
  ASP.NET アプリケーションの構成方法の詳細については、
  http://go.microsoft.com/fwlink/?LinkId=169433 を参照してください
  -->
<configuration>
  ・・・
  <appSettings>
    ・・・
    <!-- Docker Compose ファイルで指定した接続情報に変更 --> 
    <add key="RedisConnection" value="localhost:63790" />
    ・・・
    <!-- Docker Compose ファイルで指定した接続情報に変更 --> 
	<connectionStrings>
    <add name="BerkleyDbContext" providerName="System.Data.SqlClient" connectionString="Data Source=localhost,14330;Initial Catalog=TimeTrackerNX;User ID=sa;Password={任意のパスワード};MultipleActiveResultSets=true;Connection Timeout=6000" />
  </connectionStrings>
    ・・・
```
