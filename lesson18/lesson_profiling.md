## LESSON 18 PROFILING


https://pgstats.dev/?version=13


Статистика по запросам pg_stat_statements 
ТОП по загрузке CPU 
```
SELECT substring(query, 1, 50) AS short_query, round(total_time::numeric, 2) AS total_time, calls, rows, round(total_time::numeric / calls, 2) AS avg_time, round((100 * total_time / sum(total_time::numeric) OVER ())::numeric, 2) AS percentage_cpu FROM pg_stat_statements ORDER BY total_time DESC LIMIT 20;
```

ТОП по времени выполнения 
```
SELECT substring(query, 1, 100) AS short_query, round(total_time::numeric, 2) AS total_time, calls, rows, round(total_time::numeric / calls, 2) AS avg_time, round((100 * total_time / sum(total_time::numeric) OVER ())::numeric, 2) AS percentage_cpu FROM pg_stat_statements ORDER BY avg_time DESC LIMIT 20;
```

Последовательное сканирование/индексное сканирование  - pg_stat_user_tables
```
SELECT schemaname, relname, seq_scan, seq_tup_read,
seq_tup_read / seq_scan AS avg, idx_scan
FROM pg_stat_user_tables WHERE seq_scan > 0
ORDER BY seq_tup_read DESC LIMIT 25;
```

io нагрузка - pg_statio_user_tables
```
select * from pg_statio_user_tables;
```

Регулярный сбор статистики -pg_profile


Популярные запросы мониторинга
```
alter system set shared_preload_libraries = 'pg_stat_statements';


select sum(total_exec_time)/sum(calls) from pg_stat_statements; -- время отклика
select sum(xact_rollback) from pg_catalog.pg_stat_database; -- кол-во роллбеков

select sum(xact_commit+xact_rollback)/3600 from pg_stat_database; --TPS
select sum(calls)/3600 from pg_stat_statements; --QPS

select now() - pg_postmaster_start_time(); -- uptime database

select count(query) from pg_catalog.pg_stat_activity where query like '%autovacuum%'; --кол-во процессов автовакуума

select date_trunc('seconds',max(now()-xact_start)) from pg_stat_activity; -- медленные запросы / автовакуумы

select state, count(*) from pg_stat_activity group by state; -- статусы запросов для клиентов

select state, date_trunc('seconds',max(now()-xact_start)) as ts from pg_stat_activity group by state order by ts desc; -- транзакции с группировкой по коннекту

select state, date_trunc('seconds',max(now()-query_start)) as ts from pg_stat_activity group by state order by ts desc; -- запросы с группировкой по коннекту

select relname,n_tup_ins,n_tup_upd,n_tup_del,n_tup_hot_upd  from pg_stat_user_tables; -- workload by tables


select query, max(calls) as mx from pg_stat_statements group by query order by mx desc limit 10 ; -- top самые частые
select query, max(total_exec_time) as mx from pg_stat_statements group by query order by mx desc limit 10 ; -- самые долгие (среднее)
select query, max(mean_exec_time) as mx from pg_stat_statements group by query order by mx desc limit 10 ; -- самые долгие (медиана)
select query, max(shared_blks_hit+shared_blks_read+shared_blks_dirtied+shared_blks_written) as mx from pg_stat_statements group by query order by mx desc limit 10 ; -- самые тяжёлые 
select query, max(rows) as mx from pg_stat_statements group by query order by mx desc limit 10 ; -- самые большие выборки
select query, max(temp_blks_read+temp_blks_written) as mx from pg_stat_statements group by query order by mx desc limit 10 ; -- используют временные файлы
select query, max(local_blks_hit+local_blks_read+local_blks_dirtied+local_blks_written) as mx from pg_stat_statements group by query order by mx desc limit 10 ; -- -- используют временные таблицы

select * from pg_stat_bgwriter; -- мониторинг автовакуума

select * from pg_catalog.pg_stat_replication; -- мониторинг репликации
```


