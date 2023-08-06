```
root@teach-mon:~# PGPASSWORD=pgsuper pgbench -U postgres --host=pg-teach-master.service.dc.consul -i testing
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.05 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 1.27 s (drop tables 0.00 s, create tables 0.01 s, client-side generate 0.17 s, vacuum 0.08 s, primary keys 1.01 s).


root@teach-mon:~# PGPASSWORD=pgsuper pgbench -U postgres --host=pg-teach-master.service.dc.consul -c10 -C --jobs=4 --progress=4 --time=600 --verbose-errors  testing
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 4
maximum number of tries: 1
duration: 600 s
number of transactions actually processed: 34226
number of failed transactions: 0 (0.000%)
latency average = 143.470 ms
latency stddev = 86.950 ms
average connection time = 31.827 ms
tps = 57.038549 (including reconnection times


root@pg-teach-01:/home# journalctl -r -u patroni
Aug 06 21:12:13 pg-teach-01 patroni[10348]: 2023-08-06 21:12:13,079 INFO: no action. I am (pg-teach-01), the leader with the lock
Aug 06 21:12:12 pg-teach-01 patroni[70258]: 2023-08-06 21:12:12.416 UTC [70258] STATEMENT:  START_REPLICATION SLOT "pg_teach_03" 0/46000000 TIMELINE 3
Aug 06 21:12:12 pg-teach-01 patroni[70258]: 2023-08-06 21:12:12.416 UTC [70258] ERROR:  replication slot "pg_teach_03" does not exist
Aug 06 21:12:12 pg-teach-01 patroni[70257]: 2023-08-06 21:12:12.394 UTC [70257] STATEMENT:  START_REPLICATION SLOT "pg_teach_03" 0/46000000 TIMELINE 2
Aug 06 21:12:12 pg-teach-01 patroni[70257]: 2023-08-06 21:12:12.394 UTC [70257] ERROR:  replication slot "pg_teach_03" does not exist
Aug 06 21:12:12 pg-teach-01 patroni[57648]: 2023-08-06 21:12:12.135 UTC [57648] LOG:  checkpoint complete: wrote 2 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.008 s, sync=0.002 s, total=>
Aug 06 21:12:12 pg-teach-01 patroni[57646]: 2023-08-06 21:12:12.110 UTC [57646] LOG:  database system is ready to accept connections
Aug 06 21:12:12 pg-teach-01 patroni[57648]: 2023-08-06 21:12:12.103 UTC [57648] LOG:  checkpoint starting: force
Aug 06 21:12:12 pg-teach-01 patroni[57650]: 2023-08-06 21:12:12.097 UTC [57650] LOG:  archive recovery complete
Aug 06 21:12:11 pg-teach-01 patroni[57650]: 2023-08-06 21:12:11.952 UTC [57650] LOG:  selected new timeline ID: 3
Aug 06 21:12:11 pg-teach-01 patroni[57650]: 2023-08-06 21:12:11.946 UTC [57650] LOG:  last completed transaction was at log time 2023-08-06 21:10:03.178642+00
Aug 06 21:12:11 pg-teach-01 patroni[57650]: 2023-08-06 21:12:11.946 UTC [57650] LOG:  redo done at 0/4685B110 system usage: CPU: user: 9.37 s, system: 8.10 s, elapsed: 4267.59 s
Aug 06 21:12:11 pg-teach-01 patroni[57650]: 2023-08-06 21:12:11.945 UTC [57650] LOG:  received promote request
Aug 06 21:12:11 pg-teach-01 patroni[70252]: server promoting
Aug 06 21:12:11 pg-teach-01 patroni[10348]: 2023-08-06 21:12:11,943 INFO: promoted self to leader by acquiring session lock
Aug 06 21:12:11 pg-teach-01 patroni[10348]: 2023-08-06 21:12:11,901 INFO: Got response from pg-teach-03 http://10.128.0.24:8008/patroni: {"state": "running", "postmaster_start_time": "2023-08-06 18:33:05.463378>
Aug 06 21:12:11 pg-teach-01 patroni[10348]: 2023-08-06 21:12:11,871 WARNING: Request failed to pg-teach-02: GET http://10.128.0.32:8008/patroni (HTTPConnectionPool(host='10.128.0.32', port=8008): Max retries ex>
Aug 06 21:12:10 pg-teach-01 patroni[57650]: 2023-08-06 21:12:10.584 UTC [57650] LOG:  waiting for WAL to become available at 0/4685B160
Aug 06 21:12:10 pg-teach-01 patroni[70243]:                 Is the server running on that host and accepting TCP/IP connections?
Aug 06 21:12:10 pg-teach-01 patroni[70243]: 2023-08-06 21:12:10.584 UTC [70243] FATAL:  could not connect to the primary server: connection to server at "10.128.0.32", port 5432 failed: Connection refused
Aug 06 21:12:09 pg-teach-01 patroni[10348]: 2023-08-06 21:12:09,180 INFO: no action. I am (pg-teach-01), a secondary, and following a leader (pg-teach-02)


root@pg-teach-01:/home# patronictl -c /etc/patroni.yml list
+ Cluster: pgteachcluster --+---------+-----------+----+-----------+
| Member      | Host        | Role    | State     | TL | Lag in MB |
+-------------+-------------+---------+-----------+----+-----------+
| pg-teach-01 | 10.128.0.36 | Leader  | running   |  3 |           |
| pg-teach-03 | 10.128.0.24 | Replica | streaming |  3 |         0 |
+-------------+-------------+---------+-----------+----+-----------+

root@pg-teach-02:~# journalctl -r -u patroni
Aug 06 21:13:20 pg-teach-02 patroni[72164]: 2023-08-06 21:13:20,722 INFO: no action. I am (pg-teach-02), a secondary, and following a leader (pg-teach-01)
Aug 06 21:13:20 pg-teach-02 patroni[72164]: 2023-08-06 21:13:20,684 INFO: Dropped unknown replication slot 'pg_teach_01'
Aug 06 21:13:20 pg-teach-02 patroni[72164]: 2023-08-06 21:13:20,635 INFO: Dropped unknown replication slot 'pg_teach_03'
Aug 06 21:13:20 pg-teach-02 patroni[72164]: 2023-08-06 21:13:20,586 INFO: establishing a new patroni connection to the postgres cluster
Aug 06 21:13:20 pg-teach-02 patroni[72164]: 2023-08-06 21:13:20,586 INFO: Lock owner: pg-teach-01; I am pg-teach-02
Aug 06 21:13:20 pg-teach-02 patroni[72241]: 10.128.0.32:5432 - accepting connections
Aug 06 21:13:20 pg-teach-02 patroni[72239]: 10.128.0.32:5432 - accepting connections
Aug 06 21:13:19 pg-teach-02 patroni[72236]: 2023-08-06 21:13:19.807 UTC [72236] LOG:  waiting for WAL to become available at 0/470000B8
Aug 06 21:13:19 pg-teach-02 patroni[72236]: 2023-08-06 21:13:19.807 UTC [72236] LOG:  new timeline 3 forked off current database system timeline 2 before current recovery point 0/470000A0
Aug 06 21:13:19 pg-teach-02 patroni[72238]: 2023-08-06 21:13:19.806 UTC [72238] FATAL:  could not start WAL streaming: ERROR:  replication slot "pg_teach_02" does not exist
Aug 06 21:13:19 pg-teach-02 patroni[72236]: 2023-08-06 21:13:19.784 UTC [72236] LOG:  new timeline 3 forked off current database system timeline 2 before current recovery point 0/470000A0
Aug 06 21:13:19 pg-teach-02 patroni[72237]: 2023-08-06 21:13:19.784 UTC [72237] FATAL:  could not start WAL streaming: ERROR:  replication slot "pg_teach_02" does not exist
Aug 06 21:13:19 pg-teach-02 patroni[72237]: 2023-08-06 21:13:19.766 UTC [72237] LOG:  fetching timeline history file for timeline 3 from primary server
Aug 06 21:13:19 pg-teach-02 patroni[72232]: 2023-08-06 21:13:19.712 UTC [72232] LOG:  database system is ready to accept read-only connections
Aug 06 21:13:19 pg-teach-02 patroni[72236]: 2023-08-06 21:13:19.712 UTC [72236] LOG:  invalid record length at 0/470000A0: wanted 24, got 0
Aug 06 21:13:19 pg-teach-02 patroni[72236]: 2023-08-06 21:13:19.712 UTC [72236] LOG:  consistent recovery state reached at 0/470000A0
Aug 06 21:13:19 pg-teach-02 patroni[72236]: 2023-08-06 21:13:19.671 UTC [72236] LOG:  entering standby mode
Aug 06 21:13:19 pg-teach-02 patroni[72236]: 2023-08-06 21:13:19.671 UTC [72236] LOG:  database system was shut down at 2023-08-06 21:13:18 UTC
Aug 06 21:13:19 pg-teach-02 patroni[72232]: 2023-08-06 21:13:19.640 UTC [72232] LOG:  listening on Unix socket "./.s.PGSQL.5432"


root@pg-teach-01:/home# patronictl -c /etc/patroni.yml list
+ Cluster: pgteachcluster --+---------+-----------+----+-----------+
| Member      | Host        | Role    | State     | TL | Lag in MB |
+-------------+-------------+---------+-----------+----+-----------+
| pg-teach-01 | 10.128.0.36 | Leader  | running   |  3 |           |
| pg-teach-02 | 10.128.0.32 | Replica | running   |  2 |         0 |
| pg-teach-03 | 10.128.0.24 | Replica | streaming |  3 |         0 |
+-------------+-------------+---------+-----------+----+-----------+


```
