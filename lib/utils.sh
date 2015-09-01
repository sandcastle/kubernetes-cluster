#!/bin/sh

# --------------------------------------
# Utils
# --------------------------------------

# Provides helper functions

# --------------------------------------
# General

# Increments the character by one - used for walking zone identifiers.
# usage: increment_char "a"
increment_char() {
  echo "$(echo "${1}" | tr "0-9a-z" "1-9a-z_")"
}

# --------------------------------------
# Networking

# Returns the current IP address of the caller.
# usage: get_ip
get_ip() {
  echo "$(curl -s http://checkip.amazonaws.com)"
}

# --------------------------------------
# AWS

# Adds a tag to an AWS resource
# usage: add_tag <resource-id> <tag-name> <tag-value>
add_tag() {

  # We need to retry in case the resource isn't yet fully created
  n=0
  until [ $n -ge 25 ]; do
    aws ec2 create-tags --resources ${1} --tags Key=${2},Value=${3} && return
    n=$[$n+1]
    sleep 3
  done

  echo "Unable to add tag to AWS resource ${1}"
  exit 1
}
