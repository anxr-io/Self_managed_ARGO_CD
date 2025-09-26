# 🚀 Self Managed ARGO CD — GitOps Lab 
![CI](https://img.shields.io/github/actions/workflow/status/anxr-io/akuity-takehome/lint.yml?branch=main&label=CI)
![License](https://img.shields.io/github/license/anxr-io/akuity-takehome)
![Stars](https://img.shields.io/github/stars/anxr-io/akuity-takehome?style=social)

## 📚 Table of Contents

- [✨ Features](#features)
- [🧭 Architecture](#architecture)
- [🧰 Prerequisites](#prerequisites)
- [⚡ Quick Start](#quick-start)
- [🛠 Makefile Commands](#makefile-commands)
- [🗂 Folder Structure](#folder-structure)
- [🔧 Detailed Setup (Summary)](#detailed-setup-summary)
- [✅ Verify & UIs](#verify--uis)
- [🧪 Drift Demos](#drift-demos)
- [🐞 Troubleshooting](#troubleshooting)
- [🔍 Helm Pin Verification (Part 3)](#helm-pin-verification-part-3)
- [📝 Notes & Gotchas](#notes--gotchas)
- [📄 License](#license)
- [📬 Contact](#contact)

## ✨ Features

- **Self-managing Argo CD (App-of-Apps)** — Argo CD installs & manages its own manifests from this repo/path.
- **Git as Source of Truth** — edits in Git auto-sync to the cluster; drift is detected and (optionally) auto-healed.
- **Monitoring with Prometheus** — Bitnami **kube-prometheus** chart deploys Prometheus and scrapes Argo CD metrics.
- **Helm pin (Part 3)** — Argo CD repo-server is pinned to **Helm v3.14.4** via an initContainer for deterministic renders.
- **Makefile UX** — one-command bootstrap (`make bootstrap`) plus handy targets for UIs, status, and drift demos.

## 🧭 Architecture

Git is the source of truth. Argo CD installs itself (App-of-Apps), deploys sample apps, and sets up monitoring. Prometheus scrapes Argo CD metrics.

```text
GitHub repo
└── Argo CD (app-of-apps)
    ├── installs Argo CD (self-manage)
    ├── deploys nginx demo (ns: web)
    ├── deploys echo-server (ns: default or custom)
    └── deploys kube-prometheus (ns: monitoring)

Prometheus <--- scrapes Argo CD metrics
```
```markdown
**Scrape targets**
- `argocd-server-metrics:8083`
- `argocd-repo-server:8084`
- `argocd-notifications-controller-metrics:9001`
- `argocd-metrics:8082`
```
## 🧰 Prerequisites

- Docker Desktop (or any container runtime)
- **kubectl** (client) ≥ 1.29
- **Kind** ≥ 0.23
- **Helm 3**
- **Git**
- **Make**
- **UBUNTU (WSL) - Windows friendly**

**Quick checks**
```bash
kind --version
kubectl version --client
helm version
git --version
make -v
```
## ⚡ Quick Start

```bash
# 1) Clone & enter
git clone https://github.com/<anxr-io>/akuity-takehome.git
cd akuity-takehome

# 2) One-command bootstrap (cluster + Argo CD + apps + monitoring)
make bootstrap

# 3) Open UIs (keep these terminals running)
make argo-ui     # https://localhost:8080
make prom-ui     # http://localhost:9091
```
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```
## 🛠 Makefile Commands
```text
make kind-up        # Create Kind cluster (argocd-lab) & set kubectl context
make kind-down      # Delete the Kind cluster

make bootstrap      # ⚡ One-shot: install Argo CD, apply self-manage app,
                    # deploy nginx demo & Prometheus (CRDs first), then show status

make status         # Quick status of Argo CD apps and monitoring pods

make argo-ui        # Port-forward Argo CD UI   → https://localhost:8080
make prom-ui        # Port-forward Prometheus   → http://localhost:9091
make prom-nodeport  # Print NodePort URL if available

make demo-drift-svc # Demo: delete nginx service → Argo auto-heals it
make demo-drift-rep # Demo: bump nginx replicas → Argo restores desired state

make reset          # Tear down & rebuild cluster from scratch (idempotent)
```
## 🗂 Folder Structure

**Top level**
- 📁 `version-b-bootstrap/` — GitOps sources that Argo CD syncs
  - 📁 `argo-cd/` — Self-managing Argo CD (kustomize) + Helm pin patch
  - 📁 `nginx/` — Demo app (Deployment, Service, Argo CD Application)
  - 📁 `monitoring/` — Prometheus via Bitnami kube-prometheus (Argo CD Application)
- 📁 `docs/` — Setup guide & (optional) architecture diagram
- 📄 `README.md` — You’re reading it
- 🛠️ `Makefile` — One-command workflow

<details><summary><b>Show full tree</b></summary>

```text
.
├── .github
│   ├── ISSUE_TEMPLATE
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   └── workflows
│       ├── lint.yml
│       └── pull_request_template.md
├── docs
│   ├── screenshots
│   │   ├── .gitkeep
│   │   ├── README.md
│   │   ├── argo1.png
│   │   ├── argo2.png
│   │   ├── argo3.png
│   │   ├── argo4.png
│   │   ├── argo5.png
│   │   ├── argo6.png
│   │   ├── argo7.png
│   │   ├── argo8.png
│   │   └── argo9.png
│   ├── INSTALL.md
│   ├── USAGE.md
│   └── setup-guide.md
├── version-b-bootstrap
│   ├── argo-cd
│   │   ├── app-argocd.yaml
│   │   ├── kustomization.yaml
│   │   └── patch-repo-server-helm.yaml
│   ├── echo-server
│   │   ├── deployment.yaml
│   │   ├── echo-app.yaml
│   │   └── service.yaml
│   ├── monitoring
│   │   ├── app-prometheus-crds.yaml
│   │   └── app-prometheus.yaml
│   └── nginx
│       ├── README.md
│       ├── deployment.yaml
│       ├── nginx-app.yaml
│       └── service.yaml
├── .gitignore
├── LICENSE
├── Makefile
└── README.md
```
</details>
## 🔄 How Self-Management Works

This lab uses the **App-of-Apps** pattern where Argo CD manages its own installation manifests.

An Argo CD Application (`version-b-bootstrap/argo-cd/app-argocd.yaml`) points back to this same repo and path where its manifests are stored.

When any change is committed to that path in Git, Argo CD detects it and reconciles its own deployment accordingly.

This means upgrades, config changes, and even Helm binary updates are all driven from Git — making the control plane itself GitOps-managed.

## 🔧 Detailed Setup (Summary)
1) **Create cluster & install Argo CD**
   - Create Kind cluster `argocd-lab`
   - Create `argocd` namespace
   - Apply upstream Argo CD install manifest

2) **Self-manage Argo CD (App-of-Apps)**
   - Apply `version-b-bootstrap/argo-cd/app-argocd.yaml`
   - Argo CD points back to this repo/path and reconciles itself from Git

3) **Sample app (nginx)**
   - Application deploys a Deployment + Service to namespace `web`
   - `CreateNamespace=true` ensures `web` is created on first sync

4) **Monitoring (Prometheus)**
   - Install **prometheus-operator-crds** first (negative sync wave)
   - Install **kube-prometheus** (Bitnami) and scrape Argo CD metrics

5) **Open the UIs**
   - `make argo-ui` → https://localhost:8080
   - `make prom-ui` → http://localhost:9091

6) **Health checks**
   ```bash
   kubectl -n argocd get app
   kubectl -n argocd get pods
   kubectl -n monitoring get pods

## ✅ Verify & UIs

**Health checks**
```bash
kubectl -n argocd get app
kubectl -n argocd get pods
kubectl -n monitoring get pods
```
```bash
1) make argo-ui   # then open https://localhost:8080
2) kubectl -n argocd get secret argocd-initial-admin-secret \ -o jsonpath="{.data.password}" | base64 -d && echo
3) make prom-ui   # then open http://localhost:9091
```
If Prometheus service forward fails early, forward to the pod directly:
```bash
kubectl -n monitoring get pods | grep prometheus-kube-prometheus-prometheus
kubectl -n monitoring port-forward pod/<POD_NAME> 9091:9090
```
## 🧪 Drift Demos
Prove the GitOps loop by making safe, reversible changes. Argo CD should detect drift and snap things back.
**A) Delete Service → auto-heal**
```bash
make demo-drift-svc
# watch it reappear
kubectl -n web get svc nginx -w
```
B) Change Reolicas -> Restored
```bash
make demo-drift-rep
# watch desired replicas return to 1
kubectl -n web get deploy nginx -w
```
**See it in the UI**

- Argo CD → **Applications** → **nginx**
- You’ll see: `OutOfSync` → `Progressing` → `Synced` (an automated sync recorded in **History**).

## 🐞 Troubleshooting

**Prometheus app shows _OutOfSync_ but everything looks fine**
- Often harmless operator mutations (extra labels/annotations).
- Inspect the diff:
  ```bash
  argocd app diff prometheus || true
  kubectl -n argocd describe app prometheus | sed -n '1,160p'
  ```
## 📌 How Part 3 is Implemented — Helm Pinning

**Location in repo:**  
`version-b-bootstrap/argo-cd/kustomize-patch-helm.yaml`

**Implementation:**  
- An **initContainer** is added to the Argo CD `repo-server` Deployment.  
- This container downloads and places **Helm v3.14.4** into `/custom-tools/helm` inside the repo-server pod.  
- The `repo-server`'s `PATH` is updated to use this Helm binary instead of the default.

**Why this matters**:
- Ensures Argo CD’s control plane is fully GitOps-managed and reproducible.
- Changes to Argo CD itself go through the same version control, review, and deployment process as applications it manages.
- Makes the platform self-healing: if a manual change drifts from Git, Argo CD will snap back to the desired state.

Pinning the Helm version ensures charts render the same way in dev, staging, and production, avoiding unexpected diffs caused by Helm upgrades.

✅ **Verification**:

```bash
kubectl -n argocd exec deploy/argocd-repo-server -- helm version
# Expected: v3.14.4
```
```bash
argocd app get argo-cd-self-manage
# Look for:
#  Sync Status: Synced
#  Health Status: Healthy
```

## 🔍 Helm Pin Verification (Part 3)

This lab pins the Helm binary used by the Argo CD **repo-server** to `v3.14.4`.

**Check the version**
```bash
kubectl -n argocd exec deploy/argocd-repo-server -- helm version
# Expected: v3.14.4
```
(Optional) See where Helm is coming from
```bash
kubectl -n argocd exec deploy/argocd-repo-server -- which helm
# often /custom-tools/helm
```
If you don’t see v3.14.4, wait ~30–60s and retry (the initContainer may still be injecting the binary).
Still different? Refresh & restart:

```bash
kubectl -n argocd annotate app argo-cd-self-manage argocd.argoproj.io/refresh=hard --overwrite
kubectl -n argocd rollout restart deploy/argocd-repo-server
```
## 📝 Notes & Gotchas

- Keep the path `version-b-bootstrap/argo-cd` unless you also update the Argo CD Application that points to it.
- Prometheus may briefly show **OutOfSync** as the operator mutates resources (labels/annotations). That’s normal.
- If `make prom-ui` fails early, forward to the **pod**:
  ```bash
  kubectl -n monitoring get pods | grep prometheus-kube-prometheus-prometheus
  kubectl -n monitoring port-forward pod/<POD_NAME> 9091:9090
  ```
- 🔀 **Forks**
  - 👉 If you fork this repo, update `repoURL` in [`version-b-bootstrap/argo-cd/app-argocd.yaml`](version-b-bootstrap/argo-cd/app-argocd.yaml) to your fork.
  - 👉 Example:
    ```yaml
    spec:
      source:
        repoURL: https://github.com/<your-username>/akuity-takehome.git
    ```
- 🧹 **Clean slate anytime**
  - 👉 Run:
    ```bash
    make reset
    ```

### Paste this for **License**
```markdown
## 📄 License
MIT — see [LICENSE](LICENSE).
```
## 📬 Contact
Maintainer: **Ankur Dwivedi**  
GitHub: **@anxr-io**
