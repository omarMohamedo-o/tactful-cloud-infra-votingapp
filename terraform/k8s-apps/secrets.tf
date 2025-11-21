# Kubernetes Secrets for PostgreSQL and Redis
resource "kubernetes_secret" "postgres_secret" {
  metadata {
    name      = "postgres-secret"
    namespace = var.namespace
  }

  data = {
    postgres-user     = var.postgres_user
    postgres-password = var.postgres_password
    postgres-db       = var.postgres_db
  }

  type = "Opaque"
}

resource "kubernetes_secret" "redis_secret" {
  metadata {
    name      = "redis-secret"
    namespace = var.namespace
  }

  data = {
    redis-password = var.redis_password
  }

  type = "Opaque"
}
