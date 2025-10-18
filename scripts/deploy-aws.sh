#!/bin/bash

# AWS Deployment Script
# Deploys AI Chatbot to AWS using Terraform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="terraform/aws"
PROJECT_NAME="ai-chatbot"
AWS_REGION="us-east-1"

echo -e "${BLUE}🚀 AWS Deployment Script${NC}"
echo "Deploying AI Chatbot to AWS using Terraform"
echo ""

# Check prerequisites
echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not found. Please install it first.${NC}"
    echo "Install: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform not found. Please install it first.${NC}"
    echo "Install: https://developer.hashicorp.com/terraform/downloads"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured.${NC}"
    echo "Run: aws configure"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Generate SSH key pair if not exists
if [ ! -f ~/.ssh/id_rsa ]; then
    echo -e "${YELLOW}🔑 Generating SSH key pair...${NC}"
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    echo -e "${GREEN}✅ SSH key pair generated${NC}"
fi

# Get public key
PUBLIC_KEY=$(cat ~/.ssh/id_rsa.pub)

# Navigate to terraform directory
cd "$TERRAFORM_DIR"

# Initialize Terraform
echo -e "${YELLOW}📦 Initializing Terraform...${NC}"
terraform init

# Plan deployment
echo -e "${YELLOW}📋 Planning deployment...${NC}"
terraform plan \
    -var="public_key=$PUBLIC_KEY" \
    -var="private_key_path=~/.ssh/id_rsa" \
    -out=tfplan

# Ask for confirmation
echo ""
echo -e "${YELLOW}⚠️ This will create AWS resources that may incur costs.${NC}"
echo -e "${YELLOW}The deployment uses free tier eligible resources where possible.${NC}"
read -p "Do you want to proceed? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Deployment cancelled${NC}"
    exit 1
fi

# Apply deployment
echo -e "${YELLOW}🚀 Applying deployment...${NC}"
terraform apply tfplan

# Get outputs
echo -e "${YELLOW}📊 Getting deployment information...${NC}"
INSTANCE_IP=$(terraform output -raw instance_public_ip)
APPLICATION_URL=$(terraform output -raw application_url)
SSH_COMMAND=$(terraform output -raw ssh_command)

# Wait for instance to be ready
echo -e "${YELLOW}⏳ Waiting for instance to be ready...${NC}"
sleep 60

# Deploy application
echo -e "${YELLOW}📦 Deploying application...${NC}"

# Create deployment package
cd ../..
tar -czf app.tar.gz \
    --exclude='.git' \
    --exclude='__pycache__' \
    --exclude='venv' \
    --exclude='.env' \
    --exclude='terraform' \
    --exclude='.github' \
    .

# Upload and deploy
scp -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa app.tar.gz ubuntu@$INSTANCE_IP:/tmp/

ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa ubuntu@$INSTANCE_IP << 'EOF'
    cd /opt/ai-chatbot
    sudo tar -xzf /tmp/app.tar.gz --strip-components=0
    sudo chown -R ubuntu:ubuntu /opt/ai-chatbot
    sudo systemctl restart ai-chatbot
    rm /tmp/app.tar.gz
EOF

# Cleanup
rm app.tar.gz

# Health check
echo -e "${YELLOW}🔍 Performing health check...${NC}"
sleep 30

for i in {1..10}; do
    if curl -f -s $APPLICATION_URL > /dev/null; then
        echo -e "${GREEN}✅ Application is healthy!${NC}"
        break
    else
        echo -e "${YELLOW}⏳ Waiting for application to be ready... (attempt $i/10)${NC}"
        sleep 30
    fi
done

# Success message
echo ""
echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Deployment Information:${NC}"
echo "  🌐 Application URL: $APPLICATION_URL"
echo "  🖥️ Instance IP: $INSTANCE_IP"
echo "  🔑 SSH Command: $SSH_COMMAND"
echo ""
echo -e "${BLUE}🛠️ Management Commands:${NC}"
echo "  Check status: ssh -i ~/.ssh/id_rsa ubuntu@$INSTANCE_IP 'ai-chatbot status'"
echo "  View logs: ssh -i ~/.ssh/id_rsa ubuntu@$INSTANCE_IP 'ai-chatbot logs'"
echo "  Restart app: ssh -i ~/.ssh/id_rsa ubuntu@$INSTANCE_IP 'ai-chatbot restart'"
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo "  - The application will auto-start on server reboot"
echo "  - Check AWS Console for resource monitoring"
echo "  - Use 'terraform destroy' to clean up resources"
