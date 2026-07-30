#!/bin/bash
# Installs a single-node K3s cluster on this VM and applies the manifests
# (Deployments, Services, Ingress) from the shared /vagrant/confs folder.

set -euo pipefail

# Install K3s in server mode. The --write-kubeconfig-mode=644 flag makes the
# kubeconfig readable by non-root users, so we can run kubectl without sudo.
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode=644" sh -

# Wait until the node is Ready before applying manifests
until kubectl get nodes 2>/dev/null | grep -q " Ready"; do
  sleep 2
done

# Apply all Kubernetes manifests (Deployments, Services, Ingress)
kubectl apply -f /vagrant/confs/
