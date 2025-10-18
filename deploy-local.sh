#!/bin/env bash

set -e

echo "🚀 Starting Local AI Chatbot deployment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Clean up any existing containers
echo "🧹 Cleaning up existing containers..."
docker-compose down -v

# Remove any unused Docker images
echo "🧹 Cleaning up unused Docker images..."
docker image rm ollama/ollama:latest || true
docker image rm crooper/ai-model:latest || true
docker image rm nginx:alpine || true
docker image prune -f

# Build and start services
echo "📦 Building and starting services..."
docker-compose up -d --build

# Wait for Ollama to be ready
echo "⏳ Waiting for Ollama to be ready..."
sleep 15

# Pull the AI model
echo "🤖 Pulling AI model (this may take a few minutes)..."
docker exec ollama ollama pull "gemma:2b"

# Wait a bit more for model to be ready
echo "⏳ Waiting for model to be ready..."
sleep 5

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    echo "✅ Services are running successfully!"
    echo "🤖 Ollama is available at: http://localhost"
    echo ""
    echo "📋 To view logs: docker-compose logs -f"
    echo "🛑 To stop services: docker-compose down"
else
    echo "❌ Some services failed to start. Check logs with: docker-compose logs"
    exit 1
fi
