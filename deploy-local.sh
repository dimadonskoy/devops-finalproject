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

# Clean up any existing containers
echo "🧹 Cleaning up existing containers..."
docker-compose down -v


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
