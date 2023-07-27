клиенты и сервера консула
```
consul-01    158.160.63.220:8301   alive   server  1.16.0  2         dc  default    <all>
consul-02    158.160.115.116:8301  alive   server  1.16.0  2         dc  default    <all>
consul-03    158.160.111.110:8301  alive   server  1.16.0  2         dc  default    <all>
pg-teach-01  10.128.0.12:8301      alive   client  1.16.0  2         dc  default    <default>
pg-teach-02  10.128.0.23:8301      alive   client  1.16.0  2         dc  default    <default>
pg-teach-03  10.128.0.10:8301      alive   client  1.16.0  2         dc  default    <default>
```


старт кластера
```
-- запускаем патрони на мастере
root@pg-teach-01:~# systemctl start patroni
root@pg-teach-01:~# journalctl -r -u patroni
Jul 27 09:12:06 pg-teach-01 patroni[11457]: 2023-07-27 09:12:06,408 INFO: initialized a new cluster
Jul 27 09:12:06 pg-teach-01 patroni[11457]: 2023-07-27 09:12:06,296 WARNING: Could not activate Linux watchdog device: Can't open watchdog device: [Errno 2] No such file or directory: '/dev/watchdog'
Jul 27 09:12:06 pg-teach-01 patroni[11457]: 2023-07-27 09:12:06,240 INFO: running post_bootstrap
Jul 27 09:12:06 pg-teach-01 patroni[11457]: 2023-07-27 09:12:06,198 INFO: establishing a new patroni connection to the postgres cluster
Jul 27 09:12:06 pg-teach-01 patroni[11518]: 10.128.0.12:5432 - accepting connections
Jul 27 09:12:06 pg-teach-01 patroni[11516]: 10.128.0.12:5432 - accepting connections
Jul 27 09:12:05 pg-teach-01 patroni[11508]: 2023-07-27 09:12:05.245 UTC [11508] LOG:  database system is ready to accept connections
Jul 27 09:12:05 pg-teach-01 patroni[11512]: 2023-07-27 09:12:05.212 UTC [11512] LOG:  database system was shut down at 2023-07-27 09:12:02 UTC
Jul 27 09:12:05 pg-teach-01 patroni[11508]: 2023-07-27 09:12:05.197 UTC [11508] LOG:  listening on Unix socket "./.s.PGSQL.5432"
Jul 27 09:12:05 pg-teach-01 patroni[11508]: 2023-07-27 09:12:05.176 UTC [11508] LOG:  listening on IPv4 address "10.128.0.12", port 5432
Jul 27 09:12:05 pg-teach-01 patroni[11508]: 2023-07-27 09:12:05.176 UTC [11508] LOG:  starting PostgreSQL 15.3 (Ubuntu 15.3-1.pgdg22.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 11.3.0-1ubuntu1~22.04) >
Jul 27 09:12:05 pg-teach-01 patroni[11509]: 10.128.0.12:5432 - no response
Jul 27 09:12:05 pg-teach-01 patroni[11457]: 2023-07-27 09:12:05,133 INFO: postmaster pid=11508
Jul 27 09:12:04 pg-teach-01 patroni[11462]:     /usr/lib/postgresql/15/bin/pg_ctl -D /var/lib/postgresql/data/patroni -l logfile start
Jul 27 09:12:04 pg-teach-01 patroni[11462]: Success. You can now start the database server using:
Jul 27 09:12:04 pg-teach-01 patroni[11462]: initdb: hint: You can change this by editing pg_hba.conf or using the option -A, or --auth-local and --auth-host, the next time you run initdb.
Jul 27 09:12:04 pg-teach-01 patroni[11462]: initdb: warning: enabling "trust" authentication for local connections
Jul 27 09:12:04 pg-teach-01 patroni[11462]: syncing data to disk ... ok
Jul 27 09:12:02 pg-teach-01 patroni[11462]: performing post-bootstrap initialization ... ok
Jul 27 09:12:01 pg-teach-01 patroni[11462]: ok
Jul 27 09:12:01 pg-teach-01 patroni[11457]: 2023-07-27 09:12:01,435 INFO: bootstrap in progress
Jul 27 09:12:01 pg-teach-01 patroni[11462]: running bootstrap script ...
Jul 27 09:12:01 pg-teach-01 patroni[11462]: creating configuration files ... ok
Jul 27 09:12:01 pg-teach-01 patroni[11462]: selecting default time zone ... Etc/UTC
Jul 27 09:12:01 pg-teach-01 patroni[11462]: selecting default shared_buffers ... 128MB
Jul 27 09:12:01 pg-teach-01 patroni[11462]: selecting default max_connections ... 100
Jul 27 09:12:01 pg-teach-01 patroni[11462]: selecting dynamic shared memory implementation ... posix
Jul 27 09:12:01 pg-teach-01 patroni[11462]: creating subdirectories ... ok
Jul 27 09:12:01 pg-teach-01 patroni[11462]: creating directory /var/lib/postgresql/data/patroni ... ok
Jul 27 09:12:01 pg-teach-01 patroni[11462]: Data page checksums are enabled.
Jul 27 09:12:01 pg-teach-01 patroni[11462]: The default text search configuration will be set to "english".
Jul 27 09:12:01 pg-teach-01 patroni[11462]: The database cluster will be initialized with locale "en_US.UTF8".
Jul 27 09:12:01 pg-teach-01 patroni[11462]: This user must also own the server process.
Jul 27 09:12:01 pg-teach-01 patroni[11462]: The files belonging to this database system will be owned by user "postgres".
Jul 27 09:12:01 pg-teach-01 patroni[11457]: 2023-07-27 09:12:01,344 INFO: not healthy enough for leader race
Jul 27 09:12:01 pg-teach-01 patroni[11457]: 2023-07-27 09:12:01,344 INFO: Lock owner: None; I am pg-teach-01
Jul 27 09:12:01 pg-teach-01 patroni[11457]: 2023-07-27 09:12:01,338 INFO: trying to bootstrap a new cluster
Jul 27 09:12:01 pg-teach-01 patroni[11457]: 2023-07-27 09:12:01,247 INFO: Lock owner: None; I am pg-teach-01
Jul 27 09:12:01 pg-teach-01 patroni[11457]: 2023-07-27 09:12:01,090 INFO: No PostgreSQL configuration items changed, nothing to reload.
Jul 27 09:12:00 pg-teach-01 systemd[1]: Started Runners to orchestrate a high-availability PostgreSQL.


-- далее запускаем патрони на репликах


root@pg-teach-01:/etc/consul.d/scripts# patronictl -c /etc/patroni.yml list
+ Cluster: pgteachcluster --+---------+-----------+----+-----------+
| Member      | Host        | Role    | State     | TL | Lag in MB |
+-------------+-------------+---------+-----------+----+-----------+
| pg-teach-01 | 10.128.0.12 | Leader  | running   |  1 |           |
| pg-teach-02 | 10.128.0.23 | Replica | streaming |  1 |         0 |
| pg-teach-03 | 10.128.0.10 | Replica | streaming |  1 |         0 |
+-------------+-------------+---------+-----------+----+-----------+


-- тестируем переключение мастера
patronictl -c /etc/patroni.yml switchover
Current cluster topology
+ Cluster: pgteachcluster --+---------+-----------+----+-----------+
| Member      | Host        | Role    | State     | TL | Lag in MB |
+-------------+-------------+---------+-----------+----+-----------+
| pg-teach-01 | 10.128.0.12 | Leader  | running   |  1 |           |
| pg-teach-02 | 10.128.0.23 | Replica | streaming |  1 |         0 |
| pg-teach-03 | 10.128.0.10 | Replica | streaming |  1 |         0 |
+-------------+-------------+---------+-----------+----+-----------+
Primary [pg-teach-01]: pg-teach-01
Candidate ['pg-teach-02', 'pg-teach-03'] []: pg-teach-02
When should the switchover take place (e.g. 2023-07-26T16:46 )  [now]: now
Are you sure you want to switchover cluster pgteachcluster, demoting current leader pg-teach-01? [y/N]: y
2023-07-26 15:46:42.45909 Successfully switched over to "pg-teach-02"
+ Cluster: pgteachcluster --+---------+-----------+----+-----------+
| Member      | Host        | Role    | State     | TL | Lag in MB |
+-------------+-------------+---------+-----------+----+-----------+
| pg-teach-01 | 10.128.0.12 | Replica | stopped   |    |   unknown |
| pg-teach-02 | 10.128.0.23 | Leader  | running   |  1 |           |
| pg-teach-03 | 10.128.0.10 | Replica | streaming |  1 |         0 |
+-------------+-------------+---------+-----------+----+-----------+

patronictl -c /etc/patroni.yml list
+ Cluster: pgteachcluster --+---------+-----------+----+-----------+
| Member      | Host        | Role    | State     | TL | Lag in MB |
+-------------+-------------+---------+-----------+----+-----------+
| pg-teach-01 | 10.128.0.12 | Replica | streaming |  2 |         0 |
| pg-teach-02 | 10.128.0.23 | Leader  | running   |  2 |           |
| pg-teach-03 | 10.128.0.10 | Replica | streaming |  2 |         0 |
+-------------+-------------+---------+-----------+----+-----------+
```





регистрация сервисов в консуле
```
root@pg-teach-01:~# dig pg-teach-master.service.dc.consul

; <<>> DiG 9.18.12-0ubuntu0.22.04.2-Ubuntu <<>> pg-teach-master.service.dc.consul
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 14472
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;pg-teach-master.service.dc.consul. IN	A

;; ANSWER SECTION:
pg-teach-master.service.dc.consul. 0 IN	A	10.128.0.12

;; Query time: 3 msec
;; SERVER: 127.0.0.1#53(127.0.0.1) (UDP)
;; WHEN: Thu Jul 27 09:16:19 UTC 2023
;; MSG SIZE  rcvd: 78



root@pg-teach-01:~# dig pg-teach-replica.service.dc.consul

; <<>> DiG 9.18.12-0ubuntu0.22.04.2-Ubuntu <<>> pg-teach-replica.service.dc.consul
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 50552
;; flags: qr rd ra; QUERY: 1, ANSWER: 3, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;pg-teach-replica.service.dc.consul. IN	A

;; ANSWER SECTION:
pg-teach-replica.service.dc.consul. 0 IN A	10.128.0.23
pg-teach-replica.service.dc.consul. 0 IN A	10.128.0.12
pg-teach-replica.service.dc.consul. 0 IN A	10.128.0.10

;; Query time: 3 msec
;; SERVER: 127.0.0.1#53(127.0.0.1) (UDP)
;; WHEN: Thu Jul 27 09:16:41 UTC 2023
;; MSG SIZE  rcvd: 111

```


Настройка pgbouncer

```
-- получение хешей паролей для /etc/pgbouncer/userlist.txt
psql -Atq -U postgres -d postgres -c "SELECT concat('\"', usename, '\" \"', passwd, '\"') FROM pg_shadow" -h pg-teach-master.service.dc.consul


-- переключаемся назад на pg-teach-01 и проверяем
-- подключение через pgbouncer к мастеру и реплике

patronictl -c /etc/patroni.yml list
+ Cluster: pgteachcluster --+---------+-----------+----+-----------+
| Member      | Host        | Role    | State     | TL | Lag in MB |
+-------------+-------------+---------+-----------+----+-----------+
| pg-teach-01 | 10.128.0.12 | Leader  | running   |  3 |           |
| pg-teach-02 | 10.128.0.23 | Replica | streaming |  3 |         0 |
| pg-teach-03 | 10.128.0.10 | Replica | streaming |  3 |         0 |
+-------------+-------------+---------+-----------+----+-----------+

root@pg-teach-01:/etc/pgbouncer# psql -h pg-teach-master.service.dc.consul -p 6432 -U postgres -d postgres
Password for user postgres: 
psql (15.3 (Ubuntu 15.3-1.pgdg22.04+1))
Type "help" for help.

postgres=# \conninfo
You are connected to database "postgres" as user "postgres" on host "pg-teach-master.service.dc.consul" (address "10.128.0.12") at port "6432".



root@pg-teach-01:/etc/pgbouncer# psql -h pg-teach-replica.service.dc.consul -p 6432 -U postgres -d postgres
Password for user postgres: 
psql (15.3 (Ubuntu 15.3-1.pgdg22.04+1))
Type "help" for help.

postgres=# \conninfo
You are connected to database "postgres" as user "postgres" on host "pg-teach-replica.service.dc.consul" (address "10.128.0.10") at port "6432"
```
