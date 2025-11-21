# Ingress for Vote and Result applications
resource "kubernetes_ingress_v1" "voting_app" {
  metadata {
    name      = "voting-app-ingress"
    namespace = var.namespace
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    rule {
      host = "vote.local"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.vote.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    rule {
      host = "result.local"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.result.metadata[0].name
              port {
                number = 4000
              }
            }
          }
        }
      }
    }
  }
}
