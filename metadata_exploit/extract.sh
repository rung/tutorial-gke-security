#!/bin/bash
set -eu

FILENAME=metadata.txt

cd $(dirname $0)

if [[ ! -e "$FILENAME" ]]; then
  echo "File($FILENAME) doesn't exist" 1>&2
  exit 1
fi

cat $FILENAME | perl -MMIME::Base64 -nle '/KUBELET_CERT: (.*?)\\n/ and print decode_base64($1)' > metadata/client.crt
cat $FILENAME | perl -MMIME::Base64 -nle '/KUBELET_KEY: (.*?)\\n/ and print decode_base64($1)' > metadata/client.key
cat $FILENAME | perl -MMIME::Base64 -nle '/CA_CERT: (.*?)\\n/ and print decode_base64($1)' > metadata/ca.crt
cat $FILENAME | perl -MMIME::Base64 -nle '/KUBERNETES_MASTER_NAME: (.*?)\\n/ and print $1' > metadata/api_ip
cat metadata.txt | perl -nle '/"name":"(gke-.*?)"/ and print $1' > metadata/nodename

exit 0
