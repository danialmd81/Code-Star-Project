# Shared Storage Solutions for Docker Swarm

## Concept Overview

Shared storage solutions allow multiple nodes in a cluster to access the same storage, ensuring data persistence and availability across container relocations.

### Comparison Matrix

| Feature | NFS | GlusterFS | Ceph |
|---------|-----|-----------|------|
| Architecture | Client-server | Distributed | Distributed |
| Complexity | Low | Medium | High |
| Scalability | Limited | Good | Excellent |
| Use Case | Simple setups | Medium workloads | Enterprise scale |

## Implementation Details

### 1. NFS (Network File System)

**What**: Simple, traditional network storage protocol

```bash
# Server Setup
sudo apt install nfs-kernel-server
sudo mkdir -p /srv/nfs/docker-volumes
sudo chown nobody:nogroup /srv/nfs/docker-volumes
```

```bash
# Edit /etc/exports
/srv/nfs/docker-volumes *(rw,sync,no_subtree_check,no_root_squash)
```

```bash
# Client Setup
sudo apt install nfs-common
sudo mkdir -p /mnt/docker-volumes
sudo mount nfs-server:/srv/nfs/docker-volumes /mnt/docker-volumes
```

Docker Compose configuration:

````yaml
volumes:
  database_data:
    driver: local
    driver_opts:
      type: nfs
      o: addr=nfs-server,rw
      device: ":/srv/nfs/docker-volumes/postgres"
````

### 2. GlusterFS (Gluster File System)

**What**: Distributed file system for medium-scale deployments

```bash
# Install on all nodes
sudo apt install glusterfs-server

# Initialize cluster (on first node)
sudo gluster peer probe node2
sudo gluster peer probe node3

# Create volume
sudo gluster volume create docker-volumes replica 3 \
  node1:/gluster/docker \
  node2:/gluster/docker \
  node3:/gluster/docker force
```

Docker Compose configuration:

````yaml
volumes:
  database_data:
    driver: local
    driver_opts:
      type: glusterfs
      volumetype: replicate
      voluri: "gluster-node:/docker-volumes"
````

### 3. Ceph

**What**: Highly scalable distributed storage system

```bash
# Install Ceph (using cephadm)
curl --silent --remote-name --location https://github.com/ceph/ceph/raw/octopus/src/cephadm/cephadm
chmod +x cephadm
sudo ./cephadm add-repo --release octopus
sudo ./cephadm install
```

Docker Compose configuration:

````yaml
volumes:
  database_data:
    driver: rbd
    driver_opts:
      name: docker/postgres
      monitors: ceph-mon1:6789,ceph-mon2:6789
      user: admin
      keyring: /etc/ceph/ceph.client.admin.keyring
````

## Best Practices

1. **Performance Considerations**
   - Use SSDs for storage nodes
   - Configure proper network bandwidth
   - Monitor IOPS and latency

2. **High Availability**
   - NFS: Use multiple NFS servers with keepalived
   - GlusterFS: Configure replica sets
   - Ceph: Use multiple monitor nodes

3. **Security**
   - Implement network isolation
   - Use strong authentication
   - Encrypt data in transit

4. **Backup Strategy**
   - Regular snapshots
   - Off-site backups
   - Automated backup testing

## Examples

### Basic NFS Setup for PostgreSQL

````yaml
services:
  pg-0:
    volumes:
      - type: volume
        source: database_data
        target: /bitnami/postgresql
        volume:
          driver: local
          driver_opts:
            type: nfs
            o: addr=nfs.example.com,rw
            device: ":/exports/postgres"
````

### Real-World Architecture

```plaintext
[Docker Swarm Cluster]
    │
    ├── Manager Nodes
    │   └── Storage Control Plane
    │
    ├── Worker Nodes
    │   └── Storage Clients
    │
    └── Storage Backend
        ├── NFS Server(s)
        │   └── /exports/docker-volumes
        │
        ├── GlusterFS Cluster
        │   └── Replicated Volumes
        │
        └── Ceph Cluster
            ├── Monitor Nodes
            ├── OSD Nodes
            └── Manager Nodes
```

Remember to choose the solution that best fits your scale and complexity requirements:

- NFS: Small to medium deployments, simple setup
- GlusterFS: Medium deployments, better scalability
- Ceph: Large enterprise deployments, complex but highly scalable
