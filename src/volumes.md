# Docker Swarm Volumes Configuration

This document details the volume configurations used in our Docker Swarm cluster.

## Volume Overview

| Volume Name | Driver | Node Placement | Service | Purpose | Status |
|------------|--------|----------------|----------|----------|--------|
| database_data | local | worker1 | pg-0 | PostgreSQL primary data directory | Active |
| loki_data | local | worker1 | loki | Loki logs storage | Active |
| replica_data | local | worker2 | pg-1 | PostgreSQL replica data directory | Active |
| pgadmin_data | local | worker2 | pgadmin | PgAdmin configuration and data | Active |
| keycloak_themes | local | worker2 | keycloak | Custom Keycloak themes | Active |
| grafana_data | local | worker3 | grafana | Grafana dashboards and data | Active |
| registry_data | local | worker3 | registry | Docker Registry storage | Active |
| frontend_data | local | Any | frontend | Frontend static files | Active |
| prometheus_data | local | Any | prometheus | Prometheus TSDB storage | Active |
| spark_data | local | Any | spark-master | Spark master data | Active |
| spark_worker_data | local | Any | spark-worker | Spark worker data | Active |

## Pending Volume Configurations

### Backup Volume

- **Location**: worker3
- **Path**: `/home/danial/backups`
- **Status**: TODO
- **Purpose**: Database backups storage

### Certbot Volume

- **Location**: master-2
- **Paths**:
  - `/home/danial/dockerize.ir`
  - `/home/danial/certbot/www`
- **Status**: TODO
- **Purpose**: SSL certificates and verification

### Spark History Server

- **Location**: worker3
- **Path**: `/home/danial/spark-logs:/spark-logs`
- **Status**: TODO
- **Purpose**: Spark job history logs

## Notes

- All volumes use the `local` driver for direct node storage
- Critical services have specific node placement constraints
- Backup and certificate volumes require host bind mounts
- Consider implementing backup strategies for persistent data
