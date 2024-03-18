#!/bin/bash

# This is the prerm deb package script. It runs before the package is removed.

if [ "$1" = "upgrade" ] || [ "$1" = "1" ] ; then
  exit 0
fi

if [ -L /config/server.json ]; then
  rm -f /config/server.json
fi

if [ -L /config/log ]; then
  rm -f /config/log
fi

if [ -x "/bin/systemctl" ]; then
  /bin/systemctl stop supervisor
fi
