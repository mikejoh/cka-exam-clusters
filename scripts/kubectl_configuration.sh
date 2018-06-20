#!/bin/bash

# Run this in the directory where you created the admin certificate and key files

{
  KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe k8s-cluster-external \
    --region $(gcloud config get-value compute/region) \
    --format 'value(address)')

  kubectl config set-cluster k8s-cluster \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443

  kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem

  kubectl config set-context k8s-cluster-context \
    --cluster=k8s-cluster \
    --user=admin

  kubectl config use-context k8s-cluster-context
}