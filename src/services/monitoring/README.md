# Creating a Monitoring Stack Docker Compose File

## Understanding the Components

1. **Prometheus**: An open-source monitoring and alerting toolkit. It collects metrics from configured targets at specified intervals, evaluates rule expressions, displays results, and can trigger alerts when specified conditions are observed.

2. **Grafana**: A visualization and analytics platform that lets you query, visualize, and alert on metrics regardless of where they're stored. It's commonly used to create dashboards for monitoring.

3. **OpenTelemetry**: A collection of tools, APIs, and SDKs used to instrument, generate, collect, and export telemetry data (metrics, logs, and traces).

4. **Alert Manager**: Handles alerts sent by client applications such as the Prometheus server. It takes care of deduplicating, grouping, and routing them to the correct receiver.

## Directory Structure Requirements

For this Docker Compose file to work correctly, you'll need to create the following directory structure and configuration files:

```
monitoring/
├── docker-compose.yml
├── prometheus/
│   ├── prometheus.yml
│   └── rules/
│       └── alert_rules.yml
├── grafana/
│   ├── provisioning/
│   │   ├── dashboards/
│   │   │   └── dashboard.yml
│   │   └── datasources/
│   │       └── datasource.yml
│   └── dashboards/
│       └── etl_dashboard.json
├── otel-collector/
│   └── config.yaml
└── alertmanager/
    └── alertmanager.yml
```

## Explanation of Key Elements

1. **Networks**:
   - `monitoring-network`: Internal network for monitoring components to communicate
   - `etl-network`: External network to connect to your application services

2. **Volumes**:
   - Persistent storage for Prometheus, Grafana, and Alert Manager data

3. **Services**:
   - **Prometheus**: Core metrics collection service with retention set to 15 days
   - **Grafana**: Visualization platform preconfigured with dashboards and data sources
   - **OpenTelemetry Collector**: Collects metrics, traces, and logs from your applications
   - **Alert Manager**: Manages and routes alerts based on configurable rules
   - **Node Exporter**: Collects host-level metrics (CPU, memory, disk, etc.)
   - **cAdvisor**: Collects container metrics

4. **Deployment Configuration**:
   - Resource limits to prevent services from consuming too much memory
   - Health checks to verify service availability
   - Placement constraints to ensure services run on appropriate nodes

## Next Steps

After creating this file, you'll need to:

1. Create the required configuration files (prometheus.yml, alertmanager.yml, etc.)
2. Deploy the stack to your Docker Swarm:

   ```bash
   docker stack deploy -c docker-compose.yml monitoring
   ```

3. Configure your application services to send metrics to OpenTelemetry Collector

---

````yaml
receivers:
  # OTLP receiver for traces, metrics, logs from instrumented apps
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

  # Prometheus receiver scrapes metrics endpoints from all services
  prometheus:
    config:
      scrape_configs:
        - job_name: "node-exporter"
          static_configs:
            - targets: ["node-exporter:9100"]
        - job_name: "cadvisor"
          static_configs:
            - targets: ["cadvisor:8080"]
        - job_name: "backend"
          static_configs:
            - targets: ["backend:8000"] # Adjust port/path as needed
        - job_name: "database"
          static_configs:
            - targets: ["database:9187"] # Use postgres_exporter for metrics
        - job_name: "frontend"
          static_configs:
            - targets: ["frontend:8080"] # Adjust port/path as needed
        - job_name: "keycloak"
          static_configs:
            - targets: ["keycloak:8080"] # Keycloak Prometheus metrics
        - job_name: "spark-master"
          static_configs:
            - targets: ["spark-master:8080"] # Spark master metrics
        - job_name: "spark-worker"
          static_configs:
            - targets: ["spark-worker:8081"] # Spark worker metrics
        - job_name: "nginx"
          static_configs:
            - targets: ["nginx-exporter:9113"] # Use nginx-prometheus-exporter

  # Filelog receiver for collecting logs from service log files
  filelog:
    include: [ "/var/log/*.log", "/var/log/**/*.log" ] # Adjust paths as needed
    start_at: beginning
    operators:
      - type: json_parser
        # If your logs are in JSON format, parse them for better structure

processors:
  batch:
    timeout: 10s
    send_batch_size: 512
  memory_limiter:
    check_interval: 1s
    limit_mib: 128
    spike_limit_mib: 32

exporters:
  prometheus:
    endpoint: "0.0.0.0:8889" # Metrics endpoint for Prometheus to scrape
  loki:
    endpoint: "http://loki:3100/loki/api/v1/push" # Loki endpoint for logs
  logging:
    loglevel: info # For debugging, outputs to Collector logs

service:
  pipelines:
    metrics:
      receivers: [otlp, prometheus]
      processors: [batch, memory_limiter]
      exporters: [prometheus]
    logs:
      receivers: [filelog, otlp]
      processors: [batch, memory_limiter]
      exporters: [loki]
    traces:
      receivers: [otlp]
      processors: [batch, memory_limiter]
      exporters: [logging] # Replace/add Jaeger/Tempo if you use distributed tracing
````

---

### **How This Works**

- **Receivers**:  
  - `prometheus`: Scrapes metrics from all service endpoints.
  - `filelog`: Reads logs from service log files.
  - `otlp`: Accepts telemetry from instrumented apps (traces, metrics, logs).
- **Processors**:  
  - `batch`: Groups data for efficient export.
  - `memory_limiter`: Prevents Collector from using too much memory.
- **Exporters**:  
  - `prometheus`: Exposes metrics for Prometheus to scrape.
  - `loki`: Pushes logs to Loki.
  - `logging`: Outputs to Collector logs (for debugging).
- **Service Pipelines**:  
  - `metrics`: Collects and exports metrics.
  - `logs`: Collects and exports logs.
  - `traces`: Collects traces (add Jaeger/Tempo exporter if needed).

---

### **Best Practices & Tips**

- **Adjust target ports/paths** for each service as needed.
- **Use exporters** that match your monitoring stack (Prometheus, Loki, Jaeger, etc.).
- **Secure endpoints**: Only expose metrics/logs internally.
- **Rotate logs** so filelog receiver can access them reliably.
- **Monitor Collector health** and resource usage.

---

### **Learning Resources**

- [OpenTelemetry Collector Docs](https://opentelemetry.io/docs/collector/)
- [Prometheus Monitoring](https://prometheus.io/docs/introduction/overview/)
- [Grafana Loki Docs](https://grafana.com/docs/loki/latest/)
- [nginx-prometheus-exporter](https://github.com/nginxinc/nginx-prometheus-exporter)
- [postgres_exporter](https://github.com/prometheus-community/postgres_exporter)

---
