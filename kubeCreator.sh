#kubeadm join 10.171.52.205:6443 --token 2udm83.epzhbvcgro00ukj7 \
#    --discovery-token-ca-cert-hash sha256:d47ae7153a4f7ed40b837483d846caeba4f0803453021390f8b222a7ae1356a9

#!/bin/bash

#variables
localip="10.171.52.207"
proxy="http://10.239.57.126:443/"
proxy_conf="/etc/systemd/system/docker.service.d/http-proxy.conf"
bashrc="$HOME/.bashrc"

#validations


#init
echo " Hello User, I am going to deploy a k8s-cluster for you, remember this is for quick deployment of cluster on your machine. Where master Node will act as worker like miniKube."
echo " this setup is based on for Ubuntu Bionic "
echo " This file works best as root user on Orange VMware machines"
export http_proxy=${proxy}
export https_proxy=http://10.239.57.126:443

#echo "Let's start with setting up your machine"
echo "setting up docker"
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

#sudo su
#echo "ubuntu"

apt-key fingerprint 0EBFCD88
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-cache policy docker-ce
apt-get install -y docker-ce
docker run hello-world
systemctl status docker
# Linux post-install
#sudo groupadd docker
#sudo usermod -aG docker $USER
systemctl enable docker
mkdir /etc/systemd/system/docker.service.d

sed -i '$a [Service]' ${proxy_conf}  \
       '$a Environment=’HTTP_PROXY=${proxy}’ '  ${proxy_conf} \
       '$a Environment=’NO_PROXY=localhost,127.0.0.0, ${localip}’ ' ${proxy_conf}

systemctl daemon-reload
systemctl restart docker

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo deb http://apt.kubernetes.io/ kubernetes-xenial main >> /etc/apt/sources.list.d/kubernetes.list

apt-get update -y

apt-get install -y \
        kubelet \
        kubeadm \
        kubernetes-cni

echo "let's setup proxy in .bashrc file"

sed -i '$a export http_proxy=http://10.239.57.126:443/  \
        export HTTP_PROXY=$http_proxy    \
        export https_proxy=$http_proxy    \ 
        export HTTPS_PROXY=$http_proxy     \
        printf -v lan '%s,' ${localip}   \
        printf -v pool '%s,' 192.168.0.{1..253}  \
        printf -v service '%s,' 10.96.0.{1..253}   \
        export no_proxy="${lan%,},${service%,},${pool%,},127.0.0.1";  \
        export NO_PROXY=$no_proxy ' ${bashrc}

source ${bashrc}

kubeadm init --apiserver-advertise-address=${localip} --service-cidr=10.96.0.0/16

mkdir -p $HOME/.kube
         cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
         chown root:root $HOME/.kube/config

kubectl taint nodes --all node-role.kubernetes.io/master-
export KUBECONFIG=/etc/kubernetes/kubelet.conf
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml 

kubectl get pods --all-namespaces -o wide > kubectlout.txt





