```
PGPASSWORD=pgsuper pgbench -U postgres --host=127.0.0.1 -i testing
PGPASSWORD=pgsuper pgbench -U postgres --host=127.0.0.1 -c10 -C --jobs=4 --progress=4 --time=60 --verbose-errors  testing
```
