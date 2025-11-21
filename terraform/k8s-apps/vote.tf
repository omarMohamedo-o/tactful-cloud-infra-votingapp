# Vote Application Deployment
resource "kubernetes_deployment" "vote" {
  metadata {
    name      = "vote"
    namespace = var.namespace
    labels = {
      app = "vote"
    }
  }

  spec {
    replicas = var.vote_replicas

    selector {
      match_labels = {
        app = "vote"
      }
    }

    template {
      metadata {
        labels = {
          app = "vote"
        }
      }

      spec {
        container {
          name              = "vote"
          image             = var.vote_image
          image_pull_policy = "Never"

          port {
            container_port = 80
          }

          env {
            name  = "REDIS_HOST"
            value = "redis"
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

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 15
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
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

# Vote Service
resource "kubernetes_service" "vote" {
  metadata {
    name      = "vote"
    namespace = var.namespace
    labels = {
      app = "vote"
    }
  }

  spec {
    selector = {
      app = "vote"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}
