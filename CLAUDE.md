# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a production-ready Docker deployment for Apache Superset v5.0.0 with optional MDH (Managed Data Hub) integration for AWS Athena queries. The setup supports both lightweight development mode (standalone container) and production mode (full stack with Redis and Nginx).

## Architecture

### Development Mode
- Single Docker container running Superset with Gunicorn
- Persistent volume for SQLite database
- Suitable for testing and rapid iteration

### Production Mode (Docker Compose)
- **Superset**: Application server with Gunicorn WSGI (4 workers, 4 threads per worker)
- **Redis**: Distributed caching for query results, filter state, and explore data
- **Nginx**: Reverse proxy with compression, caching, and security headers
- **Volumes**: `superset_data` for application data, `redis_data` for Redis persistence

## Key Commands

### Development Mode
```bash
# Build multi-platform image (amd64/arm64)
./build.sh

# Run container in background
./run.sh -d

# Stop container
./stop.sh

# Wipe database and start fresh
./cleanup.sh -f
```

### Production Mode
```bash
# First time setup (build + start)
./up.sh --build

# Start existing services
./up.sh

# Stop services (preserve data)
./down.sh

# Stop and wipe all data
./down.sh --volumes
```

### Monitoring
```bash
# View all logs (production)
docker compose logs -f

# View specific service
docker compose logs -f superset
docker compose logs -f redis
docker compose logs -f nginx

# Check service status
docker compose ps
```

## Configuration Architecture

### superset_config.py
The main configuration file contains several critical components:

1. **MDH Integration Mode**: Activated when `MDH_SECRET`, `MDH_ACC_NAME`, and `MDH_PROJECT_ID` are all set
   - Uses `custom_db_connector_mutator` to intercept database connections with host `mdh.athena.com`
   - Automatically fetches temporary AWS credentials via MDH API
   - Refreshes credentials when expired (checks `Expiration` timestamp)
   - Rewrites SQLALCHEMY_DATABASE_URI to AWS Athena format with temporary credentials

2. **Redis Caching Strategy**:
   - `CACHE_CONFIG`: General cache (5 min timeout)
   - `DATA_CACHE_CONFIG`: Query results (24 hour timeout)
   - `FILTER_STATE_CACHE_CONFIG`: Filter state (24 hour timeout)
   - `EXPLORE_FORM_DATA_CACHE_CONFIG`: Explore form data (24 hour timeout)
   - `CELERY_CONFIG`: Async task queue (optional, requires separate worker)

3. **Production Settings**: `DEBUG=False`, `WTF_CSRF_ENABLED=True`, `ENABLE_PROXY_FIX=True`

### entry.sh
Container initialization sequence:
1. `superset db upgrade` - Initialize/migrate database schema
2. `superset fab create-admin` - Create admin user from environment variables
3. `superset init` - Load examples and initial data
4. Start Gunicorn with production config

### Environment Variables
All configuration via `.env` file (copy from `.env.example`):
- **Required**: `SECRET_KEY` (generate with `openssl rand -base64 42`)
- **Admin**: `ADMIN_USERNAME`, `ADMIN_PASSWORD`, `ADMIN_EMAIL`, etc.
- **Redis**: `REDIS_HOST`, `REDIS_PORT`, `REDIS_DB`
- **Gunicorn**: `GUNICORN_WORKERS`, `GUNICORN_THREADS`, `GUNICORN_TIMEOUT`
- **MDH** (optional): `MDH_SECRET` (base64 encoded), `MDH_ACC_NAME`, `MDH_PROJECT_ID`, `MDH_SCHEMA`, `MDH_S3`

## MDH Integration Details

When MDH mode is enabled:
- The `custom_db_connector_mutator` function intercepts connections to `mdh.athena.com`
- Calls `getExplorerCredentials()` to fetch temporary AWS credentials from MDH API
- Credentials include: `AccessKeyId`, `SecretAccessKey`, `SessionToken`, `Expiration`
- Automatically refreshes when expired by comparing UTC timestamps
- Rewrites connection to AWS Athena format with temporary credentials injected

## Data Persistence

- **Development**: Volume `superset_data` mounted at `/app/superset_home`
- **Production**: Named volumes `superset_data` and `redis_data`
- Database location: `$SUPERSET_HOME/superset.db` (SQLite by default)
- Logs: `$SUPERSET_HOME/logs/superset.log` (10MB rotation, 10 backups)

## Build System

The `build.sh` script uses Docker buildx for multi-platform builds:
- Creates builder instance if not exists
- Supports `--platforms linux/amd64,linux/arm64`
- Use `--push` to push to registry
- Use `--tag` for version tagging

## Health Checks

All services have health checks configured:
- **Superset**: `curl -f http://localhost:8088/health`
- **Redis**: `redis-cli ping`
- **Nginx**: `wget --spider http://localhost/health`

Docker Compose uses `condition: service_healthy` to ensure proper startup order.

## Common Issues

- Missing SECRET_KEY: Generate with `openssl rand -base64 42`
- Port conflicts: Change `NGINX_PORT` in `.env`
- Volume persistence: Use `./cleanup.sh` to wipe and start fresh in dev mode
- Redis connection: Check `docker compose logs redis` and verify `REDIS_HOST=redis` in production

## Security Notes

- Never commit `.env` file (ignored in `.gitignore`)
- MDH_SECRET must be base64 encoded before setting in `.env`
- SECRET_KEY protects the local Superset database
- Production mode enforces CSRF protection
- Nginx adds security headers: X-Frame-Options, X-Content-Type-Options
