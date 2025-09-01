# Docker Swarm Logging Architecture

## Concept Overview

In a 5-node Docker Swarm cluster, logs are handled through:

1. Docker's built-in logging drivers
2. Log aggregation (Promtail + Loki)
3. Centralized storage and visualization (Grafana)

## Implementation Details

### 1. Docker Logging Configuration

Your services are correctly configured with json-file logging driver:

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
    tag: "{{.Name}}/{{.ID}}"
```

### 2. Log File Locations

Docker container logs are stored in:

- Default path: `/var/lib/docker/containers/<container-id>/<container-id>-json.log`
- One file per container
- Across all Swarm nodes

### 3. Promtail Configuration

Your current Promtail setup needs optimization. Here's the enhanced configuration:

```yaml
server:
  http_listen_port: 9080

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push
    tenant_id: default

scrape_configs:
  # Docker containers with service discovery
  - job_name: docker
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        regex: '/(.*)'
        target_label: 'container'
      - source_labels: ['__meta_docker_container_log_stream']
        target_label: 'logstream'
      - source_labels: ['__meta_docker_container_label_com_docker_swarm_service_name']
        target_label: 'service'
      - source_labels: ['__meta_docker_container_label_com_docker_swarm_node_id']
        target_label: 'node'

  # Service-specific configurations
  - job_name: postgres
    pipeline_stages:
      - match:
          selector: '{service=~".*postgres.*"}'
          stages:
            - regex:
                expression: '^(?P<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (?P<level>\w+): (?P<message>.*)$'
            - labels:
                level:

  - job_name: keycloak
    pipeline_stages:
      - match:
          selector: '{service=~".*keycloak.*"}'
          stages:
            - json:
                expressions:
                  level: level
                  logger: logger_name
            - labels:
                level:
                logger:

  - job_name: spark
    pipeline_stages:
      - match:
          selector: '{service=~".*spark.*"}'
          stages:
            - regex:
                expression: '(?P<timestamp>\d{2}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}) (?P<level>\w+) (?P<message>.*)'
            - labels:
                level:
```

### 4. Deployment Configuration

Update the Promtail service in docker-compose.yml:

```yaml
promtail:
  image: grafana/promtail:2.9.3
  command: -config.file=/etc/promtail/promtail.yaml
  configs:
    - source: promtail_config
      target: /etc/promtail/promtail.yaml
  volumes:
    - /var/log:/var/log:ro
    - /var/lib/docker/containers:/var/lib/docker/containers:ro
    - /var/run/docker.sock:/var/run/docker.sock:ro
  deploy:
    mode: global
    placement:
      constraints:
        - node.platform.os == linux
```

## Best Practices

1. **Log Rotation**
   - Set appropriate max-size and max-file values
   - Prevent disk space issues
   - Configure system-level logrotate

2. **Label Management**
   - Use meaningful labels for filtering
   - Include service name and environment
   - Add custom labels for specific needs

3. **Pipeline Stages**
   - Parse logs according to format
   - Extract relevant fields
   - Add useful labels

4. **Resource Management**
   - Monitor Promtail resource usage
   - Set appropriate limits
   - Configure buffer sizes

## Accessing Logs

### 1. Through Grafana

```logql
# View all container logs
{job="docker"}

# Filter by service
{service="postgres"}

# Filter by level
{service="keycloak"} | json | level="ERROR"

# Complex queries
{service=~"spark.*"} 
| logfmt 
| level=~"ERROR|WARN" 
| line_format "{{.timestamp}} [{{.level}}] {{.message}}"
```

### 2. Direct Access on Nodes

```bash
# List all container logs
docker ps -q | xargs -L 1 docker inspect --format '{{.LogPath}}'

# Tail specific service logs
docker service logs -f project_postgres

# View logs on specific node
ssh worker1 'tail -f /var/lib/docker/containers/*/project_postgres-*.log'
```

### 3. Monitoring Dashboard

Create a Grafana dashboard for log visualization:

```jsonc
// Example panel query
{
  "expr": "rate({job=\"docker\"}[5m])",
  "legendFormat": "{{service}}",
  "refId": "A"
}
```

## Common Issues & Solutions

1. **Missing Logs**

   ```bash
   # Check Promtail status
   docker service logs project_promtail
   
   # Verify permissions
   ls -la /var/lib/docker/containers
   ```

2. **High Resource Usage**

   ```yaml
   # Add to promtail config
   limit_config:
     readline_rate_limit: 1MB
     readline_burst_limit: 10MB
   ```

3. **Log Parsing Issues**

   ```yaml
   # Add debug stage
   pipeline_stages:
     - debug:
         log_line: true
   ```
