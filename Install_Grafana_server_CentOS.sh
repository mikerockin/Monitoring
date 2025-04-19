#!/bin/bash
#--------------------------------------------------------------------
# Script to Install Grafana Server on CentOS Stream  9
# Includes Prometheus DataSource Configuration
#--------------------------------------------------------------------
# https://grafana.com/grafana/download

GRAFANA_VERSION="11.6.4"
PROMETHEUS_URL="http://192.168.56.15:9090"

sudo dnf install -y wget
wget -q -O gpg.key https://rpm.grafana.com/gpg.key
sudo rpm --import gpg.key

cat <<EOF> /etc/yum.repos.d/grafana.repo
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

sudo yum install -y https://dl.grafana.com/oss/release/grafana-11.6.0-1.x86_64.rpm
echo "export PATH=/usr/share/grafana/bin:$PATH" >> /etc/profile

cat <<EOF> /etc/grafana/provisioning/datasources/prometheus.yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    url: ${PROMETHEUS_URL}
EOF

systemctl daemon-reload
systemctl start grafana-server
systemctl enable grafana-server
systemctl status grafana-server
