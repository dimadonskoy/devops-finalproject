#!/bin/bash

# Remote Deployment Script for Ubuntu Server
# Usage: ./deploy-remote.sh <server_ip> <username> [ssh_key_path]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVER_IP=$1
USERNAME=$2
SSH_KEY=${3:-~/.ssh/id_rsa}
APP_NAME="ai-chatbot"
REMOTE_DIR="/opt/$APP_NAME"
DOCKER_IMAGE="crooper/ai-model:latest"

# Validate arguments
if [ -z "$SERVER_IP" ] || [ -z "$USERNAME" ]; then
    echo -e "${RED}❌ Usage: $0 <server_ip> <username> [ssh_key_path]${NC}"
    echo "Example: $0 192.168.1.100 ubuntu ~/.ssh/id_rsa"
    exit 1
fi

echo -e "${BLUE}🚀 Starting deployment to $SERVER_IP${NC}"
echo -e "${BLUE}📋 Configuration:${NC}"
echo "  Server: $SERVER_IP"
echo "  User: $USERNAME"
echo "  SSH Key: $SSH_KEY"
echo "  App Name: $APP_NAME"
echo "  Remote Directory: $REMOTE_DIR"
echo ""

# Check if SSH key exists
if [ ! -f "$SSH_KEY" ]; then
    echo -e "${RED}❌ SSH key not found at $SSH_KEY${NC}"
    exit 1
fi

# Test SSH connection
echo -e "${YELLOW}🔍 Testing SSH connection...${NC}"
if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o BatchMode=yes "$USERNAME@$SERVER_IP" "echo 'SSH connection successful'" > /dev/null 2>&1; then
    echo -e "${RED}❌ Cannot connect to server. Please check:${NC}"
    echo "  - Server IP address"
    echo "  - Username"
    echo "  - SSH key path"
    echo "  - Server is running and accessible"
    exit 1
fi
echo -e "${GREEN}✅ SSH connection successful${NC}"

# Create deployment package
echo -e "${YELLOW}📦 Creating deployment package...${NC}"
TEMP_DIR=$(mktemp -d)
DEPLOY_PACKAGE="$TEMP_DIR/$APP_NAME.tar.gz"

# Copy necessary files
cp -r . "$TEMP_DIR/$APP_NAME"
cd "$TEMP_DIR/$APP_NAME"

# Remove unnecessary files
rm -rf .git __pycache__ venv .env
find . -name "*.pyc" -delete
find . -name ".DS_Store" -delete

# Create tar.gz package
tar -czf "$DEPLOY_PACKAGE" -C "$TEMP_DIR" "$APP_NAME"
echo -e "${GREEN}✅ Deployment package created${NC}"

# Upload to server
echo -e "${YELLOW}📤 Uploading to server...${NC}"
scp -i "$SSH_KEY" "$DEPLOY_PACKAGE" "$USERNAME@$SERVER_IP:/tmp/"
echo -e "${GREEN}✅ Upload completed${NC}"

# Deploy on server
echo -e "${YELLOW}🔧 Deploying on server...${NC}"
ssh -i "$SSH_KEY" "$USERNAME@$SERVER_IP" << EOF
set -e

echo "📋 Server deployment started..."

# Create application directory
sudo mkdir -p $REMOTE_DIR
sudo chown $USERNAME:$USERNAME $REMOTE_DIR

# Extract application
cd $REMOTE_DIR
tar -xzf /tmp/$APP_NAME.tar.gz --strip-components=1
rm /tmp/$APP_NAME.tar.gz

# Set proper permissions
chmod +x deploy.sh
chmod 644 docker-compose.yml Dockerfile nginx.conf
chmod -R 755 templates/

echo "✅ Application extracted successfully"

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "📦 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USERNAME
    echo "✅ Docker installed"
else
    echo "✅ Docker already installed"
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    echo "📦 Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose installed"
else
    echo "✅ Docker Compose already installed"
fi

# Create systemd service for auto-start
sudo tee /etc/systemd/system/$APP_NAME.service > /dev/null << 'SERVICE_EOF'
[Unit]
Description=AI Chatbot Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$REMOTE_DIR
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0
User=$USERNAME
Group=$USERNAME

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable $APP_NAME.service

echo "✅ Systemd service created and enabled"

# Start the application
echo "🚀 Starting application..."
/usr/local/bin/docker-compose up -d --build

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 30

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    echo "✅ Application started successfully!"
    echo "🌐 Application is available at: http://$SERVER_IP"
else
    echo "❌ Some services failed to start"
    docker-compose logs
    exit 1
fi

echo "📋 Deployment completed successfully!"
echo "🔧 Useful commands:"
echo "  View logs: docker-compose logs -f"
echo "  Stop app: docker-compose down"
echo "  Restart: sudo systemctl restart $APP_NAME"
echo "  Status: sudo systemctl status $APP_NAME"
EOF

# Cleanup
rm -rf "$TEMP_DIR"

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${BLUE}📋 Next steps:${NC}"
echo "  1. Visit: http://$SERVER_IP"
echo "  2. Check logs: ssh -i $SSH_KEY $USERNAME@$SERVER_IP 'cd $REMOTE_DIR && docker-compose logs -f'"
echo "  3. Monitor status: ssh -i $SSH_KEY $USERNAME@$SERVER_IP 'sudo systemctl status $APP_NAME'"
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo "  - The app will auto-start on server reboot"
echo "  - Use 'sudo systemctl restart $APP_NAME' to restart the app"
echo "  - Check 'docker-compose logs' if you encounter issues"
