# Creating a Docker Compose File for Apache Spark Service

## Understanding Apache Spark in Your ETL Architecture

Before diving into the Docker Compose configuration, let's understand Apache Spark's role in your ETL architecture:

1. According to your diagram, Spark is a core component that:
   - Receives SQL queries from the backend
   - Handles data transformations (filtering, aggregation, column operations)
   - Processes data as part of your ETL pipeline
   - Returns transformed data back to your central database

2. Spark needs to be integrated with:
   - Your backend services that send processing requests
   - The monitoring stack for observability
   - The central database for data storage

# Apache Spark Service for ETL Processing

This directory contains the Docker Compose configuration and related files for running Apache Spark as part of our ETL processing pipeline.

## Architecture

The Spark cluster consists of:

1. **Spark Master**: Coordinates job execution and resource allocation
2. **Spark Workers**: Execute the actual data processing tasks
3. **History Server**: Maintains job history and logs for debugging and monitoring

## Directory Structure

spark/
├── docker-compose.yml  # Docker Compose configuration
├── conf/               # Spark configuration files
│   └── spark-defaults.conf
├── data/               # Shared data directory
└── spark-logs/         # Directory for Spark event logs

## Configuration

Spark is configured with the following settings:

- Master node with 2 CPUs and 2GB memory
- Two worker nodes, each with 2 CPUs and 3GB memory
- History server for job tracking and debugging
- Dynamic allocation of resources for optimal performance
- OpenTelemetry integration for monitoring

## Usage

### Starting the Spark Cluster

```bash
# Create required directories
mkdir -p conf data spark-logs

# Start the Spark services
docker-compose up -d
```

### Accessing Spark UIs

- Spark Master UI: <http://localhost:8080>
- Spark Worker UI: <http://localhost:8081>
- Spark History Server: <http://localhost:18080>

### Submitting Jobs

Jobs can be submitted to the cluster using the Spark submit command:

```bash
docker exec -it spark-master spark-submit \
  --master spark://spark-master:7077 \
  --class org.example.SparkApp \
  /path/to/your/jar/file.jar
```

### Integration with ETL Pipeline

This Spark cluster is designed to work with the backend service that:

1. Generates SparkSQL queries based on user input
2. Configures the pipeline with transformation operations
3. Executes the pipeline using Spark's processing capabilities
4. Stores results back to the central database

## Maintenance

### Logs

Spark logs are stored in the `spark-logs` directory and can be viewed through the History Server UI.

### Scaling

To adjust the number of worker nodes:

```bash
docker-compose up -d --scale spark-worker=3  # Increases to 3 workers
```

### Monitoring

Spark metrics are forwarded to the OpenTelemetry collector and can be viewed in Grafana dashboards.

## Explanation of Key Components

### 1. Service Components

- **Spark Master**:
  - The control center of your Spark cluster that manages worker nodes
  - Exposes port 8080 for web UI access and 7077 for Spark application connections
  - Has resource limits to prevent excessive resource consumption

- **Spark Workers**:
  - Processing nodes that perform the actual data transformations
  - Connected to the Spark master using the `SPARK_MASTER_URL` environment variable
  - Configured with specific memory and CPU allocations
  - Set up for replication (2 workers by default)

- **Spark History Server**:
  - Stores and serves completed Spark job information
  - Makes debugging and performance analysis easier
  - Requires a shared volume for logs

### 2. Volumes

- **spark-data**: Persistent storage for the master node
- **spark-worker-data**: Persistent storage for worker nodes
- **Local directory mounts**: For configuration and data sharing between host and containers

### 3. Network Configuration

The services connect to the `etl-network` which is defined as an external network, allowing communication with other services in your ETL pipeline.

### 4. Health Checks

Each service includes health checks to ensure they're running correctly:

- Uses `curl` to check the web UI ports
- Configures retry attempts and timeouts for robustness
- Includes a start period to allow for initial setup time

### 5. Resource Management

- Services have specific CPU and memory allocations
- Both limits (maximum usage) and reservations (guaranteed resources) are defined
- Prevents resource contention and ensures stable operation

## How to Deploy This Configuration

1. **Create directory structure**:

   ```bash
   mkdir -p src/services/spark/conf src/services/spark/data src/services/spark/spark-logs
   ```

2. **Create configuration files**:

   ```bash
   # Create the spark-defaults.conf file
   touch src/services/spark/conf/spark-defaults.conf
   # Add the configuration content from above
   ```

3. **Deploy with Docker Swarm**:

   ```bash
   # Navigate to the spark directory
   cd src/services/spark
   
   # Deploy as a standalone service
   docker-compose up -d
   
   # Or deploy as part of your swarm
   docker stack deploy -c docker-compose.yml spark
   ```

4. **Verify deployment**:

   ```bash
   # Check service status
   docker ps | grep spark
   
   # Access the Spark Master UI
   # Open a browser and navigate to http://localhost:8080
   ```

## Integration with Other Services

### 1. Backend Integration

Your backend services should be configured to connect to Spark using:

```
spark://spark-master:7077
```

### 2. Monitoring Integration

The Spark services expose metrics that can be collected by your OpenTelemetry collector. The `spark-defaults.conf` includes the necessary configuration to enable this integration.

### 3. Data Flow

According to your architecture diagram:

1. Backend generates SparkSQL and sends it to Spark
2. Spark processes the data using the configured operations
3. Results are stored back to the central database

## Best Practices Applied in This Configuration

1. **Idempotency**: Services can be started, stopped, and restarted without issues
2. **Parameterization**: Uses environment variables instead of hardcoded values
3. **Documentation**: Comprehensive README explains the purpose and usage
4. **Resource management**: Proper limits and reservations for stable operation
5. **Health checking**: Services are monitored for availability
6. **Observability**: Integration with your monitoring stack
7. **Scalability**: Worker nodes can be scaled based on demand

This configuration provides a solid foundation for your Spark processing needs within the ETL pipeline, following DevOps best practices while ensuring integration with the rest of your architecture.### 2. Monitoring Integration

The Spark services expose metrics that can be collected by your OpenTelemetry collector. The `spark-defaults.conf` includes the necessary configuration to enable this integration.

### 3. Data Flow

According to your architecture diagram:

1. Backend generates SparkSQL and sends it to Spark
2. Spark processes the data using the configured operations
3. Results are stored back to the central database

## Best Practices Applied in This Configuration

1. **Idempotency**: Services can be started, stopped, and restarted without issues
2. **Parameterization**: Uses environment variables instead of hardcoded values
3. **Documentation**: Comprehensive README explains the purpose and usage
4. **Resource management**: Proper limits and reservations for stable operation
5. **Health checking**: Services are monitored for availability
6. **Observability**: Integration with your monitoring stack
7. **Scalability**: Worker nodes can be scaled based on demand
