#!/bin/bash

curl -s https://golift.io/repo.sh | sudo bash -s - notifiarr
echo "deb [signed-by=/usr/share/keyrings/golift-archive-keyring.gpg] https://packagecloud.io/golift/nonpublic/ubuntu focal main" | \
    sudo tee /etc/apt/sources.list.d/golift-nonpublic.list
sudo add-apt-repository ppa:ondrej/php
sudo apt install -y notifiarr-workers

if [ $DD_API_KEY != "" ]; then
 DD_SITE="datadoghq.com" DD_APM_INSTRUMENTATION_ENABLED=host \
    bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script_agent7.sh)"
fi

mkdir -p /etc/datadog-agent/
echo "DD_PROCESS_AGENT_ENABLED=true"                      > /etc/datadog-agent/environment
echo "DD_SYSTEM_PROBE_NETWORK_ENABLED=true"              >> /etc/datadog-agent/environment
echo "DD_PROCESS_CONFIG_PROCESS_COLLECTION_ENABLED=true" >> /etc/datadog-agent/environment


