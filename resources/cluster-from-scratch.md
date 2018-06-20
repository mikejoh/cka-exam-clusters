# Creating a cluster from scratch

_Notes to self_

## Network

Kubernetes allocates an IP address to each pod. When you create a cluster, you need to allocate a block of IPs for Kubernetes to use as Pod IPs, the simplest way is to allocate a different block of IPs to each node in the cluster as the node is added.

Pod-to-Pod connectivity can be acheived in two ways:
1. Overlay network (encapsulation e.g. with VXLAN)
2. Without overlay, instead use the underlying network fabric to be aware of Pod IPs. Does not require encapsulation.

Kubernetes also allocates an IP to each `Service` object, however Service IPs do not need to be routable, the `kube-proxy` take care of translating Service IPs to Pod IPs before traffic leaves the node.                                                                              
### Network Policy

Kubernetes enables the definition of fine-grained network policy between Pods using the `NetworkPolicy` resource.

## Cluster naming

Pick a name for your cluster, a short one.

## Software binaries

You'll need binaries for:
* `etcd`
* Container runtime: `docker` (actually `containerd`) or `rkt`
* Kubernetes
  * `kubelet`
  * `kube-proxy`
  * `kube-apiserver`
  * `kube-controller-manager`
  * `kube-scheduler`

  ## Security models

  * Accessing API server over HTTP
  * Accessing API server over HTTPS