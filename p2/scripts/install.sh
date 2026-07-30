#!/bin/bash

set -euo pipefail

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode=644" sh -

until kubectl get nodes 2>/dev/null | grep -q " Ready"; do
  sleep 2
done

kubectl apply -f /vagrant/confs/
