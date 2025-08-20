# Adding Centralized Database, Grafana, and Prometheus to the ETL Architecture

## Detailed Explanation of the New Architecture Components

### 1. Centralized Database Implementation

#### What's Changed?

In the original architecture, we had separate databases:

- **KeycloakDB**: For user authentication and management
- **PostgreSQL**: For ETL pipeline data
- **PipelineStore**: For pipeline configurations

Now, we've unified these into one **Central Database** that handles all data storage needs.

#### Technical Implementation Details

**1. Database Schema Organization:**

- We'll use PostgreSQL schemas to logically separate different data domains:

  ```sql
  -- Create schemas for different data domains
  CREATE SCHEMA keycloak;
  CREATE SCHEMA etl_data;
  CREATE SCHEMA pipeline_config;
  CREATE SCHEMA monitoring;
  ```

**2. Connection Pooling:**

- PgBouncer is crucial for managing multiple connections to a centralized database:

  ```yaml
  # pgbouncer.ini example configuration
  [databases]
  * = host=centraldb.internal port=5432
  
  [pgbouncer]
  pool_mode = transaction
  max_client_conn = 1000
  default_pool_size = 20
  ```

**3. High Availability Configuration:**

- For production, we'd implement PostgreSQL replication:

  ```yaml
  # postgresql.conf on primary
  wal_level = replica
  max_wal_senders = 10
  wal_keep_segments = 32
  ```

**4. Access Control:**

- Role-based access control at the database level:

  ```sql
  -- Create application roles
  CREATE ROLE keycloak_app WITH LOGIN PASSWORD 'secure_password';
  CREATE ROLE etl_app WITH LOGIN PASSWORD 'secure_password';
  CREATE ROLE reporting_app WITH LOGIN PASSWORD 'secure_password';
  
  -- Grant schema permissions
  GRANT ALL PRIVILEGES ON SCHEMA keycloak TO keycloak_app;
  GRANT ALL PRIVILEGES ON SCHEMA etl_data TO etl_app;
  GRANT SELECT ON SCHEMA etl_data TO reporting_app;
  ```

### 2. Prometheus Implementation

#### Technical Components

**1. Prometheus Server Configuration:**

- Basic `prometheus.yml` configuration:

  ```yaml
  global:
    scrape_interval: 15s
    evaluation_interval: 15s
  
  scrape_configs:
    - job_name: 'centraldb'
      static_configs:
        - targets: ['centraldb:9187']  # PostgreSQL exporter
    
    - job_name: 'keycloak'
      static_configs:
        - targets: ['keycloak:8080']
    
    - job_name: 'backend'
      static_configs:
        - targets: ['backend:8080']
    
    - job_name: 'spark'
      static_configs:
        - targets: ['spark-master:7777']
  ```

**2. Service Discovery in Kubernetes:**

- For dynamic environments, Kubernetes service discovery is preferable:

  ```yaml
  - job_name: 'kubernetes-services'
    kubernetes_sd_configs:
      - role: service
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        action: keep
        regex: true
  ```

**3. Key Metrics to Collect:**

- Database: Connections, query performance, table sizes
- Application: Request rates, error rates, response times
- System: CPU, memory, disk utilization
- ETL Process: Pipeline execution times, record counts

### 3. Grafana Implementation

#### Dashboard Design

**1. Main Overview Dashboard:**

- System health metrics
- Active users and requests
- ETL pipeline status
- Database performance

**2. ETL Pipeline Dashboard:**

- Pipeline execution metrics
- Success/failure rates
- Processing times
- Data volume trends

**3. Database Performance Dashboard:**

- Query performance
- Connection pools
- Table growth
- Slow queries

**4. Infrastructure Dashboard:**

- Node health
- Container resource usage
- Network traffic
- Storage utilization

#### Alert Configuration

Configure Grafana alerts for critical conditions:

```yaml
# Example alert rule in Grafana
name: High Database CPU Usage
expr: avg by (instance) (rate(node_cpu{mode!="idle",instance=~"$instance"}[1m])) * 100 > 80
for: 5m
labels:
  severity: warning
  service: database
annotations:
  summary: Database CPU high (instance {{ $labels.instance }})
  description: "Database CPU usage is above 80% for 5 minutes\n  VALUE = {{ $value }}%"
```

## Best Practices and Real-World Considerations

### 1. Database Management

- **Connection Pooling**: Essential for a centralized database to handle multiple services efficiently
- **Regular Vacuum and Analyze**: Maintain database performance with scheduled maintenance
- **Index Optimization**: Regularly review and optimize indexes for query performance
- **Schema Versioning**: Implement schema migration tools like Flyway or Liquibase

### 2. Monitoring Best Practices

- **Golden Signals Monitoring**: Focus on latency, traffic, errors, and saturation
- **Alert Fatigue Prevention**: Only alert on actionable conditions
- **Dashboard Hierarchy**: Create dashboards for different user personas (operators, developers, management)
- **SLO Monitoring**: Define and track Service Level Objectives for key components

### 3. Security Considerations

- **Database Access Control**: Fine-grained permissions based on service requirements
- **Data Encryption**: Implement encryption at rest and in transit
- **Audit Logging**: Enable database audit logging for sensitive operations
- **Secrets Management**: Use a secure solution like HashiCorp Vault for database credentials

### 4. Performance Considerations

- **Query Optimization**: Regular review of slow queries
- **Connection Management**: Properly size connection pools based on workload
- **Caching Strategies**: Implement appropriate caching layers to reduce database load
- **Resource Allocation**: Right-size database resources based on monitoring data

## Common Pitfalls to Avoid

1. **Overloading the Central Database**:
   - Solution: Implement proper connection pooling and query optimization
   - Consider read replicas for reporting workloads

2. **Excessive Metrics Collection**:
   - Solution: Be selective about what metrics to collect and store
   - Implement appropriate retention policies

3. **Alert Storms**:
   - Solution: Use alert grouping and intelligent routing
   - Implement escalation policies and silencing mechanisms

4. **Database Schema Conflicts**:
   - Solution: Maintain clear ownership boundaries between services
   - Implement schema versioning and migration strategies

5. **Monitoring Blind Spots**:
   - Solution: Regularly review monitoring coverage
   - Implement black-box monitoring in addition to white-box monitoring

---

# Streamlining the Observability Stack: Removing Loki and Jaeger

## Implementation Considerations

### OpenTelemetry Configuration

Adjust your OpenTelemetry collector configuration to focus only on metrics:

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024
  memory_limiter:
    check_interval: 1s
    limit_mib: 400

exporters:
  prometheus:
    endpoint: 0.0.0.0:8889
    namespace: etl_project
  
service:
  pipelines:
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [prometheus]
```

### Prometheus Configuration

Ensure Prometheus is configured to scrape metrics from both the OpenTelemetry collector and directly from components that expose Prometheus metrics:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'otel-collector'
    static_configs:
      - targets: ['otel-collector:8889']
  
  - job_name: 'centraldb'
    static_configs:
      - targets: ['centraldb-exporter:9187']
  
  - job_name: 'spark'
    static_configs:
      - targets: ['spark-master:8080']
```

### Grafana Dashboards

With the focus on metrics, prioritize these Grafana dashboards:

1. **System Overview Dashboard**
   - Key health metrics for all components
   - Resource utilization trends
   - Error rates and availability

2. **ETL Performance Dashboard**
   - Pipeline execution metrics
   - Data processing rates
   - Success/failure statistics

3. **Database Performance Dashboard**
   - Query performance
   - Connection metrics
   - Storage utilization
   - Transaction rates

---
