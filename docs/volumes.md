# Docker Swarm Volumes Configuration

This document details the volume configurations used in our Docker Swarm cluster.

## Volume Overview

| Volume Name | Driver | Node Placement | Service | Purpose | Status |
|------------|--------|----------------|----------|----------|--------|
| dockerize.ir | **bind** | master-2 | certbot | SSL certificates and verification | TODO |
| certbot/www | **bind** | master-2 | certbot | SSL certificates and verification | TODO |
|||||||
| database_data | NFS(master-2) | manager | pg-0 | PostgreSQL primary data directory | Active |
| keycloak_themes | NFS(master-2) | worker2 | keycloak | Custom Keycloak themes | Active |
| prometheus_data | NFS(master-2) | worker | prometheus | Prometheus TSDB storage | Active |
| spark_data | NFS(master-2) | worker | spark-master | Spark master data | Active |
| spark_history_data | NFS(master-2) | worker3 | spark-history-server | Spark job history logs | TODO |
|||||||
| grafana_data | NFS(master-1) | worker3 | grafana | Grafana dashboards and data | Active |
| replica_data | NFS(master-1) | worker | pg-1 | PostgreSQL replica data directory | Active |
| registry_data | NFS(master-1) | worker3 | registry | Docker Registry storage | Active |
| pgadmin_data | NFS(master-1) | worker2 | pgadmin | PgAdmin configuration and data | Active |
|||||||
| alertmanager_data | NFS(worker1) | worker2 | alertmanager | Alertmanager data | Active |
| backup_data | NFS(worker1) | worker3 | backup | Database backups storage | TODO |
| loki_data | NFS(worker1) | manager | loki | Loki logs storage | Active |
| spark_worker_data | NFS(worker1) | worker | spark-worker | Spark worker data | Active |
