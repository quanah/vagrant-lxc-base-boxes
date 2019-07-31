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

PACKAGES=(vim curl wget man-db openssh-server bash-completion ca-certificates sudo)

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
if [ $RELEASE != 'stretch' ] && [ $RELEASE != 'bionic' ] && [ $RELEASE != 'buster'] ; then
  PACKAGES+=' python-software-properties'
fi
utils.lxc.attach apt-get update
utils.lxc.attach apt-get install ${PACKAGES[*]} -y --force-yes
utils.lxc.attach apt-get upgrade -y --force-yes

BABUSHKA=${BABUSHKA:-0}

if [ $DISTRIBUTION = 'debian' ]; then
  # Enable bash-completion
  sed -e '/^#if ! shopt -oq posix; then/,/^#fi/ s/^#\(.*\)/\1/g' \
    -i ${ROOTFS}/etc/bash.bashrc
fi

if [ $BABUSHKA = 1 ]; then
  if $(lxc-attach -n ${CONTAINER} -- which babushka &>/dev/null); then
    log "Babushka has been installed on container, skipping"
  elif [ ${RELEASE} = 'trusty' ]; then
    warn "Babushka can't be installed on Ubuntu Trusty 14.04, skipping"
  else
    log "Installing Babushka"
    cat > $ROOTFS/tmp/install-babushka.sh << EOF
#!/bin/sh
curl https://babushka.me/up | sudo bash
EOF
    chmod +x $ROOTFS/tmp/install-babushka.sh
    utils.lxc.attach /tmp/install-babushka.sh
  fi
else
  log "Skipping Babushka installation"
fi
