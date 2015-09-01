#!/bin/sh

# Boostrap - Creates the required infrastructure, then bootstraps
# a new Kubernetes cluster

# --------------------------------------
# Helpers

source "lib/utils.sh"
source "lib/vars.sh"

# --------------------------------------
# Let it be known

echo ""
echo "Service:     ${APP_SERVICE}"
echo "Environment: ${APP_ENV}"
echo "My IP:       ${MY_IP}"

# --------------------------------------
# Make it rain!

source "lib/network.sh"
source "lib/elb.sh"
# source "lib/members.sh"
