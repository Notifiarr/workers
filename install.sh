#!/bin/bash

# This is the entry point for setting up a worker. Download and run this script on a fresh Ubuntu 22.04 server.

curl -s https://golift.io/repo.sh | sudo bash -s - notifiarr
echo "Adding Nonpublic Golift APT repo"
echo "deb [signed-by=/usr/share/keyrings/golift-archive-keyring.gpg] https://packagecloud.io/golift/nonpublic/ubuntu focal main" | \
    sudo tee /etc/apt/sources.list.d/golift-nonpublic.list
sudo add-apt-repository ppa:ondrej/php
sudo apt install -y notifiarr-workers

if ! grep -q /share /etc/fstab ; then
    echo "Adding /share mount to /etc/fstab:"
    echo "10.1.0.92:/volume1/data /share nfs rw,noatime,norelatime,async,vers=4.0,rsize=131072,wsize=131072,soft,sec=sys 0 0" | sudo tee -a /etc/fstab
    sudo mount /share
fi

if [ -f /share/workers/defaults/notifiarr.conf ]; then
    sudo cp /share/workers/defaults/notifiarr.conf /etc/notifiarr/
    sudo systemctl restart notifiarr
fi

if [ -f /share/workers/defaults/datadog-api-key.txt ]; then
    echo "Installing datadog agent."
    DD_API_KEY=$(head -n1 /share/workers/defaults/datadog-api-key.txt) \
    DD_SITE="datadoghq.com" \
    DD_APM_INSTRUMENTATION_ENABLED=host \
        bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script_agent7.sh)"
fi

echo "Creating Datadog environment config file: /etc/datadog-agent/environment"
mkdir -p /etc/datadog-agent/
echo "DD_PROCESS_AGENT_ENABLED=true"                     | sudo tee    /etc/datadog-agent/environment
echo "DD_SYSTEM_PROBE_NETWORK_ENABLED=true"              | sudo tee -a /etc/datadog-agent/environment
echo "DD_PROCESS_CONFIG_PROCESS_COLLECTION_ENABLED=true" | sudo tee -a /etc/datadog-agent/environment
sudo systemctl restart datadog-agent