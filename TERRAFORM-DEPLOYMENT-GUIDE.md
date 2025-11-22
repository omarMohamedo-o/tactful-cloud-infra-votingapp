# Terraform Deployment Guide

## 🚀 Two Deployment Options

### Option 1: Full Deployment (Without Seed)

Deploy the complete infrastructure without waiting for seed data:

```bash
cd terraform
terraform apply -auto-approve
```

**What this deploys:**
- ✅ Minikube cluster (voting-app-dev)
- ✅ Docker images (vote, result, worker)
- ✅ PostgreSQL database (Helm chart)
- ✅ Redis cache (Helm chart)
- ✅ Application services (vote, result, worker)
- ✅ NetworkPolicies & Ingress
- ✅ /etc/hosts configuration

**Duration:** ~2-3 minutes

**Access the app:**
- Vote: http://vote.local
- Results: http://result.local

---

### Option 2: Run Seed Job Separately

After deployment, generate test data independently:

```bash
cd terraform
terraform apply -target=null_resource.run_seed -auto-approve
```

**What this does:**
- 🌱 Deletes any existing seed pod
- 🌱 Deploys new seed job
- 🌱 Generates 3000 votes (2000 Cats, 1000 Dogs)
- 🌱 Shows real-time progress
- 🌱 Displays final vote counts

**Duration:** ~6 minutes

**Re-run seed anytime:**
```bash
# The timestamp trigger automatically changes each run
terraform apply -target=null_resource.run_seed -auto-approve
```

---

## 📊 Architecture

```
Terraform Resources (7 total)
├── minikube_cluster          # Provisions Minikube
├── build_images              # Builds Docker images
├── create_namespace          # Creates namespace with PSA
├── configure_hosts           # Updates /etc/hosts
├── deploy_databases          # PostgreSQL + Redis via Helm
├── deploy_application        # All K8s manifests
└── kubeconfig                # Exports kubeconfig

Separate Seed Resource (in seed.tf)
└── run_seed                  # Independent seed job
```

---

## 🔄 Workflow Examples

### Fresh Deployment
```bash
# 1. Deploy infrastructure
cd terraform
terraform apply -auto-approve

# 2. Wait 2-3 minutes for all pods to be ready
kubectl get pods -n voting-app --watch

# 3. Test the app manually
open http://vote.local
open http://result.local

# 4. Generate test data when ready
terraform apply -target=null_resource.run_seed -auto-approve
```

### Re-seed Data
```bash
# Run seed multiple times for testing
cd terraform
terraform apply -target=null_resource.run_seed -auto-approve
# Wait ~6 minutes
terraform apply -target=null_resource.run_seed -auto-approve
# Adds another 3000 votes
```

### Complete Teardown
```bash
cd terraform
terraform destroy -auto-approve
minikube delete -p voting-app-dev
```

---

## ✨ Benefits of Separate Seed

### Before (Seed in main deployment):
- ❌ 8-9 minute total deployment time
- ❌ Can't skip seed data
- ❌ Can't re-run seed easily
- ❌ Blocks other testing

### After (Seed separate):
- ✅ 2-3 minute infrastructure deployment
- ✅ Optional test data generation
- ✅ Re-run seed anytime
- ✅ Faster iteration during development
- ✅ Test with different data volumes

---

## 🧪 Verification Commands

```bash
# Check all resources
terraform output

# Verify pods
kubectl get pods -n voting-app

# Check seed status
kubectl get pod seed -n voting-app
kubectl logs seed -n voting-app --tail=20

# View vote counts
kubectl exec -n voting-app postgresql-0 -- \
  sh -c 'PGPASSWORD="$POSTGRES_PASSWORD" psql -U postgres -d postgres \
  -c "SELECT vote, COUNT(*) FROM votes GROUP BY vote;"'

# Test voting
curl -X POST http://vote.local -d "vote=a"
curl http://result.local
```

---

## 📝 Files Structure

```
terraform/
├── cluster.tf          # Main infrastructure (7 resources)
├── seed.tf             # Separate seed job (1 resource)
├── variables.tf        # Configuration variables
├── outputs.tf          # Deployment status & URLs
├── terraform.tfvars    # Dev environment values
└── prod.tfvars         # Production values
```

---

## 🎯 Common Tasks

### Just build new images:
```bash
terraform apply -target=null_resource.build_images -auto-approve
```

### Just update app manifests:
```bash
terraform apply -target=null_resource.deploy_application -auto-approve
```

### Just run seed:
```bash
terraform apply -target=null_resource.run_seed -auto-approve
```

### Full re-deployment:
```bash
terraform destroy -auto-approve
terraform apply -auto-approve
```

---

## 🔒 Security Notes

- Pod Security Admission: baseline enforced
- NetworkPolicies: 7 policies for database isolation
- Non-root containers: UID 1000
- SeccompProfile: RuntimeDefault
- Resource limits: CPU & memory constrained

---

## 📈 Scaling

To increase seed votes, edit `k8s/manifests/10-seed.yaml`:
```yaml
env:
- name: TOTAL_VOTES
  value: "10000"  # Increase as needed
```

Then re-run:
```bash
terraform apply -target=null_resource.run_seed -auto-approve
```

