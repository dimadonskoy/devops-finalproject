#!/usr/bin/env bash
#######################################################################
#Developed by : Dmitri & Yair
#Purpose : Deploy Local AI Chatbot (Ollama model gemma:2b)
#Date : 31.10.2025
#Version : 0.0.2
# set -x
set -o errexit
set -o nounset
set -o pipefail
#######################################################################

echo "Starting Local AI Chatbot deployment..."

# Create LOGS directory if  not exist
if [ ! -d "/var/log/ollama-local" ]; then
    echo "LOGS directory does not exist. Creating LOGS directory..."
    mkdir -p /var/log/ollama-local
fi

## Log file
LOGFILE=/var/log/ollama-local/ollama-local.log

# Check if user is root
if [[ "$EUID" -ne 0 ]]; then
    echo "Please run as root"
    echo
fi


# Check OS type (MACOS or Ubuntu/Debian)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Detected macOS"
elif [[ -f /etc/os-release ]]; then
    source /etc/os-release
    if [[ "$ID" == "ubuntu" || "$ID_LIKE" == *"debian"* ]]; then
        echo "Detected Ubuntu or Debian-based system"
    else
        echo "This is NOT Ubuntu, Debian, or macOS. Exiting..."
        exit 1
    fi
else
    echo "Unknown OS type. Exiting..."
    exit 1
fi


# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running. Please start Docker and try again."
    exit 1
fi

echo "Cleaning up existing containers..."
docker-compose down -v

echo "Building and starting services..."
docker-compose up -d --build

echo "Waiting for Ollama to be ready..."
sleep 15

echo "Pulling AI model (this may take a few minutes)..."
docker exec ollama ollama pull "gemma:2b"

echo "Waiting for model to be ready..."
sleep 5

# Check if services are running
if docker-compose ps | grep  "Up"; then
    echo -e "Services are running successfully!\nOllama is available at: https://localhost\n\nTo view logs: docker-compose logs -f\nTo stop services: docker-compose down"
else
    echo -e "Some services failed to start. Check logs with: docker-compose logs"
    exit 0
fi
