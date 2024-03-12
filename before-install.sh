#!/bin/sh

# This is the preinst deb package script. It runs before the package is installed.

# Make a user and group for this app, but only if it does not already exist.
groupadd --force --non-unique --gid 1001 abc
id abc >/dev/null 2>&1 || \
  useradd --non-unique --create-home --uid 1001 --gid 1001 --groups users abc

mkdir -p ~abc/.ssh
