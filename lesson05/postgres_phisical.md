## Работа с postgresql на физическом уровне


#### postgres server process (aka postmaster)
> первый процесс postgres, запускается при старте сервиса, порождает все остальные процессы, создает shared memory, слушает TCP и Unix socket

<image src="img/server_process.png">

<image src="img/server_process_shared_memory.png">

#### backend processes (aka postgres)
> запускается postmaster, обслуживает сессию, работает пока сессия активна, максимальное количество определяется параметром max_connections

<image src="img/server_process_backends.png">


> logger (запись сообщений в лог файл)
> checkpointer (запись грязных страниц из buffer cache на диск при наступлении checkpoint)
> bgwriter (проактивная запись грязных страниц из buffer cache на диск)
> walwriter (запись wal buffer в wal file)
> autovacuum (периодический запуск autovacuum)
> archiver (архивация и репликация WAL)
> statscollector (сбор статистики использования по сессиям и таблицам)


##### session

> принадлежит backend процессу
> work_mem (4 MB) -эта память используется на этапе выполнения запроса для сортировок строк, например ORDER BY и DISTINCT
> maintenance_work_mem (64MB) - используется служебными операциями типа VACUUM и REINDEX выделяется только при использовании команд обслуживания в сессии
> temp_buffers (8 MB) - используется на этапе выполнения для хранения временных таблиц


<image src="img/server_process_query.png">

Parser > Analyser > Rewriter > Planner Executor


https://postgrespro.ru/docs/postgresql/15/rule-system



