
#!/usr/bin/env bash

set -euo pipefail

LOGFILE="/var/log/deploy-on-cloud.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "🚀 Starting Local AI Chatbot deployment..."

REPO_DIR="/opt/devops-finalproject"
REPO_URL="https://github.com/crooper/devops-finalproject.git"

if [ -d "$REPO_DIR" ]; then
    echo "ℹ️  Repository already exists at $REPO_DIR — pulling latest changes"
    cd "$REPO_DIR"
    git pull --rebase || echo "⚠️  Git pull failed — continuing with existing copy"
else
    echo "📥 Cloning repository into $REPO_DIR"
    git clone "$REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
fi

# Ensure docker is available
if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    echo "❌ Docker not available or not running. Installing prerequisites and Docker..."
    # remove conflicting packages quietly
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        apt-get remove -y "$pkg" || true
    done
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
        $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable --now docker || true
fi

echo "📦 Building and starting services (docker-compose)..."
# Use compose plugin if available, otherwise fall back to docker-compose binary
if docker compose version >/dev/null 2>&1; then
    docker compose up -d --build
else
    docker-compose up -d --build
fi

echo "⏳ Waiting for Ollama service to be healthy..."
sleep 15

# Pull AI model if ollama container exists
if docker ps --format '{{.Names}}' | grep -q "ollama"; then
    echo "🤖 Pulling AI model (may take several minutes)..."
    docker exec ollama ollama pull "gemma:2b" || echo "⚠️ Failed to pull model inside container"
else
    echo "⚠️ ollama container not found — skipping model pull"
fi

echo "⏳ Waiting briefly for services to settle..."
sleep 5

if (docker compose ps 2>/dev/null || docker-compose ps) | grep -q "Up"; then
    echo "✅ Services are running successfully!"
    echo "🤖 Ollama is available at: http://ollama.local (or the VM IP)"
    echo "📋 To view logs: docker compose logs -f || docker-compose logs -f"
    echo "🛑 To stop services: docker compose down || docker-compose down"
else
    echo "❌ Some services failed to start. Check logs with: docker compose logs or docker-compose logs"
    exit 1
fi
