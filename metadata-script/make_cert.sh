#!/bin/bash
set -eu

cd $(dirname $0)

DATE=$(date +%s)
NODE=$1
API_IP=$(cat metadata/api_ip | tr -d '\n')
KUBECTL_OPT="--client-certificate metadata/client.crt --client-key metadata/client.key --certificate-authority metadata/ca.crt --server https://$API_IP"

# Make CSR
openssl req -nodes -newkey rsa:2048 -keyout newcert/new.key -out newcert/new.csr -subj "/O=system:nodes/CN=system:node:$NODE" >/dev/null 2>&1

# Send CSR to K8S API
echo -e "[Send CSR to K8S API]\n-----"
CERT=$(cat newcert/new.csr | base64 | tr -d '\n')
cat csr_template | perl -spe 's!\{\{REQUEST\}\}!$CERT!g;s!\{\{DATE\}\}!$DATE!g' -- -CERT=$CERT -DATE=$DATE | kubectl $KUBECTL_OPT create -f -

# Confirm CSR was approved
echo -e "\n-----\n[Confirm CSR was approved]"
kubectl $KUBECTL_OPT get certificatesigningrequests node-csr-mal-$DATE

# Get new certificate
kubectl $KUBECTL_OPT get csr node-csr-mal-$DATE -o jsonpath='{.status.certificate}' | perl -MMIME::Base64 -ne 'print decode_base64($_)' > newcert/node.crt

# Try get nodes
echo -e "\n-----\n[Try 'get node']"
KUBECTL_OPT2="--client-certificate newcert/node.crt --client-key newcert/new.key --certificate-authority metadata/ca.crt --server https://$API_IP"
kubectl $KUBECTL_OPT2 get nodes -o wide

# Show sample command
echo -e "\n-----[Please use this option for kubectl]"
echo "--client-certificate newcert/node.crt --client-key newcert/new.key --certificate-authority metadata/ca.crt --server https://\$(cat metadata/api_ip)"
