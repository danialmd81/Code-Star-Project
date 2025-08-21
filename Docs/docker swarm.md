# Docker Swarm: Beginner-Friendly Guide

---

## What is Docker Swarm?

**Docker Swarm** is Docker’s built-in solution for clustering and orchestrating containers. It lets you manage a group of Docker nodes (servers) as a single, highly available, and scalable system. This is essential for running production workloads reliably.

### Key Concepts

- **Node:** Any machine (physical or virtual) running Docker Engine and participating in the Swarm.
- **Manager Node:** Controls and manages the cluster, schedules tasks, and maintains cluster state using the Raft consensus algorithm.
- **Worker Node:** Executes containers (called tasks) as instructed by managers.
- **Service:** The definition of containers to run, including image, replicas, networks, and configuration.
- **Task:** An individual running container in the Swarm, managed by the orchestrator.
- **Stack:** A collection of services that make up an application, defined in a Compose file.

---

## Swarm Architecture

```
┌─────────────────────────────┐     ┌─────────────────────────────┐
│       Manager Node 1        │     │       Manager Node 2        │
│  (Leader) ┌──────────────┐  │     │        ┌──────────────┐     │
│           │ Swarm API    │  │     │        │ Replica of   │     │
│           │ Orchestrator │  │     │        │ Swarm State  │     │
│           │ Scheduler    │  │     │        │              │     │
│           │ Raft Store   │  │     │        │              │     │
│           └──────────────┘  │     │        └──────────────┘     │
└─────────────────────────────┘     └─────────────────────────────┘
                │                               │
                └───────────────────────────────┘
                                │
                                ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Worker Node 1 │     │   Worker Node 2 │     │   Worker Node 3 │
│  ┌───────────┐  │     │  ┌───────────┐  │     │  ┌───────────┐  │
│  │Container 1│  │     │  │Container 2│  │     │  │Container 3│  │
│  └───────────┘  │     │  └───────────┘  │     │  └───────────┘  │
│  ┌───────────┐  │     │  ┌───────────┐  │     │  ┌───────────┐  │
│  │Container 4│  │     │  │Container 5│  │     │  │Container 6│  │
│  └───────────┘  │     │  └───────────┘  │     │  └───────────┘  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

---

## Getting Started

### Prerequisites

- **Docker Engine** installed on all hosts (version 1.12+).
- **Network connectivity** between all nodes.
- **Open ports:**
  - TCP 2377 (cluster management)
  - TCP/UDP 7946 (node communication)
  - UDP 4789 (overlay network traffic)

---

## Networking in Swarm

### Overlay Networks

**Overlay networks** allow containers on different nodes to communicate securely.

```bash
docker network create --driver overlay --attachable mynetwork
docker service create --name myservice --network mynetwork nginx
```

### Ingress Network

The **ingress network** is a special overlay network for load balancing traffic to services with published ports. It’s created automatically when you initialize a swarm.

---

## Storage in Swarm

Docker Swarm does **not** provide native distributed storage. For persistent data:

- Use **local volumes** (data stays on the node).
- Use **external storage** (NFS, GlusterFS, Ceph, or cloud solutions like AWS EFS).

Example:

```bash
docker service create \
  --name db \
  --mount type=volume,source=dbdata,destination=/var/lib/mysql \
  mysql:8.0
```

---

## Security Features

- **Mutual TLS:** All nodes use encrypted communication and authenticate each other.
- **Autolock:** Protects encryption keys for swarm communication.

  ```bash
  docker swarm init --autolock
  docker swarm update --autolock=true
  ```

- **Secrets Management:** Securely provide sensitive data (passwords, certs) to containers.

  ```bash
  echo "mypassword" | docker secret create db_password -
  docker service create \
    --name db \
    --secret db_password \
    --env POSTGRES_PASSWORD_FILE=/run/secrets/db_password \
    postgres
  ```

---

## Monitoring and Scaling

- **View service logs:**  
  `docker service logs webapp`
- **Monitor tasks:**  
  `watch docker service ps webapp`
- **Scale a service:**  
  `docker service scale webapp=10`
- **Auto-scaling:** Requires external tools (e.g., Prometheus + custom scripts).

---

## Best Practices

1. **Manager Nodes:** Use an odd number (3, 5, 7) for high availability. Don’t overload managers with workloads.
2. **Worker Nodes:** Add more for horizontal scaling. Use placement constraints for workload distribution.
3. **Network Segmentation:** Use separate overlay networks for different app tiers.
4. **Secrets Management:** Always use Docker secrets for sensitive info.
5. **Health Checks:** Implement health checks for all services.

   ```bash
   docker service create \
     --name webapp \
     --health-cmd "curl -f http://localhost/ || exit 1" \
     --health-interval 5s \
     --health-retries 3 \
     --replicas 3 \
     nginx
   ```

6. **Backup:** Regularly backup swarm state.

   ```bash
   tar -czf swarm-backup.tar.gz /var/lib/docker/swarm/
   ```

---

## Common Docker Swarm Commands

### Cluster Management

- **Initialize Swarm:**  
  `docker swarm init`
- **Join Swarm:**  
  `docker swarm join --token <token> <manager-ip>:2377`
- **List Nodes:**  
  `docker node ls`

### Stack Management

- **Deploy Stack:**  
  `docker stack deploy -c <compose-file> <stack-name>`
- **List Stacks:**  
  `docker stack ls`
- **List Services in Stack:**  
  `docker stack services <stack-name>`
- **List Tasks in Stack:**  
  `docker stack ps <stack-name>`
- **Remove Stack:**  
  `docker stack rm <stack-name>`

### Service Management

- **Create Service:**  
  `docker service create --name <service-name> <image>`
- **List Services:**  
  `docker service ls`
- **Inspect Service:**  
  `docker service inspect <service-name>`
- **Scale Service:**  
  `docker service scale <service-name>=<replica-count>`
- **Update Service:**  
  `docker service update --image <new-image> <service-name>`
- **Remove Service:**  
  `docker service rm <service-name>`

### Node Management

- **Drain Node:**  
  `docker node update --availability drain <node-name>`
- **Activate Node:**  
  `docker node update --availability active <node-name>`
- **Remove Node:**  
  `docker node rm <node-name>`

### Useful Options

- `--detach=false`: Run commands in foreground.
- `--with-registry-auth`: Pass registry authentication for private images.
- `--limit-cpu`, `--limit-memory`: Set resource limits.
- `--publish <host-port>:<container-port>`: Expose service ports via ingress.

---

## Common Pitfalls

- Using outdated Compose file versions (`version: "2"` or lower).
- Not securing manager nodes.
- Forgetting to scale services for redundancy.

---

## Learning Resources

- [Docker Swarm Official Docs](https://docs.docker.com/engine/swarm/)
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [Docker Networking](https://docs.docker.com/network/)
- [Docker Secrets Management](https://docs.docker.com/engine/swarm/secrets/)
- Books:  
  - "Docker in Practice"  
  - "Docker: Up & Running"
- Online Courses:  
  - Docker Mastery (Udemy)  
  - Docker Swarm Mastery (Udemy)
- Tutorials:  
  - [Play with Docker Classroom](https://training.play-with-docker.com/)  
  - [Docker Labs](https://github.com/docker/labs)
- Community:  
  - Docker Forums  
  - Stack Overflow
