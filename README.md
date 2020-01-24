# training-gke-security
This repository is for training of GKE Security

[![Open in Cloud Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/rung/training-gke-security&page=editor&open_in_editor=README.md)

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
gcloud container clusters create gke-security-testing --zone=asia-northeast1 --async
```

- Get a credential of GKE
```bash
gcloud container clusters create gke-security-testing --zone asia-northeast1-a --machine-type f1-micro --num-nodes 3 --async
```

### Exercise 1: PodSecurityPolicy


### Exercise 2: Workload Identity

### Clean cluster
```bash
gcloud container clusters delete gke-security-testing --zone asia-northeast1-a --async
```
