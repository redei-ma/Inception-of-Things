#!/bin/bash

set -euo pipefail

until [ -f /vagrant/token ]; do
  sleep 2
done

TOKEN=$(cat /vagrant/token)
MASTER_IP=192.168.56.110

sudo curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$TOKEN sh -