# PostgreSQL Database Service (with Backup & HA)

This service provides a **central PostgreSQL database** for your ETL platform, with automated backups and high-availability (HA) via replication.

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

## High Availability (HA)

- **Replica**: Standby DB for failover.  
  Configure streaming replication via custom scripts in `./replica-init`.
- **Failover**: Promote replica manually or automate with tools like [Patroni](https://patroni.readthedocs.io/en/latest/) or [pg_auto_failover](https://github.com/citusdata/pg_auto_failover).

**Best Practice:**  
Monitor replication lag and automate failover for production.

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
