#!/bin/bash
# Installs the tools needed to run the k3d cluster on this VM:
# - Docker (used by k3d to run cluster nodes as containers)
# - kubectl (CLI to interact with the Kubernetes cluster)
# - k3d (creates lightweight k3s clusters inside Docker containers)

set -euo pipefail

# --- Base utilities ---
apt-get update
# qemu-user-static + binfmt-support let this arm64 VM run amd64-only
# container images (such as wil42/playground) through kernel-level emulation.
apt-get install -y curl ca-certificates qemu-user-static binfmt-support

# --- Docker (installed via the official get.docker.com script) ---
curl -fsSL https://get.docker.com | sh
# Allow the vagrant user to run docker without sudo
usermod -aG docker vagrant

# --- kubectl (official binary, matched to the VM architecture) ---
ARCH=$(dpkg --print-architecture)   # returns "arm64" or "amd64"
KUBECTL_VERSION=$(curl -Ls https://dl.k8s.io/release/stable.txt)
curl -Lo /usr/local/bin/kubectl \
  "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
chmod +x /usr/local/bin/kubectl

# --- k3d (official install script) ---
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# --- Helm (official install script) ---

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash
