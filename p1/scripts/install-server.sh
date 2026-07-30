#!/bin/bash

sudo rm -f /vagrant/token

sudo curl -sfL https://get.k3s.io | sh -

until [ -f /var/lib/rancher/k3s/server/node-token ]; do
  sleep 2
done

sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/token
sudo chmod 644 /vagrant/token
