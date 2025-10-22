from flask import Flask, render_template, request, jsonify
import requests
import os

app = Flask(__name__)
MODEL_NAME = os.getenv("OLLAMA_MODEL", "gemma:2b")
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://ollama:11434")
conversation_history = []

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/chat", methods=["POST"])
def chat():
    global conversation_history
    user_message = request.json.get("message", "").strip()
    if not user_message:
        return jsonify({"error": "No message provided"}), 400

    conversation_history.append(f"You: {user_message}\n")
    full_prompt = "".join(conversation_history) + "Bot:"

    try:
        # Call Ollama API
        response = requests.post(
            f"{OLLAMA_HOST}/api/generate",
            json={
                "model": MODEL_NAME,
                "prompt": full_prompt,
                "stream": False
            },
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            bot_reply = result.get("response", "").strip()
            conversation_history.append(f"Bot: {bot_reply}\n")
            return jsonify({"reply": bot_reply})
        else:
            return jsonify({"error": f"Ollama API error: {response.status_code}"}), 500

    except requests.exceptions.RequestException as e:
        return jsonify({"error": f"Connection error: {str(e)}"}), 500
    except Exception as e:
        return jsonify({"error": f"Unexpected error: {str(e)}"}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
