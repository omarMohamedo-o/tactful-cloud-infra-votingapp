# Voting Application - Cloud Infrastructure Project

> **Complete Cloud-Native DevOps Implementation**  
> Microservices • Docker • Kubernetes • Terraform • CI/CD • Monitoring • Security

---

## 🚀 Quick Start (3 Commands!)

```bash
# 1. Deploy everything with Terraform
cd terraform && terraform init && terraform apply -auto-approve

# 2. Configure /etc/hosts (sudo password once)
cd .. && chmod +x configure-hosts.sh && ./configure-hosts.sh

# 3. Access applications
curl http://vote.local      # Vote: Cats vs Dogs
curl http://result.local    # Real-time results
```

**✨ Simple, secure, and automated!**

---

## 📋 Table of Contents

- [Project Overview](#️-project-overview)
- [Project Structure](#-project-structure)
- [How to Build & Deploy](#-how-to-build--deploy)
- [Architecture](#-architecture)
- [Quick Command Reference](#-quick-command-reference)
- [Problems Faced & Solutions](#-problems-faced--solutions)
- [Documentation Links](#-documentation-links)

---

## 🏗️ Project Overview

A **distributed microservices voting application** demonstrating modern cloud-native DevOps practices. Users vote between Cats and Dogs, with real-time results displayed across multiple services.

### Application Components

| Service | Technology | Purpose | Port |
|---------|-----------|---------|------|
| **Vote** | Python 3.11 + Flask | User voting interface | 8080 |
| **Result** | Node.js 18 + Socket.io | Real-time results display | 8081 |
| **Worker** | .NET 8.0 + C# | Process votes from queue | - |
| **Redis** | Redis 7 Alpine | Message queue | 6379 |
| **PostgreSQL** | Postgres 15 Alpine | Persistent storage | 5432 |
| **Seed** | Shell script | Generate 3000 test votes | - |

### Technology Stack

**Development:**

- Languages: Python, JavaScript, C#
- Frameworks: Flask, Express, Socket.io, Gunicorn
- Databases: Redis, PostgreSQL

**DevOps:**

- Containers: Docker, Docker Compose
- Orchestration: Kubernetes (Minikube), Terraform
- CI/CD: GitHub Actions
- Security: Snyk (SAST, SCA, Container, IaC)
- Monitoring: Prometheus, Grafana

---

## 📁 Project Structure

```bash
tactful-votingapp-cloud-infra/
├── vote/                          # Python Flask voting service
│   ├── app.py                     # Main application logic
│   ├── requirements.txt           # Python dependencies
│   ├── Dockerfile                 # Multi-stage build
│   ├── templates/index.html       # Voting UI
│   └── static/stylesheets/        # CSS styling
│
├── result/                        # Node.js result service
│   ├── server.js                  # Express + Socket.io server
│   ├── package.json               # Node dependencies
│   ├── Dockerfile                 # Multi-stage build
│   └── views/                     # Result dashboard UI
│
├── worker/                        # .NET worker service
│   ├── Program.cs                 # Vote processing logic
│   ├── Worker.csproj              # .NET project file
│   └── Dockerfile                 # Multi-stage build
│
├── seed-data/                     # Test data generator
│   ├── generate-votes.sh          # Shell script for votes
│   └── Dockerfile                 # Alpine with curl
│
├── terraform/                     # Infrastructure as Code
│   ├── main.tf                    # Terraform configuration
│   ├── cluster.tf                 # Minikube cluster setup
│   ├── seed.tf                    # Optional seed job
│   ├── variables.tf               # Input variables
│   └── outputs.tf                 # Output values
│
├── k8s/                           # Kubernetes manifests
│   ├── manifests/                 # Raw Kubernetes YAML
│   │   ├── 00-namespace.yaml     # Namespace with PSA
│   │   ├── 01-secrets.yaml       # DB credentials
│   │   ├── 02-configmap.yaml     # App configuration
│   │   ├── 03-postgres.yaml      # StatefulSet
│   │   ├── 04-redis.yaml         # Deployment
│   │   ├── 05-vote.yaml          # 2 replicas
│   │   ├── 06-result.yaml        # 2 replicas
│   │   ├── 07-worker.yaml        # 1 replica
│   │   ├── 08-network-policies.yaml  # DB isolation
│   │   ├── 09-ingress.yaml       # vote.local, result.local
│   │   └── 10-seed.yaml          # Job for test data
│   ├── helm/                      # Helm values
│   │   ├── postgresql-values-dev.yaml
│   │   ├── redis-values-dev.yaml
│   │   └── voting-app/           # Custom Helm chart
│   └── monitoring/                # Prometheus/Grafana configs
│
├── .github/workflows/             # CI/CD pipelines
│   ├── ci-cd.yml                  # Main build pipeline
│   ├── security-scanning.yml      # Snyk scans
│   └── docker-compose-test.yml    # Integration tests
│
├── healthchecks/                  # Health check scripts
│   ├── redis.sh                   # Redis health check
│   └── postgres.sh                # PostgreSQL health check
│
├── docker-compose.yml             # Local development setup
├── setup-sudoers.sh               # Passwordless sudo config
├── test-e2e.sh                    # End-to-end tests
└── snyk-full-scan.sh              # Security scanning
```

---

## 🔨 How to Build & Deploy

This section provides complete step-by-step build and deployment instructions for each phase.

---

### 📦 Phase 1: Docker Compose (Local Development)

**Description:** Build and run all services locally using Docker Compose for development and testing.

**Requirements:**

- Docker Engine 20.10+
- Docker Compose 2.0+
- 4GB+ RAM available
- Ports 8080, 8081, 5432, 6379 available

**Step-by-Step Build & Deploy:**

```bash
# Step 1: Navigate to project directory
cd /home/omar/Projects/tactful-votingapp-cloud-infra

# Step 2: Create .env file (optional, uses defaults if not provided)
cat > .env << EOF
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=postgres
REDIS_PASSWORD=
EOF

# Step 3: Build all Docker images
docker compose build
# This builds: vote, result, worker, seed-data
# Uses multi-stage builds for optimization

# Step 4: Start all services in detached mode
docker compose up -d

# Step 5: Verify all services are running
docker compose ps
# All services should show "Up" status
# Redis and PostgreSQL should show "(healthy)"

# Step 6: Test the application
# Vote interface
curl http://localhost:8080
# Or open in browser

# Result interface
curl http://localhost:8081
# Or open in browser

# Submit a test vote
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "vote=a"

# Step 7: (Optional) Generate test data
docker compose --profile seed up seed-data
# Generates 3000 votes: 2000 for Cats, 1000 for Dogs

# Step 8: View logs
docker compose logs -f
# Or specific service: docker compose logs -f vote

# Step 9: Cleanup when done
docker compose down -v
# Removes containers, networks, and volumes
```

**What Gets Built:**

- `vote` image (Python 3.11 + Flask + Gunicorn)
- `result` image (Node.js 18 + Express + Socket.io)
- `worker` image (.NET 8.0 + C# service)
- `seed-data` image (Alpine + curl)

**Expected Results:**

- Vote UI: <http://localhost:8080>
- Result UI: <http://localhost:8081>
- 5 running containers: vote, result, worker, redis, postgres
- Real-time vote updates visible in result dashboard

---

### ☸️ Phase 2: Kubernetes Deployment (Terraform)

**Description:** Deploy complete application to local Minikube cluster using Terraform automation.

**Requirements:**

- Minikube 1.30+
- kubectl 1.27+
- Terraform 1.0+
- Docker 20.10+
- 8GB+ RAM available
- 4+ CPU cores

**Step-by-Step Build & Deploy:**

```bash
# Step 1: One-time setup for passwordless deployment
sudo ./setup-sudoers.sh
# This configures sudoers for /etc/hosts updates
# Only needs to be run once

# Step 2: Navigate to terraform directory
cd terraform

# Step 3: Initialize Terraform
terraform init
# Downloads required providers (Minikube, Docker, Kubernetes, Null)

# Step 4: Validate configuration
terraform validate
# Ensures all HCL syntax is correct

# Step 5: Review deployment plan (optional)
terraform plan
# Shows what will be created

# Step 6: Deploy everything automatically
terraform apply -auto-approve
# This will:
# - Create Minikube cluster (voting-app-dev)
# - Build Docker images in Minikube's daemon
# - Deploy PostgreSQL via Helm
# - Deploy Redis via Helm
# - Deploy vote, result, worker services
# - Configure ingress (vote.local, result.local)
# - Update /etc/hosts automatically

# Step 7: Wait for all pods to be ready
kubectl get pods -n voting-app --watch
# Press Ctrl+C when all pods show Running

# Step 8: Verify deployment
kubectl get all -n voting-app
# Should show: deployments, pods, services

# Step 9: Test the application
curl http://vote.local
curl http://result.local
# Or open in browser

# Step 10: (Optional) Generate test data
kubectl apply -f ../k8s/manifests/10-seed.yaml
# Creates a Job that generates 3000 test votes

# Step 11: Monitor pods
kubectl logs -f deployment/vote -n voting-app
kubectl logs -f deployment/result -n voting-app
kubectl logs -f deployment/worker -n voting-app

# Step 12: Cleanup when done
terraform destroy -auto-approve
# Removes all resources including Minikube cluster
```

**What Gets Built:**

- Minikube cluster (profile: voting-app-dev)
- Docker images (built in Minikube's daemon):
  - `tactful-votingapp-cloud-infra-vote:latest`
  - `tactful-votingapp-cloud-infra-result:latest`
  - `tactful-votingapp-cloud-infra-worker:latest`
- Kubernetes resources:
  - Namespace: voting-app
  - PostgreSQL StatefulSet (via Helm)
  - Redis Deployment (via Helm)
  - Vote Deployment (2 replicas)
  - Result Deployment (2 replicas)
  - Worker Deployment (1 replica)
  - Services (ClusterIP and LoadBalancer)
  - Ingress (vote.local, result.local)

**Expected Results:**

- Vote UI: <http://vote.local>
- Result UI: <http://result.local>
- All pods running: `kubectl get pods -n voting-app`
- Services accessible via ingress

**Troubleshooting:**

```bash
# If pods are not ready
kubectl describe pod <pod-name> -n voting-app

# If ingress not working
kubectl get ingress -n voting-app
minikube addons enable ingress -p voting-app-dev

# If /etc/hosts not updated
cat /etc/hosts | grep local
# Should see: <MINIKUBE_IP> vote.local result.local
```

---

### 🔄 Phase 3: CI/CD Pipeline (GitHub Actions)

**Description:** Automated build, test, scan, and container registry push via GitHub Actions.

**Requirements:**

- GitHub account
- GitHub repository
- GitHub Container Registry enabled
- Snyk account (for security scanning)

**Step-by-Step Setup & Trigger:**

```bash
# Step 1: Configure GitHub Secrets
# Go to: Settings → Secrets and variables → Actions
# Add these secrets:
# - SNYK_TOKEN (from snyk.io)

# Step 2: Enable GitHub Container Registry
# Go to: Settings → Packages → Enable Container Registry

# Step 3: Make code changes
git checkout -b feature/my-changes
# Edit files as needed

# Step 4: Commit changes
git add .
git commit -m "feat: add new feature"

# Step 5: Push to trigger pipeline
git push origin feature/my-changes

# Step 6: Monitor pipeline in GitHub UI
# Go to: Actions tab in GitHub repository
# Watch the ci-cd.yml workflow

# Step 7: Review build results
# Pipeline will:
# - Build all 3 Docker images
# - Scan with Snyk for vulnerabilities
# - Run docker-compose integration tests
# - Tag images with commit SHA
# - Push to GitHub Container Registry (ghcr.io)

# Step 8: Create Pull Request
gh pr create --title "My Feature" --body "Description"

# Step 9: Merge when tests pass
gh pr merge --squash

# Step 10: Verify images in registry
# Go to: Packages tab in GitHub
# Should see: vote, result, worker packages
```

**What Gets Built:**

- Three Docker images tagged with commit SHA:
  - `ghcr.io/<username>/vote:<commit-sha>`
  - `ghcr.io/<username>/result:<commit-sha>`
  - `ghcr.io/<username>/worker:<commit-sha>`
- Images also tagged as `:latest`

**CI/CD Pipeline Jobs:**

1. **build-vote**
   - Builds vote service
   - Scans with Snyk
   - Pushes to GHCR

2. **build-result**
   - Builds result service
   - Scans with Snyk
   - Pushes to GHCR

3. **build-worker**
   - Builds worker service
   - Scans with Snyk
   - Pushes to GHCR

4. **docker-compose-test**
   - Runs integration tests
   - Validates all services work together

**Expected Results:**

- All CI/CD checks pass ✓
- Images available in GitHub Container Registry
- Security scan reports (no critical vulnerabilities)
- Docker Compose tests pass

---

### 📊 Phase 4: Monitoring Stack (Prometheus + Grafana)

**Description:** Deploy monitoring and observability stack to track application metrics and logs.

**Requirements:**

- Kubernetes cluster running (from Phase 2)
- Helm 3.12+
- kubectl access
- 4GB+ additional RAM

**Step-by-Step Build & Deploy:**

```bash
# Step 1: Ensure Kubernetes cluster is running
kubectl cluster-info
kubectl get nodes

# Step 2: Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Step 3: Create monitoring namespace
kubectl create namespace monitoring

# Step 4: Install Prometheus + Grafana stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --wait \
  --timeout 10m

# This installs:
# - Prometheus (metrics collection)
# - Grafana (visualization)
# - AlertManager (alerting)
# - Node Exporter (host metrics)
# - Kube State Metrics (K8s metrics)

# Step 5: Verify monitoring pods are running
kubectl get pods -n monitoring
# Wait for all pods to be Running

# Step 6: Get Grafana admin password
kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode
echo

# Step 7: Access Grafana dashboard
kubectl port-forward -n monitoring \
  svc/prometheus-grafana 3000:80

# Open browser: http://localhost:3000
# Username: admin
# Password: (from Step 6)

# Step 8: Access Prometheus UI
kubectl port-forward -n monitoring \
  svc/prometheus-kube-prometheus-prometheus 9090:9090

# Open browser: http://localhost:9090

# Step 9: Import voting-app dashboards
# In Grafana:
# - Go to Dashboards → Import
# - Use dashboard ID: 315 (Kubernetes cluster monitoring)
# - Use dashboard ID: 1860 (Node Exporter Full)

# Step 10: Create custom dashboard for voting app
# In Grafana:
# - Create new dashboard
# - Add panels to track:
#   - Vote count per second
#   - Result service response time
#   - Worker processing rate
#   - Redis queue length
#   - PostgreSQL connections

# Step 11: View metrics
# Query examples in Prometheus:
# - container_memory_usage_bytes{namespace="voting-app"}
# - rate(container_cpu_usage_seconds_total{namespace="voting-app"}[5m])

# Step 12: Cleanup monitoring stack
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring
```

**What Gets Deployed:**

- Prometheus (metrics database)
- Grafana (visualization)
- AlertManager (alerts)
- Node Exporter (node metrics)
- Kube State Metrics (K8s metrics)
- Service Monitors (metrics scraping)

**Expected Results:**

- Grafana UI: <http://localhost:3000>
- Prometheus UI: <http://localhost:9090>
- Real-time metrics from voting-app namespace
- Pre-built Kubernetes dashboards
- Alert rules configured

**Useful Queries:**

```promql
# CPU usage by pod
rate(container_cpu_usage_seconds_total{namespace="voting-app"}[5m])

# Memory usage by pod
container_memory_working_set_bytes{namespace="voting-app"}

# Pod restart count
kube_pod_container_status_restarts_total{namespace="voting-app"}
```

---

## 📖 Build Order Summary

Execute phases in this order:

1. **Phase 1** → Develop and test locally with Docker Compose
2. **Phase 2** → Deploy to Kubernetes for production-like environment
3. **Phase 3** → Set up CI/CD for automated deployments
4. **Phase 4** → Add monitoring for observability

Each phase builds on the previous one, creating a complete DevOps pipeline.

---

## 📐 Architecture

### Data Flow

```bash
User → Vote Service → Redis Queue → Worker → PostgreSQL → Result Service → User
```

**Detailed Flow:**

1. User submits vote via <http://vote.local>
2. Vote service stores vote in Redis queue (LPUSH)
3. Worker polls Redis (BLPOP) and processes vote
4. Worker inserts/updates vote in PostgreSQL (UPSERT by voter_id)
5. Result service queries PostgreSQL every 1 second
6. Result service pushes updates via WebSocket (Socket.io)
7. User sees real-time results

### Network Architecture

**Docker Compose:**

- Frontend Network: vote, result (exposed to host)
- Backend Network: worker, redis, postgres (internal only)

**Kubernetes:**

- Namespace: `voting-app`
- NetworkPolicies: Postgres/Redis isolated, only worker can access
- Ingress: vote.local (vote service), result.local (result service)

---

## 🔧 Quick Command Reference

### Phase 1: Docker Compose

```bash
# Deploy
docker compose up --build -d
docker compose ps

# Test
curl http://localhost:8080   # Vote
curl http://localhost:8081   # Result

# Seed 3000 test votes
docker compose --profile seed up seed-data

# Cleanup
docker compose down -v
```

### Phase 2: Kubernetes (Terraform)

```bash
# One-time setup
sudo ./setup-sudoers.sh

# Deploy everything
cd terraform
terraform init
terraform apply -auto-approve

# Test
kubectl get pods -n voting-app
curl http://vote.local
curl http://result.local

# Seed data
kubectl apply -f ../k8s/manifests/10-seed.yaml

# Cleanup
terraform destroy -auto-approve
```

### Phase 3: CI/CD

```bash
# Trigger pipeline
git push origin main

# Check status
gh run list --limit 5
gh run view --log
```

### Phase 4: Monitoring (Manual)

```bash
# Deploy monitoring stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace --wait

# Access dashboards
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# http://localhost:3000 (admin/prom-operator)
```

---

## 🚨 Problems Faced & Solutions

### Problem 1: Debug Mode Enabled in Production

**Issue:** Flask app running with `debug=True` exposes sensitive information

- **Severity:** Medium
- **File:** `vote/app.py`
- **Solution:** Changed to `debug=False`

```python
# Fixed in vote/app.py
if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80, debug=False)  # Was True
```

### Problem 2: .NET Worker Package Vulnerabilities

**Issue:** Npgsql 8.0.3 had SQL injection vulnerabilities (CVE-2024-32056)

- **Severity:** High
- **File:** `worker/Worker.csproj`
- **Solution:** Upgraded to Npgsql 8.0.5

```xml
<!-- Fixed in worker/Worker.csproj -->
<PackageReference Include="Npgsql" Version="8.0.5" />
```

### Problem 3: Result Service Dependency Vulnerabilities

**Issue:** Multiple npm package vulnerabilities

- express 4.19.2 → 4.21.1
- body-parser 1.20.2 → 1.20.3  
- ws 8.17.0 → 8.18.0
- **Solution:** Updated `package.json` and ran `npm update`

### Problem 4: Terraform Asking for Sudo Password

**Issue:** Terraform couldn't configure /etc/hosts without password

- **Impact:** Blocked automation, required manual intervention
- **Solution:** Created `setup-sudoers.sh` for one-time passwordless sudo setup

```bash
# One-time setup
sudo ./setup-sudoers.sh

# Creates /etc/sudoers.d/terraform-hosts with permissions for:
# - sudo sed -i '/vote\.local/d' /etc/hosts
# - sudo tee -a /etc/hosts
```

### Problem 5: Seed Job Running Automatically

**Issue:** Seed job was running during every `terraform apply`

- **Impact:** 3000 test votes added every time
- **Solution:** Made seed job optional with variable control

```hcl
# seed.tf
variable "run_seed" { default = false }
resource "null_resource" "run_seed" {
  count = var.run_seed ? 1 : 0
  # ...
}
```

### Problem 6: Kubernetes Pod Security Admission

**Issue:** Pods failing with "must not set securityContext.runAsUser to 0"

- **Solution:** Set `runAsNonRoot: true` and `runAsUser: 1000` in all manifests

```yaml
# Fixed in all k8s manifests
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  allowPrivilegeEscalation: false
```

### Problem 7: PostgreSQL StatefulSet Not Ready

**Issue:** PostgreSQL pod stuck in Pending state

- **Cause:** No storage class configured in Minikube
- **Solution:** Minikube automatically provisions hostPath PVs

```bash
# Verify PVC bound
kubectl get pvc -n voting-app
# Should show: Bound status
```

### Problem 8: Ingress Not Working

**Issue:** vote.local and result.local not accessible

- **Cause:** /etc/hosts not configured, ingress addon not enabled
- **Solution:**
  1. Enable ingress: `minikube addons enable ingress -p voting-app-dev`
  2. Configure /etc/hosts: Terraform now does this automatically

---

## 📚 Documentation Links

**For more detailed step-by-step guides, see:**

- [TEST-ALL-PHASES.md](TEST-ALL-PHASES.md) - Complete testing guide for all phases with detailed commands and validation steps

**Note:** This README provides complete build instructions for each phase. The TEST-ALL-PHASES.md file contains additional testing scenarios and troubleshooting steps.

---

## Made with ❤️ - Cloud-Native DevOps Project
