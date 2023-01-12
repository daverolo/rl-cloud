#!/bin/bash
# -----------------------------------------------------------------------------
# What: Init new VM in RL-cloud
# Link: https://raw.githubusercontent.com/daverolo/rl-cloud/main/initvm.sh
# Usage: sudo bash initvm.sh
# -----------------------------------------------------------------------------

#
# HEADER
#

# Make sure piped errors will result in $? (https://unix.stackexchange.com/a/73180/452265)
set -o pipefail
	
# Set path manually since the script is maybe called via cron!
PATH=~/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

#
# CONFIG
#

# Set host and os infos
HOST_NAME="$(hostname)"                                             # e.g. -> server1
OS_NAME="$(cat /etc/issue 2>/dev/null | awk -F " " '{print $1}')"   # e.g. -> Ubuntu

#
# FUNCTIONS
#

# output default message
say() {
    echo "$@"
}

# exit script with error message and error code
die() {
    echo "$@" >&2
    exit 3
}

# trim whitespaces
# example: myvar=$(trim "$myvar")
trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   
    echo -n "$var"
}

#
# FLOW
#

# Make sure user is root
if [ "$(whoami)" != "root" ]; then
    die "error: call this script with sudo or as root"
fi

# Check if this is executed on Ubuntu (to prevent running this on the local OS by accident)
OS_NAME=$(echo "${OS_NAME}" | tr '[:upper:]' '[:lower:]')
if [ "${OS_NAME}" != 'ubuntu' ]; then
    die "error: this script is only allowed to run on Ubuntu"
fi

# Get new host name for this VM
while true; do
    read -p "Please enter a unique hostname for this VM: " NEW_HOST_NAME
    NEW_HOST_NAME=$(trim "$NEW_HOST_NAME")
    if [ "${NEW_HOST_NAME}" != '' ]; then
        # The hostname only allows "A-Za-z0-9-" chars (https://stackoverflow.com/a/3523068)
        if [[ "${NEW_HOST_NAME}" =~ ^[A-Za-z0-9-]*$ ]]; then
            break
        else
            echo "error: hostname only allows chars a-z, 0-9 and the hyphen (-)"
        fi
    fi
done

# Change hostname
hostnamectl hostname "$NEW_HOST_NAME" || die "error: could not change hostname via hostnamectl"
sed -i "s/$HOST_NAME/$NEW_HOST_NAME/g" /etc/hosts || die "error: could not change hostname in /etc/hosts"

# Success
say "success: host name changed from ${HOST_NAME} to ${NEW_HOST_NAME}"