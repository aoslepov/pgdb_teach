## Работа с postgresql на физическом уровне


### postgres server process (aka postmaster)
> первый процесс postgres, запускается при старте сервиса, порождает все остальные процессы, создает shared memory, слушает TCP и Unix socket

<image src="img/server_process.png">

<image src="img/server_process_shared_memory.png">

### backend processes (aka postgres)
> запускается postmaster, обслуживает сессию, работает пока сессия активна, максимальное количество определяется параметром max_connections

<image src="img/server_process_backends.png">


> logger (запись сообщений в лог файл)
> checkpointer (запись грязных страниц из buffer cache на диск при наступлении checkpoint)
> bgwriter (проактивная запись грязных страниц из buffer cache на диск)
> walwriter (запись wal buffer в wal file)
> autovacuum (периодический запуск autovacuum)
> archiver (архивация и репликация WAL)
> statscollector (сбор статистики использования по сессиям и таблицам)


### session

> принадлежит backend процессу
> work_mem (4 MB) -эта память используется на этапе выполнения запроса для сортировок строк, например ORDER BY и DISTINCT
> maintenance_work_mem (64MB) - используется служебными операциями типа VACUUM и REINDEX выделяется только при использовании команд обслуживания в сессии
> temp_buffers (8 MB) - используется на этапе выполнения для хранения временных таблиц


<image src="img/server_process_query.png">

**Parser > Analyser > Rewriter > Planner Executor**

https://postgrespro.ru/docs/postgresql/15/rule-system


### tables

> для каждой таблицы создается до 3-х файлов, каждый до 1 Гб, если превышает, то создается файл NNN.1 NNN.2 и т.д. также для FSM и VM:
> • файл с данными - OID таблицы
> • файл со свободными блоками - OID_fsm - отмечает свободное пространство в страницах после очистки используется при вставке новых версий строк существует для всех объектов
> • файл с таблицей видимости - OID_vm отмечает страницы, на которых все версии строк видны во всех снимках
> используется для оптимизации работы процесса очистки и ускорения индексного доступа существует только для таблиц иными словами, это страницы, которые давно не изменялись и успели полностью
очиститься от неактуальных версий 

<image src="img/server_process_tables.png">


### toast 
> Версия строки должна помещаться на одну страницу
> можно сжать часть атрибутов, или вынести в отдельную TOAST-таблицу, или сжать и вынести одновременно 

**TOAST-таблица**
>  схема pg_toast поддержана собственным индексом, «длинные» атрибуты разделены на части размером меньше страницы
>  читается только при обращении к «длинному» атрибуту собственная версионность (если при обновлении toast часть не меняется, то и не будет создана новая версия toast части)
>  работает прозрачно для приложения
>  стоит задуматься, когда пишем select *


### psql_history и логироание ddl админов


> Файл $HOME/.psql_history в Postgres содержит историю всех команд, введенных в интерактивной оболочке psql. По умолчанию, в этом файле сохраняется только текст команд, без информации о времени и пользователе, который ввел команду. 
> Однако, вы можете изменить поведение psql с помощью установки параметра HISTCONTROL. Например, чтобы сохранять в файле $HOME/.psql_history информацию о времени и пользователе, вы можете добавить следующие строки в файл $HOME/.bashrc, который будет выполняться при запуске нового терминала:

```
export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=1000000
export HISTFILESIZE=2000000
export PROMPT_COMMAND='echo "date "+%Y-%m-%d %T" | whoami | head -1 >> ~/.psql_history'
```

>Первые три строки устанавливают размеры истории и файла истории. Последняя строка добавляет команду echo в переменную PROMPT_COMMAND, которая будет выполняться перед каждым новым приглашением в терминале. Эта команда добавляет в файл $HOME/.psql_history текущую дату и время, имя пользователя и имя хоста, на котором была введена команда.
>После того, как вы добавите эти строки в файл $HOME/.bashrc, необходимо перезапустить терминал, чтобы изменения вступили в силу. После этого, все команды, введенные в интерактивной оболочке psql, будут сохраняться в файле $HOME/.psql_history вместе с информацией о времени и пользователе.
