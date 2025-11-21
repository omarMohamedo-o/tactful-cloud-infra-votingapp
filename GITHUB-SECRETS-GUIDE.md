# GitHub Secrets Setup Guide

**Required for:** CI/CD Pipeline (Phase 3)  
**Purpose:** Enable GitHub Actions to deploy to Kubernetes

---

## Required Secrets

### 1. GITHUB_TOKEN ✅

- **Status:** Automatic (No action needed)
- **Purpose:** Push Docker images to GitHub Container Registry
- **Automatically provided by GitHub Actions**

### 2. KUBECONFIG ⚠️

- **Status:** Manual setup required (for cloud deployments only)
- **Purpose:** Deploy to Kubernetes cluster
- **Used by:**
  - `.github/workflows/ci-cd.yml` (deployment job)
  - `.github/workflows/deploy-monitoring.yml` (all jobs)

---

## Quick Start

### Option 1: Automated Setup (Recommended for Cloud)

```bash
# Run the automated setup script
./setup-github-secrets.sh
```

This script will:

- ✅ Detect your cluster type (Minikube/Cloud)
- ✅ Create service account in Kubernetes
- ✅ Generate kubeconfig with limited permissions
- ✅ Add secret to GitHub automatically
- ✅ Verify setup

### Option 2: Manual Setup

Follow the steps below based on your setup.

---

## For Local Minikube (Current Setup)

### ⚠️ Important Note

**Minikube clusters are NOT accessible from GitHub Actions** because they run locally on your machine.

### What Works Without KUBECONFIG

✅ Automated builds on push/PR  
✅ Security scanning (Trivy + Snyk)  
✅ Docker image builds  
✅ Push to GitHub Container Registry  
✅ Running tests  

### What Requires Manual Action

⏭️ Kubernetes deployment (use `workflow_dispatch` manual trigger)  
⏭️ Monitoring stack deployment (manual)

### Recommendation for Minikube

**No KUBECONFIG secret needed!** Your workflows are already configured for manual deployment.

Just deploy locally:

```bash
# Deploy to your local Minikube
kubectl apply -f k8s/manifests/
```

---

## For Cloud Kubernetes (AKS, EKS, GKE)

### Step 1: Create Service Account

```bash
# Create namespace if not exists
kubectl create namespace voting-app

# Create service account with limited permissions
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: github-actions
  namespace: voting-app
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: github-actions-deployer
  namespace: voting-app
rules:
  - apiGroups: ["", "apps", "batch", "extensions", "networking.k8s.io"]
    resources: ["*"]
    verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: github-actions-deployer-binding
  namespace: voting-app
subjects:
  - kind: ServiceAccount
    name: github-actions
    namespace: voting-app
roleRef:
  kind: Role
  name: github-actions-deployer
  apiGroup: rbac.authorization.k8s.io
EOF
```

### Step 2: Get Cluster Information

```bash
# Get cluster server
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'

# Get cluster name
kubectl config view --minify -o jsonpath='{.clusters[0].name}'
```

### Step 3: Create Token (Kubernetes 1.24+)

```bash
# Create long-lived token (1 year)
kubectl create token github-actions -n voting-app --duration=8760h > /tmp/sa-token.txt

# Get certificate authority
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 --decode > /tmp/ca.crt
```

### Step 4: Create Kubeconfig File

Create a file `/tmp/kubeconfig-github.yaml` with this content (replace placeholders):

```yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: <BASE64_ENCODED_CA_CERT>
    server: <CLUSTER_SERVER_URL>
  name: <CLUSTER_NAME>
contexts:
- context:
    cluster: <CLUSTER_NAME>
    namespace: voting-app
    user: github-actions
  name: github-actions-context
current-context: github-actions-context
users:
- name: github-actions
  user:
    token: <SERVICE_ACCOUNT_TOKEN>
```

Replace:

- `<BASE64_ENCODED_CA_CERT>`: Content of ca.crt (base64 encoded)
- `<CLUSTER_SERVER_URL>`: Your cluster server URL
- `<CLUSTER_NAME>`: Your cluster name
- `<SERVICE_ACCOUNT_TOKEN>`: Content of sa-token.txt

### Step 5: Add Secret to GitHub

#### Method A: Using GitHub CLI (Recommended)

```bash
# Base64 encode the kubeconfig
cat /tmp/kubeconfig-github.yaml | base64 -w 0 | gh secret set KUBECONFIG
```

#### Method B: Via GitHub Web UI

1. Base64 encode the kubeconfig:

   ```bash
   cat /tmp/kubeconfig-github.yaml | base64 -w 0
   ```

2. Copy the output

3. Go to: `https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions`

4. Click **"New repository secret"**

5. Name: `KUBECONFIG`

6. Value: Paste the base64 encoded string

7. Click **"Add secret"**

### Step 6: Verify Setup

```bash
# List secrets (names only, values are hidden)
gh secret list

# Should show:
# KUBECONFIG  Updated YYYY-MM-DD
```

---

## Cloud-Specific Instructions

### Azure AKS

```bash
# Login to Azure
az login

# Get AKS credentials
az aks get-credentials \
  --resource-group <RESOURCE_GROUP> \
  --name <CLUSTER_NAME>

# Verify connection
kubectl get nodes

# Then follow steps above to create service account
```

### AWS EKS

```bash
# Configure AWS CLI
aws configure

# Get EKS credentials
aws eks update-kubeconfig \
  --region <REGION> \
  --name <CLUSTER_NAME>

# Verify connection
kubectl get nodes

# Then follow steps above to create service account
```

### Google GKE

```bash
# Login to GCloud
gcloud auth login

# Get GKE credentials
gcloud container clusters get-credentials \
  <CLUSTER_NAME> \
  --zone <ZONE> \
  --project <PROJECT_ID>

# Verify connection
kubectl get nodes

# Then follow steps above to create service account
```

---

## Verification

### Check Secrets in GitHub

```bash
# Via CLI
gh secret list

# Via Web UI
# Visit: https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions
```

### Test Deployment Workflow

```bash
# Trigger deployment manually
gh workflow run ci-cd.yml

# Check workflow status
gh run list --workflow=ci-cd.yml

# View logs
gh run view --log
```

---

## Security Best Practices

### ✅ DO

- Use service accounts with minimal required permissions
- Use namespace-scoped roles (not cluster-admin)
- Rotate tokens periodically (every 3-6 months)
- Use separate service accounts for dev/staging/prod
- Monitor service account usage via audit logs

### ❌ DON'T

- Share your personal kubeconfig
- Use cluster-admin permissions
- Store unencrypted kubeconfig in repos
- Use tokens without expiration (on supported versions)
- Grant write access to production without approval

---

## Troubleshooting

### Secret Not Working

```bash
# Verify secret exists
gh secret list | grep KUBECONFIG

# Check workflow logs
gh run view --log

# Common issues:
# 1. Base64 encoding incorrect (use -w 0 flag)
# 2. Service account lacks permissions
# 3. Token expired (Kubernetes 1.24+)
# 4. Cluster unreachable from GitHub runners
```

### Test Kubeconfig Locally

```bash
# Decode secret
echo "<BASE64_KUBECONFIG>" | base64 -d > /tmp/test-kubeconfig.yaml

# Test connection
KUBECONFIG=/tmp/test-kubeconfig.yaml kubectl get nodes

# If it works locally, should work in GitHub Actions
```

### Update Existing Secret

```bash
# Update via CLI
cat /tmp/new-kubeconfig.yaml | base64 -w 0 | gh secret set KUBECONFIG

# Or delete and recreate via web UI
```

---

## Current Project Status

### Your Setup: Minikube (Local)

- ✅ Workflows configured for manual deployment
- ✅ No KUBECONFIG secret needed
- ✅ All automated features working (build, test, scan)
- ⏭️ Deployment: Manual from local machine

### To Enable Automated Deployment

1. **Option A:** Keep Minikube, deploy manually (current setup) ✅
2. **Option B:** Use cloud Kubernetes (AKS, EKS, GKE) and follow guide above

---

## Summary

| Secret | Required | Auto-Generated | Purpose |
|--------|----------|----------------|---------|
| GITHUB_TOKEN | ✅ Yes | ✅ Yes | Push images to GHCR |
| KUBECONFIG | ⚠️ Cloud only | ❌ No | Deploy to Kubernetes |

### For Your Current Setup (Minikube)

- **No secrets needed to be added manually**
- **GITHUB_TOKEN:** Auto-provided ✅
- **KUBECONFIG:** Not needed (local cluster) ✅

### For Cloud Deployment

- Follow the guide above to add KUBECONFIG secret
- Run `./setup-github-secrets.sh` for automated setup

---

## Next Steps

### Current Setup (Minikube)

1. ✅ Push code to GitHub
2. ✅ Watch automated builds/tests
3. ⏭️ Deploy manually to local Minikube
4. ✅ Use manual workflow triggers when needed

### Cloud Setup

1. Create cloud Kubernetes cluster
2. Run `./setup-github-secrets.sh`
3. Push code to GitHub
4. Automated deployment will work!

---

**Quick Commands:**

```bash
# Check if secrets are needed
kubectl cluster-info | grep -i "minikube\|local" && echo "Local: No secrets needed" || echo "Cloud: Add KUBECONFIG"

# List current secrets
gh secret list

# Add secret (automated)
./setup-github-secrets.sh

# Add secret (manual)
cat kubeconfig.yaml | base64 -w 0 | gh secret set KUBECONFIG

# Test workflows
gh workflow run ci-cd.yml
gh run list --limit 5
```
