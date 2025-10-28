#!/bin/bash

# set -euo pipefail

LOGFILE="/var/log/deploy-on-cloud.log"
exec > >(tee -a "$LOGFILE") 2>&1
d
echo "Starting Local AI Chatbot deployment..."

# Export DEBIAN_FRONTEND for non-interactive apt operations
export DEBIAN_FRONTEND=noninteractive

# Function to run commands with sudo if not root
run_sudo() {
    if [ "$EUID" -ne 0 ]; then
        sudo -n "$@"
    else
        "$@"
    fi
}

REPO_DIR="/opt/devops-finalproject"
REPO_URL="https://github.com/dimadonskoy/devops-finalproject.git"
REPO_BRANCH="clean-main"

CLOUD_SCRIPTS_DIR="/var/lib/cloud/instance/scripts"

# If cloud-init provided repo files, copy them into REPO_DIR
if [ -d "$CLOUD_SCRIPTS_DIR" ] && [ -f "$CLOUD_SCRIPTS_DIR/docker-compose.yml" ]; then
    echo "Found bundled repo files from cloud-init, copying into $REPO_DIR"
    run_sudo mkdir -p "$REPO_DIR"
    run_sudo cp -a "$CLOUD_SCRIPTS_DIR/docker-compose.yml" "$REPO_DIR/docker-compose.yml"
    # copy optional files if present
    for f in Dockerfile nginx.conf requirements.txt app.py templates_index.html selfsigned.crt selfsigned.key; do
        if [ -f "$CLOUD_SCRIPTS_DIR/$f" ]; then
            # templates_index.html should be moved into templates/index.html
            if [ "$f" = "templates_index.html" ]; then
                run_sudo mkdir -p "$REPO_DIR/templates"
                run_sudo cp -a "$CLOUD_SCRIPTS_DIR/$f" "$REPO_DIR/templates/index.html"
            else
                run_sudo cp -a "$CLOUD_SCRIPTS_DIR/$f" "$REPO_DIR/$(echo $f | sed 's/_index//')"
            fi
        fi
    done
    cd "$REPO_DIR"
    # If repo already has a .git, try to pull updates
    if [ -d ".git" ]; then
        run_sudo git config --global --add safe.directory "$REPO_DIR"
        run_sudo git pull --rebase || true
    fi
else
    if [ -d "$REPO_DIR" ]; then
        echo "Repository already exists at $REPO_DIR - pulling latest changes"
        cd "$REPO_DIR"
        run_sudo git config --global --add safe.directory "$REPO_DIR"
        run_sudo git pull --rebase || echo "Git pull failed - continuing with existing copy"
    else
        echo "Cloning repository into $REPO_DIR"
        run_sudo git clone -b "$REPO_BRANCH" "$REPO_URL" "$REPO_DIR"
        cd "$REPO_DIR"
        run_sudo git config --global --add safe.directory "$REPO_DIR"
    fi
fi

# Ensure docker is available
if ! command -v docker >/dev/null 2>&1 || ! run_sudo docker info >/dev/null 2>&1; then
    echo "Docker not available or not running. Installing prerequisites and Docker..."
    
    # Update package list
    run_sudo apt-get update -qq
    
    # Install prerequisites non-interactively
    run_sudo apt-get install -y -qq \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        software-properties-common
    
    # Try Docker CE installation first
    echo "Installing Docker CE..."
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/debian/gpg | run_sudo apt-key add -
    
    # Add Docker repository
    run_sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
    
    # Update and install Docker CE
    run_sudo apt-get update -qq
    run_sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin || {
        echo "Docker CE installation failed, trying docker.io..."
        run_sudo apt-get install -y -qq docker.io docker-compose
    }
    
    # Start and enable Docker
    run_sudo systemctl enable docker || true
    run_sudo systemctl start docker || true
    
    # Wait for Docker to be ready
    echo "Waiting for Docker to be ready..."
    for i in {1..30}; do
        if run_sudo docker info >/dev/null 2>&1; then
            echo "Docker is ready!"
            break
        fi
        echo "Waiting for Docker... ($i/30)"
        sleep 2
    done
fi

echo "Building and starting services (docker-compose)..."
# Use compose plugin if available, otherwise fall back to docker-compose binary
if run_sudo docker compose version >/dev/null 2>&1; then
    run_sudo docker compose up -d --build
else
    run_sudo docker-compose up -d --build
fi

echo "Waiting for Ollama service to be healthy..."
sleep 15

# Pull AI model if ollama container exists
if run_sudo docker ps --format '{{.Names}}' | grep -q "ollama"; then
    echo "Pulling AI model (may take several minutes)..."
    run_sudo docker exec ollama ollama pull "gemma:2b" || echo "Failed to pull model inside container"
else
    echo "ollama container not found - skipping model pull"
fi

echo "Waiting briefly for services to settle..."
sleep 5

# Check if services are running
if (run_sudo docker compose ps 2>/dev/null || run_sudo docker-compose ps) | grep -q "Up"; then
    echo "Services are running successfully!"
    PUBLIC_IP=$(curl -s ifconfig.me)
    echo "Web Interface: http://$PUBLIC_IP:5001"
    echo "Ollama API: http://$PUBLIC_IP:11434"
    echo "To view logs: sudo docker compose logs -f || sudo docker-compose logs -f"
    echo "To stop services: sudo docker compose down || sudo docker-compose down"
else
    echo "Some services failed to start. Check logs with: sudo docker compose logs or sudo docker-compose logs"
    exit 1
fi