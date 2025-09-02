#!/bin/bash
while ! (echo >/dev/tcp/pg-0/5432) 2>/dev/null; do
	echo "Waiting for primary database at pg-0:5432..."
	sleep 2
done
echo "Primary database is available. Starting replica..."
exec /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh /opt/bitnami/scripts/postgresql-repmgr/run.sh
