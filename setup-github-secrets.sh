#!/bin/bash

# GitHub Secrets Setup Guide
# This script helps you add required secrets to GitHub

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                   ║${NC}"
echo -e "${BLUE}║              🔐 GITHUB SECRETS SETUP ASSISTANT                    ║${NC}"
echo -e "${BLUE}║                                                                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if gh is authenticated
if ! gh auth status &>/dev/null; then
    echo -e "${RED}❌ GitHub CLI not authenticated!${NC}"
    echo "Run: gh auth login"
    exit 1
fi

echo -e "${GREEN}✓ GitHub CLI authenticated${NC}"
echo ""

# Get repository info
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo -e "${BLUE}Repository: ${YELLOW}$REPO${NC}"
echo ""

# Required secrets
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}REQUIRED SECRETS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "1. GITHUB_TOKEN (Automatic - No action needed)"
echo "   ✓ Automatically provided by GitHub Actions"
echo "   ✓ Used for: Pushing Docker images to GHCR"
echo ""
echo "2. KUBECONFIG (Required - Manual setup)"
echo "   ⚠ Needed for: Kubernetes deployments, monitoring setup"
echo "   ⚠ Used by: ci-cd.yml, deploy-monitoring.yml"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check current secrets
echo -e "${BLUE}Checking existing secrets...${NC}"
EXISTING_SECRETS=$(gh secret list 2>/dev/null | awk '{print $1}')
echo ""

if echo "$EXISTING_SECRETS" | grep -q "KUBECONFIG"; then
    echo -e "${GREEN}✓ KUBECONFIG already exists${NC}"
    echo ""
    read -p "Do you want to update KUBECONFIG? (y/n): " UPDATE_KUBE
    if [ "$UPDATE_KUBE" != "y" ]; then
        echo -e "${YELLOW}Skipping KUBECONFIG update${NC}"
        exit 0
    fi
else
    echo -e "${YELLOW}⚠ KUBECONFIG not found${NC}"
fi
echo ""

# Setup KUBECONFIG
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}KUBECONFIG SETUP${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "This secret allows GitHub Actions to deploy to your Kubernetes cluster."
echo ""
echo -e "${YELLOW}⚠ IMPORTANT SECURITY NOTES:${NC}"
echo "  • For local Minikube: NOT RECOMMENDED (cluster not accessible from GitHub)"
echo "  • For cloud clusters (AKS, EKS, GKE): Safe to use"
echo "  • For production: Use service accounts with limited permissions"
echo ""

read -p "Do you have a cloud Kubernetes cluster? (y/n): " HAS_CLOUD
echo ""

if [ "$HAS_CLOUD" != "y" ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}LOCAL MINIKUBE DETECTED${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "For Minikube (local development):"
    echo "  • GitHub Actions CANNOT reach your local cluster"
    echo "  • Deployments must be triggered manually from your machine"
    echo "  • The ci-cd.yml workflow is already configured for manual deployment"
    echo ""
    echo -e "${GREEN}✓ No KUBECONFIG secret needed for local Minikube${NC}"
    echo ""
    echo "Your workflows will:"
    echo "  ✓ Build and test automatically"
    echo "  ✓ Push images to GHCR automatically"
    echo "  ✓ Run security scans automatically"
    echo "  ⏭ Skip deployment (manual trigger only)"
    echo ""
    exit 0
fi

# Cloud cluster setup
echo -e "${BLUE}Setting up KUBECONFIG for cloud cluster...${NC}"
echo ""

echo "Select your cloud provider:"
echo "  1) Azure AKS"
echo "  2) AWS EKS"
echo "  3) Google GKE"
echo "  4) Other/Custom"
read -p "Enter choice (1-4): " CLOUD_CHOICE
echo ""

case $CLOUD_CHOICE in
    1)
        echo -e "${BLUE}Azure AKS Setup${NC}"
        echo ""
        echo "Run the following commands:"
        echo ""
        echo -e "${YELLOW}# Login to Azure${NC}"
        echo "az login"
        echo ""
        echo -e "${YELLOW}# Get AKS credentials${NC}"
        echo "az aks get-credentials --resource-group <resource-group> --name <cluster-name>"
        echo ""
        ;;
    2)
        echo -e "${BLUE}AWS EKS Setup${NC}"
        echo ""
        echo "Run the following commands:"
        echo ""
        echo -e "${YELLOW}# Configure AWS CLI${NC}"
        echo "aws configure"
        echo ""
        echo -e "${YELLOW}# Get EKS credentials${NC}"
        echo "aws eks update-kubeconfig --region <region> --name <cluster-name>"
        echo ""
        ;;
    3)
        echo -e "${BLUE}Google GKE Setup${NC}"
        echo ""
        echo "Run the following commands:"
        echo ""
        echo -e "${YELLOW}# Login to GCloud${NC}"
        echo "gcloud auth login"
        echo ""
        echo -e "${YELLOW}# Get GKE credentials${NC}"
        echo "gcloud container clusters get-credentials <cluster-name> --zone <zone>"
        echo ""
        ;;
    *)
        echo -e "${YELLOW}Custom cluster - ensure kubectl is configured${NC}"
        echo ""
        ;;
esac

# Check if kubectl is configured
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ kubectl not configured or cluster not accessible${NC}"
    echo "Please configure kubectl first, then run this script again."
    exit 1
fi

echo -e "${GREEN}✓ kubectl configured${NC}"
echo ""

# Get cluster info
CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')

echo "Cluster detected:"
echo "  Name: $CLUSTER_NAME"
echo "  Server: $CLUSTER_SERVER"
echo ""

# Create service account for GitHub Actions
echo -e "${BLUE}Creating service account for GitHub Actions...${NC}"
echo ""

cat > /tmp/github-actions-sa.yaml << 'EOF'
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

# Apply service account
kubectl apply -f /tmp/github-actions-sa.yaml

echo -e "${GREEN}✓ Service account created${NC}"
echo ""

# Create kubeconfig for service account
echo -e "${BLUE}Generating kubeconfig for service account...${NC}"
echo ""

# Get service account token
SA_SECRET=$(kubectl get sa github-actions -n voting-app -o jsonpath='{.secrets[0].name}' 2>/dev/null)

if [ -z "$SA_SECRET" ]; then
    # For Kubernetes 1.24+, create token manually
    kubectl create token github-actions -n voting-app --duration=8760h > /tmp/sa-token.txt
    SA_TOKEN=$(cat /tmp/sa-token.txt)
    rm /tmp/sa-token.txt
else
    SA_TOKEN=$(kubectl get secret "$SA_SECRET" -n voting-app -o jsonpath='{.data.token}' | base64 --decode)
fi

# Get CA certificate
kubectl get secret "$SA_SECRET" -n voting-app -o jsonpath='{.data.ca\.crt}' 2>/dev/null > /tmp/ca.crt || \
    kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 --decode > /tmp/ca.crt

CA_CRT=$(cat /tmp/ca.crt | base64 -w 0)

# Create kubeconfig
cat > /tmp/kubeconfig-github-actions.yaml << EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: $CA_CRT
    server: $CLUSTER_SERVER
  name: $CLUSTER_NAME
contexts:
- context:
    cluster: $CLUSTER_NAME
    namespace: voting-app
    user: github-actions
  name: github-actions-context
current-context: github-actions-context
users:
- name: github-actions
  user:
    token: $SA_TOKEN
EOF

echo -e "${GREEN}✓ Kubeconfig generated${NC}"
echo ""

# Base64 encode kubeconfig for GitHub secret
KUBECONFIG_BASE64=$(cat /tmp/kubeconfig-github-actions.yaml | base64 -w 0)

# Add secret to GitHub
echo -e "${BLUE}Adding KUBECONFIG secret to GitHub...${NC}"
echo ""

echo "$KUBECONFIG_BASE64" | gh secret set KUBECONFIG

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ KUBECONFIG secret added successfully!${NC}"
else
    echo -e "${RED}❌ Failed to add KUBECONFIG secret${NC}"
    echo ""
    echo "Manual setup:"
    echo "1. Copy the kubeconfig: cat /tmp/kubeconfig-github-actions.yaml | base64 -w 0"
    echo "2. Go to: https://github.com/$REPO/settings/secrets/actions"
    echo "3. Click 'New repository secret'"
    echo "4. Name: KUBECONFIG"
    echo "5. Value: Paste the base64 encoded kubeconfig"
    exit 1
fi

# Cleanup
rm -f /tmp/github-actions-sa.yaml /tmp/ca.crt /tmp/kubeconfig-github-actions.yaml

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}SETUP COMPLETE!${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Verify secrets
echo -e "${BLUE}Verifying secrets...${NC}"
gh secret list
echo ""

echo -e "${GREEN}✓ All secrets configured!${NC}"
echo ""
echo "Next steps:"
echo "  1. Push code to trigger workflows"
echo "  2. Check Actions tab: https://github.com/$REPO/actions"
echo "  3. Monitor deployments"
echo ""

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                   ║${NC}"
echo -e "${BLUE}║                    ✅ SECRETS SETUP COMPLETE                      ║${NC}"
echo -e "${BLUE}║                                                                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
