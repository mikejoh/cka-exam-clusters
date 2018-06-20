#!/bin/bash

# Deploy DNS addon
# 
# This yaml-file provides needed manifests to run kube-dns and service discovery for application within the cluster.
#
# Breakdown of the yaml:
# 1. Creates a Service object for kube-dns with a ClusterIP of 10.32.0.10
# 2. Creates a ServiceAccount object 
# 3. Creates a ConfigMap object for the kube-dns-config
# 4. Creates a Deployment, specifies three containers:
#     * kube-dns:    Watches the Kubernetes master for changes in Services and Endpoints, in-memory lookups to serve DNS requests
#     * dnsmasq:     Adds DNS caching and improve performance
#     * sidecar:     Provides a single health check endpoint while performing dual healtchecks (for dnsmasq and kubedns)
#

kubectl create -f https://storage.googleapis.com/kubernetes-the-hard-way/kube-dns.yaml