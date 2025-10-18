#!/bin/bash
# deploy.sh - Deploy Docker Compose app to EC2

set -e  # exit on error

APP_DIR="/opt/ai-chatbot"

echo "🔹 Creating app directory if it doesn't exist..."
sudo mkdir -p "$APP_DIR"
sudo chown ubuntu:ubuntu "$APP_DIR"

echo "🔹 Copying app files..."
# Assuming you have already scp'ed files to /tmp/app.tar.gz
sudo tar -xzf /tmp/app.tar.gz -C "$APP_DIR" --strip-components=0

echo "🔹 Deploying Docker Compose..."
cd "$APP_DIR"
docker compose pull
docker compose down || true
docker compose up -d

echo "✅ Deployment finished"
