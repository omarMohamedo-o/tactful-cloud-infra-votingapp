# Local Minikube Deployment Guide

This project has been configured for **local-only deployment using Minikube**. All cloud provider dependencies have been removed.

## 🎯 Deployment Flow

```
Developer commits → GitHub Actions CI/CD → Build & Scan → Push to GHCR → Manual local deployment
```

### What GitHub Actions Does (Automated)

1. ✅ **Build Docker images** for vote, result, and worker services
2. ✅ **Run security scans** with Snyk (SAST, SCA, Container, IaC)
3. ✅ **Push images** to GitHub Container Registry (GHCR)
4. ✅ **Provide deployment instructions** in workflow summary

### What You Do (Manual)

1. 📥 **Pull images** from GHCR (optional - Minikube can pull automatically)
2. 🚀 **Deploy** to your local Minikube cluster
3. 🧪 **Run smoke tests** to verify deployment

---

## 🔧 Prerequisites

### Required

- **Minikube** (v1.30+)
- **kubectl** (v1.27+)
- **Helm** (v3.12+)
- **Docker** (for Minikube driver)

### Optional

- **Snyk CLI** (for local security scanning)

---

## 📦 Quick Start

### 1. Start Minikube

```bash
# Start Minikube with sufficient resources
minikube start --cpus=4 --memory=8192 --driver=docker

# Enable ingress addon
minikube addons enable ingress

# Verify cluster is running
minikube status
```

### 2. Deploy the Voting Application

#### Option A: Using Kubernetes Manifests

```bash
# Apply all manifests
kubectl apply -f k8s/manifests/

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=vote -n voting-app --timeout=300s
kubectl wait --for=condition=ready pod -l app=result -n voting-app --timeout=300s
kubectl wait --for=condition=ready pod -l app=worker -n voting-app --timeout=300s
```

#### Option B: Using Helm (Recommended)

```bash
# Install/upgrade using Helm
helm upgrade --install voting-app k8s/helm/voting-app \
  --namespace voting-app \
  --create-namespace \
  --wait \
  --timeout 5m

# Or with specific image tags from CI/CD
helm upgrade --install voting-app k8s/helm/voting-app \
  --namespace voting-app \
  --create-namespace \
  --set vote.image.tag=<commit-sha> \
  --set result.image.tag=<commit-sha> \
  --set worker.image.tag=<commit-sha> \
  --wait
```

### 3. Access the Application

#### Configure /etc/hosts

```bash
# Get Minikube IP
minikube ip

# Add to /etc/hosts (use sudo)
echo "$(minikube ip) vote.local result.local" | sudo tee -a /etc/hosts
```

#### Access URLs

- **Vote App**: <http://vote.local>
- **Result App**: <http://result.local>

---

## 🧪 Smoke Tests

After deployment, run these tests to verify everything works:

### Test Vote Service

```bash
# Health check
curl -s http://vote.local | grep 'Cats vs Dogs'

# Submit a vote
curl -X POST http://vote.local/ -d "vote=a" -H "Content-Type: application/x-www-form-urlencoded"
```

### Test Result Service

```bash
# Check results page loads
curl -s http://result.local | grep 'Result'
```

### Check Pods Status

```bash
# All pods should be Running
kubectl get pods -n voting-app

# Expected output:
# NAME                      READY   STATUS    RESTARTS   AGE
# postgres-0                1/1     Running   0          5m
# redis-0                   1/1     Running   0          5m
# result-xxxxxxxxxx-xxxxx   1/1     Running   0          5m
# vote-xxxxxxxxxx-xxxxx     1/1     Running   0          5m
# worker-xxxxxxxxxx-xxxxx   1/1     Running   0          5m
```

### Test Database

```bash
# Check vote count in PostgreSQL
kubectl exec -n voting-app postgres-0 -- \
  psql -U postgres -d postgres -c 'SELECT COUNT(*) FROM votes;'
```

### Test Redis

```bash
# Ping Redis
kubectl exec -n voting-app redis-0 -- redis-cli ping
# Should return: PONG
```

---

## 📊 Monitoring (Optional)

Deploy monitoring stack to your local Minikube:

```bash
# Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus + Grafana
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values k8s/monitoring/prometheus-values-dev.yaml \
  --wait

# Port-forward to access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Access Grafana at <http://localhost:3000> (default credentials: admin/prom-operator)

---

## 🔐 Security Scanning

### Automatic Scanning (GitHub Actions)

Every push triggers:

- **Snyk Code** - SAST analysis
- **Snyk Open Source** - SCA dependency scan
- **Snyk Container** - Docker image vulnerabilities
- **Snyk IaC** - Kubernetes manifest security

### Manual Local Scanning

```bash
# Run complete security scan
./snyk-full-scan.sh

# Or run individual scans
snyk code test vote/
snyk test --file=result/package.json --docker result:latest
snyk iac test k8s/manifests/
```

---

## 🚀 CI/CD Workflow

### Active Workflows

1. **CI/CD Pipeline** (`.github/workflows/ci-cd.yml`)
   - ✅ Builds and pushes images on push to main/develop
   - ✅ Runs security scans
   - ✅ Provides deployment instructions in workflow summary

2. **Security Scanning** (`.github/workflows/security-scanning.yml`)
   - ✅ Scheduled daily scans
   - ✅ Scan on PR to main

3. **Docker Compose Test** (`.github/workflows/docker-compose-test.yml`)
   - ✅ Tests with Docker Compose on PR

### Disabled Workflows (Cloud Only)

These workflows are **disabled** for local Minikube setup but can be re-enabled for cloud deployment:

1. **Deploy Monitoring** (`.github/workflows/deploy-monitoring.yml`)
   - Requires KUBECONFIG secret for cloud cluster
   - Use manual Helm commands instead (see Monitoring section)

2. **Terraform Infrastructure** (`.github/workflows/terraform.yml`)
   - Provisions cloud clusters (AKS/EKS/GKE)
   - Not needed for local Minikube

To re-enable for cloud deployment:

- Add KUBECONFIG secret to GitHub repository
- Uncomment push/pull_request triggers in workflow files
- Update terraform variables for your cloud provider

---

## 🐛 Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n voting-app

# Describe pod for details
kubectl describe pod <pod-name> -n voting-app

# Check logs
kubectl logs <pod-name> -n voting-app
```

### Image Pull Errors

```bash
# For GHCR images, authenticate Docker
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin

# Or pull images manually
docker pull ghcr.io/<your-org>/vote:latest
docker pull ghcr.io/<your-org>/result:latest
docker pull ghcr.io/<your-org>/worker:latest

# Load into Minikube
minikube image load ghcr.io/<your-org>/vote:latest
```

### Ingress Not Working

```bash
# Verify ingress addon is enabled
minikube addons list | grep ingress

# Enable if not active
minikube addons enable ingress

# Check ingress controller
kubectl get pods -n ingress-nginx

# Verify /etc/hosts entry
cat /etc/hosts | grep "vote.local"
```

### Database Connection Issues

```bash
# Check PostgreSQL is running
kubectl get pods -n voting-app -l app=postgres

# Check PostgreSQL logs
kubectl logs -n voting-app postgres-0

# Test connection from worker pod
kubectl exec -n voting-app <worker-pod> -- \
  env | grep DATABASE_URL
```

---

## 🔄 Update Deployment

### After CI/CD builds new images

```bash
# Get latest commit SHA from GitHub Actions
COMMIT_SHA=<sha-from-github>

# Update deployment with new images
helm upgrade voting-app k8s/helm/voting-app \
  --namespace voting-app \
  --set vote.image.tag=$COMMIT_SHA \
  --set result.image.tag=$COMMIT_SHA \
  --set worker.image.tag=$COMMIT_SHA \
  --reuse-values

# Or rollout restart
kubectl rollout restart deployment/vote -n voting-app
kubectl rollout restart deployment/result -n voting-app
kubectl rollout restart deployment/worker -n voting-app
```

---

## 🧹 Cleanup

### Uninstall Voting App

```bash
# Using Helm
helm uninstall voting-app -n voting-app

# Or delete manifests
kubectl delete -f k8s/manifests/

# Delete namespace
kubectl delete namespace voting-app
```

### Stop Minikube

```bash
# Stop cluster
minikube stop

# Delete cluster (removes all data)
minikube delete
```

---

## 📚 Additional Resources

- **Complete Testing Guide**: See `COMPLETE-TESTING-GUIDE.md` for step-by-step testing
- **Security Fixes**: See `SECURITY-FIXES.md` for vulnerability remediation
- **Docker Compose**: Use `docker-compose.yml` for quick local testing
- **Helm Charts**: See `k8s/helm/voting-app/` for Helm configuration

---

## ❓ FAQ

**Q: Why no automatic deployment from GitHub Actions?**  
A: Minikube runs locally on your machine. GitHub Actions runners cannot access your local cluster. Manual deployment ensures you control when and what gets deployed to your development environment.

**Q: Can I use a different image tag?**  
A: Yes! The CI/CD pipeline tags images with both commit SHA and `:latest`. Use either:

- `--set vote.image.tag=latest` (always pulls latest)
- `--set vote.image.tag=<commit-sha>` (specific version)

**Q: How do I enable cloud deployment?**  
A: Uncomment the disabled triggers in `deploy-monitoring.yml` and `terraform.yml`, add necessary secrets (KUBECONFIG, cloud credentials), and run the workflows manually first to test.

**Q: Where are the container images stored?**  
A: GitHub Container Registry (GHCR) at `ghcr.io/<your-org>/<service>:tag`. Images are public by default for public repos, or require authentication for private repos.

---

## 🎯 Summary

✅ **CI/CD**: Automated builds, tests, and security scans  
🚀 **Deployment**: Manual to local Minikube cluster  
🔐 **Security**: Snyk scanning integrated in pipeline  
📊 **Monitoring**: Optional Prometheus/Grafana stack  
🧪 **Testing**: Comprehensive test guide available  

**Happy coding! 🎉**
