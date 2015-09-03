#!/bin/sh

# Load Balancing - Sets up the load balancer

# --------------------------------------
# ELB

ELB_ID=

# Creates a load balancer for the cluster
# usage: createLoadBalancer
createLoadBalancer() {

  # create ELB
  local elb="elb-${APP_NAME}"
  ELB_ID=$(aws elb create-load-balancer \
        --load-balancer-name "${ELB}" \
        --listeners "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80" \
        --subnets "${SUBNET_ELB_A_ID}" "${SUBNET_ELB_B_ID}" \
        --security-groups "${GRP_ELB_ID}" \
        --output text)

  echo ""
  echo "[Load Balancer]"
  echo " - ${ELB_ID} / ${ELB} (80->80)"

  # -------

  # enable cross zone load balancing
  $(aws elb modify-load-balancer-attributes \
      --load-balancer-name "${ELB}" \
      --load-balancer-attributes "{\"CrossZoneLoadBalancing\":{\"Enabled\":true}}")

  # -------

  # ELB Proxy Protocol (Websocket Support)
  local proxy_policy="${ELB}-proxy-protocol"

  # define policy
  aws elb create-load-balancer-policy \
      --load-balancer-name "${ELB}" \
      --policy-name "${proxy_policy}" \
      --policy-type-name "ProxyProtocolPolicyType" \
      --policy-attributes "AttributeName=ProxyProtocol,AttributeValue=true"

  # apply policy
  aws elb set-load-balancer-policies-for-backend-server \
      --load-balancer-name "${ELB}" \
      --instance-port 80 \
      --policy-names "${proxy_policy}"
}

createLoadBalancer
