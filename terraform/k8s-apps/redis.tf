# Redis StatefulSet
resource "kubernetes_stateful_set" "redis" {
  metadata {
    name      = "redis"
    namespace = var.namespace
    labels = {
      app = "redis"
    }
  }

  spec {
    service_name = "redis"
    replicas     = 1

    selector {
      match_labels = {
        app = "redis"
      }
    }

    template {
      metadata {
        labels = {
          app = "redis"
        }
      }

      spec {
        container {
          name  = "redis"
          image = "redis:7-alpine"

          command = [
            "redis-server",
            "--requirepass",
            "$(REDIS_PASSWORD)",
            "--appendonly",
            "yes"
          ]

          port {
            container_port = 6379
            name           = "redis"
          }

          env {
            name = "REDIS_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.redis_secret.metadata[0].name
                key  = "redis-password"
              }
            }
          }

          volume_mount {
            name       = "redis-storage"
            mount_path = "/data"
          }

          liveness_probe {
            exec {
              command = ["redis-cli", "--no-auth-warning", "-a", "$(REDIS_PASSWORD)", "ping"]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            exec {
              command = ["redis-cli", "--no-auth-warning", "-a", "$(REDIS_PASSWORD)", "ping"]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          security_context {
            run_as_user                = 999
            run_as_non_root            = true
            allow_privilege_escalation = false
            read_only_root_filesystem  = false
          }
        }

        security_context {
          fs_group               = 999
          fs_group_change_policy = "OnRootMismatch"
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "redis-storage"
      }

      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "1Gi"
          }
        }
      }
    }
  }
}

# Redis Service
resource "kubernetes_service" "redis" {
  metadata {
    name      = "redis"
    namespace = var.namespace
    labels = {
      app = "redis"
    }
  }

  spec {
    selector = {
      app = "redis"
    }

    port {
      port        = 6379
      target_port = 6379
    }

    cluster_ip = "None"
    type       = "ClusterIP"
  }
}
