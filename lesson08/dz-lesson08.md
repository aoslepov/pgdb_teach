> Создать инстанс ВМ с 2 ядрами и 4 Гб ОЗУ и SSD 10GB
> Установить на него PostgreSQL 15 с дефолтными настройками
```
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql-15
```

> Создать БД для тестов: выполнить pgbench -i postgres
> Запустить pgbench -c8 -P 6 -T 60 -U postgres postgres
```
sudo -u postgres pgbench -i postgres
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.42 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 2.10 s (drop tables 0.00 s, create tables 0.04 s, client-side generate 0.66 s, vacuum 0.03 s, primary keys 1.37 s).

sudo -u postgres pgbench -c8 -P 6 -T 60 -U postgres postgres
pgbench (15.2 (Ubuntu 15.2-1.pgdg22.04+1))
starting vacuum...end.
progress: 6.0 s, 525.7 tps, lat 15.144 ms stddev 12.801, 0 failed
progress: 12.0 s, 487.5 tps, lat 16.421 ms stddev 12.203, 0 failed
progress: 18.0 s, 170.8 tps, lat 46.799 ms stddev 370.898, 0 failed
progress: 24.0 s, 480.8 tps, lat 16.649 ms stddev 85.776, 0 failed
progress: 30.0 s, 533.3 tps, lat 14.971 ms stddev 10.837, 0 failed
progress: 36.0 s, 548.7 tps, lat 14.561 ms stddev 17.374, 0 failed
progress: 42.0 s, 355.2 tps, lat 22.581 ms stddev 22.263, 0 failed
progress: 48.0 s, 508.7 tps, lat 15.740 ms stddev 16.008, 0 failed
progress: 54.0 s, 652.7 tps, lat 12.233 ms stddev 8.304, 0 failed
progress: 60.0 s, 683.3 tps, lat 11.715 ms stddev 7.290, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 29688
number of failed transactions: 0 (0.000%)
latency average = 16.165 ms
latency stddev = 75.245 ms
initial connection time = 18.785 ms
tps = 494.794590 (without initial connection time)
```
> Применить параметры настройки PostgreSQL из прикрепленного к материалам занятия файла
```
-- кол-во коннкетов
max_connections = 40 # default 100
-- буффер разделяемой памяти, доступной серверу
shared_buffers = 1GB # default 128MB
-- дисковый кеш одного запроса
effective_cache_size = 3GB #default 4GB
maintenance_work_mem = 512MB #default 64MB
checkpoint_completion_target = 0.9
-- буфферизация wal - было 3.84(3% от shared_buffers 128MB)
-- улучшает паралельную фиксацию транзакций
wal_buffers = 16MB # default -1
-- увеличина "размерность" статистики, улучшает качество планов для планировщика
default_statistics_target = 500 #default 100
random_page_cost = 4
--кол-во параллельных запросов ввода-вывода
effective_io_concurrency = 2 # default 1
-- объём памяти, используемый для сортировки и агрегатов
work_mem = 6553kB #default 4MB
-- увеличены пределы минимального и максимального wal
-- wal будет реже ротироваться и содержать больше информации для восстановления/репликации
min_wal_size = 4GB # default 80MB
max_wal_size = 16GB # default  1GB
```

Протестировать заново
```
sudo -u postgres pg_ctlcluster 15 main restart

root@pg-teach-01:/etc/postgresql/15/main# sudo -u postgres pgbench -c8 -P 6 -T 60 -U postgres postgres
pgbench (15.2 (Ubuntu 15.2-1.pgdg22.04+1))
starting vacuum...end.
progress: 6.0 s, 492.2 tps, lat 16.182 ms stddev 11.686, 0 failed
progress: 12.0 s, 572.3 tps, lat 13.947 ms stddev 10.695, 0 failed
progress: 18.0 s, 405.3 tps, lat 19.746 ms stddev 16.096, 0 failed
progress: 24.0 s, 299.2 tps, lat 26.760 ms stddev 16.862, 0 failed
progress: 30.0 s, 234.3 tps, lat 34.178 ms stddev 26.142, 0 failed
progress: 36.0 s, 575.0 tps, lat 13.862 ms stddev 9.698, 0 failed
progress: 42.0 s, 292.7 tps, lat 27.403 ms stddev 14.774, 0 failed
progress: 48.0 s, 349.2 tps, lat 22.929 ms stddev 15.636, 0 failed
progress: 54.0 s, 612.7 tps, lat 13.071 ms stddev 8.964, 0 failed
progress: 60.0 s, 490.5 tps, lat 16.251 ms stddev 21.136, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 25948
number of failed transactions: 0 (0.000%)
latency average = 18.504 ms
latency stddev = 16.046 ms
initial connection time = 16.816 ms
tps = 432.253486 (without initial connection time)
```
Что изменилось и почему?
```
-- в результате манипуляций видим улучшение стандартного отклонения латенси более чем в 4 раза
-- используются оба ядра
-- больше памяти для сортировки
-- больше дискового кеша для запросов
-- более эффективная параллельная работа
```
Создать таблицу с текстовым полем и заполнить случайными или сгенерированными данным в размере 1млн строк
Посмотреть размер файла с таблицей
```
dbtest=# CREATE TABLE test(
  id serial,
  txt char(100)
);
CREATE TABLE
dbtest=# create index idx_txt on test(txt);

dbtest=# INSERT INTO test(txt) SELECT 'test' FROM generate_series(1,1000000);
INSERT 0 1000000
dbtest=# select pg_size_pretty(pg_total_relation_size('test'));
 pg_size_pretty
----------------
 142 MB
(1 row)
```
5 раз обновить все строчки и добавить к каждой строчке любой символ
Посмотреть количество мертвых строчек в таблице и когда последний раз приходил автовакуум
```
dbtest=# update test set txt = txt || '1';
dbtest=# update test set txt = txt || '2';
dbtest=# update test set txt = txt || '3';
dbtest=# update test set txt = txt || '4';
dbtest=# update test set txt = txt || '5';

dbtest=# select pg_size_pretty(pg_total_relation_size('test'));
 pg_size_pretty
----------------
 439 MB

dbtest=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs WHERE relname = 'test';
 relname | n_live_tup | n_dead_tup | ratio% |       last_autovacuum
---------+------------+------------+--------+------------------------------
 test    |    1000000 |    1000000 |     99 | 2023-05-03 21:33:48.91609+00
(1 row)
```
Подождать некоторое время, проверяя, пришел ли автовакуум
5 раз обновить все строчки и добавить к каждой строчке любой символ
Посмотреть размер файла с таблицей
```
dbtest=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs WHERE relname = 'test';
 relname | n_live_tup | n_dead_tup | ratio% |        last_autovacuum
---------+------------+------------+--------+-------------------------------
 test    |    1000000 |          0 |      0 | 2023-05-03 21:34:54.441447+00

dbtest=# update test set txt = txt || '1';
UPDATE 1000000
dbtest=# update test set txt = txt || '2';
UPDATE 1000000
dbtest=# update test set txt = txt || '3';
UPDATE 1000000
dbtest=# update test set txt = txt || '4';
UPDATE 1000000
dbtest=# update test set txt = txt || '5';
UPDATE 1000000

dbtest=# select pg_size_pretty(pg_total_relation_size('test'));
 pg_size_pretty
----------------
 452 MB

```
Отключить Автовакуум на конкретной таблице
10 раз обновить все строчки и добавить к каждой строчке любой символ
Посмотреть размер файла с таблицей
```
dbtest=# alter table test set (autovacuum_enabled = off);
ALTER TABLE

dbtest=# update test set txt = txt || '1';
...
dbtest=# update test set txt = txt || '10';

select pg_size_pretty(pg_total_relation_size('test'));
 pg_size_pretty
----------------
 1587 MB

```
Объясните полученный результат
Не забудьте включить автовакуум)
```
dbtest=# alter table test set (autovacuum_enabled = off);
```
Задание со *:
Написать анонимную процедуру, в которой в цикле 10 раз обновятся все строчки в искомой таблице.
Не забыть вывести номер шага цикла.
```
DO
$do$
DECLARE
   i int;
BEGIN
   FOR i IN 1..10 LOOP
      update test set txt = txt || i;
      raise info '%', i;
   END LOOP;
END
$do$;
```


==============
===================

sudo -u postgres pgbench -i postgres
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.42 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 2.10 s (drop tables 0.00 s, create tables 0.04 s, client-side generate 0.66 s, vacuum 0.03 s, primary keys 1.37 s).

===

sudo -u postgres pgbench -c8 -P 6 -T 60 -U postgres postgres
pgbench (15.2 (Ubuntu 15.2-1.pgdg22.04+1))
starting vacuum...end.
progress: 6.0 s, 525.7 tps, lat 15.144 ms stddev 12.801, 0 failed
progress: 12.0 s, 487.5 tps, lat 16.421 ms stddev 12.203, 0 failed
progress: 18.0 s, 170.8 tps, lat 46.799 ms stddev 370.898, 0 failed
progress: 24.0 s, 480.8 tps, lat 16.649 ms stddev 85.776, 0 failed
progress: 30.0 s, 533.3 tps, lat 14.971 ms stddev 10.837, 0 failed
progress: 36.0 s, 548.7 tps, lat 14.561 ms stddev 17.374, 0 failed
progress: 42.0 s, 355.2 tps, lat 22.581 ms stddev 22.263, 0 failed
progress: 48.0 s, 508.7 tps, lat 15.740 ms stddev 16.008, 0 failed
progress: 54.0 s, 652.7 tps, lat 12.233 ms stddev 8.304, 0 failed
progress: 60.0 s, 683.3 tps, lat 11.715 ms stddev 7.290, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 29688
number of failed transactions: 0 (0.000%)
latency average = 16.165 ms
latency stddev = 75.245 ms
initial connection time = 18.785 ms
tps = 494.794590 (without initial connection time)


-- кол-во коннкетов
max_connections = 40 # default 100
-- буффер разделяемой памяти, доступной серверу
shared_buffers = 1GB # default 128MB
-- дисковый кеш одного запроса
effective_cache_size = 3GB #default 4GB
maintenance_work_mem = 512MB #default 64MB
checkpoint_completion_target = 0.9
-- буфферизация wal - было 3.84(3% от shared_buffers 128MB)
-- улучшает паралельную фиксацию транзакций
wal_buffers = 16MB # default -1

-- увеличина "размерность" статистики, улучшает качество планов для планировщика
default_statistics_target = 500 #default 100
random_page_cost = 4
--кол-во параллельных запросов ввода-вывода
effective_io_concurrency = 2 # default 1
-- объём памяти, используемый для сортировки и агрегатов
work_mem = 6553kB #default 4MB
-- увеличены пределы минимального и максимального wal
-- wal будет реже ротироваться и содержать больше информации для восстановления/репликации
min_wal_size = 4GB # default 80MB
max_wal_size = 16GB # default  1GB


sudo -u postgres pg_ctlcluster 15 main restart

root@pg-teach-01:/etc/postgresql/15/main# sudo -u postgres pgbench -c8 -P 6 -T 60 -U postgres postgres
pgbench (15.2 (Ubuntu 15.2-1.pgdg22.04+1))
starting vacuum...end.
progress: 6.0 s, 492.2 tps, lat 16.182 ms stddev 11.686, 0 failed
progress: 12.0 s, 572.3 tps, lat 13.947 ms stddev 10.695, 0 failed
progress: 18.0 s, 405.3 tps, lat 19.746 ms stddev 16.096, 0 failed
progress: 24.0 s, 299.2 tps, lat 26.760 ms stddev 16.862, 0 failed
progress: 30.0 s, 234.3 tps, lat 34.178 ms stddev 26.142, 0 failed
progress: 36.0 s, 575.0 tps, lat 13.862 ms stddev 9.698, 0 failed
progress: 42.0 s, 292.7 tps, lat 27.403 ms stddev 14.774, 0 failed
progress: 48.0 s, 349.2 tps, lat 22.929 ms stddev 15.636, 0 failed
progress: 54.0 s, 612.7 tps, lat 13.071 ms stddev 8.964, 0 failed
progress: 60.0 s, 490.5 tps, lat 16.251 ms stddev 21.136, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 25948
number of failed transactions: 0 (0.000%)
latency average = 18.504 ms
latency stddev = 16.046 ms
initial connection time = 16.816 ms
tps = 432.253486 (without initial connection time)



-- в результате манипуляций видим улучшение стандартного отклонения латенси более чем в 4 раза 
-- используются оба ядра
-- больше памяти для сортировки 
-- больше дискового кеша для запросов
-- более эффективная параллельная работа


==========


dbtest=# CREATE TABLE test(
  id serial,
  txt char(100)
);
CREATE TABLE
dbtest=# create index idx_txt on test(txt);

dbtest=# INSERT INTO test(txt) SELECT 'test' FROM generate_series(1,1000000);
INSERT 0 1000000
dbtest=# select pg_size_pretty(pg_total_relation_size('test'));
 pg_size_pretty
----------------
 142 MB
(1 row)

dbtest=# update test set txt = txt || '1';
UPDATE 1000000
dbtest=# update test set txt = txt || '2';
UPDATE 1000000
dbtest=# update test set txt = txt || '3';
UPDATE 1000000
dbtest=# update test set txt = txt || '4';
UPDATE 1000000
dbtest=# update test set txt = txt || '5';
UPDATE 1000000

dbtest=# select pg_size_pretty(pg_total_relation_size('test'));
 pg_size_pretty
----------------
 439 MB


dbtest=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs WHERE relname = 'test';
 relname | n_live_tup | n_dead_tup | ratio% |       last_autovacuum
---------+------------+------------+--------+------------------------------
 test    |    1000000 |    1000000 |     99 | 2023-05-03 21:33:48.91609+00
(1 row)

dbtest=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs WHERE relname = 'test';
 relname | n_live_tup | n_dead_tup | ratio% |        last_autovacuum
---------+------------+------------+--------+-------------------------------
 test    |    1000000 |          0 |      0 | 2023-05-03 21:34:54.441447+00

dbtest=# update test set txt = txt || '1';
UPDATE 1000000
dbtest=# update test set txt = txt || '2';
UPDATE 1000000
dbtest=# update test set txt = txt || '3';
UPDATE 1000000
dbtest=# update test set txt = txt || '4';
UPDATE 1000000
dbtest=# update test set txt = txt || '5';
UPDATE 1000000

dbtest=# select pg_size_pretty(pg_total_relation_size('test'));
 pg_size_pretty
----------------
 452 MB


dbtest=# alter table test set (autovacuum_enabled = off);
ALTER TABLE

dbtest=# update test set txt = txt || '1';
...
dbtest=# update test set txt = txt || '10';

select pg_size_pretty(pg_total_relation_size('test'));
 pg_size_pretty
----------------
 1587 MB


=============

-- анонимная процедура обновления 10 строк


DO
$do$
DECLARE
   i int;
BEGIN
   FOR i IN 1..10 LOOP
      update test set txt = txt || i;
      raise info '%', i;
   END LOOP;
END
$do$;
