#!/bin/bash

echo "[TASK 1] Update /etc/hosts file with hostnames"
cat >> /etc/hosts <<EOF
192.168.56.10 master
192.168.56.11 worker1
192.168.56.12 worker2
EOF

echo "[TASK 2] Disable swap"
swapoff -a
sed -i '/swap/d' /etc/fstab

echo "[TASK 3] Install containerd runtime"
apt-get update
apt-get install -y containerd

echo "[TASK 4] Configure containerd and enable service"
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

echo "[TASK 5] Add Kubernetes apt repo with refreshed GPG key"
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.26/deb/Release.key | \
  gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.26/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

apt-get update

echo "[TASK 6] Install Kubernetes components"
apt-get install -y kubelet kubeadm kubectl

# Fallback if install failed
if ! command -v kubeadm &> /dev/null; then
  echo "❌ kubeadm not found. Retrying install..."
  apt-get update
  apt-get install -y kubelet kubeadm kubectl
fi

echo "[TASK 7] Enable kubelet service"
systemctl enable kubelet
systemctl start kubelet

echo "[TASK 8] Apply sysctl settings"
modprobe overlay
modprobe br_netfilter

cat <<EOF | tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

# Suppress deprecated sysctl warnings
sysctl -w net.ipv4.conf.all.accept_source_route=0 || true
sysctl -w net.ipv4.conf.all.promote_secondaries=1 || true
