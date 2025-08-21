# ETL Pipeline Project on Docker Swarm

Welcome to the ETL Pipeline Project! This guide will walk you through the architecture, setup, deployment, and operational steps for building a robust, scalable, and observable ETL solution using Docker Swarm, Ansible, and modern DevOps practices.

---

## 1. Architecture Overview

- **Docker Swarm Cluster**: Two manager nodes (public IP, SSH bastion) and four worker nodes (private IP) ([diagram.md](diagram/diagram.md)).
- **Bastion Host**: Secure SSH gateway for accessing all nodes.
- **Application Services**: Frontend, Backend, Nginx (reverse proxy), Keycloak (authentication), Apache Spark (ETL processing).
- **Database**: PostgreSQL master-replica setup with automated backup and failover ([Tasks/Project.md](Tasks/Project.md)).
- **Observability**: OpenTelemetry, Prometheus, Grafana, Loki, AlertManager.
- **CI/CD**: Choice between GitHub Actions and Jenkins CI for automated build, test, and deployment.

---

## 2. Prerequisites

- **Docker Engine** with Swarm mode enabled on all nodes.
- **SSH access** to all nodes via bastion host ([Nodes.md](Tasks/Nodes.md), [ssh config](~/.ssh/config)).
- **Ansible** installed for automation ([Docs/README.md](Docs/README.md)).
- **Custom SSH configuration** for seamless access ([ssh config](~/.ssh/config)).
- **.env files** for secrets and environment variables.

---

## 3. Node Setup

- Provision manager and worker nodes as described in [Tasks/Nodes.md](Tasks/Nodes.md).
- Configure SSH bastion access using your `~/.ssh/config` file.
- Ensure all nodes are reachable via SSH from your control machine.

---

## 4. Infrastructure Automation
  
- Use Ansible for provisioning and configuration:

  ```bash
  cd src/ansible
  ansible-playbook -i hosts.yml playbook.yml
  ```

  - `hosts.yml`: Inventory file listing all nodes.
  - `playbook.yml`: Main playbook for setup tasks.

---

## 5. Application Deployment

- Use Docker Compose files for service definitions.
- Deploy the stack to Swarm managers:

  ```bash
  docker stack deploy -c docker-compose.yml etl-stack
  ```

- Services include Frontend, Backend, Nginx, Keycloak, Spark, PostgreSQL.

---

## 6. Database Management

- PostgreSQL master-replica setup for high availability.
- Automated backups and failover mechanisms ([Tasks/Tasks.md](Tasks/Tasks.md)).
- All database operations are centralized under Parham's responsibility.

---

## 7. Authentication & User Management

- Keycloak deployed for SSO and RBAC ([Tasks/Tasks.md](Tasks/Tasks.md)).
- Keycloak integrated with PostgreSQL for user data.
- Frontend and backend configured to use Keycloak for authentication.

---

## 8. Observability & Monitoring

- OpenTelemetry collects metrics, logs, and traces.
- Prometheus and Grafana provide dashboards for infrastructure, applications, and pipelines.
- Loki aggregates logs; AlertManager sends notifications.

---

## 9. CI/CD Pipeline

- Choose between GitHub Actions or Jenkins CI ([Tasks/Tasks.md](Tasks/Tasks.md)).
- Pipelines automate build, test, and deployment.
- Use `docker stack deploy` for production releases.

---

## 10. Team Responsibilities

- **Parham**: Database backup, failover, self-recovery, PostgreSQL optimization.
- **Danial**: Keycloak authentication, Apache Spark setup.
- **Arman**: Monitoring stack, metrics collection, observability best practices.
- **Radmehr**: CI/CD implementation, pipeline visualization.

---

## 11. Best Practices

- Use SSH bastion for secure access.
- Store secrets in `.env` files, not in code.
- Validate configs before restarting services.
- Use healthchecks and backups for resilience.
- Enforce HTTPS/SSL for all communications.
- Monitor system health and set up alerts.

---

## 12. References & Further Reading

- [diagram.md](diagram/diagram.md): Visual architecture overview.
- [Tasks/Project.md](Tasks/Project.md): Detailed architecture and node setup.
- [Tasks/Tasks.md](Tasks/Tasks.md): Team responsibilities and task breakdown.
- [Docs/README.md](Docs/README.md): DevOps learning roadmap and tool explanations.

---

**Tip:** For deeper expertise, explore official documentation for Docker, Ansible, Keycloak, Prometheus, Grafana, and CI/CD tools. Practice hands-on, automate everything, and always
