#!/bin/bash
set -euo pipefail
dnf install -y nginx
printf '<h1>Terraform Cloud Project</h1><p>Host: %s</p>
' "$(hostname)" > /usr/share/nginx/html/index.html
echo ok > /usr/share/nginx/html/health
systemctl enable --now nginx
