-- развернем ВМ postgres в GCE
gcloud beta compute --project=celtic-house-266612 instances create postgres --zone=us-central1-a --machine-type=e2-medium --subnet=default --network-tier=PREMIUM --maintenance-policy=MIGRATE --service-account=933982307116-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --image=ubuntu-2104-hirsute-v20210928 --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-ssd --boot-disk-device-name=postgres --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any
 
gcloud compute ssh postgres
 
-- установим 14 версию
-- https://www.postgresql.org/download/linux/ubuntu/

sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-14

-- посмотрим, что кластер стартовал
pg_lsclusters

-- если работаете с локалным развертыванием, удаленное подключение

psql -h ip_pg_host -U postgres -W -- Не подключиться ip_pg_host = 
ssh remote_user@ip_pg_host        -- если настроен доступ, то соединиться получится remote_user=   ip_pg_host= 

-- посмотрим файлы
sudo su postgres
cd /var/lib/postgresql/14/main
ls -l

sudo -u postgres psql
-- sudo su postgres
-- psql

Как посмотреть конфигурационные файлы?

show hba_file;
select * from pg_hba_file_rules;
show config_file;
show data_directory;

все параметры (как думаете сколько у нас параметров для настроек?:):
show all;
-- context
-- postmaster - перезапуск инстанса
-- sighup - во время работы
SELECT * FROM pg_settings \gx ;

ss -tlpn
netstat -a      -- менее информативно





-- open access
su mike   -- под локальным пользователем
show listen_addresses;
ALTER SYSTEM SET listen_addresses = '10.128.0.54'; -- создает в /var/lib/postgresql/14/main   postgresql.auto.conf с параметрами

-- uncomment listen_addresses = '*'
-- Alt + R | Alt+W
sudo nano /etc/postgresql/14/main/postgresql.conf 

-- host    all             all             0.0.0.0/0               md5/scram-sha-256
sudo nano /etc/postgresql/14/main/pg_hba.conf

-- change password
# ALTER USER postgres PASSWORD 'otus$123';
# \password -- либо так

-- Далее перегружаем кластер
sudo pg_ctlcluster 14 main restart -- будет ошибка почему?

-- try access
psql -h ip_pg_host -U postgres -W 


Расширенный вывод информации - вертикальный вывод колонок
SELECT * FROM pg_stat_activity;
\x

SELECT * FROM pg_stat_activity \gx

select * from pg_stat_activity \g | less


\set ECHO_HIDDEN on
\l
\set ECHO_HIDDEN off


sudo su postgres
cat $HOME/.psql_history
-- более подробно в файле 06_User_logging.sql

sudo su postgres 
ps -xf 			-- процессы с xf расширенный вид

--Форматирование префикса командной строки
sudo -u postgres psql
\set PROMPT1 '%M:%> %n@%/%R%#%x '
Вернуть обратно
set PROMPT1 ''


Поподробнее из psql:
# SELECT pg_backend_pid();
# SELECT inet_client_addr();
# SELECT inet_client_port();
# SELECT inet_server_addr();
# SELECT inet_server_port();
# SELECT datid, datname, pid, usename, application_name, client_addr, backend_xid FROM pg_stat_activity;

-- табличное пространство практика
sudo mkdir /home/postgres
sudo chown postgres /home/postgres
sudo su postgres
cd /home/postgres
mkdir tmptblspc

CREATE TABLESPACE ts location '/home/postgres/tmptblspc';
\db
CREATE DATABASE app TABLESPACE ts;
\c app
\l+ -- посмотреть дефолтный tablespace
CREATE table test (i int);
CREATE table test2 (i int) TABLESPACE pg_default;
SELECT tablename, tablespace FROM pg_tables WHERE schemaname = 'public';
ALTER table test set TABLESPACE pg_default;
SELECT oid, spcname FROM pg_tablespace; -- oid унимальный номер, по кторому можем найти файлы
SELECT oid, datname,dattablespace FROM pg_database;

-- всегда можем посмотреть, где лежит таблица
SELECT pg_relation_filepath('test2');

-- Узнать размер, занимаемый базой данных и объектами в ней, можно с помощью ряда функций.
SELECT pg_database_size('app');

-- Для упрощения восприятия можно вывести число в отформатированном виде:
SELECT pg_size_pretty(pg_database_size('app'));

-- Полный размер таблицы (вместе со всеми индексами):
SELECT pg_size_pretty(pg_total_relation_size('test2'));

-- И отдельно размер таблицы...
SELECT pg_size_pretty(pg_table_size('test2'));

-- ...и индексов:
SELECT pg_size_pretty(pg_indexes_size('test2'));

-- При желании можно узнать и размер отдельных слоев таблицы, например:
SELECT pg_size_pretty(pg_relation_size('test2','vm'));

-- Размер табличного пространства показывает другая функция:
SELECT pg_size_pretty(pg_tablespace_size('ts'));

-- посмотрим на файловую систему
-- sudo apt install mc
-- cd /var/lib/postgresql
\l+
SELECT d.datname as "Name",
       r.rolname as "Owner",
       pg_catalog.pg_encoding_to_char(d.encoding) as "Encoding",
       pg_catalog.shobj_description(d.oid, 'pg_database') as "Description",
       t.spcname as "tablespace"
FROM pg_catalog.pg_database d
  JOIN pg_catalog.pg_roles r ON d.datdba = r.oid
  JOIN pg_catalog.pg_tablespace t on d.datTABLEspace = t.oid
ORDER BY 1;


-- зададим переменную
SELECT oid as tsoid FROM pg_tablespace WHERE spcname='ts' \gset 
SELECT datname FROM pg_database WHERE oid in (SELECT pg_tablespace_databases(:tsoid));


--с дефолтным неймспейсом не все так просто
SELECT count(*) FROM pg_class WHERE reltablespace = 0;


\! pwd

\i /var/lib/postgresql/s.sql


-- удалим наш проект
gcloud compute instances delete postgres
