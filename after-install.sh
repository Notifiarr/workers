#!/bin/sh

# This is the postinst deb package script. It runs after the package contents are installed.

set -e

# Backup our ssh keys if they aren't already.
if [ -d "/share/workers/defaults/ssh" ] && [ ! -d "/share/workers/defaults/ssh/$(hostname -s)" ]; then
  mkdir "/share/workers/defaults/ssh/$(hostname -s)"
  cp -r /etc/ssh/ssh_host_* "/share/workers/defaults/ssh/$(hostname -s)"
fi

if [ -d ~abc/.ssh ]; then
  chown -R abc: ~abc
fi

if [ -x "/bin/systemctl" ]; then
  /bin/systemctl daemon-reload

  if [ -d "/share/websites/www" ]; then
    echo "Restarting supervisor daemon!"
    /bin/systemctl restart supervisor
  fi
fi

# Replace the ssh keys with the backup if they're different; then restart sshd.
if [ -d "/share/workers/defaults/ssh/$(hostname -s)" ] && \
  ! diff -q "/share/workers/defaults/ssh/$(hostname -s)/ssh_host_ecdsa_key" /etc/ssh/ssh_host_ecdsa_key >/dev/null 2>&1
then
  echo "SSH Host keys updated. Restarting SSH daemon!"
  cp -r "/share/workers/defaults/ssh/$(hostname -s)/ssh_host_*" /etc/ssh/
  /bin/systemctl restart sshd
fi
