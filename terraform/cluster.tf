# Minikube Cluster Provisioning
# This uses null_resource as Minikube doesn't have an official Terraform provider
# In production with AKS, this would be azurerm_kubernetes_cluster

resource "null_resource" "minikube_cluster" {
  triggers = {
    cluster_name = var.cluster_name
    environment  = var.environment
    cpus         = var.cpus
    memory       = var.memory
  }

  # Check if minikube is installed
  provisioner "local-exec" {
    command = "which minikube || (echo 'Minikube is not installed' && exit 1)"
  }

  # Delete existing cluster if it exists
  provisioner "local-exec" {
    command    = "minikube delete -p ${var.cluster_name}-${var.environment} 2>/dev/null || true"
    on_failure = continue
  }

  # Start Minikube cluster
  provisioner "local-exec" {
    command = <<-EOT
      minikube start \
        --profile=${var.cluster_name}-${var.environment} \
        --kubernetes-version=v${var.kubernetes_version} \
        --cpus=${var.cpus} \
        --memory=${var.memory} \
        --disk-size=${var.disk_size} \
        --driver=${var.driver} \
        --embed-certs
    EOT
  }

  # Enable addons
  provisioner "local-exec" {
    command = <<-EOT
      for addon in ${join(" ", var.addons)}; do
        minikube addons enable $addon -p ${var.cluster_name}-${var.environment}
      done
    EOT
  }

  # Wait for cluster to be ready
  provisioner "local-exec" {
    command = "kubectl wait --for=condition=Ready nodes --all --timeout=300s"
  }

  # Cleanup on destroy
  provisioner "local-exec" {
    when    = destroy
    command = "minikube delete -p ${self.triggers.cluster_name}-${self.triggers.environment}"
  }
}

# Build Docker images in Minikube's Docker environment
resource "null_resource" "build_images" {
  depends_on = [null_resource.minikube_cluster]

  triggers = {
    cluster_name = var.cluster_name
    environment  = var.environment
    # Trigger rebuild when source code changes
    vote_src   = filemd5("${path.module}/../vote/app.py")
    result_src = filemd5("${path.module}/../result/server.js")
    worker_src = filemd5("${path.module}/../worker/Program.cs")
  }

  # Build vote image
  provisioner "local-exec" {
    command = <<-EOT
      eval $(minikube -p ${var.cluster_name}-${var.environment} docker-env)
      docker build -t tactful-votingapp-cloud-infra-vote:latest ${path.module}/../vote
    EOT
  }

  # Build result image
  provisioner "local-exec" {
    command = <<-EOT
      eval $(minikube -p ${var.cluster_name}-${var.environment} docker-env)
      docker build -t tactful-votingapp-cloud-infra-result:latest ${path.module}/../result
    EOT
  }

  # Build worker image
  provisioner "local-exec" {
    command = <<-EOT
      eval $(minikube -p ${var.cluster_name}-${var.environment} docker-env)
      docker build -t tactful-votingapp-cloud-infra-worker:latest ${path.module}/../worker
    EOT
  }
}

# Create namespace for the application
resource "null_resource" "create_namespace" {
  depends_on = [null_resource.minikube_cluster]

  triggers = {
    namespace = var.namespace
  }

  provisioner "local-exec" {
    command = "kubectl create namespace ${var.namespace} --dry-run=client -o yaml | kubectl apply -f -"
  }

  # Set PSA (Pod Security Admission) to baseline
  provisioner "local-exec" {
    command = <<-EOT
      kubectl label namespace ${var.namespace} \
        pod-security.kubernetes.io/enforce=baseline \
        pod-security.kubernetes.io/audit=baseline \
        pod-security.kubernetes.io/warn=baseline \
        --overwrite
    EOT
  }
}

# Display connection info (no /etc/hosts modification during terraform)
# BEST PRACTICE: Configure /etc/hosts manually AFTER deployment
# Run: ./configure-hosts.sh
resource "null_resource" "display_connection_info" {
  depends_on = [null_resource.minikube_cluster]

  provisioner "local-exec" {
    command = <<-EOT
      MINIKUBE_IP=$(minikube ip -p ${var.cluster_name}-${var.environment})
      
      echo ""
      echo "=========================================="
      echo "🌐 Minikube Ingress Configuration"
      echo "=========================================="
      echo ""
      echo "Minikube IP: $MINIKUBE_IP"
      echo ""
      echo "⚠️  /etc/hosts configuration required!"
      echo ""
      echo "After deployment completes, run:"
      echo "  ./configure-hosts.sh"
      echo ""
      echo "Or manually add to /etc/hosts:"
      echo "  $MINIKUBE_IP vote.local"
      echo "  $MINIKUBE_IP result.local"
      echo ""
      echo "Then access:"
      echo "  Vote:   http://vote.local"
      echo "  Result: http://result.local"
      echo ""
      
      echo "=========================================="
    EOT
  }
}

# Output the kubeconfig for use with kubectl
resource "local_file" "kubeconfig" {
  depends_on = [null_resource.minikube_cluster]

  content  = "" # Placeholder - actual kubeconfig is managed by minikube
  filename = "${path.module}/kubeconfig-${var.environment}"

  provisioner "local-exec" {
    command = "kubectl config view --raw > ${path.module}/kubeconfig-${var.environment}"
  }
}

# Deploy databases via Helm
resource "null_resource" "deploy_databases" {
  depends_on = [null_resource.create_namespace, null_resource.build_images]

  triggers = {
    namespace   = var.namespace
    environment = var.environment
  }

  # Add Bitnami Helm repo
  provisioner "local-exec" {
    command = "helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || true && helm repo update"
  }

  # Deploy PostgreSQL
  provisioner "local-exec" {
    command = <<-EOT
      helm upgrade --install postgresql bitnami/postgresql \
        --namespace ${var.namespace} \
        --values ${path.module}/../k8s/helm/postgresql-values-${var.environment}.yaml \
        --wait \
        --timeout 5m
    EOT
  }

  # Deploy Redis
  provisioner "local-exec" {
    command = <<-EOT
      helm upgrade --install redis bitnami/redis \
        --namespace ${var.namespace} \
        --values ${path.module}/../k8s/helm/redis-values-${var.environment}.yaml \
        --wait \
        --timeout 5m
    EOT
  }

  # Wait for databases to be ready
  provisioner "local-exec" {
    command = <<-EOT
      kubectl wait --for=condition=ready pod \
        -l app.kubernetes.io/name=postgresql \
        -n ${var.namespace} \
        --timeout=300s
      
      kubectl wait --for=condition=ready pod \
        -l app.kubernetes.io/name=redis \
        -n ${var.namespace} \
        --timeout=300s
    EOT
  }
}

# Deploy application manifests
resource "null_resource" "deploy_application" {
  depends_on = [null_resource.deploy_databases]

  triggers = {
    namespace = var.namespace
    # Trigger redeployment on manifest changes
    manifests_hash = md5(join("", [
      for f in fileset("${path.module}/../k8s/manifests", "*") :
      fileexists("${path.module}/../k8s/manifests/${f}") ? filemd5("${path.module}/../k8s/manifests/${f}") : ""
    ]))
  }

  # Deploy application manifests
  provisioner "local-exec" {
    command = <<-EOT
      kubectl apply -f ${path.module}/../k8s/manifests/01-secrets.yaml -n ${var.namespace}
      kubectl apply -f ${path.module}/../k8s/manifests/02-configmap.yaml -n ${var.namespace}
      kubectl apply -f ${path.module}/../k8s/manifests/10-rbac.yaml -n ${var.namespace}
      kubectl apply -f ${path.module}/../k8s/manifests/05-vote.yaml -n ${var.namespace}
      kubectl apply -f ${path.module}/../k8s/manifests/06-result.yaml -n ${var.namespace}
      kubectl apply -f ${path.module}/../k8s/manifests/07-worker.yaml -n ${var.namespace}
      kubectl apply -f ${path.module}/../k8s/manifests/08-network-policies.yaml -n ${var.namespace}
      kubectl apply -f ${path.module}/../k8s/manifests/09-ingress.yaml -n ${var.namespace}
    EOT
  }

  # Wait for application pods
  provisioner "local-exec" {
    command = <<-EOT
      kubectl wait --for=condition=ready pod \
        -l app=vote \
        -n ${var.namespace} \
        --timeout=300s || true
      
      kubectl wait --for=condition=ready pod \
        -l app=result \
        -n ${var.namespace} \
        --timeout=300s || true
      
      kubectl wait --for=condition=ready pod \
        -l app=worker \
        -n ${var.namespace} \
        --timeout=300s || true
    EOT
  }
}
