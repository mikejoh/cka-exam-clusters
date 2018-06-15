#!/bin/bash

# Provision Pod network routes in GCE

for instance in worker-0 worker-1; do
  gcloud compute instances describe ${instance} \
    --format 'value[separator=" "](networkInterfaces[0].networkIP,metadata.items[0].value)'
done

for i in 0 1; do
  gcloud compute routes create k8s-cluster-route-10-200-${i}-0-24 \
    --network k8s-cluster-network \
    --next-hop-address 10.240.0.2${i} \
    --destination-range 10.200.${i}.0/24
done

gcloud compute routes list --filter "network: k8s-cluster-network"