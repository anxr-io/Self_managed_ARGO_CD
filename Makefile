SHELL := /bin/bash

# ---- Config ----
KIND_CLUSTER ?= argocd-lab
KCTX        ?= kind-$(KIND_CLUSTER)
NS_ARGO     ?= argocd
NS_MON      ?= monitoring
NS_WEB      ?= web

.PHONY: help kind-up kind-down bootstrap status argo-ui prom-ui prom-nodeport demo-drift-svc demo-drift-rep reset clean

help: ## Show available targets
	@echo "Make targets:"
	@grep -E '^[a-zA-Z0-9_-]+:.*?##' Makefile | awk -F':|##' '{printf "  \033[36m%-20s\033[0m %s\n", $$1, $$3}'

kind-up: ## Create Kind cluster (argocd-lab) & set kubectl context
	kind get clusters | grep -qx $(KIND_CLUSTER) || kind create cluster --name $(KIND_CLUSTER)
	kubectl config use-context $(KCTX)

kind-down: ## Delete the Kind cluster
	kind delete cluster --name $(KIND_CLUSTER) || true

bootstrap: ## One-shot: Argo CD + self-manage app + nginx + Prometheus (CRDs first)
	@echo "🧱 Ensuring Kind cluster $(KIND_CLUSTER) exists..."
	kind get clusters | grep -qx $(KIND_CLUSTER) || kind create cluster --name $(KIND_CLUSTER)
	@echo "🚀 Installing Argo CD baseline..."
	kubectl create namespace $(NS_ARGO) --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n $(NS_ARGO) -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "📦 Applying self-manage + apps..."
	kubectl apply -n $(NS_ARGO) -f version-b-bootstrap/argo-cd/app-argocd.yaml
	kubectl apply -n $(NS_ARGO) -f version-b-bootstrap/nginx/nginx-app.yaml
	kubectl apply -n $(NS_ARGO) -f version-b-bootstrap/monitoring/app-prometheus-crds.yaml
	kubectl apply -n $(NS_ARGO) -f version-b-bootstrap/monitoring/app-prometheus.yaml
	@echo "⏳ Waiting for Argo CD server..."
	kubectl -n $(NS_ARGO) rollout status deploy/argocd-server --timeout=180s || true
	@$(MAKE) status

status: ## Show Argo CD apps and monitoring pods
	@echo "🔎 Argo CD Apps:"; kubectl -n $(NS_ARGO) get app || true
	@echo; echo "📦 Argo CD Pods:"; kubectl -n $(NS_ARGO) get pods || true
	@echo; echo "📈 Monitoring Pods:"; kubectl -n $(NS_MON) get pods || true

argo-ui: ## Port-forward Argo CD UI → https://localhost:8080
	@echo "🌐 Argo CD → https://localhost:8080 (Ctrl+C to stop)"
	kubectl -n $(NS_ARGO) port-forward svc/argocd-server 8080:443

prom-ui: ## Port-forward Prometheus UI → http://localhost:9091
	@echo "📊 Prometheus → http://localhost:9091 (Ctrl+C to stop)"
	kubectl -n $(NS_MON) port-forward svc/prometheus-kube-prometheus-prometheus 9091:9090

prom-nodeport: ## Print Prometheus NodePort (if chart exposes one)
	kubectl -n $(NS_MON) get svc prometheus-kube-prometheus-prometheus -o jsonpath='{.spec.ports[0].nodePort}{"\n"}' || true
	@echo "If a port printed, try: http://localhost:<nodePort>"

demo-drift-svc: ## Demo: delete nginx Service → Argo recreates it
	- kubectl -n $(NS_WEB) delete svc nginx || true
	@echo "Watching for recreation (Ctrl+C to stop)..."
	watch -n1 'kubectl -n $(NS_WEB) get svc nginx'

demo-drift-rep: ## Demo: change nginx replicas → Argo restores desired state
	- kubectl -n $(NS_WEB) patch deploy nginx -p '{"spec":{"replicas":2}}' --type=merge || true
	@echo "Watching until replicas snap back (Ctrl+C to stop)..."
	watch -n1 'kubectl -n $(NS_WEB) get deploy nginx -o wide'

reset: ## Delete & rebuild the lab from scratch
	@echo "🗑️  Deleting cluster $(KIND_CLUSTER)..."
	kind delete cluster --name $(KIND_CLUSTER) || true
	@$(MAKE) bootstrap

clean: ## No-op placeholder (for symmetry)
	@true
