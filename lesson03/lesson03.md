Cписок бд с информацией
```
select * from pg_database;
\l
```

?collate
?c_type


```
select current_database(); -- получить текущую бд
```

табличные пространства

```
create tablespace ИМЯ 
    [ OWNER владелец|CURRENT_USER|SESSION_USER]
    LOCATION 'каталог'
    [WIHT параметр=значение,]

-- параметры
seq_page_cost
random_page_cost (1.1 лоя ссд)
effectiove_io_concurrency
maintenance_io_concurrency

-- примеры
create tablespace ext_tablespace location '/srv/pg_ext';
select * from pg_tablespace ;
\db
alter tablespace ext_tablespace set (random_page_cost=1.1);
```

pg_default - табличное пространство по умолчанию
pg_global - табличное пространство межкластерных  объектов
https://postgrespro.ru/docs/postgrespro/9.5/manage-ag-tablespaces


схемы
```
create schema in not exists имя AUTORIZATION владелец схемы;
```


```
public - схема по умолчанию
pg_catalog - метаданные таблицы
information_schema - представления по pg_catalog
pg_temp_* - схемы для временных таблицы
```


```
-- список схем
select * from pg_namespace - список схем
\dn

-- примеры
create schema ddl_test;
alter table table_one set schema ddl_test

set search_path='ddl_test,public'; -- список поиска схем
select current_schemas(true); -- пути поиска

схема совпадающая с именем пользователя видна всегда и в приоретете если создана
```

```
--- практика
create schema ddl_pract;

select * from pg_catalog.pg_namespace ;
create table table_one (
	id integer primary key,
	some_text text
) tablespace ext_tablespace;

create table table_two (
	id integer generated always as identity primary key,
	id_one integer references table_one(id),
	some_text text unique
) tablespace ext_tablespace;

insert into table_one (id,some_text) values (1,'one'),(2,'two');
insert into table_two (id_one,some_text) values (1,'1-1'),(2,'2-2');

-- создание таблицы из селекта
create table table_three 
as
select t1.id,t1.some_text as first_text,t2.id as id_two,t2.some_text as second_text
from table_one t1 
inner join table_two t2 on t1.id=t2.id_one;
select * from table_three;

create table ddl_pract.copy_of_table_two (like table_two); -- создание таблицы с копированием структуры

alter table table_one set schema  ddl_pract; -- перенос таблицы в схему без блока

select * from pg_catalog.pg_tables ; -- список таблиц со схемами
select * from ddl_pract.table_one; -- полное квалифицированное имя

set search_path = ddl_pract, public; -- установка пути поиска для схем
select current_schemas(true) ; -- посмотреть пути поиска для сессии

create schema tec; -- схема с именем совпадающем с именем пользователя всегда видна и в приоритете /$user/
----
select * from pg_catalog.pg_tables ;
alter table ddl_pract.table_one set tablespace pg_default; -- перенос данных в тейблспейс по умолчанию с блоком
alter table public.table_two    set tablespace pg_default;

```
https://postgrespro.ru/docs/postgresql/14/ddl-schemas

база данных как шаблон
```
alter database otus_ddl is_template true;

select * from pg_stat_activity where datname='otus_ddl'; -- смотрим активные сессии
select pg_terminate_backend(pid) from pg_stat_activity where datname='otus_ddl'; -- отрубаем все активные сессии otus_ddl
alter database otus_ddl rename to otus_ddl_template; -- переименовываем бд

create database ddl_pract template otus_ddl_template; -- создаём бд на основании шаблона
```

представления
```
create view ddl_pract.view_one
as
select t1.id,t1.some_text as first_text,t2.id as id_two,t2.some_text as second_text
from ddl_pract.table_one t1 
inner join public.table_two t2 on t1.id=t2.id_one;


select * from pg_views; -- список вьюх
\dv

--- материализованные представления
--- данные на момент создания представления
create materialized view ddl_pract.view_mat_one
as
select t1.id,t1.some_text as first_text,t2.id as id_two,t2.some_text as second_text
from ddl_pract.table_one t1 
inner join public.table_two t2 on t1.id=t2.id_one;

refresh materialized view concurrently ddl_pract.view_mat_one; --обновить данные в таблице

```

создание юзеров и групп
```
create role bookkeeper; -- создаём роль select из бд
grant select on  all tables in schema public to bookkeeper;

create role john with password 'test' in role bookkeeper login; -- наследуем права с роли bookkeeper с логином
```

последовательности
```
create sequence seq001 start 10;
select nextval('seq001'::regclass);
select setval('seq001'::regclass,999,false); -- следующий будет 999
select setval('seq001'::regclass,999);       -- следующий будет 1000
create sequence seq002 cache 10; --- кеширует выдачу значений последовательностей (по умолчанию 10)
select currval('seq001'::regclass); -- возвращает значение выданное nextval для указанной последовательности 
select lastval();  -- возвращает значение выданное nextval

create table inc_test (id integer generated always identity primary key) -- создание автоинкремента
create table inc_test (id serial primary key) -- создание автоинкремента
```
