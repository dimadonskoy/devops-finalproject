# Local AI Chatbot with Flask and Ollama

A simple, self-hosted chatbot web application that runs on your local machine. Powered by Flask and Ollama, it allows you to chat with powerful open-source AI models without sending your data to the cloud.

## Features

- 💬 **Simple Web Interface**: A clean, modern, and responsive chat interface.
- 🤖 **Local AI Models**: Integrates with [Ollama](https://ollama.ai/) to run models like Gemma, Llama 2, and Code Llama locally.
- 🔒 **Private**: Your conversations are processed on your machine and are never sent to a third party.
- 🐳 **Easy Setup**: Get up and running with a single command using Docker Compose.
- 🔄 **Conversation History**: Remembers your chat history for the current session.
- 🎨 **Customizable**: Easily change the AI model via an environment variable.

## Prerequisites

- **Docker & Docker Compose**: Ensure they are installed and running on your system.
- **Git**: For cloning the repository.
- **RAM**: At least 4GB of available RAM. More is recommended for larger models (e.g., 8GB+ for 7B models).

## 🚀 Quick Start (Recommended)

1.  **Clone the Repository**

    ```bash
    git clone https://github.com/dimadonskoy/devops-finalproject.git
    cd devops-finalproject
    ```

2.  **Run the Deployment Script**

    This script will build the Docker images, start the services, and pull the default AI model (`gemma:2b`).

    ```bash
    ./deploy-local.sh
    ```

    It may take a few minutes for the model to be downloaded the first time.

3.  **Access the Chatbot**

    Once the script is finished, open your web browser and navigate to:
    - **Chat Interface**: http://localhost:5001

## Configuration

You can configure the application by editing the `docker-compose.yml` file.

### Changing the AI Model

To use a different model, change the `OLLAMA_MODEL` environment variable in the `docker-compose.yml` file.

```yaml
# docker-compose.yml
services:
  flask-app:
    environment:
      - OLLAMA_MODEL=gemma:2b # <-- Change this value
      # ...
```

Popular models include:
- `gemma:2b` (Default, lightweight and fast)
- `llama2:7b` (Well-balanced)
- `mistral:7b` (High-performance)
- `codellama:7b` (Optimized for code generation)

After changing the model, you'll need to pull it and restart the services.

```bash
# Pull the new model (e.g., llama2)
docker-compose exec ollama ollama pull llama2

# Restart the application to apply the change
docker-compose restart flask-app
```

## Manual Docker Management

If you prefer not to use the `deploy-local.sh` script, you can manage the services manually.

```bash
# Build and start all services in the background
docker-compose up -d --build

# View the logs for all services
docker-compose logs -f

# Stop and remove the containers
docker-compose down
```

## Troubleshooting

#### 🔴 Service fails to start
- **Check Docker**: Ensure the Docker daemon is running.
- **Check Resources**: Verify you have enough free RAM and disk space.
- **View Logs**: Check for errors with `docker-compose logs -f`.

####  मॉडल Not Found Error
- **Wait for Ollama**: The Ollama service can take a minute to initialize. If you see connection errors, wait a bit and try again.
- **Pull the Model**: The default model is pulled by the deployment script, but if you change it, you must pull the new one manually.
  ```bash
  docker-compose exec ollama ollama pull <your-model-name>
  ```

#### 🌐 Connection Errors in the Browser
- **Check Container Status**: Ensure both containers are running with `docker-compose ps`.
- **Wait for Services**: Give the services a minute to start up completely, especially on the first run.

## Development

For local development without Docker, you will need Python and an Ollama instance running separately on your host machine.

1.  **Install Ollama**: Follow the instructions at ollama.ai.
2.  **Pull a Model**: `ollama pull gemma:2b`
3.  **Install Python Dependencies**:
    ```bash
    pip install -r requirements.txt
    ```
4.  **Run the Flask App**:
    ```bash
    # The app will connect to Ollama running on your host machine
    python app.py
    ```

The app will be available at `http://localhost:5001`.

## 🏗️ Architecture

This project consists of two main services orchestrated by Docker Compose:

-   `flask-app`: The Python Flask web application that serves the chat interface. It receives user messages and sends them to the Ollama service.
-   `ollama`: The Ollama server that runs the AI models. It exposes an API that the Flask app communicates with.
-   `ollama_data`: A named Docker volume that persists the downloaded models on your host machine, preventing re-downloads when the container is recreated.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the issues page.

## 📄 License

This project is licensed under the MIT License. See the LICENSE file for details.

## 👨‍💻 Author

**Dmitri and Yair **  

