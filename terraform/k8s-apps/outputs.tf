output "namespace" {
  description = "Kubernetes namespace"
  value       = var.namespace
}

output "vote_service" {
  description = "Vote service endpoint"
  value       = "http://vote.local"
}

output "result_service" {
  description = "Result service endpoint"
  value       = "http://result.local"
}

output "postgres_service" {
  description = "PostgreSQL service name"
  value       = kubernetes_service.postgres.metadata[0].name
}

output "redis_service" {
  description = "Redis service name"
  value       = kubernetes_service.redis.metadata[0].name
}
