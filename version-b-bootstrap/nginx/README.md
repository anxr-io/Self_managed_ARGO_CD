# 🟢 NGINX Demo (Version B)

Small workload used to prove the GitOps loop and drift auto-healing.

## What this folder contains
- `deployment.yaml` — Deployment (`nginx:1.25`) in **namespace `web`**
- `service.yaml` — ClusterIP Service on port **80**
- `nginx-app.yaml` — Argo CD **Application** pointing to this folder  
  - **name:** `nginx`  
  - **dest namespace:** `web`  
  - **repo path:** `version-b-bootstrap/nginx`  
  - **syncPolicy:** automated (prune + selfHeal)

## Quick verify
```bash
kubectl -n argocd get app nginx -o wide
kubectl -n web get deploy,svc,pods
```
**Expected**

- App is **Synced/Healthy**
- `deployment/nginx` READY **1/1**
- `service/nginx` (ClusterIP)

## Drift demos (safe)

**A) Delete Service → auto-heal**
```bash
kubectl -n web delete svc nginx
watch -n1 'kubectl -n web get svc nginx'
```

**B) Change replicas → Argo restores**
```bash
kubectl -n web patch deploy nginx -p '{"spec":{"replicas":2}}'
watch -n1 'kubectl -n web get deploy nginx -o wide'
```
