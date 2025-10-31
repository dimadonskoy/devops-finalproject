#!/usr/bin/env bash
#######################################################################
#Developed by : Dmitri & Yair
#Purpose : Deploy Local AI Chatbot (Ollama model gemma:2b)
#Date : 29.10.2025
#Version : 0.0.1
set -o errexit
set -o nounset
set -o pipefail
#######################################################################

LOGFILE="/var/log/deploy-on-cloud.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "Starting Local AI Chatbot deployment..."

# 1. make sure HOME exists (cloud-init often has none)
export HOME=/root

run_sudo() {
  if [ "$EUID" -ne 0 ]; then
    sudo -n "$@"
  else
    "$@"
  fi
}

REPO_DIR="/opt/devops-finalproject"
REPO_URL="https://github.com/dimadonskoy/devops-finalproject.git"
REPO_BRANCH="main"

# 2. get repo (idempotent)
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "Cloning repository into $REPO_DIR"
  run_sudo mkdir -p "$REPO_DIR"
  run_sudo git clone -b "$REPO_BRANCH" "$REPO_URL" "$REPO_DIR"
else
  echo "Repo exists. Pulling latest..."
  cd "$REPO_DIR"
  run_sudo git config --global --add safe.directory "$REPO_DIR" || true
  run_sudo git -C "$REPO_DIR" fetch --all --prune
  run_sudo git -C "$REPO_DIR" checkout "$REPO_BRANCH"
  run_sudo git -C "$REPO_DIR" pull --ff-only origin "$REPO_BRANCH"
fi

cd "$REPO_DIR"

# 3. docker install (same as yours, cut a bit)
if ! command -v docker >/dev/null 2>&1 || ! run_sudo docker info >/dev/null 2>&1; then
  echo "Installing Docker..."
  export DEBIAN_FRONTEND=noninteractive
  run_sudo apt-get update -qq
  run_sudo apt-get install -y -qq apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common
  curl -fsSL https://download.docker.com/linux/debian/gpg | run_sudo apt-key add -
  run_sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
  run_sudo apt-get update -qq
  run_sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin || run_sudo apt-get install -y -qq docker.io docker-compose
  run_sudo systemctl enable docker || true
  run_sudo systemctl start docker || true
fi

echo "Starting services..."
if run_sudo docker compose version >/dev/null 2>&1; then
  run_sudo docker compose up -d --build
else
  run_sudo docker-compose up -d --build
fi

echo "Pulling model (if container exists)..."
if run_sudo docker ps --format '{{.Names}}' | grep -q "ollama"; then
  run_sudo docker exec ollama ollama pull "gemma:2b" || true
fi

echo "Done."