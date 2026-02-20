## documentation:

https://github.com/cncf/curriculum/blob/master/CKAD_Curriculum_v1.34.pdf

## First step, look in kubernetes documentation:

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

## Control Plane:

in Cloud
Kubeadm init

in VM env:
kubeadm init --apiserver-advertise-address=192.168.56.10
  --pod-network-cidr=10.244.0.0/16

install cilium binary

install cilium

kubectl get no

kubectl get po -A

kubectl describe nodes

kubeadm token create --print-join-command

kubeclt run first-pod --image nginx

## Worker node:

kubeadm join 10.0.2.15:6443 --token hqxzm1.eckh2wpelsni58cy --discovery-token-ca-cert-hash sha256:bc61c1f4b920b3151603d0ee346c0c0878c3dc90a398a6af82bbd0a4c643f0ed

## Upgrade a cluster:

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

apt-get update (to check the packages that will be updated)

apt-mark unhold kubeadm kubelet kubectl

apt install kubeadm

apt install kubelet

apt install kubectl

restart your VM with: vagrant reload

than:

mkdir -p $HOME/.kube
  cp /etc/kubernetes/admin.conf $HOME/.kube/config
  chown $(id -u):$(id -g) $HOME/.kube/config

to reload the config

Than: 

kubectl get po kube-apiserver-ubuntu1 -n kube-system -o yaml

You will see that the image is still 1.31

Than:

kubeadm version

To see if the package is 1.32.x

Than:

kubeadm upgrade plan

Than:

kubeadm upgrade apply v1.32.x

Than:

always check the image:
kubectl get po kube-apiserver-ubuntu1 -n kube-system -o yaml

it will show:
image: registry.k8s.io/kube-apiserver:v1.32.12

Than, for safety, mark the hold:
ape-mark hold kubeadm kubectl kubelet

## Upgrade Worker node

First lets drain the node, in the control plane VM:

kubectl drain <name_of_node> --ignore-daemonsets (To ignore CNI's)

if you have one pod, like this environment:

kubectl drain <name_of_node> --ignore-daemonsets --force (it will delete the pod)

in both cases, a flag will be added: Schedulingdisable, nothing will be added to this node.

Now, in the worker node VM:

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

apt-get update (to check the packages that will be updated)

aFollow thse steps:

1. apt-mark unhold kubeadm

2. apt install kubeadm

3. kubeadm upgrade node

4. 1. apt-mark unhold kubectl kubelet

2. apt install kubectl kubelet

Once upgraded:

1. apt-mark hold kubectl kubelet kubeadm

Now, lets incordon the worker node, in control plane VM:

1. kubectl incordon <name_of_node>

To test, lets run a pod:

1. kubectl run nginx --image nginx


## Trobleoushooting

If you restart your VMs, using: vagrant reload, you must run this command in control plane VM:

mkdir -p $HOME/.kube
  cp /etc/kubernetes/admin.conf $HOME/.kube/config
  chown $(id -u):$(id -g) $HOME/.kube/config
