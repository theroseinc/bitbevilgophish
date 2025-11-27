#!/bin/bash
# Deploy and execute fix on VM

set -e

ZONE="us-central1-a"
PROJECT="phishing-infra-1764142047"
INSTANCE="evilginx-server"

echo "Copying fix script to VM..."
gcloud compute scp ./fix-evilginx-vm.sh ${INSTANCE}:/tmp/ --zone=${ZONE} --project=${PROJECT} --quiet

echo "Executing fix on VM..."
gcloud compute ssh ${INSTANCE} --zone=${ZONE} --project=${PROJECT} --command="sudo bash /tmp/fix-evilginx-vm.sh"

echo ""
echo "Fix deployed and executed!"
echo ""
echo "To verify, SSH into the VM and check:"
echo "  gcloud compute ssh ${INSTANCE} --zone=${ZONE} --project=${PROJECT}"
echo "  sudo screen -r evilginx"
