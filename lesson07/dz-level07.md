### Домашнее задание. Работа с базами данных, пользователями и правами

**Цель:
создание новой базы данных, схемы и таблицы
создание роли для чтения данных из созданной схемы созданной базы данных
создание роли для чтения и записи из созданной схемы созданной базы данных** 

**Описание/Пошаговая инструкция выполнения домашнего задания:**

> 1 создайте новый кластер PostgresSQL 14
```
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql-14
```

> 2 зайдите в созданный кластер под пользователем postgres
> 3 создайте новую базу данных testdb
> 4 зайдите в созданную базу данных под пользователем postgres
> 5 создайте новую схему testnm
> 6 создайте новую таблицу t1 с одной колонкой c1 типа integer
> 7 вставьте строку со значением c1=1

```
postgres=# create database testdb;
postgres=# \c testdb
testdb=# create schema testnm;
testdb=# create table t1 (c1 int);
testdb=# insert into t1 (c1) values (1);
```

> 8 создайте новую роль readonly
> 9 дайте новой роли право на подключение к базе данных testdb
> 10 дайте новой роли право на использование схемы testnm
> 11 дайте новой роли право на select для всех таблиц схемы testnm
> 12 создайте пользователя testread с паролем test123
> 13 дайте роль readonly пользователю testread

```
testdb=# create role readonly;

-- права на коннект
grant connect on database testdb to readonly;

-- права на использование схемы testnm
grant usage on schema testnm to readonly;

-- права на селект всех таблиц схемы testnm
grant select on all tables in schema testnm to readonly;

-- создание юзера
testdb=# create user testread with password 'test123' ;

-- добавляем юзера в группу readonly
testdb=# grant readonly to testread;
```

> 14 зайдите под пользователем testread в базу данных testdb
> 15 сделайте select * from t1;
> 16 получилось? (могло если вы делали сами не по шпаргалке и не упустили один существенный момент про который позже)
> 17 напишите что именно произошло в тексте домашнего задания
> 18 у вас есть идеи почему? ведь права то дали?
> 19 посмотрите на список таблиц
> 20 подсказка в шпаргалке под пунктом 20
> 21 а почему так получилось с таблицей (если делали сами и без шпаргалки то может у вас все нормально)
```
sudo -u postgres psql -U testread

testdb=> select * from t1;
ERROR:  permission denied for table t1


testdb=> \dt
       List of relations
 Schema | Name | Type  | Owner
--------+------+-------+---------
 public | t1   | table | postgres


--  прав на селект нет, т.к. таблица была создана в схеме public, а права выдавались на схему testnm

sudo -u postgres psql -U postgres
testdb=# select * from pg_tables where tablename not like 'pg%' and tablename not like 'sql%';
 schemaname | tablename | tableowner | tablespace | hasindexes | hasrules | hastriggers | rowsecurity
------------+-----------+------------+------------+------------+----------+-------------+-------------
 public     | t1        | postgres   |            | f          | f        | f           | f


testdb=# set search_path=public, testnm;
testdb=# \dp+
                             Access privileges
 Schema | Name | Type  |  Access privileges         | Column privileges | Policies 
--------+------+-------+----------------------------+-------------------+----------
 testnm | t1   | table | postgres=arwdDxt/postgres+ |                   | 
        |      |       | readonly=r/postgres        |                   | 


```



> 22 вернитесь в базу данных testdb под пользователем postgres
> 23 удалите таблицу t1
> 24 создайте ее заново но уже с явным указанием имени схемы testnm
> 25 вставьте строку со значением c1=1
```
sudo -u postgres psql -U postgres
testdb=# drop table t1;
testdb=# create table testnm.t1 (c1 int);
testdb=# insert into testnm.t1(c1) values (1);
```

> 26 зайдите под пользователем testread в базу данных testdb
> 27 сделайте select * from testnm.t1;
> 28 получилось?
> 29 есть идеи почему? если нет - смотрите шпаргалку

```
-- доступа не будет, т.к таблица была создана после grant select on all tables in schema testnm to readonly
sudo -u postgres psql -U testread
testdb=> select * from testnm.t1;
ERROR:  permission denied for table t1;
```

> 30 как сделать так чтобы такое больше не повторялось? если нет идей - смотрите шпаргалку
> 31 сделайте select * from testnm.t1;
> 32 получилось?
> 33 есть идеи почему? если нет - смотрите шпаргалку
> 31 сделайте select * from testnm.t1;
> 32 получилось?
> 33 ура!

```
---выдаём явные права

testdb=# grant select on testnm.t1  to readonly;

testdb=# \dp+ testnm.t1
                             Access privileges
 Schema | Name | Type  |  Access privileges         | Column privileges | Policies
--------+------+-------+----------------------------+-------------------+----------
 testnm | t1   | table | postgres=arwdDxt/postgres+ |                   |
        |      |       | readonly=r/postgres        |                   |


-- теперь доступ есть
testdb=> select * from testnm.t1;
 c1
----
  1

```

> 34 теперь попробуйте выполнить команду create table t2(c1 integer); insert into t2 values (2);
> 35 а как так? нам же никто прав на создание таблиц и insert в них под ролью readonly?
> 36 есть идеи как убрать эти права? если нет - смотрите шпаргалку
> 37 если вы справились сами то расскажите что сделали и почему, если смотрели шпаргалку - объясните что сделали и почему выполнив указанные в ней команды
> 38 теперь попробуйте выполнить команду create table t3(c1 integer); insert into t2 values (2);
> 39 расскажите что получилось и почему

```
?ВОПРОС
--- таблица не создаётся

testdb=> create table testnm.t2(c1 integer); 
ERROR:  permission denied for schema testnm
LINE 1: create table testnm.t2(c1 integer);

-- прав по умолчанию нет

testdb=# \ddp+ 
         Default access privileges
 Owner | Schema | Type | Access privileges 
-------+--------+------+-------------------
(0 rows)


testdb=>  select t.table_name, t.table_type, c.relname, c.relowner, u.usename
 from information_schema.tables t
 join pg_catalog.pg_class c on (t.table_name = c.relname)
 join pg_catalog.pg_user u on (c.relowner = u.usesysid)
 where t.table_schema='testnm';
 table_name | table_type | relname | relowner | usename 
------------+------------+---------+----------+---------
 t1         | BASE TABLE | t1      |       10 | postgres

-- подобное можно воспроизвести, если установить владельцем схемы testnm роль readonly


-- аналогично не будет прав на создание таблицы в public
testdb=> create table t2(c1 integer);
ERROR:  permission denied for schema public
LINE 1: create table t2(c1 integer);
```

