# Monitoring & Observability - Phase 4

## 🎯 Overview

This directory contains the monitoring stack configuration for the Voting Application, deployed using the **kube-prometheus-stack** Helm chart.

## 📊 Components Deployed

| Component | Purpose | Access URL |
|-----------|---------|------------|
| **Grafana** | Metrics visualization and dashboarding | <http://grafana.local> |
| **Prometheus** | Metrics collection and storage | <http://prometheus.local> |
| **Alertmanager** | Alert routing and notifications | <http://alertmanager.local> |
| **Node Exporter** | Host-level metrics (CPU, memory, disk) | (Internal) |
| **Kube State Metrics** | Kubernetes object metrics | (Internal) |

## 🔑 Default Credentials

- **Grafana**:
  - Username: `admin`
  - Password: `admin`

## 📈 Metrics Collection

### Application ServiceMonitors

Four ServiceMonitors scrape metrics from the voting application every 30 seconds:

1. **vote-service** (Python Flask)
   - Endpoint: `http://vote-service:80/metrics`
   - Metrics: HTTP requests, response times, Python runtime

2. **result-service** (Node.js)
   - Endpoint: `http://result-service:80/metrics`
   - Metrics: HTTP requests, Node.js event loop, memory

3. **redis-service** (Redis)
   - Endpoint: `http://redis-service:6379/metrics`
   - Metrics: Memory usage, commands, connections

4. **postgres-service** (PostgreSQL)
   - Endpoint: `http://postgres-service:5432/metrics`
   - Metrics: Connections, transactions, database size

### Cluster ServiceMonitors

The kube-prometheus-stack automatically deploys 9 ServiceMonitors for comprehensive cluster monitoring:

- API Server
- CoreDNS
- Kubelet
- Kube State Metrics
- Node Exporter
- Prometheus Operator
- Prometheus itself
- Grafana
- Alertmanager

## 🚀 Quick Start

### 1. Access Grafana

```bash
# Open Grafana in your browser
xdg-open http://grafana.local

# Or manually navigate to: http://grafana.local
# Login: admin / admin
```

### 2. Import Voting App Dashboard

**Option A: Via Grafana UI**

1. Login to Grafana (admin/admin)
2. Click **+ → Import** in the left sidebar
3. Click **Upload JSON file**
4. Select: `k8s/monitoring/voting-app-dashboard.json`
5. Select datasource: **Prometheus**
6. Click **Import**

**Option B: Via ConfigMap (Automated)**

```bash
# Create ConfigMap with dashboard
kubectl create configmap voting-app-dashboard \
  --from-file=voting-app-dashboard.json=k8s/monitoring/voting-app-dashboard.json \
  -n monitoring \
  --dry-run=client -o yaml | kubectl apply -f -

# Label it for Grafana sidecar auto-discovery
kubectl label configmap voting-app-dashboard \
  grafana_dashboard=1 \
  -n monitoring

# Wait ~30 seconds for Grafana to auto-load the dashboard
```

### 3. Verify Prometheus Targets

```bash
# Open Prometheus UI
xdg-open http://prometheus.local

# Or check targets via API
curl -s http://prometheus.local/api/v1/targets | jq '.data.activeTargets[] | select(.labels.namespace=="voting-app") | {job: .labels.job, health: .health, lastScrape: .lastScrape}'
```

### 4. Access Alertmanager

```bash
# Open Alertmanager UI
xdg-open http://alertmanager.local
```

## 📊 Dashboard Panels

The `voting-app-dashboard.json` includes:

### Application Metrics

- **Vote Service HTTP Requests** - Request rate per endpoint
- **Result Service HTTP Requests** - Request rate per endpoint
- **Redis Memory Usage** - Current vs max memory
- **PostgreSQL Connections** - Active database connections

### Resource Metrics

- **Pod CPU Usage** - CPU usage per pod/container
- **Pod Memory Usage** - Memory usage per pod/container

### Status Panels

- **Running Pods** - Total pods in Running state
- **Vote Replicas** - Available vote pod replicas
- **Result Replicas** - Available result pod replicas
- **Worker Replicas** - Available worker pod replicas

## 🔧 Configuration Files

### prometheus-values-dev.yaml

Helm values for development environment:

- **Prometheus Retention**: 7 days
- **Prometheus Storage**: 10Gi
- **Alertmanager Retention**: 120 hours
- **Grafana Storage**: 5Gi
- **ServiceMonitor Selection**: Discovers all ServiceMonitors (not just Helm-managed)

### voting-app-servicemonitors.yaml

ServiceMonitor definitions for the 4 voting app services:

- Namespace: `voting-app`
- Scrape Interval: 30s
- Metrics Path: Auto-detected per service

### ingress.yaml

Ingress routes for monitoring UIs:

- `grafana.local` → `prometheus-grafana:80`
- `prometheus.local` → `prometheus-kube-prometheus-prometheus:9090`
- `alertmanager.local` → `prometheus-kube-prometheus-alertmanager:9093`

## 🛠️ Useful Commands

### Check Monitoring Stack Status

```bash
# All monitoring resources
kubectl get all,ingress,servicemonitor -n monitoring

# Pod status
kubectl get pods -n monitoring -w

# ServiceMonitor status (voting app)
kubectl get servicemonitor -n voting-app

# ServiceMonitor status (cluster)
kubectl get servicemonitor -n monitoring
```

### View Logs

```bash
# Prometheus logs
kubectl logs -n monitoring prometheus-prometheus-kube-prometheus-prometheus-0

# Grafana logs
kubectl logs -n monitoring deployment/prometheus-grafana

# Alertmanager logs
kubectl logs -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager-0
```

### Get Grafana Admin Password

```bash
kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d && echo
```

### Port Forward (Alternative Access)

If Ingress is not working:

```bash
# Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Alertmanager
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
```

## 🧪 Testing Metrics

### Generate Load on Vote Service

```bash
# Send votes using curl
for i in {1..100}; do
  curl -X POST http://vote.local/ \
    -d "vote=a" \
    -H "Content-Type: application/x-www-form-urlencoded" &
done
```

### Check Metrics Directly

```bash
# Vote service metrics (if exposed)
curl -s http://vote.local/metrics

# Redis metrics (via exporter)
kubectl exec -n voting-app redis-0 -- redis-cli INFO stats
```

## 🔔 Alerting (Optional)

### Example Alert Rules

Create a file `k8s/monitoring/voting-app-alerts.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: voting-app-alerts
  namespace: monitoring
  labels:
    prometheus: kube-prometheus
data:
  voting-app.rules: |
    groups:
    - name: voting-app
      interval: 30s
      rules:
      - alert: VotingAppPodDown
        expr: kube_deployment_status_replicas_available{namespace="voting-app"} < 1
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Voting App pod is down"
          description: "{{ $labels.deployment }} has no available replicas"
      
      - alert: HighMemoryUsage
        expr: container_memory_working_set_bytes{namespace="voting-app"} / container_spec_memory_limit_bytes{namespace="voting-app"} > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
          description: "{{ $labels.pod }} is using {{ $value | humanizePercentage }} of memory"
```

Apply:

```bash
kubectl apply -f k8s/monitoring/voting-app-alerts.yaml
```

## 📝 Retention & Storage

| Component | Retention Period | Storage Size |
|-----------|------------------|--------------|
| Prometheus | 7 days | 10Gi |
| Alertmanager | 120 hours (5 days) | Default |
| Grafana | Unlimited | 5Gi |

## 🐛 Troubleshooting

### ServiceMonitor Not Discovered

```bash
# Check if Prometheus found the ServiceMonitor
kubectl logs -n monitoring prometheus-prometheus-kube-prometheus-prometheus-0 | grep -i servicemonitor

# Verify selector matches
kubectl get servicemonitor -n voting-app -o yaml | grep -A5 selector
```

### Metrics Not Appearing

```bash
# Check if services have metrics endpoints
kubectl get svc -n voting-app

# Test scraping manually
kubectl run curl --image=curlimages/curl -it --rm --restart=Never -- \
  curl -s http://vote-service.voting-app.svc.cluster.local/metrics
```

### Ingress Not Working

```bash
# Check ingress status
kubectl get ingress -n monitoring -o wide

# Check NGINX controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Verify /etc/hosts entries
cat /etc/hosts | grep "192.168.49.2"
```

## 🎓 Next Steps

1. **Explore Pre-built Dashboards**
   - Go to Grafana → Dashboards
   - Browse Kubernetes cluster dashboards (auto-imported)

2. **Configure Alertmanager**
   - Set up notification channels (Email, Slack, PagerDuty)
   - Create alert routing rules

3. **Custom Metrics**
   - Instrument vote/result/worker with Prometheus client libraries
   - Expose business metrics (vote count, processing latency)

4. **Long-term Storage**
   - Consider remote write to Thanos, Cortex, or Mimir for multi-cluster/long-term storage

## 📚 References

- [kube-prometheus-stack Documentation](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Prometheus Operator](https://prometheus-operator.dev/)
- [Grafana Documentation](https://grafana.com/docs/)
- [ServiceMonitor Spec](https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.ServiceMonitor)
