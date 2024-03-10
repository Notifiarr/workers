#!/bin/bash

# This is the prerm deb package script.

if [ "$1" = "upgrade" ] || [ "$1" = "1" ] ; then
  exit 0
fi

# do stuff here.