# Challenge 3: Offline migration

[< Previous Challenge](./02-size-analysis.md) - **[Home](./README.md)** - [Next Challenge >](./04-offline-cutover-validation.md)

## Coach Tips

The attendees will not be able to connect to Azure DB for PostgreSQL/MySQL from within the container. In order to connect, they will need to add the public IP address to the DB firewall. This is the ip address the container is using for egress to connect to Azure DB. One way to find it is to do this:
```bash

apt update
apt install curl
curl ifconfig.me

```
Please note there are many 3rd party tools similar to SQL wokbench and dbeaver . There is also mydumper and myloader ( https://centminmod.com/mydumper.html ) to use for MySQL

Another way is to login to the database container, and then try to launch a connection to the Azure DB for MySQL or Postgres. It will fail wuth a firewall error that will reveal the address. In the example below, pgtarget is the Postgres server name, pgtarget2 is the mysql servername and both has serveradmin as the admin user created on Azure.

```bash

kubectl -n postgresql exec deploy/postgres -it -- bash
root@postgres-64786b846-khk28:/#  psql -h pgtarget.postgres.database.azure.com -p 5432 -U serveradmin@pgtarget -d postgres

```

Before migrating the data, they need to create an empty database and create the application user. Connect to the database container first and from there connect to Azure DB.
Alternately connect to Azure DB using  Azure Data studio or Pgadmin tool

```bash

kubectl -n postgresql exec deploy/postgres -it -- bash
psql -h pgtarget.postgres.database.azure.com -p 5432 -U serveradmin@pgtarget -d postgres
create database wth ;

```

```bash

kubectl -n mysql exec deploy/mysql -it -- bash
mysql -h mytarget2.mysql.database.azure.com -P 3306 -u serveradmin@mytarget2 -p
create database wth ;

```

Create the pizzeria application database user and the database wth

```sql

CREATE ROLE CONTOSOAPP WITH LOGIN NOSUPERUSER INHERIT CREATEDB CREATEROLE NOREPLICATION PASSWORD 'OCPHack8';
create database wth ;

```
* Postgres command to do offline export to exportdir directory and import offline to Azure Postgres. First bash into the postgres container and then two commands

```bash

 pg_dump -C -Fd  wth -j 4 -f exportdir -U contosoapp
 pg_restore -h pgtarget.postgres.database.azure.com -p 5432 -U contosoapp@pgtarget -d wth -Fd exportdir

```

* For MySQL the MySQL database script file may contain references to @@SESSION and @@GLOBAL that will need to be removed prior to importing.

Privileges required to run Mysql export on the source database - connect as root

```sql
grant ALL PRIVILEGES ON wth.* TO contosoapp ;
grant process, select on *.*  to contosoapp ;

-- check privileges already granted

show grants for contosoapp ;

```
Grants for contosoapp should report


GRANT SELECT, PROCESS ON *.* TO 'contosoapp'@'%'

GRANT ALL PRIVILEGES ON `wth`.* TO 'contosoapp'@'%'

It is possible to use mysql workbench tool to run the export with proper settings.  The mysql workbench version ( 8.0.23 as of Jan 2021 ) being different from mysql version
5.7 is not a factor for this challenge. The mysql export runs series of exports for each table like this. If you do not want to see the warnings about --set-gtid-purged, use
the flag  --set-gtid-purged

Running: mysqldump.exe --defaults-file="C:\Users\susengu\AppData\Local\Temp\tmp_akgbble.cnf"  --host=<container ip> --port=3306 --default-character-set=utf8 --user=contosoapp --protocol=tcp --no-data --skip-triggers --skip-column-statistics "wth" "bakestyle" --set-gtid-purged=off

 Alternately from command prompt

 ```bash

mysqldump -h <container ip> -u contosoapp -p --set-gtid-purged=off --skip-column-statistics --databases wth >dump_data.sql

 ```

 * Mysql command to do offline import from import directory. When run from MySQL workbench

 mysql  --protocol=tcp --host=mytarget2.mysql.database.azure.com --user=contosoapp@mytarget2 --port=3306 --default-character-set=utf8 --comments --database=wth < "C:\\Documents\\OneDrive - Microsoft\\Dump20210126 (2)\\wth_users.sql"

 Or from shell prompt

 ```bash

  mysql  -h mytarget2.mysql.database.azure.com -P 3306 -u contosoapp@mytarget2 -pOCPHack8  <dump_data.sql

 ```

 From command line shell script to load all files one at a time

 ```bash

 for file in `ls wth_*sql`; do mysql -h mytarget2.mysql.database.azure.com -P 3306 -u contosoapp@mytarget2 -pOCPHack8 wth <$file; done

 ```

