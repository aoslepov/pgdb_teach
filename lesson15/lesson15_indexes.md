## LESSON 15 INDEX

create index ...

```
fillfactor
Фактор заполнения для индекса определяет в процентном отношении, насколько плотно метод индекса будет заполнять страницы индекса. Для B-деревьев концевые страницы заполняются до этого процента при начальном построении индекса и позже, при расширении индекса вправо (добавлении новых наибольших значений ключа). Если страницы впоследствии оказываются заполненными полностью, они будут разделены, что приводит к постепенному снижению эффективности индекса. Для B-деревьев по умолчанию используется фактор заполнения 90, но его можно поменять на любое целое значение от 10 до 100. Фактор заполнения, равный 100, полезен для статических таблиц и помогает уменьшить физический размер таблицы, но для интенсивно изменяемых таблиц лучше использовать меньшее значение, чтобы разделять страницы приходилось реже. С другими методами индекса фактор заполнения действует по-другому, но примерно в том же ключе; значение фактора заполнения по умолчанию для разных методов разное.
```

fillfactor=50 - много апдейтов на поля с индексами - ападейты в режиме hot update в свободное место на странице
fillfactor=100 - для таймлайн данных без апдейтов - более компактное хранение

```
select * from pg_settings where name ='seq_page_cost'; -- кол-во костов для последовательного чтения
select * from pg_settings where name ='cpu_tuple_cost'; -- кол-во костов для получения одной строчки
```

cost = (число_чтений_диска * seq_page_cost) + (число_просканированных_строк * cpu_tuple_cost)
cost = shared hit*seq_page_cost + rows*cpu_tuple_cost

```
explain (buffers,analyse)
select *
from test;

Seq Scan on test  (cost=0.00..882.00 rows=50000 width=31) (actual time=0.011..7.138 rows=50000 loops=1)
  Buffers: shared hit=382
Planning Time: 0.044 ms
Execution Time: 11.853 ms

-- cost=0.00..882.00 rows=50000 width=31
-- косты для получения первой строчки..всех строчек, кол-во строк, ширина колонки с данными

-- actual time=0.011..7.138 rows=50000 loops=1
-- время получения первой..всех строчек, кол-встрок, проход за один цикл (запрос влез в work mem)

-- Buffers: shared hit=382 
-- все данные по запросу находятся в оперативной памяти

-- cost = 382*1+50000*0.01 = 882
```

Визуализация эксплейна
https://explain.tensor.ru/
https://explain.depesz.com/


Уникальный индекс создаётся при помощи констрейнт
```
alter table test add constraint uk_test_id unique(id);
```

Настройка планировщика
https://postgrespro.ru/docs/postgresql/13/runtime-config-query

Индекс на функцию
```
create index idx_test_id_is_okay on test(lower(is_okay));
```

Частичный индекс
```
create index idx_test_id_100 on test(id) where id < 100;
```

Cелективность индексов
```
< 20% строк таблицы - index scan
> 20% < 40% - bitmap index scan 
> 40% -- seq scan

cost > 1000 - parallel seq scan
```

Обслуживание индексов
```
SELECT
    TABLE_NAME,
    pg_size_pretty(table_size) AS table_size,
    pg_size_pretty(indexes_size) AS indexes_size,
    pg_size_pretty(total_size) AS total_size
FROM (
    SELECT
        TABLE_NAME,
        pg_table_size(TABLE_NAME) AS table_size,
        pg_indexes_size(TABLE_NAME) AS indexes_size,
        pg_total_relation_size(TABLE_NAME) AS total_size
    FROM (
        SELECT ('"' || table_schema || '"."' || TABLE_NAME || '"') AS TABLE_NAME
        FROM information_schema.tables
    ) AS all_tables
    ORDER BY total_size DESC

    ) AS pretty_sizes;

select * from pg_stat_user_indexes;
```

Неиспользуемые индексы
```
SELECT s.schemaname,
       s.relname AS tablename,
       s.indexrelname AS indexname,
       pg_size_pretty(pg_relation_size(s.indexrelid)) AS index_size,
       s.idx_scan
FROM pg_catalog.pg_stat_all_indexes s
   JOIN pg_catalog.pg_index i ON s.indexrelid = i.indexrelid
WHERE s.idx_scan < 100      -- has never been scanned
  AND 0 <>ALL (i.indkey)  -- no index column is an expression
  AND NOT i.indisunique   -- is not a UNIQUE index
  AND NOT EXISTS          -- does not enforce a constraint
         (SELECT 1 FROM pg_catalog.pg_constraint c
          WHERE c.conindid = s.indexrelid)
ORDER BY pg_relation_size(s.indexrelid) DESC;
```

Посмотреть команды, которыми были созданы индексы
```
SELECT tablename, indexname,  indexdef FROM pg_indexes  ORDER BY tablename, indexname;
```

```
jit_above_cost -- обработка запроса при помощт jit компилятора
```

??  bitmap scan (битовая карта)


Мониторинг распухания таблиц

```
select * from pgstattuple('orders'); 
-- tuple_persent ~ fillfactor

select * from pgstatindex('orders_order_date');
--avg_leaf_density
```
