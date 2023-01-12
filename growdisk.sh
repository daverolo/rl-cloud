#!/bin/bash
# -----------------------------------------------------------------------------
# What: Grow partition and disk size to the maximum available
# Link: https://raw.githubusercontent.com/daverolo/rl-cloud/main/growdisk.sh
# Usage: sudo bash growdisk.sh
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

# Set disk and partition infos
DISK_NAME=$(lsblk | grep disk | awk -F " " '{print $1}')            # e.g. -> vda
DISK_PATH=$(df -h | grep "${DISK_NAME}" | awk -F " " '{print $1}')  # e.g. -> /dev/vda2
PART_NAME=$(basename "${DISK_PATH}")                                # e.g. -> vda2
PART_PATH="${DISK_PATH%?}"                                          # e.g. -> /dev/vda
PART_NUM="${DISK_PATH:0-1}"                                         # e.g. -> 2

# Set disk and partition size as number (e.g: 500 for 500G)
DISK_SIZE_STRING=$(lsblk | grep disk | awk -F " " '{print $4}')
DISK_SIZE=$(echo "${DISK_SIZE_STRING}" | tr -d -c 0-9)
PART_SIZE_STRING=$(lsblk | grep "${PART_NAME}.*part" | awk -F " " '{print $4}' | tr -d -c 0-9)
PART_SIZE=$(echo "${PART_SIZE_STRING}" | tr -d -c 0-9)

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

# Check if disk space is available to grow the partition
if [ $DISK_SIZE -le $PART_SIZE ]; then
    #die "error: no space left to grow partition"
    die "error: disk ${DISK_PATH} already using all ${DISK_SIZE_STRING} space"
fi

# Grow partition and disk size
growpart ${PART_PATH} ${PART_NUM} || die "error: could not grow partition size"
resize2fs ${DISK_PATH} || die "error: could not grow disk size"

# Success
say "success: disk ${DISK_PATH} resized to ${DISK_SIZE_STRING}"