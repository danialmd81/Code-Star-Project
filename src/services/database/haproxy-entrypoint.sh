#!/bin/sh
until nc -z pg-0 5432; do
	echo "Waiting for PostgreSQL primary..."
	sleep 2
done
exec haproxy -f /usr/local/etc/haproxy/haproxy.cfg
