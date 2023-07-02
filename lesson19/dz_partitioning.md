## Домашнее задание. Секционирование таблицы

### Цель: научиться секционировать таблицы.



*Смотрим распределение по неделям по дате отправления*

```
select EXTRACT('WEEK' FROM scheduled_departure) as scd, count(*)  from flights group by scd order by scd; 
20	2717
21	3798
22	3798
23	3798
24	3798
25	3798
26	3798
27	3798
28	3798
29	3798
30	3798
31	3798
32	3798
33	3798
34	3797
35	3798
36	3798
37	2179
```

*Смотрим диапазон дат*

```
select min(scheduled_departure) from flights; -- 2017-05-17 02:00:00.000 +0300
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

-- запускаем тюнинг постгрес 
timescaledb-tune
-- основной конфиг shared_preload_libraries='timescaledb'

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

*Создаём гипертаблицу с партицированием по неделе*

```
SELECT create_hypertable(
  'flights_part', 'scheduled_departure',
  chunk_time_interval => INTERVAL '1 week'
);
```

*Переносим данные и смотрим чанки*
```
insert into flights_part select * from flights;

analyze flights_part;

SELECT show_chunks('flights_part');

_timescaledb_internal._hyper_7_123_chunk
_timescaledb_internal._hyper_7_124_chunk
_timescaledb_internal._hyper_7_125_chunk
_timescaledb_internal._hyper_7_126_chunk
_timescaledb_internal._hyper_7_127_chunk
_timescaledb_internal._hyper_7_128_chunk
_timescaledb_internal._hyper_7_129_chunk
_timescaledb_internal._hyper_7_130_chunk
_timescaledb_internal._hyper_7_131_chunk
_timescaledb_internal._hyper_7_132_chunk
_timescaledb_internal._hyper_7_133_chunk
_timescaledb_internal._hyper_7_134_chunk
_timescaledb_internal._hyper_7_135_chunk
_timescaledb_internal._hyper_7_136_chunk
_timescaledb_internal._hyper_7_137_chunk
_timescaledb_internal._hyper_7_138_chunk
_timescaledb_internal._hyper_7_139_chunk
_timescaledb_internal._hyper_7_140_chunk
_timescaledb_internal._hyper_7_141_chunk
```

*Сморим корректность работы партицированной таблицы*

```
explain select flight_id,scheduled_departure from flights_part where scheduled_departure < '2017-06-01';

Append  (cost=0.28..225.43 rows=8142 width=12)
  ->  Index Only Scan using "133_266_flights_part_pkey" on _hyper_7_133_chunk  (cost=0.28..85.42 rows=3795 width=12)
        Index Cond: (scheduled_departure < '2017-06-01 00:00:00+03'::timestamp with time zone)
  ->  Seq Scan on _hyper_7_135_chunk  (cost=0.00..13.86 rows=549 width=12)
        Filter: (scheduled_departure < '2017-06-01 00:00:00+03'::timestamp with time zone)
  ->  Index Only Scan using "139_278_flights_part_pkey" on _hyper_7_139_chunk  (cost=0.28..85.45 rows=3798 width=12)
        Index Cond: (scheduled_departure < '2017-06-01 00:00:00+03'::timestamp with time zone)

```

