# Result Application Deployment
resource "kubernetes_deployment" "result" {
  metadata {
    name      = "result"
    namespace = var.namespace
    labels = {
      app = "result"
    }
  }

  spec {
    replicas = var.result_replicas

    selector {
      match_labels = {
        app = "result"
      }
    }

    template {
      metadata {
        labels = {
          app = "result"
        }
      }

      spec {
        container {
          name              = "result"
          image             = var.result_image
          image_pull_policy = "Never"

          port {
            container_port = 4000
          }

          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_secret.metadata[0].name
                key  = "postgres-user"
              }
            }
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_secret.metadata[0].name
                key  = "postgres-password"
              }
            }
          }

          env {
            name = "POSTGRES_DB"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_secret.metadata[0].name
                key  = "postgres-db"
              }
            }
          }

          env {
            name  = "POSTGRES_HOST"
            value = "db"
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 4000
            }
            initial_delay_seconds = 15
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 4000
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
            run_as_user                = 1000
            run_as_non_root            = true
            allow_privilege_escalation = false
            read_only_root_filesystem  = false

            capabilities {
              drop = ["ALL"]
            }
          }
        }

        security_context {
          fs_group               = 1000
          fs_group_change_policy = "OnRootMismatch"
        }
      }
    }
  }
}

# Result Service
resource "kubernetes_service" "result" {
  metadata {
    name      = "result"
    namespace = var.namespace
    labels = {
      app = "result"
    }
  }

  spec {
    selector = {
      app = "result"
    }

    port {
      port        = 4000
      target_port = 4000
    }

    type = "ClusterIP"
  }
}
