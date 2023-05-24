### Домашнее задание.  Бэкапы
#### Цель: Применить логический бэкап. Восстановиться из бэкапа

**Описание/Пошаговая инструкция выполнения домашнего задания:**

> Создаем ВМ/докер c ПГ.
> Создаем БД, схему и в ней таблицу.
> Заполним таблицы автосгенерированными 100 записями.
```

--- ставим pg15 
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql-15

-- создаём бд data и таблицу с тестовыми данными
create database data;
\c data

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
-- создаём вторую таблицу со структурой, аналогичной первой
create table test2 (like test1);
-- делаем дамп первой таблицы и восстанавливаем во второй
\copy test1 to '/mnt/bkp/test1.sql';
\copy test2 from '/mnt/bkp/test1.sql';
COPY 100
-- данные восстановлены
select count(*) from test2;
 count
-------
   100

```


> Используя утилиту pg_dump создадим бэкап с оглавлением в кастомном сжатом формате 2 таблиц
```

-- делаем резервную копию всех таблиц бд data со структурой в кастомном формате
-- по коду ответа можно мониторить успешность бекапа
sudo -u postgres pg_dump -d data --create -U postgres -Fc --compress=9 > /mnt/bkp/dump.gz && echo 'BKP_OK' || echo 'BKP_FAIL'
```

> Используя утилиту pg_restore восстановим в новую БД только вторую таблицу!
```
create database restoredb;
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
