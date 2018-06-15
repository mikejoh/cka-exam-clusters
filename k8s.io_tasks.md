# The k8s.io tasks

There's some great tasks over at [k8s.io](https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/) where you get to test _a lot_ of different things in regards to Kubernetes. It's a really good way of getting to know Kubernetes step by step, you don't have to do them sequentially and it's perfectly fine to cherry-pick tasks you find interesting or that covers areas you are interested in.

Far from all tasks requires a configured multi master setup and with a external etcd cluster, minikube works just fine.

I'm keeping track of which tasks i've done in this file and i'll be using the cluster created provided from this repo.

## Tasks status

Status | Task |  Notes
--- | --- |  ---
:white_check_mark: | Customizing DNS Service | Within the kube-dns ConfigMap you can specify `upstreamNameserver`. `dnsPolicy` for Pods are default set to `None`. If you configure `ClusterFirst` the name resolution is handled differently.
:black_square_button: | Assign Memory Resources to Containers and Pods | A container can _exceed_ its memory **request** if the Node has memory available. A container is _not allowed_ to use more than it's memory **limit**. If the container consume memory beyond it's limits the container is _terminated_. Reported status of a Pod can be e.g. `OOMKilled` (Out Of Memory).<br><br> Memory requests and limits are associated with _containers_ but it's useful to think o a Pod as having a memory request and limit. The memory _request_ are the sum of the memory requests for _all_ the containers in the Pod. Same goes for memory _limit_. <br><br> A Pod is scheduled to run on a Node only if the Node has _enough memory_ to satisfy the Pod's memory _request_. The status of the Pod would be `Pending` and a event would state that there's no available nodes to satisfy the specified resources.


