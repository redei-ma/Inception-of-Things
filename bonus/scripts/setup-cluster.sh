#!/bin/bash
# Creates the k3d cluster, installs Argo CD and a local GitLab instance,
# imports our GitHub repository into GitLab, then applies the Argo CD Application
# so that everything is driven by the local GitLab (instead of GitHub).

set -euo pipefail

# --- Create the k3d cluster (spawns k3s inside Docker containers) ---
k3d cluster create iot

# --- Wait until the node is Ready before applying manifests ---
until kubectl get nodes 2>/dev/null | grep -q " Ready"; do
  sleep 2
done

# --- Create the three namespaces required by the bonus ---
kubectl create namespace argocd
kubectl create namespace dev
kubectl create namespace gitlab

# --- Install Argo CD from the official upstream manifest ---
# Server-side apply avoids the "annotations too long" error caused by the
# large CRDs shipped by Argo CD when using classic client-side apply.
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --server-side

# --- Wait until all Argo CD deployments are Available ---
kubectl wait --for=condition=available --timeout=300s deployment --all -n argocd

# --- Install GitLab via Helm using a minimal values.yaml ---
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm install gitlab gitlab/gitlab \
    --namespace gitlab \
    --values /vagrant/confs/gitlab-values.yaml \
    --timeout 15m

# --- Wait until every GitLab deployment is Available (may take several minutes) ---
kubectl wait --for=condition=available --timeout=900s deployment --all -n gitlab

# --- Fetch the auto-generated root password from the initial secret ---
GITLAB_ROOT_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password \
    -n gitlab -o jsonpath="{.data.password}" | base64 -d)

# --- Open a background port-forward so we can talk to GitLab's HTTP API ---
kubectl port-forward -n gitlab svc/gitlab-webservice-default 8181:8181 >/dev/null 2>&1 &
PF_PID=$!
sleep 5

# --- Create a GitLab project that imports from the public GitHub repo ---
# Argo CD will then read the manifests from this local GitLab project.
curl -sSf --request POST \
    --user "root:$GITLAB_ROOT_PASSWORD" \
    --header "Content-Type: application/json" \
    --data '{"name":"iot-app","visibility":"public","import_url":"https://github.com/redei-ma/Inception-of-Things.git"}' \
    "http://localhost:8181/api/v4/projects"

# --- Wait until the GitHub -> GitLab import is finished ---
until curl -s --user "root:$GITLAB_ROOT_PASSWORD" \
        "http://localhost:8181/api/v4/projects/root%2Fiot-app" \
        | grep -q '"import_status":"finished"'; do
  sleep 5
done

# --- Stop the background port-forward ---
kill $PF_PID 2>/dev/null || true

# --- Deploy the Argo CD Application resource (points to local GitLab) ---
kubectl apply -f /vagrant/confs/application.yaml

# --- Make kubectl config available to the vagrant user ---
mkdir -p /home/vagrant/.kube
cp /root/.kube/config /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
