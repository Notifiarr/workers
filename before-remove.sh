#!/bin/bash

# This is the prerm deb package script. It runs before the package is removed.

if [ "$1" = "upgrade" ] || [ "$1" = "1" ] ; then
  exit 0
fi

if [ -x "/bin/systemctl" ]; then
  /bin/systemctl stop supervisor 2>/dev/null
fi

# Put this back.
if [ -d /etc/supervisor ]; then
  rm -f /etc/supervisor/conf.d 2>/dev/null
  mkdir /etc/supervisor/conf.d 2>/dev/null
fi
