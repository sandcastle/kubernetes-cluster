#!/bin/sh

# Members - Sets up the cluster master and initial nodes

# --------------------------------------
# Vars

master_size="t2.micro"
node_size="m3.medium"
KUBE_IMAGE="ami-8f88c8b5"

# --------------------------------------
# Master

KUBE_MINION_CONFIG=$(<minion.yml)
# TODO: Inject values
echo KUBE_MINION_CONFIG > logs/minion.yml

# create cluster master
aws ec2 run-instances \
  --count 1 \
  --image-id $KUBE_IMAGE \
  --key-name $KEY \
  --region ${AWS_REGION} \
  --security-groups ${GRP_CLUSTER_ID} \
  --instance-type t2.micro \
  --user-data "file://logs/master.yml"
  >> ${LOG}

# MASTER_IP=$(aws ec2 describe-instances --instance-id)

# --------------------------------------
# Nodes

KUBE_MINION_CONFIG=$(<minion.yml)
# TODO: Inject values
echo KUBE_MINION_CONFIG > logs/minion.yml

#create cluster nodes
aws ec2 run-instances \
  --count 1 \
  --image-id $KUBE_IMAGE \
  --key-name $KEY \
  --region ${AWS_REGION} \
  --security-groups ${GRP_CLUSTER_ID} \
  --instance-type m3.medium \
  --user-data "file://logs/minion.yml"
  >> ${LOG}


# --------------------------------------
# IP Addresses


# --------------------------------------
# Auto Scaling

# ${AWS_ASG_CMD} create-launch-configuration \
#     --launch-configuration-name ${ASG_NAME} \
#     --image-id $KUBE_MINION_IMAGE \
#     --iam-instance-profile ${IAM_PROFILE_MINION} \
#     --instance-type $MINION_SIZE \
#     --key-name ${AWS_SSH_KEY_NAME} \
#     --security-groups ${MINION_SG_ID} \
#     ${public_ip_option} \
#     --block-device-mappings "${BLOCK_DEVICE_MAPPINGS}" \
#     --user-data "file://${KUBE_TEMP}/minion-user-data"
# 
# echo "Creating autoscaling group"
# ${AWS_ASG_CMD} create-auto-scaling-group \
#     --auto-scaling-group-name ${ASG_NAME} \
#     --launch-configuration-name ${ASG_NAME} \
#     --min-size ${NUM_MINIONS} \
#     --max-size ${NUM_MINIONS} \
#     --vpc-zone-identifier ${SUBNET_ID} \
#     --tags ResourceId=${ASG_NAME},ResourceType=auto-scaling-group,Key=Name,Value=${NODE_INSTANCE_PREFIX} \
#            ResourceId=${ASG_NAME},ResourceType=auto-scaling-group,Key=Role,Value=${MINION_TAG} \
#            ResourceId=${ASG_NAME},ResourceType=auto-scaling-group,Key=KubernetesCluster,Value=${CLUSTER_ID}
