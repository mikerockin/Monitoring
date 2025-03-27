#!/bin/bash
#--------------------------------------------------------------------
# Script to Install Prometheus Mysqld_Exporter on CentOS Stream  9
# Tested on  CentOS Stream Vagrant 9
#--------------------------------------------------------------------
# https://github.com/prometheus/mysqld_exporter/releases

MYSQLD_EXPORTER_VERSION="0.17.2"

cd /tmp
curl -L https://github.com/prometheus/mysqld_exporter/releases/download/v$MYSQLD_EXPORTER_VERSION/mysqld_exporter-$MYSQLD_EXPORTER_VERSION.linux-amd64.tar.gz -O
tar xvfz mysqld_exporter-$MYSQLD_EXPORTER_VERSION.linux-amd64.tar.gz
cd mysqld_exporter-$MYSQLD_EXPORTER_VERSION.linux-amd64

mv mysqld_exporter /usr/bin/
chcon -t bin_t /usr/bin/mysqld_exporter
rm -rf /tmp/mysqld_exporter*

useradd -rs /bin/false mysqld_exporter
chown mysqld_exporter:mysqld_exporter /usr/bin/mysqld_exporter

cat <<EOF> /etc/mysqld_exporter.cnf
[client]
user = exporter
password = MyNewPass4!
socket = /var/lib/mysql/mysql.sock
EOF

cat <<EOF> /etc/systemd/system/mysqld_exporter.service
[Unit]
Description=Prometheus MySQL Exporter
After=network.target

[Service]
User=mysqld_exporter
Group=mysqld_exporter
Type=simple
Restart=on-failure
ExecStart=/usr/bin/mysqld_exporter --config.my-cnf=/etc/mysqld_exporter.cnf

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start mysqld_exporter
systemctl enable mysqld_exporter
systemctl status mysqld_exporter
