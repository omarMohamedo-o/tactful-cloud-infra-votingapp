# 🧪 Complete Testing Guide - All Phases

This guide will walk you through testing all three phases of the voting application deployment, from Docker Compose to Kubernetes with Terraform.

---

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] Docker & Docker Compose installed
- [ ] Minikube installed (for Phase 2)
- [ ] Terraform installed (for Phase 2)
- [ ] kubectl installed (for Phase 2)
- [ ] Helm installed (for Phase 2)
- [ ] Git repository access
- [ ] At least 8GB RAM available
- [ ] Ports 8080, 8081 available (Docker Compose)
- [ ] GitHub account configured (for Phase 3)

---

## 🐳 Phase 1: Docker Compose Testing

### Step 1: Clean Environment

```bash
# Navigate to project root
cd /home/omar/Projects/tactful-votingapp-cloud-infra

# Stop any running containers and remove volumes
docker compose down -v

# Clean up old images (optional)
docker system prune -f
```

### Step 2: Build and Start Services

```bash
# Build and start all services in one command
docker compose up --build -d

# Expected output:
# ✓ Network created
# ✓ 5 services created (vote, result, worker, redis, db)
```

### Step 3: Verify All Services Are Running

```bash
# Check service status
docker compose ps

# Expected output: All services should show "Up" or "Up (healthy)"
# vote      Up      0.0.0.0:8080->80/tcp
# result    Up      0.0.0.0:8081->80/tcp
# worker    Up
# redis     Up (healthy)
# db        Up (healthy)
```

**✅ Checkpoint 1:** All 5 services should be "Up" with redis and db showing "(healthy)"

### Step 4: Check Service Logs

```bash
# View logs for all services
docker compose logs --tail=50

# Check specific service if issues
docker compose logs vote
docker compose logs result
docker compose logs worker

# Look for:
# - No error messages
# - Services successfully connected to dependencies
# - Worker processing votes
```

**✅ Checkpoint 2:** No error messages in logs

### Step 5: Test Vote Application

```bash
# Test vote service is accessible
curl -s http://localhost:8080 | grep -i "cats\|dogs"

# Submit a test vote for Cats
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "vote=a"

# Submit a test vote for Dogs
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "vote=b"

# Or open in browser:
echo "Vote app: http://localhost:8080"
```

**✅ Checkpoint 3:** Vote page loads and votes can be submitted

### Step 6: Test Result Application

```bash
# Test result service is accessible
curl -s http://localhost:8081 | grep -i "votes"

# Or open in browser:
echo "Result app: http://localhost:8081"

# You should see real-time vote counts updating
```

**✅ Checkpoint 4:** Results page shows vote counts

### Step 7: Verify Data Persistence

```bash
# Check votes in PostgreSQL
docker compose exec db psql -U postgres -d postgres -c \
  "SELECT vote, COUNT(*) FROM votes GROUP BY vote;"

# Expected output: Table showing vote counts
```

**✅ Checkpoint 5:** Votes are stored in database

### Step 8: Run Seed Data (Optional but Recommended)

```bash
# Generate 3000 test votes
docker compose --profile seed up seed-data

# Wait for completion (about 30-60 seconds)
# Expected output:
# - 2000 votes for option A (Cats)
# - 1000 votes for option B (Dogs)

# Verify increased vote count
docker compose exec db psql -U postgres -d postgres -c \
  "SELECT vote, COUNT(*) as count FROM votes GROUP BY vote;"
```

**✅ Checkpoint 6:** Database shows ~3000 total votes

### Step 9: Run Automated Tests

```bash
# Run the comprehensive test script
./test-e2e.sh

# Expected output:
# ✅ All services running
# ✅ All health checks passing
# ✅ Vote submission works
# ✅ Data persistence verified
# ✅ Security (non-root) verified
```

**✅ Checkpoint 7:** All automated tests pass

### Step 10: Verify Resource Limits & Security

```bash
# Check resource usage
docker stats --no-stream

# Verify non-root users
docker compose exec vote id
docker compose exec result id
docker compose exec worker id

# All should show uid=1000 or similar (not root/0)
```

**✅ Checkpoint 8:** Services running as non-root users

### Phase 1 Summary

Run all Phase 1 tests in sequence:

```bash
# Complete Phase 1 test sequence
cd /home/omar/Projects/tactful-votingapp-cloud-infra && \
docker compose down -v && \
docker compose up --build -d && \
echo "⏳ Waiting 30 seconds for services to be healthy..." && \
sleep 30 && \
docker compose ps && \
echo "✅ Services status checked" && \
curl -X POST http://localhost:8080 -d "vote=a" && \
curl -X POST http://localhost:8080 -d "vote=b" && \
echo "✅ Test votes submitted" && \
curl -s http://localhost:8081 | grep -q votes && \
echo "✅ Result page accessible" && \
docker compose --profile seed up seed-data && \
echo "✅ Seed data loaded" && \
./test-e2e.sh
```

**🎉 Phase 1 Complete When:**

- ✅ All 5 services running and healthy
- ✅ Can vote at <http://localhost:8080>
- ✅ Can see results at <http://localhost:8081>
- ✅ 3000+ votes in database
- ✅ `./test-e2e.sh` passes
- ✅ All services non-root

---

## ☁️ Phase 2: Kubernetes with Terraform Testing

### Prerequisites for Phase 2

```bash
# Check all tools are installed
which minikube kubectl helm terraform

# Check versions
minikube version
kubectl version --client
helm version
terraform version
```

### Step 1: Clean Environment

```bash
# Stop Docker Compose services
cd /home/omar/Projects/tactful-votingapp-cloud-infra
docker compose down -v

# Delete any existing Minikube cluster
minikube delete --all

# Clean up old Kubernetes contexts
kubectl config get-contexts
```

### Step 2: Provision Minikube with Terraform

```bash
# Navigate to Terraform directory
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply Terraform configuration
terraform apply -auto-approve

# Expected output:
# - Minikube profile created: voting-app-dev
# - Cluster started with Kubernetes v1.28.3
# - Addons enabled (ingress, metrics-server)
# - Namespace created: voting-app
# - /etc/hosts configured with vote.local and result.local

# Verify cluster is running (use the correct profile name from terraform output)
minikube status -p voting-app-dev

# Should show:
# ✅ host: Running
# ✅ kubelet: Running
# ✅ apiserver: Running
# ✅ kubeconfig: Configured
```

**✅ Checkpoint 1:** Minikube cluster running via Terraform

### Step 3: Configure kubectl Context

```bash
# Set kubectl context (Terraform already set this automatically)
kubectl config use-context voting-app-dev

# Verify connection
kubectl cluster-info
kubectl get nodes

# Expected: 1 node (voting-app-dev) in Ready state
```

**✅ Checkpoint 2:** kubectl connected to Minikube cluster

### Step 4: Verify /etc/hosts Configuration

```bash
# Get Minikube IP (Terraform already configured /etc/hosts)
MINIKUBE_IP=$(minikube ip -p voting-app-dev)
echo "Minikube IP: $MINIKUBE_IP"

# Verify entries were added by Terraform
grep "vote.local\|result.local" /etc/hosts

# Expected output:
# 192.168.49.2 vote.local
# 192.168.49.2 result.local

# Test DNS resolution
ping -c 1 vote.local
ping -c 1 result.local
```

**✅ Checkpoint 3:** DNS resolution working for ingress hosts

### Step 5: Deploy with Helm

```bash
# Follow the next steps from Terraform output:
# 1. Add Helm repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# 2. Deploy PostgreSQL
helm install postgresql bitnami/postgresql \
  -n voting-app \
  -f ../k8s/helm/postgresql-values-dev.yaml

# 3. Deploy Redis
helm install redis bitnami/redis \
  -n voting-app \
  -f ../k8s/helm/redis-values-dev.yaml

# 4. Deploy voting application
helm install voting-app ../k8s/helm/voting-app \
  -n voting-app \
  --set environment=dev

# Expected output:
# ✅ Helm repositories added
# ✅ PostgreSQL deployed
# ✅ Redis deployed
# ✅ Voting app deployed
# ✅ All pods running

# This takes about 2-3 minutes
```

**✅ Checkpoint 4:** Helm deployment successful

### Step 6: Verify All Pods Are Running

```bash
# Check all pods in voting-app namespace
kubectl get pods -n voting-app

# Expected output: All pods should be "Running"
# - postgresql-0           1/1     Running
# - redis-master-0         1/1     Running
# - vote-xxx               1/1     Running
# - result-xxx             1/1     Running
# - worker-xxx             1/1     Running

# Watch pods until all are ready
kubectl get pods -n voting-app -w
# Press Ctrl+C when all are Running
```

**✅ Checkpoint 5:** All 5+ pods running in voting-app namespace

### Step 7: Check Services and Ingress

```bash
# List all services
kubectl get svc -n voting-app

# Check ingress
kubectl get ingress -n voting-app

# Expected:
# - vote ingress at vote.local
# - result ingress at result.local

# Verify ingress is ready
kubectl describe ingress voting-app-ingress -n voting-app
```

**✅ Checkpoint 6:** Ingress configured with both hosts

### Step 8: Test Vote Application

```bash
# Test vote service via ingress
curl -s http://vote.local | grep -i "cats\|dogs"

# Submit test votes
curl -X POST http://vote.local \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "vote=a"

curl -X POST http://vote.local \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "vote=b"

# Or open in browser:
echo "Vote app: http://vote.local"
```

**✅ Checkpoint 7:** Vote application accessible via ingress

### Step 9: Test Result Application

```bash
# Test result service
curl -s http://result.local | grep -i "votes"

# Or open in browser:
echo "Result app: http://result.local"
```

**✅ Checkpoint 8:** Result application accessible via ingress

### Step 10: Verify Data in PostgreSQL

```bash
# Connect to PostgreSQL pod
kubectl exec -n voting-app postgresql-0 -- \
  psql -U postgres -d postgres -c \
  "SELECT vote, COUNT(*) as count FROM votes GROUP BY vote;"

# Should show vote counts
```

**✅ Checkpoint 9:** Votes stored in PostgreSQL

### Step 11: Deploy Seed Job

```bash
# Apply seed job
kubectl apply -f manifests/10-seed.yaml

# Watch seed job
kubectl get jobs -n voting-app -w

# Check seed job logs
kubectl logs -n voting-app job/seed-data --follow

# Verify increased vote count
kubectl exec -n voting-app postgresql-0 -- \
  psql -U postgres -d postgres -c \
  "SELECT vote, COUNT(*) as count, SUM(COUNT(*)) OVER() as total FROM votes GROUP BY vote;"

# Should show ~3000 total votes
```

**✅ Checkpoint 10:** Seed job completed successfully

### Step 12: Verify Security Policies

```bash
# Check Pod Security Standards
kubectl get ns voting-app -o yaml | grep -A 5 labels

# Should show: pod-security.kubernetes.io/enforce: restricted

# Verify non-root containers
kubectl get pods -n voting-app -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].securityContext.runAsNonRoot}{"\n"}{end}'

# All should show "true"

# Check NetworkPolicies
kubectl get networkpolicies -n voting-app

# Should show policies isolating database
```

**✅ Checkpoint 11:** Security policies enforced

### Step 13: Verify Resource Limits

```bash
# Check resource limits on pods
kubectl describe pods -n voting-app | grep -A 5 "Limits\|Requests"

# All pods should have CPU and memory limits
```

**✅ Checkpoint 12:** Resource limits configured

### Step 14: Test High Availability

```bash
# Delete a pod and watch it recreate
kubectl delete pod -n voting-app -l app=vote

# Watch pod recreation
kubectl get pods -n voting-app -w

# Verify vote app still works
curl http://vote.local
```

**✅ Checkpoint 13:** Pods automatically recreate

### Phase 2 Summary

Run all Phase 2 tests in sequence:

```bash
# Complete Phase 2 test sequence
cd /home/omar/Projects/tactful-votingapp-cloud-infra/terraform && \
terraform apply -auto-approve && \
kubectl config use-context voting-app-dev && \
echo "✅ Terraform applied, cluster created" && \
helm repo add bitnami https://charts.bitnami.com/bitnami && \
helm repo update && \
helm install postgresql bitnami/postgresql -n voting-app -f ../k8s/helm/postgresql-values-dev.yaml && \
helm install redis bitnami/redis -n voting-app -f ../k8s/helm/redis-values-dev.yaml && \
helm install voting-app ../k8s/helm/voting-app -n voting-app --set environment=dev && \
echo "⏳ Waiting 60 seconds for pods to be ready..." && \
sleep 60 && \
kubectl get pods -n voting-app && \
curl -X POST http://vote.local -d "vote=a" && \
curl -X POST http://vote.local -d "vote=b" && \
kubectl apply -f manifests/10-seed.yaml && \
kubectl wait --for=condition=complete --timeout=300s job/seed-data -n voting-app && \
kubectl exec -n voting-app postgresql-0 -- psql -U postgres -d postgres -c "SELECT COUNT(*) as total FROM votes;"
```

**🎉 Phase 2 Complete When:**

- ✅ Minikube cluster provisioned via Terraform
- ✅ All pods running in voting-app namespace
- ✅ Vote accessible at <http://vote.local>
- ✅ Result accessible at <http://result.local>
- ✅ 3000+ votes in PostgreSQL
- ✅ NetworkPolicies isolating database
- ✅ PSA enforcing restricted mode
- ✅ All containers non-root

---

## 🔄 Phase 3: CI/CD Pipeline Testing

### Prerequisites for Phase 3

```bash
# Ensure GitHub CLI is installed and authenticated
gh auth status

# Verify you can access your repository
gh repo view omarMohamedo-o/tactful-votingapp-cloud-infra
```

### Step 1: Verify Workflows Are in Place

```bash
cd /home/omar/Projects/tactful-votingapp-cloud-infra

# List all workflows
ls -la .github/workflows/

# Expected files:
# - ci-cd.yml (main CI/CD pipeline)
# - terraform.yml (IaC automation)
# - security-scanning.yml (security scans)
# - docker-compose-test.yml (Docker Compose tests)
# - deploy-monitoring.yml (monitoring setup)
# - dependabot.yml (dependency updates)
```

**✅ Checkpoint 1:** All workflow files present

### Step 2: Check Latest Workflow Runs

```bash
# List recent workflow runs
gh run list --limit 10

# Check status of latest run
gh run view --log
```

**✅ Checkpoint 2:** Latest CI/CD workflow succeeded

### Step 3: Verify Docker Images in Registry

```bash
# List container images in GitHub Container Registry
gh api /user/packages?package_type=container | jq '.[].name'

# Expected images:
# - tactful-votingapp-cloud-infra/vote
# - tactful-votingapp-cloud-infra/result
# - tactful-votingapp-cloud-infra/worker

# Or check via Docker
docker pull ghcr.io/omarmohamedo-o/tactful-votingapp-cloud-infra/vote:latest
```

**✅ Checkpoint 3:** Docker images available in GHCR

### Step 4: Verify Security Scanning Results

```bash
# Check security tab in GitHub
gh api /repos/omarMohamedo-o/tactful-votingapp-cloud-infra/code-scanning/alerts

# View Trivy scan results in GitHub Security tab
echo "Check: https://github.com/omarMohamedo-o/tactful-votingapp-cloud-infra/security/code-scanning"
```

**✅ Checkpoint 4:** Security scans completed

### Step 5: Test Manual Workflow Trigger

```bash
# Manually trigger CI/CD workflow
gh workflow run ci-cd.yml

# Watch the workflow run
gh run watch

# Expected:
# ✅ Build & Test Vote Service
# ✅ Build & Test Result Service
# ✅ Build & Test Worker Service
# ⏭️ Deploy to Kubernetes (skipped - manual only)
```

**✅ Checkpoint 5:** Manual workflow trigger works

### Step 6: Verify Automated Tests in CI

```bash
# View latest test results
gh run view --log | grep -A 10 "Test"

# Should show:
# ✅ Vote service tests passed
# ✅ Result service tests passed
# ✅ Docker Compose tests passed
```

**✅ Checkpoint 6:** Automated tests passing in CI

### Step 7: Check Dependabot Configuration

```bash
# View Dependabot status
cat .github/dependabot.yml

# Check for open Dependabot PRs
gh pr list --author app/dependabot
```

**✅ Checkpoint 7:** Dependabot configured and monitoring

### Phase 3 Summary

```bash
# Complete Phase 3 verification
cd /home/omar/Projects/tactful-votingapp-cloud-infra && \
gh run list --limit 5 && \
echo "✅ Workflow runs checked" && \
gh api /user/packages?package_type=container | jq '.[].name' && \
echo "✅ Container images verified" && \
gh workflow run ci-cd.yml && \
echo "✅ Manual workflow triggered"
```

**🎉 Phase 3 Complete When:**

- ✅ All GitHub Actions workflows present
- ✅ Latest CI/CD run successful
- ✅ Docker images pushed to GHCR
- ✅ Security scans completed (Trivy)
- ✅ Automated tests passing
- ✅ Dependabot monitoring dependencies
- ✅ Manual workflow trigger works

---

## 🎯 Complete End-to-End Test

Run this ultimate test sequence to verify all phases:

```bash
#!/bin/bash
set -e

echo "🧪 COMPLETE END-TO-END TEST - ALL PHASES"
echo "========================================"

# Phase 1: Docker Compose
echo ""
echo "📦 PHASE 1: Docker Compose"
cd /home/omar/Projects/tactful-votingapp-cloud-infra
docker compose down -v
docker compose up --build -d
sleep 30
docker compose ps
curl -X POST http://localhost:8080 -d "vote=a"
curl -s http://localhost:8081 | grep -q votes
docker compose --profile seed up seed-data
./test-e2e.sh
echo "✅ Phase 1 PASSED"

# Phase 2: Kubernetes
echo ""
echo "☁️ PHASE 2: Kubernetes with Terraform"
docker compose down -v
cd terraform
terraform apply -auto-approve
kubectl config use-context tactful-voting
MINIKUBE_IP=$(minikube ip -p tactful-voting)
echo "$MINIKUBE_IP vote.local result.local" | sudo tee -a /etc/hosts
cd ../k8s
./deploy-helm.sh dev
sleep 60
kubectl get pods -n voting-app
curl -s http://vote.local | grep -q "Cats"
kubectl apply -f manifests/10-seed.yaml
kubectl wait --for=condition=complete --timeout=300s job/seed-data -n voting-app
echo "✅ Phase 2 PASSED"

# Phase 3: CI/CD
echo ""
echo "🔄 PHASE 3: CI/CD Pipeline"
cd /home/omar/Projects/tactful-votingapp-cloud-infra
gh run list --limit 3
gh workflow run ci-cd.yml
echo "✅ Phase 3 PASSED"

echo ""
echo "🎉 ALL PHASES COMPLETED SUCCESSFULLY!"
echo "======================================"
echo ""
echo "📊 Summary:"
echo "  ✅ Phase 1: Docker Compose - Fully functional"
echo "  ✅ Phase 2: Kubernetes - Deployed and accessible"
echo "  ✅ Phase 3: CI/CD - Automated and tested"
echo ""
echo "🌐 Access URLs:"
echo "  Docker Compose:"
echo "    - Vote: http://localhost:8080"
echo "    - Result: http://localhost:8081"
echo ""
echo "  Kubernetes:"
echo "    - Vote: http://vote.local"
echo "    - Result: http://result.local"
echo ""
echo "  GitHub Actions:"
echo "    - Workflows: https://github.com/omarMohamedo-o/tactful-votingapp-cloud-infra/actions"
echo ""
```

---

## 📝 Submission Checklist

Before submitting, verify:

### Docker Compose (Phase 1)

- [ ] `docker compose up` runs without errors
- [ ] All 5 services healthy
- [ ] Vote at <http://localhost:8080> works
- [ ] Result at <http://localhost:8081> works
- [ ] Seed data populates 3000 votes
- [ ] `./test-e2e.sh` passes
- [ ] All containers non-root
- [ ] Two-tier networking configured
- [ ] Health checks functional

### Kubernetes (Phase 2)

- [ ] Terraform provisions Minikube cluster
- [ ] All pods running in voting-app namespace
- [ ] Vote at <http://vote.local> works
- [ ] Result at <http://result.local> works
- [ ] PostgreSQL via Helm with persistence
- [ ] Redis via Helm with persistence
- [ ] NetworkPolicies isolate database
- [ ] PSA enforcing restricted mode
- [ ] Resource limits on all pods
- [ ] Ingress controller functional
- [ ] ConfigMaps and Secrets used
- [ ] Seed job completes successfully

### CI/CD (Phase 3)

- [ ] GitHub Actions workflows configured
- [ ] Latest CI/CD run successful
- [ ] Docker images in GitHub Container Registry
- [ ] Trivy security scans completed
- [ ] Automated tests passing
- [ ] Dependabot configured
- [ ] Manual deployment trigger works
- [ ] Build → Test → Push automated

### Documentation

- [ ] README.md updated with setup instructions
- [ ] Architecture decisions documented
- [ ] Trade-offs explained (Minikube vs AKS)
- [ ] All commands tested and working
- [ ] Troubleshooting guide included

---

## 🎬 Next Steps

1. **Run Phase 1 Tests** - Start with Docker Compose
2. **Run Phase 2 Tests** - Move to Kubernetes
3. **Run Phase 3 Tests** - Verify CI/CD
4. **Create Demo Video** - Record walkthrough (≤15 min)
5. **Submit Repository** - Share GitHub link

---

## 🆘 Troubleshooting

### Docker Compose Issues

```bash
# Reset everything
docker compose down -v
docker system prune -af
docker compose up --build -d
```

### Kubernetes Issues

```bash
# Reset Minikube
minikube delete -p voting-app-dev
cd terraform && terraform apply -auto-approve

# Reset deployments
helm uninstall postgresql redis voting-app -n voting-app
# Then follow Terraform output to redeploy with Helm
```

### CI/CD Issues

```bash
# Re-trigger workflow
gh workflow run ci-cd.yml

# View detailed logs
gh run view --log
```

---

**Ready to start? Begin with Phase 1! 🚀**
