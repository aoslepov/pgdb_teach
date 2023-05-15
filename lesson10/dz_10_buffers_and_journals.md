### Домашнее задание
#### Работа с журналами

**Цель:
уметь работать с журналами и контрольными точками
уметь настраивать параметры журналов**

#### Описание/Пошаговая инструкция выполнения домашнего задания:


> Настройте выполнение контрольной точки раз в 30 секунд.
> 10 минут c помощью утилиты pgbench подавайте нагрузку.
> Измерьте, какой объем журнальных файлов был сгенерирован за это время. Оцените, какой объем приходится в среднем на одну контрольную точку.
> Проверьте данные статистики: все ли контрольные точки выполнялись точно по расписанию. Почему так произошло?

```

-- устанавливаем таймаут контрольой точки
alter system set checkpoint_timeout to '30s';

-- перечитываем конфигурацию
select pg_reload_conf();


-- ставим расширение page_inspect
create extension page_inspect;


-- сбрасываем статистику bgwriter
select pg_stat_reset_shared('bgwriter');

-- смотрим lsn до старта 
select pg_current_wal_insert_lsn();
 pg_current_wal_insert_lsn
---------------------------
 0/1A39DD0


-- запускаем тест на 10 мин
 sudo -u postgres pgbench -i journal
 sudo -u postgres pgbench -c8 -P 6 -T 600 -U postgres journal

 scaling factor: 1
 query mode: simple
 number of clients: 8
 number of threads: 1
 maximum number of tries: 1
 duration: 600 s
 number of transactions actually processed: 308851
 number of failed transactions: 0 (0.000%)
 latency average = 15.540 ms
 latency stddev = 29.343 ms
 initial connection time = 16.824 ms
 tps = 514.754838 (without initial connection time)


-- смотрим lsn по окончанию
select pg_current_wal_insert_lsn();
  pg_current_wal_insert_lsn
 ---------------------------
  0/1D8D4320


-- смотрим размер журнала, сгенерированного во время теста
select pg_size_pretty('0/1D8D4320'::pg_lsn - '0/1A39DD0'::pg_lsn);
  pg_size_pretty
 ----------------
  447 MB

-- в среднем 22,35 MB на контрольную точку



-- смотрим статистику
select * from pg_stat_bgwriter\gx
-[ RECORD 1 ]---------+------------------------------
checkpoints_timed     | 21
checkpoints_req       | 0
checkpoint_write_time | 198377
checkpoint_sync_time  | 19157
buffers_checkpoint    | 166
buffers_clean         | 84793
maxwritten_clean      | 0
buffers_backend       | 240725
buffers_backend_fsync | 0
buffers_alloc         | 523015
stats_reset           | 2023-05-13 19:56:13.586983+0

-- https://postgrespro.ru/docs/postgrespro/15/monitoring-stats#MONITORING-PG-STAT-BGWRITER-VIEW
-- все чекпоинты были выполнены вовремя
-- о задержке чекпоинтов говорит параметр maxwritten_clean 
-- приостановка процесса чекпоинта из-за большого кол-ва грязных страниц
```

> Сравните tps в синхронном/асинхронном режиме утилитой pgbench. Объясните полученный результат.

```
-- тестируем в смнхронном режиме

show synchronous_commit;
 synchronous_commit
----------------------
  on


 sudo -u postgres pgbench -c8 -P 6 -T 60 -U postgres journal
progress: 6.0 s, 530.5 tps, lat 15.022 ms stddev 14.330, 0 failed
progress: 12.0 s, 605.2 tps, lat 13.223 ms stddev 13.704, 0 failed
progress: 18.0 s, 568.2 tps, lat 14.077 ms stddev 14.459, 0 failed
progress: 24.0 s, 570.2 tps, lat 14.027 ms stddev 14.879, 0 failed
progress: 30.0 s, 442.0 tps, lat 18.094 ms stddev 50.664, 0 failed
progress: 36.0 s, 557.2 tps, lat 14.341 ms stddev 31.879, 0 failed
progress: 42.0 s, 568.8 tps, lat 14.084 ms stddev 14.871, 0 failed
progress: 48.0 s, 556.0 tps, lat 14.384 ms stddev 14.564, 0 failed
progress: 54.0 s, 601.3 tps, lat 13.270 ms stddev 13.716, 0 failed
progress: 60.0 s, 383.7 tps, lat 20.915 ms stddev 57.555, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 32305
number of failed transactions: 0 (0.000%)
latency average = 14.855 ms
latency stddev = 26.634 ms
initial connection time = 16.428 ms
tps = 538.450598 (without initial connection time)


-- тестируем в асинхронном режиме коммита
alter system set synchronous_commit to 'off';
select pg_reload_conf();

 synchronous_commit
----------------------
  off

 sudo -u postgres pgbench -c8 -P 6 -T 60 -U postgres journal
progress: 6.0 s, 2826.7 tps, lat 2.820 ms stddev 1.885, 0 failed
progress: 12.0 s, 2868.7 tps, lat 2.789 ms stddev 1.229, 0 failed
progress: 18.0 s, 2845.5 tps, lat 2.811 ms stddev 2.085, 0 failed
progress: 24.0 s, 2422.0 tps, lat 3.302 ms stddev 19.496, 0 failed
progress: 30.0 s, 2875.5 tps, lat 2.781 ms stddev 1.036, 0 failed
progress: 36.0 s, 2487.9 tps, lat 3.216 ms stddev 16.372, 0 failed
progress: 42.0 s, 2874.2 tps, lat 2.783 ms stddev 0.760, 0 failed
progress: 48.0 s, 2186.6 tps, lat 3.644 ms stddev 28.487, 0 failed
progress: 54.0 s, 1855.7 tps, lat 4.313 ms stddev 37.135, 0 failed
progress: 60.0 s, 3001.9 tps, lat 2.673 ms stddev 1.605, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 157474
number of failed transactions: 0 (0.000%)
latency average = 3.047 ms
latency stddev = 15.076 ms
initial connection time = 16.555 ms
tps = 2624.744274 (without initial connection time)

-- при synchronous_commit=off клиенту сообщается о записи в wal сразу после завершения транзакции
-- сама запись будет добавлена в wal позже в асинхронном режиме
-- и это не гарантирует её пападение в wal в случае сбоя на момент транзакции
-- но значительно увеличивает tps 
```

>Создайте новый кластер с включенной контрольной суммой страниц. Создайте таблицу. Вставьте несколько значений. Выключите кластер. Измените пару байт в таблице. Включите кластер и сделайте выборку из таблицы. Что и почему произошло? как проигнорировать ошибку и продолжить работу?

```

-- создаем класер с включённой поддержкой чексумм на страницах
mkdir -p /var/lib/pgsql
chown -R postgres:postgres /var/lib/pgsql
sudo -u postgres pg_createcluster -D /var/lib/pgsql 15 test -- --data-checksums
sudo -u postgrespg_ctlcluster 15 test start

sudo -u postgres pg_lsclusters
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
15  test    5433 online postgres /var/lib/pgsql              /var/log/postgresql/postgresql-15-test.log

-- добавляем тестовые данные
sudo -u postgres psql -p 5433
create table test(i int);
insert into test values (1),(2),(3);


-- смотрим путь к файлу с таблицей
SELECT pg_relation_filepath('test');
 pg_relation_filepath
----------------------
 base/5/16388

-- правим файл в редакторе
-- при селекте будет ошибка чексуммы
 postgres=# select * from test;
 WARNING:  page verification failed, calculated checksum 16068 but expected 28862
 ERROR:  invalid page in block 0 of relation base/5/16388

-- включаем опцию игнорирования ошибок чексумм
 alter system set ignore_checksum_failure to  'on';
 select pg_reload_conf();


-- запрос к таблице становится возможен, но с предупреждением об ошибках чексумм
postgres=# select * from test;
WARNING:  page verification failed, calculated checksum 16068 but expected 28862
 i 
---
 1
 2
```
