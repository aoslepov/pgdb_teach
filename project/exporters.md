```
-- node_exporter
curl http://127.0.0.1:9100/metrics

# HELP node_network_carrier Network device property: carrier
# TYPE node_network_carrier gauge
node_network_carrier{device="eth0"} 1
node_network_carrier{device="lo"} 1
# HELP node_network_carrier_changes_total Network device property: carrier_changes_total
# TYPE node_network_carrier_changes_total counter
node_network_carrier_changes_total{device="eth0"} 2
node_network_carrier_changes_total{device="lo"} 0
# HELP node_network_carrier_down_changes_total Network device property: carrier_down_changes_total
# TYPE node_network_carrier_down_changes_total counter
node_network_carrier_down_changes_total{device="eth0"} 1
node_network_carrier_down_changes_total{device="lo"} 0
# HELP node_network_carrier_up_changes_total Network device property: carrier_up_changes_total
# TYPE node_network_carrier_up_changes_total counter
node_network_carrier_up_changes_total{device="eth0"} 1
node_network_carrier_up_changes_total{device="lo"} 0
# HELP node_network_device_id Network device property: device_id
# TYPE node_network_device_id gauge
node_network_device_id{device="eth0"} 0
node_network_device_id{device="lo"} 0
# HELP node_network_dormant Network device property: dormant
# TYPE node_network_dormant gauge
node_network_dormant{device="eth0"} 0
node_network_dormant{device="lo"} 0



-- postgres exporter
curl http://127.0.0.1:9101/metrics
# TYPE pg_settings_wal_recycle gauge
pg_settings_wal_recycle{server="127.0.0.1:5432"} 1
# HELP pg_settings_wal_retrieve_retry_interval_seconds Server Parameter: wal_retrieve_retry_interval [Units converted to seconds.]
# TYPE pg_settings_wal_retrieve_retry_interval_seconds gauge
pg_settings_wal_retrieve_retry_interval_seconds{server="127.0.0.1:5432"} 5
# HELP pg_settings_wal_segment_size_bytes Server Parameter: wal_segment_size [Units converted to bytes.]
# TYPE pg_settings_wal_segment_size_bytes gauge
pg_settings_wal_segment_size_bytes{server="127.0.0.1:5432"} 1.6777216e+07
# HELP pg_settings_wal_sender_timeout_seconds Server Parameter: wal_sender_timeout [Units converted to seconds.]
# TYPE pg_settings_wal_sender_timeout_seconds gauge
pg_settings_wal_sender_timeout_seconds{server="127.0.0.1:5432"} 60
# HELP pg_settings_wal_skip_threshold_bytes Server Parameter: wal_skip_threshold [Units converted to bytes.]
# TYPE pg_settings_wal_skip_threshold_bytes gauge
pg_settings_wal_skip_threshold_bytes{server="127.0.0.1:5432"} 2.097152e+06
# HELP pg_settings_wal_writer_delay_seconds Server Parameter: wal_writer_delay [Units converted to seconds.]
# TYPE pg_settings_wal_writer_delay_seconds gauge
pg_settings_wal_writer_delay_seconds{server="127.0.0.1:5432"} 0.2
# HELP pg_settings_wal_writer_flush_after_bytes Server Parameter: wal_writer_flush_after [Units converted to bytes.]
# TYPE pg_settings_wal_writer_flush_after_bytes gauge
pg_settings_wal_writer_flush_after_bytes{server="127.0.0.1:5432"} 1.048576e+06
# HELP pg_settings_work_mem_bytes Server Parameter: work_mem [Units converted to bytes.]
# TYPE pg_settings_work_mem_bytes gauge
pg_settings_work_mem_bytes{server="127.0.0.1:5432"} 4.194304e+06
# HELP pg_settings_zero_damaged_pages Server Parameter: zero_damaged_pages
# TYPE pg_settings_zero_damaged_pages gauge
pg_settings_zero_damaged_pages{server="127.0.0.1:5432"} 0
# HELP pg_stat_activity_count number of connections in this state
# TYPE pg_stat_activity_count gauge



--pgbouncer exporter
curl http://127.0.0.1:9102/metrics
pgbouncer_databases 1
# HELP pgbouncer_databases_current_connections Current number of connections for this database
# TYPE pgbouncer_databases_current_connections gauge
pgbouncer_databases_current_connections{database="pgbouncer",force_user="pgbouncer",host="",name="pgbouncer",pool_mode="statement",port="6432"} 0
# HELP pgbouncer_databases_disabled 1 if this database is currently disabled, else 0
# TYPE pgbouncer_databases_disabled gauge
pgbouncer_databases_disabled{database="pgbouncer",force_user="pgbouncer",host="",name="pgbouncer",pool_mode="statement",port="6432"} 0
# HELP pgbouncer_databases_max_connections Maximum number of allowed connections for this database
# TYPE pgbouncer_databases_max_connections gauge
pgbouncer_databases_max_connections{database="pgbouncer",force_user="pgbouncer",host="",name="pgbouncer",pool_mode="statement",port="6432"} 0
# HELP pgbouncer_databases_paused 1 if this database is currently paused, else 0
# TYPE pgbouncer_databases_paused gauge
pgbouncer_databases_paused{database="pgbouncer",force_user="pgbouncer",host="",name="pgbouncer",pool_mode="statement",port="6432"} 0
# HELP pgbouncer_databases_pool_size Maximum number of server connections
# TYPE pgbouncer_databases_pool_size gauge
pgbouncer_databases_pool_size{database="pgbouncer",force_user="pgbouncer",host="",name="pgbouncer",pool_mode="statement",port="6432"} 2
# HELP pgbouncer_databases_reserve_pool Maximum number of additional connections for this database
# TYPE pgbouncer_databases_reserve_pool gauge
pgbouncer_databases_reserve_pool{database="pgbouncer",force_user="pgbouncer",host="",name="pgbouncer",pool_mode="statement",port="6432"} 0
# HELP pgbouncer_exporter_build_info A metric with a constant '1' value labeled by version, revision, branch, goversion from which pgbouncer_exporter was built, and the goos and goarch for the build.
# TYPE pgbouncer_exporter_build_info gauge
pgbouncer_exporter_build_info{branch="master",goarch="amd64",goos="linux",goversion="go1.18.1",revision="cafbe516eedd89fd33543105cb0567dd02e1937e",tags="netgo static_build",version="0.7.0"} 1
# HELP pgbouncer_free_clients Count of free clients
# TYPE pgbouncer_free_clients gauge
pgbouncer_free_clients 49
# HELP pgbouncer_free_servers Count of free servers
# TYPE pgbouncer_free_servers gauge
pgbouncer_free_servers 0
# HELP pgbouncer_in_flight_dns_queries Count of in-flight DNS queries
# TYPE pgbouncer_in_flight_dns_queries gauge
pgbouncer_in_flight_dns_queries 0
# HELP pgbouncer_login_clients Count of clients in login state
# TYPE pgbouncer_login_clients gauge
pgbouncer_login_clients 0
# HELP pgbouncer_pools Count of pools
# TYPE pgbouncer_pools gauge
pgbouncer_pools 1
```
