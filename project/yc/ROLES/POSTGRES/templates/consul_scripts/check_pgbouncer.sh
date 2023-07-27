#!/bin/bash
PGCONNECT_TIMEOUT=5 PGPASSWORD="GA5xrTQCHyzGrqrBR71J" psql -q -p 6432 -h 127.0.0.1 -U pgloader -d template1 -c "select 1;" || exit 3
