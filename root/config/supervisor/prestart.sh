#!/usr/bin/bash

# This script is executed by systemd before sueprvisord is started.
# See: https://github.com/Notifiarr/workers/blob/main/root/etc/systemd/system/supervisor.service.d/notifiarr.conf

set -e
PATH=/usr/bin

# Before starting supervisor, we create a symlink to the website config file for this server.
ln -sf "/share/websites/confs/server.$(hostname -s)" "/config/server.json"

# We also create a symlink to a server-specific log directory in shared storage.
ln -Tsf "/share/logs/notifiarr/supervisor/$(hostname -s)" "/config/log"

# This php script creates (builds) the supervisord configurations for this server.
php /share/websites/www/notifiarr.com/supervisor/confBuilder.php
# The files created by confBuilder.php go in this directory. Fix their ownership.
chown -R abc: "/share/workers/$(hostname -s)/supervisor"
