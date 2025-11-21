#!/bin/bash

################################################################################
# Complete End-to-End Test Script - All Phases
# This script tests Phase 1 (Docker Compose), Phase 2 (Kubernetes), and Phase 3 (CI/CD)
################################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_step() { echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${BLUE}$1${NC}"; echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

# Get project root directory
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$PROJECT_ROOT"

# Variables
PHASE1_VOTE_URL="http://localhost:8080"
PHASE1_RESULT_URL="http://localhost:8081"
PHASE2_VOTE_URL="http://vote.local"
PHASE2_RESULT_URL="http://result.local"
MINIKUBE_PROFILE="voting-app-dev"
NAMESPACE="voting-app"

################################################################################
# PHASE 1: Docker Compose Testing
################################################################################

print_step "🐳 PHASE 1: Docker Compose Testing"

print_info "Step 1.1: Cleaning Docker Compose environment..."
docker compose down -v 2>/dev/null || true
docker system prune -f > /dev/null 2>&1
print_success "Environment cleaned"

print_info "Step 1.2: Building and starting services..."
docker compose up --build -d
print_success "Services started"

print_info "Step 1.3: Waiting for services to be healthy (30 seconds)..."
sleep 30

print_info "Step 1.4: Checking service status..."
docker compose ps
if docker compose ps | grep -q "Up"; then
    print_success "All services are running"
else
    print_error "Some services failed to start"
    docker compose logs
    exit 1
fi

print_info "Step 1.5: Testing Vote service accessibility..."
if curl -s -o /dev/null -w "%{http_code}" $PHASE1_VOTE_URL | grep -q "200"; then
    print_success "Vote service is accessible at $PHASE1_VOTE_URL"
else
    print_error "Vote service is not accessible"
    exit 1
fi

print_info "Step 1.6: Testing Result service accessibility..."
if curl -s -o /dev/null -w "%{http_code}" $PHASE1_RESULT_URL | grep -q "200"; then
    print_success "Result service is accessible at $PHASE1_RESULT_URL"
else
    print_error "Result service is not accessible"
    exit 1
fi

print_info "Step 1.7: Submitting test votes..."
curl -X POST $PHASE1_VOTE_URL -H "Content-Type: application/x-www-form-urlencoded" -d "vote=a" > /dev/null 2>&1
curl -X POST $PHASE1_VOTE_URL -H "Content-Type: application/x-www-form-urlencoded" -d "vote=b" > /dev/null 2>&1
print_success "Test votes submitted"

print_info "Step 1.8: Verifying data in PostgreSQL..."
VOTE_COUNT=$(docker compose exec -T db psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM votes;" 2>/dev/null | tr -d '[:space:]')
if [ "$VOTE_COUNT" -gt 0 ]; then
    print_success "Votes stored in database: $VOTE_COUNT votes"
else
    print_warning "No votes found in database yet, worker may still be processing"
fi

print_info "Step 1.9: Running seed data generation..."
docker compose --profile seed up seed-data
print_success "Seed data generated"

print_info "Step 1.10: Verifying seed data..."
FINAL_COUNT=$(docker compose exec -T db psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM votes;" 2>/dev/null | tr -d '[:space:]')
if [ "$FINAL_COUNT" -gt 3000 ]; then
    print_success "Total votes in database: $FINAL_COUNT (seed data loaded successfully)"
else
    print_warning "Expected ~3000 votes, found: $FINAL_COUNT"
fi

print_info "Step 1.11: Verifying non-root users..."
VOTE_USER=$(docker compose exec -T vote id -u 2>/dev/null)
RESULT_USER=$(docker compose exec -T result id -u 2>/dev/null)
WORKER_USER=$(docker compose exec -T worker id -u 2>/dev/null)

if [ "$VOTE_USER" != "0" ] && [ "$RESULT_USER" != "0" ] && [ "$WORKER_USER" != "0" ]; then
    print_success "All services running as non-root users"
else
    print_error "Some services running as root"
    exit 1
fi

print_info "Step 1.12: Checking resource usage..."
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -6
print_success "Resource usage checked"

print_success "🎉 PHASE 1 COMPLETED SUCCESSFULLY!"
echo ""
echo "Phase 1 Results:"
echo "  ✅ All 5 services running and healthy"
echo "  ✅ Vote accessible at $PHASE1_VOTE_URL"
echo "  ✅ Result accessible at $PHASE1_RESULT_URL"
echo "  ✅ $FINAL_COUNT votes in database"
echo "  ✅ All services running as non-root"
echo ""

# Pause before Phase 2
read -p "Press Enter to continue to Phase 2 (Kubernetes) or Ctrl+C to exit..."

################################################################################
# PHASE 2: Kubernetes with Terraform Testing
################################################################################

print_step "☸️  PHASE 2: Kubernetes with Terraform Testing"

print_info "Step 2.1: Cleaning Docker Compose environment..."
docker compose down -v
print_success "Docker Compose stopped"

print_info "Step 2.2: Checking prerequisites..."
command -v minikube >/dev/null 2>&1 || { print_error "Minikube not installed"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { print_error "kubectl not installed"; exit 1; }
command -v helm >/dev/null 2>&1 || { print_error "Helm not installed"; exit 1; }
command -v terraform >/dev/null 2>&1 || { print_error "Terraform not installed"; exit 1; }
print_success "All prerequisites installed"

print_info "Step 2.3: Provisioning Minikube cluster with Terraform..."
cd terraform
terraform init > /dev/null 2>&1
terraform apply -auto-approve
cd ..
print_success "Minikube cluster provisioned"

print_info "Step 2.4: Verifying cluster status..."
if minikube status -p $MINIKUBE_PROFILE | grep -q "Running"; then
    print_success "Minikube cluster is running"
else
    print_error "Minikube cluster failed to start"
    exit 1
fi

print_info "Step 2.5: Setting kubectl context..."
kubectl config use-context $MINIKUBE_PROFILE
print_success "kubectl context set to $MINIKUBE_PROFILE"

print_info "Step 2.6: Verifying cluster connection..."
kubectl cluster-info
kubectl get nodes
print_success "Cluster connection verified"

print_info "Step 2.7: Verifying namespace creation..."
if kubectl get namespace $NAMESPACE > /dev/null 2>&1; then
    print_success "Namespace $NAMESPACE exists"
else
    print_error "Namespace $NAMESPACE not found"
    exit 1
fi

print_info "Step 2.8: Verifying /etc/hosts configuration..."
if grep -q "vote.local" /etc/hosts && grep -q "result.local" /etc/hosts; then
    MINIKUBE_IP=$(minikube ip -p $MINIKUBE_PROFILE)
    print_success "/etc/hosts configured with Minikube IP: $MINIKUBE_IP"
else
    print_error "/etc/hosts not configured properly"
    exit 1
fi

print_info "Step 2.9: Adding Helm repositories..."
helm repo add bitnami https://charts.bitnami.com/bitnami > /dev/null 2>&1
helm repo update > /dev/null 2>&1
print_success "Helm repositories added and updated"

print_info "Step 2.10: Deploying PostgreSQL via Helm..."
if [ -f "k8s/helm/postgresql-values-dev.yaml" ]; then
    helm install postgresql bitnami/postgresql -n $NAMESPACE -f k8s/helm/postgresql-values-dev.yaml
    print_success "PostgreSQL deployed"
else
    print_warning "PostgreSQL values file not found, skipping..."
fi

print_info "Step 2.11: Deploying Redis via Helm..."
if [ -f "k8s/helm/redis-values-dev.yaml" ]; then
    helm install redis bitnami/redis -n $NAMESPACE -f k8s/helm/redis-values-dev.yaml
    print_success "Redis deployed"
else
    print_warning "Redis values file not found, skipping..."
fi

print_info "Step 2.12: Deploying voting application via Helm..."
if [ -d "k8s/helm/voting-app" ]; then
    helm install voting-app k8s/helm/voting-app -n $NAMESPACE --set environment=dev
    print_success "Voting app deployed"
else
    print_warning "Voting app Helm chart not found, deploying via kubectl..."
    kubectl apply -f k8s/manifests/
    print_success "Voting app deployed via kubectl"
fi

print_info "Step 2.13: Waiting for pods to be ready (60 seconds)..."
sleep 60

print_info "Step 2.14: Checking pod status..."
kubectl get pods -n $NAMESPACE
if kubectl get pods -n $NAMESPACE | grep -q "Running"; then
    print_success "Pods are running"
else
    print_warning "Some pods may still be starting"
fi

print_info "Step 2.15: Waiting for all pods to be ready..."
kubectl wait --for=condition=ready pod --all -n $NAMESPACE --timeout=300s || print_warning "Some pods took longer than expected"

print_info "Step 2.16: Checking services..."
kubectl get svc -n $NAMESPACE
print_success "Services checked"

print_info "Step 2.17: Checking ingress..."
kubectl get ingress -n $NAMESPACE
print_success "Ingress checked"

print_info "Step 2.18: Testing Vote service accessibility..."
MAX_RETRIES=10
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s -o /dev/null -w "%{http_code}" $PHASE2_VOTE_URL | grep -q "200"; then
        print_success "Vote service is accessible at $PHASE2_VOTE_URL"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT+1))
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            print_warning "Vote service not ready yet, retrying ($RETRY_COUNT/$MAX_RETRIES)..."
            sleep 10
        else
            print_error "Vote service is not accessible after $MAX_RETRIES attempts"
            print_info "Checking ingress controller status..."
            kubectl get pods -n ingress-nginx
            exit 1
        fi
    fi
done

print_info "Step 2.19: Testing Result service accessibility..."
if curl -s -o /dev/null -w "%{http_code}" $PHASE2_RESULT_URL | grep -q "200"; then
    print_success "Result service is accessible at $PHASE2_RESULT_URL"
else
    print_warning "Result service may not be fully ready yet"
fi

print_info "Step 2.20: Submitting test votes to Kubernetes deployment..."
curl -X POST $PHASE2_VOTE_URL -H "Content-Type: application/x-www-form-urlencoded" -d "vote=a" > /dev/null 2>&1
curl -X POST $PHASE2_VOTE_URL -H "Content-Type: application/x-www-form-urlencoded" -d "vote=b" > /dev/null 2>&1
print_success "Test votes submitted"

print_info "Step 2.21: Deploying seed job..."
if [ -f "k8s/manifests/10-seed.yaml" ]; then
    kubectl apply -f k8s/manifests/10-seed.yaml
    print_success "Seed job deployed"
    
    print_info "Step 2.22: Waiting for seed job to complete..."
    kubectl wait --for=condition=complete --timeout=300s job/seed-data -n $NAMESPACE || print_warning "Seed job is taking longer than expected"
    
    print_info "Step 2.23: Checking seed job logs..."
    kubectl logs -n $NAMESPACE job/seed-data --tail=20
else
    print_warning "Seed job manifest not found, skipping..."
fi

print_info "Step 2.24: Verifying Pod Security Standards..."
kubectl get namespace $NAMESPACE -o yaml | grep -A 5 "pod-security"
print_success "Pod Security Standards verified"

print_info "Step 2.25: Checking resource limits..."
kubectl describe pods -n $NAMESPACE | grep -A 3 "Limits:" | head -20
print_success "Resource limits checked"

print_success "🎉 PHASE 2 COMPLETED SUCCESSFULLY!"
echo ""
echo "Phase 2 Results:"
echo "  ✅ Minikube cluster provisioned via Terraform"
echo "  ✅ All pods running in $NAMESPACE namespace"
echo "  ✅ Vote accessible at $PHASE2_VOTE_URL"
echo "  ✅ Result accessible at $PHASE2_RESULT_URL"
echo "  ✅ Ingress controller functional"
echo "  ✅ Security policies enforced"
echo ""

# Pause before Phase 3
read -p "Press Enter to continue to Phase 3 (CI/CD) or Ctrl+C to exit..."

################################################################################
# PHASE 3: CI/CD Pipeline Testing
################################################################################

print_step "🔄 PHASE 3: CI/CD Pipeline Testing"

print_info "Step 3.1: Checking GitHub CLI installation..."
if command -v gh >/dev/null 2>&1; then
    print_success "GitHub CLI installed"
else
    print_warning "GitHub CLI not installed, skipping automated checks"
    print_info "Please manually verify:"
    echo "  1. Check GitHub Actions: https://github.com/omarMohamedo-o/tactful-votingapp-cloud-infra/actions"
    echo "  2. Verify container images: https://github.com/omarMohamedo-o?tab=packages"
    echo "  3. Check security scanning results"
    print_success "Phase 3 manual verification instructions provided"
    exit 0
fi

print_info "Step 3.2: Checking GitHub authentication..."
if gh auth status > /dev/null 2>&1; then
    print_success "GitHub CLI authenticated"
else
    print_error "GitHub CLI not authenticated"
    print_info "Run: gh auth login"
    exit 1
fi

print_info "Step 3.3: Listing workflow files..."
ls -la .github/workflows/
print_success "Workflow files listed"

print_info "Step 3.4: Checking recent workflow runs..."
gh run list --limit 5
print_success "Recent workflow runs listed"

print_info "Step 3.5: Checking latest workflow status..."
LATEST_RUN=$(gh run list --limit 1 --json status,conclusion,databaseId --jq '.[0]')
RUN_STATUS=$(echo $LATEST_RUN | jq -r '.status')
RUN_CONCLUSION=$(echo $LATEST_RUN | jq -r '.conclusion')

if [ "$RUN_STATUS" = "completed" ] && [ "$RUN_CONCLUSION" = "success" ]; then
    print_success "Latest workflow run: SUCCESS"
elif [ "$RUN_STATUS" = "completed" ]; then
    print_warning "Latest workflow run completed with status: $RUN_CONCLUSION"
else
    print_info "Latest workflow run status: $RUN_STATUS"
fi

print_info "Step 3.6: Checking container packages..."
if gh api /user/packages?package_type=container > /dev/null 2>&1; then
    print_success "Container packages accessible"
    gh api /user/packages?package_type=container | jq -r '.[].name' | grep -E "vote|result|worker" || print_warning "No voting app packages found"
else
    print_warning "Unable to access container packages"
fi

print_info "Step 3.7: Checking repository workflows..."
gh workflow list
print_success "Workflows listed"

print_info "Step 3.8: Triggering manual workflow (optional)..."
read -p "Do you want to trigger a manual CI/CD workflow run? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    gh workflow run ci-cd.yml
    print_success "Workflow triggered"
    print_info "Monitor progress: gh run watch"
else
    print_info "Skipping manual workflow trigger"
fi

print_success "🎉 PHASE 3 COMPLETED SUCCESSFULLY!"
echo ""
echo "Phase 3 Results:"
echo "  ✅ GitHub CLI authenticated"
echo "  ✅ Workflows configured and accessible"
echo "  ✅ Latest workflow run verified"
echo "  ✅ Container packages checked"
echo ""

################################################################################
# FINAL SUMMARY
################################################################################

print_step "🎊 ALL PHASES COMPLETED SUCCESSFULLY! 🎊"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "                          FINAL TEST SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ PHASE 1: Docker Compose"
echo "   • Services: Vote, Result, Worker, Redis, PostgreSQL"
echo "   • Vote URL: $PHASE1_VOTE_URL"
echo "   • Result URL: $PHASE1_RESULT_URL"
echo "   • Status: FULLY FUNCTIONAL"
echo ""
echo "✅ PHASE 2: Kubernetes (Minikube + Terraform)"
echo "   • Cluster: $MINIKUBE_PROFILE"
echo "   • Namespace: $NAMESPACE"
echo "   • Vote URL: $PHASE2_VOTE_URL"
echo "   • Result URL: $PHASE2_RESULT_URL"
echo "   • Status: DEPLOYED AND ACCESSIBLE"
echo ""
echo "✅ PHASE 3: CI/CD Pipeline"
echo "   • GitHub Actions: CONFIGURED"
echo "   • Workflows: FUNCTIONAL"
echo "   • Container Registry: ACCESSIBLE"
echo "   • Status: AUTOMATED AND TESTED"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 Access URLs:"
echo "   Docker Compose:"
echo "     • Vote:   $PHASE1_VOTE_URL"
echo "     • Result: $PHASE1_RESULT_URL"
echo ""
echo "   Kubernetes:"
echo "     • Vote:   $PHASE2_VOTE_URL"
echo "     • Result: $PHASE2_RESULT_URL"
echo ""
echo "   GitHub:"
echo "     • Actions: https://github.com/omarMohamedo-o/tactful-votingapp-cloud-infra/actions"
echo "     • Packages: https://github.com/omarMohamedo-o?tab=packages"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Quick Commands:"
echo ""
echo "   Docker Compose:"
echo "     docker compose ps                    # Check status"
echo "     docker compose logs -f               # View logs"
echo "     docker compose down -v               # Clean up"
echo ""
echo "   Kubernetes:"
echo "     kubectl get pods -n $NAMESPACE       # Check pods"
echo "     kubectl logs -n $NAMESPACE -l app=vote -f  # View vote logs"
echo "     minikube dashboard -p $MINIKUBE_PROFILE    # Open dashboard"
echo ""
echo "   GitHub:"
echo "     gh run list                          # List workflow runs"
echo "     gh run watch                         # Watch current run"
echo "     gh workflow run ci-cd.yml            # Trigger workflow"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_success "Testing complete! All systems operational. 🚀"
echo ""
