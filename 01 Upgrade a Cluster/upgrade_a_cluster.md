## Exam docs:

[CKA CV](https://github.com/cncf/curriculum/blob/master/CKAD_Curriculum_v1.34.pdf)

## Documentation:

[Create a cluster](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)

[Install a cluster](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)

[Upgrade a cluster](https://v1-32.docs.kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)

## Control Plane:

in Cloud:

```bash
Kubeadm init
```

in VM env:

```bash
kubeadm init --apiserver-advertise-address=192.168.56.10
  --pod-network-cidr=10.244.0.0/16
```

```bash
install cilium binary
```

```bash
install cilium
```

```bash
kubectl get no
```

```bash
kubectl get po -A
```

```bash
kubectl describe nodes
```

```bash
kubeadm token create --print-join-command
```

```bash
kubeclt run first-pod --image nginx
```

## Worker node:

```bash
kubeadm join 10.0.2.15:6443 --token hqxzm1.eckh2wpelsni58cy --discovery-token-ca-cert-hash sha256:bc61c1f4b920b3151603d0ee346c0c0878c3dc90a398a6af82bbd0a4c643f0ed
```

## Upgrade a cluster:

```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

```bash
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

```bash
apt-get update (to check the packages that will be updated)
```

```bash
apt-mark unhold kubeadm kubelet kubectl
```

```bash
apt install kubeadm
```

```bash
apt install kubelet
```

```bash
apt install kubectl
```

```bash
restart your VM with: vagrant reload\
```

Now:

```bash
mkdir -p $HOME/.kube
  cp /etc/kubernetes/admin.conf $HOME/.kube/config
  chown $(id -u):$(id -g) $HOME/.kube/config
```

to reload the config

Onde reloaded: 

```bash
kubectl get po kube-apiserver-ubuntu1 -n kube-system -o yaml
```

You will see that the image is still 1.31

Than:

```bash
kubeadm version
```
To see if the package is 1.32.x

Continue:

```bash
kubeadm upgrade plan
```

```bash
kubeadm upgrade apply v1.32.x
```

always check the image:

```bash
kubectl get po kube-apiserver-ubuntu1 -n kube-system -o yaml
```

it will show:

```bash
image: registry.k8s.io/kube-apiserver:v1.32.12
```

Than, for safety, mark the hold:

```bash
apt-mark hold kubeadm kubectl kubelet
```

## Upgrade Worker node

First lets drain the node, in the control plane VM:

```bash
kubectl drain <name_of_node> --ignore-daemonsets (To ignore CNI's)
```

if you have one pod, like this environment:

```bash
kubectl drain <name_of_node> --ignore-daemonsets --force (it will delete the pod)
```
in both cases, a flag will be added: SchedulingDisable, nothing will be added to this node.

Now, in the worker node VM:

```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

```bash
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

```bash
apt-get update (to check the packages that will be updated)
```

Follow thse steps:

```bash
1. apt-mark unhold kubeadm

2. apt install kubeadm

3. kubeadm upgrade node

4. apt-mark unhold kubectl kubelet

5. apt install kubectl kubelet
```

Once upgraded:

```bash
1. apt-mark hold kubectl kubelet kubeadm
```

Now, lets incordon the worker node, in control plane VM:

```bash
1. kubectl incordon <name_of_node>
```

To test, lets run a pod:

```bash
1. kubectl run nginx --image nginx
```

## Trobleoushooting

If you restart your VMs, using: vagrant reload, you must run this command in control plane VM:

```bash
mkdir -p $HOME/.kube
  cp /etc/kubernetes/admin.conf $HOME/.kube/config
  chown $(id -u):$(id -g) $HOME/.kube/config
```