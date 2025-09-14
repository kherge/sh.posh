#!/bin/dash

# This script assumes your current working directory is the root of the
# project. It will set up POSH to run in the shell and is expected to be
# used within an existing DASH shell session.

# shellcheck disable=SC1091
# shellcheck disable=SC2155

# Configure the environment.
export POSH_DIR="$PWD"
export POSH_DEBUG=1

# Install POSH.
. ./posh.sh && __posh_init
