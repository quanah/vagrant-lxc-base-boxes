#!/bin/bash
set -e

source common/ui.sh
source common/utils.sh

info 'Installing extra packages and upgrading'

debug 'Bringing container up'
utils.lxc.start

# Sleep for a bit so that the container can get an IP
SECS=15
log "Sleeping for $SECS seconds..."
sleep $SECS

PACKAGES=(apt-utils vim curl wget man-db openssh-server bash-completion ca-certificates sudo psmisc)

log "Installing additional packages: ${ADDPACKAGES}"
PACKAGES+=" ${ADDPACKAGES}"

if [ $DISTRIBUTION = 'ubuntu' ]; then
  PACKAGES+=' software-properties-common'
  if [ $RELEASE == 'xenial' ]; then
    PACKAGES+=' libpam-systemd'
  fi
fi
if [ $RELEASE != 'raring' ] && [ $RELEASE != 'saucy' ] && [ $RELEASE != 'trusty' ] && [ $RELEASE != 'wily' ] ; then
  PACKAGES+=' nfs-common'
fi
if [ $RELEASE != 'stretch' ] && [ $RELEASE != 'bionic' ] && [ $RELEASE != 'buster' ] ; then
  PACKAGES+=' python-software-properties'
fi
if [ $RELEASE = 'jessie' ]; then
  PACKAGES+=' dbus'
fi

utils.lxc.attach apt-get update
utils.lxc.attach apt-get install ${PACKAGES[*]} -y --force-yes
utils.lxc.attach apt-get upgrade -y --force-yes

if [ $DISTRIBUTION = 'debian' ]; then
  # Enable bash-completion
  sed -e '/^#if ! shopt -oq posix; then/,/^#fi/ s/^#\(.*\)/\1/g' \
    -i ${ROOTFS}/etc/bash.bashrc
fi

