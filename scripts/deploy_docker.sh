#!/bin/bash
set -e

INSTANCE_IP=$1
SSH_KEY=$2

echo "Waiting for EC2 instance to be SSH-ready..."
until ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@"$INSTANCE_IP" 'echo ok' &>/dev/null; do
  echo "⏳ Waiting for SSH..."
  sleep 5
done

ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@"$INSTANCE_IP" <<'DEPLOY'
sudo apt update && sudo apt install -y docker.io
sudo systemctl enable docker
docker pull crooper/ai-model:latest
docker stop ai-chatbot || true
docker rm ai-chatbot || true
docker run -d --name ai-chatbot -p 80:80 crooper/ai-model:latest
DEPLOY
