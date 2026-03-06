## ETCD Backup

[Operating ETCD Clusters for Kubernetes](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)

[Backing up an ectd cluster](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster)

[Restoring an ectd cluster](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#restoring-an-etcd-cluster)

## Install ETCDCTL - X86_64 - Cloud (It won't be on the exam, but it must know for the environment setup)

### 1. Get the install version
```bash
Install ETCDCTL - x86_64 machines

https://github.com/etcd-io/etcd/releases
```
#### 2. Define variables clearly

```bash
ETCD_VER=v3.6.8
```

### 3. Choose the download URL

```bash
GOOGLE_URL=https://storage.googleapis.com/etcd
GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
DOWNLOAD_URL=${GOOGLE_URL}
```

### 4. Remove any leftover

```bash
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test
```

### 5. Download the latest version

```bash
curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1 --no-same-owner
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
```

### 6. Navigate to the etcd folder

```bash
cd /tmp/etcd-download-test/
```

### 7. Move the binaries to the correct folder

```bash
mv etcd* /usr/bin/
```

## Install ETCDCTL - ARM - MacOS (It won't be on the exam, but it must know for the environment setup)

### 1. Define variables clearly
export ETCD_VER=v3.5.17
export ARCH=arm64

### 2. Create a fresh workspace
mkdir -p /tmp/etcd-download
cd /tmp/etcd-download

### 3. Download (using -L to follow redirects)
DOWNLOAD_URL=https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-${ARCH}.tar.gz
curl -L ${DOWNLOAD_URL} -o etcd-linux.tar.gz

### 4. Extract and Install
tar xzvf etcd-linux.tar.gz --strip-components=1
sudo cp etcd etcdctl etcdutl /usr/bin/

### 5. Verify the version
etcd --version

## Backup the ETCD (etcd with options in the doc):

Log-in in the ETCD machine control plane, open the etcd.yaml at /etc/kubernetes/manifests.

```bash
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=<trusted-ca-file> --cert=<cert-file> --key=<key-file> \
  snapshot save <backup-file-location>
```

Need to define where is: "trusted-ca-file", "cert-file", "key-file", and define the snapshot save location "backup-file-location"

The path to the files are in: etcd.yaml:

- --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
- --cert-file=/etc/kubernetes/pki/etcd/server.crt
- --key-file=/etc/kubernetes/pki/etcd/server.key
- The save path will be at your choice or it will be passed in the exam day by the instructor

It will be like:

```bash
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key \
snapshot save /tmp/snapshot-cka.db
```

Once the command is done, the output will be like:

```bash
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key \
snapshot save /tmp/snapshot-cka.db
{"level":"info","ts":"2026-03-03T12:11:20.465825Z","caller":"snapshot/v3_snapshot.go:65","msg":"created temporary db file","path":"/tmp/snapshot-cka.db.part"}
{"level":"info","ts":"2026-03-03T12:11:20.472171Z","logger":"client","caller":"v3@v3.5.17/maintenance.go:212","msg":"opened snapshot stream; downloading"}
{"level":"info","ts":"2026-03-03T12:11:20.472192Z","caller":"snapshot/v3_snapshot.go:73","msg":"fetching snapshot","endpoint":"https://127.0.0.1:2379"}
{"level":"info","ts":"2026-03-03T12:11:20.521576Z","logger":"client","caller":"v3@v3.5.17/maintenance.go:220","msg":"completed snapshot read; closing"}
{"level":"info","ts":"2026-03-03T12:11:20.528801Z","caller":"snapshot/v3_snapshot.go:88","msg":"fetched snapshot","endpoint":"https://127.0.0.1:2379","size":"7.0 MB","took":"now"}
{"level":"info","ts":"2026-03-03T12:11:20.528921Z","caller":"snapshot/v3_snapshot.go:97","msg":"saved","path":"/tmp/snapshot-cka.db"}
Snapshot saved at /tmp/snapshot-cka.db
```

### Check status of a snapshot:

```bash
etcdutl --write-out=table snapshot status <name_of_snap>.db
```

### Try out the snapshot again with more resources:

kubectl create configmap restore
kubectl create deployment restore --image=nginx

ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key \
snapshot save /tmp/snapshot-cka-v1.db

Delete the config map and deployment:

kubectl delete cm restore
kubectl delete deploy restore

They exist in the snapshot created.

Check the status: 
etcdutl --write-out=table snapshot status snapshot-cka-v1.db

Now restore a snapshot:

Deprecated method:

ETCDCTL_API=3 etcdctl --data-dir=/var/lib/etcd-backup --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot restore /tmp/snapshot-cka-v1.db

The diference is that it will have the --data-dir flag and th restore instead of save.

Actual method:

etcdutl --data-dir <data-dir-location> snapshot restore <snapshot_name>.db

the data-dir-location will be created once the command is started.

Once restored, go in the kubernetes manifests folder: cd /etc/kubernetes/manifests/

Open in vi: etcd.yaml

Change the mount points:

```bash
spec:
  containers:
  - command:
    - etcd
    ...
    - --data-dir=/var/lib/etcd
    ...
  volumeMounts:
    - mountPath: /var/lib/etcd
      name: etcd-data
    ...
  volumes:
  - hostPath:
      ...
    name: etcd-certs
  - hostPath:
      path: /var/lib/etcd
```

to:

```bash
/var/lib/etcd-backup
```

Save it, kubelet will automatic apply.

During this process, the cluster is down.

Do a:

systemclt restart kubelet
systemctl restart containerd

Go in:

cd /etc/kubernetes/manifests

do:

mv etcd.yaml ../
mv kube-apiserver.yaml ../

To move to the directory kubernetes, and stop the cluster.

Wait, a little bit and move back:

cd /etc/kubernetes

mv etcd.yaml /etc/kubernetes/manifests/
mv kube-apiserver.yaml /etc/kubernetes/manifests/

To force the cluster to come back.

since i had created a configmap named restore and a deployment named restore, once the cluster is restarted, the snapshot restored will be presented like:

root@ubuntu1:/etc/kubernetes# kubectl get cm
NAME               DATA   AGE
kube-root-ca.crt   1      13d
restore            0      18h
root@ubuntu1:/etc/kubernetes# kubeclt get deploy
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
restore   1/1     1            1           18h
