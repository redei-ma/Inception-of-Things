#!/bin/bash
# Creates the k3d cluster, installs Argo CD and a local GitLab instance,
# imports the upstream GitHub repository into GitLab, then applies the Argo CD
# Application so that everything is driven by the local GitLab (instead of GitHub).

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
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.3.12/manifests/install.yaml \
  --server-side

# --- Wait until all Argo CD deployments are Available ---
kubectl wait --for=condition=available --timeout=300s deployment --all -n argocd

# --- Install GitLab via Helm using a minimal values.yaml ---
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm install gitlab gitlab/gitlab \
    --version 9.11.8 \
    --namespace gitlab \
    --values /vagrant/confs/gitlab-values.yaml \
    --timeout 15m

# --- Wait until every GitLab deployment is Available (may take several minutes) ---
kubectl wait --for=condition=available --timeout=900s deployment --all -n gitlab

# --- Bootstrap GitLab entirely through the Rails console via the toolbox pod ---
# Enable "git" as an allowed import source, create the "iot-app" project
# owned by root that mirrors the public GitHub repository, and wait for the
# import to complete. Everything runs inside GitLab's own Ruby process, so
# no HTTP authorisation layer stands in the way.
kubectl exec -n gitlab deploy/gitlab-toolbox -c toolbox -- gitlab-rails runner "
  ApplicationSetting.current.update!(import_sources: ['git', 'gitlab_project'])
  root = User.find_by_username('root')
  project = Projects::CreateService.new(root,
    name: 'iot-app',
    path: 'iot-app',
    namespace_id: root.namespace_id,
    visibility_level: Gitlab::VisibilityLevel::PUBLIC,
    import_url: 'https://github.com/redei-ma/Inception-of-Things.git'
  ).execute
  raise 'Project creation failed: ' + project.errors.full_messages.join(', ') unless project.persisted?
  loop do
    project.reload
    break if project.import_status == 'finished'
    raise 'Import failed' if project.import_status == 'failed'
    sleep 5
  end
"

# --- Deploy the Argo CD Application resource (points to local GitLab) ---
kubectl apply -f /vagrant/confs/application.yaml

# --- Make kubectl config available to the vagrant user ---
mkdir -p /home/vagrant/.kube
cp /root/.kube/config /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
