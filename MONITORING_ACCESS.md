# Monitoring Access Guide

## 🎯 Quick Access to Grafana and Prometheus

This guide shows you how to access Grafana and Prometheus through AWS Load Balancers with easily identifiable names.

## 📋 Prerequisites

Monitoring must be enabled in your Terraform configuration:
```bash
# In terraform/variables.tf, ensure:
enable_monitoring = true
```

## 🚀 Deployment

### Step 1: Apply Terraform Configuration
```bash
cd terraform
terraform apply --auto-approve
```

### Step 2: Wait for Load Balancers to be Ready
```bash
# Check monitoring pods are running
kubectl get pods -n monitoring

# Check services are created
kubectl get svc -n monitoring
```

## 🔍 Finding Your Load Balancers in AWS Console

### In AWS Console:
1. Go to **EC2 > Load Balancers**
2. Look for these specific names:

| Service | Load Balancer Name | Port |
|---------|-------------------|------|
| **Grafana** | `retail-store-grafana` | 80 |
| **Prometheus** | `retail-store-prometheus` | 9090 |
| **AlertManager** | `retail-store-alertmanager` | 9093 |
| **ArgoCD** | `retail-store-argocd-server` | 80 |

### Filter by Name:
In the AWS Load Balancers console, use the search/filter:
- Type: `retail-store-grafana`
- Type: `retail-store-prometheus`

## 🌐 Getting Access URLs

### Option 1: Using Terraform Outputs
```bash
cd terraform

# Get all load balancer names
terraform output load_balancer_names

# Get Grafana URL command
terraform output grafana_url_command

# Get Prometheus URL command
terraform output prometheus_url_command

# Get credentials
terraform output grafana_credentials
```

### Option 2: Using kubectl Commands
```bash
# Get Grafana URL
echo "http://$(kubectl get svc -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

# Get Prometheus URL
echo "http://$(kubectl get svc -n monitoring kube-prometheus-stack-prometheus -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):9090"

# Get AlertManager URL
echo "http://$(kubectl get svc -n monitoring kube-prometheus-stack-alertmanager -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):9093"
```

### Option 3: Direct kubectl Query
```bash
# List all monitoring services with their external IPs
kubectl get svc -n monitoring -o wide

# Get specific service details
kubectl describe svc kube-prometheus-stack-grafana -n monitoring
```

## 🔐 Login Credentials

### Grafana
- **URL**: `http://<grafana-loadbalancer-hostname>`
- **Username**: `admin`
- **Password**: `admin123`
- ⚠️ **IMPORTANT**: Change this password in production!

### Prometheus
- **URL**: `http://<prometheus-loadbalancer-hostname>:9090`
- **Authentication**: None (add authentication for production!)

## 📊 What You'll See

### Grafana Dashboard
- Pre-configured Prometheus datasource
- Default Kubernetes monitoring dashboards
- Cluster metrics, pod metrics, node metrics
- Custom dashboard creation available

### Prometheus UI
- Metrics explorer
- Query interface (PromQL)
- Targets status
- Alerts configuration

## 🛠️ Troubleshooting

### Load Balancer Not Showing Up
```bash
# Check if service is created
kubectl get svc -n monitoring

# Check service events
kubectl describe svc kube-prometheus-stack-grafana -n monitoring

# Check if monitoring is enabled
cd terraform
terraform output monitoring_enabled
```

### Load Balancer Stuck in "Provisioning"
```bash
# Wait 2-3 minutes for AWS to provision
# Check AWS CloudFormation events
# Verify security groups allow traffic
```

### Can't Access Grafana/Prometheus
```bash
# Verify load balancer is active in AWS Console
# Check security groups allow inbound traffic on ports 80, 9090
# Try port-forwarding as alternative:
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# Then access: http://localhost:3000
```

### Wrong Load Balancer Name
```bash
# Verify cluster name
cd terraform
terraform output cluster_name_base

# Load balancer names follow pattern: {cluster_name}-{service}
# Default: retail-store-grafana, retail-store-prometheus
```

## 🔄 Alternative Access (Port Forwarding)

If you prefer not to use Load Balancers:

```bash
# Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80 &
# Access: http://localhost:3000

# Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090 &
# Access: http://localhost:9090
```

## 📝 Customization

### Change Grafana Password
Edit `terraform/addons-direct.tf`:
```hcl
grafana = {
  adminPassword = "your-secure-password-here"
}
```

### Disable Load Balancers (Use ClusterIP)
Edit `terraform/addons-direct.tf`:
```hcl
grafana = {
  service = {
    type = "ClusterIP"  # Change from LoadBalancer
  }
}
```

### Change Load Balancer Names
Edit `terraform/addons-direct.tf`:
```hcl
"service.beta.kubernetes.io/aws-load-balancer-name" = "my-custom-grafana-lb"
```

## 🔒 Security Best Practices

1. **Change Default Password**: Update Grafana admin password
2. **Enable HTTPS**: Configure SSL/TLS certificates
3. **Restrict Access**: Use security groups to limit IP ranges
4. **Enable Authentication**: Add OAuth or LDAP for Prometheus
5. **Use Internal Load Balancers**: For production, consider `internal` scheme

## 📚 Additional Resources

- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Kube-Prometheus-Stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

## 🎯 Quick Reference Commands

```bash
# Get all monitoring URLs at once
kubectl get svc -n monitoring | grep LoadBalancer

# Watch load balancer provisioning
kubectl get svc -n monitoring -w

# Get Grafana password from secret (if using auto-generated)
kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# Check monitoring stack health
kubectl get pods -n monitoring
kubectl top nodes
kubectl top pods -n monitoring
```
