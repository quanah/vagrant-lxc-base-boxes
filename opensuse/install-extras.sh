#!/bin/bash
set -e

source common/ui.sh
source common/utils.sh

info 'Installing extra packages and upgrading'

debug 'Bringing container up'
utils.lxc.start

# Sleep for a bit so that the container can get an IP
SECS=20
log "Sleeping for $SECS seconds..."
sleep $SECS

# Fix name resolution
utils.lxc.attach bash -c 'echo "nameserver 192.168.122.1" > /etc/resolv.conf'
lxc-attach -n ${CONTAINER} -- bash -c 'echo "nameserver 192.168.122.1" > /etc/resolv.conf'

# TODO: Support for appending to this list from outside
PACKAGES=(vim curl wget man sudo openssh)

utils.lxc.attach zypper --no-gpg-checks --gpg-auto-import-keys update -y
utils.lxc.attach zypper install -y ${PACKAGES[*]}
