Домашнее задание
Механизм блокировок

Цель:
понимать как работает механизм блокировок объектов и строк


Описание/Пошаговая инструкция выполнения домашнего задания:
Настройте сервер так, чтобы в журнал сообщений сбрасывалась информация о блокировках, удерживаемых более 200 миллисекунд. Воспроизведите ситуацию, при которой в журнале появятся такие сообщения.
Смоделируйте ситуацию обновления одной и той же строки тремя командами UPDATE в разных сеансах. Изучите возникшие блокировки в представлении pg_locks и убедитесь, что все они понятны. Пришлите список блокировок и объясните, что значит каждая.
Воспроизведите взаимоблокировку трех транзакций. Можно ли разобраться в ситуации постфактум, изучая журнал сообщений?
Могут ли две транзакции, выполняющие единственную команду UPDATE одной и той же таблицы (без where), заблокировать друг друга?
Задание со звездочкой*
Попробуйте воспроизвести такую ситуацию.


> Настройте сервер так, чтобы в журнал сообщений сбрасывалась информация о блокировках, удерживаемых более 200 миллисекунд. Воспроизведите ситуацию, при которой в журнале появятся такие сообщения

```
-- подготавливаем таблицу
CREATE TABLE accounts(
  acc_no integer PRIMARY KEY,
  amount numeric
);
INSERT INTO accounts VALUES (1,1000.00), (2,2000.00), (3,3000.00);


--настраиваем postgres
alter system set log_lock_waits to 'on';
alter system set log_min_duration_statement to 200;
alter system set deadlock_timeout to '1s';
select pg_reload_conf();

-- вызываем долгую транзакцию
begin
update accounts set amount=amount+2 where acc_no=1;


-- смотрим лог
2023-05-05 11:48:57.536 UTC [132] STATEMENT:  update accounts set amount=amount+2 where acc_no=1;
2023-05-05 11:49:08.519 UTC [336] LOG:  process 336 still waiting for ExclusiveLock on tuple (0,1) of relation 21449 of database 21439 after 1000.126 ms
2023-05-05 11:49:08.519 UTC [336] DETAIL:  Process holding the lock: 132. Wait queue: 336.
```

> Смоделируйте ситуацию обновления одной и той же строки тремя командами UPDATE в разных сеансах. Изучите возникшие блокировки в представлении pg_locks и убедитесь, что все они понятны. Пришлите список блокировок и объясните, что значит каждая.

session1>>
```
begin;
lock=*# SELECT pg_backend_pid();
 pg_backend_pid
----------------
            290
lock=*# update accounts set amount=amount+1 where acc_no=1;
UPDATE 1

```

session2>>
```
lock=# begin;
lock=*# SELECT pg_backend_pid();
 pg_backend_pid
----------------
            132
update accounts set amount=amount+2 where acc_no=1;

```

session3>>
```
lock=# begin;
lock=*# SELECT pg_backend_pid();
 pg_backend_pid
----------------
            336

update accounts set amount=amount+3 where acc_no=1;
```

session4>>
```
lock=# begin;
lock=*# SELECT pg_backend_pid();
 pg_backend_pid
----------------
            747
(1 row)

lock=*# update accounts set amount=amount+4 where acc_no=1;
```


смотрим список блокировок
```
lock=# SELECT locktype, relation::REGCLASS, mode, granted, pid, pg_blocking_pids(pid) AS wait_for FROM pg_locks WHERE relation = 'accounts'::regclass order by pid;
 locktype | relation |       mode       | granted | pid | wait_for
----------+----------+------------------+---------+-----+-----------
 relation | accounts | RowExclusiveLock | t       | 132 | {290}
 tuple    | accounts | ExclusiveLock    | t       | 132 | {290}
 relation | accounts | RowExclusiveLock | t       | 290 | {}
 tuple    | accounts | ExclusiveLock    | f       | 336 | {132}
 relation | accounts | RowExclusiveLock | t       | 336 | {132}
 relation | accounts | RowExclusiveLock | t       | 747 | {132,336}
 tuple    | accounts | ExclusiveLock    | f       | 747 | {132,336}
(7 rows)

-- session pid txid1 = 290
-- session pid txid2 = 132
-- session pid txid3 = 336
-- session pid txid4 = 747
```


описание блокировок
```
--  транзакция txid1(290) поставила блокировку строки RowExclusiveLock на странице с данными 
--- и блокировку типа tupple в памяти
-- relation | accounts | RowExclusiveLock | t       | 290 | {}

-- транзакция txid2(132) поставила блокировку строки RowExclusiveLock на странице с данными 
-- и ссылается на tupple txid1(290)
--  relation | accounts | RowExclusiveLock | t       | 132 | {290}
--  tuple    | accounts | ExclusiveLock    | t       | 132 | {290}

-- транзакции txid3(336) и txid4(747) также  поставили блокировку строки RowExclusiveLock на странице с данными 
-- и ссылаются на tupple txid1(290)
-- tuple    | accounts | ExclusiveLock    | f       | 336 | {132}
-- relation | accounts | RowExclusiveLock | t       | 336 | {132}
-- relation | accounts | RowExclusiveLock | t       | 747 | {132,336}
-- tuple    | accounts | ExclusiveLock    | f       | 747 | {132,336}

```


commit в session1 txid1(290)
```
-- при коммите txid1(290) очередь перестраивается
-- блокировка  txid1(290) отпускается, txid2(132) позволяет захватить блокировку и сделать апдейт.
-- остальные транзакиции выстраиваются в очередь от  txid2(132) и засыпают

lock=# SELECT locktype, relation::REGCLASS, mode, granted, pid, pg_blocking_pids(pid) AS wait_for FROM pg_locks WHERE relation = 'accounts'::regclass order by pid;
 locktype | relation |       mode       | granted | pid | wait_for
----------+----------+------------------+---------+-----+----------
 relation | accounts | RowExclusiveLock | t       | 132 | {}
 relation | accounts | RowExclusiveLock | t       | 336 | {132}
 relation | accounts | RowExclusiveLock | t       | 747 | {132}
```


commit в session2 txid2(132)
```
-- при коммите txid2(132) тапл освобождается и очередь перестраивается заново
-- в данном случае, блокировку смогла захватить txid4(747) и tupple устанавливает она (соответвенно для неё разрешёна блокировка для update)
-- оставшаяся транзакция txid3(336) становится в очередь за ней


lock=# SELECT locktype, relation::REGCLASS, mode, granted, pid, pg_blocking_pids(pid) AS wait_for FROM pg_locks WHERE relation = 'accounts'::regclass order by pid;
 locktype | relation |       mode       | granted | pid | wait_for
----------+----------+------------------+---------+-----+----------
 relation | accounts | RowExclusiveLock | t       | 336 | {747}
 tuple    | accounts | ExclusiveLock    | t       | 336 | {747}
 relation | accounts | RowExclusiveLock | t       | 747 | {}
```


commit в session3 txid4(747)
```
 -- после коммита txid4(747) таппл захватывает txid3(336) (разрешёна блокировка для update)
 lock=# SELECT locktype, relation::REGCLASS, mode, granted, pid, pg_blocking_pids(pid) AS wait_for  FROM pg_locks WHERE relation = 'accounts'::regclass order by pid;
  locktype | relation |       mode       | granted | pid | wait_for
 ----------+----------+------------------+---------+-----+----------
  relation | accounts | RowExclusiveLock | t       | 336 | {}
```


> Воспроизведите взаимоблокировку трех транзакций. Можно ли разобраться в ситуации постфактум, изучая журнал сообщений?


каждая транзакция обновляет свою строку
```
-- открываем 3 сессии, каждая сессия обновляет всою строчку

-- session1 > pid(911) 

lock=# begin;
BEGIN
lock=*# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
            911
(1 row)

lock=*# update accounts set amount = 1000 where acc_no=1;
UPDATE 1
lock=*# SELECT locktype, relation::REGCLASS, mode, granted, pid, pg_blocking_pids(pid) AS wait_for
FROM pg_locks WHERE relation = 'accounts'::regclass order by pid;
 locktype | relation |       mode       | granted | pid | wait_for 
----------+----------+------------------+---------+-----+----------
 relation | accounts | RowExclusiveLock | t       | 911 | {}


-- session2 > pid(920)

lock=# begin;
BEGIN
lock=*# SELECT pg_backend_pid();
 pg_backend_pid
----------------
            920
lock=*# update accounts set amount = 1000 where acc_no=2;
UPDATE 1
lock=*# SELECT locktype, relation::REGCLASS, mode, granted, pid, pg_blocking_pids(pid) AS wait_for
FROM pg_locks WHERE relation = 'accounts'::regclass order by pid;
 locktype | relation |       mode       | granted | pid | wait_for 
----------+----------+------------------+---------+-----+----------
 relation | accounts | RowExclusiveLock | t       | 911 | {}
 relation | accounts | RowExclusiveLock | t       | 920 | {}


-- session3 > pid(1219)

lock=# begin;
BEGIN
lock=*# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
           1219
(1 row)

lock=*# update accounts set amount = 1000 where acc_no=3;
UPDATE 1
lock=*# SELECT locktype, relation::REGCLASS, mode, granted, pid, pg_blocking_pids(pid) AS wait_for
FROM pg_locks WHERE relation = 'accounts'::regclass order by pid;
 locktype | relation |       mode       | granted | pid  | wait_for 
----------+----------+------------------+---------+------+----------
 relation | accounts | RowExclusiveLock | t       |  911 | {}
 relation | accounts | RowExclusiveLock | t       |  920 | {}
 relation | accounts | RowExclusiveLock | t       | 1219 | {}

```

сессия 2 обновляет строку 3, а сессия 3 обновляет строку 1
```
-- session2 > pid(920)
-- обновляем acc_no=3. ожидает блокировки, т.к. она уже заблокирована pid(1219)
lock=*# update accounts set amount = 1000 where acc_no=3;

-- session3 > pid(1219) 
-- обновляем acc_no=1. ожидает блокировки, т.к. она уже заблокирована pid(911)
lock=* #update accounts set amount = 1000 where acc_no=1;
lock=# SELECT locktype, relation::REGCLASS, mode, granted, pid, pg_blocking_pids(pid) AS wait_for
FROM pg_locks WHERE relation = 'accounts'::regclass order by pid;
 locktype | relation |       mode       | granted | pid  | wait_for 
----------+----------+------------------+---------+------+----------
 relation | accounts | RowExclusiveLock | t       |  911 | {}
 relation | accounts | RowExclusiveLock | t       |  920 | {1219}
 tuple    | accounts | ExclusiveLock    | t       |  920 | {1219}
 relation | accounts | RowExclusiveLock | t       | 1219 | {911}
 tuple    | accounts | ExclusiveLock    | t       | 1219 | {911}
```


описание дедлока
```
-- session1 > pid(911)
-- обновляем acc_no=2 
-- pid(1219) ожидает освобождения блокировки от pid(920)
-- pid(220) ожидает освобождения блокировки от pid(1219)
-- при попытке pid(911) взять блокировку на строку, которая заблокирована pid(920) образуется взаимоблокировка (dead_lock)
-- транзакция trxid1(911) не может захватить блокировку в течении deadlock_timeout и вызывает процесс разрешения взаимоблокировок
-- в случае обнаружения взаимоблокировки postgres убивает процесс,который инициализировал поиск взаимоблокировки


lock=*# update accounts set amount = 1000 where acc_no=2;
ERROR:  deadlock detected
DETAIL:  Process 911 waits for ShareLock on transaction 860; blocked by process 920.
Process 920 waits for ShareLock on transaction 862; blocked by process 1219.
Process 1219 waits for ShareLock on transaction 858; blocked by process 911.
HINT:  See server log for query details.
CONTEXT:  while updating tuple (0,2) in relation "accounts"

-- при этом блокировака в session3 pid(1219) становится возможной, update выполнияетя
-- session2 pid(920) будет ожидать коммита в pid(1219)

lock=# SELECT locktype, relation::REGCLASS, mode, granted, pid, pg_blocking_pids(pid) AS wait_for
FROM pg_locks WHERE relation = 'accounts'::regclass order by pid;
 locktype | relation |       mode       | granted | pid  | wait_for 
----------+----------+------------------+---------+------+----------
 relation | accounts | RowExclusiveLock | t       |  920 | {1219}
 tuple    | accounts | ExclusiveLock    | t       |  920 | {1219}
 relation | accounts | RowExclusiveLock | t       | 1219 | {}

```




анализ лога

```
--- в данном логе транзакция trxid1(911) была убита, т.к. вызвала дедлок

2023-05-05 14:07:52.572 UTC [920] LOG:  process 920 still waiting for ShareLock on transaction 862 after 1000.202 ms
2023-05-05 14:07:52.572 UTC [920] DETAIL:  Process holding the lock: 1219. Wait queue: 920.
2023-05-05 14:07:52.572 UTC [920] CONTEXT:  while updating tuple (0,3) in relation "accounts"
2023-05-05 14:07:52.572 UTC [920] STATEMENT:  update accounts set amount = 1000 where acc_no=3;
2023-05-05 14:10:59.834 UTC [1219] LOG:  process 1219 still waiting for ShareLock on transaction 858 after 1000.077 ms
2023-05-05 14:10:59.834 UTC [1219] DETAIL:  Process holding the lock: 911. Wait queue: 1219.
2023-05-05 14:10:59.834 UTC [1219] CONTEXT:  while updating tuple (0,7) in relation "accounts"
2023-05-05 14:10:59.834 UTC [1219] STATEMENT:  update accounts set amount = 1000 where acc_no=1;
2023-05-05 14:14:44.320 UTC [911] LOG:  process 911 detected deadlock while waiting for ShareLock on transaction 860 after 1000.072 ms
2023-05-05 14:14:44.320 UTC [911] DETAIL:  Process holding the lock: 920. Wait queue: .
2023-05-05 14:14:44.320 UTC [911] CONTEXT:  while updating tuple (0,2) in relation "accounts"
2023-05-05 14:14:44.320 UTC [911] STATEMENT:  update accounts set amount = 1000 where acc_no=2;
2023-05-05 14:14:44.320 UTC [911] ERROR:  deadlock detected
2023-05-05 14:14:44.320 UTC [911] DETAIL:  Process 911 waits for ShareLock on transaction 860; blocked by process 920.
	Process 920 waits for ShareLock on transaction 862; blocked by process 1219.
	Process 1219 waits for ShareLock on transaction 858; blocked by process 911.
	Process 911: update accounts set amount = 1000 where acc_no=2;
	Process 920: update accounts set amount = 1000 where acc_no=3;
	Process 1219: update accounts set amount = 1000 where acc_no=1;
```
