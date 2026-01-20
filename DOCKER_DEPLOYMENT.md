# Guide de Déploiement Docker - Stocky Application

## 📋 Contenu du déploiement Docker

Ce guide explique comment déployer l'application Stocky (Spring Boot + Angular) avec Docker.

### Fichiers créés :

1. **docker-compose.yml** - Orchestration production des services
2. **docker-compose.dev.yml** - Configuration développement avec hot-reload
3. **Dockerfile.api** - Build multi-étapes pour Spring Boot
4. **Dockerfile.web** - Build multi-étapes pour Angular + Nginx
5. **nginx.conf** - Configuration Nginx avec proxy vers API
6. **.dockerignore** - Fichiers à exclure du build
7. **.env.example** - Variables d'environnement à configurer

## 🚀 Démarrage rapide

### Prérequis
- Docker & Docker Compose installés
- Git (pour cloner le projet)

### Déploiement Production

1. **Cloner/Préparer le projet** :
```bash
cd c:\Users\diall\Desktop\stocky
```

2. **Copier et configurer les variables d'environnement** :
```bash
cp .env.example .env
# Éditer .env et modifier les valeurs sensibles (JWT_SECRET, mots de passe, etc.)
```

3. **Lancer l'application** :
```bash
docker-compose up -d
```

4. **Accéder à l'application** :
   - Frontend: http://localhost
   - API: http://localhost:8080
   - PgAdmin: http://localhost:5050 (admin@stocky.local / admin)

### Déploiement Développement

Pour le développement avec hot-reload :

```bash
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

Services accédés :
- Frontend (avec hot-reload): http://localhost:4200
- API (debug mode): http://localhost:8080
- Database: localhost:5432
- PgAdmin: http://localhost:5050

## 📦 Architecture des Services

### 1. **PostgreSQL** (postgres:15-alpine)
```
- Container: stocky-postgres
- Port: 5432
- Utilisateur: stockyuser
- DB: stockydb
- Volume: postgres_data
- Healthcheck: ✓ Actif
```

### 2. **Spring Boot API** (Java 17 + Maven)
```
- Container: stocky-api
- Port: 8080
- Build: Multi-étages (Maven builder + JRE runtime)
- Profile: prod/dev
- Utilisateur: appuser (non-root)
- Healthcheck: ✓ Actuator /actuator/health
- Volumes: api_logs
```

**Caractéristiques** :
- Optimisation des images (builder stage + Alpine JRE)
- Configuration Hibernate avec batch processing
- JWT authentication
- Logging configurable par niveau
- Memory settings: -Xmx512m -Xms256m (prod), -Xmx1024m -Xms512m (dev)

### 3. **Angular Frontend** (Node 18 + Nginx)
```
- Container: stocky-web
- Port: 80
- Build: Multi-étages (Node builder + Nginx)
- Utilisateur: appuser (non-root)
- Healthcheck: ✓ HTTP wget
```

**Caractéristiques** :
- Build optimisé avec caching
- Nginx pour serving + reverse proxy vers API
- Gzip compression
- Browser caching (1 an pour assets statiques)
- URL rewriting pour SPA (try_files)
- Headers de sécurité (X-Content-Type-Options, etc.)

### 4. **PgAdmin** (UI Database Management)
```
- Container: stocky-pgadmin
- Port: 5050
- Email: admin@stocky.local
- Password: admin
```

## 🔧 Commandes Utiles

### Démarrage et arrêt

```bash
# Démarrer l'application
docker-compose up -d

# Arrêter l'application
docker-compose down

# Arrêter et supprimer les volumes
docker-compose down -v

# Voir les logs
docker-compose logs -f

# Logs d'un service spécifique
docker-compose logs -f stocky-api
docker-compose logs -f stocky-web
docker-compose logs -f postgres
```

### Management des services

```bash
# Redémarrer un service
docker-compose restart stocky-api

# Reconstruire les images
docker-compose build --no-cache

# Nettoyer les images non utilisées
docker image prune -a

# Voir l'état des services
docker-compose ps

# Exécuter une commande dans un container
docker-compose exec stocky-api sh
docker-compose exec postgres psql -U stockyuser -d stockydb
```

### Debugging

```bash
# Entrer dans le container API
docker-compose exec stocky-api sh

# Vérifier la connectivité à la DB depuis API
docker-compose exec stocky-api curl -X GET http://postgres:5432

# Vérifier les logs détaillés
docker-compose logs --tail=100 stocky-api

# Inspecter les variables d'environnement
docker-compose exec stocky-api env
```

## 🔐 Configuration de Sécurité

### Variables d'environnement critiques à modifier :

1. **JWT_SECRET** (Dockerfile.api et .env)
   ```
   JWT_SECRET=your-very-secure-secret-key-change-this-in-production
   ```

2. **Passwords PostgreSQL**
   ```
   POSTGRES_PASSWORD=stockypassword → À changer
   ```

3. **PgAdmin**
   ```
   PGADMIN_DEFAULT_PASSWORD=admin → À changer
   ```

### Recommandations de sécurité :

- ✅ Utilisateurs non-root dans les containers (appuser)
- ✅ Alpine images pour réduire la surface d'attaque
- ✅ Multi-stage builds pour images optimisées
- ✅ Network isolation (bridge network stocky-network)
- ✅ Health checks sur tous les services critiques
- ✅ Gestion des secrets via .env (à adapter pour production)

## 📊 Monitoring et Logs

### Spring Boot Actuator
```bash
# Health check
curl http://localhost:8080/actuator/health

# Metrics
curl http://localhost:8080/actuator/metrics

# Environment
curl http://localhost:8080/actuator/env
```

### Logs depuis Docker

```bash
# Tous les services
docker-compose logs

# Suivi en temps réel
docker-compose logs -f

# Dernier 50 lignes
docker-compose logs --tail=50
```

## 🔄 Pipeline de Build

### API (Dockerfile.api)
```
1. Build stage: Maven compile + package
2. Runtime stage: JRE alpine
3. Non-root user: appuser:appuser
4. Healthcheck: curl actuator/health
```

### Web (Dockerfile.web)
```
1. Build stage: Node npm build
2. Runtime stage: Nginx alpine
3. Non-root user: appuser:appuser
4. Healthcheck: wget /index.html
```

## 🌐 Configuration Nginx

Le fichier `nginx.conf` inclut :

- **Compression** : Gzip pour JS, CSS, JSON
- **Caching** : 1 an pour assets statiques
- **SPA Routing** : try_files pour Angular routes
- **Proxy API** : /api/* → http://stocky-api:8080
- **Headers de sécurité** : X-Content-Type-Options, X-Frame-Options, etc.
- **Timeouts** : 60s pour éviter les déconnexions

## 📝 Variables d'Environnement Complètes

```properties
# PostgreSQL
POSTGRES_USER=stockyuser
POSTGRES_PASSWORD=stockypassword
POSTGRES_DB=stockydb

# API Spring Boot
PORT=8080
SPRING_PROFILES_ACTIVE=prod

# Database
SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/stockydb
SPRING_DATASOURCE_USERNAME=stockyuser
SPRING_DATASOURCE_PASSWORD=stockypassword

# JWT
JWT_SECRET=your-secret-key
JWT_EXPIRATION=86400000 (24h in ms)
JWT_ISSUER=stocky-app

# Hibernate
SPRING_JPA_HIBERNATE_DDL_AUTO=validate (validate/update/create)

# Logging
LOGGING_LEVEL_ROOT=INFO
LOGGING_LEVEL_COM_JAMESAWORO=DEBUG

# Java
JAVA_OPTS=-Xmx512m -Xms256m (prod)

# PgAdmin
PGADMIN_DEFAULT_EMAIL=admin@stocky.local
PGADMIN_DEFAULT_PASSWORD=admin
```

## 🐛 Troubleshooting

### API ne démarre pas
```bash
# Vérifier les logs
docker-compose logs stocky-api

# Vérifier la connexion DB
docker-compose exec stocky-api curl -X GET http://postgres:5432

# Vérifier les variables d'environnement
docker-compose exec stocky-api env
```

### Erreurs de connexion DB
```bash
# Vérifier le statut PostgreSQL
docker-compose logs postgres

# Vérifier les credentials
docker-compose exec postgres psql -U stockyuser -d stockydb -c "SELECT 1"
```

### Frontend ne charge pas
```bash
# Vérifier Nginx
docker-compose logs stocky-web

# Vérifier la build
docker-compose build --no-cache stocky-web

# Accéder directement à Nginx
curl http://localhost/
```

### Problèmes de performances
```bash
# Vérifier l'utilisation des ressources
docker stats

# Augmenter la mémoire JVM
JAVA_OPTS=-Xmx1024m -Xms512m
```

## 📈 Scaling et Production

Pour la production, considérez :

1. **Load Balancing** : Ajouter Nginx/HAProxy en front
2. **Multiple instances** : docker-compose scale stocky-api=3
3. **Volume management** : Utiliser des volumes externes
4. **Backup strategy** : Sauvegarder postgres_data régulièrement
5. **Monitoring** : Ajouter Prometheus + Grafana
6. **CI/CD** : Intégrer avec GitHub Actions/GitLab CI

## 📞 Support

Pour des questions ou problèmes :
1. Vérifier les logs : `docker-compose logs -f`
2. Consulter le troubleshooting ci-dessus
3. Adapter les variables d'environnement selon votre contexte

---

**Créé le** : 2026-01-20  
**Version Docker Compose** : 3.8  
**Versions minimales** : Docker 20.10+, Docker Compose 1.29+
