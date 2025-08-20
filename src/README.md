# Master Swarm Configuration for ETL Project

## Deployment Instructions

1. **Label your swarm nodes**:

   ```bash
   # Label manager nodes
   docker node update --label-add role=manager manager1
   docker node update --label-add role=manager manager2
   
   # Label worker nodes with capabilities
   docker node update --label-add compute=high worker1
   docker node update --label-add storage=high worker2
   docker node update --label-add compute=medium worker3
   ```

2. **Create required networks**:

   ```bash
   docker network create --driver overlay --attachable etl-network
   docker network create --driver overlay --attachable monitoring-network
   ```

3. **Deploy the stack**:

   ```bash
   docker stack deploy -c central-swarm.yml etl-stack
   ```

4. **Verify deployment**:

   ```bash
   docker stack services etl-stack
   ```

This configuration:

- References each service from its component Docker Compose file
- Adds appropriate deployment constraints based on node roles and capabilities
- Configures resource limits and restart policies
- Uses existing networks and volumes defined in component files

The services will be distributed across your 5-node Docker Swarm cluster according to the constraints and preferences defined.
