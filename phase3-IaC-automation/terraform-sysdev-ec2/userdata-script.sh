#!/bin/bash
apt-get update -y
apt-get install -y nginx

mkdir -p /var/www/portfolio
echo "Hello world from Nginx!" > /var/www/portfolio/index.html

sed -i 's|root /var/www/html;|root /var/www/portfolio;|' /etc/nginx/sites-available/default

nginx -t
systemctl reload nginx
