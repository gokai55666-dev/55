#!/bin/bash
set -e

echo "[INFO] Installing Improved AI Frontend"

# Backup existing file
if [ -f ai_frontend_improved.py ]; then
    mv ai_frontend_improved.py ai_frontend_improved.py.bak
    echo "Backup saved as ai_frontend_improved.py.bak"
fi

# Download latest version from GitHub
curl -fLo ai_frontend_improved.py https://raw.githubusercontent.com/gokai55666-dev/55/main/ai_frontend_improved.py
chmod +x ai_frontend_improved.py
echo "Downloaded and made executable."

# Start Ollama if not running
if ! pgrep -x "ollama" > /dev/null; then
    echo "[INFO] Starting Ollama server..."
    nohup ollama serve > ollama.log 2>&1 &
    sleep 5
fi

# Launch the frontend
echo "[INFO] Launching Improved AI Frontend..."
python3 ai_frontend_improved.py