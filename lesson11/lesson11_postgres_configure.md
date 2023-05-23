### LESSON 11 CONFIG_SERVERS
```
-- путь ко конфигу
show config_file;
-- функция current_setting
select current_setting('work_mem');


select * from pg_settings where name like  '%listen%';
select pg_reload_conf();

name            | listen_addresses
setting         | localhost
unit            | 
category        | Connections and Authentication / Connection Settings
short_desc      | Sets the host name or IP address(es) to listen to.
extra_desc      | 
context         | postmaster
vartype         | string
source          | default
min_val         | 
max_val         | 
enumvals        | 
boot_val        | localhost
reset_val       | localhost
sourcefile      | 
sourceline      | 
pending_restart | t


pending_restart - true - необходимость перезагрузки кластера

-- установленные значения раскомментированные
-- в том числе показывает необходимость рестарта и ошибки в конфиге

select * from pg_file_settings;
```

*установка и сброс значений в рамках коннекта (в begin для транзакции)*
```
-- установка для коннекта
set work_mem='128MB';
-- установка для транзакции
begin;
set work_mem='32MB';
commit;
-- сброс до значения reset_val в pg_settings
reset work_mem;
reset work_mem; 
```

**контесты параметоров**
```
select context,count(*) from pg_settings group by context order by 2 desc;
      context      | count 
-------------------+-------
 user              |   135 - конфиг для сеансов любых юзеров
 sighup            |    92 - конфиг требует релоада
 postmaster        |    55 - корфиг требует рестарта
 superuser         |    45 - конфиг меняется только суперпользователями
 internal          |    20 - конфигурировано при инициализации кластера
 superuser-backend |     4 - настройка будет применена для всех сеансов суперюзера после текущего
 backend           |     2 - настройка будет применена для всех сеансов после текущего
   

select set_config('work_mem','16MB',true); -- установка текущего значения для транзакции
select set_config('work_mem','16MB',false); -- установка текущего значения для сеанса
```

**параметры для баз и юзеров**
```
create database test;
alter database test set work_mem='128MB';

create user test with password 'test' login;
alter user test set work_mem='128MB';

-- параметры заданные на уровне юзеров/ролей
SELECT coalesce(role.rolname, 'database wide') as role,
       coalesce(db.datname, 'cluster wide') as database,
       setconfig as what_changed
FROM pg_db_role_setting role_setting
LEFT JOIN pg_roles role ON role.oid = role_setting.setrole
LEFT JOIN pg_database db ON db.oid = role_setting.setdatabase;

select * from pg_db_role_setting;
```

https://pgtune.leopard.in.ua/
https://pgconfigurator.cybertec.at/

основные парамеры
```
max_connections - максимальное кол-во подключений

shared_buffers - 25%(50%) - буфферы запросов

wal_buffers - буфферы журнала (def=-1 - 1/3 от shared_buffers)

work_mem - память сортировки и хеш-таблиц в рамках коннекта
work_mem = ($YOUR_INSTANCE_MEMORY * 0.8 - shared_buffers) / $YOUR_ACTIVE_CONNECTION_COUNT

maintenance_work_mem - память, выделяемая для обслуживания бд

effective_cache_size - размер дискового кэша для одного запроса. эффективность индексов
effective_cache_size = ram*0.7(0.8)

autovacuum - ражим работы автовакуума

synchronous_commit - синхронный/асинхронный коммит
```

https://www.commandprompt.com/blog/the_write_ahead_log/
