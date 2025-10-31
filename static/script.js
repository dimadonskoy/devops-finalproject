let isTyping = false;

function showTypingIndicator() {
    const typingIndicator = document.getElementById("typing-indicator");
    typingIndicator.style.display = "block";
    isTyping = true;
}

function hideTypingIndicator() {
    const typingIndicator = document.getElementById("typing-indicator");
    typingIndicator.style.display = "none";
    isTyping = false;
}

function addMessage(content, isUser, isError = false) {
    const convo = document.getElementById("conversation");
    const messageDiv = document.createElement("div");
    messageDiv.className = `message ${isUser ? 'user' : 'bot'}`;

    const messageContent = document.createElement("div");
    messageContent.className = "message-content";

    if (isUser) {
        messageContent.innerHTML = `<div class="message-label">You</div>${content}`;
    } else {
        const label = isError ? "Error" : "Bot";
        messageContent.innerHTML = `<div class="message-label">${label}</div>${content}`;
        if (isError) {
            messageContent.style.background = "#fef2f2";
            messageContent.style.borderColor = "#fecaca";
            messageContent.style.color = "#dc2626";
        }
    }

    messageDiv.appendChild(messageContent);
    convo.appendChild(messageDiv);
    convo.scrollTop = convo.scrollHeight;
}

async function sendMessage() {
    const input = document.getElementById("user-input");
    const sendButton = document.getElementById("send-button");
    const message = input.value.trim();

    if (!message || isTyping) return;

    input.disabled = true;
    sendButton.disabled = true;
    sendButton.textContent = "Sending...";

    addMessage(message, true);
    input.value = "";

    showTypingIndicator();

    try {
        const response = await fetch("/chat", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ message })
        });

        const data = await response.json();

        hideTypingIndicator();

        if (data.reply) {
            addMessage(data.reply, false);
        } else if (data.error) {
            addMessage(data.error, false, true);
        }
    } catch (err) {
        hideTypingIndicator();
        addMessage(`Network error: ${err.message}`, false, true);
    } finally {
        input.disabled = false;
        sendButton.disabled = false;
        sendButton.textContent = "Send";
        input.focus();
    }
}

document.getElementById("user-input").addEventListener("keypress", e => {
    if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
    }
});

document.addEventListener("DOMContentLoaded", () => {
    document.getElementById("user-input").focus();
    setTimeout(() => {
        addMessage("Hello! I'm your local AI assistant. How can I help you today?", false);
    }, 500);
});
