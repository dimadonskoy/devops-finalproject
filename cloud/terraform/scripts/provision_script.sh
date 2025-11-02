#!/usr/bin/env bash
#######################################################################
#Developed by : Dmitri & Yair
#Purpose : Deploy Local AI Chatbot (Ollama model gemma:2b)
#Date : 31.10.2025
#Version : 0.0.2
set -o errexit
set -o nounset
set -o pipefail


########################## VARIABLES #################################
## Log file
LOGFILE=/var/log/cloud-deploy/cloud-deploy.log

## Repo details
REPO_DIR="/opt/devops-finalproject"
REPO_URL="https://github.com/dimadonskoy/devops-finalproject.git"
REPO_BRANCH="main"

########################################################################

echo "Starting Local AI Chatbot deployment..."

# Create LOGS directory if  not exist
if [[ ! -d "/var/log/cloud-deploy" ]]; then
    echo "LOGS directory does not exist. Creating LOGS directory..."
    mkdir -p /var/log/cloud-deploy
fi


# Check if user is root
if [[ "$EUID" -ne 0 ]]; then
    echo "Please run as root"
    echo
fi


# Check if system is Debian
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    if [[ "$ID" == "debian" ]]; then
        echo "Detected Debian system"
    else
        echo "This is NOT Debian. Exiting..."
        exit 1
    fi
else
    echo "Unknown OS type. Exiting..."
    exit 1
fi


# Function to run commands with sudo if not root
if [[ ! -d "$REPO_DIR/.git" ]]; then
    echo "Cloning repository into $REPO_DIR"
    mkdir -p "$REPO_DIR"
    git clone -b "$REPO_BRANCH" "$REPO_URL" "$REPO_DIR"
else
    echo "Repo exists. Pulling latest..."
    cd "$REPO_DIR"
    git config --global --add safe.directory "$REPO_DIR" || true
    git -C "$REPO_DIR" fetch --all --prune
    git -C "$REPO_DIR" checkout "$REPO_BRANCH"
    git -C "$REPO_DIR" pull --ff-only origin "$REPO_BRANCH"
fi

cd "$REPO_DIR"

# Install Docker if not installed
if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    echo "Installing Docker..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
    add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin || apt-get install -y -qq docker.io docker-compose
    systemctl enable docker || true
    systemctl start docker || true
fi

echo "Starting services..."
if docker compose version >/dev/null 2>&1; then
    docker compose up -d --build
else
    docker-compose up -d --build
fi

echo "Pulling model (if container exists)..."
if docker ps --format '{{.Names}}' | grep -q "ollama"; then
    docker exec ollama ollama pull "gemma:2b" || true
fi

echo "Done."