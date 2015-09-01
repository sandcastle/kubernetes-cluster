#!/bin/sh

# --------------------------------------
# Members
# --------------------------------------

master_size="t2.micro"
node_size="m3.medium"

KUBE_IMAGE="ami-8f88c8b5"
KUBE_MASTER_CONFIG=$(base64 $(<master.yml))

# --------------------------------------
# Master

# create cluster master
aws ec2 run-instances \
  --count 1 \
  --image-id $CIO_KUBE_IMAGE \
  --key-name $CIO_KEY \
  --region $CIO_KUBE_REGION \
  --security-groups kubernetes \
  --instance-type t2.micro \
  --user-data $CIO_KUBE_MASTER_CONFIG \
  --disable-api-termination

# MASTER_IP=$(aws ec2 describe-instances --instance-id)

# --------------------------------------
# Nodes

#create cluster nodes
aws ec2 run-instances \
  --count 1 \
  --image-id $CIO_KUBE_IMAGE \
  --key-name $CIO_KUBE_KEY \
  --region $CIO_KUBE_REGION \
  --security-groups kubernetes \
  --instance-type m3.medium \
  --user-data file://node.yaml \
  --disable-api-termination
