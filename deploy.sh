docker stack deploy \
	-c docker-compose.yml \
	-c services/database/docker-compose.yml \
	-c services/keycloak/docker-compose.yml \
	-c services/monitoring/docker-compose.yml \
	-c services/nginx/docker-compose.yml \
	-c services/spark/docker-compose.yml \
	etl-project
	
	# -c services/frontend/docker-compose.yml \
