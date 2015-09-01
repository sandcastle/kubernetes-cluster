#!/bin/sh

# --------------------------------------
# Cluster Boostrap
# --------------------------------------

# helpers
source "lib/utils.sh"

# --------------------------------------
# Variables

# debug
LOG=

# networking
MY_IP=$(get_ip)

# --------------------------------------
# Printer

# let it be known
echo ""
echo "Service:     ${APP_SERVICE}"
echo "Environment: ${APP_ENV}"
echo "My IP:       ${MY_IP}"

# --------------------------------------
# Make it rain!

# bootstrap
source "lib/network.sh"
# source "lib/members.sh"
