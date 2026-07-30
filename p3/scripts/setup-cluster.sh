#!/bin/bash
# Creates the k3d cluster, installs Argo CD, and deploys the Application
# that syncs manifests from the GitHub repository into the "dev" namespace.

set -euo pipefail

# --- Create the k3d cluster (spawns k3s inside Docker containers) ---
k3d cluster create iot

# --- Wait until the node is Ready before applying manifests ---
until kubectl get nodes 2>/dev/null | grep -q " Ready"; do
  sleep 2
done

# --- Create the two namespaces required by the project ---
kubectl create namespace argocd
kubectl create namespace dev

# --- Install Argo CD from the official upstream manifest ---
# Server-side apply avoids the "annotations too long" error caused by the
# large CRDs shipped by Argo CD when using classic client-side apply.
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --server-side

# --- Wait until all Argo CD deployments are Available ---
kubectl wait --for=condition=available --timeout=300s deployment --all -n argocd

# --- Deploy the Argo CD Application resource (defined in confs/) ---
kubectl apply -f /vagrant/confs/application.yaml

# --- Make kubectl config available to the vagrant user ---
mkdir -p /home/vagrant/.kube
cp /root/.kube/config /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
