#!/bin/bash

echo "##################################"
echo "#   RUNNING worker.sh script     #"
echo "##################################"

echo "[TASK 1] Join node to Kubernetes Cluster"

# Validate join script exists
if [ ! -f /vagrant/scripts/joincluster.sh ]; then
  echo "❌ joincluster.sh not found. Cannot join cluster."
  exit 1
fi

# Execute join command
bash /vagrant/scripts/joincluster.sh

# Validate kubelet is active
if ! systemctl is-active --quiet kubelet; then
  echo "❌ kubelet is not running. Check logs for errors."
  exit 1
fi

echo "[TASK 2] Copy kube config for vagrant user"
mkdir -p /home/vagrant/.kube
cp /etc/kubernetes/kubelet.conf /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config

echo "[TASK 3] Create alias for kubectl"
echo "alias k='kubectl'" >> /home/vagrant/.bashrc

echo "##################################"
echo "#   WORKER NODE SETUP COMPLETE   #"
echo "##################################"
