# =============================================================================
# DIRECT HELM RELEASES FOR EKS ADD-ONS
# Alternative to eks-blueprints-addons module
# =============================================================================

# =============================================================================
# CERT-MANAGER
# =============================================================================
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = "v1.13.3"

  # Cleanup settings for reliable destroy
  cleanup_on_fail = true
  force_update    = true
  wait            = true
  timeout         = 600

  # Ensure clean destroy
  wait_for_jobs    = false
  disable_webhooks = true

  values = [
    yamlencode({
      installCRDs = true
    })
  ]

  depends_on = [module.retail_app_eks]
}

# =============================================================================
# NGINX INGRESS CONTROLLER
# =============================================================================
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = "4.8.3"

  # Cleanup settings for reliable destroy
  cleanup_on_fail = true
  wait            = true
  timeout         = 600

  # Ensure clean destroy
  wait_for_jobs = false

  values = [
    yamlencode({
      controller = {
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type"   = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
          }
        }
      }
    })
  ]

  depends_on = [module.retail_app_eks]
}

# =============================================================================
# PROMETHEUS STACK (Optional - Disabled by default)
# =============================================================================
resource "helm_release" "kube_prometheus_stack" {
  count = var.enable_monitoring ? 1 : 0

  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  version          = "55.5.0"

  # Cleanup settings for reliable destroy
  cleanup_on_fail = true
  wait            = false # Don't wait for all resources to be ready
  timeout         = 1800  # Increased to 30 minutes

  # Ensure clean destroy
  wait_for_jobs = false
  replace       = true
  atomic        = false # Don't rollback on failure

  values = [
    yamlencode({
      # Disable some components for faster deployment
      kubeStateMetrics = {
        enabled = true
      }
      nodeExporter = {
        enabled = true
      }

      # Prometheus configuration
      prometheus = {
        prometheusSpec = {
          retention = "7d"
          resources = {
            requests = {
              cpu    = "200m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "2Gi"
            }
          }
        }
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type"   = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
            "service.beta.kubernetes.io/aws-load-balancer-name"   = "${var.cluster_name}-prometheus"
          }
        }
      }

      # Grafana configuration
      grafana = {
        enabled       = true
        adminPassword = "admin123" # Change this in production!
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type"   = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
            "service.beta.kubernetes.io/aws-load-balancer-name"   = "${var.cluster_name}-grafana"
          }
        }
        # Pre-configure Prometheus datasource
        datasources = {
          "datasources.yaml" = {
            apiVersion = 1
            datasources = [
              {
                name      = "Prometheus"
                type      = "prometheus"
                url       = "http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090"
                access    = "proxy"
                isDefault = true
              }
            ]
          }
        }
      }

      # AlertManager configuration (optional)
      alertmanager = {
        enabled = true
        alertmanagerSpec = {
          resources = {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type"   = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
            "service.beta.kubernetes.io/aws-load-balancer-name"   = "${var.cluster_name}-alertmanager"
          }
        }
      }
    })
  ]

  depends_on = [module.retail_app_eks]
}
