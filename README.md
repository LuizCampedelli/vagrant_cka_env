# CKA Practice Environment

A two-node Vagrant + VirtualBox environment that runs Ubuntu 22.04 VMs with
Kubernetes v1.31 tooling pre-installed (containerd, kubeadm, kubelet, kubectl).
Designed for hands-on CKA (Certified Kubernetes Administrator) exam preparation.

Both VMs share a private network and are reachable by hostname. You SSH in,
then run `kubeadm init` and `kubeadm join` yourself — just like the real exam.

## Architecture

| VM         | Hostname  | IP              | Role            | SSH                          |
|------------|-----------|-----------------|-----------------|------------------------------|
| `machine1` | `ubuntu1` | `192.168.56.10` | Control-plane   | `vagrant ssh machine1`       |
| `machine2` | `ubuntu2` | `192.168.56.11` | Worker node     | `vagrant ssh machine2`       |

## Prerequisites

- [Vagrant](https://www.vagrantup.com/downloads) v2.3+
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) v7+
- macOS, Linux, or Windows

## Quick Start

### 1. Configure credentials

```bash
cp .env.example .env
# Edit .env to set your root password
```

### 2. Start the environment

The first boot downloads the base box (~700 MB) and provisions both VMs.
Subsequent starts are faster.

```bash
vagrant up
```

### 3. Connect via SSH

```bash
# Control-plane node
vagrant ssh machine1

# Worker node
vagrant ssh machine2

# Or use direct SSH with the root password from .env
ssh root@192.168.56.10   # machine1
ssh root@192.168.56.11   # machine2
```

### 4. Initialise the cluster (practice task)

**On machine1 (control-plane):**

```bash
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=192.168.56.10
```

After `kubeadm init` completes, set up kubectl access:

```bash
export KUBECONFIG=/etc/kubernetes/admin.conf
```

Verify the control-plane is up:

```bash
kubectl get nodes
kubectl get pods -n kube-system
```

**Install a CNI plugin (required before pods can be scheduled):**

```bash
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
```

### 5. Join the worker node (practice task)

`kubeadm init` prints a `kubeadm join` command at the end. Copy it and run it
on machine2:

```bash
# On machine2 – paste the full command printed by kubeadm init, e.g.:
sudo kubeadm join 192.168.56.10:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

If you missed the join command, regenerate it on machine1:

```bash
kubeadm token create --print-join-command
```

Verify the worker joined:

```bash
# Back on machine1
kubectl get nodes -o wide
```

### 6. Stop the environment

```bash
# Suspend VMs (fast resume later)
vagrant suspend

# Shut down VMs gracefully (keeps disk state)
vagrant halt

# Destroy VMs completely (start fresh next time)
vagrant destroy -f
```

## How to Use (End-to-End)

```bash
# 1. Start both VMs
vagrant up

# 2. SSH into the control-plane node
vagrant ssh machine1

# 3. Initialize the Kubernetes cluster
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=192.168.56.10

# 4. Configure kubectl
export KUBECONFIG=/etc/kubernetes/admin.conf

# 5. Install Flannel CNI
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# 6. Verify control-plane is Ready
kubectl get nodes
kubectl get pods -n kube-system
```

Now open a second terminal and join the worker node:

```bash
# 7. SSH into the worker node
vagrant ssh machine2

# 8. Join the cluster (paste the command printed by kubeadm init)
sudo kubeadm join 192.168.56.10:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

Back on machine1, confirm both nodes are ready:

```bash
# 9. Verify the cluster
kubectl get nodes -o wide
```

To reset and start over:

```bash
vagrant destroy -f && vagrant up
```

## What Is Pre-installed

| Component          | Version        | Notes                                              |
|--------------------|----------------|----------------------------------------------------|
| `containerd`       | latest stable  | Configured with `SystemdCgroup = true` (real VMs)   |
| `kubeadm`          | v1.31.x        | For initialising and joining nodes                  |
| `kubelet`          | v1.31.x        | Pinned via `apt-mark hold`                          |
| `kubectl`          | v1.31.x        | Bash completion pre-configured                      |
| `crictl`           | v1.31.1        | CRI debug tool; points at containerd socket         |
| `openssh-server`   | ---            | SSH root login enabled                              |
| Networking tools   | ---            | ping, ifconfig, ip, ss, netstat, iptables           |
| Debug tools        | ---            | vim, jq, wget, curl, bash-completion                |

## What Provisioning Does

During `vagrant up`, `scripts/provision.sh` runs on each VM and:

1. Installs system packages (networking tools, debug tools, kmod, socat, conntrack, etc.)
2. Disables swap (`swapoff -a` + removes from `/etc/fstab`)
3. Loads kernel modules (`overlay`, `br_netfilter`) and persists them
4. Sets sysctl parameters (`bridge-nf-call-iptables=1`, `ip_forward=1`)
5. Installs containerd from the Docker apt repo, configures `SystemdCgroup = true`
6. Installs crictl v1.31.1
7. Installs kubeadm, kubelet, kubectl v1.31 and pins them with `apt-mark hold`
8. Enables kubelet via systemd
9. Configures SSH root login with the password from `.env`
10. Updates `/etc/hosts` with both node IPs

## Vagrant Commands

| Command                     | Description                                     |
|-----------------------------|-------------------------------------------------|
| `vagrant up`                | Create and provision VMs                        |
| `vagrant ssh machine1`      | SSH into control-plane node                     |
| `vagrant ssh machine2`      | SSH into worker node                            |
| `vagrant halt`              | Shut down VMs (preserves state)                 |
| `vagrant suspend`           | Suspend VMs (fast resume)                       |
| `vagrant resume`            | Resume suspended VMs                            |
| `vagrant destroy -f`        | Delete VMs completely                           |
| `vagrant provision`         | Re-run provisioning scripts                     |
| `vagrant status`            | Show VM status                                  |

## Troubleshooting

**kubelet is not running after provisioning?**

kubelet is enabled but will only start properly after `kubeadm init` or
`kubeadm join` configures it. Check status with:

```bash
sudo systemctl status kubelet
sudo journalctl -u kubelet -f
```

**containerd is not running:**

```bash
sudo systemctl status containerd
sudo journalctl -u containerd
# Restart it:
sudo systemctl restart containerd
```

**Nodes stay in NotReady after join:**

A CNI plugin must be installed. Run the Flannel step on machine1 (see step 4).

**I need a fresh cluster:**

```bash
# On each node, reset kubeadm state
sudo kubeadm reset -f
# Then destroy and recreate VMs
vagrant destroy -f
vagrant up
```

**VMs can't reach each other:**

Verify the private network is configured:

```bash
ip addr show   # should have 192.168.56.x on an interface
ping ubuntu2   # from machine1
ping ubuntu1   # from machine2
```

## Networking

| Network               | Subnet           | Purpose                        |
|-----------------------|------------------|--------------------------------|
| Private (host-only)   | `192.168.56.0/24`| Node-to-node communication     |
| Pod network (Flannel) | `10.244.0.0/16`  | Set via `--pod-network-cidr`   |

VMs communicate by hostname: `ping ubuntu2` from ubuntu1 (and vice versa).

## Project Structure

```text
.
├── .env                  # Passwords (git-ignored)
├── .env.example          # Example env file (safe to commit)
├── Vagrantfile           # Two-VM cluster definition
├── scripts/
│   └── provision.sh      # VM provisioning (packages, containerd, k8s)
├── Class 01/
│   └── class_01.md       # Class notes
└── README.md
```

## Default Credentials

| User      | Default Password | `.env` Variable      | Notes                  |
|-----------|------------------|----------------------|------------------------|
| `root`    | see `.env`       | `ROOT_PASSWORD`      | SSH root login enabled |
| `vagrant` | `vagrant`        | ---                  | Default Vagrant user   |

## Security Notes

- VMs are for local CKA practice only. Not for production.
- Passwords are in `.env` which is git-ignored. Never commit `.env`.
- Root SSH login is enabled for practice convenience.

## License

This project is provided as-is for educational and CKA exam practice purposes.
