#!/bin/sh

add-apt-repository ppa:ondrej/php
# Make a user and group for this app, but only if it does not already exist.
id abc >/dev/null 2>&1 || \
  useradd --user-group --non-unique --create-home --uid 1002 --groups users abc

mkdir -p ~abc/.ssh
