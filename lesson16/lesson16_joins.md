## LESSON 16 JOIN

#### nested loop
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

#### hash match join
```
Соединение по внешнему ключу без индекса при поиске совпадений в хэше
Этап build - создание в памяти хеш-таблицы по первой таблице соединения
Этап probe - проход по второй таблицы соединения и сравнивание хешей первой и второй таблиц

explain analyse
select a.attrelid
    from pg_class c
        join pg_attribute a on c.oid = a.attrelid;
------------
Hash Join  (cost=23.32..123.39 rows=3089 width=4) (actual time=0.247..2.177 rows=3089 loops=1)
  Hash Cond: (a.attrelid = c.oid)
  ->  Seq Scan on pg_attribute a  (cost=0.00..91.89 rows=3089 width=4) (actual time=0.007..0.606 rows=3089 loops=1)
  ->  Hash  (cost=18.14..18.14 rows=414 width=4) (actual time=0.230..0.231 rows=414 loops=1)
        Buckets: 1024  Batches: 1  Memory Usage: 23kB
        ->  Seq Scan on pg_class c  (cost=0.00..18.14 rows=414 width=4) (actual time=0.006..0.112 rows=414 loops=1)
Planning Time: 0.362 ms
Execution Time: 2.460 ms

backets - кол-во построенных бакетов
batches - кол-во проходов (1 - поместились в workmem)
```

![hash match join](img/Hash_Match_Join.gif)

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

![hash match join](img/Merge_join.gif)


*Логирование темповых запросов*
```
logging_collector=on ##need restart
log_temp_files=0
```
### Латеральный соединения
```
drop table t_product;
CREATE TABLE t_product AS
    SELECT   id AS product_id,
             id * 10 * random() AS price,
             'product ' || id AS product
    FROM generate_series(1, 1000) AS id;

drop table t_wishlist;
CREATE TABLE t_wishlist
(
    wishlist_id        int,
    username           text,
    desired_price      numeric
);

INSERT INTO t_wishlist VALUES
    (1, 'hans', '450'),
    (2, 'joe', '60'),
    (3, 'jane', '1500');

SELECT * FROM t_product LIMIT 10;
SELECT * FROM t_wishlist;


-- вывести топ 5 товаров, которые мог позволить каждый их таблицы t_whishlist

explain
SELECT        *
FROM      t_wishlist AS w
    left join LATERAL  (SELECT      *
        FROM       t_product AS p
        WHERE       p.price < w.desired_price
        ORDER BY p.price DESC
        LIMIT 5
       ) AS x
on true -- заглушка для условия left join
ORDER BY wishlist_id, price DESC;



SELECT        *
FROM      t_wishlist AS w,
    LATERAL  (SELECT      *
        FROM       t_product AS p
        WHERE       p.price < w.desired_price
        ORDER BY p.price DESC
        LIMIT 5
       ) AS x
ORDER BY wishlist_id, price DESC;
```


*пример латеральных соединений*
```

--создаём таблицу с температурой и влажностью по городам
create table temperature(
ts TIMESTAMP not null,
city text not null,
temperature int not null);

create table humidity (
ts TIMESTAMP not null,
city text not null,
humidity int not null);
);


insert into temperature  (ts,city,temperature) 
select ts + (interval '60 minutes' * random()),city,30*random()
from generate_series('2023-01-01'::timestamp,'2023-01-31'::timestamp, '1 day') as ts,
unnest(array['Moscow','Berlin','Volgograd']) as city;

insert into humidity  (ts,city,humidity) 
select ts + (interval '60 minutes' * random()),city,100*random()
from generate_series('2023-01-01'::timestamp,'2023-01-31'::timestamp, '1 day') as ts,
unnest(array['Moscow','Berlin','Volgograd']) as city;


select * from temperature ;
select * from humidity ;


-- соединить таблицы не получится - время разное
select t.ts,t.city,t.temperature, h.humidity
from temperature as t 
left join humidity as h on t.ts=h.ts;


-- для каждого города выбираем значение влажности пришедшему по времени <=таблицы температуры
select t.ts,t.city,t.temperature, h.humidity
from temperature as t
left join lateral (
select * from humidity  
where city=t.city and ts <=t.ts
order by ts desc limit 1
) as h 
on true 
where t.ts < '2023-01-10';


2023-01-01 00:13:08.260	Moscow	        4	78
2023-01-02 00:25:13.767	Moscow	        13	18
2023-01-03 00:37:22.711	Moscow	        11	49
2023-01-04 00:42:30.462	Moscow	        11	16
2023-01-05 00:24:20.646	Moscow	        5	63
2023-01-06 00:53:37.733	Moscow	        19	63
2023-01-07 00:32:41.586	Moscow	        26	82
2023-01-08 00:24:54.275	Moscow	        21	69
2023-01-09 00:25:56.056	Moscow	        18	42
2023-01-01 00:31:11.733	Berlin	        15	36
2023-01-02 00:38:56.453	Berlin	        4	36
2023-01-03 00:39:09.385	Berlin	        16	75
2023-01-04 00:13:03.512	Berlin	        2	46
2023-01-05 00:07:22.650	Berlin	        17	77
2023-01-06 00:13:15.779	Berlin	        11	97
2023-01-07 00:12:21.613	Berlin	        14	2
2023-01-08 00:52:16.847	Berlin	        29	39
2023-01-09 00:57:04.957	Berlin     	22	53
2023-01-01 00:50:29.143	Volgograd	27	65
2023-01-02 00:47:55.884	Volgograd	9	32
2023-01-03 00:42:25.104	Volgograd	7	32
2023-01-04 00:58:46.656	Volgograd	5	82
2023-01-05 00:02:45.094	Volgograd	6	33
2023-01-06 00:46:15.406	Volgograd	13	33
2023-01-07 00:18:05.588	Volgograd	5	37
2023-01-08 00:10:48.653	Volgograd	11	19
2023-01-09 00:19:52.233	Volgograd	11	19
```

join_collapse_limit = 8 -- максимальное кол-во джоинов для составления плана запроса без генетического алгоритма 


### Множества
```
DROP TABLE IF EXISTS top_rated_films;
CREATE TABLE top_rated_films(
	title VARCHAR NOT NULL,
	release_year SMALLINT
);

DROP TABLE IF EXISTS most_popular_films;
CREATE TABLE most_popular_films(
	title VARCHAR NOT NULL,
	release_year SMALLINT
);

INSERT INTO
   top_rated_films(title,release_year)
VALUES
   ('The Shawshank Redemption',1994),
   ('The Godfather',1972),
   ('12 Angry Men',1957);

INSERT INTO
   most_popular_films(title,release_year)
VALUES
   ('An American Pickle',2020),
   ('The Godfather',1972),
   ('Greyhound',2020);

SELECT * FROM top_rated_films;
select * from most_popular_films;

-- объединение исключая дубли
SELECT * FROM top_rated_films
UNION
SELECT * FROM most_popular_films;

-- объединение включая дубли
SELECT * FROM top_rated_films
UNION all
SELECT * FROM most_popular_films;

-- разность множеств (вывести дубли)
SELECT * FROM top_rated_films
INTERSECT
SELECT * FROM most_popular_films;


-- вычитание множеств
SELECT * FROM top_rated_films
EXCEPT
SELECT * FROM most_popular_films;
```

---
