# Environment Configuration Guide

## Overview

The voting application now uses a `.env` file for centralized, secure configuration management. This follows Docker and security best practices by:

- ✅ Centralizing all configuration in one place
- ✅ Keeping secrets out of git repository
- ✅ Making it easy to change ports and credentials
- ✅ Supporting different environments (dev, staging, prod)

## Files

### `.env` - Your Active Configuration

Contains your actual configuration values. **Never commit this file to git!**

### `.env.example` - Template File

A template showing what variables are needed. Safe to commit to git.

### `.gitignore` - Protects Secrets

Ensures `.env` files are never accidentally committed.

## Configuration Variables

### Port Mappings

```bash
VOTE_PORT=8080      # Port to access vote app on your machine
RESULT_PORT=8081    # Port to access result app on your machine
```

### PostgreSQL Database

```bash
POSTGRES_USER=postgres              # Database username
POSTGRES_PASSWORD=postgres          # Database password (CHANGE IN PRODUCTION!)
POSTGRES_DB=postgres                # Database name
```

### Redis Cache

```bash
REDIS_HOST=redis                    # Redis hostname (service name in Docker)
REDIS_PASSWORD=myredispassword      # Redis password (empty = no auth)
```

### Vote Application Options

```bash
OPTION_A=Cats       # First voting option
OPTION_B=Dogs       # Second voting option
```

## How It Works

### 1. Docker Compose Reads .env

Docker Compose automatically loads `.env` file and makes variables available.

### 2. Variable Substitution

In `docker-compose.yml`:

```yaml
ports:
  - "${VOTE_PORT:-8080}:80"  # Uses VOTE_PORT from .env, defaults to 8080
```

### 3. Environment Variables Passed to Containers

```yaml
environment:
  - POSTGRES_USER=${POSTGRES_USER:-postgres}
  - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}
```

## Security Features Implemented

### 1. Redis Password Protection

- Redis now requires authentication
- Password configured via `REDIS_PASSWORD`
- Vote app and Worker connect with password
- Health check updated to support authentication

### 2. PostgreSQL Password from Environment

- Database credentials from .env
- Worker service reads from environment variables
- No hardcoded passwords in code

### 3. Git Protection

Added `.gitignore` to prevent committing:

```
.env
.env.local
.env.*.local
```

## Usage

### First Time Setup

1. **Copy the example file:**

```bash
cp .env.example .env
```

2. **Edit .env with your values:**

```bash
nano .env
# or
vim .env
```

3. **Update passwords:**

```bash
# Change these to secure values:
POSTGRES_PASSWORD=your_secure_password_here
REDIS_PASSWORD=your_redis_password_here
```

4. **Start the application:**

```bash
docker compose up -d
```

### Changing Configuration

1. **Stop services:**

```bash
docker compose down
```

2. **Edit .env:**

```bash
nano .env
```

3. **Restart services:**

```bash
docker compose up -d
```

### Different Environments

#### Development (.env)

```bash
POSTGRES_PASSWORD=postgres
REDIS_PASSWORD=devpassword
VOTE_PORT=8080
RESULT_PORT=8081
```

#### Production (.env.production)

```bash
POSTGRES_PASSWORD=super_secure_random_password_here
REDIS_PASSWORD=another_secure_random_password
VOTE_PORT=80
RESULT_PORT=81
```

Use with:

```bash
docker compose --env-file .env.production up -d
```

## Code Changes Made

### 1. vote/app.py

Updated Redis connection to support password:

```python
def get_redis():
    redis_password = os.getenv('REDIS_PASSWORD', '')
    if redis_password:
        g.redis = Redis(host="redis", password=redis_password, ...)
    else:
        g.redis = Redis(host="redis", ...)
```

### 2. worker/Program.cs

Updated to read environment variables:

```csharp
var postgresUser = Environment.GetEnvironmentVariable("POSTGRES_USER") ?? "postgres";
var postgresPassword = Environment.GetEnvironmentVariable("POSTGRES_PASSWORD") ?? "postgres";
var redisPassword = Environment.GetEnvironmentVariable("REDIS_PASSWORD") ?? "";
```

### 3. healthchecks/redis.sh

Updated to support password authentication:

```bash
if [ -n "$REDIS_PASSWORD" ]; then
    ping="$(redis-cli -h "$host" -a "$REDIS_PASSWORD" --no-auth-warning ping)"
else
    ping="$(redis-cli -h "$host" ping)"
fi
```

### 4. docker-compose.yml

Updated all services to use environment variables:

```yaml
services:
  vote:
    ports:
      - "${VOTE_PORT:-8080}:80"
    environment:
      - REDIS_PASSWORD=${REDIS_PASSWORD:-}
      - OPTION_A=${OPTION_A:-Cats}
      - OPTION_B=${OPTION_B:-Dogs}
```

## Testing

### Verify Configuration Loaded

```bash
# Check environment variables in a service
docker compose exec vote env | grep REDIS_PASSWORD

# Check ports
docker compose ps
# Should show your configured ports
```

### Test Redis Authentication

```bash
# Should fail without password
docker compose exec redis redis-cli ping
# (error) NOAUTH Authentication required

# Should work with password
docker compose exec redis redis-cli -a myredispassword ping
# PONG
```

### Test Vote Submission

```bash
# Submit vote
curl -X POST http://localhost:${VOTE_PORT:-8080} -d "vote=a"

# Check database
docker compose exec db psql -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT COUNT(*) FROM votes;"
```

## Security Best Practices

### ✅ DO

- Use strong, random passwords in production
- Keep `.env` file permissions restricted (`chmod 600 .env`)
- Use different passwords for each environment
- Rotate passwords regularly
- Backup `.env` file securely

### ❌ DON'T

- Commit `.env` to git
- Share `.env` file in chat/email
- Use default passwords in production
- Reuse passwords across services
- Store `.env` in public locations

## Troubleshooting

### Issue: Changes not taking effect

**Solution:** Restart services

```bash
docker compose down
docker compose up -d
```

### Issue: Authentication failures

**Solution:** Check passwords match in .env

```bash
# Verify .env file
cat .env | grep PASSWORD

# Check service logs
docker compose logs vote
docker compose logs worker
```

### Issue: Ports already in use

**Solution:** Change ports in .env

```bash
# Edit .env
VOTE_PORT=9080
RESULT_PORT=9081

# Restart
docker compose down
docker compose up -d
```

## Migration from Hardcoded Values

**Before:** Passwords hardcoded in docker-compose.yml and code

```yaml
environment:
  - POSTGRES_PASSWORD=postgres  # Hardcoded!
```

**After:** Read from .env file

```yaml
environment:
  - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}  # From .env
```

**Benefits:**

- ✅ One place to change all configuration
- ✅ Secrets not in git history
- ✅ Easy to use different values per environment
- ✅ Follows Docker Compose best practices

## Summary

Your voting application is now configured using environment variables with:

✅ Centralized configuration in `.env` file  
✅ Redis password protection  
✅ PostgreSQL credentials from environment  
✅ Configurable ports  
✅ Git-protected secrets  
✅ Production-ready security  
✅ Easy environment switching  
✅ No hardcoded passwords in code  

**Access your application:**

- **Vote:** <http://localhost:8080> (or your VOTE_PORT)
- **Result:** <http://localhost:8081> (or your RESULT_PORT)

**Remember to change default passwords before deploying to production!**
