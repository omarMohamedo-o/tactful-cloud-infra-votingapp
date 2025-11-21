# 🔐 Secrets Management Guide

## Security Audit Summary

✅ **Good Practices Already Implemented:**

- `.env` file is in `.gitignore`
- No hardcoded credentials in source code
- Environment variables used for configuration
- Kubernetes Secrets for credential management

⚠️ **Issues Fixed:**

- Converted K8s secrets from `stringData` to `data` (base64)
- Created `.env.example` template
- Added security warnings and documentation
- Removed plaintext passwords from repository

---

## For Local Development (Docker Compose)

### Setup

1. **Copy the template:**

   ```bash
   cp .env.example .env
   ```

2. **Generate strong passwords:**

   ```bash
   # PostgreSQL password
   POSTGRES_PASS=$(openssl rand -base64 24)
   echo "POSTGRES_PASSWORD=$POSTGRES_PASS" >> .env
   
   # Redis password
   REDIS_PASS=$(openssl rand -base64 24)
   echo "REDIS_PASSWORD=$REDIS_PASS" >> .env
   ```

3. **Edit `.env` file:**

   ```bash
   nano .env  # or your preferred editor
   ```

### Important Notes

- ✅ `.env` is **git-ignored** - never commit it
- ⚠️ Use strong passwords (minimum 16 characters)
- 🔄 Different passwords for dev/staging/prod
- 📝 Store production passwords in a password manager

---

## For Kubernetes Deployment

### Current State (Development)

The secrets file `k8s/manifests/01-secrets.yaml` contains **base64-encoded** defaults:

- PostgreSQL password: `postgres` (base64: `cG9zdGdyZXM=`)
- Redis password: empty (no authentication)

⚠️ **These are ONLY for development!**

### For Production: Three Options

#### Option 1: Manual Secret Creation (Basic)

```bash
# Create secrets manually (not committed to git)
kubectl create secret generic postgres-secret \
  --from-literal=postgres-user=postgres \
  --from-literal=postgres-password='YOUR_STRONG_PASSWORD_HERE' \
  --from-literal=postgres-db=postgres \
  --namespace=voting-app

kubectl create secret generic redis-secret \
  --from-literal=redis-password='YOUR_STRONG_REDIS_PASSWORD' \
  --namespace=voting-app
```

Then **delete** or **exclude** `01-secrets.yaml` from your deployment.

#### Option 2: Sealed Secrets (Recommended for GitOps)

[Bitnami Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) encrypts secrets so they can be safely stored in git.

1. **Install sealed-secrets controller:**

   ```bash
   kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml
   ```

2. **Install kubeseal CLI:**

   ```bash
   # macOS
   brew install kubeseal
   
   # Linux
   wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz
   tar xfz kubeseal-0.24.0-linux-amd64.tar.gz
   sudo install -m 755 kubeseal /usr/local/bin/kubeseal
   ```

3. **Create sealed secret:**

   ```bash
   # Create regular secret (don't apply)
   kubectl create secret generic postgres-secret \
     --from-literal=postgres-user=postgres \
     --from-literal=postgres-password='YOUR_PASSWORD' \
     --from-literal=postgres-db=postgres \
     --namespace=voting-app \
     --dry-run=client -o yaml > /tmp/postgres-secret.yaml
   
   # Seal it
   kubeseal -f /tmp/postgres-secret.yaml -w k8s/manifests/01-postgres-sealed-secret.yaml
   
   # Now you can commit 01-postgres-sealed-secret.yaml safely!
   rm /tmp/postgres-secret.yaml
   ```

4. **Apply sealed secret:**

   ```bash
   kubectl apply -f k8s/manifests/01-postgres-sealed-secret.yaml
   ```

#### Option 3: External Secrets Operator (Advanced)

[External Secrets Operator](https://external-secrets.io/) syncs secrets from cloud providers or Vault.

Supports:

- AWS Secrets Manager
- Azure Key Vault
- Google Cloud Secret Manager
- HashiCorp Vault
- 1Password
- And more...

**Example with AWS Secrets Manager:**

1. **Install External Secrets Operator:**

   ```bash
   helm repo add external-secrets https://charts.external-secrets.io
   helm install external-secrets external-secrets/external-secrets \
     --namespace external-secrets-system \
     --create-namespace
   ```

2. **Create secret in AWS:**

   ```bash
   aws secretsmanager create-secret \
     --name voting-app/postgres \
     --secret-string '{"username":"postgres","password":"YOUR_STRONG_PASSWORD","database":"postgres"}'
   ```

3. **Create ExternalSecret resource:**

   ```yaml
   apiVersion: external-secrets.io/v1beta1
   kind: ExternalSecret
   metadata:
     name: postgres-secret
     namespace: voting-app
   spec:
     refreshInterval: 1h
     secretStoreRef:
       name: aws-secretsmanager
       kind: SecretStore
     target:
       name: postgres-secret
     data:
       - secretKey: postgres-user
         remoteRef:
           key: voting-app/postgres
           property: username
       - secretKey: postgres-password
         remoteRef:
           key: voting-app/postgres
           property: password
       - secretKey: postgres-db
         remoteRef:
           key: voting-app/postgres
           property: database
   ```

---

## Security Best Practices

### ✅ DO

1. **Use strong passwords:**
   - Minimum 16 characters
   - Mix of uppercase, lowercase, numbers, symbols
   - Use password generator: `openssl rand -base64 24`

2. **Rotate credentials regularly:**
   - Every 90 days for production
   - After any security incident
   - When team member leaves

3. **Use different passwords per environment:**
   - Dev, staging, and prod must have different credentials
   - Never use production passwords in development

4. **Limit access:**
   - Use Kubernetes RBAC to restrict secret access
   - Only grant secret read access to necessary service accounts
   - Audit who has access to secrets

5. **Monitor access:**
   - Enable audit logging for secret access
   - Alert on unusual secret access patterns

### ❌ DON'T

1. **Never commit secrets to git:**
   - Not even in private repositories
   - Not even "temporarily"
   - Git history is permanent

2. **Don't use default passwords:**
   - Change all defaults before production
   - Even "postgres" is easily guessable

3. **Don't share passwords:**
   - Use secret management tools
   - Each person/service should have their own credentials

4. **Don't log passwords:**
   - Check application logs for accidental password exposure
   - Sanitize logs before sharing

5. **Don't store passwords in plaintext:**
   - At minimum, use base64 encoding in Kubernetes
   - Better: use sealed-secrets or external secret managers

---

## Verification

### Check for Exposed Secrets

```bash
# Scan for hardcoded secrets in code
snyk code test

# Scan git history for committed secrets
git log -p | grep -i password

# Check Docker Compose doesn't expose secrets
docker compose config | grep -i password
```

### Verify Kubernetes Secrets

```bash
# List secrets
kubectl get secrets -n voting-app

# Check secret is not plaintext in git
grep -r "password" k8s/manifests/

# Verify base64 encoding
kubectl get secret postgres-secret -n voting-app -o yaml
```

### Verify .env Protection

```bash
# Ensure .env is git-ignored
git check-ignore -v .env

# Should output: .gitignore:2:.env    .env
```

---

## Emergency: Secret Compromised

If a password is accidentally committed or exposed:

1. **Rotate immediately:**

   ```bash
   # Generate new password
   NEW_PASS=$(openssl rand -base64 24)
   
   # Update Kubernetes secret
   kubectl create secret generic postgres-secret \
     --from-literal=postgres-password="$NEW_PASS" \
     --namespace=voting-app \
     --dry-run=client -o yaml | kubectl apply -f -
   
   # Restart pods to use new secret
   kubectl rollout restart deployment/vote -n voting-app
   kubectl rollout restart deployment/result -n voting-app
   kubectl rollout restart deployment/worker -n voting-app
   kubectl rollout restart statefulset/postgres -n voting-app
   ```

2. **Rewrite git history** (if committed):

   ```bash
   # Use BFG Repo-Cleaner or git-filter-repo
   # WARNING: This rewrites history!
   git filter-branch --tree-filter 'rm -f .env' HEAD
   ```

3. **Notify your team**

4. **Review access logs** for unauthorized access

5. **Update documentation** about what went wrong

---

## Resources

- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [Kubernetes Secrets Best Practices](https://kubernetes.io/docs/concepts/security/secrets-good-practices/)
- [Sealed Secrets Documentation](https://github.com/bitnami-labs/sealed-secrets)
- [External Secrets Operator](https://external-secrets.io/)

---

**Last Updated:** 2024-11-21  
**Status:** ✅ Secrets are properly managed for development. For production, implement Option 2 (Sealed Secrets) or Option 3 (External Secrets Operator).
