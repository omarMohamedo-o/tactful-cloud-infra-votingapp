#!/bin/bash

# Voting App Monitoring - Quick Access Script
# Phase 4: Monitoring & Observability

set -e

MINIKUBE_PROFILE="voting-app-dev"
MINIKUBE_IP=$(minikube ip -p $MINIKUBE_PROFILE 2>/dev/null || echo "192.168.49.2")

echo "=========================================="
echo "  Voting App Monitoring - Quick Access"
echo "=========================================="
echo ""

# Check cluster status
echo "🔍 Checking cluster status..."
if ! minikube status -p $MINIKUBE_PROFILE &>/dev/null; then
    echo "❌ Minikube cluster '$MINIKUBE_PROFILE' is not running!"
    echo "   Start it with: minikube start -p $MINIKUBE_PROFILE"
    exit 1
fi
echo "✅ Cluster is running at $MINIKUBE_IP"
echo ""

# Check monitoring pods
echo "📊 Monitoring Stack Status:"
TOTAL_PODS=$(kubectl get pods -n monitoring --no-headers 2>/dev/null | wc -l)
RUNNING_PODS=$(kubectl get pods -n monitoring --no-headers 2>/dev/null | grep -c "Running" || echo "0")
echo "   Pods: $RUNNING_PODS/$TOTAL_PODS Running"
echo ""

# Check ServiceMonitors
APP_SM=$(kubectl get servicemonitor -n voting-app --no-headers 2>/dev/null | wc -l)
CLUSTER_SM=$(kubectl get servicemonitor -n monitoring --no-headers 2>/dev/null | wc -l)
echo "📈 ServiceMonitors:"
echo "   Voting App: $APP_SM"
echo "   Cluster: $CLUSTER_SM"
echo ""

# Get Grafana password
echo "🔑 Grafana Credentials:"
echo "   Username: admin"
GRAFANA_PASSWORD=$(kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" 2>/dev/null | base64 -d)
echo "   Password: $GRAFANA_PASSWORD"
echo ""

# Check web access
echo "🌐 Web Interfaces:"
echo "   Grafana:      http://grafana.local (HTTP $(curl -s -o /dev/null -w '%{http_code}' http://grafana.local 2>/dev/null || echo 'N/A'))"
echo "   Prometheus:   http://prometheus.local (HTTP $(curl -s -o /dev/null -w '%{http_code}' http://prometheus.local 2>/dev/null || echo 'N/A'))"
echo "   Alertmanager: http://alertmanager.local (HTTP $(curl -s -o /dev/null -w '%{http_code}' http://alertmanager.local 2>/dev/null || echo 'N/A'))"
echo ""

# Check voting app
echo "🗳️  Voting Application:"
echo "   Vote:   http://vote.local (HTTP $(curl -s -o /dev/null -w '%{http_code}' http://vote.local 2>/dev/null || echo 'N/A'))"
echo "   Result: http://result.local (HTTP $(curl -s -o /dev/null -w '%{http_code}' http://result.local 2>/dev/null || echo 'N/A'))"
echo ""

# Quick actions
echo "=========================================="
echo "  Quick Actions"
echo "=========================================="
echo ""
echo "1. Open Grafana in browser:"
echo "   xdg-open http://grafana.local"
echo ""
echo "2. Open Prometheus in browser:"
echo "   xdg-open http://prometheus.local"
echo ""
echo "3. Import voting app dashboard:"
echo "   - Login to Grafana (admin/$GRAFANA_PASSWORD)"
echo "   - Click + → Import"
echo "   - Upload: k8s/monitoring/voting-app-dashboard.json"
echo ""
echo "4. View monitoring pod logs:"
echo "   kubectl logs -n monitoring -l app.kubernetes.io/name=grafana"
echo "   kubectl logs -n monitoring prometheus-prometheus-kube-prometheus-prometheus-0"
echo ""
echo "5. Port forward (if ingress not working):"
echo "   kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo ""
echo "=========================================="

# Ask if user wants to open Grafana
read -p "Open Grafana in browser now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    xdg-open http://grafana.local 2>/dev/null || open http://grafana.local 2>/dev/null || echo "Please open http://grafana.local manually"
fi
