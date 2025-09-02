#!/bin/bash
while ! (echo >/dev/tcp/database/5432) 2>/dev/null; do
	echo "Waiting for database at database:5432..."
	sleep 2
done
exec /opt/keycloak/bin/kc.sh "$@"
