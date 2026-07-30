#!/bin/bash
# Installs K3s in agent (worker) mode on this VM and joins the cluster
# hosted by the server VM. Uses the token shared via /vagrant/token.

set -euo pipefail

# Wait until the server has written the token file
until [ -f /vagrant/token ]; do
  sleep 2
done

TOKEN=$(cat /vagrant/token)
MASTER_IP=192.168.56.110

# Install K3s as an agent and register with the server
sudo curl -sfL https://get.k3s.io | \
  K3S_URL=https://$MASTER_IP:6443 \
  K3S_TOKEN=$TOKEN \
  INSTALL_K3S_VERSION="v1.36.2+k3s1" \
  sh -
