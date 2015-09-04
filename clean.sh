#!/bin/sh

# Boostrap - Creates the required infrastructure, then bootstraps
# a new Kubernetes cluster

# --------------------------------------
# Helpers

source "config.sh"
source "lib/utils.sh"
source "lib/vars.sh"

LOG=logs/clean.log
echo "Cleaning" > ${LOG}

# --------------------------------------
# Clean it up

clean() {

  # vpc info
  local vpc_cidr="${NET_PREFIX}.0.0/16"
  local vpc_id=$(aws ec2 describe-vpcs --query "Vpcs[?CidrBlock=='${vpc_cidr}'].[VpcId][0][0]" --output text)

  # check if VPC exists
  if [ "${vpc_id}" == "None" ]; then
    echo "VPC (${vpc_cidr}) already exists"
    exit 99
  fi

  # -------

  # confirm first
  read -p "Confirm you want to delete the VPC ${vpc_id} (${vpc_cidr}) [Yn]?" -n 1 -r
  echo    # move to a new line
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
      exit 1
  fi

  # -------

  # removing instances




  # -------

  echo "Removing ELB"

  # get elb name (filtering not supported)
  elb_name=$(aws elb describe-load-balancers --page-size 400 | jq -r '.LoadBalancerDescriptions[] | select(.VPCId=="${vpc_id}").LoadBalancerName')

  aws elb delete-load-balancer \
      --load-balancer-name "${elb_name}" \
      >> ${LOG}

  # -------

  echo "Removing security groups"

  local elb_grp=$(aws ec2 describe-security-groups --filters "Name=group-name,Values='grp-${APP_NAME}-elb'" | jq -r '.SecurityGroups[0].GroupId')
  aws ec2 delete-security-group \
      --group-id "${elb_grp}" \
      >> ${LOG}

  local cluster_grp=$(aws ec2 describe-security-groups --filters "Name=group-name,Values='grp-${APP_NAME}-cluster'" | jq -r '.SecurityGroups[0].GroupId')
  aws ec2 delete-security-group \
      --group-id "${cluster_grp}" \
      >> ${LOG}

  local db_grp=$(aws ec2 describe-security-groups --filters "Name=group-name,Values='grp-${APP_NAME}-db'" | jq -r '.SecurityGroups[0].GroupId')
  aws ec2 delete-security-group \
      --group-id "${db_grp}" \
      >> ${LOG}

  # -------

  echo "Removing route tables"
  
  local elb_route_table=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${vpc_id}" "Name=tag:Tier,Values=elb" | jq -r '.RouteTables[0].RouteTableId')
  aws ec2 delete-route-table \
      --route-table-id "${elb_route_table}" \
      >> ${LOG}
  
  local cluster_route_table=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${vpc_id}" "Name=tag:Tier,Values=cluster" | jq -r '.RouteTables[0].RouteTableId')
  aws ec2 delete-route-table \
      --route-table-id "${cluster_route_table}" \
      >> ${LOG}

  local db_route_table=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${vpc_id}" "Name=tag:Tier,Values=db" | jq -r '.RouteTables[0].RouteTableId')
  aws ec2 delete-route-table \
      --route-table-id "${db_route_table}" \
      >> ${LOG}

  # -------

  echo "Removing internet gateway"
  
  local igw_id=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=${vpc_id}" | jq -r '.InternetGateways[0].InternetGatewayId')

  aws ec2 detach-internet-gateway \
      --vpc-id "${vpc_id}" \
      --internet-gateway-id "${igw_id}" \
      >> ${LOG}

  aws ec2 delete-internet-gateway \
      --internet-gateway-id "${igw_id}" \
      >> ${LOG}

  # -------

  echo "Removing VPC"

  aws ec2 delete-vpc \
    --vpc-id "${vpc_id}"
    >> ${LOG}

}

clean
