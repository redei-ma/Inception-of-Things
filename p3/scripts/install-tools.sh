#!/bin/bash

set -euo pipefail

apt-get update

apt-get install -y curl ca-certificates 

curl -fsSL https://get.docker.com | sh
usermod -aG docker vagrant

ARCH=$(dpkg --print-architecture)   # ritorna "arm64" o "amd64" a seconda della VM                                                      
KUBECTL_VERSION=$(curl -Ls https://dl.k8s.io/release/stable.txt)                                                                        
curl -Lo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"                                                              
chmod +x /usr/local/bin/kubectl

curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash