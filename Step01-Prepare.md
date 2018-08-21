# Pre-Settings on all nodes

## 1. Modify /etc/ssh/sshd_config to allow ssh by root on all nodes

```
sed -i 's#PermitRootLogin prohibit-password#PermitRootLogin yes#g' /etc/ssh/sshd_config
systemctl restart sshd
```

## 2. Change the root password on all nodes (the new password is "password")

```
echo -e "password\npassword" | passwd -q
```

## 3. Enable ssh from deploy node to all the other nodes without password

```
ssh-keygen
ssh-copy-id 192.168.9.31
ssh-copy-id 192.168.9.32
ssh-copy-id 192.168.9.33
ssh-copy-id 192.168.9.34
ssh-copy-id 192.168.9.35
ssh-copy-id 192.168.9.36
```

## 4. Add hosts records to all nodes

```
cat << EOFEOF > /root/add-hosts.sh
#!/bin/bash
cat << EOF >> /etc/hosts

192.168.9.30     k8sdeploy
192.168.9.31     k8s01
192.168.9.32     k8s02
192.168.9.33     k8s03
192.168.9.34     k8s04
192.168.9.35     k8s05
192.168.9.36     k8s06
EOF
EOFEOF
```

```
chmod +x /root/add-hosts.sh
/root/add-hosts.sh
scp -p /root/add-hosts.sh 192.168.9.31:/root/
scp -p /root/add-hosts.sh 192.168.9.32:/root/
scp -p /root/add-hosts.sh 192.168.9.33:/root/
scp -p /root/add-hosts.sh 192.168.9.34:/root/
scp -p /root/add-hosts.sh 192.168.9.35:/root/
scp -p /root/add-hosts.sh 192.168.9.36:/root/
```

```
ssh 192.168.9.31 /root/add-hosts.sh
ssh 192.168.9.32 /root/add-hosts.sh
ssh 192.168.9.33 /root/add-hosts.sh
ssh 192.168.9.34 /root/add-hosts.sh
ssh 192.168.9.35 /root/add-hosts.sh
ssh 192.168.9.36 /root/add-hosts.sh
```

## 5. Install Docker v1.13.1 on all nodes

```
cat << EOF > /root/install-docker.sh
#!/bin/bash
curl -fsSL https://apt.dockerproject.org/gpg | sudo apt-key add -
apt-add-repository "deb https://apt.dockerproject.org/repo ubuntu-xenial main"
apt-get update
apt-cache policy docker-engine
apt-get install -y docker-engine=1.13.1-0~ubuntu-xenial
EOF
```

```
chmod +x /root/install-docker.sh
scp -p /root/install-docker.sh 192.168.9.31:/root/
scp -p /root/install-docker.sh 192.168.9.32:/root/
scp -p /root/install-docker.sh 192.168.9.33:/root/
scp -p /root/install-docker.sh 192.168.9.34:/root/
scp -p /root/install-docker.sh 192.168.9.35:/root/
scp -p /root/install-docker.sh 192.168.9.36:/root/
```

```
ssh 192.168.9.31 /root/install-docker.sh
ssh 192.168.9.32 /root/install-docker.sh
ssh 192.168.9.33 /root/install-docker.sh
ssh 192.168.9.34 /root/install-docker.sh
ssh 192.168.9.35 /root/install-docker.sh
ssh 192.168.9.36 /root/install-docker.sh
```

## 6. sysctl settings on all nodes

```
cat << EOFEOF > /root/set-sysctl.sh
#!/bin/bash
cat << EOF > /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl -p /etc/sysctl.d/k8s.conf
EOFEOF
```

```
chmod +x /root/set-sysctl.sh
scp -p /root/set-sysctl.sh 192.168.9.31:/root/
scp -p /root/set-sysctl.sh 192.168.9.32:/root/
scp -p /root/set-sysctl.sh 192.168.9.33:/root/
scp -p /root/set-sysctl.sh 192.168.9.34:/root/
scp -p /root/set-sysctl.sh 192.168.9.35:/root/
scp -p /root/set-sysctl.sh 192.168.9.36:/root/
```

```
ssh 192.168.9.31 /root/set-sysctl.sh
ssh 192.168.9.32 /root/set-sysctl.sh
ssh 192.168.9.33 /root/set-sysctl.sh
ssh 192.168.9.34 /root/set-sysctl.sh
ssh 192.168.9.35 /root/set-sysctl.sh
ssh 192.168.9.36 /root/set-sysctl.sh
```

## 7. Disable swap partition on all nodes

```
cat << 'EOF' > /root/disable-swap.sh
#!/bin/bash
swapoff -a
sysctl -w vm.swappiness=0
lines=$(cat /etc/fstab |grep -n swap | awk -F ":" '{print $1}')
for i in $lines; do sed -i "${i}s/^/#/" /etc/fstab; done
EOF
```

```
chmod +x /root/disable-swap.sh
scp -p /root/disable-swap.sh 192.168.9.31:/root/
scp -p /root/disable-swap.sh 192.168.9.32:/root/
scp -p /root/disable-swap.sh 192.168.9.33:/root/
scp -p /root/disable-swap.sh 192.168.9.34:/root/
scp -p /root/disable-swap.sh 192.168.9.35:/root/
scp -p /root/disable-swap.sh 192.168.9.36:/root/
```

```
ssh 192.168.9.31 /root/disable-swap.sh
ssh 192.168.9.32 /root/disable-swap.sh
ssh 192.168.9.33 /root/disable-swap.sh
ssh 192.168.9.34 /root/disable-swap.sh
ssh 192.168.9.35 /root/disable-swap.sh
ssh 192.168.9.36 /root/disable-swap.sh
```

## 8. Fix the warning message "No swap limit support" with docker

```
cat << 'EOF' > /root/disable-docker-warning.sh
#!/bin/bash
sed -i 's#GRUB_CMDLINE_LINUX=""#GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"#g' /etc/default/grub
update-grub
reboot
EOF
```

```
chmod +x /root/disable-docker-warning.sh
scp -p /root/disable-docker-warning.sh 192.168.9.31:/root/
scp -p /root/disable-docker-warning.sh 192.168.9.32:/root/
scp -p /root/disable-docker-warning.sh 192.168.9.33:/root/
scp -p /root/disable-docker-warning.sh 192.168.9.34:/root/
scp -p /root/disable-docker-warning.sh 192.168.9.35:/root/
scp -p /root/disable-docker-warning.sh 192.168.9.36:/root/
```

```
ssh 192.168.9.31 /root/disable-docker-warning.sh
ssh 192.168.9.32 /root/disable-docker-warning.sh
ssh 192.168.9.33 /root/disable-docker-warning.sh
ssh 192.168.9.34 /root/disable-docker-warning.sh
ssh 192.168.9.35 /root/disable-docker-warning.sh
ssh 192.168.9.36 /root/disable-docker-warning.sh
```

## 9. Change timezone to CST

```
ssh 192.168.9.31 timedatectl set-timezone Asia/Shanghai
ssh 192.168.9.32 timedatectl set-timezone Asia/Shanghai
ssh 192.168.9.33 timedatectl set-timezone Asia/Shanghai
ssh 192.168.9.34 timedatectl set-timezone Asia/Shanghai
ssh 192.168.9.35 timedatectl set-timezone Asia/Shanghai
ssh 192.168.9.36 timedatectl set-timezone Asia/Shanghai
```
