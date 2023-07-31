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
Jul 31 06:09:21 pg-teach-01 patroni[14745]: 2023-07-31 06:09:21,016 INFO: initialized a new cluster
Jul 31 06:09:20 pg-teach-01 patroni[14745]: 2023-07-31 06:09:20,946 WARNING: Could not activate Linux watchdog device: Can't open watchdog device: [Errno 2] No such file or directory: '/dev/watchdog'
Jul 31 06:09:20 pg-teach-01 patroni[14745]: 2023-07-31 06:09:20,893 INFO: running post_bootstrap
Jul 31 06:09:20 pg-teach-01 patroni[14745]: 2023-07-31 06:09:20,853 INFO: establishing a new patroni connection to the postgres cluster
Jul 31 06:09:20 pg-teach-01 patroni[14821]: 10.128.0.36:5432 - accepting connections
Jul 31 06:09:20 pg-teach-01 patroni[14819]: 10.128.0.36:5432 - accepting connections
Jul 31 06:09:19 pg-teach-01 patroni[14811]: 2023-07-31 06:09:19.891 UTC [14811] LOG:  database system is ready to accept connections
Jul 31 06:09:19 pg-teach-01 patroni[14815]: 2023-07-31 06:09:19.873 UTC [14815] LOG:  database system was shut down at 2023-07-31 06:09:16 UTC
Jul 31 06:09:19 pg-teach-01 patroni[14811]: 2023-07-31 06:09:19.862 UTC [14811] LOG:  listening on Unix socket "./.s.PGSQL.5432"
Jul 31 06:09:19 pg-teach-01 patroni[14811]: 2023-07-31 06:09:19.854 UTC [14811] LOG:  listening on IPv4 address "10.128.0.36", port 5432
Jul 31 06:09:19 pg-teach-01 patroni[14811]: 2023-07-31 06:09:19.854 UTC [14811] LOG:  starting PostgreSQL 15.3 (Ubuntu 15.3-1.pgdg22.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 11.3.0-1ubuntu1~22.04) >
Jul 31 06:09:19 pg-teach-01 patroni[14812]: 10.128.0.36:5432 - no response
Jul 31 06:09:19 pg-teach-01 patroni[14745]: 2023-07-31 06:09:19,811 INFO: postmaster pid=14811
Jul 31 06:09:19 pg-teach-01 patroni[14750]:     /usr/lib/postgresql/15/bin/pg_ctl -D /var/lib/postgresql/data/patroni -l logfile start
Jul 31 06:09:19 pg-teach-01 patroni[14750]: Success. You can now start the database server using:
Jul 31 06:09:19 pg-teach-01 patroni[14750]: initdb: hint: You can change this by editing pg_hba.conf or using the option -A, or --auth-local and --auth-host, the next time you run initdb.
Jul 31 06:09:19 pg-teach-01 patroni[14750]: initdb: warning: enabling "trust" authentication for local connections
Jul 31 06:09:19 pg-teach-01 patroni[14750]: syncing data to disk ... ok
Jul 31 06:09:16 pg-teach-01 patroni[14750]: performing post-bootstrap initialization ... ok
Jul 31 06:09:16 pg-teach-01 patroni[14750]: running bootstrap script ... ok
Jul 31 06:09:16 pg-teach-01 patroni[14750]: creating configuration files ... ok
Jul 31 06:09:16 pg-teach-01 patroni[14750]: selecting default time zone ... Etc/UTC
Jul 31 06:09:16 pg-teach-01 patroni[14750]: selecting default shared_buffers ... 128MB
Jul 31 06:09:16 pg-teach-01 patroni[14750]: selecting default max_connections ... 100
Jul 31 06:09:16 pg-teach-01 patroni[14750]: selecting dynamic shared memory implementation ... posix
Jul 31 06:09:16 pg-teach-01 patroni[14750]: creating subdirectories ... ok
Jul 31 06:09:16 pg-teach-01 patroni[14750]: creating directory /var/lib/postgresql/data/patroni ... ok
Jul 31 06:09:16 pg-teach-01 patroni[14750]: Data page checksums are enabled.
Jul 31 06:09:16 pg-teach-01 patroni[14750]: The default text search configuration will be set to "english".
Jul 31 06:09:16 pg-teach-01 patroni[14750]: The database cluster will be initialized with locale "en_US.UTF8".
Jul 31 06:09:16 pg-teach-01 patroni[14750]: This user must also own the server process.
Jul 31 06:09:16 pg-teach-01 patroni[14750]: The files belonging to this database system will be owned by user "postgres".
Jul 31 06:09:16 pg-teach-01 patroni[14745]: 2023-07-31 06:09:16,146 INFO: bootstrap in progress
Jul 31 06:09:16 pg-teach-01 patroni[14745]: 2023-07-31 06:09:16,135 INFO: not healthy enough for leader race
Jul 31 06:09:16 pg-teach-01 patroni[14745]: 2023-07-31 06:09:16,135 INFO: Lock owner: None; I am pg-teach-01
Jul 31 06:09:16 pg-teach-01 patroni[14745]: 2023-07-31 06:09:16,127 INFO: trying to bootstrap a new cluster
Jul 31 06:09:16 pg-teach-01 patroni[14745]: 2023-07-31 06:09:16,111 INFO: Lock owner: None; I am pg-teach-01
Jul 31 06:09:16 pg-teach-01 patroni[14745]: 2023-07-31 06:09:16,085 INFO: No PostgreSQL configuration items changed, nothing to reload.
Jul 31 06:09:15 pg-teach-01 systemd[1]: Started Runners to orchestrate a high-availability PostgreSQL.

-- далее запускаем патрони на репликах
root@pg-teach-02:~# systemctl restart patroni
root@pg-teach-02:~# journalctl -r -u patroni
Jul 31 06:11:29 pg-teach-02 patroni[19435]: 2023-07-31 06:11:29,072 INFO: no action. I am (pg-teach-02), a secondary, and following a leader (pg-teach-01)
Jul 31 06:11:29 pg-teach-02 patroni[19435]: 2023-07-31 06:11:29,015 INFO: establishing a new patroni connection to the postgres cluster
Jul 31 06:11:29 pg-teach-02 patroni[19435]: 2023-07-31 06:11:29,015 INFO: Lock owner: pg-teach-01; I am pg-teach-02
Jul 31 06:11:29 pg-teach-02 patroni[19506]: 10.128.0.17:5432 - accepting connections
Jul 31 06:11:28 pg-teach-02 patroni[19504]: 10.128.0.17:5432 - accepting connections
Jul 31 06:11:28 pg-teach-02 patroni[19501]: 2023-07-31 06:11:28.113 UTC [19501] LOG:  waiting for WAL to become available at 0/3000018
Jul 31 06:11:28 pg-teach-02 patroni[19503]: 2023-07-31 06:11:28.112 UTC [19503] FATAL:  could not start WAL streaming: ERROR:  replication slot "pg_teach_02" does not exist
Jul 31 06:11:28 pg-teach-02 patroni[19502]: 2023-07-31 06:11:28.089 UTC [19502] FATAL:  could not start WAL streaming: ERROR:  replication slot "pg_teach_02" does not exist
Jul 31 06:11:28 pg-teach-02 patroni[19497]: 2023-07-31 06:11:28.064 UTC [19497] LOG:  database system is ready to accept read-only connections
Jul 31 06:11:28 pg-teach-02 patroni[19501]: 2023-07-31 06:11:28.064 UTC [19501] LOG:  consistent recovery state reached at 0/20001B0
Jul 31 06:11:28 pg-teach-02 patroni[19501]: 2023-07-31 06:11:28.061 UTC [19501] LOG:  redo starts at 0/20000D8
Jul 31 06:11:28 pg-teach-02 patroni[19501]: 2023-07-31 06:11:28.052 UTC [19501] LOG:  entering standby mode
Jul 31 06:11:28 pg-teach-02 patroni[19501]: 2023-07-31 06:11:28.039 UTC [19501] LOG:  database system was interrupted; last known up at 2023-07-31 06:11:23 UTC
Jul 31 06:11:28 pg-teach-02 patroni[19497]: 2023-07-31 06:11:28.029 UTC [19497] LOG:  listening on Unix socket "./.s.PGSQL.5432"
Jul 31 06:11:28 pg-teach-02 patroni[19497]: 2023-07-31 06:11:28.022 UTC [19497] LOG:  listening on IPv4 address "10.128.0.17", port 5432
Jul 31 06:11:28 pg-teach-02 patroni[19497]: 2023-07-31 06:11:28.022 UTC [19497] LOG:  starting PostgreSQL 15.3 (Ubuntu 15.3-1.pgdg22.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 11.3.0-1ubuntu1~22.04) >
Jul 31 06:11:27 pg-teach-02 patroni[19498]: 10.128.0.17:5432 - no response
Jul 31 06:11:27 pg-teach-02 patroni[19435]: 2023-07-31 06:11:27,981 INFO: postmaster pid=19497
Jul 31 06:11:27 pg-teach-02 patroni[19435]: 2023-07-31 06:11:27,248 INFO: bootstrapped from leader 'pg-teach-01'
Jul 31 06:11:27 pg-teach-02 patroni[19435]: 2023-07-31 06:11:27,247 INFO: replica has been created using basebackup
Jul 31 06:11:23 pg-teach-02 patroni[19440]: WARNING:  skipping special file "./.s.PGSQL.5432"
Jul 31 06:11:23 pg-teach-02 patroni[19440]: WARNING:  skipping special file "./.s.PGSQL.5432"
Jul 31 06:11:23 pg-teach-02 patroni[19435]: 2023-07-31 06:11:23,141 INFO: bootstrap from leader 'pg-teach-01' in progress
Jul 31 06:11:23 pg-teach-02 patroni[19435]: 2023-07-31 06:11:23,128 INFO: Lock owner: pg-teach-01; I am pg-teach-02
Jul 31 06:11:23 pg-teach-02 patroni[19435]: 2023-07-31 06:11:23,124 INFO: trying to bootstrap from leader 'pg-teach-01'
Jul 31 06:11:23 pg-teach-02 patroni[19435]: 2023-07-31 06:11:23,114 INFO: Lock owner: pg-teach-01; I am pg-teach-02
Jul 31 06:11:23 pg-teach-02 patroni[19435]: 2023-07-31 06:11:23,075 INFO: No PostgreSQL configuration items changed, nothing to reload.
Jul 31 06:11:22 pg-teach-02 systemd[1]: Started Runners to orchestrate a high-availability PostgreSQL.


root@pg-teach-01:~# patronictl -c /etc/patroni.yml list


```




регистрация сервисов в консуле
```
root@pg-teach-01:~# dig pg-teach-master.service.dc.consul

; <<>> DiG 9.18.12-0ubuntu0.22.04.2-Ubuntu <<>> pg-teach-master.service.dc.consul
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 64229
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;pg-teach-master.service.dc.consul. IN	A

;; ANSWER SECTION:
pg-teach-master.service.dc.consul. 0 IN	A	10.128.0.17

;; Query time: 4 msec
;; SERVER: 127.0.0.1#53(127.0.0.1) (UDP)
;; WHEN: Mon Jul 31 06:19:27 UTC 2023
;; MSG SIZE  rcvd: 78

root@pg-teach-01:~# dig pg-teach-replica.service.dc.consul

; <<>> DiG 9.18.12-0ubuntu0.22.04.2-Ubuntu <<>> pg-teach-replica.service.dc.consul
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 27487
;; flags: qr rd ra; QUERY: 1, ANSWER: 3, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;pg-teach-replica.service.dc.consul. IN	A

;; ANSWER SECTION:
pg-teach-replica.service.dc.consul. 0 IN A	10.128.0.17
pg-teach-replica.service.dc.consul. 0 IN A	10.128.0.36
pg-teach-replica.service.dc.consul. 0 IN A	10.128.0.14

;; Query time: 0 msec
;; SERVER: 127.0.0.1#53(127.0.0.1) (UDP)
;; WHEN: Mon Jul 31 06:19:51 UTC 2023
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
