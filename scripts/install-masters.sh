#!/bin/bash
set -eu

##### Constant Definition Begin #####

# for etcd
ETCD_VERSION=3.2.18
ETCD_HOST1=k8s01
ETCD_HOST2=k8s02
ETCD_HOST3=k8s03
ETCD_IP1=192.168.9.31
ETCD_IP2=192.168.9.32
ETCD_IP3=192.168.9.33
ETCD_PKI_DIR=/etc/etcd/ssl

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

# for CNI
CNI_VERSION=0.6.0

# for Flannel
FLANNEL_VERSION=v0.10.0-amd64

# for Calico


# for CoreDNS
COREDNS_VERSION=1.1.3

# for K8S Dashboard
K8S_DASHBOARD_VERSION=v1.8.3

# for KubeDNS

##### Constant Definition End #####

cd pki

##### Generate certificate for etcd #####
mkdir -p ${ETCD_PKI_DIR}

cfssl gencert -initca etcd-ca-csr.json | cfssljson -bare ${ETCD_PKI_DIR}/etcd-ca
cfssl gencert \
  -ca=${ETCD_PKI_DIR}/etcd-ca.pem \
  -ca-key=${ETCD_PKI_DIR}/etcd-ca-key.pem \
  -config=ca-config.json \
  -hostname=127.0.0.1,${ETCD_IP1},${ETCD_IP2},${ETCD_IP3} \
  -profile=kubernetes \
  etcd-csr.json | cfssljson -bare ${ETCD_PKI_DIR}/etcd
rm -rf ${ETCD_PKI_DIR}/*.csr

# SCP certificate to etcd nodes
for NODE in ${ETCD_HOST1} ${ETCD_HOST2} ${ETCD_HOST3}; do
  echo "--- $NODE ---"
  ssh ${NODE} " mkdir -p /etc/etcd/ssl"
  for FILE in etcd-ca-key.pem  etcd-ca.pem  etcd-key.pem  etcd.pem; do
    scp ${ETCD_PKI_DIR}/${FILE} ${NODE}:${ETCD_PKI_DIR}/${FILE}
  done
done

##### Generate certificates Kubernetes Begin #####
mkdir -p ${K8S_PKI_DIR}

# K8S CA
cfssl gencert -initca ca-csr.json | cfssljson -bare ${K8S_PKI_DIR}/ca

# K8S API Server
cfssl gencert \
  -ca=${K8S_PKI_DIR}/ca.pem \
  -ca-key=${K8S_PKI_DIR}/ca-key.pem \
  -config=ca-config.json \
  -hostname=127.0.0.1,${K8S_CLUSTER_SVC_IP},${K8S_MASTER_HOST1},${K8S_MASTER_HOST2},${K8S_MASTER_HOST3},${K8S_MASTER_IP1},${K8S_MASTER_IP2},${K8S_MASTER_IP3},${K8S_MASTER_VIP},kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster.local \
  -profile=kubernetes \
  apiserver-csr.json | cfssljson -bare ${K8S_PKI_DIR}/apiserver

# K8S Front Proxy Client
cfssl gencert -initca front-proxy-ca-csr.json | cfssljson -bare ${K8S_PKI_DIR}/front-proxy-ca
cfssl gencert \
  -ca=${K8S_PKI_DIR}/front-proxy-ca.pem \
  -ca-key=${K8S_PKI_DIR}/front-proxy-ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  front-proxy-client-csr.json | cfssljson -bare ${K8S_PKI_DIR}/front-proxy-client

# K8S Controller Manager
cfssl gencert \
  -ca=${K8S_PKI_DIR}/ca.pem \
  -ca-key=${K8S_PKI_DIR}/ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  manager-csr.json | cfssljson -bare ${K8S_PKI_DIR}/controller-manager

kubectl config set-cluster kubernetes \
    --certificate-authority=${K8S_PKI_DIR}/ca.pem \
    --embed-certs=true \
    --server=${K8S_KUBE_APISERVER_ENTRY} \
    --kubeconfig=${K8S_DIR}/controller-manager.conf

kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=${K8S_PKI_DIR}/controller-manager.pem \
    --client-key=${K8S_PKI_DIR}/controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=${K8S_DIR}/controller-manager.conf

kubectl config set-context system:kube-controller-manager@kubernetes \
    --cluster=kubernetes \
    --user=system:kube-controller-manager \
    --kubeconfig=${K8S_DIR}/controller-manager.conf

kubectl config use-context system:kube-controller-manager@kubernetes \
    --kubeconfig=${K8S_DIR}/controller-manager.conf

# K8S Scheduler
cfssl gencert \
  -ca=${K8S_PKI_DIR}/ca.pem \
  -ca-key=${K8S_PKI_DIR}/ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  scheduler-csr.json | cfssljson -bare ${K8S_PKI_DIR}/scheduler

kubectl config set-cluster kubernetes \
    --certificate-authority=${K8S_PKI_DIR}/ca.pem \
    --embed-certs=true \
    --server=${K8S_KUBE_APISERVER_ENTRY} \
    --kubeconfig=${K8S_DIR}/scheduler.conf

kubectl config set-credentials system:kube-scheduler \
    --client-certificate=${K8S_PKI_DIR}/scheduler.pem \
    --client-key=${K8S_PKI_DIR}/scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=${K8S_DIR}/scheduler.conf

kubectl config set-context system:kube-scheduler@kubernetes \
    --cluster=kubernetes \
    --user=system:kube-scheduler \
    --kubeconfig=${K8S_DIR}/scheduler.conf

kubectl config use-context system:kube-scheduler@kubernetes \
    --kubeconfig=${K8S_DIR}/scheduler.conf

# K8S Admin
cfssl gencert \
  -ca=${K8S_PKI_DIR}/ca.pem \
  -ca-key=${K8S_PKI_DIR}/ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare ${K8S_PKI_DIR}/admin

kubectl config set-cluster kubernetes \
    --certificate-authority=${K8S_PKI_DIR}/ca.pem \
    --embed-certs=true \
    --server=${K8S_KUBE_APISERVER_ENTRY} \
    --kubeconfig=${K8S_DIR}/admin.conf

kubectl config set-credentials kubernetes-admin \
    --client-certificate=${K8S_PKI_DIR}/admin.pem \
    --client-key=${K8S_PKI_DIR}/admin-key.pem \
    --embed-certs=true \
    --kubeconfig=${K8S_DIR}/admin.conf

kubectl config set-context kubernetes-admin@kubernetes \
    --cluster=kubernetes \
    --user=kubernetes-admin \
    --kubeconfig=${K8S_DIR}/admin.conf

kubectl config use-context kubernetes-admin@kubernetes \
    --kubeconfig=${K8S_DIR}/admin.conf

# K8S Kubelet
for NODE in ${K8S_MASTER_HOST1} ${K8S_MASTER_HOST2} ${K8S_MASTER_HOST3}; do
    echo "--- $NODE ---"
    cp kubelet-csr.json kubelet-$NODE-csr.json;
    sed -i "s/\$NODE/$NODE/g" kubelet-$NODE-csr.json;
    cfssl gencert \
      -ca=${K8S_PKI_DIR}/ca.pem \
      -ca-key=${K8S_PKI_DIR}/ca-key.pem \
      -config=ca-config.json \
      -hostname=$NODE \
      -profile=kubernetes \
      kubelet-$NODE-csr.json | cfssljson -bare ${K8S_PKI_DIR}/kubelet-$NODE;
    rm kubelet-$NODE-csr.json
done

for NODE in ${K8S_MASTER_HOST1} ${K8S_MASTER_HOST2} ${K8S_MASTER_HOST3}; do
    echo "--- $NODE ---"
    ssh ${NODE} "mkdir -p ${K8S_PKI_DIR}"
    scp ${K8S_PKI_DIR}/ca.pem ${NODE}:${K8S_PKI_DIR}/ca.pem
    scp ${K8S_PKI_DIR}/kubelet-$NODE-key.pem ${NODE}:${K8S_PKI_DIR}/kubelet-key.pem
    scp ${K8S_PKI_DIR}/kubelet-$NODE.pem ${NODE}:${K8S_PKI_DIR}/kubelet.pem
    rm ${K8S_PKI_DIR}/kubelet-$NODE-key.pem ${K8S_PKI_DIR}/kubelet-$NODE.pem
done

for NODE in ${K8S_MASTER_HOST1} ${K8S_MASTER_HOST2} ${K8S_MASTER_HOST3}; do
    echo "--- $NODE ---"
    ssh ${NODE} "cd ${K8S_PKI_DIR} && \
      kubectl config set-cluster kubernetes \
        --certificate-authority=${K8S_PKI_DIR}/ca.pem \
        --embed-certs=true \
        --server=${K8S_KUBE_APISERVER_ENTRY} \
        --kubeconfig=${K8S_DIR}/kubelet.conf && \
      kubectl config set-credentials system:node:${NODE} \
        --client-certificate=${K8S_PKI_DIR}/kubelet.pem \
        --client-key=${K8S_PKI_DIR}/kubelet-key.pem \
        --embed-certs=true \
        --kubeconfig=${K8S_DIR}/kubelet.conf && \
      kubectl config set-context system:node:${NODE}@kubernetes \
        --cluster=kubernetes \
        --user=system:node:${NODE} \
        --kubeconfig=${K8S_DIR}/kubelet.conf && \
      kubectl config use-context system:node:${NODE}@kubernetes \
        --kubeconfig=${K8S_DIR}/kubelet.conf"
done

# K8S Service Account Key
openssl genrsa -out ${K8S_PKI_DIR}/sa.key 2048
openssl rsa -in ${K8S_PKI_DIR}/sa.key -pubout -out ${K8S_PKI_DIR}/sa.pub

##### Generate certificates Kubernetes End #####

cd ..

# Clean temporary files
rm -rf ${K8S_PKI_DIR}/*.csr \
    ${K8S_PKI_DIR}/scheduler*.pem \
    ${K8S_PKI_DIR}/controller-manager*.pem \
    ${K8S_PKI_DIR}/admin*.pem \
    ${K8S_PKI_DIR}/kubelet*.pem

# Copy files to all master nodes
for NODE in ${K8S_MASTER_HOST1} ${K8S_MASTER_HOST2} ${K8S_MASTER_HOST3}; do
    echo "--- $NODE ---"
    for FILE in $(ls ${K8S_PKI_DIR}); do
      scp ${K8S_PKI_DIR}/${FILE} ${NODE}:${K8S_PKI_DIR}/${FILE}
    done
done

for NODE in ${K8S_MASTER_HOST1} ${K8S_MASTER_HOST2} ${K8S_MASTER_HOST3}; do
    echo "--- $NODE ---"
    for FILE in admin.conf controller-manager.conf scheduler.conf; do
      scp ${K8S_DIR}/${FILE} ${NODE}:${K8S_DIR}/${FILE}
    done
done

##### Generate HAProxy and etcd configuration files for master nodes Begin #####

: ${ETCD_TPML:="master/etc/etcd/config.yml"}
: ${HAPROXY_TPML:="master/etc/haproxy/haproxy.cfg"}

RED='\033[0;31m'
NC='\033[0m'

# generate envs
ETCD_SERVERS=""
HAPROXY_BACKENDS=""
for NODE in ${K8S_MASTER_HOST1} ${K8S_MASTER_HOST2} ${K8S_MASTER_HOST3}; do
  IP=$(ssh ${NODE} "ip route get 8.8.8.8" | awk '{print $NF; exit}')
  ETCD_SERVERS="${ETCD_SERVERS}${NODE}=https:\/\/${IP}:2380,"
  HAPROXY_BACKENDS="${HAPROXY_BACKENDS}    server ${NODE}-api ${IP}:6443 check\n"
done
ETCD_SERVERS=$(echo ${ETCD_SERVERS} | sed 's/.$//')

# generating config
for NODE in ${K8S_MASTER_HOST1} ${K8S_MASTER_HOST2} ${K8S_MASTER_HOST3}; do
  IP=$(ssh ${NODE} "ip route get 8.8.8.8" | awk '{print $NF; exit}')
  ssh ${NODE} "sudo mkdir -p /etc/etcd /etc/haproxy"

  # etcd
  scp ${ETCD_TPML} ${NODE}:/etc/etcd/config.yml 2>&1 > /dev/null
  ssh ${NODE} "sed -i 's/\${HOSTNAME}/${NODE}/g' /etc/etcd/config.yml;
               sed -i 's/\${PUBLIC_IP}/${IP}/g' /etc/etcd/config.yml;
               sed -i 's/\${ETCD_SERVERS}/${ETCD_SERVERS}/g' /etc/etcd/config.yml;"

  # haproxy
  scp ${HAPROXY_TPML} ${NODE}:/etc/haproxy/haproxy.cfg 2>&1 > /dev/null
  ssh ${NODE} "sed -i 's/\${API_SERVERS}/${HAPROXY_BACKENDS}/g' /etc/haproxy/haproxy.cfg"
  echo "${RED}${NODE}${NC} config generated..."
done

##### Generate HAProxy and etcd configuration files for master nodes End #####

##### Generate manifests files for master nodes Begin #####

: ${ADVERTISE_VIP:=${K8S_MASTER_VIP}}
: ${MANIFESTS_TPML_DIR:="master/manifests"}
: ${ENCRYPT_TPML_DIR:="master/encryption"}
: ${ADUIT_TPML_DIR:="master/audit"}
: ${FILES:="etcd.yml haproxy.yml keepalived.yml kube-apiserver.yml kube-controller-manager.yml kube-scheduler.yml"}

MANIFESTS_PATH="/etc/kubernetes/manifests"
ENCRYPT_PATH="/etc/kubernetes/encryption"
ADUIT_PATH="/etc/kubernetes/audit"
HOST_START=$(ip route get 8.8.8.8 | awk '{print $NF; exit}')
ENCRYPT_SECRET=$(openssl rand -hex 16)

ETCD_SERVERS=""
UNICAST_PEERS=""
for NODE in ${K8S_MASTER_HOST1} ${K8S_MASTER_HOST2} ${K8S_MASTER_HOST3}; do
  IP=$(ssh ${NODE} "ip route get 8.8.8.8" | awk '{print $NF; exit}')
  ETCD_SERVERS="${ETCD_SERVERS}https:\/\/${IP}:2379,"
  UNICAST_PEERS="${UNICAST_PEERS}'${IP}',"
  HOST_END=${IP}
done
ETCD_SERVERS=$(echo ${ETCD_SERVERS} | sed 's/.$//')
UNICAST_PEERS=$(echo ${UNICAST_PEERS} | sed 's/,$//')

# generate manifests
i=0
for NODE in ${K8S_MASTER_HOST1} ${K8S_MASTER_HOST2} ${K8S_MASTER_HOST3}; do
  ssh ${NODE} "sudo mkdir -p ${MANIFESTS_PATH} ${ENCRYPT_PATH} ${ADUIT_PATH}"
  for FILE in ${FILES}; do
    scp ${MANIFESTS_TPML_DIR}/${FILE} ${NODE}:${MANIFESTS_PATH}/${FILE} 2>&1 > /dev/null
  done

  # configure keepalived
  NIC=$(ssh ${NODE} "ip route get 8.8.8.8" | awk '{print $5; exit}')
  PRIORITY=150
  if [ ${i} -eq 0 ]; then
    PRIORITY=100
  fi
  ssh ${NODE} "sed -i 's/\${ADVERTISE_VIP}/${ADVERTISE_VIP}/g' ${MANIFESTS_PATH}/keepalived.yml;
               sed -i 's/\${ADVERTISE_VIP_NIC}/${NIC}/g' ${MANIFESTS_PATH}/keepalived.yml;
               sed -i 's/\${UNICAST_PEERS}/${UNICAST_PEERS}/g' ${MANIFESTS_PATH}/keepalived.yml;
               sed -i 's/\${PRIORITY}/${PRIORITY}/g' ${MANIFESTS_PATH}/keepalived.yml"

  # configure kue-apiserver
  ssh ${NODE} "sed -i 's/\${ADVERTISE_VIP}/${ADVERTISE_VIP}/g' ${MANIFESTS_PATH}/kube-apiserver.yml;
               sed -i 's/\${ETCD_SERVERS}/${ETCD_SERVERS}/g' ${MANIFESTS_PATH}/kube-apiserver.yml;"

  # configure encryption
  scp ${ENCRYPT_TPML_DIR}/config.yml ${NODE}:${ENCRYPT_PATH}/config.yml 2>&1 > /dev/null
  ssh ${NODE} "sed -i 's/\${ENCRYPT_SECRET}/${ENCRYPT_SECRET}/g' ${ENCRYPT_PATH}/config.yml"

  # configure audit
  scp ${ADUIT_TPML_DIR}/policy.yml ${NODE}:${ADUIT_PATH}/policy.yml 2>&1 > /dev/null

  echo "${RED}${NODE}${NC} manifests generated..."
  i=$((i+1))
done

##### Generate manifests files for master nodes End #####

for NODE in ${K8S_MASTER_HOST1} ${K8S_MASTER_HOST2} ${K8S_MASTER_HOST3}; do
    echo "--- $NODE ---"
    ssh ${NODE} "mkdir -p /var/lib/kubelet /var/log/kubernetes /var/lib/etcd /etc/systemd/system/kubelet.service.d"
    scp master/var/lib/kubelet/config.yml ${NODE}:/var/lib/kubelet/config.yml
    scp master/systemd/kubelet.service ${NODE}:/lib/systemd/system/kubelet.service
    scp master/systemd/10-kubelet.conf ${NODE}:/etc/systemd/system/kubelet.service.d/10-kubelet.conf
done

for NODE in ${K8S_MASTER_HOST1} ${K8S_MASTER_HOST2} ${K8S_MASTER_HOST3}; do
    ssh ${NODE} "systemctl enable kubelet.service && systemctl start kubelet.service"
    ssh ${NODE} "cp -pf ${K8S_DIR}/admin.conf /root/.kube/config"
done

##### TLS Bootstrapping Begin ##### 
ssh ${K8S_MASTER_IP1} "mkdir -p /root/temp/k8s-install"
scp -p bootstrapping.sh ${K8S_MASTER_IP1}:/root/temp/k8s-install/
scp -pr master ${K8S_MASTER_IP1}:/root/temp/k8s-install/
ssh ${K8S_MASTER_IP1} "chmod +x /root/temp/k8s-install/bootstrapping.sh"

#execute below command after all pods are running
#ssh ${K8S_MASTER_IP1} "/root/temp/k8s-install/bootstrapping.sh"

##### TLS Bootstrapping End #####
