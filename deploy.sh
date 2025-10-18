#!/bin/bash
# deploy.sh - deploy using docker-compose

cd /opt/ai-chatbot || exit 1

# stop old containers
docker-compose down || true

# pull latest images
docker-compose pull

# start containers in detached mode
docker-compose up -d
