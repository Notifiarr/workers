#!/bin/bash

# This is the entry point for setting up a worker. Download and run this script on a fresh Ubuntu 24.04 server.
# Make sure the new server has access to the NFS /share (see below). It's safe to run this more than once; in case you forgot.

echo "==> Adding Public Golift APT repo"
curl -s https://golift.io/repo.sh | sudo bash -s - notifiarr

echo "==> Adding Nonpublic Golift APT repo"
curl -sL https://packagecloud.io/golift/nonpublic/gpgkey | gpg --dearmor | \
    sudo tee /usr/share/keyrings/golift-nonpublic-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/golift-nonpublic-keyring.gpg] https://packagecloud.io/golift/nonpublic/ubuntu focal main" | \
    sudo tee /etc/apt/sources.list.d/golift-nonpublic.list > /dev/null

echo "==> Adding Influx/Telegraf APT repo"
curl -s https://repos.influxdata.com/influxdata-archive.key | gpg --dearmor | \
    sudo tee /etc/apt/keyrings/influxdata-archive.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main" | \
    sudo tee /etc/apt/sources.list.d/influxdata.list > /dev/null

echo "==> Adding PHP PPA"
sudo add-apt-repository -y ppa:ondrej/php
sudo apt install -y notifiarr-worker

if ! grep -q /share /etc/fstab ; then
    echo "==> Adding /share mount to /etc/fstab:"
    echo "10.1.0.92:/volume1/data/share /share nfs rw,noatime,norelatime,async,vers=4.0,rsize=131072,wsize=131072,soft,sec=sys,auto 0 0" | \
        sudo tee -a /etc/fstab
else
    echo "==> OK: /share is already in /etc/fstab."
fi

if [ ! -d /share/workers ]; then
    sudo mkdir -p /share
    sudo mount /share
fi

if [ -f /share/workers/defaults/notifiarr.conf ] && \
        ! diff -s /etc/notifiarr/notifiarr.conf /share/workers/defaults/notifiarr.conf >/dev/null; then
    echo "==> Installing notifiarr.conf and restarting the client"
    sudo cp /share/workers/defaults/notifiarr.conf /etc/notifiarr/
    sudo systemctl restart notifiarr
else
    echo "==> OK: notifiarr.conf is already installed."
fi
