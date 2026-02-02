#!/bin/bash
set -e

apt-get update -y
apt-get install -y nginx

mkdir -p /var/www/portfolio
echo "Hello world from Nginx!" > /var/www/portfolio/index.html

sed -i 's|root /var/www/html;|root /var/www/portfolio;|' /etc/nginx/sites-available/default

nginx -t
systemctl reload nginx

# Install CloudWatch Agent
cd /tmp
wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

# Write agent config: tail nginx logs -> CloudWatch Logs group /sysdev/nginx
cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'JSON'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/sysdev/nginx",
            "log_stream_name": "{instance_id}/nginx/access",
            "timestamp_format": "%d/%b/%Y:%H:%M:%S %z"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/sysdev/nginx",
            "log_stream_name": "{instance_id}/nginx/error"
          }
        ]
      }
    }
  }
}
JSON

# Start the agent using that config
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

# install amazon-ssm-agent
apt-get install -y amazon-ssm-agent
systemctl enable --now amazon-ssm-agent
