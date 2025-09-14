#!/bin/dash

# This script assumes your current working directory is the root of the
# project. It will set up POSH to run in DASH, run your command against
# POSH, and then exit.

# shellcheck disable=SC1091
# shellcheck disable=SC2155

# Configure the environment.
export POSH_DIR="$PWD"

# Install POSH.
. ./posh.sh && __posh_init

# Run the desired command.
"$@"

# Preserve exit status.
exit $?
