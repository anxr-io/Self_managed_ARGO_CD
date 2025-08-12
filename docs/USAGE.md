# 🚀 Usage Guide — Akuity Take-Home (Version B)

This document explains how to work with the deployed environment, run demos, verify metrics, and troubleshoot common issues.
## 1) Common commands (Makefile)

```bash
make help         # list targets
make status       # quick health checks (apps + pods)

make argo-ui      # Argo CD UI → https://localhost:8080
make prom-ui      # Prometheus UI → http://localhost:9091

make kind-up      # create Kind cluster
make bootstrap    # Argo CD + self-manage + nginx + Prometheus
make kind-down    # delete Kind cluster
make reset        # delete + bootstrap (clean rebuild)
```
## 2) Drift demos (safe)  

### A) Delete Service → auto-heal
```bash
kubectl -n web delete svc nginx
watch -n1 'kubectl -n web get svc nginx'
```
### B) Change replicas → restored
```bash
kubectl -n web patch deploy nginx -p '{"spec":{"replicas":2}}'
watch -n1 'kubectl -n web get deploy nginx -o wide'
```
**Open Argo CD → Applications → nginx** to watch:  
*OutOfSync → Progressing → Synced* (auto-sync recorded in History).
## 3) Prometheus targets (verify Argo metrics)  
```bash
make prom-ui
# In the browser: http://localhost:9091 → Status → Targets
```
**Scrape targets you should see:**
- `argocd-server-metrics:8083`
- `argocd-repo-server:8084`
- `argocd-notifications-controller-metrics:9001`
- `argocd-metrics:8082`

- ## 4) Helm pin (Part 3) — re-check anytime  
```bash
kubectl -n argocd exec deploy/argocd-repo-server -- which helm
kubectl -n argocd exec deploy/argocd-repo-server -- helm version
# Expect v3.14.4
```
**If not pinned yet (force a refresh & restart):**  
```bash
kubectl -n argocd annotate app argo-cd-self-manage argocd.argoproj.io/refresh=hard --overwrite
kubectl -n argocd rollout restart deploy/argocd-repo-server
```
## 5) Health & status  
```bash
kubectl -n argocd get app -o wide
kubectl -n argocd get pods
kubectl -n monitoring get pods
kubectl -n web get deploy,svc,pods
```
**Expected:**
- All apps **Synced/Healthy**
- `deployment/nginx` **READY 1/1**
- `service/nginx` present *(ClusterIP)*
- Prometheus server *(kube-prometheus)* running in `monitoring`

## 6) Quick fixes  

**Prometheus OutOfSync but looks fine**  
```bash
kubectl -n argocd describe app prometheus | sed -n '1,160p'
# optional:
argocd app diff prometheus || true
```
*(Often harmless operator mutations; Argo will reconcile.)*

**Port-forward to service fails**  
```bash
# use the pod directly
kubectl -n monitoring get pods | grep prometheus-kube-prometheus-prometheus
kubectl -n monitoring port-forward pod/<POD_NAME> 9091:9090
```
**Wrong kube context**  
```bash
kubectl config use-context kind-argocd-lab
```
## 7) Clean slate anytime  
```bash
make reset    # deletes the Kind cluster and re-bootstraps everything
```
## 8) Contributing (PRs)  

Use the included Pull Request template.  

**Safety checks:**
- Do not move/rename Argo-watched paths (e.g., `version-b-bootstrap/argo-cd`) unless you update the corresponding Application.
- Update README/docs if behavior changes.
- Ensure CI (YAML lint) is green.

---

If you want, you can also drop a tiny section in your root `README.md` linking to these:

```markdown
**Docs:** [INSTALL](docs/INSTALL.md) • [USAGE](docs/USAGE.md)
```


