## LESSON 8 MVCC
ARIES - (algoritms of recovery and isolation exploting semantics) - алгоритмы восстановления систем
```
- журнал транзакций
- кортежные блокировки
- checkpoints
- undo
- redo
```

В других субд mvcc - метод конкурентного доступа, реализуем через сегмент отката (undo)
В posrgres mvcc -  данные не удаляются, а создаются новые версии строк

```
xmin - id транзакции, создавшей запись
xmax - id транзакции, удалившей запись
cmin - порядковый номер транзакции, создавшей запись
cmax - порядковый номер транзакции, удалившей запись
infomask - биты для определения свойств xmin_commited,xmin_aborted,xmax_commited,xmax_aborted,
ctid (x,y) - порядковый номер транзакции, x - номер страницы, у - порядковый номер в массиве

-- номер транзакции
select txid_current();
```

```
-- insert
xmin=txid_current,xmax=0
otus=# select i,xmin,xmax,cmin,cmax,ctid from test;
 i  | xmin | xmax | cmin | cmax | ctid  
----+------+------+------+------+-------
 10 |  819 |    0 |    0 |    0 | (0,1)
 20 |  819 |    0 |    0 |    0 | (0,2)
 30 |  819 |    0 |    0 |    0 | (0,3)




-- delete
xmax=txid_current

-- update
xmax=txid_current для старой версии
добавляется строка xmin=txid_current,xmax=0


```


```
-- посмотреть мёртвые строки
SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs WHERE relname = 'test';

-- расширение для просмотра страничной информации (мёртвых строк)
create extension pageinspect; 
\dx+ - список функций расширения

-- update
otus=# SELECT lp as tuple, t_xmin, t_xmax, t_field3 as t_cid, t_ctid FROM heap_page_items(get_raw_page('test',0));
 tuple | t_xmin | t_xmax | t_cid | t_ctid 
-------+--------+--------+-------+--------
     1 |    819 |    820 |     0 | (0,4)
     2 |    819 |      0 |     0 | (0,2)
     3 |    819 |      0 |     0 | (0,3)
     4 |    820 |      0 |     0 | (0,4)

-- rollback
данные не удаляются, в infomask ставится бит xmax_aborted
```


#### VACUUM

```
мёртвые строки занимают место на диске и в памяти, участвуют select и update where,снижают производительность
vacuum verbose таблица - запуск вакуума
vacuum full - пересоздание таблицы с данными без дыр
pg_stat_progress_vacuum -- мониторинг процесса вакуума
```

```
select pg_relation_filepath('test'); -- путь к таблице

-- конфигурация vacuum
SELECT name, setting, context, short_desc FROM pg_settings WHERE name like 'vacuum%';

 vacuum_cost_limit -- 
vacuum_cost_delay  - вакуум преостанавливается на время при достижении лимита
 vacuum_cost_page_hit -  буффер > 1
 vacuum_cost_page_miss - оперативка > 5
 vacuum_cost_page_dirty -- хдд > 10

analyze table -- после заливки большого объёма данных 
```

#### AUTOVACUUM
```
-- параметры автовакуума
SELECT name, setting, context, short_desc FROM pg_settings WHERE name like 'autovacuum%';


 autovacuum_vacuum_cost_limit -предел стоимости 
 autovacuum_vacuum_cost_delay - автовакуум преостанавливается на время при достижении лимита

 autovacuum_max_workers - кол-во воркеров (один на таблицу)
 autovacuum_work_mem - память из work_mem

 autovacuum_vacuum_threshold-  трешхолд сработки для записей для мёртвых строк
 autovacuum_vacuum_scale_factor - трешхолд сработки на долю в таблице  для мёртвых строк
autovacuum_vacuum_insert_threshold-  трешхолд сработки для записей для мёртвых строк для вставки

 autovacuum_analyze_threshold- трешхолд сработки на долю в таблице для статистики
 autovacuum_analyze_scale_factor - трешхолд сработки на долю в таблице  для статистики

```

Сработка автовакуума по формуле:
```
Кол-во мёртвых строк(pg_stat_user_tables.n_dead_tup) >= autovacuum_vacuum_threshold+ autovacuum_vacuum_scale_factor*pg_class.reltuples
```

```
log_autovacuum_min_duration=0 -- мин время выполнения для логирования
autovacuum_max_workers-кол-во ядер
autovacuum_naptime=15s
autovacuum_vacuum_threshold=25
autovacuum_vacuum_scale_factor=0.05
autovacuum_vacuum_cost_delay = 10
autovacuum_vacuum_cost_limit=1000
```

```
-- настройки для конкретных таблиц
alter table table_name set (autovacuum_enabled = off);
alter table table_name set (autovacuum_vacuum_threshold = 100);
```

```
SELECT * FROM pg_stat_activity WHERE query ~ 'autovacuum' \gx - мониторинг автовакуума
```
