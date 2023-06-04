### Домашнее задание. Репликация

#### Цель: реализовать свой миникластер на 3 ВМ.
#### Описание/Пошаговая инструкция выполнения домашнего задания:



>> На 1 ВМ создаем таблицы test для записи, test2 для запросов на чтение.


**Предварительно делаем на всех нодах следующие настройки**
```
-- Добавляем доступы к внутненней подсети для репликации

echo 'host    all     repluser        10.129.0.0/24            scram-sha-256' >> /etc/postgresql/15/main/pg_hba.conf
echo 'host    replication     repluser        10.129.0.0/24            scram-sha-256' >> /etc/postgresql/15/main/pg_hba.conf

-- устанавливаем уроверь репликации и открываем доступ 

alter system set wal_level to 'logical';
alter system set listen_addresses to '*';

-- создаём юзера для реаликации

CREATE USER repluser REPLICATION PASSWORD 'p@ssw0rd';
GRANT CONNECT ON database logical TO repluser;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO repluser;

-- создаём базу и пустые тестовые таблицы

create database logical;
\с logical
create table test1 (id int, txt char(10));
create table test2 (id int, txt char(10));


-- перегружаем ноды для применения параметров 
pg_ctlcluster 15 main restart
```

>> Создаем публикацию таблицы test и подписываемся на публикацию таблицы test2 с ВМ №2



**На VM1 добавляем тестовый набор данных**
```
insert into test1
  select generate_series(1,10) as id,
  md5(random()::text)::char(10) as txt;
insert into test1 (id,txt) values (11,'vm01');

select * from test1;
 id |    txt
----+------------
  1 | af922dcd31
  2 | ed45557e8e
  3 | 88079b2ea2
  4 | b6e6a65f4f
  5 | 0973ea6fe3
  6 | 2f7be9dd37
  7 | d89378e62b
  8 | c279dee151
  9 | dd0320fcac
 10 | 7d1c7da67b
 11 | vm01

```

**На VM1 создаём публикацию pub_test1 для таблицы test1**

```
CREATE PUBLICATION pub_test1 FOR TABLE test1;
```


**На VM2 подписываемся на публикацию pub_test1 на VM1. Слот репликации sub_test1 будет создан на VM1**

```
CREATE SUBSCRIPTION sub_test1 CONNECTION 'host=10.129.0.7 port=5432 user=repluser password=p@ssw0rd dbname=logical' PUBLICATION pub_test1 WITH (copy_data = true);
select * from test1;
 id |    txt
----+------------
  1 | af922dcd31
  2 | ed45557e8e
  3 | 88079b2ea2
  4 | b6e6a65f4f
  5 | 0973ea6fe3
  6 | 2f7be9dd37
  7 | d89378e62b
  8 | c279dee151
  9 | dd0320fcac
 10 | 7d1c7da67b
 11 | vm01

SELECT * FROM pg_stat_subscription \gx
 -[ RECORD 1 ]---------+------------------------------
 subid                 | 16412
 subname               | sub_test1
 pid                   | 19183
 relid                 |
 received_lsn          | 4/739048C8
 last_msg_send_time    | 2023-06-04 20:56:58.724191+00
 last_msg_receipt_time | 2023-06-04 20:56:58.723812+00
 latest_end_lsn        | 4/739048C8
 latest_end_time       | 2023-06-04 20:56:58.724191+00
```

> На 2 ВМ создаем таблицы test2 для записи, test для запросов на чтение.
> Создаем публикацию таблицы test2 и подписываемся на публикацию таблицы test1 с ВМ №1.


**На VM2 создаём добавляем тестовые данные в test2**

```
insert into test2
  select generate_series(1,10) as id,
  md5(random()::text)::char(10) as txt;
insert into test2 (id,txt) values (11,'vm02');
select * from test2;
logical=# select * from test2;
 id |    txt
----+------------
  1 | 580cab8bf7
  2 | fab294bc31
  3 | fd2cfc1ed0
  4 | 9612565bdb
  5 | 1128b43fd3
  6 | 0a4cd6a21b
  7 | 4ca6bfc016
  8 | a1e94d0b21
  9 | 336f8cf038
 10 | 7e929bebde
 11 | vm02
```

**На VM2 создаём публикацию pub_test2 для таблицы test2**

```
 CREATE PUBLICATION pub_test2 FOR TABLE test2;
```

**На VM2 подписываемся на публикацию pub_test1 на VM1. Cлот репликации sub_test1 будет создан на VM1*

```
CREATE SUBSCRIPTION sub_test2 CONNECTION 'host=10.129.0.8 port=5432 user=repluser password=p@ssw0rd dbname=logical'  PUBLICATION pub_test2 WITH (copy_data = true); 
select * from test2;
 id |    txt
----+------------
  1 | 580cab8bf7
  2 | fab294bc31
  3 | fd2cfc1ed0
  4 | 9612565bdb
  5 | 1128b43fd3
  6 | 0a4cd6a21b
  7 | 4ca6bfc016
  8 | a1e94d0b21
  9 | 336f8cf038
 10 | 7e929bebde
 11 | vm02
(11 row)

SELECT * FROM pg_stat_subscription \gx
-[ RECORD 1 ]---------+------------------------------
subid                 | 18547
subname               | sub_test2
pid                   | 2439
relid                 |
received_lsn          | 0/19966F8
last_msg_send_time    | 2023-06-04 21:04:09.569449+00
last_msg_receipt_time | 2023-06-04 21:04:09.56876+00
latest_end_lsn        | 0/19966F8
latest_end_time       | 2023-06-04 21:04:09.569449+00
```


> ВМ3 использовать как реплику для чтения и бэкапов (подписаться на таблицы из ВМ №1 и №2 ).

**Подписываемся. Будут созданы слоты sub_backup_test1 и sub_backup_test2 на соответствующих нодах**

````
CREATE SUBSCRIPTION sub_backup_test1 CONNECTION 'host=10.129.0.7 port=5432 user=repluser password=p@ssw0rd dbname=logical' PUBLICATION pub_test1 WITH (copy_data = true);
CREATE SUBSCRIPTION sub_backup_test2  CONNECTION 'host=10.129.0.8 port=5432 user=repluser password=p@ssw0rd dbname=logical'  PUBLICATION pub_test2 WITH (copy_data = true);

```



*Проверяем репликацию*
```
-- на ВМ1
insert into test1 (id,txt) values (12,'vm1 backup');
-- на ВМ2
insert into test2 (id,txt) values (12,'vm2 backup');

-- на ВМ3
select * from test1;
 id |    txt
----+------------
  1 | af922dcd31
  2 | ed45557e8e
  3 | 88079b2ea2
  4 | b6e6a65f4f
  5 | 0973ea6fe3
  6 | 2f7be9dd37
  7 | d89378e62b
  8 | c279dee151
  9 | dd0320fcac
 10 | 7d1c7da67b
 11 | vm01
 12 | vm1 backup
(12 rows)

select * from test2;
 id |    txt
----+------------
  1 | 580cab8bf7
  2 | fab294bc31
  3 | fd2cfc1ed0
  4 | 9612565bdb
  5 | 1128b43fd3
  6 | 0a4cd6a21b
  7 | 4ca6bfc016
  8 | a1e94d0b21
  9 | 336f8cf038
 10 | 7e929bebde
 11 | vm02
 12 | vm2 backup
```
