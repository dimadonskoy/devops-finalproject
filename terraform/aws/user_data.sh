#!/bin/bash

# Ubuntu Server Setup Script for AI Chatbot
# This script runs on EC2 instance startup

set -e

# Update system
apt update && apt upgrade -y

# Install essential packages
apt install -y \
    curl \
    wget \
    git \
    unzip \
    htop \
    ufw \
    fail2ban \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Configure firewall
ufw --force enable
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 11434/tcp

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu
rm get-docker.sh

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create application directory
mkdir -p /opt/${project_name}
chown ubuntu:ubuntu /opt/${project_name}

# Create systemd service
cat > /etc/systemd/system/${project_name}.service << 'EOF'
[Unit]
Description=AI Chatbot Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/${project_name}
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0
User=ubuntu
Group=ubuntu

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl daemon-reload
systemctl enable ${project_name}.service

# Create monitoring script
cat > /usr/local/bin/${project_name}-monitor << 'EOF'
#!/bin/bash
APP_DIR="/opt/${project_name}"
cd $APP_DIR

if ! docker-compose ps | grep -q "Up"; then
    echo "$(date): Containers not running, attempting restart..."
    docker-compose up -d
    sleep 30
fi
EOF

chmod +x /usr/local/bin/${project_name}-monitor

# Set up monitoring cron job
(crontab -u ubuntu -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/${project_name}-monitor") | crontab -u ubuntu -

# Create management script
cat > /usr/local/bin/${project_name} << 'EOF'
#!/bin/bash
APP_DIR="/opt/${project_name}"
cd $APP_DIR

case "$1" in
    start)
        echo "Starting AI Chatbot..."
        docker-compose up -d
        ;;
    stop)
        echo "Stopping AI Chatbot..."
        docker-compose down
        ;;
    restart)
        echo "Restarting AI Chatbot..."
        docker-compose down
        docker-compose up -d
        ;;
    status)
        echo "AI Chatbot Status:"
        docker-compose ps
        ;;
    logs)
        docker-compose logs -f
        ;;
    update)
        echo "Updating AI Chatbot..."
        docker-compose pull
        docker-compose up -d --build
        ;;
    *)
        echo "Usage: ${project_name} {start|stop|restart|status|logs|update}"
        exit 1
        ;;
esac
EOF

chmod +x /usr/local/bin/${project_name}

# Log completion
echo "$(date): Server setup completed" >> /var/log/user-data.log
