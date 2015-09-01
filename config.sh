#!/bin/sh

# --------------------------------------
# Config
# --------------------------------------

# application
APP_ENV="${APP_ENV:-prod}"
APP_SERVICE="${APP_SERVICE:-app}"
APP_NAME="${APP_SERVICE}-${APP_ENV}"

# networking
NET_PREFIX="${NET_PREFIX:-10.100}"
