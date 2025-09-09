#!/bin/sh
until nc -z keycloak 8080; do
	echo "Waiting for Keycloak at keycloak:8080..."
	sleep 2
done

until nc -z spark-master 7077; do
	echo "Waiting for Spark Master at spark-master:7077..."
	sleep 2
done

exec nginx -g 'daemon off;'
