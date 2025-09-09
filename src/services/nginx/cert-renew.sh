#!/bin/bash
set -e

CERT_PATH="/srv/docker/volumes/certbot_data/live/dani-docker.ir/fullchain.pem"
KEY_PATH="/srv/docker/volumes/certbot_data/live/dani-docker.ir/privkey.pem"

# Remove old secrets (ignore errors if not exist)
docker secret rm ssl_cert || true
docker secret rm ssl_key || true

# Create new secrets
docker secret create ssl_cert "$CERT_PATH"
docker secret create ssl_key "$KEY_PATH"

# Force update services that use the secrets
docker service update --force project_nginx
docker service update --force project_keycloak
docker service update --force project_registry
