#!/usr/bin/env bash
#######################################################################
#Developed by : Dmitri & Yair
#Purpose : Deploy Local AI Chatbot (Ollama model gemma:2b)
#Date : 29.10.2025
#Version : 0.0.1
# set -x
set -o errexit
set -o nounset
set -o pipefail
#######################################################################

echo "🚀 Starting Local AI Chatbot deployment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

echo "🧹 Cleaning up existing containers..."
docker-compose down -v

echo "📦 Building and starting services..."
docker-compose up -d --build

echo "⏳ Waiting for Ollama to be ready..."
sleep 15

echo "🤖 Pulling AI model (this may take a few minutes)..."
docker exec ollama ollama pull "gemma:2b"

echo "⏳ Waiting for model to be ready..."
sleep 5

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    echo "Services are running successfully!"
    echo "Ollama is available at: http://localhost"
    echo ""
    echo "To view logs: docker-compose logs -f"
    echo "To stop services: docker-compose down"
else
    echo "Some services failed to start. Check logs with: docker-compose logs"
    exit 1
fi
