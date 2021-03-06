#!/bin/bash

num_jobs=4

gsutil cp gcp_setup_script.sh gs://testing-npm-bucket

instance_list=$(for ((my_job=0;my_job<num_jobs;my_job++)); do
  echo -n "instance-$my_job "
done)

echo "Creating VMs: $instance_list"

gcloud beta compute instances create $instance_list \
  --zone=us-central1-a \
  --machine-type=e2-small \
  --subnet=default \
  --network-tier=PREMIUM \
  --maintenance-policy=MIGRATE \
  --service-account=391228219250-compute@developer.gserviceaccount.com \
  --scopes=https://www.googleapis.com/auth/cloud-platform \
  --image=debian-10-buster-v20210916 \
  --image-project=debian-cloud \
  --boot-disk-size=10GB \
  --boot-disk-type=pd-balanced \
  --boot-disk-device-name=the-boot-disk \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --reservation-affinity=any

echo "Waiting a bit..."
sleep 10

for ((my_job=0;my_job<num_jobs;my_job++)); do
  echo ""
  echo "Download setup script on VM $my_job"
  gcloud compute ssh instance-$my_job \
    --zone=us-central1-a \
    --command "gsutil cp gs://testing-npm-bucket/gcp_setup_script.sh gcp_setup_script.sh"
done

for ((my_job=1;my_job<num_jobs;my_job++)); do
  echo ""
  echo "Starting background setup script up VM $my_job"
  gcloud compute ssh instance-$my_job \
    --zone=us-central1-a \
    --command "nohup bash gcp_setup_script.sh" &
done

my_job=0
echo ""
echo "Foreground setup script up VM $my_job"
gcloud compute ssh instance-$my_job \
  --zone=us-central1-a \
  --command "bash gcp_setup_script.sh"
