#!/bin/bash

# Ubuntu Server Setup Script for AI Chatbot Deployment
# Run this script on your Ubuntu server before deploying the application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Ubuntu Server Setup for AI Chatbot${NC}"
echo "This script will prepare your Ubuntu server for deployment"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}❌ Please don't run this script as root. Use a regular user with sudo privileges.${NC}"
    exit 1
fi

# Update system packages
echo -e "${YELLOW}📦 Updating system packages...${NC}"
sudo apt update && sudo apt upgrade -y
echo -e "${GREEN}✅ System packages updated${NC}"

# Install essential packages
echo -e "${YELLOW}📦 Installing essential packages...${NC}"
sudo apt install -y \
    curl \
    wget \
    git \
    unzip \
    htop \
    ufw \
    fail2ban \
    nginx \
    certbot \
    python3-certbot-nginx \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release
echo -e "${GREEN}✅ Essential packages installed${NC}"

# Configure firewall
echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 11434/tcp  # Ollama port
echo -e "${GREEN}✅ Firewall configured${NC}"

# Configure fail2ban
echo -e "${YELLOW}🛡️ Configuring fail2ban...${NC}"
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
echo -e "${GREEN}✅ Fail2ban configured${NC}"

# Install Docker
echo -e "${YELLOW}🐳 Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo -e "${GREEN}✅ Docker installed${NC}"
else
    echo -e "${GREEN}✅ Docker already installed${NC}"
fi

# Install Docker Compose
echo -e "${YELLOW}🐳 Installing Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}✅ Docker Compose installed${NC}"
else
    echo -e "${GREEN}✅ Docker Compose already installed${NC}"
fi

# Create application directory
echo -e "${YELLOW}📁 Creating application directory...${NC}"
sudo mkdir -p /opt/ai-chatbot
sudo chown $USER:$USER /opt/ai-chatbot
echo -e "${GREEN}✅ Application directory created${NC}"

# Configure Nginx (optional - for SSL termination)
echo -e "${YELLOW}🌐 Configuring Nginx...${NC}"
sudo tee /etc/nginx/sites-available/ai-chatbot > /dev/null << 'NGINX_EOF'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_EOF

# Enable the site (optional)
# sudo ln -sf /etc/nginx/sites-available/ai-chatbot /etc/nginx/sites-enabled/
# sudo nginx -t && sudo systemctl reload nginx

# Set up log rotation
echo -e "${YELLOW}📝 Setting up log rotation...${NC}"
sudo tee /etc/logrotate.d/ai-chatbot > /dev/null << 'LOGROTATE_EOF'
/opt/ai-chatbot/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
}
LOGROTATE_EOF

# Create monitoring script
echo -e "${YELLOW}📊 Creating monitoring script...${NC}"
sudo tee /usr/local/bin/ai-chatbot-monitor > /dev/null << 'MONITOR_EOF'
#!/bin/bash
# AI Chatbot Health Monitor

APP_DIR="/opt/ai-chatbot"
LOG_FILE="/var/log/ai-chatbot-monitor.log"

cd $APP_DIR

# Check if containers are running
if ! docker-compose ps | grep -q "Up"; then
    echo "$(date): Containers not running, attempting restart..." >> $LOG_FILE
    docker-compose up -d
    sleep 30
    
    if docker-compose ps | grep -q "Up"; then
        echo "$(date): Containers restarted successfully" >> $LOG_FILE
    else
        echo "$(date): Failed to restart containers" >> $LOG_FILE
    fi
fi
MONITOR_EOF

sudo chmod +x /usr/local/bin/ai-chatbot-monitor

# Set up cron job for monitoring
echo -e "${YELLOW}⏰ Setting up monitoring cron job...${NC}"
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/ai-chatbot-monitor") | crontab -
echo -e "${GREEN}✅ Monitoring cron job set up${NC}"

# Create backup script
echo -e "${YELLOW}💾 Creating backup script...${NC}"
sudo tee /usr/local/bin/ai-chatbot-backup > /dev/null << 'BACKUP_EOF'
#!/bin/bash
# AI Chatbot Backup Script

APP_DIR="/opt/ai-chatbot"
BACKUP_DIR="/opt/backups/ai-chatbot"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Create backup
cd $APP_DIR
tar -czf "$BACKUP_DIR/ai-chatbot-backup-$DATE.tar.gz" \
    --exclude='logs' \
    --exclude='*.log' \
    .

# Keep only last 7 days of backups
find $BACKUP_DIR -name "ai-chatbot-backup-*.tar.gz" -mtime +7 -delete

echo "$(date): Backup created: ai-chatbot-backup-$DATE.tar.gz"
BACKUP_EOF

sudo chmod +x /usr/local/bin/ai-chatbot-backup

# Set up daily backup
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/ai-chatbot-backup") | crontab -
echo -e "${GREEN}✅ Backup script set up${NC}"

# Create management script
echo -e "${YELLOW}🛠️ Creating management script...${NC}"
sudo tee /usr/local/bin/ai-chatbot > /dev/null << 'MANAGE_EOF'
#!/bin/bash
# AI Chatbot Management Script

APP_DIR="/opt/ai-chatbot"
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
    backup)
        /usr/local/bin/ai-chatbot-backup
        ;;
    *)
        echo "Usage: ai-chatbot {start|stop|restart|status|logs|update|backup}"
        exit 1
        ;;
esac
MANAGE_EOF

sudo chmod +x /usr/local/bin/ai-chatbot
echo -e "${GREEN}✅ Management script created${NC}"

# Final system check
echo -e "${YELLOW}🔍 Running final system check...${NC}"

# Check Docker
if docker --version > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker: $(docker --version)${NC}"
else
    echo -e "${RED}❌ Docker not working properly${NC}"
fi

# Check Docker Compose
if docker-compose --version > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker Compose: $(docker-compose --version)${NC}"
else
    echo -e "${RED}❌ Docker Compose not working properly${NC}"
fi

# Check firewall
if sudo ufw status | grep -q "Status: active"; then
    echo -e "${GREEN}✅ Firewall: Active${NC}"
else
    echo -e "${YELLOW}⚠️ Firewall: Not active${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Server setup completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo "1. Reboot your server: sudo reboot"
echo "2. After reboot, deploy your application using the deploy-remote.sh script"
echo ""
echo -e "${BLUE}🛠️ Useful commands:${NC}"
echo "  Start app: ai-chatbot start"
echo "  Stop app: ai-chatbot stop"
echo "  Check status: ai-chatbot status"
echo "  View logs: ai-chatbot logs"
echo "  Create backup: ai-chatbot backup"
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo "  - The server will automatically monitor and restart the app if needed"
echo "  - Daily backups are created at 2 AM"
echo "  - Check logs in /var/log/ai-chatbot-monitor.log"
echo "  - Application will be available at http://your-server-ip"
