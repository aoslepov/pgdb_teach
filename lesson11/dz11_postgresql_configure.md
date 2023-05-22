### Домашнее задание. Нагрузочное тестирование и тюнинг PostgreSQL

#### Цель: сделать нагрузочное тестирование PostgreSQL, настроить параметры PostgreSQL для достижения максимальной производительности

> Описание/Пошаговая инструкция выполнения домашнего задания:
> • развернуть виртуальную машину любым удобным способом
> • поставить на неё PostgreSQL 15 любым способом
> • настроить кластер PostgreSQL 15 на максимальную производительность не обращая внимание на возможные проблемы с надежностью в случае аварийной перезагрузки виртуальной машины
> • нагрузить кластер через утилиту через утилиту pgbench (https://postgrespro.ru/docs/postgrespro/14/pgbench)
> • написать какого значения tps удалось достичь, показать какие параметры в какие значения устанавливали и почему
```
-- подготавливаем данные для теста
sudo -u postgres pgbench -i test

-- запускаем тест
sudo -u postgres pgbench -c 50 -C -j 2 -P 10 -T 60 -M extended test

transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: extended
number of clients: 50
number of threads: 2
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 14896
number of failed transactions: 0 (0.000%)
latency average = 196.134 ms
latency stddev = 234.118 ms
average connection time = 5.281 ms
tps = 204.900910 (including reconnection time)

```

*Добавляем в conf.d tune.conf*
```
-- конфигурация для cpu 2/ram 4gb

-- определяем максимальное кол-во коннектов и резервные коннекты для суперюзеров
max_connections = 100
superuser_reserved_connections = 3

-- буфферы разделяемой памяти
-- shared_buffers - 1/3 RAM
shared_buffers = '1 GB' 

-- размер памяти для хеш таблиц и сортировки в рамках коннекта
-- work_mem = (RAM * 0.8 - shared_buffers) / max_connections
work_mem = '22 MB'

-- память для обслуживания бд (vacuul,analyze, create index...)
maintenance_work_mem = '320 MB'

-- размер дискового кэша в рамках коннекта
-- effective_cache_size = RAM*0.7(0.8)
effective_cache_size = '3 GB'

-- iops, рекомендация для облачного ssd
effective_io_concurrency = 200 

-- стоимость рандомного чтения (рекомендовано для ssd)
random_page_cost = 1.2 

-- определяем изоляцию транзакций
transaction_isolation = 'read uncommitted'
default_transaction_isolation = 'read uncommitted'

-- минимальная информация в wal без сендеров
wal_level = minimal 
max_wal_senders = 0
-- тюнинг min/max размера wal
max_wal_size = '1024 MB'
min_wal_size = '512 MB'


-- сброс страниц на диск выполняет ос по мере необходимости
fsync = off

-- таймаут чекпоинта - 15 мин выполняется 90% времени
checkpoint_timeout = '15 min'
checkpoint_completion_target = 0.9


-- отключено сжатие wal
wal_compression = off

-- асинхронный коммит и конфигурация bgwriter
synchronous_commit = off
bgwriter_delay = 200ms
bgwriter_lru_maxpages = 1000
bgwriter_lru_multiplier = 2.0

-- конфигурация для распараллеливания запросов по ядрам 
max_worker_processes = 2
max_parallel_workers_per_gather = 1
max_parallel_maintenance_workers = 1
max_parallel_workers = 2
parallel_leader_participation = on

-- выключаем автовакуум
autovacuum = off

```



*tuned =>*
```
sudo -u postgres pgbench -c 50 -C -j 2 -P 10 -T 60 -M extended test
progress: 10.0 s, 257.7 tps, lat 184.310 ms stddev 195.651, 0 failed
progress: 20.0 s, 262.4 tps, lat 186.065 ms stddev 185.812, 0 failed
progress: 30.0 s, 253.0 tps, lat 190.352 ms stddev 208.937, 0 failed
progress: 40.0 s, 249.1 tps, lat 196.991 ms stddev 195.802, 0 failed
progress: 50.0 s, 260.3 tps, lat 186.530 ms stddev 208.092, 0 failed
progress: 60.0 s, 254.5 tps, lat 190.677 ms stddev 229.245, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: extended
number of clients: 50
number of threads: 2
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 15420
number of failed transactions: 0 (0.000%)
latency average = 189.352 ms
latency stddev = 204.572 ms
average connection time = 5.233 ms
tps = 256.613164 (including reconnection times)


-- результаты 
latency average: 196.134 ms  --> 189.352
latency stddev:  234.118 ms  --> 204.572
tps:             204.900910  --> 256.613164

--  при данном конфиге данные теcтового прогона полностью умещаются в ram
--  также минимизировано кол-во обращений к диску
```



>Задание со *: аналогично протестировать через утилиту https://github.com/Percona-Lab/sysbench-tpcc (требует установки https://github.com/akopytov/sysbench)

```
-- ставим пакет sysbench
curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash
sudo apt -y install sysbench

-- забираем на сервер скрипты для тестирования
git clone https://github.com/Percona-Lab/sysbench-tpcc.git


-- создаём тестового пользователя
create user test  with password 'test' login superuser;


-- создаём тестовый набор данных
./tpcc.lua --pgsql-user=test --pgsql-db=test --pgsql-password=test --pgsql-host=127.0.0.1 --time=60 --threads=2 --report-interval=1 --tables=1 --scale=1 --use_fk=0 --trx_level=RC --db-driver=pgsql prepare


-- запускем vacuum+analyze для бд test и спрасываем кеши ос перед каждум тестом
vacuumdb -j 2 -d test -z -h 127.0.0.1 -U test -W
echo 3 > /proc/sys/vm/drop_caches


./tpcc.lua --pgsql-user=test --pgsql-db=test --pgsql-password=test --pgsql-host=127.0.0.1 --time=60 --threads=2 --report-interval=1 --tables=1 --scale=1 --use_fk=0 --trx_level=RC --db-driver=pgsql run


*original config =>*
```
SQL statistics:
    queries performed:
        read:                            150532
        write:                           156069
        other:                           23484
        total:                           330085
    transactions:                        11740  (195.62 per sec.)
    queries:                             330085 (5500.00 per sec.)
    ignored errors:                      51     (0.85 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          60.0137s
    total number of events:              11740

Latency (ms):
         min:                                    0.60
         avg:                                   10.22
         max:                                 1027.69
         95th percentile:                       21.89
         sum:                               119991.44

Threads fairness:
    events (avg/stddev):           5870.0000/10.00
    execution time (avg/stddev):   59.9957/0.00
``


*tuned =>*
```
SQL statistics:
    queries performed:
        read:                            191474
        write:                           198854
        other:                           28978
        total:                           419306
    transactions:                        14487  (241.39 per sec.)
    queries:                             419306 (6986.83 per sec.)
    ignored errors:                      64     (1.07 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          60.0120s
    total number of events:              14487

Latency (ms):
         min:                                    0.62
         avg:                                    8.28
         max:                                 1235.63
         95th percentile:                       16.12
         sum:                               119983.15

Threads fairness:
    events (avg/stddev):           7243.5000/112.50
    execution time (avg/stddev):   59.9916/0.00

``
