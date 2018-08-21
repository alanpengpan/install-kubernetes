# Kubernetes add-on settings

## scp the add-on folder to the first master node

```
git clone https://github.com/wise2ck8s/kubernetes-installation-scripts
scp -pr kubernetes-installation-scripts k8s01:/root/
```

## On the first master node set kube-proxy and coredns
```
cd /root/kubernetes-installation-scripts/
export KUBE_APISERVER=https://192.168.9.100:6443
for file in $(ls addons/kube-proxy/); do sed -i 's/\${KUBE_APISERVER}/${KUBE_APISERVER}/g' addons/kube-proxy/$file; done
kubectl create -f addons/kube-proxy/
kubectl create -f addons/coredns/
kubectl -n kube-system get pods -l k8s-app=kube-proxy -o wide
```

## Flannel Network

```
curl -L -o kube-flannel.yml https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl create -f kube-flannel.yml
```
