## LESSON 16 JOIN

#### nested loop
```
```

Алгоритм вложенного цикла основан на двух циклах: внутренний цикл внутри внешнего цикла. Внешний цикл просматривает все строки первого (внешнего) набора. Для каждой такой строки внутренний цикл ищет совпадающие строки во втором (внутреннем) наборе. При обнаружении пары, удовлетворяющей условию соединения, узел немедленно возвращает ее родительскому узлу, а затем возобновляет сканирование.

Внутренний цикл повторяется столько раз, сколько строк во внешнем наборе. Таким образом, эффективность алгоритма зависит от нескольких факторов:




1. Мощность внешнего множества.
2. Наличие эффективного метода доступа, извлекающего строки из внутреннего набора.


=> EXPLAIN (COSTS OFF) SELECT *
  FROM tickets t JOIN ticket_flights tf ON tf.ticket_no = t.ticket_no 
  WHERE t.ticket_no IN ('0005432312163','0005432312164');
                                    QUERY PLAN                                     
-----------------------------------------------------------------------------------

 Nested Loop
   ->  Index Scan using tickets_pkey on tickets t
         Index Cond: (ticket_no = ANY ('{0005432312163,0005432312164}'::bpchar[]))
   ->  Index Scan using ticket_flights_pkey on ticket_flights tf
         Index Cond: (ticket_no = t.ticket_no)

```
```

#### hash match join
```
Соединение по внешнему ключу без индекса при поиске совпадений в хэше
Этап build - создание в памяти хеш-таблицы по первой таблице соединения
Этап probe - проход по второй таблицы соединения и сравнивание хешей первой и второй таблиц

SELECT name, subject, score FROM student st INNER JOIN score s ON st.id =
s.stu_id
QUERY PLAN
---------------------------------------------------
Hash Join (cost=35.42..297.73 …)
 Hash Cond: (st.id = s.stu_id)
 -> Seq Scan on student st (cost=0.00..22.00)
 -> Hash (cost=21.30..21.30 rows=1130 width=8)
 -> Seq Scan on score s (cost=0.00..21.30)

backets - кол-во построенных бакетов
batches - кол-во проходов (1 - поместились в workmem)
```

#### merge join
```
Соединение слиянием по индексу. Бакеты есть по обоим полям в индексах

=> EXPLAIN (COSTS OFF) SELECT t.ticket_no, bp.flight_id, bp.seat_no
  FROM tickets t
    JOIN ticket_flights tf ON t.ticket_no = tf.ticket_no 
    JOIN boarding_passes bp ON bp.ticket_no = tf.ticket_no 
     AND bp.flight_id = tf.flight_id 
  ORDER BY t.ticket_no;
                                   QUERY PLAN                                   
--------------------------------------------------------------------------------
 Merge Join
   Merge Cond: ((t.ticket_no = tf.ticket_no) AND (bp.flight_id = tf.flight_id))
   ->  Merge Join
         Merge Cond: (bp.ticket_no = t.ticket_no)
         ->  Index Scan using boarding_passes_pkey on boarding_passes bp
         ->  Index Only Scan using tickets_pkey on tickets t
   ->  Index Only Scan using ticket_flights_pkey on ticket_flights tf

heap fetch=0 - данные только из индекса для index only scan
heap fetch>0 - в карте видимости есть мёртвые строки 

```

---
LESSON 17 STATISTICS

Параметры статистики

```
• track_activities - включает мониторинг текущих команд, выполняемых любым серверным процессом. По умолчанию on 
• track_counts - определяет необходимость сбора статистики по обращениям к таблицам и индексам. По умолчанию on 
• track_functions - включает отслеживание использования пользовательских функций. По умолчанию none (отключён) 
• track_io_timing - включает мониторинг времени чтения и записи блоков. По умолчанию off так как для этого требуется постоянно запрашивать текущее время у операционной системы, что может значительно замедлить работу на некоторых платформах (pg_stat_kcache)
• track_wal_io_timing - включает мониторинг времени записи WAL
```

https://postgrespro.ru/docs/postgresql/12/runtime-config-statistics#GUC-TRACK-ACTIVITIES

Параметр сбора статистики
**default_statistic_target=N**
```
row analyze = N * 300
alter table...alter column set statistics 0..10000;
```

Представления на основании статистики
https://postgrespro.ru/docs/postgresql/15/monitoring-stats

**pg_stat_database -  статистика бд**
```
--------- pg_stat_database -----
select datname
     , numbackends
     , xact_commit
     , xact_rollback
     , blks_read
     , blks_hit
     , tup_returned
     , tup_fetched
     , tup_inserted
     , tup_updated
     , tup_deleted
     , stats_reset   
     from pg_stat_database
where datname = 'demo';

---

• blks_hit – количество блоков, полученных из
кэша PostgreSQL
• blks_read – количество блоков, прочитанных
с диска
• xact_commit – количество закомиченных
транзацкий
• xact_rollback – количество транзакций, где
был выполнен откат транзакции

• tup_updated, tup_deleted - параметр кол-ва обновлённых,удалённых строк - на него смотрит автовакуум
• tup_returned - последовательное чтение
• tup_fetched  - индексное чтение
• deadlocks - кол-во дедлоков
• sessions_abandoned - сессии, закрытые бекэндом приложения 
```

**pg_class - объекты бд**
```
select * from pg_class; 
•relpages - размер представления этой таблицы на диске (в страницах размера BLCKSZ). Это лишь
примерная оценка, используемая планировщиком. Она обновляется командами VACUUM, ANALYZE и
несколькими командами DDL, например, CREATE INDEX.
•reltuples - число строк в таблице. Это лишь примерная оценка, используемая планировщиком. Она
обновляется командами VACUUM, ANALYZE и несколькими командами DDL, например, CREATE INDEX.
•relallvisible - число страниц, помеченных как «полностью видимые» в карте видимости таблицы. Это лишь
примерная оценка, используемая планировщиком. Она обновляется командами VACUUM, ANALYZE и
несколькими командами DDL, например, CREATE INDEX.
```

**pg_stats - стата по объектам пб**
```
статистика для планировщика
null_frac - оценка нулевых значений
n_distict - оценка уникальных значений
most_common_vals - оценка наиболее често встречающихся значений
most_common_freq - оценка частоты наиболее често встречающихся значений
histogram_bounds - гистограмма - оценка того, что не попало в most_common_vals (default statistics)
correlation - корреляция выборки с данными на диске - низкая корреляция говорит о возможной необходимости индексов
```

**pg_statistic_ext - расширенная стата**

*статистика по dependencies*
```


select count(*)
from bookings.flights
where flight_no = 'PG0007' and departure_airport = 'VKO'; --121

explain
select *
from bookings.flights
where flight_no = 'PG0007' and departure_airport = 'VKO';

create statistics flights_multi(dependencies) on flight_no,  departure_airport from bookings.flights;
select * from pg_statistic_ext;
analyze bookings.flights;

explain
select *
from bookings.flights
where flight_no = 'PG0007' and departure_airport = 'VKO';
```

*статистика по ndistinct*
```
select count(*)
from
(
    select distinct departure_airport, arrival_airport
    from bookings.flights
) s1;

explain
select distinct departure_airport, arrival_airport
from bookings.flights;

create statistics flights_multi_dist(ndistinct) on departure_airport, arrival_airport from bookings.flights;
select * from pg_statistic_ext;
analyze bookings.flights;

explain
select distinct departure_airport, arrival_airport
from bookings.flights;

explain --618
select departure_airport, arrival_airport
from bookings.flights
group by departure_airport, arrival_airport;

drop statistics flights_multi_dist;
```


*Статистика многовариантых списков значений (mcv)*
```

select * from flights;

SELECT count(*) FROM flights
WHERE departure_airport = 'DME' AND aircraft_code = 'CN1';

explain
SELECT count(*) FROM flights
WHERE departure_airport = 'DME' AND aircraft_code = 'CN1';

CREATE STATISTICS flights_mcv(mcv)
ON departure_airport, aircraft_code FROM flights;

ANALYZE flights;

explain
SELECT count(*) FROM flights
WHERE departure_airport = 'DME' AND aircraft_code = 'CN1';

-- представление для mcv

SELECT values, frequency
FROM pg_statistic_ext stx
  JOIN pg_statistic_ext_data stxd ON stx.oid = stxd.stxoid,
  pg_mcv_list_items(stxdmcv) m
WHERE stxname = 'flights_mcv';
```
https://www.postgresql.org/docs/10/sql-createstatistics.html
https://postgrespro.ru/docs/postgresql/12/multivariate-statistics-examples#MCV-LISTS


**pg_stat_activity - активность процессов**
```
track_activity_query_size - значение в байтах отображения поля query
```
 
**pg_stat_user_tables - информация по таблицам**
```
• relname - название объекта
• seq_scan - кол-во поледовательных сканирований
• idx_scan - кол-во индексных чтений
• n_tup_upd - вставленные строки
• n_tup_hot_upd - вставленные через хот апдейт
• n_live_tup - живые строки
• n_dead_tup - мёртвые строки (при росте автовакуум не приходит)
• autovacuum_count - кол-во автовакуума

select * from pg_stat_user_tables where relname = 'flights';
```

**pg_stat_user_index - информация по индексам**
```
select *
from pg_stat_user_indexes
where relname = 'flights';

•idx_scan -кол-во индексных сканирований
•idx_tup_read - кол-во считанных строк (ходим в таблицу на диск index scan)
•idx_tup_fetch - кол-во извлечённых строк (ходим только в индекс index only scan)


--неиспользуемые индексы
SELECT s.schemaname,
       s.relname AS tablename,
       s.indexrelname AS indexname,
       pg_size_pretty(pg_relation_size(s.indexrelid)) AS index_size,
       s.idx_scan
FROM pg_catalog.pg_stat_all_indexes s
   JOIN pg_catalog.pg_index i ON s.indexrelid = i.indexrelid
WHERE s.idx_scan =0      -- has never been scanned
  AND 0 <>ALL (i.indkey)  -- no index column is an expression
  AND NOT i.indisunique   -- is not a UNIQUE index
  AND NOT EXISTS          -- does not enforce a constraint
         (SELECT 1 FROM pg_catalog.pg_constraint c
          WHERE c.conindid = s.indexrelid)
ORDER BY pg_relation_size(s.indexrelid) DESC;
```


**EXTENSION pg_stat_statements**
```
create extension pg_stat_statements;

• rows — суммарное количество вовзращенных строк;
• shared_blks_hit — количество страниц, которые были в
кэше БД;
• shared_blks_read — количество страниц, которые были
прочитаны с диска, чтобы выполнить запросы такого типа;
• shared_blks_dirtied — количество страниц, которые были
изменены;
• shared_blks_written — количество страниц, которые были
записаны на диск;
• local_blks_hit, local_blks_read, local_blks_dirtied,
local_blks_written — то же самое, что предыдущие 4, только
для временных таблиц и индексов;
• temp_blks_read — сколько страниц временных данных было
прочитано;
• temp_blks_written — сколько страниц временных данных
было записано (используется при сортировке на диски,
джойнах и других временных операциях);
• blk_read_time — сколько времени суммарно заняло чтение
с диска;
• blk_write_time — сколько времени суммарно заняла запись
на диск.
• wal_fpi -кол-во файлов, сгенерённых данным запросом

select * from pg_stat_statements where query like '%bookings.bookings%';
```
