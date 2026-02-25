## ETCD Backup

[Operating ETCD Clusters for Kubernetes](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)

[Backing up an ectd cluster](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster)

[Restoring an ectd cluster](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#restoring-an-etcd-cluster)

## Install ETCDCTL - X86_64 - Cloud (It won't be on the exam, but it must know for the environment setup)

# 1. Get the install version
```bash
Install ETCDCTL - x86_64 machines

https://github.com/etcd-io/etcd/releases
```
# 1. Define variables clearly

```bash
ETCD_VER=v3.6.8
```

# 2. Choose the download URL

```bash
GOOGLE_URL=https://storage.googleapis.com/etcd
GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
DOWNLOAD_URL=${GOOGLE_URL}
```

# 3. Remove any leftover

```bash
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test
```

# 4. Download the latest version

```bash
curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1 --no-same-owner
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
```

# 5. Navigate to the etcd folder

```bash
cd /tmp/etcd-download-test/
```

# 6. Move the binaries to the correct folder

```bash
mv etcd* /usr/bin/
```



## Install ETCDCTL - ARM - MacOS (It won't be on the exam, but it must know for the environment setup)

# 1. Define variables clearly
export ETCD_VER=v3.5.17
export ARCH=arm64

# 2. Create a fresh workspace
mkdir -p /tmp/etcd-download
cd /tmp/etcd-download

# 3. Download (using -L to follow redirects)
DOWNLOAD_URL=https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-${ARCH}.tar.gz
curl -L ${DOWNLOAD_URL} -o etcd-linux.tar.gz

# 4. Extract and Install
tar xzvf etcd-linux.tar.gz --strip-components=1
sudo cp etcd etcdctl etcdutl /usr/bin/

# 5. Verify the version
etcd --version