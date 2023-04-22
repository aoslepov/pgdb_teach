

## Домашнее задание. Установка и настройка PostgreSQL

> Цель:
> создавать дополнительный диск для уже существующей виртуальной машины, размечать его и делать на нем файловую систему
> переносить содержимое базы данных PostgreSQL на дополнительный диск
> переносить содержимое БД PostgreSQL между виртуальными машинами

> создайте виртуальную машину c Ubuntu 20.04/22.04 LTS в GCE/ЯО/Virtual Box/докере
> поставьте на нее PostgreSQL 15 через sudo apt
> проверьте что кластер запущен через sudo -u postgres pg_lsclusters
> зайдите из под пользователя postgres в psql и сделайте произвольную таблицу с произвольным содержимым
> postgres=# create table test(c1 text);
> postgres=# insert into test values('1');
> \q


```
--- ставим postgres-15
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql-15
sudo -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log


--- добавляем тестовые данные
sudo -u postgres psql
psql (15.2 (Ubuntu 15.2-1.pgdg22.04+1))
Type "help" for help.

postgres=# create table test(c1 text);
CREATE TABLE
postgres=# insert into test values('1');
INSERT 0 1
postgres=# \dt
          List of relations
 Schema |  Name   | Type  |  Owner
--------+---------+-------+----------
 public | test    | table | postgres
```

> остановите postgres например через sudo -u postgres pg_ctlcluster 15 main stop
> создайте новый диск к ВМ размером 10GB
> добавьте свеже-созданный диск к виртуальной машине - надо зайти в режим ее редактирования и дальше выбрать пункт attach existing disk
> проинициализируйте диск согласно инструкции и подмонтировать файловую систему, только не забывайте менять имя диска на актуальное, в вашем случае это скорее всего будет /dev/sdb - https://www.digitalocean.com/community/tutorials/how-to-partition-and-format-storage-devices-in-linux
> перезагрузите инстанс и убедитесь, что диск остается примонтированным (если не так смотрим в сторону fstab)
> сделайте пользователя postgres владельцем /mnt/data - chown -R postgres:postgres /mnt/data/
> перенесите содержимое /var/lib/postgres/14 в /mnt/data - mv /var/lib/postgresql/15/mnt/data

```
--- заказываем диск размером 10GB
--- монтируем этот диск на ВМ


--- проверяем что диск смонтирован
pg-teach-01# fdisk -l

Disk /dev/vdb: 10 GiB, 10737418240 bytes, 20971520 sectors
 Units: sectors of 1 * 512 = 512 bytes
 Sector size (logical/physical): 512 bytes / 8192 bytes
 I/O size (minimum/optimal): 8192 bytes / 8192 bytes

--- ставим parted 
 sudo apt update
 sudo apt install parted


--- диск пока не размечен

 sudo parted -l
 Error: /dev/vdb: unrecognised disk label
 Model: Virtio Block Device (virtblk)
 Disk /dev/vdb: 10.7GB
 Sector size (logical/physical): 512B/8192B
 Partition Table: unknown
 Disk Flags:

 sudo lsblk
 NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
 vda    252:0    0    15G  0 disk
 ├─vda1 252:1    0     1M  0 part
 └─vda2 252:2    0    15G  0 part /
 vdb    252:16   0    10G  0 disk


--- размечаем диск

parted -a opt /dev/vdb mkpart primary xfs 0% 100%

lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
vda    252:0    0    15G  0 disk
├─vda1 252:1    0     1M  0 part
└─vda2 252:2    0    15G  0 part /
vdb    252:16   0    10G  0 disk
└─vdb1 252:17   0    10G  0 part


--- создаём ФС xfs для партиции /dev/vdb1

mkfs.xfs  /dev/vdb1
specified blocksize 4096 is less than device physical sector size 8192
switching to logical sector size 512
meta-data=/dev/vdb1              isize=512    agcount=4, agsize=655232 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=1, rmapbt=0
         =                       reflink=1    bigtime=0 inobtcount=0
data     =                       bsize=4096   blocks=2620928, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0


--- создаём каталог для данных, задаём права
mkdir /mnt/data && chown -R postgres:postgres /mnt/data/


--- смотрим uuid диска /dev/vdb1
blkid
/dev/vda2: UUID="82aeea96-6d42-49e6-85d5-9071d3c9b6aa" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="12dde951-b45e-4012-bce4-328a47213d1b"
/dev/vdb1: UUID="b4bfd480-631d-4d5c-bd7b-1a076c36fd17" BLOCK_SIZE="512" TYPE="xfs" PARTLABEL="primary" PARTUUID="bf8b2bd4-893c-4b4e-8858-85e26e3b799e"
/dev/vda1: PARTUUID="0597456a-4228-4f4a-b023-7a349e3b6798"

--- добавляем в /etc/fstab запись для диска и монтируем диск
UUID="b4bfd480-631d-4d5c-bd7b-1a076c36fd17" /mnt/data xfs defaults 0 1

mount -a


--- после перезагрузки диск по прежнему примонтирован

df -h
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           393M  1.2M  392M   1% /run
/dev/vda2        15G  5.7G  8.4G  41% /
tmpfs           2.0G     0  2.0G   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs           393M  4.0K  393M   1% /run/user/1000
/dev/vdb1        10G  104M  9.9G   2% /mnt/data

--- переносим данные
mv /var/lib/postgresql /mnt/data/
```


> попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 15 main start
> напишите получилось или нет и почему
> задание: найти конфигурационный параметр в файлах раположенных в /etc/postgresql/15/main который надо поменять и поменяйте его
> напишите что и почему поменяли
> попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 15 main start
> напишите получилось или нет и почему
```

--- кластер не запустится - нет каталога с данными
sudo -u postgres pg_ctlcluster 15 main start
Error: /var/lib/postgresql/15/main is not accessible or does not exist

--- меняем каталог с данными на новый в /etc/postgresql/15/main/postgresql.conf
data_directory = '/mnt/data/postgresql/15/main' 

--- запускаем постгрес, проверяем что кластер запустился и тестовые данные на месте

sudo -u postgres pg_ctlcluster 15 main start
Warning: the cluster will not be running as a systemd service. Consider using systemctl:
  sudo systemctl start postgresql@15-main

sudo -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory               Log file
15  main    5432 online postgres /mnt/data/postgresql/15/main /var/log/postgresql/postgresql-15-main.log

tail -f /var/log/postgresql/postgresql-15-main.log
2023-04-22 13:52:45.581 UTC [2488] LOG:  starting PostgreSQL 15.2 (Ubuntu 15.2-1.pgdg22.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 11.3.0-1ubuntu1~22.04) 11.3.0, 64-bit
2023-04-22 13:52:45.582 UTC [2488] LOG:  listening on IPv4 address "0.0.0.0", port 5432
2023-04-22 13:52:45.582 UTC [2488] LOG:  listening on IPv6 address "::", port 5432
2023-04-22 13:52:45.584 UTC [2488] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2023-04-22 13:52:45.598 UTC [2491] LOG:  database system was shut down at 2023-04-22 13:28:02 UTC
2023-04-22 13:52:45.605 UTC [2488] LOG:  database system is ready to accept connections

su -u postgres psql
psql (15.2 (Ubuntu 15.2-1.pgdg22.04+1))
Type "help" for help.

postgres=# select * from test;
 c1
----
 1
(1 row)
```


зайдите через через psql и проверьте содержимое ранее созданной таблицы
задание со звездочкой *: не удаляя существующий инстанс ВМ сделайте новый, поставьте на его PostgreSQL, удалите файлы с данными из /var/lib/postgres, перемонтируйте внешний диск который сделали ранее от первой виртуальной машины ко второй и запустите PostgreSQL на второй машине так чтобы он работал с данными на внешнем диске, расскажите как вы это сделали и что в итоге получилось.

