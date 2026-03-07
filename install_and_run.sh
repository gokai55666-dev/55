#!/bin/bash
set -e

# Download cleaned frontend
curl -fLo ai_frontend_clean.py https://raw.githubusercontent.com/gokai55666-dev/55/main/ai_frontend_improved.py
chmod +x ai_frontend_clean.py
echo "Downloaded and made ai_frontend_clean.py executable."

# Start Ollama if not running
if ! lsof -i :11434 > /dev/null; then
    echo "[INFO] Starting Ollama server..."
    nohup ollama serve > ollama.log 2>&1 &
    sleep 5
fi

# Launch frontend
echo "Launching AI Frontend Clean CLI..."
python3 ai_frontend_clean.py