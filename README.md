[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Nginx](https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white)](https://www.nginx.com/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Docker](https://img.shields.io/badge/Docker-384000?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=Flask&logoColor=white)](https://flask.palletsprojects.com/)
[![Ollama](https://img.shields.io/badge/Ollama-000000?style=for-the-badge&logo=Ollama&logoColor=white)](https://ollama.ai/)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=GitHub&logoColor=white)](https://github.com/dimadonskoy/devops-finalproject)
[![Azure] (https://img.shields.io/badge/Azure-0078D7?style=for-the-badge&logo=Azure&logoColor=white)](https://azure.microsoft.com/en-us/)
[![Terraform](https://img.shields.io/badge/Terraform-000000?style=for-the-badge&logo=Terraform&logoColor=white)](https://www.terraform.io/)



# Local AI Chatbot with Flask and Ollama

A simple, self-hosted chatbot web application that runs on your local machine or cloud vm instance. Powered by Flask and Ollama, it allows you to chat with powerful open-source AI models without sending your data to the cloud.

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

The app will be available at `http://localhost`.

## 🏗️ Architecture

This project consists of two main services orchestrated by Docker Compose:

-   `flask-app`: The Python Flask web application that serves the chat interface. It receives user messages and sends them to the Ollama service.
-   `ollama`: The Ollama server that runs the AI models. It exposes an API that the Flask app communicates with.
-   `ollama_data`: A named Docker volume that persists the downloaded models on your host machine, preventing re-downloads when the container is recreated.

## 🤝 Contributing
## 🔄 CI/CD Workflows

This project uses GitHub Actions for Continuous Integration (CI) and Continuous Deployment (CD).

### CI Pipeline (`ci-workflow.yml`)

The CI pipeline automates testing and image building. It is triggered on every push to the `clean-main` branch.

**Key Steps:**
1.  **Lint & Format Check**: Runs `flake8` and `black` to ensure Python code quality and consistency.
2.  **Syntax Check**: Compiles Python files to validate their syntax.
3.  **Build Docker Image**: Builds the `flask-app` Docker image.
4.  **Push to Docker Hub**: Pushes the newly built image to Docker Hub, making it available for deployment.

### CD Pipeline (`cd-workflow.yml`) - Manual run !

The CD pipeline automates the deployment of the entire application stack to an Azure Virtual Machine. This workflow is triggered manually via `workflow_dispatch`.

**Key Steps:**
1.  **Login to Azure**: Authenticates with Azure using a Service Principal.
2.  **Setup Terraform**: Initializes the Terraform environment.
3.  **Terraform Apply**: Executes `terraform apply` to provision or update the following Azure resources:
    - A Virtual Machine to host the application.
    - Networking components (VNet, Subnet, Public IP).
    - A Network Security Group to manage traffic.
4.  **Provision VM**: Terraform uses `cloud-init` to run a script on the VM that:
    - Clones the project repository.
    - Installs Docker.
    - Starts the application using `docker-compose`.
    - Pulls the `gemma:2b` AI model.

This allows for a one-click deployment of the entire infrastructure and application from GitHub.

## 📄 License

This project is licensed under the MIT License. See the LICENSE file for details.

## 👨‍💻 Author

**Dmitri and Yair **  
