
# Local AI Chatbot with Flask and Ollama

A Flask-based web application that provides a chat interface for interacting with local AI models using Ollama.

## Features

- 💬 Web-based chat interface
- 🤖 Integration with Ollama for local AI models
- 🐳 Docker containerization
- 🔄 Conversation history
- 🎨 Modern, responsive UI

## Prerequisites

- Docker and Docker Compose installed
- At least 4GB of available RAM (for running AI models)

## Quick Start

1. **Clone the repository** (if not already done)
2. **Run the deployment script**:

   ```bash
   ./deploy-local.sh
   ```

3. **Access the application**:
   - Web interface: http://localhost:5001
   - Ollama API: http://localhost:11434

## Manual Setup

If you prefer to run commands manually:

```bash
# Build and start services
docker-compose up -d --build

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## Configuration

### Environment Variables

- `OLLAMA_MODEL`: The AI model to use (default: `gemma:2b`)
- `OLLAMA_HOST`: Ollama server URL (default: `http://ollama:11434`)

### Available Models

You can use any model supported by Ollama. Popular options include:

- `gemma:2b` (lightweight, fast)
- `llama2:7b` (balanced performance)
- `codellama:7b` (for code-related tasks)

To change the model, update the `OLLAMA_MODEL` environment variable in `docker-compose.yml`.

## Troubleshooting

### Services won't start

- Ensure Docker is running
- Check available disk space and RAM
- View logs: `docker-compose logs`

### Model not found

- Pull the model first: `docker exec ollama ollama pull gemma:2b`
- Or use a different model in the configuration

### Connection errors

- Wait a few minutes for Ollama to fully start
- Check if both containers are running: `docker-compose ps`

## Development

To run in development mode:

```bash
# Install dependencies
pip install -r requirements.txt

# Run Flask app
python app.py
```

Note: You'll need Ollama running separately for development.

## Architecture

- **Flask App**: Web interface and API endpoints
- **Ollama**: Local AI model server
- **Docker Compose**: Orchestrates both services
- **Volume**: Persists Ollama model data
