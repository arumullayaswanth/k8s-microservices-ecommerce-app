# =============================================================================
# OUTPUT VALUES
# =============================================================================

# =============================================================================
# CLUSTER INFORMATION
# =============================================================================

output "cluster_name" {
  description = "Name of the EKS cluster (with unique suffix)"
  value       = module.retail_app_eks.cluster_name
}

output "cluster_name_base" {
  description = "Base cluster name without suffix"
  value       = var.cluster_name
}

output "cluster_name_suffix" {
  description = "Random suffix added to cluster name"
  value       = random_string.suffix.result
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.retail_app_eks.cluster_endpoint
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = module.retail_app_eks.cluster_version
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.retail_app_eks.cluster_security_group_id
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.retail_app_eks.cluster_oidc_issuer_url
}

# =============================================================================
# NETWORK INFORMATION
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC where the cluster is deployed"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

# =============================================================================
# ACCESS INFORMATION
# =============================================================================

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.retail_app_eks.cluster_name}"
}

output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = var.argocd_namespace
}

output "argocd_server_port_forward" {
  description = "Command to port-forward to ArgoCD server (alternative to LoadBalancer)"
  value       = "kubectl port-forward svc/argocd-server -n ${var.argocd_namespace} 8080:443"
}

output "argocd_loadbalancer_url" {
  description = "Command to get ArgoCD LoadBalancer URL"
  value       = "kubectl get svc -n ${var.argocd_namespace} argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "argocd_url" {
  description = "Command to get the full ArgoCD URL"
  value       = "echo 'http://'$(kubectl get svc -n ${var.argocd_namespace} argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
}

output "argocd_admin_password" {
  description = "Command to get ArgoCD admin password"
  value       = "kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  sensitive   = true
}

# =============================================================================
# APPLICATION ACCESS
# =============================================================================

output "ingress_nginx_loadbalancer" {
  description = "Command to get the LoadBalancer URL for accessing applications"
  value       = "kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "retail_store_url" {
  description = "Command to get the retail store application URL"
  value       = "echo 'http://'$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
}

# =============================================================================
# USEFUL COMMANDS
# =============================================================================

output "useful_commands" {
  description = "Useful commands for managing the cluster"
  value = {
    get_nodes        = "kubectl get nodes"
    get_pods_all     = "kubectl get pods -A"
    get_retail_store = "kubectl get pods -n retail-store"
    argocd_apps      = "kubectl get applications -n ${var.argocd_namespace}"
    ingress_status   = "kubectl get ingress -A"
    describe_cluster = "kubectl cluster-info"
  }
}

# =============================================================================
# MONITORING OUTPUTS
# =============================================================================

output "monitoring_enabled" {
  description = "Whether monitoring stack is enabled"
  value       = var.enable_monitoring
}

output "prometheus_loadbalancer_command" {
  description = "Command to get Prometheus LoadBalancer URL"
  value       = var.enable_monitoring ? "kubectl get svc -n monitoring kube-prometheus-stack-prometheus -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'" : "Monitoring not enabled. Set enable_monitoring=true"
}

output "grafana_loadbalancer_command" {
  description = "Command to get Grafana LoadBalancer URL"
  value       = var.enable_monitoring ? "kubectl get svc -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'" : "Monitoring not enabled. Set enable_monitoring=true"
}

output "grafana_url_command" {
  description = "Command to get the full Grafana URL"
  value       = var.enable_monitoring ? "echo 'http://'$(kubectl get svc -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')" : "Monitoring not enabled"
}

output "prometheus_url_command" {
  description = "Command to get the full Prometheus URL"
  value       = var.enable_monitoring ? "echo 'http://'$(kubectl get svc -n monitoring kube-prometheus-stack-prometheus -o jsonpath='{.status.loadBalancer.ingress[0].hostname}':9090)" : "Monitoring not enabled"
}

output "alertmanager_loadbalancer_command" {
  description = "Command to get Alertmanager LoadBalancer URL"
  value       = var.enable_monitoring ? "kubectl get svc -n monitoring kube-prometheus-stack-alertmanager -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'" : "Monitoring not enabled. Set enable_monitoring=true"
}

output "alertmanager_url_command" {
  description = "Command to get the full Alertmanager URL"
  value       = var.enable_monitoring ? "echo 'http://'$(kubectl get svc -n monitoring kube-prometheus-stack-alertmanager -o jsonpath='{.status.loadBalancer.ingress[0].hostname}':9093)" : "Monitoring not enabled"
}

output "grafana_credentials" {
  description = "Grafana login credentials"
  value       = var.enable_monitoring ? "Username: admin | Password: admin123 (CHANGE THIS IN PRODUCTION!)" : "Monitoring not enabled"
}

output "load_balancer_names" {
  description = "AWS Load Balancer names for easy identification in AWS Console"
  value = {
    argocd       = "${var.cluster_name}-argocd-server"
    ingress      = "Managed by ingress-nginx (check EC2 > Load Balancers)"
    prometheus   = var.enable_monitoring ? "${var.cluster_name}-prometheus" : "Not enabled"
    grafana      = var.enable_monitoring ? "${var.cluster_name}-grafana" : "Not enabled"
    alertmanager = var.enable_monitoring ? "${var.cluster_name}-alertmanager" : "Not enabled"
  }
}

output "monitoring_commands" {
  description = "Useful commands for monitoring stack"
  value = var.enable_monitoring ? {
    get_monitoring_pods     = "kubectl get pods -n monitoring"
    get_monitoring_services = "kubectl get svc -n monitoring"
    port_forward_grafana    = "kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
    port_forward_prometheus = "kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090"
  } : {}
}

# =============================================================================
# DESTROY HELPER
# =============================================================================

output "destroy_instructions" {
  description = "Instructions for clean destruction of all resources"
  value       = <<-EOT
    To destroy all resources cleanly, run these commands in order:
    
    1. First, configure kubectl:
       aws eks update-kubeconfig --region ${var.aws_region} --name ${module.retail_app_eks.cluster_name}
    
    2. Delete all ArgoCD applications (to prevent them from recreating resources):
       kubectl delete applications.argoproj.io --all -n ${var.argocd_namespace} --timeout=60s
    
    3. Delete all LoadBalancer services (to clean up AWS load balancers):
       kubectl delete svc --all-namespaces --field-selector spec.type=LoadBalancer --timeout=60s
    
    4. Wait 30 seconds for AWS to clean up load balancers
    
    5. Run terraform destroy:
       terraform destroy -auto-approve
    
    OR simply run: terraform destroy -auto-approve
    (The cleanup scripts are now automated in the Terraform configuration)
  EOT
}
