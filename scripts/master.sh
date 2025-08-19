#!/bin/bash

echo "##################################"
echo "#   RUNNING master.sh script     #"
echo "##################################"

echo "[TASK 1] Initialize Kubernetes Cluster"
kubeadm init --pod-network-cidr=10.244.0.0/16

# Validate cluster init
if [ ! -f /etc/kubernetes/admin.conf ]; then
  echo "❌ kubeadm init failed. Exiting master.sh."
  exit 1
fi

echo "[TASK 2] Generate and save cluster join command to /vagrant/scripts/joincluster.sh"
kubeadm token create --print-join-command > /vagrant/scripts/joincluster.sh

echo "[TASK 3] Copy kube admin config to user's .kube directory"
mkdir -p /home/vagrant/.kube
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config

mkdir -p /home/kube/.kube
cp /etc/kubernetes/admin.conf /home/kube/.kube/config
chown kube:kube /home/kube/.kube/config

echo "[TASK 4] Install Pod Networking plugin"
echo "Cilium Networking plugin selected"
echo "Installing Cilium networking plugin"

export KUBECONFIG=/etc/kubernetes/admin.conf

# Validate cluster before installing Cilium
if ! kubectl get nodes &> /dev/null; then
  echo "❌ Kubernetes API unreachable. Skipping Cilium install."
  exit 1
fi

curl -LO https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz
tar xzvf cilium-linux-amd64.tar.gz
mv cilium /usr/local/bin

cilium install

echo "##################################"
echo "#   MASTER NODE SETUP COMPLETE   #"
echo "##################################"
