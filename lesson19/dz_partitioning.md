## Домашнее задание. Секционирование таблицы

### Цель: научиться секционировать таблицы.

>> Описание/Пошаговая инструкция выполнения домашнего задания: Секционировать большую таблицу из демо базы flights

*Смотрим распределение по неделям по дате отправления*

```
select EXTRACT('WEEK' FROM scheduled_departure) as scd, count(*)  from flights group by scd order by scd; 
1	3798
2	3798
3	3798
4	3798
5	3798
6	3798
7	3798
8	3798
9	3798
10	3798
11	3798
12	3798
13	3798
14	3798
..
```

*Смотрим диапазон дат*

```
select min(scheduled_departure) from flights; -- 2016-08-15 02:45:00.000 +0300
select max(scheduled_departure) from flights; -- 2017-09-14 20:55:00.000 +0300
```

*Будем партицировать по времени отправления (scheduled_departure) с интервалом в неделю при помощи timescaledb*
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

*Добавляем расширение timescaledb, создаём гипертаблицу с партицированием по неделе*

```
create extension timescaledb;

SELECT create_hypertable(
  'flights_part', 'scheduled_departure',
  chunk_time_interval => INTERVAL '1 week'
);
```

*Переносим данные и смотрим чанки*
```
insert into flights_part select * from flights;
vacuum analyze flights_part;

SELECT show_chunks('flights_part');

_timescaledb_internal._hyper_7_123_chunk
_timescaledb_internal._hyper_7_124_chunk
_timescaledb_internal._hyper_7_125_chunk
_timescaledb_internal._hyper_7_126_chunk
_timescaledb_internal._hyper_7_127_chunk
_timescaledb_internal._hyper_7_128_chunk
..
```

*Сморим корректность работы партицированной таблицы*

```
explain select flight_id,scheduled_departure from flights_part where scheduled_departure < '2016-09-01';

Append  (cost=0.28..255.68 rows=9223 width=12)
  ->  Index Only Scan using "27_54_flights_part_pkey" on _hyper_1_27_chunk  (cost=0.28..85.42 rows=3795 width=12)
        Index Cond: (scheduled_departure < '2016-09-01 00:00:00+03'::timestamp with time zone)
  ->  Index Only Scan using "42_84_flights_part_pkey" on _hyper_1_42_chunk  (cost=0.28..85.45 rows=3798 width=12)
        Index Cond: (scheduled_departure < '2016-09-01 00:00:00+03'::timestamp with time zone)
  ->  Index Only Scan using "55_110_flights_part_pkey" on _hyper_1_55_chunk  (cost=0.28..38.70 rows=1630 width=12)
        Index Cond: (scheduled_departure < '2016-09-01 00:00:00+03'::timestamp with time zone)
```

