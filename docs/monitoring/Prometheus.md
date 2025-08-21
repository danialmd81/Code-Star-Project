# Prometheus: Production-Grade Monitoring & Configuration Guide

## What is Prometheus?

**Prometheus** is an open-source monitoring and alerting toolkit designed for reliability and scalability. It collects metrics from configured targets at given intervals, stores them efficiently, and provides a powerful query language (PromQL) for analysis and alerting.

- **Why use Prometheus?**  
  Prometheus is widely adopted for cloud-native and containerized environments due to its pull-based metrics collection, flexible data model, and seamless integration with visualization tools like Grafana.

---

## Key Concepts

- **Metrics:** Numeric measurements about systems (CPU, memory, requests/sec).
- **Targets:** Endpoints exposing metrics (e.g., Node Exporter, cAdvisor).
- **Scraping:** Prometheus pulls metrics from targets at intervals.
- **PromQL:** Query language for aggregating and analyzing metrics.
- **Alerting:** Rules to notify on abnormal conditions.
- **Service Discovery:** Dynamically finds targets in cloud/container environments.

---

## Prometheus Architecture

```
+-------------------+        +-------------------+
|   Exporters       |        |   Application     |
| (Node, cAdvisor)  |        | (Custom Metrics)  |
+--------+----------+        +--------+----------+
         |                            |
         v                            v
+---------------------------------------------+
|           Prometheus Server                 |
|  - Scrapes metrics from targets             |
|  - Stores time-series data                  |
|  - Evaluates alerting rules                 |
+----------------+----------------------------+
                 |
                 v
+----------------+----------------------------+
|           Alertmanager                      |
|  - Handles alerts from Prometheus           |
|  - Sends notifications (email, Slack, etc.) |
+----------------+----------------------------+
                 |
                 v
+----------------+----------------------------+
|           Grafana                           |
|  - Visualizes metrics via dashboards        |
+---------------------------------------------+
```

---

## Prometheus Configuration (`prometheus.yml`)

The main configuration file is `prometheus.yml`. Key sections:

### 1. Global Settings

```yaml
global:
  scrape_interval: 15s    # How often to scrape targets (default: 1m)
  evaluation_interval: 15s # How often to evaluate rules (default: 1m)
  scrape_timeout: 10s     # Timeout for scraping targets
```

### 2. Scrape Configs

Defines which targets to scrape and how.

```yaml
scrape_configs:
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['localhost:8080']
```

- **job_name:** Logical name for the group of targets.
- **static_configs:** List of endpoints to scrape.
- **service_discovery_configs:** For dynamic environments (Kubernetes, Docker Swarm, EC2, etc.).

### 3. Alerting

Configure where alerts are sent.

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
```

### 4. Rule Files

Define alerting and recording rules.

```yaml
rule_files:
  - "rules/alerts.yml"
  - "rules/recording.yml"
```

---

## Production Considerations

### 1. Storage & Retention

- **TSDB (Time Series Database):**  
  Stores metrics on disk.  
  Configure retention to balance disk usage and historical data needs.

  ```yaml
  --storage.tsdb.retention.time=15d
  --storage.tsdb.path=/prometheus
  ```

- **Best Practice:**  
  Use dedicated persistent volumes for `/prometheus` data.

### 2. High Availability

- **Prometheus is not natively HA.**  
  Use multiple instances with federation or external solutions (e.g., Cortex, Thanos) for redundancy and long-term storage.

### 3. Security

- **Network:**  
  Restrict access to Prometheus UI and API (firewalls, reverse proxies).
- **Authentication:**  
  Prometheus does not provide built-in auth; use a proxy (e.g., NGINX) for authentication.
- **TLS:**  
  Use HTTPS for secure communication.

### 4. Service Discovery

- **Static:**  
  Manually list targets.
- **Dynamic:**  
  Integrate with cloud providers, Kubernetes, Docker Swarm, etc.

### 5. Resource Limits

- Set memory and CPU limits in container environments to prevent resource exhaustion.

### 6. Monitoring Prometheus

- Scrape Prometheus’s own `/metrics` endpoint for self-monitoring.

---

## Example: Docker Compose Integration

See your `docker-compose.yml` for a production-ready stack:

- **Volumes:** Persistent storage for metrics.
- **Networks:** Isolated communication.
- **Healthchecks:** Automated container health monitoring.
- **Resource Limits:** Prevents overuse.
- **Alertmanager, Grafana, Node Exporter, cAdvisor:** Integrated for full observability.

---

## Common Pitfalls

- **No persistent storage:** Metrics lost on restart.
- **Unrestricted UI/API access:** Security risk.
- **Too frequent scraping:** High resource usage.
- **No alerting rules:** No notifications for issues.

---

## Best Practices

- Always use persistent volumes.
- Secure endpoints with firewalls and proxies.
- Use service discovery for dynamic environments.
- Regularly review and tune scrape intervals.
- Monitor Prometheus itself.
- Document all alerting and recording rules.

---

## Learning Resources

- [Prometheus Official Docs](https://prometheus.io/docs/introduction/overview/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Awesome Prometheus](https://github.com/roaldnefs/awesome-prometheus)
- [Grafana Labs Tutorials](https://grafana.com/tutorials/)
- [Thanos (HA Prometheus)](https://thanos.io/)
- [Cortex (Scalable Prometheus)](https://cortexmetrics.io/)

---

## Summary Table

| Feature         | Description                          | Production Tip                |
|-----------------|--------------------------------------|-------------------------------|
| Metrics         | Numeric system/app data               | Use exporters for coverage    |
| Scraping        | Pull-based data collection            | Tune intervals for efficiency |
| Alerting        | Automated notifications               | Integrate with Alertmanager   |
| Storage         | Local TSDB, retention config          | Use persistent volumes        |
| Visualization   | Grafana dashboards                    | Secure Grafana UI             |
| Service Discovery | Dynamic target detection            | Use for cloud/K8s environments|
| Security        | Network, auth, TLS                    | Always restrict access        |

---

## ASCII Architecture Diagram

```
+-------------------+      +-------------------+
|   Exporters       | ---> |   Prometheus      | ---> | Alertmanager |
+-------------------+      +-------------------+      +-------------+
                                   |
                                   v
                              +---------+
                              | Grafana |
                              +---------+
```

---

## Next Steps

- Set up exporters for all critical infrastructure.
- Define alerting rules for key metrics.
- Secure your Prometheus and Grafana endpoints.
- Explore HA solutions for scaling.
- Continuously tune and review your monitoring setup.
