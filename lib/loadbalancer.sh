#!/bin/sh

# Load Balancing - Sets up the load balancer

# --------------------------------------
# ELB

# placeholders
ELB_ID=
ELB_ZONE_ID=
ELB_ZONE_NAME=

# Creates a load balancer for the cluster
# usage: createLoadBalancer
createLoadBalancer() {

  echo ""
  echo "[Load Balancer]"

  # create ELB
  local elb="elb-${APP_NAME}"
  aws elb create-load-balancer \
      --load-balancer-name "${elb}" \
      --listeners "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80" \
      --subnets "${SUBNET_ELB_A_ID}" "${SUBNET_ELB_B_ID}" \
      --security-groups "${GRP_ELB_ID}" \
      >> ${LOG}

  # -------

  # enable connection draining
  aws elb modify-load-balancer-attributes \
      --load-balancer-name "${elb}" \
      --load-balancer-attributes "{\"ConnectionDraining\":{\"Enabled\":true,\"Timeout\":300}}" \
      >> ${LOG}

  # -------

  # enable health checks
  aws elb configure-health-check \
      --load-balancer-name "${elb}" \
      --health-check Target=TCP:80,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=4 \
      >> ${LOG}

  # -------

  # enable cross zone load balancing
  aws elb modify-load-balancer-attributes \
      --load-balancer-name "${elb}" \
      --load-balancer-attributes "{\"CrossZoneLoadBalancing\":{\"Enabled\":true}}" \
      >> ${LOG}

  # -------

  # ELB Proxy Protocol (Websocket Support)
  local proxy_policy="${elb}-proxy-protocol"

  # define policy
  aws elb create-load-balancer-policy \
      --load-balancer-name "${elb}" \
      --policy-name "${proxy_policy}" \
      --policy-type-name "ProxyProtocolPolicyType" \
      --policy-attributes "AttributeName=ProxyProtocol,AttributeValue=true" \
      >> ${LOG}

  # apply policy
  aws elb set-load-balancer-policies-for-backend-server \
      --load-balancer-name "${elb}" \
      --instance-port 80 \
      --policy-names "${proxy_policy}" \
      >> ${LOG}

  # -------

  local elb_config=$(aws elb describe-load-balancers --load-balancer-name "${elb}")
  echo ${elb_config} >> ${LOG}

  ELB_ZONE_ID=$(echo ${elb_config} | jq -r '.LoadBalancerDescriptions[0].CanonicalHostedZoneNameID')
  ELB_ZONE_NAME=$(echo ${elb_config} | jq -r '.LoadBalancerDescriptions[0].CanonicalHostedZoneName')

  echo " - ${ELB_ZONE_NAME} / ${elb} (TCP:80->80)"
}

createLoadBalancer
