#!/bin/bash
#--------------------------------------------------------------------
# Script to Install Prometheus ALert Manager on CentOS Stream  9
# Tested on  CentOS Stream Vagrant 9
#--------------------------------------------------------------------
# https://github.com/prometheus/alertmanager/releases

ALERT_MANAGER_VERSION="0.28.1"

cd /tmp
curl -L https://github.com/prometheus/alertmanager/releases/download/v$ALERT_MANAGER_VERSION/alertmanager-$ALERT_MANAGER_VERSION.linux-amd64.tar.gz -O
tar xvfz alertmanager-$ALERT_MANAGER_VERSION.linux-amd64.tar.gz
cd alertmanager-$ALERT_MANAGER_VERSION.linux-amd64

mv alertmanager /usr/bin/
chcon -t bin_t /usr/bin/alertmanager
rm -rf /tmp/alertmanager*
mkdir -p /etc/alertmanager
mkdir -p /etc/alertmanager/data

useradd -rs /bin/false alertmanager
chown alertmanager:alertmanager /usr/bin/alertmanager

cat <<EOF>> /etc/alertmanager/alertmanager.yml
global:

route:
  receiver: 'slack-notifications'
  group_by: ['alertname', 'instance']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 1h

receivers:
  - name: 'slack-notifications'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/T08KF6DNH7V/B08KGEH0LSW/*************'
        channel: '#noub'
        send_resolved: true
        title: '{{ .CommonAnnotations.summary }}'
        text: '{{ .CommonAnnotations.description }}'
EOF

cat <<EOF> /etc/systemd/system/alertmanager.service
[Unit]
Description=Prometheus Alertmanager
After=network.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
Restart=on-failure
ExecStart=/usr/bin/alertmanager --config.file=/etc/alertmanager/alertmanager.yml --storage.path=/etc/alertmanager/data

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF> /etc/prometheus/prometheus.yml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ["localhost:9093"]


rule_files:
  - "/etc/prometheus/rules.yml"
EOF

cat <<EOF> /etc/prometheus/rules.yml
groups:
  - name: InstanceDown
    rules:
      - alert: InstanceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Instance {{ $labels.instance }} down"
          description: "{{ $labels.instance }} has been down for more than 1 minute."

  - name: memory-alerts
    rules:
      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 40
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "high RAM usage on {{ $labels.instance }}"
          description: "Used {{ printf \"%.2f\" $value }}% RAM (threshhold: 40%)."
EOF


sudo systemctl daemon-reload
sudo systemctl restart prometheus
sudo systemctl start alertmanager
sudo systemctl enable alertmanager
sudo systemctl status alertmanager
