#!/bin/bash

# This is the prerm deb package script. It runs before the package is removed.

if [ "$1" = "upgrade" ] || [ "$1" = "1" ] ; then
  exit 0
fi

# Put this back.
if [ -d /etc/supervisor ]; then
  rm -f /etc/supervisor/conf.d
  mkdir /etc/supervisor/conf.d
fi

if [ -x "/bin/systemctl" ]; then
  /bin/systemctl stop supervisor
fi
