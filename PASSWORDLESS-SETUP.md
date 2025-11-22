# Passwordless Terraform Deployment Setup

## Problem Statement

Running `terraform apply` requires sudo password to configure `/etc/hosts`, which:

- ❌ Breaks automation and CI/CD pipelines
- ❌ Requires manual intervention during deployment
- ❌ Cannot run in background or cron jobs

## Solution: Passwordless Sudo Configuration

Configure Linux sudoers to allow specific `/etc/hosts` modifications without password.

---

## Setup (Run Once Per Machine)

### Step 1: Run Setup Script

```bash
# From project root
sudo ./setup-sudoers.sh
```

**What it does:**

- Creates `/etc/sudoers.d/terraform-hosts`
- Allows your user to run these commands without password:
  - `sudo sed -i ... /etc/hosts` (remove old entries)
  - `sudo tee -a /etc/hosts` (add new entries)
- Validates sudoers syntax (safe!)

### Step 2: Verify Configuration

```bash
# Test passwordless sudo (should work without asking password)
sudo -n sed -i.bak '/test/d' /etc/hosts
echo $?  # Should output: 0 (success)
```

---

## Usage

### Deploy Everything (Fully Automated)

```bash
cd terraform
terraform apply -auto-approve
```

**Result:**

- ✅ Minikube cluster created
- ✅ Images built (vote, result, worker)
- ✅ Databases deployed (PostgreSQL, Redis)
- ✅ Applications deployed
- ✅ **/etc/hosts configured automatically** (no password!)

### Access Applications

```bash
# Immediate access after deployment
curl http://vote.local
curl http://result.local

# Or browser
firefox http://vote.local
firefox http://result.local
```

---

## Security Considerations

### What's Allowed (Very Limited Scope)

The sudoers configuration **ONLY** allows:

1. **Modifying /etc/hosts** with sed

   ```bash
   sudo sed -i '/pattern/d' /etc/hosts
   ```

2. **Appending to /etc/hosts** with tee

   ```bash
   echo "..." | sudo tee -a /etc/hosts
   ```

### What's NOT Allowed

- ❌ Running any other sudo commands without password
- ❌ Installing packages
- ❌ Modifying system files (except /etc/hosts)
- ❌ User management
- ❌ Network configuration
- ❌ Any other system administration

### Why This Is Safe

1. **Minimal scope**: Only 2 specific commands for 1 specific file
2. **No privilege escalation**: Cannot use this to gain root access
3. **Auditable**: All changes logged in `/var/log/auth.log`
4. **Standard practice**: Same approach used by Docker, Kubernetes installers
5. **Reversible**: Delete `/etc/sudoers.d/terraform-hosts` to remove

---

## Alternative: Without Passwordless Sudo

If you prefer NOT to configure passwordless sudo:

### Option 1: Manual /etc/hosts Configuration

```bash
# Deploy infrastructure
cd terraform
terraform apply -auto-approve

# Configure /etc/hosts manually (one-time)
MINIKUBE_IP=$(minikube ip -p voting-app-dev)
sudo bash -c "sed -i.bak '/vote\.local/d; /result\.local/d' /etc/hosts"
sudo bash -c "echo '$MINIKUBE_IP vote.local' >> /etc/hosts"
sudo bash -c "echo '$MINIKUBE_IP result.local' >> /etc/hosts"
```

### Option 2: Use Port Forwarding Instead

```bash
# Deploy without ingress
cd terraform
terraform apply -auto-approve

# Access via port-forward (no /etc/hosts needed)
kubectl port-forward -n voting-app svc/vote 8080:80 &
kubectl port-forward -n voting-app svc/result 8081:4000 &

# Access at:
curl http://localhost:8080  # vote
curl http://localhost:8081  # result
```

---

## Troubleshooting

### "sudo: no tty present and no askpass program specified"

**Cause:** Passwordless sudo not configured

**Fix:**

```bash
sudo ./setup-sudoers.sh
```

### "sudo: /etc/sudoers.d/terraform-hosts is world writable"

**Cause:** Wrong permissions on sudoers file

**Fix:**

```bash
sudo chmod 0440 /etc/sudoers.d/terraform-hosts
```

### Verify Sudoers Configuration

```bash
# Check file exists
ls -la /etc/sudoers.d/terraform-hosts

# Check syntax
sudo visudo -c -f /etc/sudoers.d/terraform-hosts

# Check content
sudo cat /etc/sudoers.d/terraform-hosts
```

### Remove Passwordless Configuration

```bash
# Remove sudoers file
sudo rm /etc/sudoers.d/terraform-hosts

# Verify removed
sudo visudo -c
```

---

## For CI/CD Pipelines

### GitHub Actions Example

```yaml
- name: Setup passwordless sudo
  run: sudo ./setup-sudoers.sh

- name: Deploy with Terraform
  run: |
    cd terraform
    terraform init
    terraform apply -auto-approve
```

### GitLab CI Example

```yaml
deploy:
  script:
    - sudo ./setup-sudoers.sh
    - cd terraform
    - terraform init
    - terraform apply -auto-approve
```

### Jenkins Pipeline Example

```groovy
stage('Deploy') {
    steps {
        sh 'sudo ./setup-sudoers.sh'
        sh 'cd terraform && terraform init'
        sh 'cd terraform && terraform apply -auto-approve'
    }
}
```

---

## Files Modified

1. **setup-sudoers.sh** - One-time setup script for passwordless sudo
2. **terraform/cluster.tf** - Auto-configures /etc/hosts (uses passwordless sudo)
3. **terraform/seed.tf** - Seed job only runs when explicitly requested
4. **TERRAFORM-NO-SUDO.md** - Usage documentation

---

## Benefits Summary

✅ **Zero interruption** - terraform apply runs completely unattended  
✅ **CI/CD ready** - works in automated pipelines  
✅ **Secure** - minimal, auditable sudo permissions  
✅ **One-time setup** - configure once per machine  
✅ **Reversible** - easy to remove if needed  
✅ **Standard practice** - used by Docker, K8s, etc.  

---

## Quick Reference

```bash
# One-time setup
sudo ./setup-sudoers.sh

# Deploy everything (no password!)
cd terraform
terraform apply -auto-approve

# Access apps
curl http://vote.local
curl http://result.local

# Optional: Run seed job
kubectl apply -f ../k8s/manifests/10-seed.yaml
kubectl logs -f seed -n voting-app

# Cleanup
terraform destroy -auto-approve
sudo rm /etc/sudoers.d/terraform-hosts
```
