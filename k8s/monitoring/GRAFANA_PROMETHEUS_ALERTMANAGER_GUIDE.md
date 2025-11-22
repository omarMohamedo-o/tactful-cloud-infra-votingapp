# Grafana, Prometheus, and Alertmanager Guide

## 📊 Creating Dashboards in Grafana

### Method 1: Import the Pre-built Voting App Dashboard

1. **Access Grafana:**

   ```bash
   xdg-open http://grafana.local
   ```

   Login: `admin` / `admin`

2. **Import Dashboard:**
   - Click **☰** (menu) → **Dashboards** → **Import**
   - Click **Upload JSON file**
   - Select: `k8s/monitoring/voting-app-dashboard.json`
   - Select datasource: **Prometheus** (default)
   - Click **Import**

3. **View Dashboard:**
   - Your custom voting app dashboard will appear with 11 panels showing:
     - Vote/Result service HTTP requests
     - Redis memory usage
     - PostgreSQL connections
     - Pod CPU/Memory usage
     - Pod replica counts

### Method 2: Create Dashboard from Scratch

1. **Create New Dashboard:**
   - Click **☰** → **Dashboards** → **New** → **New Dashboard**
   - Click **Add visualization**

2. **Configure Panel:**

   ```
   Panel Title: Pod CPU Usage
   
   Query (PromQL):
   rate(container_cpu_usage_seconds_total{namespace="voting-app",container!=""}[5m])
   
   Legend:
   {{pod}} - {{container}}
   
   Visualization: Time series (line graph)
   ```

3. **Add More Panels:**
   Click **Add** → **Visualization** and repeat

4. **Save Dashboard:**
   - Click 💾 (Save dashboard icon)
   - Enter name: "My Custom Dashboard"
   - Click **Save**

### Method 3: Import Community Dashboards

Grafana has thousands of pre-built dashboards:

1. **Browse Dashboards:**
   - Visit: <https://grafana.com/grafana/dashboards/>
   - Search for: "Kubernetes", "PostgreSQL", "Redis"

2. **Import by ID:**
   - Click **☰** → **Dashboards** → **Import**
   - Enter Dashboard ID (popular ones below)
   - Click **Load**
   - Select datasource: **Prometheus**
   - Click **Import**

**Recommended Dashboard IDs:**

- **15760** - Kubernetes Cluster Monitoring
- **1860** - Node Exporter Full
- **9628** - PostgreSQL Database
- **11835** - Redis Dashboard
- **7249** - Kubernetes Cluster (Prometheus)

---

## 📈 Creating Graphs in Prometheus

### Access Prometheus

```bash
xdg-open http://prometheus.local
```

### PromQL Query Examples

#### 1. Basic Metrics

**View all voting app pods:**

```promql
kube_pod_info{namespace="voting-app"}
```

**Pod CPU usage:**

```promql
rate(container_cpu_usage_seconds_total{namespace="voting-app"}[5m])
```

**Pod memory usage:**

```promql
container_memory_working_set_bytes{namespace="voting-app"}
```

#### 2. Vote Service Metrics

**HTTP request rate (once instrumented):**

```promql
rate(http_requests_total{job="vote-service"}[5m])
```

**HTTP request latency (p95):**

```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

#### 3. Database Metrics

**PostgreSQL connections (once exporter deployed):**

```promql
pg_stat_database_numbackends{datname="postgres"}
```

**Redis memory usage (once exporter deployed):**

```promql
redis_memory_used_bytes / redis_memory_max_bytes * 100
```

#### 4. Cluster Metrics

**Nodes CPU usage:**

```promql
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Nodes memory usage:**

```promql
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100
```

**Pod status by phase:**

```promql
count by(phase) (kube_pod_status_phase{namespace="voting-app"})
```

**Deployment replicas:**

```promql
kube_deployment_status_replicas_available{namespace="voting-app"}
```

### Using Prometheus UI

1. **Enter query** in the Expression box
2. Click **Execute** button
3. Switch between:
   - **Table** - Raw data view
   - **Graph** - Time series visualization
4. Adjust time range using picker (top right)
5. Click **Add Panel** to add to Grafana

### Query Builder Tips

- **Filters:** `{label="value"}`
- **Regex:** `{job=~"vote.*"}`
- **Multiple conditions:** `{namespace="voting-app",app="vote"}`
- **Rate (per second):** `rate(metric[5m])`
- **Increase (total):** `increase(metric[5m])`
- **Average:** `avg(metric) by (label)`
- **Sum:** `sum(metric) by (label)`

---

## 🔔 Creating Alerts in Alertmanager

### Step 1: Create Alert Rules

Create a file for Prometheus alert rules:

```bash
# Create alert rules file
cat > /home/omar/Projects/tactful-votingapp-cloud-infra/k8s/monitoring/voting-app-alerts.yaml << 'EOF'
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
    - name: voting-app-alerts
      interval: 30s
      rules:
      
      # Pod Down Alert
      - alert: VotingAppPodDown
        expr: kube_deployment_status_replicas_available{namespace="voting-app"} == 0
        for: 2m
        labels:
          severity: critical
          component: voting-app
        annotations:
          summary: "Voting App pod is down"
          description: "Deployment {{ $labels.deployment }} has no available replicas for 2 minutes"
      
      # Low Replicas Alert
      - alert: VotingAppLowReplicas
        expr: kube_deployment_status_replicas_available{namespace="voting-app",deployment=~"vote|result"} < 2
        for: 5m
        labels:
          severity: warning
          component: voting-app
        annotations:
          summary: "Low replica count for {{ $labels.deployment }}"
          description: "{{ $labels.deployment }} has only {{ $value }} replicas (expected 2)"
      
      # High Memory Usage
      - alert: HighMemoryUsage
        expr: (container_memory_working_set_bytes{namespace="voting-app",container!="",container!="POD"} / container_spec_memory_limit_bytes{namespace="voting-app"}) > 0.9
        for: 5m
        labels:
          severity: warning
          component: performance
        annotations:
          summary: "High memory usage in {{ $labels.pod }}"
          description: "Pod {{ $labels.pod }} is using {{ $value | humanizePercentage }} of its memory limit"
      
      # High CPU Usage
      - alert: HighCPUUsage
        expr: rate(container_cpu_usage_seconds_total{namespace="voting-app",container!="",container!="POD"}[5m]) > 0.8
        for: 5m
        labels:
          severity: warning
          component: performance
        annotations:
          summary: "High CPU usage in {{ $labels.pod }}"
          description: "Pod {{ $labels.pod }} CPU usage is {{ $value | humanize }}"
      
      # Pod Restart Alert
      - alert: PodFrequentlyRestarting
        expr: rate(kube_pod_container_status_restarts_total{namespace="voting-app"}[15m]) > 0
        for: 5m
        labels:
          severity: warning
          component: stability
        annotations:
          summary: "Pod {{ $labels.pod }} is restarting frequently"
          description: "Pod {{ $labels.pod }} has restarted {{ $value }} times in the last 15 minutes"
      
      # PostgreSQL Down
      - alert: PostgreSQLDown
        expr: kube_statefulset_status_replicas_ready{namespace="voting-app",statefulset="postgres"} == 0
        for: 1m
        labels:
          severity: critical
          component: database
        annotations:
          summary: "PostgreSQL is down"
          description: "PostgreSQL database has no ready replicas"
      
      # Redis Down
      - alert: RedisDown
        expr: kube_statefulset_status_replicas_ready{namespace="voting-app",statefulset="redis"} == 0
        for: 1m
        labels:
          severity: critical
          component: cache
        annotations:
          summary: "Redis is down"
          description: "Redis cache has no ready replicas"
      
      # Persistent Volume Low Space
      - alert: PersistentVolumeLowSpace
        expr: (kubelet_volume_stats_available_bytes / kubelet_volume_stats_capacity_bytes) < 0.1
        for: 10m
        labels:
          severity: warning
          component: storage
        annotations:
          summary: "PVC {{ $labels.persistentvolumeclaim }} is running low on space"
          description: "Only {{ $value | humanizePercentage }} space remaining"

EOF
```

### Step 2: Apply Alert Rules

```bash
kubectl apply -f k8s/monitoring/voting-app-alerts.yaml
```

### Step 3: Verify Alerts in Prometheus

1. **Open Prometheus:**

   ```bash
   xdg-open http://prometheus.local
   ```

2. **Check Alerts:**
   - Click **Alerts** in top menu
   - You should see all your rules listed
   - Green = OK, Red = Firing, Yellow = Pending

### Step 4: Configure Alertmanager Notifications

Create Alertmanager configuration:

```bash
cat > /home/omar/Projects/tactful-votingapp-cloud-infra/k8s/monitoring/alertmanager-config.yaml << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-prometheus-kube-prometheus-alertmanager
  namespace: monitoring
type: Opaque
stringData:
  alertmanager.yaml: |
    global:
      resolve_timeout: 5m
    
    # Route all alerts
    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'default'
      routes:
      
      # Critical alerts - immediate notification
      - match:
          severity: critical
        receiver: 'critical'
        continue: true
      
      # Warning alerts - less frequent
      - match:
          severity: warning
        receiver: 'warning'
    
    # Receivers (notification channels)
    receivers:
    
    # Default receiver (logs only)
    - name: 'default'
      # No configuration = logs only
    
    # Critical alerts receiver
    - name: 'critical'
      # Slack example (uncomment and configure)
      # slack_configs:
      # - api_url: 'YOUR_SLACK_WEBHOOK_URL'
      #   channel: '#alerts-critical'
      #   title: 'Critical Alert: {{ .GroupLabels.alertname }}'
      #   text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
      
      # Email example (uncomment and configure)
      # email_configs:
      # - to: 'ops-team@company.com'
      #   from: 'alertmanager@company.com'
      #   smarthost: 'smtp.gmail.com:587'
      #   auth_username: 'alertmanager@company.com'
      #   auth_password: 'your-password'
      #   headers:
      #     Subject: 'CRITICAL: {{ .GroupLabels.alertname }}'
    
    # Warning alerts receiver
    - name: 'warning'
      # Slack example
      # slack_configs:
      # - api_url: 'YOUR_SLACK_WEBHOOK_URL'
      #   channel: '#alerts-warning'
      #   title: 'Warning: {{ .GroupLabels.alertname }}'
    
    # Inhibit rules (prevent alert spam)
    inhibit_rules:
    - source_match:
        severity: 'critical'
      target_match:
        severity: 'warning'
      equal: ['alertname', 'namespace']

EOF
```

### Step 5: Apply Alertmanager Config

```bash
kubectl apply -f k8s/monitoring/alertmanager-config.yaml
```

### Step 6: Test Alerts

**Trigger a test alert:**

```bash
# Scale down vote service to trigger alert
kubectl scale deployment/vote --replicas=0 -n voting-app

# Wait 2 minutes, then check Alertmanager
xdg-open http://alertmanager.local

# Restore replicas
kubectl scale deployment/vote --replicas=2 -n voting-app
```

### Access Alertmanager UI

```bash
xdg-open http://alertmanager.local
```

**In Alertmanager UI:**

- **Alerts** - View active/firing alerts
- **Silences** - Mute alerts temporarily
- **Status** - View configuration

---

## 🎯 Complete Example Workflow

### 1. Create Custom Dashboard

```bash
# Access Grafana
xdg-open http://grafana.local
```

**Create dashboard with these panels:**

**Panel 1: Vote Service Requests/sec**

```promql
rate(http_requests_total{job="vote-service"}[5m])
```

**Panel 2: Active Pods**

```promql
count(kube_pod_status_phase{namespace="voting-app",phase="Running"})
```

**Panel 3: Memory Usage by Pod**

```promql
container_memory_working_set_bytes{namespace="voting-app",container!=""}
```

**Panel 4: CPU Usage %**

```promql
rate(container_cpu_usage_seconds_total{namespace="voting-app"}[5m]) * 100
```

### 2. Query Metrics in Prometheus

```bash
# Open Prometheus
xdg-open http://prometheus.local
```

**Try these queries:**

```promql
# All voting app pods
kube_pod_info{namespace="voting-app"}

# Available replicas
kube_deployment_status_replicas_available{namespace="voting-app"}

# Memory usage
container_memory_working_set_bytes{namespace="voting-app"}

# Network received bytes
rate(container_network_receive_bytes_total{namespace="voting-app"}[5m])
```

### 3. Set Up Alerts

```bash
# Apply alert rules
kubectl apply -f k8s/monitoring/voting-app-alerts.yaml

# Apply alertmanager config (optional)
kubectl apply -f k8s/monitoring/alertmanager-config.yaml

# View alerts in Prometheus
xdg-open http://prometheus.local/alerts

# View alerts in Alertmanager
xdg-open http://alertmanager.local
```

---

## 📚 Common PromQL Patterns

### Aggregation

```promql
# Sum across all pods
sum(container_memory_working_set_bytes{namespace="voting-app"})

# Average CPU by deployment
avg by(deployment) (rate(container_cpu_usage_seconds_total{namespace="voting-app"}[5m]))

# Max memory by pod
max by(pod) (container_memory_working_set_bytes{namespace="voting-app"})

# Count running pods
count(kube_pod_status_phase{namespace="voting-app",phase="Running"})
```

### Rate and Increase

```promql
# Rate of HTTP requests (per second)
rate(http_requests_total[5m])

# Total increase in 5 minutes
increase(http_requests_total[5m])

# Rate of container restarts
rate(kube_pod_container_status_restarts_total[15m])
```

### Comparison and Math

```promql
# Memory usage percentage
(container_memory_working_set_bytes / container_spec_memory_limit_bytes) * 100

# Disk usage percentage
(kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes) * 100

# Pods under limit
kube_deployment_status_replicas_available < 2
```

---

## 🔍 Troubleshooting

### Dashboard Not Showing Data

```bash
# Check Prometheus is scraping
kubectl logs -n monitoring prometheus-prometheus-kube-prometheus-prometheus-0

# Check ServiceMonitors
kubectl get servicemonitor -n voting-app
kubectl get servicemonitor -n monitoring

# Test metrics endpoint manually
kubectl run curl --image=curlimages/curl -it --rm -- \
  curl -s http://vote-service.voting-app.svc.cluster.local/metrics
```

### Alerts Not Firing

```bash
# Check alert rules are loaded
curl http://prometheus.local/api/v1/rules | jq '.data.groups[].rules[] | {alert: .name, state: .state}'

# Check Alertmanager config
kubectl get secret -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d

# View Alertmanager logs
kubectl logs -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager-0
```

### Grafana Dashboard Empty

1. **Check datasource:**
   - Click **⚙️** → **Data Sources**
   - Verify Prometheus is connected (green checkmark)
   - Click **Test** button

2. **Check time range:**
   - Ensure time range is set appropriately (top right)
   - Try "Last 1 hour" or "Last 6 hours"

3. **Check query:**
   - Edit panel → Check query syntax
   - Run query in Prometheus first to verify data exists

---

## 📖 Quick Reference

### Access URLs

```bash
Grafana:       http://grafana.local (admin/admin)
Prometheus:    http://prometheus.local
Alertmanager:  http://alertmanager.local
```

### Key Commands

```bash
# Import dashboard
./scripts/monitoring-access.sh

# View alerts
kubectl get prometheusrules -n monitoring

# Check alert status
curl -s http://prometheus.local/api/v1/rules | jq '.data.groups[].rules[] | select(.type=="alerting")'

# Silence alert (via UI)
xdg-open http://alertmanager.local/#/silences
```

### Documentation

- Grafana Docs: <https://grafana.com/docs/grafana/latest/>
- Prometheus Docs: <https://prometheus.io/docs/>
- PromQL Cheat Sheet: <https://promlabs.com/promql-cheat-sheet/>
- Alertmanager Docs: <https://prometheus.io/docs/alerting/latest/alertmanager/>

---

**🎉 You're all set!** Start by importing the pre-built dashboard, then explore Prometheus queries and create your own alerts!
