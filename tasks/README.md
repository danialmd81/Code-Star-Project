# ETL Pipeline Project on Docker Swarm

This repository contains the implementation of an ETL (Extract, Transform, Load) pipeline deployed on a Docker Swarm cluster. The project focuses on creating a robust, scalable, and maintainable data processing architecture using Docker Swarm orchestration.

## Architecture Overview

This project utilizes a **Docker Swarm** cluster architecture with the following components:

- **Bastion Host**: Used for SSH access to the cluster
- **Master Nodes**: Manage the Swarm and have public IPs for external access
- **Worker Nodes**: Run application workloads and have private IPs for internal communication

### Cluster Topology

```
      m       m
     / \     / \
    w---w---w---w

m = manager node
w = worker node
```

- Managers orchestrate and control the cluster (master nodes with public IPs)
- Workers run application containers (worker nodes with private IPs)

### Key Components

1. **Authentication & User Management**
   - Keycloak for authentication and RBAC
   - PostgreSQL integration for user data storage

2. **Data Processing**
   - Apache Spark for distributed data processing
   - PostgreSQL for data storage and retrieval

3. **Observability Stack**
   - Grafana and Prometheus for monitoring
   - OpenTelemetry for distributed tracing
   - Loki for log aggregation

4. **CI/CD Pipeline**
   - Jenkins CI or GitHub Actions (to be determined)
   - Automated build, test, and deployment processes

5. **High Availability**
   - Database replica/master configuration
   - Self-recovery mechanisms for failed nodes

## Team Roles & Responsibilities

### Database

- Database backup & failover mechanisms
- Self-recovery & node management for Docker Swarm
- UI components for system management
- PostgreSQL optimization

### Keycloak & Spark

- User management & Keycloak implementation
- Metrics integration for authentication services
- Apache Spark setup and configuration
- Spark monitoring integration

### Monitoring

- Monitoring stack implementation (Grafana, Prometheus)
- Database monitoring and alerting
- OpenTelemetry integration
- Observability best practices documentation

### CI/CD

- CI/CD pipeline selection and implementation
- Pipeline visualization dashboards
- Integration with observability stack

## Getting Started

### Prerequisites

- Docker Engine with Swarm mode enabled
- SSH access to cluster nodes
- Ansible for automation tasks

### Access & Automation

- All nodes are accessed via SSH through a bastion host
- Ansible is used for server provisioning and configuration
- Custom SSH configuration required for seamless access

## Development Workflow

1. Code changes are submitted through pull requests
2. CI/CD pipeline validates and tests changes
3. Upon approval, changes are deployed to the Docker Swarm cluster
4. Monitoring dashboards provide visibility into system health and performance

## Documentation

Detailed documentation is available for:

- Database backup and recovery procedures
- Node management and self-recovery processes
- Monitoring and alerting configuration
- CI/CD pipeline usage
- Best practices for each component

## Architecture Benefits

- **Simplicity**: Docker Swarm offers a simpler approach compared to Kubernetes
- **Scalability**: Easily scale services across multiple nodes
- **Resilience**: Self-recovery mechanisms ensure high availability
- **Observability**: Comprehensive monitoring and alerting
- **Security**: Role-based access control and secure SSH
