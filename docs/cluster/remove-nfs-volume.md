# How to Safely Remove an NFS Volume from a Docker Swarm Cluster

When using NFS-backed Docker volumes in a Swarm cluster, it's important to remove both the Docker volume reference on all nodes and the actual data on the NFS server. Follow these steps to fully remove an NFS volume:

---

## 1. Remove the Docker Volume from All Hosts

On every node where the container using the volume has run (manager or worker), remove the Docker volume:

```bash
docker volume rm <volume_name>
```

- Replace `<volume_name>` with your actual volume name (e.g., `pgadmin_data`).
- If you are unsure which nodes have used the volume, you can run `docker volume ls` on each node to check.

---

## 2. Remove the Volume Data from the NFS Server

SSH into the NFS server that exports the volume directory. Then, delete the directory for the volume:

```bash
ssh <nfs_user>@<nfs_server_ip>
sudo rm -rf /srv/docker/volumes/<volume_name>
```

- Replace `<nfs_user>` and `<nfs_server_ip>` with your NFS server's user and IP address.
- Replace `<volume_name>` with the actual directory name.

---

## 3. (Optional) Post-Removal Steps

### a. Recreate the NFS Volume Directory

If you need to recreate the volume directory (for example, for `pgadmin_data`), run the following commands on the NFS server:

```bash
sudo mkdir -p /srv/docker/volumes/pgadmin_data
sudo chown 5050:5050 /srv/docker/volumes/pgadmin_data
```

Adjust the directory name and ownership as needed for your use case.

### b. Clean Up NFS Exports

If you no longer need to export this directory, remove or comment out the corresponding line in `/etc/exports` on the NFS server and reload exports:

```bash
sudo exportfs -ra
```

---

## Summary

- Remove the Docker volume from all Swarm nodes that have used it.
- Delete the actual data directory from the NFS server.
- (Optional) Recreate the NFS directory if needed.
- (Optional) Clean up NFS export configuration.

This ensures the volume is fully removed from your cluster and storage.
