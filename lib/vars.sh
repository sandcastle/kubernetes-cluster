#!/bin/sh

# Vars - Variables that are shared across

# --------------------------------------
# General

# debug
LOG=
mkdir -p logs

# networking
MY_IP=$(get_ip)

# --------------------------------------
# AWS

# current region (ap-southeast-2)
AWS_REGION=$(aws configure get region)

# availability zones
AWS_ZONE_1="${AWS_ZONE_1:-a}"
AWS_ZONE_2="${AWS_ZONE_1:-b}"
