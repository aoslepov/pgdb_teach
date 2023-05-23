### Домашнее задание.  Бэкапы
#### Цель: Применить логический бэкап. Восстановиться из бэкапа

**Описание/Пошаговая инструкция выполнения домашнего задания:**

> Создаем ВМ/докер c ПГ.
> Создаем БД, схему и в ней таблицу.
> Заполним таблицы автосгенерированными 100 записями.
```
create table test1 as
select
  generate_series(1,100) as id,
  gen_random_uuid ()::uuid as uuid;

```
> Под линукс пользователем Postgres создадим каталог для бэкапов
```
mkdir -p /mnt/bkp
chown -R postgres:postgres /mnt/bkp
```
> Сделаем логический бэкап используя утилиту COPY
> Восстановим в 2 таблицу данные из бэкапа.
```
postgres=# create table test2 (like test1);
postgres=# \copy test1 to '/mnt/bkp/test1.sql';
postgres=# \copy test2 from '/mnt/bkp/test1.sql';
COPY 100
postgres=# select count(*) from test2;
 count
-------
   100

```


> Используя утилиту pg_dump создадим бэкап с оглавлением в кастомном сжатом формате 2 таблиц
```

-- делаем резервную копию всех таблиц бд postgres со структурой в кастомном формате
-- по коду ответа можно мониторить успешность бекапа
sudo -u postgres pg_dump -d postgres --create -U postgres -Fc --compress=9 > /mnt/bkp/dump.gz && echo 'BKP_OK' || echo 'BKP_FAIL'
```

> Используя утилиту pg_restore восстановим в новую БД только вторую таблицу!
```
postgres=# create database restoredb;
sudo -u postgres pg_restore -d restoredb -U postgres --table=test2 /mnt/bkp/dump.gz

sudo -u postgres -d restoredb

restoredb=# \dt
         List of relations
 Schema | Name  | Type  |  Owner
--------+-------+-------+----------
 public | test2 | table | postgres
(1 row)

restoredb=# select count(*) from test2;
 count
-------
   100
```
