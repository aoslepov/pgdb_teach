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

---
