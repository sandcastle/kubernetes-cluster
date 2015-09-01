#!/bin/sh

# Init - Runs the bootstrap process

echo "------------------------"
echo "~ Initializing Cluster ~"
echo "------------------------"

# config
source "config.sh"

# bootstrap
source "lib/bootstrap.sh"

echo "All done!"
