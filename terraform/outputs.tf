output "cluster_name" {
  description = "Name of the Minikube cluster"
  value       = "${var.cluster_name}-${var.environment}"
}

output "kubernetes_version" {
  description = "Kubernetes version"
  value       = var.kubernetes_version
}

output "namespace" {
  description = "Application namespace"
  value       = var.namespace
}

output "environment" {
  description = "Current environment"
  value       = var.environment
}

output "cluster_endpoint" {
  description = "Cluster endpoint URL"
  value       = "Run: minikube ip -p ${var.cluster_name}-${var.environment}"
}

output "ingress_urls" {
  description = "Application URLs"
  value = {
    vote   = "http://vote.local"
    result = "http://result.local"
  }
}

output "resource_config" {
  description = "Resource configuration for this environment"
  value = {
    replicas     = var.app_replicas[var.environment]
    storage_size = var.db_storage_size[var.environment]
    cpu_limit    = var.resource_limits[var.environment].cpu
    memory_limit = var.resource_limits[var.environment].memory
  }
}

output "next_steps" {
  description = "Next steps after deployment"
  value       = <<-EOT
    
    ✅ Deployment Complete!
    
    The voting application has been automatically deployed via Terraform.
    
    ⚠️  IMPORTANT: Configure /etc/hosts (one-time setup)
       Run: ./configure-hosts.sh
       
       Or manually add to /etc/hosts:
         $(minikube ip -p ${var.cluster_name}-${var.environment}) vote.local
         $(minikube ip -p ${var.cluster_name}-${var.environment}) result.local
    
    Access the application:
       Vote:   http://vote.local
       Result: http://result.local
    
    Verify deployment:
       kubectl get pods -n ${var.namespace}
       kubectl get svc -n ${var.namespace}
       kubectl get ingress -n ${var.namespace}
    
    View Helm releases:
       helm list -n ${var.namespace}
    
    Test the application:
       curl http://vote.local
       curl http://result.local
    
    Minikube commands:
       minikube status -p ${var.cluster_name}-${var.environment}
       minikube dashboard -p ${var.cluster_name}-${var.environment}
       minikube stop -p ${var.cluster_name}-${var.environment}
  EOT
}

output "deployment_status" {
  description = "Deployment components status"
  value = {
    cluster_provisioned = "✅ Minikube cluster created"
    images_built        = "✅ Docker images built in Minikube"
    databases_deployed  = "✅ PostgreSQL and Redis via Helm"
    app_deployed        = "✅ Vote, Result, and Worker services"
    ingress_configured  = "✅ Nginx ingress with vote.local and result.local"
    security_enabled    = "✅ NetworkPolicies and Pod Security Admission"
  }
}
