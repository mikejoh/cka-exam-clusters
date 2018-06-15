#!/bin/bash

#
# Script that creates the first CKA exam cluster scenario.
#
# Cluster composition:
#   1. etcd-0
#   2. master-0
#   3. worker-0
#   4. worker-1
# 

echo 
echo "Let's do this!"
echo

echo "Creating cluster network..."
gcloud compute networks create k8s-cluster-network --subnet-mode custom

echo "Creating cluster network subnet used by the instances..."
gcloud compute networks subnets create k8s-cluster-network \
  --network k8s-cluster-network \
  --range 10.240.0.0/24

echo "Creating firewall rule that allows internal communication within the cluster..."
gcloud compute firewall-rules create k8s-cluster-allow-internal \
  --allow tcp,udp,icmp \
  --network k8s-cluster-network \
  --source-ranges 10.240.0.0/24,10.200.0.0/16

echo "Creating firewall rule that allows external communication to the cluster..."
gcloud compute firewall-rules create k8s-cluster-allow-external \
  --allow tcp:22,tcp:6443,icmp \
  --network k8s-cluster-network \
  --source-ranges 0.0.0.0/0

echo "Creating a static external IP address..."
gcloud compute addresses create k8s-cluster-external \
  --region $(gcloud config get-value compute/region)

echo "Creating cluster instances..."
k8s_cluster=(etcd-0 master-0 worker-0 worker-1)

worker_ip_start=20
worker_pod_ip_start=0

for host in ${k8s_cluster[@]}
do
  tag=$(echo $host | sed -e 's/-.*//g')
  if [[ $host = *"worker"* ]]
  then
    gcloud compute instances create ${host} \
      --async \
      --boot-disk-size 20GB \
      --can-ip-forward \
      --image-family ubuntu-1804-lts \
      --image-project ubuntu-os-cloud \
      --machine-type n1-standard-1 \
      --metadata pod-cidr=10.200.${worker_pod_ip_start}.0/24 \
      --private-network-ip 10.240.0.${worker_ip_start} \
      --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
      --subnet k8s-cluster-network \
      --tags k8s,${tag}
    
    worker_ip_start=$((worker_ip_start + 1))
    worker_pod_ip_start=$((worker_pod_ip_start + 1))
  elif [[ $host = *"master"* ]]
  then
    gcloud compute instances create ${host} \
      --async \
      --boot-disk-size 20GB \
      --can-ip-forward \
      --image-family ubuntu-1804-lts \
      --image-project ubuntu-os-cloud \
      --machine-type n1-standard-1 \
      --private-network-ip 10.240.0.10 \
      --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
      --subnet k8s-cluster-network \
      --tags k8s,${tag}
  elif [[ $host = *"etcd"* ]]
  then
    gcloud compute instances create ${host} \
      --async \
      --boot-disk-size 20GB \
      --can-ip-forward \
      --image-family ubuntu-1804-lts \
      --image-project ubuntu-os-cloud \
      --machine-type n1-standard-1 \
      --private-network-ip 10.240.0.11 \
      --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
      --subnet k8s-cluster-network \
      --tags k8s,${tag}
  else
    echo "$host not recognized, exiting..."
    exit 1
  fi
done

read -p "CHECK THE STATUS OF CREATED INSTANCES!" -n 1 -r

echo "Creating certificates..."
mkdir $PWD/k8s-files
cd $PWD/k8s-files

echo "Creating the CA certificate"
{

cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Cloudland",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Cloud St"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca

}

echo "Creating the admin certificate..."
{

cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Cloudland",
      "O": "system:masters",
      "OU": "CKA The Hard Way",
      "ST": "Cloud St"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin

}

echo "Creating the kubelet client certificates..."
for instance in worker-0 worker-1; do
cat > ${instance}-csr.json <<EOF
{
  "CN": "system:node:${instance}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Cloudland",
      "O": "system:nodes",
      "OU": "CKA The Hard Way",
      "ST": "Cloud St"
    }
  ]
}
EOF

EXTERNAL_IP=$(gcloud compute instances describe ${instance} \
  --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')

INTERNAL_IP=$(gcloud compute instances describe ${instance} \
  --format 'value(networkInterfaces[0].networkIP)')

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${instance},${EXTERNAL_IP},${INTERNAL_IP} \
  -profile=kubernetes \
  ${instance}-csr.json | cfssljson -bare ${instance}
done

echo "Creating the kube-controller-manager client certificate..."
{

cat > kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Cloudland",
      "O": "system:kube-controller-manager",
      "OU": "CKA The Hard Way",
      "ST": "Cloud St"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

}

echo "Creating the kube-proxy client certificate..."
{

cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Cloudland",
      "O": "system:node-proxier",
      "OU": "CKA The Hard Way",
      "ST": "Cloud St"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy

}

echo "Creating the kube-scheduler client certificate..."
{

cat > kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Cloudland",
      "O": "system:kube-scheduler",
      "OU": "CKA The Hard Way",
      "ST": "Cloud St"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler

}

echo "Creating the kube-apiserver certificate..."
{

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe k8s-cluster-external \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')

cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Cloudland",
      "O": "Kubernetes",
      "OU": "CKA The Hard Way",
      "ST": "Cloud St"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.32.0.1,10.240.0.11,10.240.0.10,${KUBERNETES_PUBLIC_ADDRESS},k8s.robotnik.io,127.0.0.1,kubernetes.default \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

}

echo "Creating the Service Account key pair..."
{

cat > service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Cloudland",
      "O": "Kubernetes",
      "OU": "CKA The Hard Way",
      "ST": "Cloud St"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account

}

echo "Distribute certificates and keys to worker instances..."
for instance in worker-0 worker-1; do
  gcloud compute scp ca.pem ${instance}-key.pem ${instance}.pem ${instance}:~/
done

echo "Distribute certificate(s) and key(s) to etcd-0..."
gcloud compute scp ca.pem kubernetes-key.pem kubernetes.pem etcd-0:~/

echo "Distribute certificate(s) and key(s) to master-0..."
gcloud compute scp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem service-account-key.pem service-account.pem master-0:~/

echo "Generate Kubernetes configuration files for authentication..."
KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe k8s-cluster-external \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')

echo "Generate kubeconfig files for kubelets..."
for instance in worker-0 worker-1; do
  kubectl config set-cluster k8s-cluster \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=${instance}.pem \
    --client-key=${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=k8s-cluster \
    --user=system:node:${instance} \
    --kubeconfig=${instance}.kubeconfig

  kubectl config use-context default --kubeconfig=${instance}.kubeconfig
done

echo "Generate a kubeconfig for the kube-proxy service..."
{
  kubectl config set-cluster k8s-cluster \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=kube-proxy.pem \
    --client-key=kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=k8s-cluster \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
}

echo "Generate a kubeconfig for the kube-controller-manager..."
{
  kubectl config set-cluster k8s-cluster \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=kube-controller-manager.pem \
    --client-key=kube-controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-context default \
    --cluster=k8s-cluster \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
}

echo "Generate a kubeconfig for the kube-scheduler..."
{
  kubectl config set-cluster k8s-cluster \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=kube-scheduler.pem \
    --client-key=kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster=k8s-cluster \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
}

echo "Generate a kubeconfig for the admin user..."
{
  kubectl config set-cluster k8s-cluster \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=admin.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem \
    --embed-certs=true \
    --kubeconfig=admin.kubeconfig

  kubectl config set-context default \
    --cluster=k8s-cluster \
    --user=admin \
    --kubeconfig=admin.kubeconfig

  kubectl config use-context default --kubeconfig=admin.kubeconfig
}

echo "Distribute the kubeconfig files to worker instances..."
for instance in worker-0 worker-1; do
  gcloud compute scp ${instance}.kubeconfig kube-proxy.kubeconfig ${instance}:~/
done

echo "Distribute the kubeconfig files to the master instance..."
gcloud compute scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig master-0:~/

echo "Generating the data encryption config and key..."
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

echo "Copy the encryption config file to the master instance..."
gcloud compute scp encryption-config.yaml master-0:~/

echo "Finished! Now continue with bootstrapping the etcd-0 instance!"