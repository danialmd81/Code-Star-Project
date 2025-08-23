# PostgreSQL Database Service (with Backup & HA)

This service provides a **central PostgreSQL database** for your ETL platform, with automated backups and high-availability (HA) via replication and automated failover.

---

## Components

- **database**: Main PostgreSQL instance (`postgres:15-alpine`)
- **backup**: Automated backup container (`prodrigestivill/postgres-backup-local`)
- **replica**: Standby PostgreSQL replica for HA/failover

---

## Configuration

### Environment Variables

Set these in your `.env` file (recommended for security):

- `POSTGRES_DB`: Database name (default: `etl_db`)
- `POSTGRES_USER`: Main DB user (default: `postgres`)
- `POSTGRES_PASSWORD`: Main DB password (default: `postgres`)
- Replica credentials can be customized as needed.

### Volumes

- `centraldb_data`: Persists main DB data.
- `replica_data`: Persists replica data.
- `./init`: Place SQL/init scripts for main DB.
- `./replica-init`: Place SQL/init scripts for replica.
- `./backups`: Stores backup files.

### Networks

- `etl-network`: Isolates DB traffic from other services.

---

## Backup & Restore

- **Automated Backups**: Nightly at 3 AM (`SCHEDULE: "0 3 * * *"`).
- **Retention**: 7 daily, 4 weekly, 6 monthly backups.
- **Restore**: Use backup files from `./backups` to restore via `psql` or container exec.

**Best Practice:**  
Test restores regularly to ensure backup integrity.

---

## High Availability (HA) & Automated Failover

- **Replica**: Standby DB for failover.  
  Configure streaming replication via custom scripts in `./replica-init`.
- **Failover**: Promote replica manually or automate with tools like [Patroni](https://patroni.readthedocs.io/en/latest/) or [pg_auto_failover](https://github.com/citusdata/pg_auto_failover).

---

### Automating Failover

#### 1. **What is repmgr?**

**repmgr** is an open-source tool for managing PostgreSQL replication and failover.  

- **Purpose:** It automates the setup, monitoring, and management of PostgreSQL streaming replication clusters.
- **Key Features:**  
  - Automatic failover: If the primary node fails, repmgr can promote a standby to primary.
  - Node registration: Easily add/remove nodes.
  - CLI tools for monitoring and management.
- **Why use it?**  
  - It’s mature, widely used, and integrates well with PostgreSQL.
  - No need for an external key-value store (unlike Patroni or Stolon).

---

#### 2. **How does repmgr work?**

- **Primary Node:** The main PostgreSQL server accepting writes.
- **Standby Nodes:** Replicas that continuously sync data from the primary.
- **repmgrd Daemon:** Runs on each node, monitors cluster health, and triggers failover if needed.
- **Replication:** Uses PostgreSQL’s built-in streaming replication.

**Failover Process:**  
If the primary fails, repmgrd promotes a standby to primary and updates the cluster state.

---

#### 3. **Architecture Diagram**

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

---

#### 4. **Step-by-Step Implementation**

##### **A. Prepare Your Docker Compose File**

We’ll use the official Bitnami image: [`bitnami/postgresql-repmgr`](https://hub.docker.com/r/bitnami/postgresql-repmgr).

````yaml
version: "3.8"

services:
  primary:
    image: bitnami/postgresql-repmgr:15
    environment:
      - POSTGRESQL_POSTGRES_PASSWORD=postgres
      - POSTGRESQL_USERNAME=postgres
      - POSTGRESQL_PASSWORD=postgres
      - POSTGRESQL_DATABASE=etl_db
      - REPMGR_PRIMARY_HOST=primary
      - REPMGR_PARTNER_NODES=primary,standby
      - REPMGR_NODE_NAME=primary
      - REPMGR_NODE_NETWORK_NAME=primary
      - REPMGR_PORT_NUMBER=5432
      - REPMGR_LOG_LEVEL=INFO
      - REPMGR_PASSWORD=repmgrpass
    volumes:
      - primary_data:/bitnami/postgresql
    networks:
      - etl-network
    ports:
      - "5432:5432"

  standby:
    image: bitnami/postgresql-repmgr:15
    environment:
      - POSTGRESQL_POSTGRES_PASSWORD=postgres
      - POSTGRESQL_USERNAME=postgres
      - POSTGRESQL_PASSWORD=postgres
      - POSTGRESQL_DATABASE=etl_db
      - REPMGR_PRIMARY_HOST=primary
      - REPMGR_PARTNER_NODES=primary,standby
      - REPMGR_NODE_NAME=standby
      - REPMGR_NODE_NETWORK_NAME=standby
      - REPMGR_PORT_NUMBER=5432
      - REPMGR_LOG_LEVEL=INFO
      - REPMGR_PASSWORD=repmgrpass
    volumes:
      - standby_data:/bitnami/postgresql
    networks:
      - etl-network

  backup:
    image: prodrigestivill/postgres-backup-local
    restart: always
    environment:
      POSTGRES_HOST: primary
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
      - primary

networks:
  etl-network:
    driver: bridge

volumes:
  primary_data:
    name: primary_data
  standby_data:
    name: standby_data
````

---

##### **B. Explanation of Each Service**

- **primary**: Main PostgreSQL node, managed by repmgr.
- **standby**: Replica node, automatically kept in sync and promoted if the primary fails.
- **backup**: Connects to the primary node and creates scheduled backups.

---

##### **C. How to Deploy**

1. **Start the cluster:**

   ```sh
   docker compose up -d
   ```

2. **Check cluster status:**

   ```sh
   docker exec -it <primary_container> repmgr cluster show
   ```

   This shows which node is primary and which are standbys.

---

##### **D. How Automated Failover Works**

- **repmgrd** runs on each node, monitoring the primary.
- If the primary fails, repmgrd promotes a standby to primary.
- The cluster continues to operate with minimal downtime.

---

##### **E. How Backups Work**

- The backup service connects to the primary and dumps its contents on a schedule.
- Backups are stored in the `./backups` directory.
- Restore using:

  ```sh
  docker exec -i primary psql -U postgres -d etl_db < ./backups/your_backup.sql
  ```

---

#### 5. **Industry Best Practices**

- **Persist data** with named volumes.
- **Automate backups** and test restores regularly.
- **Monitor cluster health** (consider Prometheus, Grafana).
- **Secure credentials** in environment variables or Docker secrets.
- **Restrict network access** to trusted services only.
- **Test failover** regularly to ensure reliability.

---

#### 6. **Common Pitfalls**

- Not persisting data (risk of data loss).
- Not testing restores (backups may be unusable).
- Not monitoring health (failures go unnoticed).
- Not securing credentials.

---

#### 7. **Security Considerations**

- Use strong passwords and rotate regularly.
- Restrict access to database.
- Enable SSL for database connections in production.
- Store secrets securely.

---

#### 8. **Further Learning Resources**

- [Bitnami PostgreSQL repmgr Docs](https://github.com/bitnami/containers/tree/main/bitnami/postgresql-repmgr)
- [repmgr Documentation](https://repmgr.org/)
- [PostgreSQL Streaming Replication](https://www.postgresql.org/docs/current/warm-standby.html)
- [Postgres Backup Local](https://github.com/prodrigestivill/docker-postgres-backup-local)

---

#### Resources

- [Patroni Docker Example](https://github.com/zalando/patroni/tree/master/docker)
- [PostgreSQL HA Concepts](https://www.postgresql.org/docs/current/warm-standby.html)
- [Docker Swarm Guide](https://docs.docker.com/engine/swarm/)

---

## Health Checks

- Main DB uses `pg_isready` for health monitoring.
- Use monitoring tools (Prometheus, OpenTelemetry) for deeper metrics.

---

## Security

- Store secrets in `.env` (never commit to git).
- Restrict network access to trusted services.
- Use strong passwords and rotate regularly.
- Enable SSL for production deployments.

---

## Usage

**Start the service:**

```sh
docker compose up -d
```

**Access the DB:**

```sh
docker exec -it centraldb psql -U $POSTGRES_USER -d $POSTGRES_DB
```

**Restore from backup:**

```sh
docker exec -i centraldb psql -U $POSTGRES_USER -d $POSTGRES_DB < ./backups/your_backup.sql
```

---

## Best Practices

- Use dedicated volumes for data and backups.
- Automate backups and test restores.
- Monitor DB health and replication.
- Secure credentials and restrict network access.
- Scale out with managed DB services for cloud deployments.

---

## Resources

- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [Docker Official Postgres Image](https://hub.docker.com/_/postgres)
- [Postgres Backup Local](https://github.com/prodrigestivill/docker-postgres-backup-local)
- [Postgres Replication Guide](https://www.postgresql.org/docs/current/warm-standby.html)

---
