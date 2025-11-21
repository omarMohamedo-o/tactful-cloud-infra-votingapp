# ConfigMap for application configuration
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = var.namespace
  }

  data = {
    POSTGRES_HOST = "db"
    POSTGRES_PORT = "5432"
    REDIS_HOST    = "redis"
    REDIS_PORT    = "6379"
  }
}
