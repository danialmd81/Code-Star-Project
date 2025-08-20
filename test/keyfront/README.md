# Docker Compose Configuration for Keycloak in Production

## Directory Structure

To make this Docker Compose configuration work, you'll need to create the following directory structure:

```
keycloak/
├── docker-compose.yml      # Main configuration file
├── realm-config/           # Keycloak realm export files (.json)
├── ssl/                    # SSL certificates
│   ├── fullchain.pem
│   └── privkey.pem
├── nginx/
│   ├── nginx.conf          # Main Nginx configuration
│   └── conf.d/             # Site-specific configurations
│       └── keycloak.conf
├── certbot/
    ├── www/                # Let's Encrypt webroot
    └── conf/               # Let's Encrypt configuration
```

## Setup Instructions

1. **SSL Certificates**:
   Either place your existing certificates in the `ssl/` directory or use Let's Encrypt:

   ```bash
   mkdir -p certbot/www certbot/conf
   ```

2. **Start the Services**:

   ```bash
   docker-compose up -d
   ```

3. **Get Let's Encrypt Certificates** (if needed):

   ```bash
   docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d auth.yourdomain.com --email your-email@example.com --agree-tos --no-eff-email
   ```

4. **Reload Nginx** after getting certificates:

   ```bash
   docker-compose exec nginx nginx -s reload
   ```

## Detailed Explanation

### 1. Component Architecture

This setup uses two main components:

- **Keycloak**: The identity and access management service that handles authentication and authorization.
- **Nginx**: Acts as a reverse proxy providing SSL termination, security headers, and improved performance.

### 2. Keycloak Configuration

- **Production mode**: Uses optimized settings for performance
- **Memory settings**: JVM configuration tuned for production workloads
- **Cache configuration**: Set up for Kubernetes environment to allow for future scaling
- **Proxy settings**: Configured to work behind Nginx reverse proxy
- **Health checks**: Enables monitoring tools to verify Keycloak availability
- **Theme persistence**: Allows custom themes to persist across container restarts
- **Realm import**: Allows pre-configuring realms, clients, and roles

### 3. Nginx as Reverse Proxy

- **SSL termination**: Handles HTTPS connections so Keycloak doesn't have to
- **Security headers**: Adds modern security headers to prevent common web vulnerabilities
- **Let's Encrypt integration**: Automatic certificate issuance and renewal
- **HTTP to HTTPS redirect**: Ensures all traffic uses encrypted connections
- **WebSocket support**: Required for certain Keycloak features

### 4. Certbot for SSL Certificates

- **Automatic renewal**: Schedules certificate renewal every 12 hours (Let's Encrypt certificates last 90 days)
- **Volume sharing**: Shares certificates with Nginx

### 5. Networks and Volumes

- **Isolated network**: Creates a dedicated bridge network for security
- **Persistent volumes**: Ensures data and configuration survive container restarts
- **Local driver**: Uses local filesystem for storage (can be replaced with more advanced options in production)

### 6. Security Considerations

- **Secret management**: Passwords stored in external files with restricted permissions
- **HTTPS enforcement**: All traffic forced to use HTTPS
- **Modern TLS settings**: Only secure protocols and ciphers allowed
- **Headers**: Security headers prevent common web attacks
- **Resource limits**: Prevent DoS by resource exhaustion

## Best Practices Implemented

1. **High Availability**: Services configured to restart automatically if they fail
2. **Security**: SSL/TLS, security headers, and secret management
3. **Performance**: JVM tuning, Nginx caching and compression
4. **Monitoring**: Health checks for all services
5. **Resource Management**: CPU and memory limits to prevent resource starvation
6. **Backups**: Persistent volumes for data preservation
