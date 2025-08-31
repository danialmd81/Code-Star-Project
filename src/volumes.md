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
| alertmanager_data | local | worker2 | alertmanager | Alertmanager data | Active |
| grafana_data | local | worker3 | grafana | Grafana dashboards and data | Active |
| registry_data | local | worker3 | registry | Docker Registry storage | Active |
| backup_data | **bind** | worker3 | backup | Database backups storage | TODO |
| spark_history_data | **bind** | worker3 | spark-history-server | Spark job history logs | TODO |
| certbot_data | **bind** | master-2 | certbot | SSL certificates and verification | TODO |
| frontend_data | local | Any | frontend | Frontend static files | Active |
| prometheus_data | local | Any | prometheus | Prometheus TSDB storage | Active |
| spark_data | local | Any | spark-master | Spark master data | Active |
| spark_worker_data | local | Any | spark-worker | Spark worker data | Active |
