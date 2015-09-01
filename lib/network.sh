#!/bin/sh

# Network - Setups up all require networking (VPC, subnets, routing, 
# security groups) to run the cluster.

# --------------------------------------
# Configuration

# VPC
VPC_CIDR="${NET_PREFIX}.0.0/16"
VPC_ID=

# --------------------------------------
# VPC

# Creates the VPC if it doesnt exist
# usage: create_vpc
create_vpc() {

  echo ""
  echo "[VPC]"
  
  VPC_ID=$(aws ec2 describe-vpcs --query "Vpcs[?CidrBlock=='${VPC_CIDR}'].[VpcId][0][0]" --output text)

  # check if VPC exists
  if [ "$vpc_id" == "None" ]; then
    echo "VPC ($vpc_cidr) already exists"
    exit 999
  fi

  # create vpc
  VPC_ID=$(aws ec2 create-vpc --cidr-block ${VPC_CIDR} | jq -r '.Vpc.VpcId')
  aws ec2 modify-vpc-attribute --vpc-id ${VPC_ID} --enable-dns-support '{"Value": true}'
  aws ec2 modify-vpc-attribute --vpc-id ${VPC_ID} --enable-dns-hostnames '{"Value": true}'

  # tags
  add_tag ${VPC_ID} Name "vpc-${APP_NAME}"
  add_tag ${VPC_ID} Env "${APP_ENV}"
  add_tag ${VPC_ID} Service "${APP_SERVICE}"

  echo " - ${VPC_ID} / vpc-${APP_NAME} (${VPC_CIDR})"
}

# create, if not exists
create_vpc


# --------------------------------------
# subnets

# creates a subnet
# usage: create_subnets <type> <start>
create_subnets() {

  local subnet
  local subnet_id
  local subnet_cidr
  local az="a"

  # create subnet per zone
  local i
  for ((i=0; i < ${NET_ZONES}; i++)); do

    # calculate cidr
    subnet_cidr="${NET_PREFIX}.${2}${i}.0/24"

    # create subnet
    subnet=$(aws ec2 create-subnet --vpc-id ${VPC_ID} --cidr-block ${subnet_cidr} --availability-zone "${AWS_REGION}${az}" | jq -r '.Subnet')
    subnet_id=$(echo ${subnet} | jq -r '.SubnetId')
    
    # tag
    add_tag ${subnet_id} Name "subnet-${APP_NAME}-${1}-${az}"
    add_tag ${subnet_id} Env "${APP_ENV}"
    add_tag ${subnet_id} Service "${APP_SERVICE}"
    add_tag ${subnet_id} Zone "${az}"

    echo " - ${subnet_id} / subnet-${APP_NAME}-${1}-${az} (${subnet_cidr})"

    # increment zone
    az=$(increment_char ${az})

  done
}

# Creates all subnets for all zones
# usage: create_all_subnets
create_all_subnets() {

  echo ""
  echo "[Subnets]"

  # create subnets
  create_subnets "elb" 1
  create_subnets "cluster" 2
  create_subnets "db" 3
}

# create VPC subnets
create_all_subnets


# --------------------------------------
# security group

create_groups(){

  echo ""
  echo "[Security Groups]"

  # elb
  local grp_elb="grp-${APP_NAME}-elb"
  local grp_elb_id=$(aws ec2 create-security-group --group-name "${grp_elb}" --description "${grp_elb} security group" --vpc-id ${VPC_ID} | jq -r ".GroupId")
  aws ec2 authorize-security-group-ingress --group-id ${grp_elb_id} --protocol tcp --port 80 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --group-id ${grp_elb_id} --protocol tcp --port 443 --cidr 0.0.0.0/0

  # elb tags
  add_tag ${grp_elb_id} Name "${grp_elb}"
  add_tag ${grp_elb_id} Env "${APP_ENV}"
  add_tag ${grp_elb_id} Service "${APP_SERVICE}"

  echo " - ${grp_elb_id} / ${grp_elb}"

  # cluster
  local grp_cluster="grp-${APP_NAME}-cluster"
  local grp_cluster_id=$(aws ec2 create-security-group --group-name "${grp_cluster}" --description "${grp_cluster} security group" --vpc-id ${VPC_ID} | jq -r ".GroupId")
  aws ec2 authorize-security-group-ingress --group-id ${grp_cluster_id} --protocol tcp --port 22 --cidr ${MY_IP}/32
  aws ec2 authorize-security-group-ingress --group-id ${grp_cluster_id} --protocol tcp --port 80 --source-group ${grp_elb_id}
  aws ec2 authorize-security-group-ingress --group-id ${grp_cluster_id} --protocol tcp --port 443 --source-group ${grp_elb_id}

  # cluster tags
  add_tag ${grp_cluster_id} Name "${grp_cluster_id}"
  add_tag ${grp_cluster_id} Env "${APP_ENV}"
  add_tag ${grp_cluster_id} Service "${APP_SERVICE}"

  echo " - ${grp_cluster_id} / ${grp_cluster}"

  # db
  local grp_db="grp-${APP_NAME}-db"
  local grp_db_id=$(aws ec2 create-security-group --group-name "${grp_db}" --description "${grp_db} security group" --vpc-id ${VPC_ID} | jq -r ".GroupId")
  aws ec2 authorize-security-group-ingress --group-id ${grp_db_id} --protocol tcp --port 22 --cidr ${MY_IP}/32
  aws ec2 authorize-security-group-ingress --group-id ${grp_db_id} --protocol tcp --port 5432 --cidr ${MY_IP}/32
  aws ec2 authorize-security-group-ingress --group-id ${grp_db_id} --protocol tcp --port 5432 --source-group ${grp_cluster_id}

  # db tags
  add_tag ${grp_db_id} Name "${grp_db}"
  add_tag ${grp_db_id} Env "${APP_ENV}"
  add_tag ${grp_db_id} Service "${APP_SERVICE}"

  echo " - ${grp_db_id} / ${grp_db}"
}

# create security groups
create_groups


# --------------------------------------
# Routing

# internet gateway placeholder
IGW_ID=

# Creates an internet gateway
# usage: create_iwg
create_iwg(){

  echo ""
  echo "[Internet Gateway]"

  IGW_ID=$(aws ec2 create-internet-gateway | jq -r ".InternetGateway.InternetGatewayId")
  aws ec2 attach-internet-gateway --internet-gateway-id ${IGW_ID} --vpc-id ${VPC_ID}

  add_tag ${IGW_ID} Name "igw-${APP_NAME}"
  add_tag ${IGW_ID} Env "${APP_ENV}"
  add_tag ${IGW_ID} Service "${APP_SERVICE}"

  echo " - ${IGW_ID} / igw-${APP_NAME}"
}

# Creates an internet gateway & configures routes
# usage: create_routes
create_routes() {

  echo ""
  echo "[Route Tables]"
  
  # route tables
  local route_table_id=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${VPC_ID}" | jq -r ".RouteTables[].RouteTableId")
  $(aws ec2 create-route --route-table-id ${route_table_id} --destination-cidr-block 0.0.0.0/0 --gateway-id ${IGW_ID})

  # TODO: Create public / private route tables for specific subnets
  # aws ec2 associate-route-table --route-table-id ${route_table_id} --subnet-id ${current_subnet}

  # route table tags
  add_tag ${route_table_id} Name "rtb-${APP_NAME}-main"
  add_tag ${route_table_id} Env "${APP_ENV}"
  add_tag ${route_table_id} Service "${APP_SERVICE}"

  echo " - ${route_table_id} / rtb-${APP_NAME}-main"
}

# setup internet gateway & routes
create_iwg
create_routes
