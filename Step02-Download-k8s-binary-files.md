# Download and distribute binary files for Kubernetes

## 1. Download

```
export KUBE_URL=https://storage.googleapis.com/kubernetes-release/release/v1.11.1/bin/linux/amd64
curl -L -o /root/kubelet ${KUBE_URL}/kubelet
curl -L -o /root/kubectl ${KUBE_URL}/kubectl
chmod +x /root/kubelet /root/kubectl
```

```
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat << EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt update && apt install -d kubernetes-cni=0.6.0-00
```

## 2. Distribute

```
scp -p /root/kubelet 192.168.9.31:/usr/local/bin/
scp -p /root/kubelet 192.168.9.32:/usr/local/bin/
scp -p /root/kubelet 192.168.9.33:/usr/local/bin/
scp -p /root/kubelet 192.168.9.34:/usr/local/bin/
scp -p /root/kubelet 192.168.9.35:/usr/local/bin/
scp -p /root/kubelet 192.168.9.36:/usr/local/bin/
scp -p /root/kubectl 192.168.9.31:/usr/local/bin/
scp -p /root/kubectl 192.168.9.32:/usr/local/bin/
scp -p /root/kubectl 192.168.9.33:/usr/local/bin/
scp -p /root/kubectl 192.168.9.34:/usr/local/bin/
scp -p /root/kubectl 192.168.9.35:/usr/local/bin/
scp -p /root/kubectl 192.168.9.36:/usr/local/bin/
```

```
scp /var/cache/apt/archives/kubernetes-cni_0.6.0-00_amd64.deb 192.168.9.31:/root/
scp /var/cache/apt/archives/kubernetes-cni_0.6.0-00_amd64.deb 192.168.9.32:/root/
scp /var/cache/apt/archives/kubernetes-cni_0.6.0-00_amd64.deb 192.168.9.33:/root/
scp /var/cache/apt/archives/kubernetes-cni_0.6.0-00_amd64.deb 192.168.9.34:/root/
scp /var/cache/apt/archives/kubernetes-cni_0.6.0-00_amd64.deb 192.168.9.35:/root/
scp /var/cache/apt/archives/kubernetes-cni_0.6.0-00_amd64.deb 192.168.9.36:/root/
```

```
ssh 192.168.9.31 dpkg -i /root/kubernetes-cni_0.6.0-00_amd64.deb
ssh 192.168.9.32 dpkg -i /root/kubernetes-cni_0.6.0-00_amd64.deb
ssh 192.168.9.33 dpkg -i /root/kubernetes-cni_0.6.0-00_amd64.deb
ssh 192.168.9.34 dpkg -i /root/kubernetes-cni_0.6.0-00_amd64.deb
ssh 192.168.9.35 dpkg -i /root/kubernetes-cni_0.6.0-00_amd64.deb
ssh 192.168.9.36 dpkg -i /root/kubernetes-cni_0.6.0-00_amd64.deb
```
