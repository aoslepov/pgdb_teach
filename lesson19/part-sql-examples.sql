----Подготовим терраформ для развертывании в яо
$Env:YC_TOKEN=$(yc iam create-token)
$Env:YC_CLOUD_ID=$(yc config get cloud-id)
$Env:YC_FOLDER_ID=$(yc config get folder-id)
terraform apply

drop database test;
create database test;

select version();


create table table0 (
id bigserial primary key,
name text,
create_date date,
some_sum numeric
);

CREATE TABLE table0_2020_03 (like table0 including all) INHERITS (table0);
ALTER TABLE table0_2020_03 add check ( create_date between date'2020-03-01' and date'2020-04-01' - 1);
CREATE TABLE table0_2020_01 () INHERITS (table0);
ALTER TABLE table0_2020_01 ad d check ( create_date between date'2020-01-01' and date'2020-02-01' - 1);
CREATE TABLE table0_2020_02 (check (create_date between date'2020-02-01' and date'2020-03-01' - 1)) INHERITS (table0);

CREATE OR REPLACE FUNCTION table0_select_part()
RETURNS TRIGGER AS $$
BEGIN
    if new.create_date between date'2020-01-01' and date'2020-02-01' - 1 then
        INSERT INTO table0_2020_01 VALUES (NEW.*);
    elsif new.create_date between date'2020-02-01' and date'2020-03-01' - 1 then
        INSERT INTO table0_2020_02 VALUES (NEW.*);
    else
        raise exception 'this date not in your partitions. add partition';
    end if;
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER check_date_table0
    BEFORE INSERT ON table0
    FOR EACH ROW EXECUTE PROCEDURE table0_select_part();

insert into table0 values (1, 'some_text', date'2020-01-02', 100.0);

select * from table0_2020_01;
explain
select * from table0;

insert into table0 values (1, 'some_text', date'2020-05-02', 100.0); --ошибка
update table0
set create_date=date'2020-02-02'
where id=1;

insert into table0 (id,create_date)
select generate_series,date'2020-02-01'
    from generate_series(1,10000);

select pg_size_pretty(pg_table_size('table0')),
       pg_size_pretty(pg_table_size('table0_2020_01')),
       pg_size_pretty(pg_table_size('table0_2020_02')),
       pg_size_pretty(pg_table_size('table0_2020_03'));

SET enable_partition_pruning = on;

explain
select *
from table0
where create_date < date'2020-02-01';

--------------Декларативный метод--------------------------------

create table table1 (
id bigserial,
name text,
create_date date,
some_sum numeric
)
partition by range (create_date);

-- Можно делать партиции по 2-ум колонкам
create table table11 (
id bigserial,
name text,
create_date date,
some_sum numeric
)
partition by range (create_date, name);

create table big_partition partition of table1 for values from (null) to (maxvalue);

create table big_partition partition of table1 for values from (minvalue) to (maxvalue);

insert into table1 values (1,'some_text',null,100);

explain
select * from table1;

insert into table1 values (1,'some_text',date'2020-01-01',100);

create table default_partition partition of table1 default;
insert into table1 values (1,'some_text',null,100);

select * from table1;
select * from default_partition;


SET enable_partition_pruning = on;
explain
select *
from table1
where create_date is null;

-----------------------------------------
drop table table2;
create table table2 (
id bigint,
name text,
create_date date,
some_sum numeric
)
partition by range (id);

create table partition_1 partition of table2 for values from (minvalue) to (10000);
create table partition_2 partition of table2 for values from (10001) to (maxvalue);
create table default_partition_test2 partition of table2 default;

insert into table2 (id)
select *
from generate_series(1,20000);

insert into table2 (id)
select null
from generate_series(1,10000);


explain
select *
from table2
where id is null;

-----------------------------------------------------------------
drop table table1;
create table table1 (
id bigserial,
name text,
create_date date,
some_sum numeric
)
partition by range (create_date);

select * from table1;
create table table1_2020_01 partition of table1 for values from ('2020-01-01') to ('2020-02-01');


alter table table1_2020_01 add constraint pk_table1_2020_01 primary key (name);
alter table table1_2020_01 drop constraint pk_table1_2020_01;
alter table table1 add constraint pk_table1 primary key (name);
alter table table1 add constraint pk_table1 primary key (create_date,name);
alter table table1 drop constraint pk_table1;

insert into table1(name, create_date, some_sum) values ('some_name', date'2020-01-01', 100.12);
insert into table1(name, create_date, some_sum) values ('some_name', date'2020-03-01', 100.12);

create table table1_default partition of table1 default;
insert into table1(name, create_date, some_sum) values ('some_name', date'2020-03-01', 100.12);
select * from table1_default;

explain
select *
from table1
where create_date between date'2020-01-01' and date'2020-04-01'-1;

explain
select *
from table1
where create_date between date'2020-01-01' and date'2020-02-01';


--создание перкрывающего диапазлна, знчение есьб в default------------------------------------------------------------------------------------------------

create table table1_2020_04 partition of table1 for values from ('2020-04-01') to ('2020-05-01');
create table table1_2020_02 partition of table1 for values from ('2020-02-01') to ('2020-03-01');
create table table1_2020_03 partition of table1 for values from ('2020-03-01') to ('2020-04-01');
alter table table1 detach partition table1_default;
create table table1_2020_03 partition of table1 for values from ('2020-03-01') to ('2020-04-01');
select *
from table1_default;

-- alter table table1 attach partition table1_default default;
insert into table1
select *
from table1_default
where create_date between date'2020-03-01' and date'2020-04-01' - 1;
delete from table1_default
where create_date between date'2020-03-01' and date'2020-04-01' - 1;
alter table table1 attach partition table1_default default;

explain
select *
from table1
where create_date between date'2020-01-01' and date'2020-04-01' - 1;


select * from table1;

update table1
set create_date = date'2020-05-01'
where id = 1;

select *
from table1_default;

---------Секционировнаие по списку--------------------

drop table table2;

create table table2 (
id bigserial,
name text,
create_date date,
some_sum numeric
) partition by list (name);
create table table2_name_1_2 partition of table2 for values in ('name1', 'name2');
create table table2_name_3 partition of table2 for values in ('name3');
create table table2_default partition of table2 default ;
create table table2_name_4 partition of table2 for values in ('name4') partition by range (create_date);
create table table2_name_4_2020_01 partition of table2_name_4 for values from ('2020-01-01') to ('2020-02-01');
insert into table2(name, create_date, some_sum) values ('some_name', date'2020-01-01', 100.12);

explain
select *
from table2;

select * from
table2_name_4;

select * from table2_default;


---------Секционирование по хэшу---------------------------
drop table table3;
create table table3 (
id bigserial,
name text,
create_date date,
some_sum numeric
) partition by hash(id);
create table dept_1 partition of table3 FOR VALUES WITH (MODULUS 5, REMAINDER 0);
create table dept_2 partition of table3 FOR VALUES WITH (MODULUS 6, REMAINDER 1);
create table dept_6 partition of table3 FOR VALUES WITH (MODULUS 5, REMAINDER 0);
create table dept_2 partition of table3 FOR VALUES WITH (MODULUS 5, REMAINDER 1);
create table dept_3 partition of table3 FOR VALUES WITH (MODULUS 5, REMAINDER 2);
create table dept_4 partition of table3 FOR VALUES WITH (MODULUS 5, REMAINDER 3);
create table dept_5 partition of table3 FOR VALUES WITH (MODULUS 5, REMAINDER 4);

insert into table3
select generate_series, 'name', current_date, 0
from generate_series(1, 10000);

select count(*) from table3;
select count(*)
from dept_1; --1969
select count(*)
from dept_2; --2034
select count(*)
from dept_3;
select count(*)
from dept_4;
select count(*)
from dept_5;

-----Хэш по дате----------------

create table table3_v2 (
id bigserial,
name text,
create_date date,
some_sum numeric
) partition by hash(create_date);
create table dept_v2_1 partition of table3_v2 FOR VALUES WITH (MODULUS 5, REMAINDER 0);
create table
    dept_v2_2 partition of table3_v2 FOR VALUES WITH (MODULUS 5, REMAINDER 1);
create table dept_v2_3 partition of table3_v2 FOR VALUES WITH (MODULUS 5, REMAINDER 2);
crea
te table dept_v2_4 partition of table3_v2 FOR VALUES WITH (MODULUS 5, REMAINDER 3);
create table dept_v2_5 partition of table3_v2 FOR VALUES WITH (MODULUS 5, REMAINDER 4);

insert into table3_v2(id, name, create_date, some_sum) values (1, 'some_name', date'2020-05-05', 100.12);

explain
select *
from table3_v2
where create_date = date'2020-05-05';

explain
select *
from table3_v2
where create_date <date'2020-05-05';

insert into table3_v2
select generate_series, 'name', date'2019-01-01' + generate_series, 0
from generate_series(1, 10000);

select count(*)
from dept_v2_1; --1978

select count(*)
from dept_v2_2; --2050

select count(*)
from dept_v2_3;


----Секционирование внешней таблицы----
create extension postgres_fdw;
create server foreign_server
foreign data wrapper postgres_fdw
options (host 'localhost',port '5432', dbname 'otus');
create user mapping for postgres
server foreign_server
options (user 'postgres',password '123456');

create foreign table
    foreign_table(
    id int,
    created_at timestamp
    )
server foreign_server
options (schema_name 'public',table_name 'table_2021_01');

select * from foreign_table;

create table big_table (
    id int,
    created_at timestamp
) partition by range (created_at);

create table table_2021_02 partition of big_table for values from (date'2021-02-01') to (date'2021-03-01');
alter table big_table attach partition foreign_table for values from (date'2021-01-01') to (date'2021-02-01');

explain
select *
from big_table
where created_at=date'2021-01-03';

-----Индекс-------------------------------------------------
drop table table2;
create table table2 (
id bigint,
name text,
create_date date,
some_sum numeric
)
partition by range (id);

create table partition_1 partition of table2 for values from (1) to (10000);
create table partition_2 partition of table2 for values from (10001) to (20000);
create table partition_3 partition of table2 for values from (20001) to (30000);
create table defau
    lt_partition_test2 partition of table2 default;

insert into table2 (id)
select *
from generate_series(1,40000);

insert into table2 (id)
select null
from generate_series(1,10000);


explain
select *
from table2
where id between 1 and 1000;

create index table2_idx on table2(id);
select * from pg_stat_user_indexes where relname ilike '%part%';

explain
select id
from table2
where id between 1 and 1000;

create table partition_4 partition of table2 for values from (40001) to (50000);
select * from pg_stat_user_indexes where relname ilike '%part%';

drop index partition_4_id_idx;
drop index table2_idx;

select * from pg_stat_user_indexes where relname ilike '%part%';

create index concurrently table2_idx on table2(id);

create index table2_idx on ONLY table2(id);
SELECT indisvalid FROM pg_index WHERE indexrelid::regclass::text = 'table2_idx';

create index concurrently partition_1_idx on partition_1(id);
create index concurrently partition_2_idx on partition_2(id);
create index concurrently partition_3_idx on partition_3(id);
create index concurrently partition_4_idx on partition_4(id);
create index concurrently default_partition_test2_idx on default_partition_test2(id);

alter index table2_idx attach partition partition_1_idx;
alter index table2_idx attach partition partition_2_idx;
alter index table2_idx attach partition partition_3_idx;
alter index table2_idx attach partition partition_4_idx;
alter index table2_idx attach partition default_partition_test2_idx;

SELECT indisvalid FROM pg_index WHERE indexrelid::regclass::text = 'table2_idx';

explain
select id
from table2
where id between 1 and 1000;

CREATE TABLE table2_new (LIKE table2 INCLUDING ALL);

select version();


---timescaledb-----



--timescaledb-------------------------------------------

apt install gnupg postgresql-common apt-transport-https lsb-release wget
/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
echo "deb https://packagecloud.io/timescale/timescaledb/ubuntu/ $(lsb_release -c -s) main" | sudo tee /etc/apt/sources.list.d/timescaledb.list
wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | sudo apt-key add -
apt update
apt install timescaledb-2-postgresql-15
timescaledb-tune --quiet --yes
systemctl restart postgresql


select version();
show shared_preload_libraries;
create database timescale;

create extension timescaledb;

CREATE TABLE conditions(
  tstamp timestamptz NOT NULL,
  device VARCHAR(32) NOT NULL,
  temperature FLOAT NOT NULL);

SELECT create_hypertable(
  'conditions', 'tstamp',
  chunk_time_interval => INTERVAL '1 day'
);

INSERT INTO conditions
  SELECT
    tstamp, 'device-' || (random()*30)::INT, random()*80 - 40
  FROM
    generate_series(
      NOW() - INTERVAL '90 days',
      NOW(),
      '1 min'
    ) AS tstamp;


select * from conditions;

SELECT show_chunks('conditions');


explain
SELECT * FROM conditions
WHERE tstamp > now() - INTERVAL '30 minutes';

explain
SELECT * FROM conditions
WHERE tstamp > (now() - INTERVAL '3 days');

--сжатие
ALTER TABLE conditions SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'device'
);

SELECT add_compression_policy(
  'conditions',
  compress_after => INTERVAL '1 day');

SELECT * FROM chunk_compression_stats('conditions');

SELECT chunk_schema,
       chunk_name,
       before_compression_total_bytes,
       after_compression_total_bytes
FROM chunk_compression_stats('conditions');

--Политика хранения данных
SELECT add_retention_policy('conditions', INTERVAL '2 days');
SELECT show_chunks('conditions');

--Отменить
SELECT remove_retention_policy('conditions');


Ссылка на опрос
https://otus.ru/polls/57773/
