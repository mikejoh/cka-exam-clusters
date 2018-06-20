# Manage TLS Certificates in a Cluster

_Note to self_

Every Kubernetes cluster has a cluster root CA. The CA is generally used by cluster components to:

* Validate the API servers certificate
* By the API server to validate kubelet client certficates

To support this the CA certificate bundle is distributed to every node in the cluster and is distributed as a **secret** attached to _default ServiceAccounts_. 

The CA certificate bundle is _automatically_ mounted into pods using the default ServiceAccount at the path `/var/run/secrets/kubernetes.io/serviceaccount/ca.crt`

