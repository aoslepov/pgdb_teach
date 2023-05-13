### Буфферы и журналы

#### buffers

```
**shared_buffers=25%** ОЗУ
- usage count - кол-во обращений к буфферу
- pin count - запросы на использование данных в буффере

--
для массовых операций используется буфферное кольцо

последовательное чтение (неск операций параллельно) - 32 страницы, грязные страницы исключаются из кольца
vacuum - 32 стр, грязные страницы вытесняются на диск
массовая запись - <=2048 стр,  грязные страницы вытесняются на диск
```

```
-- анализ буфферного кэша
create extension pg_buffercache;


-- вьюха для удобного просмотра буфферного кеша
CREATE VIEW pg_buffercache_v AS
SELECT bufferid,
       (SELECT c.relname FROM pg_class c WHERE  pg_relation_filenode(c.oid) = b.relfilenode ) relname,
       CASE relforknumber
         WHEN 0 THEN 'main' -- data
         WHEN 1 THEN 'fsm'  -- free space map
         WHEN 2 THEN 'vm'   -- visibility map
       END relfork,
       relblocknumber,
       isdirty,
       usagecount
FROM   pg_buffercache b
WHERE  b.relDATABASE IN (    0, (SELECT oid FROM pg_DATABASE WHERE datname = current_database()) )
AND    b.usagecount is not null;

SELECT * FROM pg_buffercache_v WHERE relname='test';

-- предпрогрев буффера
create extension pg_prewarm;
select pg_prewarm('test_text');
```

https://habr.com/ru/companies/postgrespro/articles/458186/

#### WAL

```
состоит из: crc,N транзакции, длина блока, ссылка на текущий и на предыдущий блоки, менеджер ресурсов

-- спискок менеджеров ресурсов
/usr/lib/postgresql/15/bin/pg_waldump -r list


pg_current_wal_insert_lsn() -- указатель на место вставки данных
pg_current_wal_lsn() -- указатель на место чтения данных
pg_current_wal_insert_lsn()-pg_current_wal_lsn() -- информация не сброшенная на диск

-- в shared buffers изменяется страница (lsn)
-- в wal xact изменений (lsn)
-- commit - сбрасывает в бд shared_buffer и wal
-- при сбое проигрывыются данные в wal, которые больше lsn бд


-- список wal файлов
SELECT * FROM pg_ls_waldir() LIMIT 10;


-- инфа про lsn
create extension page_inspect;
select pg_current_wal_insert_lsn(); -- текущая позиция
SELECT pg_walfile_name('0/1A1B9F0');  -- получить имя wal-файла для неё
SELECT lsn FROM page_header(get_raw_page('test_text',0)); -- получить lsn


-- размер данных в wal в байтах между позициями в журнале
SELECT '0/1A24FE0'::pg_lsn - '0/1A1DFD8'::pg_lsn;

-- вывести дамп данных в wal
sudo /usr/lib/postgresql/15/bin/pg_waldump -p /var/lib/postgresql/15/main/pg_wal -s 0/1A1DFD8 -e 0/1A24FE0 000000010000000000000001
rmgr: Heap2       len (rec/tot):     59/  4875, tx:        746, lsn: 0/01A1DFD8, prev 0/01A1DFA0, desc: PRUNE latestRemovedXid 0 nredirected 0 ndead 9, blkref #0: rel 1663/16388/1255 blk 95 FPW
rmgr: Heap2       len (rec/tot):     59/  7819, tx:        746, lsn: 0/01A1F300, prev 0/01A1DFD8, desc: PRUNE latestRemovedXid 0 nredirected 0 ndead 1, blkref #0: rel 1663/16388/1255 blk 18 FPW
rmgr: Heap2       len (rec/tot):     59/  7991, tx:        746, lsn: 0/01A211A8, prev 0/01A1F300, desc: PRUNE latestRemovedXid 0 nredirected 0 ndead 1, blkref #0: rel 1663/16388/1255 blk 19 FPW
rmgr: Standby     len (rec/tot):     54/    54, tx:          0, lsn: 0/01A230F8, prev 0/01A211A8, desc: RUNNING_XACTS nextXid 747 latestCompletedXid 745 oldestRunningXid 746; 1 xacts: 746
rmgr: Heap2       len (rec/tot):     59/  7731, tx:        746, lsn: 0/01A23130, prev 0/01A230F8, desc: PRUNE latestRemovedXid 0 nredirected 0 ndead 1, blkref #0: rel 1663/16388/1255 blk 25 FPW
rmgr: Standby     len (rec/tot):     54/    54, tx:          0, lsn: 0/01A24F80, prev 0/01A23130, desc: RUNNING_XACTS nextXid 747 latestCompletedXid 745 oldestRunningXid 746; 1 xacts: 746
rmgr: Transaction len (rec/tot):     34/    34, tx:        746, lsn: 0/01A24FB8, prev 0/01A24F80, desc: COMMIT 2023-05-13 17:05:36.216023 UTC

```

#### CHECKPOINT


*принудительный сброс буфферов, в т.ч. и грязных, на диск*
```

checkpoint_timeout=5min; --промежуток контрольных точек
checkpoint_completion_target=0.8 -- коэфициент выполнения чекпоинта по отрезку checkpoint_timeout для размазывания нагрузки

-- после завершения чекпоинта в журнале появляется запись с указанием времени начала кт
latest_checkpoint_location:___ 

$PGDATA/global/pg_control --инфо о последней контролькой точке

При старте сервера после сбоя
1. найти LSN0 начала последней завершенной контрольной точки
2. применить каждую запись журнала, начиная с LSN0 , если LSN записи
больше, чем LSN страницы
3. перезаписать нежурналируемые таблицы init-файлами
4. выполнить контрольную точку
```

*checkpoint*
```
root@pg-teach-01:/var/lib/postgresql/15/main/pg_wal# sudo /usr/lib/postgresql/15/bin/pg_waldump -p /var/lib/postgresql/15/main/pg_wal -s 0/1A1DFD8 -e 0/1A271A0 000000010000000000000001
rmgr: Heap2       len (rec/tot):     59/  4875, tx:        746, lsn: 0/01A1DFD8, prev 0/01A1DFA0, desc: PRUNE latestRemovedXid 0 nredirected 0 ndead 9, blkref #0: rel 1663/16388/1255 blk 95 FPW
rmgr: Heap2       len (rec/tot):     59/  7819, tx:        746, lsn: 0/01A1F300, prev 0/01A1DFD8, desc: PRUNE latestRemovedXid 0 nredirected 0 ndead 1, blkref #0: rel 1663/16388/1255 blk 18 FPW
rmgr: Heap2       len (rec/tot):     59/  7991, tx:        746, lsn: 0/01A211A8, prev 0/01A1F300, desc: PRUNE latestRemovedXid 0 nredirected 0 ndead 1, blkref #0: rel 1663/16388/1255 blk 19 FPW
rmgr: Standby     len (rec/tot):     54/    54, tx:          0, lsn: 0/01A230F8, prev 0/01A211A8, desc: RUNNING_XACTS nextXid 747 latestCompletedXid 745 oldestRunningXid 746; 1 xacts: 746
rmgr: Heap2       len (rec/tot):     59/  7731, tx:        746, lsn: 0/01A23130, prev 0/01A230F8, desc: PRUNE latestRemovedXid 0 nredirected 0 ndead 1, blkref #0: rel 1663/16388/1255 blk 25 FPW
rmgr: Standby     len (rec/tot):     54/    54, tx:          0, lsn: 0/01A24F80, prev 0/01A23130, desc: RUNNING_XACTS nextXid 747 latestCompletedXid 745 oldestRunningXid 746; 1 xacts: 746
rmgr: Transaction len (rec/tot):     34/    34, tx:        746, lsn: 0/01A24FB8, prev 0/01A24F80, desc: COMMIT 2023-05-13 17:05:36.216023 UTC
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/01A24FE0, prev 0/01A24FB8, desc: RUNNING_XACTS nextXid 747 latestCompletedXid 746 oldestRunningXid 747
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/01A25018, prev 0/01A24FE0, desc: RUNNING_XACTS nextXid 747 latestCompletedXid 746 oldestRunningXid 747
rmgr: XLOG        len (rec/tot):    114/   114, tx:          0, lsn: 0/01A25050, prev 0/01A25018, desc: CHECKPOINT_ONLINE redo 0/1A25018; tli 1; prev tli 1; fpw true; xid 0:747; oid 24600; multi 1; offset 0; oldest xid 716 in DB 1; oldest multi 1 in DB 1; oldest/newest commit timestamp xid: 0/0; oldest running xid 747; online
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/01A250C8, prev 0/01A25050, desc: RUNNING_XACTS nextXid 747 latestCompletedXid 746 oldestRunningXid 747
rmgr: Heap2       len (rec/tot):     59/  7803, tx:          0, lsn: 0/01A25100, prev 0/01A250C8, desc: PRUNE latestRemovedXid 0 nredirected 0 ndead 1, blkref #0: rel 1663/16388/1255 blk 61 FPW
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/01A26F98, prev 0/01A25100, desc: RUNNING_XACTS nextXid 747 latestCompletedXid 746 oldestRunningXid 747
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/01A26FD0, prev 0/01A26F98, desc: RUNNING_XACTS nextXid 747 latestCompletedXid 746 oldestRunningXid 747
rmgr: XLOG        len (rec/tot):    114/   114, tx:          0, lsn: 0/01A27008, prev 0/01A26FD0, desc: CHECKPOINT_ONLINE redo 0/1A26FD0; tli 1; prev tli 1; fpw true; xid 0:747; oid 24600; multi 1; offset 0; oldest xid 716 in DB 1; oldest multi 1 in DB 1; oldest/newest commit timestamp xid: 0/0; oldest running xid 747; online
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/01A27080, prev 0/01A27008, desc: RUNNING_XACTS nextXid 747 latestCompletedXid 746 oldestRunningXid 747
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/01A270B8, prev 0/01A27080, desc: RUNNING_XACTS nextXid 747 latestCompletedXid 746 oldestRunningXid 747
rmgr: XLOG        len (rec/tot):    114/   114, tx:          0, lsn: 0/01A270F0, prev 0/01A270B8, desc: CHECKPOINT_ONLINE redo 0/1A270B8; tli 1; prev tli 1; fpw true; xid 0:747; oid 24600; multi 1; offset 0; oldest xid 716 in DB 1; oldest multi 1 in DB 1; oldest/newest commit timestamp xid: 0/0; oldest running xid 747; online
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/01A27168, prev 0/01A270F0, desc: RUNNING_XACTS nextXid 747 latestCompletedXid 746 oldestRunningXid 747


--- посмореть статус сервера при сбое
/usr/lib/postgresql/15/bin/pg_controldata /var/lib/postgresql/15/main
```

*настройки конфига*
```
checkpoint_timeout = 5min        -- таймаут чекпоинта
max_wal_size = 1GB               -- предельный размер wal журнала (soft)
checkpoint_completion_target=0.8 -- коэфициент размазывания нагрузки по сегменту таймаута
min_wal_size = 100MB             -- минимальный размер wal, до этого не выполниются чекпоинты
wal_keep_segments = 0            -- кол-во сегментов(сегмент - 16МБ), хранимых для реплики. 

Сервер хранит журнальные файлы необходимые для восстановления:
• (2 (1 с 12 версии) + checkpoint_completion_target) * max_wal_size
• еще не прочитанные через слоты репликации
• еще не записанные в архив, если настроена непрерывная архивация
• не превышающие по объему минимальной отметки


```

*Асинхронный wal*
```
выполняет bgwriter

synchronous_commit=on -- включение асинхронного wal

-- Настройки
bgwriter_delay = 200ms
bgwriter_lru_maxpages = 100
bgwriter_lru_multiplier = 2.0
-- Алгоритм
• уснуть на bgwriter_delay
• если в среднем за цикл запрашивается N буферов, то записать
N * bgwriter_lru_multiplier ≤ bgwriter_lru_maxpages грязных буферов

```

*Уровни журнала*
```
Minimal
восстановление после сбоя
Replica
восстановление из резервной копии, репликация
+ операции массовой обработки данных, блокировки
Logical
логическая репликация
+ информация для логического декодирования
Настройка
wal_level = replica
```

*Синхронизация с диском*
```
данные должны дойти до энергонезависимого хранилища через многочисленные
кэши. СУБД сообщает операционной системе способом, указанным в wal_sync_method
надо учитывать аппаратное кэширование
-- Настройки
fsync = on
show fsync;
show wal_sync_method;
-- утилита pg_test_fsync помогает выбрать оптимальный способ
```

*Контрольные суммы*
```
Контрольные суммы журнальных записей
включены всегда, CRC-32
Контрольные суммы страниц (накладные расходы)
По умолчанию отключены. До 12 версии можно включить только при
инициализации кластера.
pg_createcluster --data-checksums
-- Настройки
show data_checksums;
ignore_checksum_failure = off
wal_log_hints = off (записывает все содержимое каждой страницы при
измениях даже инф.бит, неявно on при контрольных суммах страниц)
wal_compression = off
```

https://postgrespro.ru/docs/postgrespro/13/app-pgchecksums

*Характер нагрузки*
```
Постоянный поток записи
- характер нагрузки отличается от остальной системы
- последовательная запись, отсутствие случайного доступа
- при высокой нагрузке — размещение на отдельных физических дисках
(символьная ссылка из $PGDATA/pg_wal)
Редкое чтение
- при восстановлении
- при работе процессов walsender, если реплика не успевает быстро
получать записи
```

*Режим синхронной записи*
```
Алгоритм
при фиксации изменений сбрасывает накопившиеся записи, включая
запись о фиксации ждет commit_delay, если активно не менее commit_siblings транзакций
Характеристики
+ гарантируется долговечность
+ увеличивается время отклика
-- Настройки
synchronous_commit = on
commit_delay = 0
commit_siblings = 5
```

*Режим асинхронной записи*
```
-- Алгоритм
циклы записи через wal_writer_delay
записывает только целиком заполненные страницы
но если новых полных страниц нет, то записывает последнюю до конца
-- Характеристики
+ гарантируется согласованность, но не долговечность
+ зафиксированные изменения могут пропасть (3 × wal_writer_delay)
+ уменьшается время отклика
-- Настройки
synchronous_commit = off (можно изменять на уровне транзакции)
wal_writer_delay = 200ms
```




