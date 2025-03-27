#!/bin/bash
#--------------------------------------------------------------------
# Script to Install Prometheus Node_Exporter on CentOS Stream  9
# Tested on  CentOS Stream Vagrant 9
#--------------------------------------------------------------------
# https://github.com/prometheus/node_exporter/releases
NODE_EXPORTER_VERSION="1.9.0"

cd /tmp
curl -L https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz -O
tar xvfz node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
cd node_exporter-$NODE_EXPORTER_VERSION.linux-amd64

mv node_exporter /usr/bin/
sudo chcon -t bin_t /usr/bin/node_exporter
rm -rf /tmp/node_exporter*

useradd -rs /bin/false node_exporter
chown node_exporter:node_exporter /usr/bin/node_exporter



cat <<EOF> /etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
ExecStart=/usr/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter
systemctl status node_exporter
node_exporter --version