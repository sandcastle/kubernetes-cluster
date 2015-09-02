#!/bin/sh

# Load Balancing - Sets up the load balancer

# --------------------------------------
# ELB

# create ELB
ELB="elb-${APP_NAME}"
ELB_ID=$(aws elb create-load-balancer \
      --load-balancer-name "${ELB}" \
      --listeners Protocol=HTTP,LoadBalancerPort=80,InstancePort=80 \
      --availability-zones= "${AWS_REGION}${AWS_ZONE_1}" "${AWS_REGION}${AWS_ZONE_1}" \ 
      --subnets "${SUBNET_ELB_A_ID}" "${SUBNET_ELB_B_ID}" \
      --security-groups "${GRP_ELB_ID}" \
      --output text)

# --------------------------------------
# ELB Config

# enable cross zone load balancing
aws elb modify-load-balancer-attributes \
    --load-balancer-name ${ELB} \
    --load-balancer-attributes "{\"CrossZoneLoadBalancing\":{\"Enabled\":true}}"

# define proxy protocol policy
aws elb create-load-balancer-policy \
    --load-balancer-name $ELB \
    --policy-name $ELB-proxy-protocol \
    --policy-type-name ProxyProtocolPolicyType \
    --policy-attributes AttributeName=ProxyProtocol,AttributeValue=True

# attach policy to elb
aws elb set-load-balancer-policies-for-backend-server \
    --load-balancer-name $ELB_NAME \
    --instance-port 80 \
    --policy-names $ELB_NAME-proxy-protocol

# --------------------------------------
# ELB Health Checks

# enable health checks
# aws elb configure-health-check \
#     --load-balancer-name mp1jrh3 \
#     --health-check Target=HTTP:80/index.php,Interval=30,Timeout=5,UnhealthyThreshold=2,HealthyThreshold=10
