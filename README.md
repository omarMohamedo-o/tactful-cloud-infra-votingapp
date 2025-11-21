# Voting Application - Cloud Infrastructure Project

> **Complete Cloud-Native DevOps Implementation**  
> Microservices • Docker • Kubernetes • CI/CD • Monitoring • Security

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Architecture](#-architecture)
- [All Code Files Explained](#-all-code-files-explained)
- [Stage 1: Docker Compose Setup](#-stage-1-docker-compose-setup)
- [Stage 2: Kubernetes Deployment](#-stage-2-kubernetes-deployment)
- [Stage 3: CI/CD Pipeline](#-stage-3-cicd-pipeline)
- [Stage 4: Monitoring Stack](#-stage-4-monitoring-stack)
- [Testing Guide](#-testing-guide)
- [Challenges Faced & Solutions](#-challenges-faced--solutions)
- [Common Commands Reference](#-common-commands-reference)

---

## 🎯 Project Status

### ✅ Phase 1 – Containerization & Local Setup (COMPLETE)

✅ All services containerized with optimized, non-root Dockerfiles  
✅ Docker Compose with two-tier networking (frontend/backend)  
✅ Health checks for Redis and PostgreSQL  
✅ Exposed ports: 8080 (vote), 8081 (result)  
✅ Fully functional end-to-end local deployment  
✅ Optional seed service with profile support  

### ✅ Phase 2 – Kubernetes Deployment (COMPLETE)

✅ Local Minikube cluster deployment  
✅ Production-grade Kubernetes manifests  
✅ Pod Security Standards enforced  
✅ NetworkPolicies for database isolation  
✅ Resource limits and health probes  
✅ Ingress configuration with local DNS  

### ✅ Phase 3 – CI/CD Pipeline (COMPLETE)

✅ GitHub Actions workflows  
✅ Automated build, test, and push  
✅ Snyk security scanning  
✅ Docker Compose testing  
✅ Container registry integration (GHCR)  

### ✅ Phase 4 – Monitoring & Observability (COMPLETE)

✅ Prometheus metrics collection  
✅ Grafana dashboards (32 pre-configured)  
✅ Kubernetes cluster monitoring  
✅ Pod and namespace visibility

---

## 🏗️ Project Overview

This is a **distributed microservices voting application** demonstrating modern cloud-native DevOps practices. Users can vote between two options (Cats vs Dogs) and view real-time results across multiple services.

### Application Components

**Frontend Services:**

- **Vote Service** - Python Flask web application for casting votes (Port 8080/5000)
- **Result Service** - Node.js Express + Socket.io for real-time results (Port 8081)

**Backend Services:**

- **Worker Service** - .NET 7 worker that processes votes from queue
- **Redis** - In-memory message queue for vote storage
- **PostgreSQL** - Persistent database for final vote counts

**Optional Services:**

- **Seed Data** - Shell script to generate 3000 test votes (2000 Cats, 1000 Dogs)

### Technology Stack

- **Languages**: Python 3.11, Node.js 18, .NET 7, C#
- **Frameworks**: Flask, Express, Socket.io, Gunicorn
- **Databases**: Redis 7, PostgreSQL 15
- **Containerization**: Docker, Docker Compose
- **Orchestration**: Kubernetes (Minikube)
- **CI/CD**: GitHub Actions
- **Security**: Snyk (SAST, SCA, Container, IaC scanning)
- **Monitoring**: Prometheus, Grafana, Loki
- **Package Managers**: pip, npm, dotnet

---

## 📐 Architecture

### Data Flow

┌─────────────┐         ┌──────────────┐
│   Browser   │────────▶│  Vote (5000) │
│   (User)    │         │  Python/Flask│
└─────────────┘         └──────┬───────┘
                               │
                        POST /vote={a|b}
                               │
                               ▼
                        ┌──────────────┐
                        │    Redis     │
                        │  (Message    │
                        │   Queue)     │
                        └──────┬───────┘
                               │
                        LPUSH/BLPOP
                               │
                               ▼
                        ┌──────────────┐
                        │   Worker     │
                        │   .NET 7     │
                        └──────┬───────┘
                               │
                        INSERT votes
                               │
                               ▼
                        ┌──────────────┐      ┌──────────────┐
                        │  PostgreSQL  │◀─────│Result (8081) │
                        │  (Database)  │ SELECT│ Node.js/     │◀────Browser
                        └──────────────┘       │ Socket.io    │
                                               └──────────────┘

### Network Architecture (Docker Compose)

- **Frontend Tier**: vote, result (exposed to host)
- **Backend Tier**: worker, redis, postgres (internal only)

### Network Architecture (Kubernetes)

- **Namespace**: `voting-app`
- **NetworkPolicies**: Postgres/Redis isolated, only worker can access
- **Ingress**: vote.local, result.local (via Minikube IP)

---

## 📁 All Code Files Explained

### Root Directory Files

#### `docker-compose.yml`

**Purpose**: Orchestrates all 5 services for local development  
**Key Features**:

- Two-tier networking (frontend/backend)
- Health checks for redis & postgres
- Named volumes for persistence
- Resource limits (CPU/memory)
- Profiles for optional seed service

#### `.env`

**Purpose**: Environment variables for Docker Compose  
**Contains**:

- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
- `REDIS_PASSWORD` (empty for dev)
- **⚠️ Never commit to git** (in .gitignore)

#### `.github/workflows/ci-cd.yml`

**Purpose**: CI/CD pipeline for automated build/test/deploy  
**Jobs**:

1. `build-vote` - Build & scan vote service
2. `build-result` - Build & scan result service
3. `build-worker` - Build & scan worker service
4. `docker-compose-test` - Integration test with docker-compose
5. `deployment-info` - Manual deployment guide

**Triggers**: Push to main/develop, pull requests

#### `.github/workflows/security-scanning.yml`

**Purpose**: Weekly Snyk security scans  
**Schedule**: Every Monday at 9 AM UTC  
**Scans**: Container images, code vulnerabilities, dependencies

#### `.github/workflows/docker-compose-test.yml`

**Purpose**: Automated Docker Compose integration tests  
**Tests**: Service health, connectivity, data flow

---

### Service Directories

#### `vote/` - Python Voting Service

**Files**:

- `app.py` - Flask web application (main logic)
- `requirements.txt` - Python dependencies (Flask, redis, gunicorn)
- `Dockerfile` - Multi-stage build (Alpine base, non-root user)
- `templates/index.html` - Voting UI
- `static/stylesheets/style.css` - CSS styling

**How It Works**:

1. User visits `/` - gets unique voter_id cookie
2. User submits vote (a or b) via POST
3. Vote stored in Redis queue as JSON
4. Response shows confirmation

**Docker Build**: Multi-stage with Alpine base, non-root user (appuser), and Gunicorn WSGI server

---

#### `result/` - Node.js Result Service

**Files**:

- `server.js` - Express + Socket.io server
- `package.json` - Node dependencies (express, socket.io, pg)
- `Dockerfile` - Multi-stage build (Alpine base, non-root)
- `views/index.html` - Results dashboard UI
- `views/app.js` - Client-side Socket.io logic

**How It Works**:

1. Client connects via WebSocket (Socket.io)
2. Server queries PostgreSQL every 1 second
3. Emits `scores` event with vote counts
4. Client updates bar chart in real-time

---

#### `worker/` - .NET Worker Service

**Files**:

- `Program.cs` - Main worker logic (C#)
- `Worker.csproj` - .NET project file
- `Dockerfile` - Multi-stage build (.NET SDK → runtime)

**How It Works**:

1. Continuously poll Redis queue (BLPOP)
2. Deserialize JSON vote data
3. Insert/update PostgreSQL (upsert by voter_id)
4. Prevents duplicate votes (same voter_id)

---

#### `seed-data/` - Test Data Generator

**Files**:

- `generate-votes.sh` - Shell script to send HTTP votes
- `make-data.py` - Python script (alternative, unused)
- `Dockerfile` - Lightweight Alpine with curl

**Functionality**: Waits for vote service to be ready, then generates 2000 votes for Cats (option a) and 1000 votes for Dogs (option b) using curl HTTP POST requests with 0.1 second delays between votes.

---

### Kubernetes Manifests (`k8s/manifests/`)

#### `00-namespace.yaml`

Creates `voting-app` namespace with Pod Security Standard: restricted

#### `01-secrets.yaml`

Base64-encoded secrets for postgres & redis passwords

#### `02-configmap.yaml`

Configuration data (postgres connection strings, redis hosts)

#### `03-postgres.yaml`

StatefulSet + Service for PostgreSQL with:

- Persistent volume claim (10Gi)
- Non-root security context
- Resource limits (CPU/memory)
- Liveness/readiness probes

#### `04-redis.yaml`

Deployment + Service for Redis with:

- Ephemeral storage (in-memory queue)
- No password (dev mode)
- Health checks

#### `05-vote.yaml`

Deployment (2 replicas) + Service for vote frontend

#### `06-result.yaml`

Deployment (2 replicas) + Service for result frontend

#### `07-worker.yaml`

Deployment (1 replica) for worker backend

#### `08-network-policies.yaml`

Network isolation:

- Postgres: only worker can connect
- Redis: only vote & worker can connect

#### `09-ingress.yaml`

Ingress routes:

- `vote.local` → vote service
- `result.local` → result service

#### `10-seed.yaml`

Job to generate test votes with security context

---

### Monitoring Stack (`k8s/monitoring/`)

#### `prometheus-values.yaml`

Helm values for kube-prometheus-stack:

- Grafana enabled (NodePort 30300)
- Prometheus (NodePort 30090)
- AlertManager included
- Node exporter, kube-state-metrics

#### `loki-values.yaml`

Log aggregation with Grafana Loki (unused in current setup)

#### `servicemonitor.yaml`

Prometheus ServiceMonitors (apps don't expose /metrics, uses cAdvisor instead)

---

### Scripts

#### `k8s/setup-minikube.sh`

**Purpose**: Automate Minikube cluster creation  
**Steps**:

1. Checks if Minikube installed
2. Starts cluster with 2 CPUs, 4GB RAM
3. Enables ingress addon
4. Configures Docker environment
5. Builds images in Minikube Docker
6. Outputs cluster IP for /etc/hosts

#### `k8s/deploy-monitoring.sh`

**Purpose**: Deploy Prometheus/Grafana to cluster  
**Steps**:

1. Adds Helm repos (prometheus-community, grafana)
2. Creates monitoring namespace
3. Installs kube-prometheus-stack
4. Port-forwards Grafana (optional)

#### `snyk-full-scan.sh`

**Purpose**: Comprehensive security scanning  
**Scans**:

- `snyk code test` - SAST for all code
- `snyk test` - SCA for dependencies
- `snyk container test` - Container vulnerabilities
- `snyk iac test` - IaC misconfigurations

---

### Documentation Files

**All documentation has been consolidated into this README.**

The following files previously contained separate guides but their content is now fully integrated into the relevant sections above:

- `QUICKSTART.md` → Stage 1 Docker Compose Quick Start
- `SETUP-GUIDE.md` → Stage 1 Detailed Setup Steps  
- `LOCAL-MINIKUBE-SETUP.md` → Stage 2 Kubernetes Deployment
- `SECRETS-MANAGEMENT.md` → Stage 2 Secrets Management section
- `SECURITY-FIXES.md` → Challenges and Solutions section below

**This README is now a complete standalone reference.**

---

## 🚀 Stage 1: Docker Compose Setup

### Prerequisites

Check that you have Docker and Docker Compose installed:

- Docker version 20.10 or higher: `docker --version`
- Docker Compose version 2.0 or higher: `docker compose version`
- Docker daemon running: `docker ps`

**System Requirements:**

- CPU: 2+ cores
- RAM: 4GB+ available
- Disk: 5GB+ free space

### Quick Start (5 Minutes)

**Step 1: Navigate to project directory**

`cd /home/omar/Projects/tactful-votingapp-cloud-infra`

**Step 2: Build and start all services**

`docker compose up -d`

This command builds all Docker images and starts 5 services in detached mode.

**Step 3: Verify services are running**

`docker compose ps`

All services should show "Up" status, with Redis and PostgreSQL showing "(healthy)".

**Step 4: Access the applications**

- Vote: <http://localhost:8080> (cast your vote for Cats or Dogs)
- Result: <http://localhost:8081> (view live results)

**Step 5: Test voting functionality**

Submit a test vote: `curl -X POST http://localhost:8080 -H "Content-Type: application/x-www-form-urlencoded" -d "vote=a"`

Check results: `curl http://localhost:8081`

### Detailed Setup Steps

**Step 1: Create Environment Variables**

Create a `.env` file (never commit this to git):

- POSTGRES_USER=postgres
- POSTGRES_PASSWORD=postgres
- POSTGRES_DB=postgres
- REDIS_PASSWORD= (empty for development)

The `.env` file is already in `.gitignore` to prevent credential exposure.

**Step 2: Build All Docker Images**

Build all services: `docker compose build`

This uses multi-stage Dockerfiles for:

- **vote**: Python 3.11 Alpine with Flask and Gunicorn
- **result**: Node.js 18 Alpine with Express and Socket.io
- **worker**: .NET 7 with C# worker service

Verify images created: `docker images | grep tactful-votingapp`

**Step 3: Start Services with Docker Compose**

Start in detached mode: `docker compose up -d`

Watch logs in real-time: `docker compose logs -f`

The startup order is controlled by health checks:

1. PostgreSQL and Redis start first
2. Once healthy, vote and worker services start
3. Result service starts after PostgreSQL is ready

**Step 4: Verify Service Health**

Check all services status: `docker compose ps`

Test Redis health manually: `docker compose exec redis sh /healthchecks/redis.sh`

Test PostgreSQL health: `docker compose exec db sh /healthchecks/postgres.sh`

Expected: Both should return success (exit code 0).

**Step 5: Test the Application Flow**

**Vote Submission:**

- Open browser to <http://localhost:8080>
- Click on "Cats" or "Dogs" button
- You'll receive a unique voter_id cookie
- Vote is pushed to Redis queue

**Worker Processing:**

- View worker logs: `docker compose logs -f worker`
- Worker polls Redis queue using BLPOP
- Deserializes vote JSON
- Inserts into PostgreSQL using UPSERT (prevents duplicate votes by voter_id)

**Result Display:**

- Open browser to <http://localhost:8081>
- WebSocket connection established
- PostgreSQL queried every 1 second
- Bar chart updates in real-time

**Step 6: Generate Test Data (Optional)**

Run seed service: `docker compose --profile seed up seed-data`

This generates:

- 2000 votes for Cats (option a)
- 1000 votes for Dogs (option b)
- Total: 3000 votes with 0.1 second delay between each

Watch progress: `docker compose --profile seed logs -f seed-data`

Verify in results: Open <http://localhost:8081> to see updated counts

**Step 7: Verify Data Persistence**

Submit some votes, then restart services: `docker compose restart`

Check results still show: Visit <http://localhost:8081>

Data should persist because:

- PostgreSQL uses named volume `voting-app-db-data`
- Volumes survive container restarts
- Only `docker compose down -v` removes volumes

**Step 8: Monitor Resource Usage**

View real-time stats: `docker stats`

Expected resource usage per service:

- Vote: ~50MB RAM, <5% CPU
- Result: ~80MB RAM, <5% CPU
- Worker: ~60MB RAM, <5% CPU
- Redis: ~10MB RAM, <1% CPU
- PostgreSQL: ~50MB RAM, <5% CPU

Resource limits are configured in docker-compose.yml:

- CPU: 0.5 cores per service
- Memory: 512MB per service

**Step 9: Test Network Isolation**

Try accessing PostgreSQL from host (should fail):

- Port 5432 is NOT published to host
- Only accessible within backend network

Try accessing Redis from host (should fail):

- Port 6379 is NOT published to host
- Backend network isolation working correctly

Verify vote and result can reach backend:

- Both services are connected to frontend AND backend networks
- This allows communication with Redis and PostgreSQL

**Step 10: View Logs and Debug**

View all logs: `docker compose logs -f`

View specific service: `docker compose logs -f vote`

Follow worker processing: `docker compose logs -f worker`

Check for errors: `docker compose logs | grep -i error`

### Complete Testing Workflow (Phase 1)

Follow this exact workflow to test the entire Docker Compose setup from scratch:

**1️⃣ Stop everything and remove volumes**

`docker compose down -v`

This command:

- ✅ Stops all containers
- ✅ Removes networks
- ✅ Removes named and anonymous volumes (clean slate)

**2️⃣ Rebuild and start all normal services**

`docker compose up --build -d`

This command:

- ✅ Builds fresh images
- ✅ Starts Redis, Vote, Worker, Result, DB
- ✅ Runs in detached mode (background)

Wait 30-60 seconds for health checks to pass.

**3️⃣ Check running containers**

`docker compose ps`

Expected output:

- ✅ All services show "running" or "Up"
- ✅ Redis and DB show "(healthy)" status
- ✅ Vote, Result, Worker show "Up"

**4️⃣ View logs of the entire stack**

`docker compose logs -f`

Press Ctrl+C to stop following logs.

Check for:

- ✅ No error messages
- ✅ Vote service: "Running on <http://0.0.0.0:80>"
- ✅ Worker: "Connected to redis" and "Connected to db"
- ✅ Result: "App running on port 4000"

**5️⃣ Test the application**

Open browsers:

- Vote: <http://localhost:8080> (submit votes)
- Result: <http://localhost:8081> (view results)

Or test via curl:

Submit vote: `curl -X POST http://localhost:8080 -H "Content-Type: application/x-www-form-urlencoded" -d "vote=a"`

Check results: `curl http://localhost:8081`

**🌱 Seed Data Commands**

**6️⃣ Run ONLY the seed-data container**

`docker compose --profile seed up seed-data`

This command:

- ✅ Runs only seed-data service (without restarting everything else)
- ✅ Generates 3000 votes (2000 Cats, 1000 Dogs)
- ✅ Exits automatically when complete

**7️⃣ Follow logs of only seed-data**

`docker compose --profile seed logs -f seed-data`

Expected output:

- "Waiting for vote service to be ready..."
- "Vote service is ready"
- "Generating 2000 votes for option a"
- "Generating 1000 votes for option b"
- "Seed data generation complete"

**8️⃣ Verify seed data worked**

Open <http://localhost:8081> and verify:

- ✅ Cats: ~2000 votes
- ✅ Dogs: ~1000 votes
- ✅ 2:1 ratio

**9️⃣ Clean up after testing**

`docker compose down -v`

Removes everything for next test run.

---

### Testing Docker Compose Deployment

**Test 1: Service Health Check**

Command: `docker compose ps`

Expected: All 5 services show "Up", Redis and DB show "(healthy)"

**Test 2: Port Accessibility**

Vote port test: `curl -I http://localhost:8080`

Result port test: `curl -I http://localhost:8081`

Expected: Both return HTTP 200 OK

**Test 3: Vote Submission**

Submit vote for Cats: `curl -X POST http://localhost:8080 -H "Content-Type: application/x-www-form-urlencoded" -d "vote=a"`

Submit vote for Dogs: `curl -X POST http://localhost:8080 -H "Content-Type: application/x-www-form-urlencoded" -d "vote=b"`

Expected: HTTP 200 response

**Test 4: Data Flow Verification**

Check Redis queue has votes: `docker compose exec redis redis-cli LLEN votes`

Expected: Number > 0 (if worker hasn't processed yet) or 0 (if processed)

Check PostgreSQL has records: `docker compose exec db psql -U postgres -d postgres -c "SELECT COUNT(*) FROM votes;"`

Expected: Count matches submitted votes

**Test 5: Result Display**

Get results page: `curl http://localhost:8081`

Expected: HTML page with vote counts for Cats and Dogs

**Test 6: Data Persistence**

Submit votes, restart services: `docker compose restart`, then check results still display

Expected: Vote counts persist across restarts

**Test 7: Worker Processing**

Watch worker logs while submitting votes: `docker compose logs -f worker` (in one terminal), `curl -X POST http://localhost:8080 -d "vote=a"` (in another)

Expected: Worker logs show "Processing vote" messages

**Test 8: Security - Non-Root Users**

Check vote runs as non-root: `docker compose exec vote whoami`

Expected: Output is "appuser" (not root)

Check all services: `docker compose exec result whoami`, `docker compose exec worker whoami`

Expected: All return non-root usernames

**Test 9: Network Isolation**

Try connecting to PostgreSQL from vote pod (should succeed - vote is on backend network): `docker compose exec vote nc -zv db 5432`

Try connecting from host to PostgreSQL port 5432 (should fail - not published): `nc -zv localhost 5432`

Expected: Internal connection works, external blocked

**Test 10: Resource Limits**

Check resource consumption: `docker stats --no-stream`

Expected: No service exceeds 512MB memory or 0.5 CPU

### Common Docker Compose Commands

**Start and Stop:**

- Start all services: `docker compose up -d`
- Start with logs visible: `docker compose up`
- Stop all services: `docker compose down`
- Stop and remove volumes: `docker compose down -v`

**Logs and Monitoring:**

- View all logs: `docker compose logs -f`
- View specific service: `docker compose logs -f vote`
- Check service status: `docker compose ps`
- Monitor resources: `docker stats`

**Service Management:**

- Restart specific service: `docker compose restart vote`
- Rebuild service: `docker compose build vote && docker compose up -d vote`
- Rebuild without cache: `docker compose build --no-cache`
- Scale service: `docker compose up -d --scale vote=3`

**Cleanup:**

- Stop services: `docker compose down`
- Remove volumes: `docker compose down -v`
- Remove images: `docker compose down --rmi all`
- Full cleanup: `docker compose down -v --rmi all --remove-orphans`

**Debugging:**

- Execute command in container: `docker compose exec vote sh`
- Run one-off command: `docker compose run --rm vote python --version`
- View container inspect: `docker compose ps -a`

### Troubleshooting Docker Compose

**Problem: Services Won't Start**

Check logs: `docker compose logs <service-name>`

Rebuild without cache: `docker compose build --no-cache`

Check port conflicts: `sudo lsof -i :8080` and `sudo lsof -i :8081`

**Problem: Health Checks Failing**

Test Redis health: `docker compose exec redis sh /healthchecks/redis.sh`

Test PostgreSQL health: `docker compose exec db sh /healthchecks/postgres.sh`

Check connectivity: `docker compose exec vote ping redis`

**Problem: Data Not Persisting**

Verify volumes exist: `docker volume ls | grep voting-app`

Inspect volume: `docker volume inspect voting-app-db-data`

Check PostgreSQL data directory: `docker compose exec db ls -la /var/lib/postgresql/data`

**Problem: Vote Not Appearing in Results**

Check worker is running: `docker compose ps worker`

View worker logs for errors: `docker compose logs worker`

Verify Redis connection: `docker compose exec worker nc -zv redis 6379`

Verify PostgreSQL connection: `docker compose exec worker nc -zv db 5432`

**Problem: Port Already in Use**

Find what's using the port: `sudo lsof -i :8080` or `sudo netstat -tulpn | grep 8080`

Kill the process or change ports in docker-compose.yml

**Problem: Out of Memory**

Check resource usage: `docker stats`

Increase Docker memory limit (Docker Desktop settings)

Reduce service replicas or resource limits in docker-compose.yml

### Best Practices Implemented

**Docker Best Practices:**

- ✅ Multi-stage builds (40-60% size reduction)
- ✅ Non-root users in all containers
- ✅ Health checks for critical services
- ✅ Layer caching optimization
- ✅ .dockerignore files to reduce build context
- ✅ Alpine images where possible

**Docker Compose Best Practices:**

- ✅ Two-tier networking (frontend/backend isolation)
- ✅ Service dependencies with health check conditions
- ✅ Named volumes for data persistence
- ✅ Resource limits (CPU/memory)
- ✅ Restart policies for high availability
- ✅ Profiles for optional services

**Security Best Practices:**

- ✅ All containers run as non-root
- ✅ Backend services isolated from external access
- ✅ Resource limits prevent DoS attacks
- ✅ No hardcoded secrets (environment variables)
- ✅ .env file in .gitignore

---

## ☸️ Stage 2: Kubernetes Deployment

### Overview

Deploy the voting application to a local Minikube Kubernetes cluster with two options: kubectl manifests or Helm charts.

**Deployment Flow:**

1. GitHub Actions builds Docker images on push to main/develop
2. Images are scanned for vulnerabilities (Snyk)
3. Images are pushed to GitHub Container Registry (GHCR)
4. Manual deployment to local Minikube cluster

### Prerequisites

**Required Software:**

- Minikube version 1.30 or higher: `minikube version`
- kubectl version 1.27 or higher: `kubectl version --client`
- Helm version 3.12 or higher (if using Helm): `helm version`
- Docker for Minikube driver: `docker --version`

**System Requirements:**

- CPU: 4+ cores
- RAM: 8GB+ available
- Disk: 20GB+ free space

### Quick Start with Minikube

**Step 1: Start Minikube cluster**

`minikube start --cpus=4 --memory=8192 --driver=docker`

Add `--kubernetes-version=v1.27.0` to pin K8s version if needed.

**Step 2: Enable Ingress addon**

`minikube addons enable ingress`

Wait for ingress controller: `kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s`

**Step 3: Choose deployment method**

**Option A - kubectl manifests:**

`kubectl apply -f k8s/manifests/`

**Option B - Helm charts:**

`helm install voting-app k8s/helm/voting-app --namespace voting-app --create-namespace`

**Step 4: Configure /etc/hosts**

Get Minikube IP: `minikube ip`

Add to /etc/hosts: `echo "$(minikube ip) vote.local result.local" | sudo tee -a /etc/hosts`

On Windows, edit `C:\Windows\System32\drivers\etc\hosts`

**Step 5: Access the applications**

- Vote: <http://vote.local>
- Result: <http://result.local>

### Detailed Setup Steps

**Step 1: Start Minikube with Optimized Settings**

Start with resource limits: `minikube start --cpus=4 --memory=8192 --disk-size=20g --driver=docker`

Verify cluster running: `kubectl cluster-info`

Expected output shows Kubernetes control plane and CoreDNS running.

**Step 2: Enable Required Addons**

Enable ingress: `minikube addons enable ingress`

Enable metrics-server (optional for monitoring): `minikube addons enable metrics-server`

List enabled addons: `minikube addons list`

**Step 3: Deploy Using kubectl Manifests**

**Apply all manifests in order:**

Create namespace: `kubectl create namespace voting-app`

Apply secrets: `kubectl apply -f k8s/manifests/01-secrets.yaml`

Apply ConfigMaps: `kubectl apply -f k8s/manifests/02-configmap.yaml`

Apply PostgreSQL: `kubectl apply -f k8s/manifests/03-postgres.yaml`

Apply Redis: `kubectl apply -f k8s/manifests/04-redis.yaml`

Apply Vote: `kubectl apply -f k8s/manifests/05-vote.yaml`

Apply Worker: `kubectl apply -f k8s/manifests/06-worker.yaml`

Apply Result: `kubectl apply -f k8s/manifests/07-result.yaml`

Apply Ingress: `kubectl apply -f k8s/manifests/08-ingress.yaml`

**Or apply all at once:** `kubectl apply -f k8s/manifests/`

**Verify deployment:**

`kubectl get pods -n voting-app`

All pods should show "Running" status within 2-3 minutes.

**Step 4: Deploy Using Helm Charts**

**Add Helm repo (if needed):**

`helm repo add bitnami https://charts.bitnami.com/bitnami`

`helm repo update`

**Install voting-app chart:**

`helm install voting-app k8s/helm/voting-app --namespace voting-app --create-namespace`

**Verify deployment:**

`helm list -n voting-app`

`kubectl get pods -n voting-app`

**Customize values:**

Create custom-values.yaml with overrides:

- vote.replicaCount: 3
- result.replicaCount: 2
- postgres.persistence.size: 5Gi

Install with custom values: `helm install voting-app k8s/helm/voting-app -f custom-values.yaml --namespace voting-app --create-namespace`

**Step 5: Configure Ingress Access**

**Get Minikube IP:**

`minikube ip`

Example output: `192.168.49.2`

**Update /etc/hosts on Linux/Mac:**

`echo "192.168.49.2 vote.local result.local" | sudo tee -a /etc/hosts`

Or edit manually: `sudo nano /etc/hosts`

Add line: `192.168.49.2 vote.local result.local`

**Update hosts on Windows:**

Open PowerShell as Administrator

Edit: `notepad C:\Windows\System32\drivers\etc\hosts`

Add line: `192.168.49.2 vote.local result.local`

**Step 6: Verify Services Are Running**

**Check all pods:**

`kubectl get pods -n voting-app -o wide`

Expected: All pods in "Running" state, 1/1 or 2/2 Ready.

**Check services:**

`kubectl get svc -n voting-app`

Expected services:

- vote (ClusterIP, port 80)
- result (ClusterIP, port 4000)
- redis (ClusterIP, port 6379)
- postgres (ClusterIP, port 5432)

**Check ingress:**

`kubectl get ingress -n voting-app`

Expected: vote-ingress and result-ingress with Minikube IP in ADDRESS column.

**Step 7: Run Smoke Tests**

**Test Vote application:**

`curl -I http://vote.local`

Expected: HTTP/1.1 200 OK

**Test Result application:**

`curl -I http://result.local`

Expected: HTTP/1.1 200 OK

**Submit test vote:**

`curl -X POST http://vote.local -d "vote=a"`

Expected: HTTP 200 response

**Check results:**

`curl http://result.local`

Expected: HTML with vote counts

**Step 8: Verify Database Connectivity**

**Test PostgreSQL from worker pod:**

`kubectl exec -n voting-app deployment/worker -- env | grep DATABASE_URL`

Expected: Shows PostgreSQL connection string

**Connect to PostgreSQL:**

`kubectl exec -n voting-app statefulset/postgres -- psql -U postgres -d postgres -c "SELECT COUNT(*) FROM votes;"`

Expected: Returns vote count

**Test Redis from vote pod:**

`kubectl exec -n voting-app deployment/vote -- nc -zv redis 6379`

Expected: Connection succeeded message

**Ping Redis:**

`kubectl exec -n voting-app statefulset/redis -- redis-cli ping`

Expected: PONG

### Complete Testing Workflow (Phase 2)

Follow this exact workflow to test the entire Kubernetes setup from scratch:

**🚀 Quick Command to Run All Phase 2 Tests:**

```bash
# Clean, deploy, and test Kubernetes setup in one go
kubectl delete namespace voting-app --ignore-not-found=true && \
kubectl wait --for=delete namespace/voting-app --timeout=60s 2>/dev/null || true && \
minikube status || minikube start --cpus=4 --memory=8192 --driver=docker && \
minikube addons enable ingress && \
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s && \
kubectl apply -f k8s/manifests/ && \
kubectl wait --for=condition=ready pod --all -n voting-app --timeout=300s && \
echo "$(minikube ip) vote.local result.local" | sudo tee -a /etc/hosts && \
kubectl get pods -n voting-app && \
echo "✅ Phase 2 deployment complete! Access at http://vote.local and http://result.local"
```

**📝 Detailed Step-by-Step Workflow:**

**1️⃣ Clean up any existing deployment**

`kubectl delete namespace voting-app --ignore-not-found=true`

Wait for namespace deletion: `kubectl wait --for=delete namespace/voting-app --timeout=60s`

**2️⃣ Start Minikube (if not running)**

`minikube start --cpus=4 --memory=8192 --driver=docker`

Verify cluster: `kubectl cluster-info`

**3️⃣ Enable Ingress addon**

`minikube addons enable ingress`

Wait for ingress controller: `kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s`

**4️⃣ Deploy all Kubernetes manifests**

`kubectl apply -f k8s/manifests/`

This command:

- ✅ Creates namespace
- ✅ Creates secrets and ConfigMaps
- ✅ Deploys PostgreSQL, Redis, Vote, Worker, Result
- ✅ Creates services and ingress

**5️⃣ Wait for all pods to be ready**

`kubectl wait --for=condition=ready pod --all -n voting-app --timeout=300s`

Check status: `kubectl get pods -n voting-app`

Expected output:

- ✅ All pods show "Running" status
- ✅ All pods show "1/1" or "2/2" READY
- ✅ No CrashLoopBackOff or Error states

**6️⃣ Verify services and endpoints**

`kubectl get svc -n voting-app`

Expected services:

- ✅ vote (ClusterIP, port 80)
- ✅ result (ClusterIP, port 4000)
- ✅ redis (ClusterIP, port 6379)
- ✅ postgres (ClusterIP, port 5432)

Check endpoints: `kubectl get endpoints -n voting-app`

Expected: All services have endpoints listed (not `<none>`)

**7️⃣ Configure /etc/hosts**

Get Minikube IP: `minikube ip`

Add to /etc/hosts (Linux/Mac): `echo "$(minikube ip) vote.local result.local" | sudo tee -a /etc/hosts`

Verify: `cat /etc/hosts | grep -E "vote.local|result.local"`

**8️⃣ Test the applications**

Vote application: `curl -I http://vote.local`

Expected: HTTP/1.1 200 OK

Result application: `curl -I http://result.local`

Expected: HTTP/1.1 200 OK

Submit test vote: `curl -X POST http://vote.local -d "vote=a"`

Check results: `curl http://result.local`

**9️⃣ View logs**

Vote logs: `kubectl logs -n voting-app deployment/vote --tail=20`

Worker logs: `kubectl logs -n voting-app deployment/worker --tail=20 -f`

Result logs: `kubectl logs -n voting-app deployment/result --tail=20`

Check for:

- ✅ No error messages
- ✅ Worker: "Connected to redis" and "Connected to db"
- ✅ Vote/Result: No connection failures

**🔟 Test database connectivity**

Connect to PostgreSQL: `kubectl exec -n voting-app statefulset/postgres -- psql -U postgres -d postgres -c "SELECT COUNT(*) FROM votes;"`

Expected: Returns vote count (0 or more)

Test Redis: `kubectl exec -n voting-app statefulset/redis -- redis-cli ping`

Expected: PONG

**1️⃣1️⃣ Run seed data (Optional)**

`kubectl apply -f k8s/manifests/10-seed.yaml`

Wait for job: `kubectl wait --for=condition=complete job/seed-data -n voting-app --timeout=300s`

View logs: `kubectl logs -n voting-app job/seed-data`

Expected output:

- "Vote service is ready"
- "Generating 2000 votes for option a"
- "Generating 1000 votes for option b"
- "Seed data generation complete"

Verify at <http://result.local>:

- ✅ Cats: ~2000 votes
- ✅ Dogs: ~1000 votes

**1️⃣2️⃣ Test scaling**

Scale vote deployment: `kubectl scale deployment vote -n voting-app --replicas=3`

Verify: `kubectl get pods -n voting-app -l app=vote`

Expected: 3 vote pods running

Submit multiple votes and check load distribution

Scale back: `kubectl scale deployment vote -n voting-app --replicas=2`

**1️⃣3️⃣ Test persistence**

Submit some votes, then delete worker pod: `kubectl delete pod -n voting-app -l app=worker`

Wait for new pod: `kubectl wait --for=condition=ready pod -l app=worker -n voting-app --timeout=60s`

Check results: `curl http://result.local`

Expected: ✅ Vote counts persist (PostgreSQL has persistent volume)

**1️⃣4️⃣ Clean up after testing**

Delete namespace: `kubectl delete namespace voting-app`

Or keep running for further testing

Stop Minikube (optional): `minikube stop`

Delete Minikube (removes all data): `minikube delete`

---

### Can You Deploy with Terraform?

**Yes, but with limitations for this project:**

**Current State:**

- ❌ Terraform workflow is **disabled** for local Minikube deployments
- ✅ Terraform configuration exists in the project for **cloud deployments only**
- ✅ Minikube uses **kubectl manifests** or **Helm charts** (recommended approach)

**When to Use Terraform:**

Terraform is designed for provisioning **cloud infrastructure**, not local Minikube clusters. Use Terraform when:

1. **Provisioning Cloud Kubernetes Clusters:**
   - AWS EKS (Elastic Kubernetes Service)
   - Azure AKS (Azure Kubernetes Service)
   - Google GKE (Google Kubernetes Engine)

2. **Managing Cloud Resources:**
   - VPCs, subnets, load balancers
   - IAM roles and policies
   - Storage buckets and databases
   - DNS and networking

**How to Deploy to Cloud with Terraform (Future Enhancement):**

**Step 1: Configure Terraform variables**

Edit `terraform/variables.tf`:

```hcl
variable "cloud_provider" {
  default = "aws"  # or "azure", "gcp"
}

variable "cluster_name" {
  default = "voting-app-cluster"
}

variable "region" {
  default = "us-east-1"
}
```

**Step 2: Add cloud provider credentials**

GitHub repo Settings → Secrets → Add:

- `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` (for AWS)
- `AZURE_CREDENTIALS` (for Azure)
- `GCP_SERVICE_ACCOUNT_KEY` (for GCP)

**Step 3: Enable Terraform workflow**

Uncomment triggers in `.github/workflows/terraform.yml`:

```yaml
on:
  push:
    branches: [ main ]
    paths:
      - 'terraform/**'
  pull_request:
    branches: [ main ]
```

**Step 4: Run Terraform**

```bash
# Initialize Terraform
cd terraform/
terraform init

# Plan infrastructure changes
terraform plan -out=tfplan

# Apply changes (provision cluster)
terraform apply tfplan

# Get cluster credentials
aws eks update-kubeconfig --name voting-app-cluster --region us-east-1  # AWS
az aks get-credentials --resource-group voting-app --name voting-app-cluster  # Azure
gcloud container clusters get-credentials voting-app-cluster --region us-central1  # GCP

# Deploy application to cloud cluster
kubectl apply -f k8s/manifests/
```

**Step 5: Enable monitoring workflow**

Add `KUBECONFIG` secret and uncomment `.github/workflows/deploy-monitoring.yml` triggers.

**Why Not Use Terraform for Minikube?**

1. **Minikube is ephemeral** - Destroyed and recreated frequently
2. **kubectl is simpler** - Direct manifest application is faster
3. **No cloud resources** - Terraform manages cloud infrastructure, not local VMs
4. **State management overhead** - Terraform state adds complexity for local testing

**Recommended Local Approach:**

```bash
# For Minikube: Use kubectl or Helm (current setup)
kubectl apply -f k8s/manifests/

# Or use Helm for easier management
helm install voting-app k8s/helm/voting-app -n voting-app --create-namespace
```

**Terraform vs kubectl vs Helm Comparison:**

| Tool | Best For | Phase 2 Support |
|------|----------|-----------------|
| **kubectl** | Direct Kubernetes resources, local testing | ✅ Recommended for Minikube |
| **Helm** | Templated deployments, version management | ✅ Recommended for Minikube |
| **Terraform** | Cloud infrastructure, multi-cloud resources | ❌ Not needed for Minikube |

**Summary:**

- **For Phase 2 (Minikube):** Use kubectl or Helm commands above ✅
- **For Cloud Deployment:** Use Terraform to provision cluster, then kubectl/Helm to deploy app ✅
- **Terraform is disabled** because this project focuses on local Minikube development 📌

---

**Step 9: Monitor Pod Status**

**Watch pods in real-time:**

`kubectl get pods -n voting-app -w`

Press Ctrl+C to stop watching.

**Check pod logs:**

Vote logs: `kubectl logs -n voting-app deployment/vote -f`

Worker logs: `kubectl logs -n voting-app deployment/worker -f`

Result logs: `kubectl logs -n voting-app deployment/result -f`

**Describe pod for details:**

`kubectl describe pod -n voting-app <pod-name>`

Shows events, resource usage, and status.

**Step 10: Test Application Functionality**

**Open in browser:**

Vote: <http://vote.local> (submit votes for Cats or Dogs)

Result: <http://result.local> (view live results)

**Verify data flow:**

1. Submit vote at vote.local
2. Check worker logs: `kubectl logs -n voting-app deployment/worker --tail=20`
3. Should see "Processing vote" messages
4. Check results update at result.local

### Testing Kubernetes Deployment

**Test 1: Pod Health Check**

`kubectl get pods -n voting-app`

Expected: All pods Running with 1/1 or 2/2 Ready

**Test 2: Service Endpoints**

`kubectl get endpoints -n voting-app`

Expected: All services have endpoints listed

**Test 3: Ingress Configuration**

`kubectl describe ingress vote-ingress -n voting-app`

Expected: Rules for vote.local, backend pointing to vote service port 80

`kubectl describe ingress result-ingress -n voting-app`

Expected: Rules for result.local, backend pointing to result service port 4000

**Test 4: Database Persistence**

Submit votes, then delete and recreate worker pod:

`kubectl delete pod -n voting-app -l app=worker`

Wait for new pod: `kubectl wait --for=condition=ready pod -l app=worker -n voting-app --timeout=60s`

Check results still show: Open <http://result.local>

Expected: Vote counts persist (PostgreSQL StatefulSet has persistent volume)

**Test 5: Resource Limits**

`kubectl describe pod -n voting-app -l app=vote | grep -A 5 "Limits"`

Expected: CPU and memory limits defined (e.g., 500m CPU, 512Mi memory)

**Test 6: Network Policies (if applied)**

`kubectl get networkpolicies -n voting-app`

If network policies are configured, test isolation between services.

**Test 7: Horizontal Scaling**

Scale vote deployment: `kubectl scale deployment vote -n voting-app --replicas=3`

Verify scaling: `kubectl get pods -n voting-app -l app=vote`

Expected: 3 vote pods running

Test load distribution: Submit multiple votes and check logs from different pods.

Scale back: `kubectl scale deployment vote -n voting-app --replicas=2`

**Test 8: ConfigMap and Secrets**

Verify ConfigMap: `kubectl get configmap -n voting-app`

View ConfigMap data: `kubectl describe configmap app-config -n voting-app`

Verify secrets: `kubectl get secrets -n voting-app`

Check secret is not plaintext in manifests: `cat k8s/manifests/01-secrets.yaml | grep password`

**Test 9: Ingress Controller**

Check ingress controller pods: `kubectl get pods -n ingress-nginx`

Expected: ingress-nginx-controller pod Running

Test ingress from outside cluster: `curl -H "Host: vote.local" http://$(minikube ip)`

Expected: HTML response from vote service

**Test 10: End-to-End Kubernetes Test**

Execute full workflow:

1. Submit 10 votes via vote.local
2. Monitor worker processing: `kubectl logs -n voting-app deployment/worker -f`
3. Check database: `kubectl exec -n voting-app statefulset/postgres -- psql -U postgres -d postgres -c "SELECT COUNT(*) FROM votes;"`
4. Verify results at result.local
5. Expected: All votes processed and displayed

### Common Kubernetes Commands

**Namespace Management:**

- Create namespace: `kubectl create namespace voting-app`
- List namespaces: `kubectl get namespaces`
- Delete namespace: `kubectl delete namespace voting-app`

**Pod Management:**

- List pods: `kubectl get pods -n voting-app`
- Describe pod: `kubectl describe pod <pod-name> -n voting-app`
- Delete pod: `kubectl delete pod <pod-name> -n voting-app`
- Execute command: `kubectl exec -n voting-app <pod-name> -- <command>`
- View logs: `kubectl logs -n voting-app <pod-name> -f`

**Deployment Management:**

- List deployments: `kubectl get deployments -n voting-app`
- Scale deployment: `kubectl scale deployment <name> --replicas=3 -n voting-app`
- Update image: `kubectl set image deployment/<name> <container>=<new-image> -n voting-app`
- Rollout status: `kubectl rollout status deployment/<name> -n voting-app`
- Rollback: `kubectl rollout undo deployment/<name> -n voting-app`

**Service Management:**

- List services: `kubectl get svc -n voting-app`
- Describe service: `kubectl describe svc <service-name> -n voting-app`
- Port forward: `kubectl port-forward svc/<service-name> 8080:80 -n voting-app`

**Helm Commands:**

- List releases: `helm list -n voting-app`
- Upgrade release: `helm upgrade voting-app k8s/helm/voting-app -n voting-app`
- Uninstall release: `helm uninstall voting-app -n voting-app`
- Show values: `helm get values voting-app -n voting-app`
- Test release: `helm test voting-app -n voting-app`

### Troubleshooting Kubernetes

**Problem: Pods Not Starting**

Check pod status: `kubectl get pods -n voting-app`

Describe pod for events: `kubectl describe pod <pod-name> -n voting-app`

Common causes:

- ImagePullBackOff: Image not found in registry
- CrashLoopBackOff: Application crashing on startup
- Pending: Insufficient resources or scheduling issues

**Problem: Image Pull Errors**

For GHCR images, authenticate: `echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin`

Pull manually: `docker pull ghcr.io/<your-org>/vote:latest`

Load into Minikube: `minikube image load ghcr.io/<your-org>/vote:latest`

Or build locally: `eval $(minikube docker-env)` then `docker build -t vote:latest ./vote`

**Problem: Ingress Not Working**

Verify ingress addon: `minikube addons list | grep ingress`

Enable if disabled: `minikube addons enable ingress`

Check ingress controller: `kubectl get pods -n ingress-nginx`

Verify /etc/hosts: `cat /etc/hosts | grep vote.local`

Test with IP: `curl -H "Host: vote.local" http://$(minikube ip)`

**Problem: Database Connection Failures**

Check PostgreSQL pod: `kubectl get pods -n voting-app -l app=postgres`

View PostgreSQL logs: `kubectl logs -n voting-app statefulset/postgres`

Test connection from worker: `kubectl exec -n voting-app deployment/worker -- nc -zv postgres 5432`

Check secret: `kubectl get secret postgres-secret -n voting-app -o yaml`

Verify DATABASE_URL env var: `kubectl exec -n voting-app deployment/worker -- env | grep DATABASE`

**Problem: Services Not Accessible**

Check service exists: `kubectl get svc -n voting-app`

Check endpoints: `kubectl get endpoints -n voting-app`

If endpoints empty, pods may not be ready or labels mismatch

Port forward to test: `kubectl port-forward svc/vote 8080:80 -n voting-app` then open localhost:8080

**Problem: Persistent Data Loss**

Check PersistentVolumeClaim: `kubectl get pvc -n voting-app`

Describe PVC: `kubectl describe pvc postgres-pvc -n voting-app`

Ensure PVC is Bound to PersistentVolume

For Minikube, PVs use hostPath (local disk)

Verify volume mount: `kubectl describe pod -n voting-app statefulset/postgres | grep -A 5 "Mounts"`

### Monitoring with Prometheus and Grafana (Optional)

**Step 1: Add Prometheus Helm repository**

`helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`

`helm repo update`

**Step 2: Install Prometheus and Grafana stack**

`helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace --wait`

This installs:

- Prometheus for metrics collection
- Grafana for visualization
- Alertmanager for alerts
- Node exporter for hardware metrics
- Kube-state-metrics for K8s metrics

**Step 3: Access Grafana**

Port forward: `kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80`

Open browser: <http://localhost:3000>

Default credentials: admin / prom-operator

**Step 4: View voting-app metrics**

Navigate to Dashboards in Grafana

Use pre-built dashboards:

- Kubernetes / Compute Resources / Namespace (Pods)
- Kubernetes / Compute Resources / Pod

Filter by namespace: voting-app

**Step 5: Create custom dashboard**

Add panels for:

- CPU usage by pod
- Memory usage by pod
- Network traffic
- Pod restart count

Query examples:

- CPU: `rate(container_cpu_usage_seconds_total{namespace="voting-app"}[5m])`
- Memory: `container_memory_working_set_bytes{namespace="voting-app"}`

### CI/CD Workflow

**Active Workflows:**

1. **CI/CD Pipeline** (`.github/workflows/ci-cd.yml`)
   - Triggers on push to main or develop branches
   - Builds Docker images for vote, result, and worker
   - Runs Snyk security scans (Code, Open Source, Container, IaC)
   - Pushes images to GitHub Container Registry with commit SHA tags
   - Provides deployment instructions in workflow summary

2. **Security Scanning** (`.github/workflows/security-scanning.yml`)
   - Scheduled daily at midnight UTC
   - Runs on PRs to main branch
   - Comprehensive Snyk scans for all components

3. **Docker Compose Test** (`.github/workflows/docker-compose-test.yml`)
   - Runs on PRs to test Docker Compose setup
   - Builds and starts all services
   - Verifies services are healthy

**Disabled Workflows (For Cloud Only):**

1. **Deploy Monitoring** (`.github/workflows/deploy-monitoring.yml`)
   - Requires KUBECONFIG secret for cloud cluster
   - Use manual Helm commands for Minikube (see Monitoring section)

2. **Terraform Infrastructure** (`.github/workflows/terraform.yml`)
   - Provisions cloud K8s clusters (AKS/EKS/GKE)
   - Not needed for local Minikube

**To re-enable for cloud:**

- Add KUBECONFIG secret to GitHub repository
- Add cloud provider credentials
- Uncomment push/pull_request triggers in workflow YAML files
- Update terraform variables for your cloud provider

### Update Deployment After CI/CD

**Step 1: Get latest commit SHA**

Check GitHub Actions workflow run for commit SHA (e.g., `abc1234`)

Or get locally: `git rev-parse --short HEAD`

**Step 2: Update with Helm**

`helm upgrade voting-app k8s/helm/voting-app --namespace voting-app --set vote.image.tag=abc1234 --set result.image.tag=abc1234 --set worker.image.tag=abc1234 --reuse-values`

**Step 3: Or rollout restart**

`kubectl rollout restart deployment/vote -n voting-app`

`kubectl rollout restart deployment/result -n voting-app`

`kubectl rollout restart deployment/worker -n voting-app`

**Step 4: Verify update**

`kubectl get pods -n voting-app -o wide`

Check new pods are running with updated images

`kubectl describe pod -n voting-app <pod-name> | grep Image:`

### Cleanup Kubernetes Deployment

**Uninstall with Helm:**

`helm uninstall voting-app -n voting-app`

**Or delete with kubectl:**

`kubectl delete -f k8s/manifests/`

**Delete namespace:**

`kubectl delete namespace voting-app`

**Stop Minikube:**

`minikube stop`

**Delete Minikube cluster (removes all data):**

`minikube delete`

### Best Practices for Kubernetes

**Resource Management:**

- ✅ CPU and memory limits defined for all pods
- ✅ Resource requests for proper scheduling
- ✅ Horizontal Pod Autoscaling ready (HPA)

**Storage:**

- ✅ StatefulSets for PostgreSQL and Redis
- ✅ PersistentVolumeClaims for data persistence
- ✅ Volume mounts for configuration and secrets

**Networking:**

- ✅ Services for internal communication (ClusterIP)
- ✅ Ingress for external access
- ✅ Network policies for isolation (optional)

**Security:**

- ✅ Secrets for sensitive data (base64 encoded)
- ✅ Non-root containers
- ✅ Resource limits to prevent DoS
- ✅ RBAC for access control

**High Availability:**

- ✅ Multiple replicas for vote and result services
- ✅ Liveness and readiness probes
- ✅ Rolling update strategy
- ✅ Pod anti-affinity for distribution

### Secrets Management for Kubernetes

The current `k8s/manifests/01-secrets.yaml` contains base64-encoded development defaults:

- PostgreSQL password: `postgres` (base64: `cG9zdGdyZXM=`)
- Redis password: empty (no authentication)

**⚠️ These are ONLY for development!**

**For Production - Three Options:**

**Option 1: Manual Secret Creation**

`kubectl create secret generic postgres-secret --from-literal=postgres-user=postgres --from-literal=postgres-password='YOUR_STRONG_PASSWORD' --from-literal=postgres-db=postgres --namespace=voting-app`

Then delete or exclude `01-secrets.yaml` from deployment.

**Option 2: Sealed Secrets (Recommended for GitOps)**

Install controller: `kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml`

Install kubeseal CLI on Mac: `brew install kubeseal`

Install on Linux: Download from GitHub releases and `sudo install -m 755 kubeseal /usr/local/bin/kubeseal`

Create sealed secret:

`kubectl create secret generic postgres-secret --from-literal=postgres-password='YOUR_PASSWORD' --namespace=voting-app --dry-run=client -o yaml > /tmp/secret.yaml`

`kubeseal -f /tmp/secret.yaml -w k8s/manifests/01-postgres-sealed-secret.yaml`

Now you can safely commit the sealed secret to git!

Apply: `kubectl apply -f k8s/manifests/01-postgres-sealed-secret.yaml`

**Option 3: External Secrets Operator (Advanced)**

Install External Secrets Operator:

`helm repo add external-secrets https://charts.external-secrets.io`

`helm install external-secrets external-secrets/external-secrets --namespace external-secrets-system --create-namespace`

Supports AWS Secrets Manager, Azure Key Vault, Google Cloud Secret Manager, HashiCorp Vault, 1Password, and more.

Create secret in cloud provider, then create ExternalSecret resource referencing it. The operator automatically syncs secrets to Kubernetes.

**Security Best Practices:**

- ✅ Use strong passwords (minimum 16 characters)
- ✅ Generate with `openssl rand -base64 24`
- ✅ Rotate credentials every 90 days
- ✅ Different passwords per environment (dev/staging/prod)
- ✅ Use Kubernetes RBAC to restrict secret access
- ✅ Monitor secret access with audit logging
- ❌ Never commit plaintext secrets to git
- ❌ Never use default passwords in production
- ❌ Never share passwords between team members
- ❌ Never log passwords in application logs

**Emergency: Secret Compromised**

1. Generate new password: `NEW_PASS=$(openssl rand -base64 24)`
2. Update secret: `kubectl create secret generic postgres-secret --from-literal=postgres-password="$NEW_PASS" --namespace=voting-app --dry-run=client -o yaml | kubectl apply -f -`
3. Restart pods: `kubectl rollout restart deployment/vote deployment/result deployment/worker -n voting-app && kubectl rollout restart statefulset/postgres -n voting-app`
4. Notify team and review access logs

---

## 🔄 Stage 3: CI/CD Pipeline

The voting application consists of the following components:

![Architecture Diagram](./architecture.excalidraw.png)

### Frontend Services

- **Vote Service** (`/vote`): Python Flask web application that provides the voting interface
- **Result Service** (`/result`): Node.js web application that displays real-time voting results

### Backend Services  

- **Worker Service** (`/worker`): .NET worker application that processes votes from the queue
- **Redis**: Message broker that queues votes for processing
- **PostgreSQL**: Database that stores the final vote counts

### Data Flow

1. Users visit the vote service to cast their votes
2. Votes are sent to Redis queue
3. Worker service processes votes from Redis and stores them in PostgreSQL
4. Result service queries PostgreSQL and displays real-time results via WebSocket

### Network Architecture

The application uses a **two-tier network architecture** for security and organization:

- **Frontend Tier Network**:
  - Vote service (port 8080)
  - Result service (port 8081)
  - Accessible from outside the Docker environment

- **Backend Tier Network**:
  - Worker service
  - Redis
  - PostgreSQL
  - Internal communication only

This separation ensures that database and message queue services are not directly accessible from outside, while the web services remain accessible to users.

---

## 📁 Project Structure

The project consists of service directories (vote/, result/, worker/, seed-data/), Kubernetes manifests (k8s/manifests/), monitoring configuration (k8s/monitoring/), health check scripts (healthchecks/), documentation files, and the main docker-compose.yml orchestration file.

---

## 🎓 Best Practices Implemented

### Docker Best Practices

- ✅ **Multi-stage builds** for all services (40-60% size reduction)
- ✅ **Non-root users** in all containers (security)
- ✅ **Health checks** for critical services
- ✅ **Layer caching optimization** for faster builds
- ✅ **.dockerignore files** to reduce build context
- ✅ **Alpine images** where possible (smaller footprint)

### Docker Compose Best Practices

- ✅ **Two-tier networking** (frontend/backend isolation)
- ✅ **Service dependencies** with health check conditions
- ✅ **Named volumes** for data persistence
- ✅ **Resource limits** (CPU/memory)
- ✅ **Restart policies** for high availability
- ✅ **Profiles** for optional services (seed-data)

### Security Best Practices

- ✅ All containers run as non-root users
- ✅ Backend services isolated from external access
- ✅ Resource limits prevent DoS attacks
- ✅ No hardcoded secrets (environment variables)

---

## 🧪 Testing

### Automated Testing

# Run complete end-to-end test suite

./test-e2e.sh
The test script validates:

- All services are running
- Health checks pass
- Ports are accessible
- Vote submission works
- Data persistence works
- Security (non-root users)
- Resource limits
- Network configuration

### Manual Testing

# View all service status

docker compose ps

# View logs

docker compose logs -f

# Submit a test vote

curl -X POST <http://localhost:8080> \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "vote=a"

# Check results

curl <http://localhost:8081>

### Load Testing (Optional)

# Generate 3000 test votes

docker compose --profile seed up seed-data
---

## 📊 Service Details

| Service | Technology | Port | Network | Health Check |
|---------|-----------|------|---------|--------------|
| Vote | Python 3.11 / Flask / Gunicorn | 8080 | Frontend + Backend | HTTP |
| Result | Node.js 18 / Express / Socket.io | 8081 | Frontend + Backend | HTTP |
| Worker | .NET 7 / C# | - | Backend | - |
| Redis | Redis 7 Alpine | 6379 | Backend | Custom Script |
| PostgreSQL | Postgres 15 Alpine | 5432 | Backend | Custom Script |
| Seed Data | Python 3.11 Alpine / Apache Bench | - | Frontend | - |

---

## 🔧 Common Commands

# Start application

docker compose up -d

# View status

docker compose ps

# View logs (all services)

docker compose logs -f

# View logs (specific service)

docker compose logs -f vote

# Stop application

docker compose down

# Stop and remove volumes (fresh start)

docker compose down -v

# Rebuild specific service

docker compose build vote
docker compose up -d vote

# Run automated tests

./test-e2e.sh

# Generate seed data

docker compose --profile seed up seed-data

# View resource usage

docker stats
---

## 🐛 Troubleshooting

### Services Won't Start

# Check logs

docker compose logs <service-name>

# Rebuild with no cache

docker compose build --no-cache

# Check for port conflicts

sudo lsof -i :8080
sudo lsof -i :8081

### Health Checks Failing

# Test health check manually

docker compose exec redis sh /healthchecks/redis.sh
docker compose exec db sh /healthchecks/postgres.sh

# Check service connectivity

docker compose exec vote ping redis
docker compose exec worker ping db

### Data Not Persisting

# Verify volumes exist

docker volume ls | grep voting-app

# Inspect volume

docker volume inspect voting-app-db-data
---

## 🔄 Stage 3: CI/CD Pipeline

### Overview

GitHub Actions workflows automate building, testing, security scanning, and deployment of the voting application. The pipeline runs on every push and pull request, ensuring code quality and security before deployment.

### Active CI/CD Workflows

**1. CI/CD Pipeline** (`.github/workflows/ci-cd.yml`)

**Triggers:**

- Push to main or develop branches
- Pull requests to main

**Jobs:**

1. Build and Push Docker Images
   - Builds vote, result, and worker services
   - Tags with commit SHA and latest
   - Pushes to GitHub Container Registry (GHCR)
   - Image naming: `ghcr.io/<org>/<service>:<tag>`

2. Security Scans
   - Snyk Code (SAST) for vote, result, worker
   - Snyk Open Source (SCA) for dependencies
   - Snyk Container for Docker image vulnerabilities
   - Snyk IaC for Kubernetes manifests

3. Deployment Instructions
   - Generates workflow summary with deployment commands
   - Includes image tags and kubectl/helm commands
   - Manual deployment to local Minikube

**Output:** Docker images in GHCR, security scan reports, deployment instructions

**2. Security Scanning** (`.github/workflows/security-scanning.yml`)

**Triggers:**

- Scheduled daily at midnight UTC
- Pull requests to main branch

**Scans:**

- Snyk Code for static analysis
- Snyk Open Source for vulnerable dependencies
- Snyk Container for image CVEs
- Snyk IaC for Kubernetes misconfigurations

**Output:** Security findings uploaded to GitHub Security tab

**3. Docker Compose Test** (`.github/workflows/docker-compose-test.yml`)

**Triggers:**

- Pull requests to validate Docker Compose setup

**Steps:**

1. Checkout code
2. Build all services with docker compose build
3. Start services with docker compose up -d
4. Wait for health checks to pass
5. Verify all services are running
6. Run smoke tests on vote and result endpoints
7. Cleanup with docker compose down

**Output:** Pass/fail status on PR, logs in workflow run

### Disabled Workflows (Cloud Only)

**1. Deploy Monitoring** (`.github/workflows/deploy-monitoring.yml`)

**Purpose:** Deploy Prometheus and Grafana to cloud Kubernetes cluster

**Why disabled:** Requires KUBECONFIG secret for cloud cluster access

**To enable:**

- Add KUBECONFIG secret: GitHub repo Settings → Secrets → New repository secret
- Uncomment push/pull_request triggers in workflow file
- Ensure cluster credentials have proper RBAC permissions

**2. Terraform Infrastructure** (`.github/workflows/terraform.yml`)

**Purpose:** Provision cloud Kubernetes clusters (AKS/EKS/GKE)

**Why disabled:** Only needed for cloud deployments, not local Minikube

**To enable:**

- Add cloud provider credentials as secrets (AWS_ACCESS_KEY_ID, AZURE_CREDENTIALS, etc.)
- Configure terraform variables in `terraform/variables.tf`
- Uncomment workflow triggers
- Run manually first to test: Actions → Terraform → Run workflow

### Security Scanning with Snyk

**What Gets Scanned:**

1. **Snyk Code (SAST):**
   - vote/app.py (Python)
   - result/server.js (JavaScript)
   - worker/Program.cs (C#)
   - Detects: SQL injection, XSS, hardcoded secrets, insecure crypto

2. **Snyk Open Source (SCA):**
   - vote/requirements.txt (Python dependencies)
   - result/package.json (npm dependencies)
   - worker/Worker.csproj (NuGet packages)
   - Detects: Known CVEs in dependencies

3. **Snyk Container:**
   - vote:latest, result:latest, worker:latest Docker images
   - Detects: OS package vulnerabilities, outdated base images

4. **Snyk IaC:**
   - k8s/manifests/*.yaml (Kubernetes configs)
   - docker-compose.yml
   - Detects: Missing resource limits, privileged containers, exposed secrets

**Running Scans Locally:**

Install Snyk CLI: `npm install -g snyk` or `brew install snyk`

Authenticate: `snyk auth`

Scan code: `snyk code test vote/`

Scan dependencies: `snyk test --file=result/package.json`

Scan Docker image: `snyk container test vote:latest`

Scan Kubernetes: `snyk iac test k8s/manifests/`

Run all scans: `./snyk-full-scan.sh`

**Interpreting Results:**

Severity levels:

- **Critical**: Immediate action required, exploitable vulnerability
- **High**: Fix soon, significant security risk
- **Medium**: Fix in next release, moderate risk
- **Low**: Fix when possible, minor risk

Each finding includes:

- CVE or CWE identifier
- Affected package and version
- Fix recommendation (upgrade to version X)
- CVSS score and attack vector

**Fixing Issues:**

For dependency vulnerabilities:

- Upgrade to patched version: `npm update <package>` or `pip install --upgrade <package>`
- If no fix available, consider alternative package or apply workaround

For code issues:

- Review Snyk suggestion in workflow output
- Apply recommended code change
- Rescan to verify fix: `snyk code test <directory>`

For container issues:

- Update base image: Change `FROM python:3.11-alpine` to newer version
- Rebuild and rescan: `docker build -t vote:latest vote/` then `snyk container test vote:latest`

For IaC issues:

- Add missing resource limits in Kubernetes manifests
- Remove privileged: true from containers
- Use secrets instead of environment variables for sensitive data

### GitHub Container Registry (GHCR)

**Image Naming Convention:**

`ghcr.io/<github-org>/<service>:<tag>`

Examples:

- `ghcr.io/tactful/vote:abc1234` (commit SHA tag)
- `ghcr.io/tactful/vote:latest` (latest tag)

**Pulling Images:**

Authenticate to GHCR: `echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin`

Pull image: `docker pull ghcr.io/<org>/vote:latest`

Load into Minikube: `minikube image load ghcr.io/<org>/vote:latest`

**Image Lifecycle:**

1. Developer pushes code to GitHub
2. CI/CD workflow builds Docker image
3. Snyk scans image for vulnerabilities
4. If scans pass, image pushed to GHCR
5. Image tagged with commit SHA and latest
6. Developer manually deploys to Minikube using helm upgrade or kubectl

**Retention Policy:**

- Latest tag: Always kept
- Commit SHA tags: Kept for 90 days
- Untagged images: Cleaned up weekly

### Deployment from CI/CD

**After GitHub Actions builds new images:**

**Option 1: Helm upgrade**

Get commit SHA from Actions: Navigate to Actions → CI/CD Pipeline → Select run → Note commit SHA (e.g., `abc1234`)

Upgrade with Helm:

`helm upgrade voting-app k8s/helm/voting-app --namespace voting-app --set vote.image.tag=abc1234 --set result.image.tag=abc1234 --set worker.image.tag=abc1234 --reuse-values`

Verify update: `kubectl get pods -n voting-app -o wide`

**Option 2: kubectl rollout restart**

This pulls latest images if tag is `latest`:

`kubectl rollout restart deployment/vote -n voting-app`

`kubectl rollout restart deployment/result -n voting-app`

`kubectl rollout restart deployment/worker -n voting-app`

Watch rollout: `kubectl rollout status deployment/vote -n voting-app`

**Option 3: kubectl set image**

Update specific deployment with new image:

`kubectl set image deployment/vote vote=ghcr.io/<org>/vote:abc1234 -n voting-app`

Verify update: `kubectl describe pod -n voting-app -l app=vote | grep Image:`

### Viewing CI/CD Results

**In GitHub Actions:**

Navigate to repository → Actions tab → Select workflow run

View job logs:

- Click on job name (e.g., "Build and Push Docker Images")
- Expand steps to see output
- Check security scan results in "Snyk Code Test" step

Download artifacts:

- Scroll to bottom of workflow run page
- Click on artifact name (e.g., "snyk-reports")
- Unzip and view HTML reports

**In GitHub Security:**

Navigate to repository → Security tab → Vulnerability alerts

View Dependabot alerts: Automatically created PRs for vulnerable dependencies

View Snyk findings: Integrated with GitHub Security scanning

Filter by severity: Use dropdown to show only Critical or High

**Workflow Summaries:**

Each workflow run generates a summary with:

- Build status and image tags
- Security scan results summary
- Deployment commands with image tags
- Links to GHCR images

Access: Click on workflow run → Scroll to Summary section

### CI/CD Best Practices Implemented

✅ **Automated Builds:**

- Every push triggers build
- Images tagged with commit SHA for traceability
- Multi-platform builds (amd64)

✅ **Security Scanning:**

- Multiple scan types (SAST, SCA, Container, IaC)
- Scans run before deployment
- Daily scheduled scans catch new vulnerabilities

✅ **Image Management:**

- Centralized registry (GHCR)
- Tagged with commit SHA and latest
- Scanned images only

✅ **Manual Deployment:**

- Controlled deployment to Minikube
- Clear deployment instructions in workflow summary
- Version pinning with commit SHA tags

✅ **Workflow Organization:**

- Separate workflows for different purposes
- Reusable workflows for common tasks
- Clear naming and documentation

### Troubleshooting CI/CD

**Problem: Workflow Fails on Build**

Check build logs in GitHub Actions → Expand failed step

Common causes:

- Dockerfile syntax error: Review Dockerfile in service directory
- Build context too large: Add files to .dockerignore
- Network issues: Retry workflow (Re-run failed jobs button)

**Problem: Security Scan Fails**

Check Snyk output: Actions → Workflow run → Snyk step

If critical vulnerabilities found:

- Fix vulnerabilities locally: Follow Snyk recommendations
- Rescan locally: `snyk test` before pushing
- Push fixes and trigger new workflow run

To bypass (not recommended): Add `continue-on-error: true` to Snyk step

**Problem: Image Push Fails**

Check authentication: Ensure GITHUB_TOKEN has package:write permission

In repo Settings → Actions → General → Workflow permissions → Set to "Read and write permissions"

Verify GHCR access: Check GitHub profile → Packages for published images

**Problem: Workflow Not Triggering**

Check triggers in workflow file: `.github/workflows/ci-cd.yml` → `on:` section

Ensure pushing to correct branch: `git branch` to verify you're on main or develop

Check workflow is enabled: Actions → Select workflow → Enable workflow button (if present)

**Problem: Can't Pull Images from GHCR**

Authenticate to GHCR: `echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin`

Generate Personal Access Token: GitHub Settings → Developer settings → Personal access tokens → Generate with `read:packages` scope

For private repos: Ensure PAT has access to repository

Check image exists: Navigate to GitHub profile → Packages → Find voting-app images

### Setting Up CI/CD for Your Fork

**Step 1: Fork the repository**

Click Fork button on GitHub repository page

**Step 2: Enable GitHub Actions**

Navigate to forked repo → Actions tab → Click "I understand my workflows, go ahead and enable them"

**Step 3: Configure Snyk (Optional)**

Create Snyk account at snyk.io

Get API token: Snyk dashboard → Settings → API token

Add secret: Repo Settings → Secrets and variables → Actions → New repository secret

Name: `SNYK_TOKEN`, Value: your API token

**Step 4: Push code to trigger workflows**

Make a change: `echo "# Test" >> README.md`

Commit and push: `git add . && git commit -m "Test CI/CD" && git push origin main`

View workflow: Actions tab → CI/CD Pipeline → Watch progress

**Step 5: Deploy to Minikube**

After workflow completes, get commit SHA from Actions

Deploy with Helm: `helm upgrade voting-app k8s/helm/voting-app --set vote.image.tag=<commit-sha> --set result.image.tag=<commit-sha> --set worker.image.tag=<commit-sha> -n voting-app`

---

## 📊 Stage 4: Monitoring Stack

### Overview

Monitor the voting application with Prometheus for metrics collection, Grafana for visualization, and Loki for log aggregation. The monitoring stack provides insights into application performance, resource usage, and system health.

### Prerequisites

- Kubernetes cluster running (Minikube or cloud)
- Helm 3 installed: `helm version`
- kubectl access to cluster: `kubectl cluster-info`
- voting-app deployed: `kubectl get pods -n voting-app`

### Quick Start

**Step 1: Add Prometheus Helm repository**

`helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`

`helm repo update`

**Step 2: Install kube-prometheus-stack**

`helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace --wait`

This installs:

- Prometheus for metrics collection
- Grafana for dashboards
- Alertmanager for alerts
- Node exporter for hardware metrics
- Kube-state-metrics for Kubernetes metrics
- Pre-configured dashboards

Installation takes 2-3 minutes. Wait for all pods to be ready.

**Step 3: Access Grafana**

Port forward to Grafana: `kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80`

Open browser: <http://localhost:3000>

Login credentials:

- Username: `admin`
- Password: `prom-operator`

**Step 4: View voting-app metrics**

Navigate to Dashboards → Browse

Select "Kubernetes / Compute Resources / Namespace (Pods)"

Filter by namespace: Select `voting-app`

View CPU, memory, network for each pod

### Detailed Setup Steps

**Step 1: Create monitoring namespace**

`kubectl create namespace monitoring`

Verify: `kubectl get namespace monitoring`

**Step 2: Install Prometheus Operator**

Install with custom values:

`helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --values k8s/monitoring/prometheus-values-dev.yaml --wait`

The values file customizes:

- Resource limits for Prometheus
- Retention period (7 days for dev)
- Storage size (10Gi)
- Grafana admin password
- Alertmanager configuration

**Step 3: Verify Prometheus installation**

Check pods: `kubectl get pods -n monitoring`

Expected pods:

- prometheus-kube-prometheus-prometheus-0
- prometheus-grafana-<hash>
- prometheus-kube-state-metrics-<hash>
- prometheus-prometheus-node-exporter-<hash>
- alertmanager-prometheus-kube-prometheus-alertmanager-0

All should be Running.

Check services: `kubectl get svc -n monitoring`

Expected services:

- prometheus-kube-prometheus-prometheus (port 9090)
- prometheus-grafana (port 80)
- alertmanager-prometheus-kube-prometheus-alertmanager (port 9093)

**Step 4: Access Prometheus UI**

Port forward: `kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090`

Open browser: <http://localhost:9090>

Navigate to Status → Targets to see scraped endpoints

Expected targets:

- kubernetes-apiservers
- kubernetes-nodes
- kubernetes-pods
- kubernetes-service-endpoints

All should show "UP" status.

**Step 5: Access Grafana dashboards**

Port forward: `kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80`

Login: admin / prom-operator (or custom password from values file)

Change password on first login: Profile → Change Password

**Step 6: Import voting-app dashboards**

Navigate to Dashboards → Import

Enter dashboard ID or upload JSON:

- Kubernetes Cluster Monitoring: ID 7249
- Pod Resource Monitoring: ID 6417
- Node Exporter Full: ID 1860

Or create custom dashboard (see Custom Dashboards section below)

### Available Dashboards

**Pre-installed Dashboards:**

1. **Kubernetes / Compute Resources / Namespace (Pods)**
   - CPU usage per pod
   - Memory usage per pod
   - Network I/O per pod
   - Filter by namespace: voting-app

2. **Kubernetes / Compute Resources / Pod**
   - Detailed view of single pod
   - CPU throttling
   - Memory working set
   - Network bandwidth

3. **Kubernetes / Compute Resources / Cluster**
   - Overall cluster health
   - Node resource usage
   - Pod distribution
   - Total resource requests/limits

4. **Node Exporter Full**
   - CPU usage and load
   - Memory and swap
   - Disk I/O and space
   - Network traffic

### Querying Metrics with PromQL

**Common Queries for Voting App:**

**CPU Usage:**

Per pod: `rate(container_cpu_usage_seconds_total{namespace="voting-app"}[5m])`

By service: `sum by (pod) (rate(container_cpu_usage_seconds_total{namespace="voting-app"}[5m]))`

**Memory Usage:**

Per pod: `container_memory_working_set_bytes{namespace="voting-app"}`

As percentage: `(container_memory_working_set_bytes{namespace="voting-app"} / container_spec_memory_limit_bytes{namespace="voting-app"}) * 100`

**Network Traffic:**

Received bytes: `rate(container_network_receive_bytes_total{namespace="voting-app"}[5m])`

Transmitted bytes: `rate(container_network_transmit_bytes_total{namespace="voting-app"}[5m])`

**Pod Restarts:**

`kube_pod_container_status_restarts_total{namespace="voting-app"}`

**Request Rate (if service mesh enabled):**

`rate(http_requests_total{namespace="voting-app"}[5m])`

### Creating Custom Dashboards

**Step 1: Create new dashboard**

Grafana → Dashboards → New → New Dashboard

**Step 2: Add panels**

Click "Add visualization" → Select "Prometheus" as data source

**Panel 1: Vote Service CPU Usage**

Query: `rate(container_cpu_usage_seconds_total{namespace="voting-app",pod=~"vote-.*"}[5m])`

Visualization: Time series

Legend: `{{pod}}`

**Panel 2: Vote Service Memory Usage**

Query: `container_memory_working_set_bytes{namespace="voting-app",pod=~"vote-.*"} / 1024 / 1024`

Visualization: Time series

Unit: MiB

Legend: `{{pod}}`

**Panel 3: Worker Processing Rate**

Query: `rate(votes_processed_total[5m])`

Note: Requires custom metrics from worker (not implemented by default)

Visualization: Gauge

**Panel 4: PostgreSQL Connections**

Query: `pg_stat_database_numbackends{namespace="voting-app"}`

Note: Requires postgres-exporter sidecar

Visualization: Stat

**Panel 5: Redis Memory Usage**

Query: `redis_memory_used_bytes{namespace="voting-app"}`

Note: Requires redis-exporter sidecar

Visualization: Gauge

**Step 3: Arrange panels**

Drag panels to organize layout

Resize panels by dragging corners

Add rows to group related panels

**Step 4: Save dashboard**

Click Save dashboard icon (floppy disk)

Enter name: "Voting App Overview"

Select folder or create new

Click Save

**Step 5: Set refresh interval**

Top right corner → Refresh interval dropdown → Select 30s or 1m

Enable auto-refresh for live monitoring

### Setting Up Alerts

**Step 1: Access Alertmanager**

Port forward: `kubectl port-forward -n monitoring svc/alertmanager-prometheus-kube-prometheus-alertmanager 9093:9093`

Open browser: <http://localhost:9093>

**Step 2: Configure alert rules**

Create PrometheusRule resource:

File: `k8s/monitoring/prometheus-rules.yaml`

Example rules:

- High CPU usage (>80% for 5 minutes)
- High memory usage (>80% for 5 minutes)
- Pod restarts (>5 in 1 hour)
- Service down (0 ready pods)

Apply: `kubectl apply -f k8s/monitoring/prometheus-rules.yaml`

**Step 3: Configure notification channels**

Edit Alertmanager config: `kubectl edit secret -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager`

Add receivers:

- Email: SMTP configuration
- Slack: Webhook URL
- PagerDuty: Integration key

**Step 4: Test alerts**

Trigger high CPU: `kubectl run stress --image=progrium/stress -n voting-app -- --cpu 2`

Wait 5 minutes for alert to fire

Check Alertmanager UI for active alerts

Verify notification received

Cleanup: `kubectl delete pod stress -n voting-app`

### Log Aggregation with Loki (Optional)

**Step 1: Install Loki stack**

`helm repo add grafana https://grafana.github.io/helm-charts`

`helm install loki grafana/loki-stack --namespace monitoring --set grafana.enabled=false --set prometheus.enabled=false`

This installs:

- Loki for log storage
- Promtail for log collection
- Integrates with existing Grafana

**Step 2: Add Loki data source to Grafana**

Grafana → Configuration → Data Sources → Add data source → Loki

URL: `http://loki:3100`

Click "Save & Test"

**Step 3: View logs in Grafana**

Navigate to Explore → Select Loki data source

Query examples:

All logs from voting-app: `{namespace="voting-app"}`

Vote service logs: `{namespace="voting-app",app="vote"}`

Error logs: `{namespace="voting-app"} |= "error"`

Worker processing logs: `{namespace="voting-app",app="worker"} |= "Processing vote"`

**Step 4: Create log dashboard**

Add panel → Select Loki data source

Query: `{namespace="voting-app"}`

Visualization: Logs

Filter by time range and search term

Save to dashboard

### Monitoring Best Practices

**✅ DO:**

1. **Set appropriate retention:**
   - Dev: 7 days
   - Prod: 30-90 days

2. **Monitor key metrics:**
   - CPU and memory usage
   - Request rate and latency
   - Error rate
   - Pod restarts
   - Resource saturation

3. **Set up alerts:**
   - Critical: Page on-call engineer
   - Warning: Create ticket
   - Info: Log only

4. **Use dashboards:**
   - Overview dashboard for quick health check
   - Detailed dashboards per service
   - Share dashboards with team

5. **Regular review:**
   - Weekly review of trends
   - Monthly capacity planning
   - Quarterly alert tuning

**❌ DON'T:**

1. **Don't monitor everything:**
   - Focus on actionable metrics
   - Avoid vanity metrics
   - Reduce alert fatigue

2. **Don't ignore baselines:**
   - Establish normal patterns
   - Alert on deviations
   - Update baselines over time

3. **Don't forget costs:**
   - Prometheus storage grows quickly
   - Reduce cardinality of metrics
   - Implement retention policies

### Troubleshooting Monitoring

**Problem: Prometheus Not Scraping Targets**

Check ServiceMonitor: `kubectl get servicemonitor -n monitoring`

Verify labels match: `kubectl get svc -n voting-app --show-labels`

Check Prometheus logs: `kubectl logs -n monitoring prometheus-kube-prometheus-prometheus-0`

Verify RBAC: Prometheus needs permissions to scrape pods

**Problem: Grafana Not Showing Data**

Check data source: Configuration → Data Sources → Prometheus → Test

Verify time range: Adjust time picker in top right

Check query: Switch to Query Inspector to see actual PromQL

Verify metrics exist: Open Prometheus UI → Graph → Enter query

**Problem: High Memory Usage**

Reduce retention period: Edit prometheus.yaml → spec.retention

Reduce scrape interval: Edit ServiceMonitor → spec.interval

Limit series: Add relabeling rules to drop unnecessary metrics

**Problem: Alerts Not Firing**

Check alert rules: Prometheus UI → Alerts → View all rules

Verify rule syntax: `kubectl logs -n monitoring prometheus-kube-prometheus-prometheus-0 | grep -i error`

Check Alertmanager: Prometheus UI → Status → Runtime & Build → Alertmanagers → Should show "UP"

Test rule manually: Prometheus UI → Graph → Enter alert query → Check if returns data

**Problem: Can't Access Grafana**

Check pod: `kubectl get pods -n monitoring | grep grafana`

Port forward: `kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80`

Reset password: `kubectl exec -n monitoring <grafana-pod> -- grafana-cli admin reset-admin-password newpassword`

### Monitoring Stack Cleanup

**Uninstall Loki (if installed):**

`helm uninstall loki -n monitoring`

**Uninstall Prometheus stack:**

`helm uninstall prometheus -n monitoring`

**Delete monitoring namespace:**

`kubectl delete namespace monitoring`

**Delete CRDs (optional, careful!):**

`kubectl delete crd prometheuses.monitoring.coreos.com`

`kubectl delete crd servicemonitors.monitoring.coreos.com`

This removes all monitoring data and configuration.

---

## 🎯 Complete Testing Guide

- **[SETUP-GUIDE.md](./SETUP-GUIDE.md)** - Complete implementation guide with:
  - Detailed architecture explanation
  - Step-by-step implementation walkthrough
  - Comprehensive testing procedures
  - Best practices explanations
  - Security validation
  - Performance optimization tips

---

## ✅ Success Criteria

Your setup is complete when:

- ✅ All 5 services show "Up" status
- ✅ Redis and PostgreSQL show "(healthy)" status
- ✅ Can access vote app at <http://localhost:8080>
- ✅ Can access result app at <http://localhost:8081>
- ✅ Votes appear in results within 1-2 seconds
- ✅ `./test-e2e.sh` passes all tests
- ✅ Services recover from failures automatically
- ✅ Data persists across container restarts

---

## 🚀 Next Phases

### Phase 2 - Cloud Deployment (Coming Soon)

- Kubernetes manifests
- Helm charts
- Cloud provider configurations (AWS/GCP/Azure)

### Phase 3 - CI/CD Pipeline (Coming Soon)

- GitHub Actions / GitLab CI
- Automated testing
- Container scanning
- Deployment automation

### Phase 4 - Monitoring & Observability (Coming Soon)

- Prometheus metrics
- Grafana dashboards
- Log aggregation
- Distributed tracing

---

## 📞 Support

For detailed help and troubleshooting:

1. Check [SETUP-GUIDE.md](./SETUP-GUIDE.md) for comprehensive documentation
2. Review logs: `docker compose logs -f`
3. Run tests: `./test-e2e.sh`
4. Verify health: `docker compose ps`

---

## 🎉 Phase 1 Complete

**Congratulations!** You now have a fully containerized, production-ready local deployment with:

- ✅ Efficient multi-stage Dockerfiles
- ✅ Non-root security hardening
- ✅ Two-tier network architecture
- ✅ Comprehensive health checks
- ✅ Automated testing
- ✅ Complete documentation

Ready to move to Phase 2: Cloud Deployment! 🚀

## Your Task

As a DevOps engineer, your task is to containerize this application and create the necessary infrastructure files. You need to create:

### 1. Docker Files

Create `Dockerfile` for each service:

- `vote/Dockerfile` - for the Python Flask application
- `result/Dockerfile` - for the Node.js application  
- `worker/Dockerfile` - for the .NET worker application
- `seed-data/Dockerfile` - for the data seeding utility

### 2. Docker Compose

Create `docker-compose.yml` that:

- Defines all services with proper networking using **two-tier architecture**:
  - **Frontend tier**: Vote and Result services (user-facing)
  - **Backend tier**: Worker, Redis, and PostgreSQL (internal services)
- Sets up health checks for Redis and PostgreSQL
- Configures proper service dependencies
- Exposes the vote service on port 8080 and result service on port 8081
- Uses the provided health check scripts in `/healthchecks` directory

### 3. Health Checks

The application includes health check scripts:

- `healthchecks/redis.sh` - Redis health check
- `healthchecks/postgres.sh` - PostgreSQL health check

Use these scripts in your Docker Compose configuration to ensure services are ready before dependent services start.

## Requirements

- All services should be properly networked using **two-tier architecture**:
  - **Frontend tier network**: Connect Vote and Result services
  - **Backend tier network**: Connect Worker, Redis, and PostgreSQL
  - Both tiers should be isolated for security
- Health checks must be implemented for Redis and PostgreSQL
- Services should wait for their dependencies to be healthy before starting
- The vote service should be accessible at `http://localhost:8080`
- The result service should be accessible at `http://localhost:8081`
- Use appropriate base images and follow Docker best practices
- Ensure the application works end-to-end when running `docker compose up`
- Include a seed service that can populate test data

## Data Population

The application includes a seed service (`/seed-data`) that can populate the database with test votes:

- **`make-data.py`**: Creates URL-encoded vote data files (`posta` and `postb`)
- **`generate-votes.sh`**: Uses Apache Bench (ab) to send 3000 test votes:
  - 2000 votes for option A
  - 1000 votes for option B

### How to Use Seed Data

1. Include the seed service in your docker-compose.yml
2. Run the seed service after all other services are healthy: `docker compose run --rm seed`
3. Or run it as a one-time service with a profile: `docker compose --profile seed up`

## Getting Started

1. Examine the source code in each service directory
2. Create the necessary Dockerfiles
3. Create the docker-compose.yml file with two-tier networking
4. Test your implementation by running `docker compose up`
5. Populate test data using the seed service
6. Verify that you can vote and see results in real-time

## Notes

- The voting application only accepts one vote per client browser
- The result service uses WebSocket for real-time updates
- The worker service continuously processes votes from the Redis queue
- Make sure to handle service startup order properly with health checks

Good luck with your challenge! 🚀
