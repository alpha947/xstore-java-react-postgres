# Stocky Docker Configuration - Advanced Options

## Environment Variables for Production

### API Configuration
```bash
# Server
PORT=8080
SPRING_PROFILES_ACTIVE=prod

# JWT Security
JWT_SECRET=your-production-secret-key-minimum-32-characters
JWT_EXPIRATION=86400000
JWT_ISSUER=stocky-app

# Database
SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/stockydb
SPRING_DATASOURCE_USERNAME=stockyuser
SPRING_DATASOURCE_PASSWORD=your-secure-password

# JPA/Hibernate
SPRING_JPA_HIBERNATE_DDL_AUTO=validate
SPRING_JPA_SHOW_SQL=false

# Performance
JAVA_OPTS=-Xmx1024m -Xms512m -XX:+UseG1GC
```

### Scaling Configuration

To run multiple instances:
```bash
docker-compose up -d --scale stocky-api=3
```

## Database Configuration

### PostgreSQL Connection Pooling
Add to application-prod.properties:
```properties
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=30000
spring.datasource.hikari.idle-timeout=600000
spring.datasource.hikari.auto-commit=true
```

### Database Backup Strategy
```bash
# Automatic daily backup
# Add to crontab:
0 2 * * * /path/to/backup-db.sh
```

## SSL/TLS Configuration

### For Production with SSL

1. Create Nginx config with SSL:
```nginx
listen 443 ssl http2;
ssl_certificate /etc/nginx/certs/cert.pem;
ssl_certificate_key /etc/nginx/certs/key.pem;
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers HIGH:!aNULL:!MD5;
```

2. Update docker-compose.yml:
```yaml
volumes:
  - ./certs:/etc/nginx/certs:ro
ports:
  - "443:443"
```

## Monitoring Setup

### Add Prometheus & Grafana
```yaml
prometheus:
  image: prom/prometheus:latest
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml
  ports:
    - "9090:9090"

grafana:
  image: grafana/grafana:latest
  ports:
    - "3000:3000"
```

## Logging Setup

### Add ELK Stack (Elasticsearch, Logstash, Kibana)
```yaml
elasticsearch:
  image: docker.elastic.co/elasticsearch/elasticsearch:8.0.0
  environment:
    - discovery.type=single-node
  ports:
    - "9200:9200"

kibana:
  image: docker.elastic.co/kibana/kibana:8.0.0
  ports:
    - "5601:5601"
```

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Docker Build and Push

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Build Docker images
        run: docker-compose build
      
      - name: Push to registry
        run: docker-compose push
      
      - name: Deploy
        run: docker-compose up -d
```

## Resource Limits

Add to docker-compose.yml for each service:
```yaml
stocky-api:
  deploy:
    resources:
      limits:
        cpus: '1'
        memory: 1G
      reservations:
        cpus: '0.5'
        memory: 512M
```

## Network Configuration

### For production with external access:
```yaml
networks:
  stocky-network:
    driver: bridge
    driver_opts:
      com.docker.network.driver.mtu: 1450
```

## Health Check Customization

### More granular health checks:
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health/liveness"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

## Performance Tuning

### For high-traffic scenarios:
```properties
# Connection pool
spring.datasource.hikari.maximum-pool-size=50

# Tomcat threads
server.tomcat.threads.max=300
server.tomcat.threads.min-spare=10

# GC tuning
JAVA_OPTS=-Xmx2048m -Xms1024m -XX:+UseG1GC -XX:MaxGCPauseMillis=200
```

## Troubleshooting Commands

```bash
# Check resource usage
docker stats

# Inspect network
docker network inspect stocky-network

# View Docker events
docker events --filter container=stocky-api

# Check container details
docker inspect stocky-api

# Execute shell commands
docker-compose exec stocky-api sh

# View all processes
docker-compose top stocky-api
```
