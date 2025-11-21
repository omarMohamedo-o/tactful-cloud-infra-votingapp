# Phase 2 Testing Commands - Helm (Recommended Approach)

## 🎯 Quick Command to Run Phase 2 with Helm

This is the **recommended approach** for deploying the voting application to Kubernetes.

### Single Command Deployment

```bash
# Clean, deploy with Helm, and test Kubernetes setup
kubectl delete namespace voting-app --ignore-not-found=true && \
kubectl wait --for=delete namespace/voting-app --timeout=60s 2>/dev/null || true && \
minikube status || minikube start --cpus=4 --memory=8192 --driver=docker && \
minikube addons enable ingress && \
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s && \
helm install voting-app k8s/helm/voting-app --namespace voting-app --create-namespace --wait && \
echo "$(minikube ip) vote.local result.local" | sudo tee -a /etc/hosts && \
kubectl get pods -n voting-app && \
echo "✅ Phase 2 Helm deployment complete! Access at http://vote.local and http://result.local"
```

---

## 📋 Step-by-Step Helm Deployment

### 1️⃣ Prerequisites Check

```bash
# Verify Helm is installed
helm version

# Expected output: version.BuildInfo{Version:"v3.12+"}
```

### 2️⃣ Clean Up Existing Deployment

```bash
# Remove any existing deployment
helm uninstall voting-app -n voting-app 2>/dev/null || true
kubectl delete namespace voting-app --ignore-not-found=true
```

### 3️⃣ Start Minikube Cluster

```bash
# Start Minikube with recommended resources
minikube start --cpus=4 --memory=8192 --driver=docker

# Verify cluster is running
kubectl cluster-info
```

### 4️⃣ Enable Ingress Addon

```bash
# Enable ingress controller
minikube addons enable ingress

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

### 5️⃣ Install Voting App with Helm

```bash
# Install the Helm chart
helm install voting-app k8s/helm/voting-app \
  --namespace voting-app \
  --create-namespace \
  --wait \
  --timeout 5m

# Expected output:
# NAME: voting-app
# NAMESPACE: voting-app
# STATUS: deployed
```

### 6️⃣ Verify Deployment

```bash
# Check Helm release status
helm status voting-app -n voting-app

# List all resources
helm list -n voting-app

# Check pods are running
kubectl get pods -n voting-app

# Expected: All pods showing "Running" status
```

### 7️⃣ Configure Local DNS

```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"

# Add to /etc/hosts (Linux/Mac)
echo "$MINIKUBE_IP vote.local result.local" | sudo tee -a /etc/hosts

# Verify entry
cat /etc/hosts | grep -E "vote.local|result.local"
```

**For Windows:**

```powershell
# Run PowerShell as Administrator
$MINIKUBE_IP = minikube ip
Add-Content C:\Windows\System32\drivers\etc\hosts "$MINIKUBE_IP vote.local result.local"
```

### 8️⃣ Test the Applications

```bash
# Test Vote service
curl -I http://vote.local
# Expected: HTTP/1.1 200 OK

# Test Result service
curl -I http://result.local
# Expected: HTTP/1.1 200 OK

# Submit a test vote
curl -X POST http://vote.local -d "vote=a"

# Check results
curl http://result.local
```

### 9️⃣ View Logs

```bash
# View all logs
kubectl logs -n voting-app -l app.kubernetes.io/instance=voting-app --tail=50

# View specific service logs
kubectl logs -n voting-app -l app=vote --tail=20
kubectl logs -n voting-app -l app=worker --tail=20 -f
kubectl logs -n voting-app -l app=result --tail=20
```

### 🔟 Run Seed Data (Optional)

```bash
# Apply seed job
kubectl apply -f k8s/manifests/10-seed.yaml

# Wait for completion
kubectl wait --for=condition=complete job/seed-data -n voting-app --timeout=300s

# View seed logs
kubectl logs -n voting-app job/seed-data

# Verify results
curl http://result.local
# Expected: ~2000 votes for Cats, ~1000 votes for Dogs
```

---

## 🔧 Helm Management Commands

### Upgrade Deployment

```bash
# Upgrade with new values
helm upgrade voting-app k8s/helm/voting-app \
  --namespace voting-app \
  --set vote.replicaCount=3 \
  --set result.replicaCount=2 \
  --wait

# Upgrade with custom values file
helm upgrade voting-app k8s/helm/voting-app \
  -n voting-app \
  -f custom-values.yaml \
  --wait
```

### View Configuration

```bash
# Get current values
helm get values voting-app -n voting-app

# Get all values (including defaults)
helm get values voting-app -n voting-app --all

# View manifest
helm get manifest voting-app -n voting-app
```

### Rollback Deployment

```bash
# View revision history
helm history voting-app -n voting-app

# Rollback to previous version
helm rollback voting-app -n voting-app

# Rollback to specific revision
helm rollback voting-app 2 -n voting-app
```

### Cleanup

```bash
# Uninstall Helm release
helm uninstall voting-app -n voting-app

# Delete namespace
kubectl delete namespace voting-app

# Stop Minikube
minikube stop

# Delete Minikube cluster (complete cleanup)
minikube delete
```

---

## 🎨 Customizing Helm Deployment

### Create Custom Values File

Create `custom-values.yaml`:

```yaml
# Vote service configuration
vote:
  replicaCount: 3
  image:
    tag: "latest"
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi

# Result service configuration
result:
  replicaCount: 2
  image:
    tag: "latest"
  resources:
    limits:
      cpu: 500m
      memory: 512Mi

# Worker service configuration
worker:
  replicaCount: 1
  image:
    tag: "latest"

# PostgreSQL configuration
postgres:
  persistence:
    size: 10Gi
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi

# Redis configuration
redis:
  resources:
    limits:
      cpu: 500m
      memory: 512Mi

# Ingress configuration
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: vote.local
      paths:
        - path: /
          pathType: Prefix
    - host: result.local
      paths:
        - path: /
          pathType: Prefix
```

### Deploy with Custom Values

```bash
helm install voting-app k8s/helm/voting-app \
  -n voting-app \
  --create-namespace \
  -f custom-values.yaml \
  --wait
```

### Override Specific Values

```bash
# Override image tags for CI/CD
helm install voting-app k8s/helm/voting-app \
  -n voting-app \
  --create-namespace \
  --set vote.image.tag=abc1234 \
  --set result.image.tag=abc1234 \
  --set worker.image.tag=abc1234 \
  --wait
```

---

## ❓ Can You Run Phase 2 with Terraform?

### Short Answer: **No, not for Minikube. Yes, for Cloud.**

### Detailed Explanation

#### 🚫 Terraform + Minikube (NOT Recommended)

**Why Terraform is NOT used for Minikube:**

1. **Minikube is Local & Ephemeral**
   - Destroyed and recreated frequently during development
   - No need for infrastructure-as-code for local testing
   - Adds unnecessary complexity

2. **kubectl/Helm are Simpler**
   - Direct manifest application is faster
   - Helm provides templating and versioning
   - No state file management overhead

3. **No Cloud Resources to Manage**
   - Terraform excels at provisioning cloud infrastructure
   - Minikube runs locally with `minikube start`
   - No VPCs, load balancers, or IAM roles to manage

4. **Development Workflow Mismatch**
   - Developers need quick iteration cycles
   - Terraform plan/apply adds extra steps
   - kubectl/Helm provide immediate feedback

**Comparison:**

| Aspect | Terraform | kubectl/Helm |
|--------|-----------|--------------|
| **Minikube Cluster Creation** | Not supported | `minikube start` |
| **Application Deployment** | Possible but complex | ✅ Simple & fast |
| **State Management** | Requires backend config | Not needed |
| **Development Speed** | Slower (plan/apply) | ✅ Instant |
| **Best For** | Cloud infrastructure | ✅ Local development |

---

#### ✅ Terraform + Cloud Kubernetes (Recommended for Production)

**When to Use Terraform:**

Use Terraform when deploying to **cloud Kubernetes clusters**:

1. **AWS EKS** (Elastic Kubernetes Service)
2. **Azure AKS** (Azure Kubernetes Service)
3. **Google GKE** (Google Kubernetes Engine)

**What Terraform Manages in Cloud:**

- ✅ Kubernetes cluster provisioning
- ✅ VPC and networking setup
- ✅ IAM roles and policies
- ✅ Node groups and autoscaling
- ✅ Load balancers and ingress controllers
- ✅ DNS records and certificates
- ✅ Storage classes and volumes

---

## 🌩️ Cloud Deployment with Terraform (Future Setup)

### Step 1: Choose Cloud Provider

**Option A: AWS EKS**

Create `terraform/aws/main.tf`:

```hcl
# Provision EKS cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "voting-app-cluster"
  cluster_version = "1.27"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    main = {
      min_size     = 2
      max_size     = 4
      desired_size = 2

      instance_types = ["t3.medium"]
    }
  }
}

# Configure kubectl after cluster creation
resource "null_resource" "kubectl_config" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name voting-app-cluster --region us-east-1"
  }
}
```

**Option B: Azure AKS**

Create `terraform/azure/main.tf`:

```hcl
# Provision AKS cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "voting-app-cluster"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "votingapp"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}
```

**Option C: Google GKE**

Create `terraform/gcp/main.tf`:

```hcl
# Provision GKE cluster
resource "google_container_cluster" "primary" {
  name     = "voting-app-cluster"
  location = "us-central1"

  remove_default_node_pool = true
  initial_node_count       = 1

  node_pool {
    name       = "main-pool"
    node_count = 2

    node_config {
      machine_type = "e2-medium"
    }
  }
}
```

### Step 2: Deploy Infrastructure

```bash
# Initialize Terraform
cd terraform/
terraform init

# Preview changes
terraform plan -out=tfplan

# Apply changes (provision cluster)
terraform apply tfplan

# This creates:
# - Kubernetes cluster
# - VPC and subnets
# - Security groups
# - IAM roles
# - Load balancers
```

### Step 3: Deploy Application with Helm

```bash
# Get cluster credentials
# For AWS:
aws eks update-kubeconfig --name voting-app-cluster --region us-east-1

# For Azure:
az aks get-credentials --resource-group voting-app --name voting-app-cluster

# For GCP:
gcloud container clusters get-credentials voting-app-cluster --region us-central1

# Deploy with Helm (same commands as Minikube!)
helm install voting-app k8s/helm/voting-app \
  --namespace voting-app \
  --create-namespace \
  --wait
```

### Step 4: Configure DNS (Cloud)

```bash
# Get LoadBalancer external IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Add DNS records (Terraform can automate this)
# vote.example.com -> LoadBalancer IP
# result.example.com -> LoadBalancer IP
```

---

## 🔄 Terraform vs Helm Decision Matrix

| Scenario | Tool to Use | Reason |
|----------|-------------|--------|
| **Local development on Minikube** | ✅ Helm | Fast, simple, no state management |
| **Provision cloud K8s cluster** | ✅ Terraform | Infrastructure-as-code for cloud resources |
| **Deploy app to cloud K8s** | ✅ Helm | Application deployment and versioning |
| **Manage VPCs, IAM, networking** | ✅ Terraform | Cloud infrastructure management |
| **CI/CD application updates** | ✅ Helm | Rolling updates, rollbacks |
| **Multi-cloud infrastructure** | ✅ Terraform | Unified IaC across providers |

---

## 🎯 Best Practices Summary

### For Local Development (Phase 2 - Current Project)

✅ **Use Helm** for deploying to Minikube

- Simple commands
- Version management
- Easy rollbacks
- Template customization

❌ **Don't use Terraform** for Minikube

- Adds unnecessary complexity
- No cloud resources to manage
- Slower development cycle

### For Production Cloud Deployment (Future)

✅ **Use Terraform** to provision cluster

- Infrastructure-as-code
- Version control
- Reproducible environments
- Multi-cloud support

✅ **Use Helm** to deploy application

- Application lifecycle management
- Configuration management
- Easy updates and rollbacks

---

## 📝 Quick Reference

### Helm Commands for Phase 2

```bash
# Install
helm install voting-app k8s/helm/voting-app -n voting-app --create-namespace

# Upgrade
helm upgrade voting-app k8s/helm/voting-app -n voting-app --reuse-values

# Status
helm status voting-app -n voting-app

# List releases
helm list -n voting-app

# Rollback
helm rollback voting-app -n voting-app

# Uninstall
helm uninstall voting-app -n voting-app
```

### kubectl Commands for Verification

```bash
# Check pods
kubectl get pods -n voting-app

# Check services
kubectl get svc -n voting-app

# Check ingress
kubectl get ingress -n voting-app

# View logs
kubectl logs -n voting-app -l app=vote --tail=50

# Port forward (alternative to ingress)
kubectl port-forward -n voting-app svc/vote 8080:80
kubectl port-forward -n voting-app svc/result 8081:4000
```

---

## ✅ Conclusion

**For Phase 2 Testing:**

- **Recommended:** Use Helm with the commands in this guide ✅
- **Alternative:** Use kubectl with manifests (less flexible)
- **Not Recommended:** Terraform for Minikube ❌

**For Future Cloud Deployment:**

- Use Terraform to provision infrastructure ✅
- Use Helm to deploy applications ✅
- Combine both for complete IaC solution ✅
