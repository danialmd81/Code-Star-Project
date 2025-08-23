## 1. **What Is PostgreSQL?**

**PostgreSQL** is a powerful, open-source relational database system. It’s widely used for storing structured data and supports advanced features like replication, high availability, and extensibility.

---

## 2. **Why Automated Backups?**

**Automated backups** protect your data from accidental loss, corruption, or disasters. They allow you to restore your database to a previous state. In production, regular backups are critical for business continuity.

- **Tool Used:**  
  `prodrigestivill/postgres-backup-local` is a popular Docker image that automates PostgreSQL backups on a schedule.

---

## 3. **What Is High Availability (HA) and Failover?**

**High Availability (HA)** ensures your database remains accessible even if part of your infrastructure fails.  
**Failover** is the process of switching to a standby database if the primary fails.

- **Patroni:**  
  Patroni is an open-source tool that automates PostgreSQL failover and leader election. It uses a distributed key-value store (like etcd) to coordinate which node is the primary.

---

## 4. **Architecture Overview**

Here’s how the components fit together:

```
+-------------------+      +-------------------+      +-------------------+
|   PostgreSQL DB   |<---->|     Patroni       |<---->|      etcd         |
|   (Primary Node)  |      | (Failover Agent)  |      | (Cluster State)   |
+-------------------+      +-------------------+      +-------------------+
        ^                        ^                            ^
        |                        |                            |
        |                        |                            |
        |                        |                            |
+-------------------+      +-------------------+      +-------------------+
|   PostgreSQL DB   |<---->|     Patroni       |<---->|      etcd         |
|   (Replica Node)  |      | (Failover Agent)  |      | (Cluster State)   |
+-------------------+      +-------------------+      +-------------------+

+-------------------+
|   Backup Service  |
| (Automated Dumps) |
+-------------------+
```

---

## 5. **Step-by-Step Implementation**

### **A. Prepare Your Docker Compose File**

You already have a good starting point in your docker-compose.yml. Here’s what each service does:

- **database**: Main PostgreSQL instance.
- **replica**: Standby PostgreSQL instance.
- **backup**: Automated backup container.
- **etcd**: Distributed key-value store for Patroni.
- **patroni**: Manages PostgreSQL HA and failover.

### **B. Persistent Storage**

Use **named volumes** for database data. This ensures data persists even if containers restart or move between nodes.

```yaml
volumes:
  database_data:
    name: database_data
  replica_data:
    name: replica_data
  patroni_data:
    name: patroni_data
```

### **C. Automated Backups**

The backup service connects to your database and creates regular dumps.

**Key settings:**

- Schedule backups using environment variables.
- Store backups in a persistent volume (`./backups:/backups`).

**Best Practice:**  
Test your restore process regularly to ensure backups are usable.

### **D. Patroni for Automated Failover**

**How Patroni Works:**

- Each PostgreSQL node runs Patroni.
- Patroni monitors the health of the database.
- Patroni uses etcd to coordinate which node is the leader (primary).
- If the primary fails, Patroni promotes a replica automatically.

**Configuration:**

- Patroni needs access to etcd.
- Each Patroni instance points to its own PostgreSQL data directory.

**Best Practice:**  
Run multiple Patroni nodes for redundancy. Secure etcd with authentication and firewalls.

### **E. Health Checks**

Use `pg_isready` to monitor database health. This allows Docker to restart unhealthy containers.

### **F. Networking**

Use a dedicated Docker network (`etl-network`) to isolate database traffic.

---

## 6. **Deployment Steps**

### **Step 1: Initialize Docker Swarm**

```sh
docker swarm init
```

### **Step 2: Deploy the Stack**

```sh
docker stack deploy -c docker-compose.yml etl-db
```

### **Step 3: Monitor Services**

Check that all services are running:

```sh
docker service ls
```

### **Step 4: Test Automated Failover**

- Stop the primary database container.
- Patroni should detect the failure and promote the replica.
- Check Patroni logs and etcd state.

### **Step 5: Test Backups and Restore**

- Verify backup files are created in `./backups`.
- Restore a backup using:

  ```sh
  docker exec -i database psql -U $POSTGRES_USER -d $POSTGRES_DB < ./backups/your_backup.sql
  ```

---

## 7. **Industry Best Practices**

- **Persist data** with named volumes.
- **Automate backups** and test restores.
- **Monitor health** with Prometheus or OpenTelemetry.
- **Secure credentials** in `.env` files (never commit secrets).
- **Restrict network access** to trusted services.
- **Scale out** with managed DB services for cloud deployments.
- **Secure etcd** with authentication and firewalls.

---

## 8. **Common Pitfalls**

- Not persisting data (risk of data loss).
- Not testing restores (backups may be unusable).
- Not securing etcd (risk of unauthorized failover).
- Not monitoring health (failures go unnoticed).

---

## 9. **Security Considerations**

- Use strong passwords and rotate regularly.
- Restrict access to database and etcd.
- Enable SSL for database connections in production.
- Store secrets securely (use Docker secrets or environment variables).

---

## 10. **Further Learning Resources**

- [Patroni Documentation](https://patroni.readthedocs.io/en/latest/)
- [PostgreSQL Replication](https://www.postgresql.org/docs/current/warm-standby.html)
- [Docker Swarm Guide](https://docs.docker.com/engine/swarm/)
- [Postgres Backup Local](https://github.com/prodrigestivill/docker-postgres-backup-local)

---

**Summary:**  
You’ll run PostgreSQL with automated backups and Patroni for HA/failover. Use named volumes for persistence, monitor health, and secure your setup. Test failover and restore processes regularly to ensure reliability in production.
