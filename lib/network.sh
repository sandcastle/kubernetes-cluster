#!/bin/sh

# Network - Setups up all require networking (VPC, subnets, routing, 
# security groups) to run the cluster.

# --------------------------------------
# VPC

VPC_CIDR="${NET_PREFIX}.0.0/16"
VPC_ID=

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

# subnet placeholders
SUBNET_ELB_A_ID=
SUBNET_ELB_B_ID=
SUBNET_CLUSTER_A_ID=
SUBNET_CLUSTER_B_ID=
SUBNET_DB_A_ID=
SUBNET_DB_B_ID=

# creates a subnet
# usage: create_subnets <type> <subnet> <az> <result>
create_subnet() {

  # create subnet
  local subnet_name="subnet-${APP_NAME}-${1}-${3}"
  local subnet=$(aws ec2 create-subnet --vpc-id ${VPC_ID} --cidr-block ${2} --availability-zone "${AWS_REGION}${3}" | jq -r '.Subnet')
  local subnet_id=$(echo ${subnet} | jq -r '.SubnetId')
  
  # tag
  add_tag ${subnet_id} Name "${subnet_name}"
  add_tag ${subnet_id} Env "${APP_ENV}"
  add_tag ${subnet_id} Service "${APP_SERVICE}"

  # debug 
  echo " - ${subnet_id} / ${subnet_name} (${2})"

  # return result
  eval "$4=${subnet_id}"
}

# Creates all subnets for all zones
# usage: create_all_subnets
create_all_subnets() {

  echo ""
  echo "[Subnets]"

  # create subnets
  create_subnet "elb" "${NET_PREFIX}.10.0/24" "${AWS_ZONE_1}" "SUBNET_ELB_A_ID"
  create_subnet "elb" "${NET_PREFIX}.11.0/24" "${AWS_ZONE_2}" "SUBNET_ELB_B_ID"
  create_subnet "cluster" "${NET_PREFIX}.20.0/24" "${AWS_ZONE_1}" "SUBNET_CLUSTER_A_ID"
  create_subnet "cluster" "${NET_PREFIX}.21.0/24" "${AWS_ZONE_2}" "SUBNET_CLUSTER_B_ID"
  create_subnet "db" "${NET_PREFIX}.30.0/24" "${AWS_ZONE_1}" "SUBNET_DB_A_ID"
  create_subnet "db" "${NET_PREFIX}.31.0/24" "${AWS_ZONE_2}" "SUBNET_DB_B_ID"
}

# create VPC subnets
create_all_subnets


# --------------------------------------
# security group

# placeholder groups
GRP_ELB_ID=
GRP_CLUSTER_ID=
GRP_DB_ID=

create_groups(){

  echo ""
  echo "[Security Groups]"

  # elb
  local grp_elb="grp-${APP_NAME}-elb"
  GRP_ELB_ID=$(aws ec2 create-security-group --group-name "${grp_elb}" --description "${grp_elb} security group" --vpc-id ${VPC_ID} | jq -r ".GroupId")
  aws ec2 authorize-security-group-ingress --group-id ${GRP_ELB_ID} --protocol tcp --port 80 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --group-id ${GRP_ELB_ID} --protocol tcp --port 443 --cidr 0.0.0.0/0

  # elb tags
  add_tag ${GRP_ELB_ID} Name "${grp_elb}"
  add_tag ${GRP_ELB_ID} Env "${APP_ENV}"
  add_tag ${GRP_ELB_ID} Service "${APP_SERVICE}"

  echo " - ${GRP_ELB_ID} / ${grp_elb}"

  # cluster
  local grp_cluster="grp-${APP_NAME}-cluster"
  GRP_CLUSTER_ID=$(aws ec2 create-security-group --group-name "${grp_cluster}" --description "${grp_cluster} security group" --vpc-id ${VPC_ID} | jq -r ".GroupId")
  aws ec2 authorize-security-group-ingress --group-id ${GRP_CLUSTER_ID} --protocol tcp --port 22 --cidr ${MY_IP}/32
  aws ec2 authorize-security-group-ingress --group-id ${GRP_CLUSTER_ID} --protocol tcp --port 80 --source-group ${GRP_ELB_ID}
  aws ec2 authorize-security-group-ingress --group-id ${GRP_CLUSTER_ID} --protocol tcp --port 443 --source-group ${GRP_ELB_ID}

  # cluster tags
  add_tag ${GRP_CLUSTER_ID} Name "${grp_cluster}"
  add_tag ${GRP_CLUSTER_ID} Env "${APP_ENV}"
  add_tag ${GRP_CLUSTER_ID} Service "${APP_SERVICE}"

  echo " - ${GRP_CLUSTER_ID} / ${grp_cluster}"

  # db
  local grp_db="grp-${APP_NAME}-db"
  GRP_DB_ID=$(aws ec2 create-security-group --group-name "${grp_db}" --description "${grp_db} security group" --vpc-id ${VPC_ID} | jq -r ".GroupId")
  aws ec2 authorize-security-group-ingress --group-id ${GRP_DB_ID} --protocol tcp --port 22 --cidr ${MY_IP}/32
  aws ec2 authorize-security-group-ingress --group-id ${GRP_DB_ID} --protocol tcp --port 5432 --cidr ${MY_IP}/32
  aws ec2 authorize-security-group-ingress --group-id ${GRP_DB_ID} --protocol tcp --port 5432 --source-group ${GRP_CLUSTER_ID}

  # db tags
  add_tag ${GRP_DB_ID} Name "${grp_db}"
  add_tag ${GRP_DB_ID} Env "${APP_ENV}"
  add_tag ${GRP_DB_ID} Service "${APP_SERVICE}"

  echo " - ${GRP_DB_ID} / ${grp_db}"
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
  local route_table_id=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${VPC_ID}" | jq -r ".RouteTables[0].RouteTableId")
  $(aws ec2 create-route --route-table-id "${route_table_id}" --destination-cidr-block "0.0.0.0/0" --gateway-id "${IGW_ID}")

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
