## Understanding the Requirements

Based on 2.md, you need to implement user management with three access levels:

1. System Administrator
2. Data Manager
3. Analyst

Keycloak will handle authentication and access control rather than building these features from scratch.

## Architecture Overview

Your architecture diagram shows a Docker Compose network with Authentication & Frontend Services, where Keycloak is positioned as the SSO (Single Sign-On) provider working alongside Nginx as a reverse proxy.

The authentication flow works as follows:

1. User accesses the Frontend
2. Frontend sends an auth request to Keycloak
3. Keycloak issues a token to the Frontend
4. Frontend validates the token with the Backend
5. Upon validation, the user can access the application based on their role

## Implementation Steps

### 1. Deploy Keycloak with Docker Compose

You already have a foundation in README.md and docker-compose.yml. Let's enhance and customize this for your ETL project:

```yaml
version: '3.8'

volumes:
  postgres_data:
    driver: local
  keycloak_themes:
    driver: local
  frontend_data:
    driver: local

networks:
  keycloak-network:
    driver: bridge

services:
  # PostgreSQL database for Keycloak
  postgres:
    image: postgres:15-alpine
    container_name: etl-postgres
    restart: unless-stopped
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./postgres-init:/docker-entrypoint-initdb.d
      - ./secrets/postgres_password.txt:/run/secrets/postgres_password:ro
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
    networks:
      - keycloak-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U keycloak"]
      interval: 10s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G

  # Keycloak server
  keycloak:
    image: quay.io/keycloak/keycloak:22.0.1
    container_name: etl-keycloak
    restart: unless-stopped
    volumes:
      - keycloak_themes:/opt/keycloak/themes
      - ./realm-config:/opt/keycloak/data/import
    environment:
      KC_DB: postgres
      KC_DB_URL_HOST: postgres
      KC_DB_URL_DATABASE: keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD_FILE: /run/secrets/postgres_password
      KC_HOSTNAME_STRICT: "false"
      KC_HOSTNAME_STRICT_HTTPS: "false"
      KC_HTTP_ENABLED: "true"
      KC_PROXY: edge
      KC_HEALTH_ENABLED: "true"
      KEYCLOAK_ADMIN_PASSWORD_FILE: /run/secrets/keycloak_admin_password
      KEYCLOAK_ADMIN: admin
      # ETL-specific realm configuration
      KC_FEATURES: token-exchange,admin-fine-grained-authz
      # Import realm on startup
      KC_FEATURES_ENABLED: preview
      KC_HTTP_RELATIVE_PATH: /auth
    volumes:
      - ./secrets/keycloak_admin_password.txt:/run/secrets/keycloak_admin_password:ro
      - ./secrets/postgres_password.txt:/run/secrets/postgres_password:ro
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - keycloak-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/auth/health/ready"]
      interval: 30s
      timeout: 10s
      retries: 3
    command: 
      - start
      - --optimized
      - --import-realm
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G

  # Nginx reverse proxy
  nginx:
    image: nginx:1.25-alpine
    container_name: etl-nginx
    restart: unless-stopped
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./certbot/www:/var/www/certbot:ro
      - ./certbot/conf:/etc/letsencrypt:ro
      - ./ssl:/etc/nginx/ssl:ro
    ports:
      - "80:80"
      - "443:443"
    networks:
      - keycloak-network
    depends_on:
      - keycloak
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M

  # Certificate renewal service
  certbot:
    image: certbot/certbot:latest
    container_name: etl-certbot
    volumes:
      - ./certbot/www:/var/www/certbot:rw
      - ./certbot/conf:/etc/letsencrypt:rw
    depends_on:
      - nginx
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait $${!}; done;'"
    networks:
      - keycloak-network

  # Frontend application
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: etl-frontend
    restart: unless-stopped
    networks:
      - keycloak-network
    depends_on:
      - keycloak
      - nginx
    volumes:
      - frontend_data:/usr/share/nginx/html
    environment:
      - KEYCLOAK_URL=https://auth.yourdomain.com
      - KEYCLOAK_REALM=etl-project
      - KEYCLOAK_CLIENT_ID=etl-frontend
```

### 2. Create Keycloak Realm Configuration

Create a realm configuration file for your ETL project with the three required roles:

```json
{
  "realm": "etl-project",
  "enabled": true,
  "displayName": "ETL Project",
  "sslRequired": "external",
  "registrationAllowed": false,
  "roles": {
    "realm": [
      {
        "name": "system_administrator",
        "description": "System Administrator with full access"
      },
      {
        "name": "data_manager",
        "description": "Data Manager with data management privileges"
      },
      {
        "name": "analyst",
        "description": "Analyst with read-only access"
      }
    ]
  },
  "clients": [
    {
      "clientId": "etl-frontend",
      "enabled": true,
      "publicClient": true,
      "redirectUris": [
        "https://app.yourdomain.com/*"
      ],
      "webOrigins": [
        "https://app.yourdomain.com"
      ],
      "directAccessGrantsEnabled": true,
      "standardFlowEnabled": true,
      "fullScopeAllowed": true
    },
    {
      "clientId": "etl-backend",
      "enabled": true,
      "clientAuthenticatorType": "client-secret",
      "secret": "change-me-in-production",
      "redirectUris": [
        "https://api.yourdomain.com/*"
      ],
      "webOrigins": [
        "https://api.yourdomain.com"
      ],
      "serviceAccountsEnabled": true,
      "authorizationServicesEnabled": true
    }
  ]
}
```

### 3. Enhance Nginx Configuration

Update the Nginx configuration to handle proper routing:

```nginx
server {
    listen 80;
    server_name auth.yourdomain.com app.yourdomain.com;
    
    # Redirect HTTP to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
    
    # Let's Encrypt validation
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
}

server {
    listen 443 ssl;
    server_name auth.yourdomain.com;
    
    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/auth.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/auth.yourdomain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305';
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy strict-origin-when-cross-origin;
    
    # Keycloak proxy
    location / {
        proxy_pass http://keycloak:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
    }
}

server {
    listen 443 ssl;
    server_name app.yourdomain.com;
    
    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/auth.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/auth.yourdomain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305';
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy strict-origin-when-cross-origin;
    
    # Frontend app
    location / {
        proxy_pass http://frontend:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 4. Secret Management

Set up your secrets directory with proper permissions:

```bash
# Create secrets directory and files
mkdir -p secrets
echo "StrongPostgresPassword123!" > secrets/postgres_password.txt
echo "StrongKeycloakAdminPassword456!" > secrets/keycloak_admin_password.txt
chmod 600 secrets/*
```

### 5. Keycloak-Backend Integration

Update your backend service to validate tokens issued by Keycloak:

```javascript
// Example Node.js backend code for token validation
const express = require('express');
const jwt = require('express-jwt');
const jwksRsa = require('jwks-rsa');

const app = express();

// Authentication middleware
const checkJwt = jwt({
  // Dynamically provide a signing key based on the kid in the header
  secret: jwksRsa.expressJwtSecret({
    cache: true,
    rateLimit: true,
    jwksRequestsPerMinute: 5,
    jwksUri: `https://auth.yourdomain.com/auth/realms/etl-project/protocol/openid-connect/certs`
  }),
  
  // Validate the audience and issuer
  audience: 'etl-backend',
  issuer: `https://auth.yourdomain.com/auth/realms/etl-project`,
  algorithms: ['RS256']
});

// Protected API route that checks for a valid JWT
app.get('/api/data', checkJwt, (req, res) => {
  // Access token payload
  const userRoles = req.user.realm_access.roles;
  
  // Check role-based permissions
  if (userRoles.includes('system_administrator')) {
    // Full access logic
    return res.json({ data: "Full data access" });
  } else if (userRoles.includes('data_manager')) {
    // Data management access logic
    return res.json({ data: "Data management access" });
  } else if (userRoles.includes('analyst')) {
    // Read-only access logic
    return res.json({ data: "Read-only data access" });
  } else {
    return res.status(403).json({ error: "Insufficient permissions" });
  }
});

app.listen(3000, () => {
  console.log('Server is running on port 3000');
});
```

### 6. Frontend Integration

Create a sample frontend configuration to connect with Keycloak:

```javascript
// Example frontend integration with Keycloak
import Keycloak from 'keycloak-js';

const keycloakConfig = {
  url: 'https://auth.yourdomain.com/auth',
  realm: 'etl-project',
  clientId: 'etl-frontend'
};

const keycloak = new Keycloak(keycloakConfig);

keycloak.init({ 
  onLoad: 'login-required',
  checkLoginIframe: false
}).then(authenticated => {
  if (authenticated) {
    console.log('User is authenticated');
    
    // Store the token for API requests
    localStorage.setItem('token', keycloak.token);
    
    // Get user roles
    const userRoles = keycloak.tokenParsed.realm_access.roles;
    
    // Customize UI based on roles
    if (userRoles.includes('system_administrator')) {
      showAdminUI();
    } else if (userRoles.includes('data_manager')) {
      showDataManagerUI();
    } else if (userRoles.includes('analyst')) {
      showAnalystUI();
    }
    
    // Set up token refresh
    setInterval(() => {
      keycloak.updateToken(70).catch(() => {
        console.log('Failed to refresh token, logging out');
        keycloak.logout();
      });
    }, 60000); // Refresh token every minute
    
  } else {
    console.log('User authentication failed');
  }
}).catch(error => {
  console.error('Failed to initialize Keycloak', error);
});

// Function to make authenticated API requests
function callApi(endpoint) {
  return fetch(`https://api.yourdomain.com${endpoint}`, {
    headers: {
      'Authorization': `Bearer ${localStorage.getItem('token')}`
    }
  }).then(response => response.json());
}
```

### 7. Docker Swarm Deployment

Based on your diagram.md, you're using Docker Swarm for orchestration. Here's how to deploy your Keycloak stack to Swarm:

```bash
# Initialize Docker Swarm if not already done
docker swarm init

# Deploy the Keycloak stack
docker stack deploy -c docker-compose.yml etl-auth
```

## Integration with Your ETL Architecture

Your architecture diagram shows how Keycloak fits into the overall system:

1. **Authentication Flow**:
   - User accesses the Frontend
   - Frontend redirects to Keycloak for authentication
   - Keycloak validates credentials and returns tokens
   - Frontend uses tokens for Backend API requests

2. **Role-Based Access Control**:
   - System Administrator: Full access to all features
   - Data Manager: Access to data management features
   - Analyst: Read-only access to data and reports

3. **Security Measures**:
   - SSL/TLS encryption for all traffic
   - Token-based authentication
   - Role-based authorization
   - Regular certificate renewal via Certbot
   - Secure secret management

## Best Practices for Keycloak in Production

1. **High Availability**:
   - For production, deploy multiple Keycloak instances behind a load balancer
   - Use a clustered database setup for PostgreSQL

2. **Backup Strategy**:
   - Regular database backups (preferably automated)
   - Export realm configurations periodically

3. **Security Hardening**:
   - Enforce strong password policies
   - Implement MFA (Multi-Factor Authentication)
   - Regular security audits and updates
   - Token lifespan management (short-lived access tokens, longer refresh tokens)

4. **Monitoring and Logging**:
   - Set up Prometheus metrics for Keycloak
   - Configure centralized logging
   - Set up alerts for authentication failures and suspicious activities

5. **CI/CD Integration**:
   - Include Keycloak configuration in your GitOps workflow
   - Use infrastructure as code for consistent deployments

## Next Steps

1. **Create Configuration Scripts**:
   - Develop scripts to automatically configure Keycloak realms, clients, and roles

2. **User Management**:
   - Implement procedures for user provisioning and deprovisioning
   - Create self-service features for password resets

3. **Integration Testing**:
   - Develop tests to verify authentication and authorization flows
   - Test role-based access scenarios

4. **Documentation**:
   - Document the authentication architecture
   - Create user guides for authentication procedures

By implementing Keycloak as described above, you'll have a robust authentication and authorization system that aligns with the architecture shown in your diagram and meets the requirements specified in your project documentation.
