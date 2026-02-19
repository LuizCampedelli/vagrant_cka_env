#!/bin/bash
# =============================================================================
# CKA Practice Environment – VM Provisioning Script
# =============================================================================
# This script runs on both VMs (machine1 and machine2) during 'vagrant up'.
# It installs and configures everything needed for a Kubernetes v1.31 cluster
# using kubeadm, kubelet, kubectl, and containerd.
#
# =============================================================================

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

log() {
    echo "[provision] $(date '+%H:%M:%S') -- $*"
}

# =============================================================================
# 1. System packages
# =============================================================================
log "Installing system packages..."
apt-get update
apt-get install -y --no-install-recommends \
    openssh-server \
    iputils-ping \
    net-tools \
    iproute2 \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    kmod \
    socat \
    conntrack \
    ebtables \
    ethtool \
    iptables \
    ipset \
    vim \
    less \
    jq \
    wget \
    bash-completion \
    nfs-common
apt-get clean
rm -rf /var/lib/apt/lists/*

# =============================================================================
# 2. Disable swap
# =============================================================================
log "Disabling swap..."
swapoff -a
sed -i '/\bswap\b/d' /etc/fstab 2>/dev/null || true

# =============================================================================
# 3. Kernel modules
# =============================================================================
log "Loading kernel modules: overlay, br_netfilter..."
modprobe overlay
modprobe br_netfilter

cat > /etc/modules-load.d/k8s.conf <<'EOF'
overlay
br_netfilter
EOF

# =============================================================================
# 4. Sysctl parameters for Kubernetes networking
# =============================================================================
log "Applying sysctl networking parameters..."
cat > /etc/sysctl.d/99-kubernetes.conf <<'EOF'
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl -p /etc/sysctl.d/99-kubernetes.conf

# =============================================================================
# 5. containerd (from Docker apt repository)
# =============================================================================
log "Installing containerd..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" \
    > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y --no-install-recommends containerd.io
apt-get clean
rm -rf /var/lib/apt/lists/*

# Configure containerd with SystemdCgroup = true (real systemd in VMs)
log "Configuring containerd with SystemdCgroup = true..."
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

# =============================================================================
# 6. crictl v1.31.1
# =============================================================================
log "Installing crictl v1.31.1..."
CRICTL_VERSION="v1.31.1"
curl -fsSL \
    "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz" \
    | tar -C /usr/local/bin -xz

cat > /etc/crictl.yaml <<'EOF'
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

# =============================================================================
# 7. Kubernetes v1.31 (kubeadm, kubelet, kubectl)
# =============================================================================
log "Installing Kubernetes v1.31 packages..."
K8S_VERSION="v1.31"

curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key" \
    | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
    https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" \
    > /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y --no-install-recommends \
    kubelet \
    kubeadm \
    kubectl
apt-get clean
rm -rf /var/lib/apt/lists/*

apt-mark hold kubelet kubeadm kubectl

# Enable kubectl bash completion
mkdir -p /etc/bash_completion.d
kubectl completion bash > /etc/bash_completion.d/kubectl
echo 'source /etc/bash_completion.d/kubectl' >> /root/.bashrc

# =============================================================================
# 8. Enable kubelet (real systemd — no shim needed)
# =============================================================================
log "Enabling kubelet service..."
systemctl enable kubelet

# =============================================================================
# 9. SSH root login
# =============================================================================
log "Configuring SSH root login..."
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
mkdir -p /var/run/sshd

# Set root password from environment variable
if [ -n "${ROOT_PASSWORD:-}" ]; then
    echo "root:${ROOT_PASSWORD}" | chpasswd
    log "Root password set from .env"
else
    log "WARNING: ROOT_PASSWORD not set, root SSH login will not work with password"
fi

systemctl restart sshd

# =============================================================================
# 10. Hosts file (both nodes can reach each other by hostname)
# =============================================================================
log "Updating /etc/hosts..."
grep -q "ubuntu1" /etc/hosts || echo "192.168.56.10 ubuntu1" >> /etc/hosts
grep -q "ubuntu2" /etc/hosts || echo "192.168.56.11 ubuntu2" >> /etc/hosts

# =============================================================================
# Done
# =============================================================================
log "============================================================"
log "Provisioning complete. Node is ready for kubeadm."
log "  Control-plane (machine1): kubeadm init ..."
log "  Worker        (machine2): kubeadm join ..."
log "============================================================"
