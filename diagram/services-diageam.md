## 1. **Frontend Service Diagram**

```mermaid
graph TD
  User((User)) -->|Upload CSV| Frontend[Frontend]
  Frontend -->|API Requests| Backend
  Frontend -->|Auth Request| Keycloak
  Frontend -->|Metrics & Logs| OpenTelemetry
  Frontend -.->|Dashboard| Grafana
```

**Explanation:**  

- The Frontend is the user-facing web UI.
- Users upload data and interact with the ETL pipeline.
- Authenticates via Keycloak (SSO).
- Sends API requests to the Backend.
- Exposes metrics/logs to OpenTelemetry and Grafana.

---

## 2. **Backend Service Diagram**

```mermaid
graph TD
  Frontend -->|API Requests| Backend[Backend]
  Backend -->|Data Storage| PostgreSQL
  Backend -->|Auth| Keycloak
  Backend -->|Data Processing| Spark
  Backend -->|Metrics & Logs| OpenTelemetry
  Backend -.->|Dashboard| Grafana
```

**Explanation:**  

- The Backend handles business logic, data validation, and transformation orchestration.
- Stores and retrieves data from PostgreSQL.
- Authenticates users via Keycloak.
- Orchestrates Spark jobs for data transformation.
- Sends metrics/logs to OpenTelemetry and Grafana.

---

## 3. **Keycloak Service Diagram**

```mermaid
graph TD
  User((User)) -->|1.Login| Frontend[Frontend]
  Frontend -->|2.OIDC Auth| Keycloak[Keycloak]
  Keycloak -->|3.Redirect| Frontend
  Frontend -->|4.API Requests| Backend[Backend]
  Backend -->|5.OIDC Auth| Keycloak
  Backend -->|6.Give Access| Frontend

  Grafana[Grafana] -->|OIDC Auth| Keycloak
  Keycloak -->|User Data| PostgreSQL[PostgreSQL]
  Keycloak -->|Metrics & Logs| OpenTelemetry[OpenTelemetry]
  Keycloak -.->|Admin Portal| Admin[Admin]
```

**Explanation:**  

- Keycloak provides authentication.
- Stores user data in PostgreSQL.
- Integrates with OpenTelemetry for monitoring.
- Provides an admin portal for user management.

---

## 4. **Spark Service Diagram**

```mermaid
graph TD
  Backend -->|Submit Job| Spark[Spark]
  Spark -->|Transform Data| PostgreSQL
  Spark -->|Metrics & Logs| OpenTelemetry
  Spark -->|Auth| Keycloak
```

**Explanation:**  

- Spark executes distributed data transformations.
- Receives jobs from the Backend.
- Reads/writes data to PostgreSQL.
- Authenticates via Keycloak.
- Sends metrics/logs to OpenTelemetry.

---

## 5. **PostgreSQL Service Diagram**

```mermaid
graph TD
  Backend -->|Read/Write| PostgreSQL
  Spark -->|Read/Write| PostgreSQL
  Keycloak -->|User Data| PostgreSQL
  PostgreSQL -->|Backup| BackupSystem
  PostgreSQL -->|Metrics & Logs| OpenTelemetry
  BackupSystem -->|Restore| PostgreSQL
```

**Explanation:**  

- Central data store for all services.
- Automatic backup and restore procedures.
- Monitored via OpenTelemetry.

---

## 6. **Nginx Service Diagram**

```mermaid
graph TD
  User -->|HTTPS Request| Nginx[Nginx]
  Nginx -->|Proxy| Frontend
  Nginx -->|Proxy| Keycloak
  Nginx -->|Proxy| Backend
```

**Explanation:**  

- Nginx acts as a reverse proxy, routing external traffic to internal services.
- Terminates SSL and enforces security policies.

---

## 7. **Observability Stack Diagram**

```mermaid
graph TD
  AllServices((All Services)) -->|Metrics & Logs| OpenTelemetry[OpenTelemetry Collector]
  AllServices -->|Host Metrics| NodeExporter[Node Exporter]
  AllServices -->|Container Metrics| cAdvisor[cAdvisor]
  OpenTelemetry -->|Logs| Loki[Loki]
  NodeExporter -->|Metrics| Prometheus
  cAdvisor -->|Metrics| Prometheus
  OpenTelemetry -->|Metrics| Prometheus[Prometheus]
  Promtail[Promtail] -->|Push Logs| Loki
  Prometheus -->|Data Source| Grafana[Grafana]
  Loki -->|Data Source| Grafana
  Grafana -->|Alerts| AlertManager[Alertmanager]
```

**Explanation:**  

- **OpenTelemetry Collector** gathers metrics and logs from all services.
- **Node Exporter** collects host-level metrics (CPU, memory, disk, etc.).
- **cAdvisor** collects container-level metrics (resource usage, performance).
- **Prometheus** stores metrics from OpenTelemetry, Node Exporter, and cAdvisor.
- **Loki** stores logs from OpenTelemetry and Promtail.
- **Promtail** ships logs from host files to Loki.
- **Grafana** visualizes metrics and logs from Prometheus and Loki, and sends alerts.
- **Alertmanager** handles alerts triggered by Grafana or Prometheus.

---

## 8. **Backup & HA Diagram**

```mermaid
graph TD
  PostgreSQL -->|Replication| PGReplica[(PostgreSQL Replica)]
  PostgreSQL -->|Backup| BackupSystem
  BackupSystem -->|Store| BackupStorage
  PGReplica -->|Failover| FailoverMechanism
  FailoverMechanism -->|Promote| PGReplica
```

**Explanation:**  

- PostgreSQL is replicated for high availability.
- Automated backups and failover mechanisms ensure resilience.

---

## 9. **CI/CD Pipeline Diagram**

```mermaid
graph TD
  Dev[Developer] -->|Push Code| CI/CD
  CI/CD -->|Build| DockerImages
  CI/CD -->|Test| TestStage
  CI/CD -->|Deploy| SwarmManagers
  SwarmManagers -->|Orchestrate| WorkerNodes
```

**Explanation:**  

- Developers push code to CI/CD (GitHub Actions/Jenkins).
- Pipeline builds, tests, and deploys Docker images to Swarm managers.
- Managers orchestrate deployment across worker nodes.

---

## **Summary Table: Service Interactions**

| Service     | Depends On         | Exposes To         | Observability      |
|-------------|--------------------|--------------------|--------------------|
| Frontend    | Backend, Keycloak  | User               | OpenTelemetry, Grafana |
| Backend     | PostgreSQL, Spark, Keycloak | Frontend      | OpenTelemetry, Grafana |
| Keycloak    | PostgreSQL         | All Services       | OpenTelemetry      |
| Spark       | PostgreSQL, Keycloak | Backend           | OpenTelemetry      |
| PostgreSQL  | BackupSystem, PGReplica | Backend, Spark, Keycloak | OpenTelemetry      |
| Nginx       | All Services       | User               | -                  |
| Observability Stack | All Services | Admins/DevOps      | -                  |
| Backup/HA   | PostgreSQL         | Admins/DevOps      | -                  |
| CI/CD       | SwarmManagers      | Developer          | -                  |

---

### **Best Practices & Tips**

- Keep each service on its own overlay network for isolation.
- Use internal service names for inter-service communication.
- Only expose Nginx to the public; keep other services internal.
- Monitor all services for health and performance.
- Automate backups and test restore procedures regularly.

---

### **Follow-Up Learning Resources**

- [Docker Compose Networking](https://docs.docker.com/compose/networking/)
- [Keycloak Integration Patterns](https://www.keycloak.org/docs/latest/server_admin/#_integration)
- [Spark on Docker](https://spark.apache.org/docs/latest/running-on-docker.html)
- [Prometheus & Grafana Monitoring](https://prometheus.io/docs/introduction/overview/)
- [CI/CD Best Practices](https://martinfowler.com/articles/continuousIntegration.html)
