#!/bin/bash
set -eu

##### Constant Definition Begin #####

# for K8S Master Nodes
K8S_VERSION=v1.11.1
K8S_MASTER_HOST1=k8s01
K8S_MASTER_HOST2=k8s02
K8S_MASTER_HOST3=k8s03
K8S_MASTER_IP1=192.168.9.31
K8S_MASTER_IP2=192.168.9.32
K8S_MASTER_IP3=192.168.9.33
K8S_MASTER_VIP=192.168.9.100
K8S_MASTER_VIP_PORT=6443
K8S_KUBE_APISERVER_ENTRY=https://${K8S_MASTER_VIP}:${K8S_MASTER_VIP_PORT}
K8S_CLUSTER_SVC_IP=10.96.0.1
K8S_DIR=/etc/kubernetes
K8S_PKI_DIR=${K8S_DIR}/pki

# for K8S Minion Nodes
K8S_MINION_HOSTS="k8s04 k8s05"
K8S_MINION_IP="192.168.9.34 192.168.9.35"

##### Constant Definition End #####

##### Setup Minion Nodes Begin #####
for NODE in ${K8S_MINION_HOSTS}; do
    echo "--- $NODE ---"
    ssh ${NODE} "mkdir -p /etc/kubernetes/pki/"
    for FILE in pki/ca.pem pki/ca-key.pem bootstrap-kubelet.conf; do
      scp /etc/kubernetes/${FILE} ${NODE}:/etc/kubernetes/${FILE}
    done
done

for NODE in ${K8S_MINION_HOSTS}; do
    echo "--- $NODE ---"
    ssh ${NODE} "mkdir -p /var/lib/kubelet /var/log/kubernetes /var/lib/etcd /etc/systemd/system/kubelet.service.d /etc/kubernetes/manifests"
    scp node/var/lib/kubelet/config.yml ${NODE}:/var/lib/kubelet/config.yml
    scp node/systemd/kubelet.service ${NODE}:/lib/systemd/system/kubelet.service
    scp node/systemd/10-kubelet.conf ${NODE}:/etc/systemd/system/kubelet.service.d/10-kubelet.conf
done

for NODE in ${K8S_MINION_HOSTS}; do
    ssh ${NODE} "systemctl enable kubelet.service && systemctl start kubelet.service"
done
##### Setup Minion Nodes End #####
