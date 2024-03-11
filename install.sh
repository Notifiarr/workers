#!/bin/bash

# This is the entry point for setting up a worker. Download and run this script on a fresh Ubuntu 22.04 server.

curl -s https://golift.io/repo.sh | sudo bash -s - notifiarr

echo "Adding Nonpublic Golift APT repo"
curl -sL https://packagecloud.io/golift/nonpublic/gpgkey | gpg --dearmor > /tmp/golift-nonpublic-keyring.gpg && \
    sudo mv -f /tmp/golift-nonpublic-keyring.gpg /usr/share/keyrings/golift-nonpublic-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/golift-nonpublic-keyring.gpg] https://packagecloud.io/golift/nonpublic/ubuntu focal main" | \
    sudo tee /etc/apt/sources.list.d/golift-nonpublic.list

sudo add-apt-repository -y ppa:ondrej/php
sudo apt install -y notifiarr-worker

if ! grep -q /share /etc/fstab ; then
    echo "Adding /share mount to /etc/fstab:"
    echo "10.1.0.92:/volume1/data/share /share nfs rw,noatime,norelatime,async,vers=4.0,rsize=131072,wsize=131072,soft,sec=sys 0 0" | \
        sudo tee -a /etc/fstab
fi

if [ ! -d /share/workers ]; then
    sudo mkdir -p /share
    sudo mount /share
fi

if [ -f /share/workers/defaults/notifiarr.conf ] && \
        ! diff -s /etc/notifiarr/notifiarr.conf /share/workers/defaults/notifiarr.conf >/dev/null; then
    echo "Installing notifiarr.conf and restarting the client"
    sudo cp /share/workers/defaults/notifiarr.conf /etc/notifiarr/
    sudo systemctl restart notifiarr
fi

if [ -f /share/workers/defaults/datadog-api-key.txt ] && [ ! -d /etc/datadog-agent ]; then
    echo "Installing datadog agent."
    DD_API_KEY=$(head -n1 /share/workers/defaults/datadog-api-key.txt) \
    DD_SITE="datadoghq.com" \
    DD_APM_INSTRUMENTATION_ENABLED=host \
        bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script_agent7.sh)"
fi

if [ -d /etc/datadog-agent ] && [ ! -f /etc/datadog-agent/environment ]; then
    echo "Creating Datadog environment config file: /etc/datadog-agent/environment"
    echo "DD_PROCESS_AGENT_ENABLED=true"                     | sudo tee    /etc/datadog-agent/environment
    echo "DD_SYSTEM_PROBE_NETWORK_ENABLED=true"              | sudo tee -a /etc/datadog-agent/environment
    echo "DD_PROCESS_CONFIG_PROCESS_COLLECTION_ENABLED=true" | sudo tee -a /etc/datadog-agent/environment
    sudo systemctl restart datadog-agent
fi
