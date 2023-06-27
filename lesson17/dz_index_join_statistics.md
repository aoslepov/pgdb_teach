### Домашнее задание
### Работа с индексами, join'ами, статистикой

**Цель:**
* знать и уметь применять основные виды индексов PostgreSQL
* строить и анализировать план выполнения запроса
* уметь оптимизировать запросы для с использованием индексов
* знать и уметь применять различные виды join'ов
* строить и анализировать план выполенения запроса
* оптимизировать запрос
* уметь собирать и анализировать статистику для таблицы


> Создать индекс к какой-либо из таблиц вашей БД. Прислать текстом результат команды explain,в которой используется данный индекс

```
create table index_test as
select 
	  generate_series as id
	, generate_series::text || (random() * 10)::text as txt
    , (array['category1', 'category2', 'category3'])[floor(random() * 3 + 1)] as category
from generate_series(1, 100000);
analyze index_test;
```

*EXPLAIN (ANALYZE, BUFFERS) select id from index_test;*
```
Seq Scan on index_test  (cost=0.00...1834.00 rows=100000 width=37) (actual time=0.009..10.034 rows=100000 loops=1)
  Buffers: shared hit=834
Planning:
  Buffers: shared hit=14
Planning Time: 0.185 ms
Execution Time: 7.687 ms

Планировщик выбрал последовательное сканирование (seq scan)
 
Cтоимость послучения первой строки 0

shared_hit -кол-во страниц на диске/в памяти, которые необходимо прочитать 
SELECT relpages FROM pg_class WHERE relname = 'index_test'; -- 834 

Cтоимость послучения первой строки 0
Cтоимость получения всех сток=shared_hit(834)*seq_page_cost(1)+rows(100000)*cpu_tuple_cost(0.01)=1834
Ширина полученного массива данных (width) = 37
Время получения (actual_time) = первой строки (0.008)...всех строк(10.034)
Строк отдано (rows) = 100000
Проходов сделано (loops) =1 -- данные поместились в work_mem
```

**Создаём индекс**

```
drop index idx_id;
CREATE INDEX CONCURRENTLY "idx_id" ON index_test ( id );

```

Index Only Scan using idx_id on index_test  (cost=0.29..4.31 rows=1 width=4) (actual time=0.028..0.031 rows=1 loops=1)
  Index Cond: (id = 1)
  Heap Fetches: 0
  Buffers: shared hit=3
Planning Time: 0.111 ms
Execution Time: 0.061 ms

-- используется индексное сканирование без чтения данных с диска (метод index only scan)
-- также данные поместились в work_mem
```


> Реализовать индекс для полнотекстового поиска




**explain (ANALYZE, BUFFERS) select * from index_test where category like '%category1%';**
```
Seq Scan on index_test  (cost=0.00..2084.00 rows=33200 width=37) (actual time=0.019..38.348 rows=33134 loops=1)
  Filter: (category ~~ '%category1%'::text)
  Rows Removed by Filter: 66866
  Buffers: shared hit=834
Planning Time: 0.086 ms
Execution Time: 42.107 ms
```


**Для полнотесктового поиска необходимо преобразование значений колонок в лексемы с указанием позиций**
```
select category, to_tsvector(category) from index_test ;
category3	'category3':1
category2	'category2':1
category2	'category2':1
category1	'category1':1
..

```

**Поиск будет выглядеть следующим образом**


```
select category, to_tsvector(category) @@ to_tsquery('category1') from index_test;
category3	false
category2	false
category2	false
category1	true
..
```

**Для индекса создаём колонку типа tsvector и заполняем данными**
```
alter table index_test add column category_lexeme tsvector;
update index_test set category_lexeme = to_tsvector(category);
```

**Создаём на поле индекс**
```
create index concurrently idx_fulltext_category ON index_test USING GIN (category_lexeme);

-- смотрим эксплейн
explain (ANALYZE, BUFFERS)
select *
from index_test 
where category_lexeme @@ to_tsquery('category1');


Bitmap Heap Scan on index_test  (cost=313.45..10995.03 rows=33187 width=60) (actual time=8.788..22.990 rows=33134 loops=1)
  Recheck Cond: (category_lexeme @@ to_tsquery('category1'::text))
  Heap Blocks: exact=1137
  Buffers: shared hit=1145
  ->  Bitmap Index Scan on idx_fulltext_category  (cost=0.00..305.15 rows=33187 width=0) (actual time=8.400..8.400 rows=33134 loops=1)
        Index Cond: (category_lexeme @@ to_tsquery('category1'::text))
        Buffers: shared hit=8
Planning:
  Buffers: shared hit=1
Planning Time: 0.138 ms
Execution Time: 27.776 ms

-- выполняется сканирование по битовой карте
-- при этом будет прочитано 8 стр памяти для разбора лексем + 1143 стр для построения индекса по битовой карте
-- время выполнения запроса уменьшилось вдвое

```


> Реализовать индекс на часть таблицы или индекс на поле с функцией


**Частичный индес с устовием id<30**
```
create index concurrently idx_index_test_id_30 on index_test(id) where id < 30;

explain
select * from index_test where id =10;
Index Scan using idx_index_test_id_30 on index_test  (cost=0.14..8.15 rows=1 width=60)
  Index Cond: (id = 10)


-- сморим разницу по размеру индекса
select pg_size_pretty(pg_total_relation_size('idx_id')); --4408Kb
select pg_size_pretty(pg_total_relation_size('idx_index_test_id_30')); --16Kb
```

 
 
**Индекс по выражению**

--пример explain без индекса
explain (ANALYZE, BUFFERS)
SELECT * FROM index_test WHERE (id || ' ' || category) = '1 category3';

Seq Scan on index_test  (cost=0.00..4220.00 rows=500 width=60) (actual time=0.385..45.740 rows=1 loops=1)
  Filter: ((((id)::text || ' '::text) || category) = '1 category3'::text)
  Rows Removed by Filter: 99999
  Buffers: shared hit=1970
Planning Time: 0.129 ms
Execution Time: 45.765 ms

create index concurrently idx_id_cat on index_test((id || ' ' || category));

-- пример explain c индексом
explain (ANALYZE, BUFFERS)
SELECT * FROM index_test WHERE (id || ' ' || category) = '1 category3';

Bitmap Heap Scan on index_test  (cost=12.29..1167.19 rows=500 width=60) (actual time=0.032..0.034 rows=1 loops=1)
  Recheck Cond: ((((id)::text || ' '::text) || category) = '1 category3'::text)
  Heap Blocks: exact=1
  Buffers: shared hit=4
  ->  Bitmap Index Scan on idx_id_cat  (cost=0.00..12.17 rows=500 width=0) (actual time=0.027..0.027 rows=1 loops=1)
        Index Cond: ((((id)::text || ' '::text) || category) = '1 category3'::text)
        Buffers: shared hit=3
Planning Time: 0.150 ms
Execution Time: 0.063 ms

-- используется сканирование по битовой карте
```


>> Создать индекс на несколько полей

```
explain (ANALYZE, BUFFERS)
select * from index_test where id < 100 and category ='category1';

Seq Scan on index_test  (cost=10000000000.00..10000003470.00 rows=33156 width=60) (actual time=91.024..100.815 rows=33102 loops=1)
  Filter: ((id > 100) AND (category = 'category1'::text))
  Rows Removed by Filter: 66898
  Buffers: shared hit=1970
Planning Time: 0.096 ms
JIT:
  Functions: 2
  Options: Inlining true, Optimization true, Expressions true, Deforming true
  Timing: Generation 0.883 ms, Inlining 19.248 ms, Optimization 59.142 ms, Emission 12.121 ms, Total 91.394 ms
Execution Time: 103.197 ms

-- jit_above_cost>100000 - применяется jit-компиляция
```

**Смотрим корреляцию по колонкам
select attname,correlation  from pg_stats where tablename='index_test';
```
id	1.0
txt	0.82223326
category	0.32974467
category_lexeme	
-- высокая корреляция по id
-- по category относительно низкая корреляция - можно добавить в include
```

**Создаём индекс, смотрим explain**
```
create index concurrently idx_idcat on index_test(id) include(category);

explain (ANALYZE, BUFFERS)
select * from index_test where id < 100 and category ='category1';

Index Scan using idx_idcat on index_test  (cost=0.42..11.40 rows=33 width=60) (actual time=0.016..0.057 rows=31 loops=1)
  Index Cond: (id < 100)
  Filter: (category = 'category1'::text)
  Rows Removed by Filter: 68
  Buffers: shared hit=5
Planning:
  Buffers: shared hit=17 read=1
  I/O Timings: shared/local read=0.008
Planning Time: 0.290 ms
Execution Time: 0.079 ms

-- применено индексное сканирование с диска
```


