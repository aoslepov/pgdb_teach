## Домашнее задание. Секционирование таблицы

### Цель: научиться секционировать таблицы.

>> Описание/Пошаговая инструкция выполнения домашнего задания: Секционировать большую таблицу из демо базы flights

*Смотрим распределение по месяцам по дате отправления*

```
select EXTRACT('month' FROM scheduled_departure) as scd, count(*)  from flights group by scd order by scd;
--
1	16831
2	15192
3	16783
4	16318
5	16821
6	16235
7	16854
8	26060
9	23831
10	16854
11	16285
12	16803
```

*Смотрим диапазон дат*

```
select min(scheduled_departure) from flights; -- 2016-08-15 02:45:00.000 +0300
select max(scheduled_departure) from flights; -- 2017-09-14 20:55:00.000 +0300
```

*Будем партицировать по времени отправления (scheduled_departure) с интервалом в месяц при помощи timescaledb*
```
-- ставим timescaledb из пакетов

apt install gnupg apt-transport-https lsb-release wget
echo "deb https://packagecloud.io/timescale/timescaledb/ubuntu/ $(lsb_release -c -s) main" | sudo tee /etc/apt/sources.list.d/timescaledb.list
wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | sudo apt-key add -
apt update
apt install timescaledb-2-postgresql-15

-- запускаем тюнинг постгрес и выставляем предлагаемые параметры 
timescaledb-tune

-- перезапускаем постгрес
systemctl restart postgresql
```


*Подготавлиевм таблицу к партицированию*
```
-- создаём таблицу flights_part с переносом всех констрейтов/индексов из flights
create table flights_part (like flights including all);

-- необходимо чтобы в первичный ключ входили поля для партицирования
-- пересоздаём PK
alter table flights_part drop constraint flights_part_pkey;
alter table flights_part add primary key (flight_id,scheduled_departure);

```

*Добавляем расширение timescaledb, создаём гипертаблицу с партицированием по месяцам*

```
create extension timescaledb;

SELECT create_hypertable(
  'flights_part', 'scheduled_departure',
  chunk_time_interval => INTERVAL '1 month'
);
```

*Переносим данные и смотрим чанки*
```
insert into flights_part select * from flights;
vacuum analyze flights_part;

SELECT show_chunks('flights_part');
--
_timescaledb_internal._hyper_2_59_chunk
_timescaledb_internal._hyper_2_60_chunk
_timescaledb_internal._hyper_2_61_chunk
_timescaledb_internal._hyper_2_62_chunk
_timescaledb_internal._hyper_2_63_chunk
_timescaledb_internal._hyper_2_64_chunk
_timescaledb_internal._hyper_2_65_chunk
_timescaledb_internal._hyper_2_66_chunk
_timescaledb_internal._hyper_2_67_chunk
_timescaledb_internal._hyper_2_68_chunk
_timescaledb_internal._hyper_2_69_chunk
_timescaledb_internal._hyper_2_70_chunk
_timescaledb_internal._hyper_2_71_chunk
_timescaledb_internal._hyper_2_72_chunk
```

*Сморим корректность работы партицированной таблицы*

```
explain select flight_id,scheduled_departure from flights_part where scheduled_departure < '2016-09-01';
--
Append  (cost=0.29..410.89 rows=9214 width=12)
  ->  Index Only Scan using "65_130_flights_part_pkey" on _hyper_2_65_chunk  (cost=0.29..221.60 rows=2743 width=12)
        Index Cond: (scheduled_departure < '2016-09-01 00:00:00+03'::timestamp with time zone)
  ->  Index Only Scan using "72_144_flights_part_pkey" on _hyper_2_72_chunk  (cost=0.28..143.22 rows=6471 width=12)
        Index Cond: (scheduled_departure < '2016-09-01 00:00:00+03'::timestamp with time zone)
```

