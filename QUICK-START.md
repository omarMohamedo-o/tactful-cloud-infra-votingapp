# 🚀 Quick Start Guide

## One-Command Terraform Deployment

```bash
# 1. Deploy infrastructure
cd terraform
terraform init
terraform apply -auto-approve

# 2. Configure /etc/hosts (one-time, requires sudo password once)
cd ..
./configure-hosts.sh

# 3. Test the application
kubectl get pods -n voting-app
curl http://vote.local
curl http://result.local

# 4. Generate test data (optional)
cd terraform
terraform apply -var="run_seed=true" -target=null_resource.run_seed -auto-approve
```

**Simple and secure - no sudoers modification needed!** ✨

That's it! Terraform handles everything automatically.

---

## What Gets Deployed?

✅ **Minikube Cluster**

- Kubernetes 1.28.3
- Nginx ingress enabled
- Metrics server for HPA

✅ **Infrastructure**

- PostgreSQL 15 (Helm)
- Redis 7 (Helm)
- Namespace with Pod Security Admission

✅ **Applications**

- Vote (Python/Flask) - 2 replicas
- Result (Node.js/Express) - 2 replicas  
- Worker (.NET 8) - 1 replica

✅ **Security**

- RBAC with ServiceAccounts
- Network Policies (zero-trust)
- Non-root containers

✅ **Networking**

- Ingress: vote.local, result.local
- Auto-configured /etc/hosts

---

## Access Your Application

Once deployment completes:

- **Vote:** <http://vote.local>
- **Result:** <http://result.local>

---

## Verify Everything Works

```bash
# Check all pods are running
kubectl get pods -n voting-app

# Should show:
# NAME                      READY   STATUS    RESTARTS   AGE
# postgresql-0              1/1     Running   0          5m
# redis-master-0            1/1     Running   0          4m
# vote-xxx-xxx              1/1     Running   0          3m
# vote-xxx-xxx              1/1     Running   0          3m
# result-xxx-xxx            1/1     Running   0          3m
# result-xxx-xxx            1/1     Running   0          3m
# worker-xxx-xxx            1/1     Running   0          3m

# Test vote endpoint
curl http://vote.local | grep -i "cats\|dogs"

# Test result endpoint
curl http://result.local | grep -i "result"
```

---

## Alternative: Minikube Script (with all optimizations)

For the full experience with HPA, PDB, cert-manager, and monitoring:

```bash
./setup-complete-minikube.sh
```

This includes:

- ✅ Horizontal Pod Autoscaling
- ✅ Pod Disruption Budgets
- ✅ HTTPS with cert-manager
- ✅ Prometheus + Grafana monitoring
- ✅ 40+ infrastructure tests

---

## Common Commands

```bash
# View all resources
kubectl get all -n voting-app

# Check HPA status
kubectl get hpa -n voting-app

# View pod disruption budgets
kubectl get pdb -n voting-app

# Check network policies
kubectl get networkpolicies -n voting-app

# View certificates
kubectl get certificates -n voting-app

# Open Minikube dashboard
minikube dashboard

# Generate load (test autoscaling)
kubectl run -it --rm load-gen --image=busybox --restart=Never -- \
  /bin/sh -c "while true; do wget -q -O- http://vote.local; done"
```

---

## Troubleshooting

**Pods not ready?**

```bash
kubectl describe pod -n voting-app <pod-name>
kubectl logs -n voting-app <pod-name>
```

**Can't access vote.local?**

```bash
# Check /etc/hosts
cat /etc/hosts | grep vote.local

# Should show:
# <minikube-ip> vote.local result.local

# If missing, add manually:
echo "$(minikube ip) vote.local result.local" | sudo tee -a /etc/hosts
```

**Certificate error?**

```bash
# Check cert-manager
kubectl get pods -n cert-manager

# Check certificates
kubectl get certificates -n voting-app
kubectl describe certificate vote-tls -n voting-app
```

**HPA not scaling?**

```bash
# Check metrics-server
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes

# Check HPA status
kubectl describe hpa vote-hpa -n voting-app
```

---

## Clean Up

```bash
# Delete everything
kubectl delete namespace voting-app

# Or stop Minikube
minikube stop

# Or delete Minikube cluster
minikube delete
```

---

## Next Steps

1. ✅ Deploy with `./setup-complete-minikube.sh`
2. ✅ Access <https://vote.local>
3. ✅ Run tests: `cd tests && pytest test_infrastructure.py -v`
4. ✅ Generate load and watch HPA scale
5. ✅ View metrics in Grafana
6. ✅ Review `OPTIMIZATION-SUMMARY.md` for full details

---

## Need Help?

- **Full Documentation:** `OPTIMIZATION-SUMMARY.md`
- **Monitoring Guide:** `k8s/monitoring/PROMETHEUS-FIX-GUIDE.md`
- **Test Results:** `tests/test_infrastructure.py`

🎉 **Happy voting!**
