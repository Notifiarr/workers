#!/bin/sh

# This is the postinst deb package script. It runs after the package contents are installed.

set -e

if [ -d ~abc/.ssh ]; then
  chown -R abc: ~abc/.ssh
fi

if [ -d "/var/log/workers" ]; then
  chown -R abc: /var/log/workers
fi

if [ -d "/etc/supervisor/conf.d" ]; then
  rm -rf /etc/supervisor/conf.d
fi

if [ -x "/bin/systemctl" ]; then
  /bin/systemctl daemon-reload

  if [ -d "/share/websites/www" ]; then
    /bin/systemctl restart supervisor
  fi
fi
