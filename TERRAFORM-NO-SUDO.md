# Terraform Deployment - Fully Automated (No Password Prompts)

## Changes Made (November 22, 2025)

### Problem

`terraform apply` was asking for sudo password to configure `/etc/hosts`, breaking automation and CI/CD pipelines.

### Solution

1. **One-time setup**: Configure passwordless sudo for `/etc/hosts` modifications
2. **Automatic configuration**: Terraform automatically configures `/etc/hosts` without prompts
3. **Optional seed job**: Seed job only runs when explicitly requested

## Quick Start (Fully Automated)

### One-Time Setup (Run Once)

```bash
# Configure passwordless sudo for /etc/hosts (run once per machine)
sudo ./setup-sudoers.sh
```

This creates `/etc/sudoers.d/terraform-hosts` allowing passwordless sudo for:

- Modifying `/etc/hosts` with `sed`
- Appending to `/etc/hosts` with `tee`

### Deploy Everything (No Password Needed!)

```bash
cd terraform
terraform apply -auto-approve
```

**That's it!** 🎉 Terraform will:

- ✅ Create Minikube cluster
- ✅ Build Docker images (with .NET 8.0 security fixes)
- ✅ Deploy PostgreSQL and Redis via Helm
- ✅ Deploy vote, result, and worker services
- ✅ **Automatically configure /etc/hosts** (no password prompt!)
- ❌ NOT run seed job (manual control)

### Access Applications Immediately

```bash
curl http://vote.local
curl http://result.local

# Or open in browser
xdg-open http://vote.local
xdg-open http://result.local
```

## Alternative: Without Passwordless Sudo

If you don't want to configure passwordless sudo:

### Deploy Infrastructure

```bash
cd terraform
terraform apply -auto-approve
```

### Configure /etc/hosts Manually (One-Time)

```bash
MINIKUBE_IP=$(minikube ip -p voting-app-dev)
sudo bash -c "sed -i.bak '/vote\.local/d; /result\.local/d' /etc/hosts"
sudo bash -c "echo '$MINIKUBE_IP vote.local' >> /etc/hosts"
sudo bash -c "echo '$MINIKUBE_IP result.local' >> /etc/hosts"
```

### 4. (Optional) Run Seed Job

```bash
# Option 1: Terraform (requires enabling variable)
terraform apply -var="run_seed=true" -target=null_resource.run_seed -auto-approve

# Option 2: kubectl (recommended - faster)
kubectl apply -f ../k8s/manifests/10-seed.yaml
kubectl logs -f seed -n voting-app
```

## Files Modified

1. **terraform/cluster.tf** - `configure_hosts` resource now creates helper script
2. **terraform/seed.tf** - Added `count` variable to prevent automatic execution
3. **terraform/outputs.tf** - Updated instructions
4. **COMPLETE-TESTING-GUIDE.md** - Updated Phase 2 steps

## Benefits

✅ **No interruption** - terraform apply runs completely unattended  
✅ **One-time setup** - /etc/hosts only needs configuration once  
✅ **Flexible** - Can still update /etc/hosts manually if needed  
✅ **CI/CD friendly** - Works in automated pipelines  
✅ **Seed control** - Seed job only runs when explicitly requested  

## Verification

```bash
# Check deployment
terraform output deployment_status

# Check /etc/hosts
grep -E "vote\.local|result\.local" /etc/hosts

# Check pods
kubectl get pods -n voting-app

# Test services
curl http://vote.local
curl http://result.local
```

## Troubleshooting

### /etc/hosts not configured

```bash
cd terraform
./configure-hosts.sh
```

### Seed job ran automatically

If seed job runs during `terraform apply`, ensure you have the latest `seed.tf`:

```bash
cd terraform
terraform validate
terraform plan  # Should show run_seed[0] will be destroyed
```

### Minikube IP changed

```bash
cd terraform
./configure-hosts.sh  # Re-run to update /etc/hosts
```
