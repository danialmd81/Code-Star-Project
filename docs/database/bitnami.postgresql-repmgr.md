# Bitnami PostgreSQL Repmgr Cluster

This document explains how to deploy, operate, and maintain a **high-availability PostgreSQL cluster** using the [Bitnami PostgreSQL Repmgr](https://hub.docker.com/r/bitnami/postgresql-repmgr) Docker image. It covers core concepts, configuration, best practices, and troubleshooting tips for junior DevOps engineers.

---

## What is PostgreSQL?

**PostgreSQL** is a powerful, open-source relational database system. It stores structured data and supports advanced features like transactions, replication, and extensibility.  

- **Use cases:** Web apps, analytics, data warehousing, and more.

---

## What is Repmgr?

**Repmgr** is an open-source tool for managing PostgreSQL replication and failover.

- **Purpose:** Automates setup, monitoring, and management of PostgreSQL streaming replication clusters.
- **Key features:** Node registration, monitoring, automatic failover, CLI tools.

---

## What is Bitnami PostgreSQL Repmgr?

**Bitnami PostgreSQL Repmgr** is a Docker image that bundles PostgreSQL and repmgr, making it easy to deploy HA clusters in containers.

- **Why use it?**  
  - Simplifies cluster setup and management.
  - Includes health checks, backup support, and production-ready defaults.
  - Works well with Docker Compose, Swarm, and Kubernetes.

---

## Architecture Overview

```

+-------------------+      +-------------------+
|   PostgreSQL DB   |<---->|   repmgrd daemon  |
|   (Primary Node)  |      | (Monitors health) |
+-------------------+      +-------------------+
        ^                        ^
        |                        |
+-------------------+      +-------------------+
|   PostgreSQL DB   |<---->|   repmgrd daemon  |
|   (Standby Node)  |      | (Monitors health) |
+-------------------+      +-------------------+

+-------------------+
|   Backup Service  |
| (Automated Dumps) |
+-------------------+

```

- **Primary node:** Accepts writes, replicates data to standbys.
- **Standby nodes:** Sync data from primary, ready to take over if primary fails.
- **repmgrd:** Monitors cluster, triggers failover.
- **Backup service:** Periodically saves database snapshots.

---

## How Does Failover Work?

- **repmgrd** runs on each node, monitoring the primary.
- If the primary fails, repmgrd promotes a standby to primary.
- Cluster continues with minimal downtime.
- No external key-value store required.

---

## Example Docker Compose Configuration

```yaml
version: "3.8"

services:
  database:
    image: bitnami/postgresql-repmgr:15
    environment:
      - REPMGR_NODE_NAME=database-1
      - REPMGR_NODE_ID=1
      - REPMGR_NODE_NETWORK_NAME=database-1
      - REPMGR_PRIMARY_HOST=database
      - REPMGR_PARTNER_NODES=database-1,replica-2
      - POSTGRESQL_POSTGRES_PASSWORD=postgres
      - POSTGRESQL_USERNAME=postgres
      - POSTGRESQL_PASSWORD=postgres
      - POSTGRESQL_DATABASE=etl_db
      - REPMGR_PASSWORD=repmgrpass
    volumes:
      - database_data:/bitnami/postgresql
      - ./init:/docker-entrypoint-initdb.d
    networks:
      - etl-network
    ports:
      - "5432:5432"

  replica:
    image: bitnami/postgresql-repmgr:15
    environment:
      - REPMGR_NODE_NAME=replica-2
      - REPMGR_NODE_ID=2
      - REPMGR_NODE_NETWORK_NAME=replica-2
      - REPMGR_PRIMARY_HOST=database
      - REPMGR_PARTNER_NODES=database-1,replica-2
      - POSTGRESQL_POSTGRES_PASSWORD=postgres
      - POSTGRESQL_USERNAME=postgres
      - POSTGRESQL_PASSWORD=postgres
      - POSTGRESQL_DATABASE=etl_db
      - REPMGR_PASSWORD=repmgrpass
    volumes:
      - replica_data:/bitnami/postgresql
      - ./replica-init:/docker-entrypoint-initdb.d
    networks:
      - etl-network

  backup:
    image: prodrigestivill/postgres-backup-local
    environment:
      POSTGRES_HOST: database
      POSTGRES_DB: etl_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      SCHEDULE: "0 3 * * *"
      BACKUP_KEEP_DAYS: 7
      BACKUP_KEEP_WEEKS: 4
      BACKUP_KEEP_MONTHS: 6
    volumes:
      - ./backups:/backups
    networks:
      - etl-network
    depends_on:
      - database

networks:
  etl-network:
    driver: bridge

volumes:
  database_data:
    name: database_data
  replica_data:
    name: replica_data
```

---

## Step-by-Step Deployment

1. **Start the cluster:**  
   `docker compose up -d`
2. **Check cluster status:**  
   `docker exec -it database repmgr cluster show`
3. **Test failover:**  
   Stop the primary: `docker stop database`  
   Check logs on replica: `docker logs replica`  
   Replica should promote itself.
4. **Restore primary:**  
   `docker start database`  
   It should rejoin as a standby.

---

## Industry Best Practices

- **Persist data** with named volumes.
- **Automate backups** and test restores regularly.
- **Monitor cluster health** (Prometheus, Grafana).
- **Secure credentials** with environment variables or Docker secrets.
- **Restrict network access** to trusted services only.
- **Test failover** regularly.

---

## Common Pitfalls

- Not persisting data (risk of data loss).
- Not testing restores (backups may be unusable).
- Not monitoring health (failures go unnoticed).
- Not securing credentials.

---

## Security Considerations

- Use strong passwords and rotate regularly.
- Restrict access to database and backup files.
- Enable SSL for database connections in production.
- Store secrets securely.

---

## Further Learning Resources

- [Bitnami PostgreSQL Repmgr Docs](https://github.com/bitnami/containers/tree/main/bitnami/postgresql-repmgr)
- [repmgr Documentation](https://repmgr.org/)
- [PostgreSQL Streaming Replication](https://www.postgresql.org/docs/current/warm-standby.html)
- [Postgres Backup Local](https://github.com/prodrigestivill/docker-postgres-backup-local)
