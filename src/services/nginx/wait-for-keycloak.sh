#!/bin/sh
until nc -z keycloak 8080; do
	echo "Waiting for Keycloak at keycloak:8080..."
	sleep 2
done
exec nginx -g 'daemon off;'
