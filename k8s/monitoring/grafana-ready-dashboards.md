# Ready Grafana Dashboards (IDs) and Import Instructions

This file lists recommended Grafana community dashboards (IDs/UIDs) you can import quickly, plus three ways to import them:

- Grafana UI (interactive)
- Grafana HTTP API (curl)
- Kubernetes provisioning / sidecar (automated)

---

## Recommended Dashboards (IDs / Short Notes)

- Kubernetes Cluster Monitoring (Prometheus) — ID: `15760` (or search "Kubernetes Cluster Monitoring")
- Node Exporter Full — ID: `1860`
- Kubernetes / Prometheus Overview — ID: `7249`
- PostgreSQL Overview — ID: `9628`
- Redis Overview — ID: `11835`
- Docker & Containers (optional) — ID: `1229`

Note: Grafana dashboard pages sometimes list both numeric ID and a UID string. The numeric ID works in the UI; use the UID or the grafana.com API to fetch JSON programmatically.

---

## 1) Import via Grafana UI (Quick, manual)

1. Open Grafana: `http://grafana.local` (login: `admin` / `admin`)
2. Click ☰ → Dashboards → Import
3. Either:
   - Enter the numeric Dashboard ID (e.g., `15760`) and click **Load**, or
   - Upload a JSON file (if you already downloaded one)
4. Choose the Prometheus datasource and click **Import**

This is the fastest way for a few dashboards.

---

## 2) Import programmatically via Grafana HTTP API (curl)

You can fetch a dashboard JSON from grafana.com and POST it to your Grafana instance. Public dashboards are accessible at `https://grafana.com/api/dashboards/uid/<UID>` and many dashboards also provide a numeric ID page.

Example workflow (replace values as needed):

1) Fetch dashboard JSON from grafana.com

```bash
# Example: fetch dashboard JSON by numeric ID page (you may need UID instead)
# Use the dashboard page to get the UID or use the shorthand API
# Example using UID endpoint (replace <UID> with actual UID from grafana.com):
curl -s "https://grafana.com/api/dashboards/uid/<UID>" -o dashboard.json

# If the response is wrapped, extract .dashboard
jq '.dashboard' dashboard.json > dashboard-only.json
```

2) Post to your Grafana (requires admin credentials)

```bash
GRAFANA_URL="http://grafana.local"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"

curl -s -X POST "$GRAFANA_URL/api/dashboards/db" \
  -H "Content-Type: application/json" \
  -u "$GRAFANA_USER:$GRAFANA_PASS" \
  -d @dashboard-only.json
```

If successful, the API returns metadata about the imported dashboard.

Tip: you can script downloading multiple dashboards and importing in a loop.

---

## 3) Automate import using Grafana provisioning or a sidecar

Two common patterns for automated imports in Kubernetes:

A) Grafana provisioning (ConfigMap + provisioning file)

- Create a ConfigMap with dashboard JSON files and a provisioning YAML that points Grafana to load them on startup.

Example provisioning config (create `grafana-dashboards-config.yaml`):

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards
  namespace: monitoring
data:
  my-k8s-dashboard.json: |
    { ... entire dashboard JSON ... }

# Provisioning config
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-provisioning-dashboards
  namespace: monitoring
data:
  dashboards.yaml: |
    apiVersion: 1
    providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        options:
          path: /var/lib/grafana/dashboards
```

Then mount the `grafana-dashboards` ConfigMap into the Grafana deployment at `/var/lib/grafana/dashboards` and the provisioning ConfigMap at `/etc/grafana/provisioning/dashboards`. Grafana will auto-load dashboards at startup.

B) Grafana sidecar (recommended with kube-prometheus-stack)

- If your Grafana has the configmap sidecar enabled (many helm charts do), you can create a ConfigMap with `grafana-dashboard=1` label and Grafana will auto-import it.

Example:

```bash
kubectl create configmap voting-app-dashboard \
  --from-file=voting-app-dashboard.json=k8s/monitoring/voting-app-dashboard.json \
  -n monitoring
kubectl label configmap voting-app-dashboard grafana_dashboard=1 -n monitoring
```

The Grafana sidecar will detect and import the dashboard automatically.

---

## Example: Script to import multiple dashboards via Grafana API

```bash
#!/usr/bin/env bash
set -euo pipefail

GRAFANA_URL="http://grafana.local"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"

# Array of grafana.com UIDs or file paths
DASH_UIDS=("<UID1>" "<UID2>" "<UID3>")

for UID in "${DASH_UIDS[@]}"; do
  echo "Fetching dashboard $UID from grafana.com"
  curl -s "https://grafana.com/api/dashboards/uid/$UID" -o /tmp/$UID.json
  jq '.dashboard' /tmp/$UID.json > /tmp/$UID-dashboard.json

  echo "Importing $UID into Grafana"
  curl -s -X POST "$GRAFANA_URL/api/dashboards/db" \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASS" \
    -d @/tmp/$UID-dashboard.json | jq .
done
```

---

## Notes & Tips

- When importing, ensure the Prometheus datasource in Grafana is named exactly as your import expects (often `Prometheus`). If not, edit the dashboard to use your datasource.
- Using UIDs is more stable than numeric IDs because numeric IDs can change across grafana.com.
- For production, prefer provisioning/sidecar approach so dashboards are version-controlled (store JSON in git).
- If dashboards require specific panels or templates, verify PromQL queries first in Prometheus Explore.

---

If you'd like, I can:

- Add these recommended dashboard IDs directly to `k8s/monitoring/README.md` or `PHASE4_SUMMARY.md`.
- Create a script that downloads and auto-imports the dashboards into your Grafana instance.
- Create ConfigMap examples to enable Grafana sidecar auto-import for these dashboards.

Which of these would you like me to do next?
