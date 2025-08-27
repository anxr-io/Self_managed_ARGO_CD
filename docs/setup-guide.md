# Setup Guide — Akuity Take-Home (Version B)

This guide expands the README with exact commands and troubleshooting.

## 1) Prerequisites
- Docker Desktop (or container runtime)
- kubectl, Kind, Helm, Git, Make

Quick checks:
```bash
kind --version
kubectl version --client
helm version
git --version
make -v
```
## 2) Quick Start
```bash
git clone https://github.com/<your-username>/akuity-takehome.git
cd akuity-takehome
make bootstrap
make argo-ui    # https://localhost:8080
make prom-ui    # http://localhost:9091
```
## 3) Verify
```bash
kubectl -n argocd get app
kubectl -n argocd get pods
kubectl -n monitoring get pods

```

## 4) Drift Demos

**A) Delete Service → auto-heal**
```bash
make demo-drift-svc
# watch it reappear
kubectl -n web get svc nginx -w
```

**B) Change replicas → restored**
```bash
make demo-drift-rep
# watch desired replicas return
kubectl -n web get deploy nginx -w
```

## 5) Notes
- Argo CD watches the **main** branch — working in feature branches is safe.
- Prometheus OutOfSync right after install is often harmless operator changes (labels/annotations).
- Need a clean slate? `make reset`
