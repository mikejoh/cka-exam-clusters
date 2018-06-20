# One-liners (more or less)

## Troubleshooting
Get logs from a container in a Pod:

`kubectl logs POD -c CONTAINER`

Access the Init Container statuses programmatically by reading the `initContainerStatuses` field on the Pod Spec:

`kubectl get pod nginx --template '{{.status.initContainerStatuses}}'`

## kubectl
Enable `kubectl` completion (needs the `bash-completion` package):
```
source <(kubectl completion bash)
```
Dry-run, outputs Service (--expose) and a Deployment in yaml:
```
kubectl run --image=apache \ 
--port=80 \
--replicas=3 \
--restart='Always' \
--expose \
--requests='cpu=100m,memory=256Mi' \
--limits='cpu=200m,memory=512Mi' \
--labels=app=apache,version=1 \
--dry-run=true \
-o yaml
```
In a running container run `date`:
```
kubectl exec POD -- bash -c "date"
kubectl exec POD -- date
kubectl exec POD date
```
Remove label `this` from a pod:
```
kubectl label pod POD this-
```
Add label `that=thing` to a pod:
```
kubectl label pod POD that=thing
```
Select pods based on selector across all namespaces:
```
kubectl get pods --all-namespaces --selector this=label
```
Create a single Pod without a Deployment (`--restart=Never`) and a ReplicaSet:
```
kubectl run nginx --image=nginx --restart=Never
```
Create a single Pod with a Deployment (and a ReplicaSet):
```
kubectl run nginx --image=nginx --replicas=1
```
How the `--restart` flag behaves with `kubectl run`:
```
--restart=Never     Creates a single Pod without a Deployment or a ReplicaSet. You can achive this by creating a single Pod manifest and apply it.
--restart=OnFailure Creates a Pod and a Job.
--restart=Always    Default, creates a Deployment and a ReplicaSet object.
```
Copy file to/from a Pod:
```
kubectl cp POD:/path/to/file.txt ./file.txt
kubectl $HOME/file.txt POD:/path/to/file.txt
```
Patch a Deployment with a new image:
```
kubectl patch deployment nginx -p '{"spec":{"template":{"spec":{"containers":[{ "name":"nginx", "image":"nginx:1.13.1"}]}}}}'
```
## Manifests

Almost all Kubernetes objects and their Manifests looks the same, at least in the first few lines:
```
apiVersion: VERSION
kind: OBJECT_TYPE
metadata:
  annotations:
  labels:
  name:
spec:
```
Pod manifest with a Liveness Probe (from Kubernetes Up & Running):
```
apiVersion: v1
kind: Pod
metadata:
  name: kuard
spec:
  containers:
    - image: gcr.io/kuar-demo/kuard-amd64:1
      name: kuard
      livenessProbe:
        httpGet:
          path: /healthy
          port: 8080
        initialDelaySeconds: 5    <- Probe will not be used until 5 seconds after all the containers in the Pod are created
        timeoutSeconds: 1         <- Probe must respond within 1s
        periodSeconds: 10         <- Run every 10 seconds
        failureThreshold: 3       <- Fail after >3 attemps
      ports:
        - containerPort: 8080
          name: http
          protocol: TCP
```
Create a Pod from a manifest through `stdin`:
```
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: busybox-sleep
spec:
  containers:
  - name: busybox
    image: busybox
    args:
    - sleep
    - "10"
EOF
```
## gcloud one-liners

### Stop all instances
```
gcloud compute instances stop $(gcloud compute instances list | grep -v "NAME" | awk '{ print $1}')
```
### Start all instances
```
gcloud compute instances start --async $(gcloud compute instances list | grep -v NAME | awk '{ print $1 }')
```
### Manually create a network (`--subnet-mode custom`)
```
gcloud compute networks create k8s --subnet-mode custom
```
### Create a subnet within a network
```
gcloud compute networks subnets create k8s-nodes --network k8s --range 10.0.0.0/24
```
### Change configuration settings, set project for gcloud
```
gcloud config set core/project cka-exam-prep
```
### Add firewall allowing internal traffic between components and pod networks
```
gcloud compute firewall-rules create k8s-cluster-fw --network k8s --allow tcp,udp,icmp --source-ranges 10.0.0.0/24,10.100.0.0/16
```
### Add firewall allowing external traffic to the network (port 6443 are used by API server TLS)
```
gcloud compute firewall-rules create k8s-allow-external \
  --allow tcp:22,tcp:6443,icmp \
  --network k8s \
  --source-ranges 0.0.0.0/0
```
### List all firewall rules filtering on a specific network
```
gcloud compute firewall-rules list --filter="network:k8s"
```
### Allocate a external IP address
```
gcloud compute addresses create k8s-external --region $(gcloud config get-value compute/region)
```
### List allocated external IP addresses
```
gcloud compute addresses list
NAME          REGION        ADDRESS        STATUS
k8s-external  europe-west1  1.2.3.4  RESERVED
```
### Query the metadata server from within a compute instance and fetch it's IP address
```
curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip
```

## systemd

### systemd
* Provides a tool to help configure time/date called `timedatectl`

### journald
* Part of `systemd`
* A centralized management solution for logging all kernel and userland processes

#### Cheat Sheet
Command | Description
--- | ---
`journalctl -u kubelet` | Look at logs for a specified systemd process
`journalctl -u kubelet -f` | Look at logs for a specified systemd process and follow the output
`journalctl -u kubelet -r` | Look at logs for a specified systemd process in reverse order, latest first
`journalctl -u kubelet --since "10 min ago"` | Look at the logs from the last 10 minutes
`timedatectl list-timezones` | List time zones
`timedatectl set-timezone Europe/Stockholm` | Set the timezone