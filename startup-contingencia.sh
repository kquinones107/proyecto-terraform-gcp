#!/bin/bash
set -eux

mkdir -p /var/www/html

printf '%s\n' \
'<!DOCTYPE html>' \
'<html>' \
'<head>' \
'  <meta charset="UTF-8">' \
'  <title>Servicio de Contingencia</title>' \
'</head>' \
'<body style="font-family: Arial; text-align: center; margin-top: 80px;">' \
'  <h1>Error 503 - Sitio en Mantenimiento Programado</h1>' \
'</body>' \
'</html>' > /var/www/html/index.html

cat > /etc/systemd/system/servicio-web.service <<'SERVICE'
[Unit]
Description=Servicio web simple para Terraform
After=network.target

[Service]
WorkingDirectory=/var/www/html
ExecStart=/usr/bin/python3 -m http.server 80
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable servicio-web
systemctl restart servicio-web