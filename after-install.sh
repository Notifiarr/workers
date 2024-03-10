#!/bin/sh

# This is the postinst deb package script.

if [ -d ~abc/.ssh ]; then
  chown -R abc: ~abc/.ssh
fi

if [ -d /var/log/workers ]; then
  chown -R abc: /var/log/workers
fi

if [ -x "/bin/systemctl" ]; then
  /bin/systemctl daemon-reload
fi
