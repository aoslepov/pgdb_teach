LESSON 9 LOCKS

### Lightweight Lock, LWLock - используется только ядро субд
Монопольный (W) и разделяемый (R) режимы
+ Очередь ожидания
+ Мониторинг
− Нет обнаружения взаимоблокировок

```
=> SELECT pid, backend_type, wait_event_type, wait_event FROM pg_stat_activity;

pid | backend_type   | wait_event_type | wait_event
----+----------------+-----------------+----------------
123 | walwriter      | LWLock          | WALWriteLock
234 | client backend | LWLock          | buffer_mapping
```

buffer_mapping_lock - блокировка хеш таблицы буфферного кеша

### Обычные (тяжелые) блокировки

Lock, Heavyweight Lock
Множество типов, множество режимов, разные задачи
+ Честная очередь ожидания
+ Мониторинг

pg_locks, pg_stat_activity

+ Обнаружение взаимоблокировок

**Блокировка номера транзакции**
- каждая транзакция в монопольном режиме удерживает свой номер
- Способ подождать завершения транзакции

второй процесс пытается захватить блокировку номера в первом процессе, засыпает и будет разбужен когда первая транзакция завершиться
```
=> SELECT pid, locktype, virtualxid AS virtxid,transactionid AS xid, mode, granted FROM pg_locks;
pid | locktype      | virtxid | xid   | mode          | granted
----+---------------+---------+-------+---------------+---------
123 | virtualxid    | 3/16    |       | ExclusiveLock | t
123 | transactionid |         | 98765 | ExclusiveLock | t
234 | transactionid |         | 98765 | ShareLock     | f
```

**Расширение отношения**

Добавление страниц к таблице, индексу и т. п. на время добавления новых страниц в памяти
```
=> SELECT pid, locktype, relation::regclass, mode, granted FROM pg_locks;

pid | locktype | relation | mode          | granted
----+----------+----------+---------------+---------
123 | extend   | t        | ExclusiveLock | t
```

**Блокировки отношений**

Различные операции с отношениями, 8 режимов
```
=> SELECT pid, locktype, relation::regclass, mode, granted FROM pg_locks;

pid | locktype | relation | mode             | granted
----+----------+----------+------------------+---------
123 | relation | t        | AccessShareLock  | t
234 | relation | t        | RowExclusiveLock | t
```

**Режимы и совместимость**

```
Access Share - SELECT
Row Share - SELECT FOR UPDATE/SHARE
Row Exclusive - UPDATE, DELETE, INSERT
Share Update Exclusive - VACUUM, CREATE INDEX CONCURRENTLY
Share - CREATE INDEX
Share Row - Exclusive CREATE TRIGGER
Exclusive - REFRESH MATERIALIZED VIEW CONCURRENTLY
Access Exclusive - DROP, TRUNCATE, VACUUM FULL, REFRESH MATERIALIZED VIEW
```


*Честная очередь*

Невовремя выполненная команда парализует систему
lock_timeout - максимальное время захвата блокировки для сессии
```
=> SELECT pid, query, pg_blocking_pids(pid) AS blocking FROM pg_stat_activity;
```

<image src="img/lock1.png">


**Блокировки на уровне строк**

Проблема: потенциально большое количество
а) Повышение уровня при превышении порога
теряется эффективность
б) Признак блокировки в странице данных (PostgreSQL)
сложность организации очереди ожидания,
для которой надо использовать нормальную блокировку
