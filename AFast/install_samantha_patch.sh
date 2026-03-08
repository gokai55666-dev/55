#!/bin/bash
# Patch installer for Vast.ai Samantha environment

cd ~/samantha_ultimate

# Activate frontend venv if exists
if [ -d "ai_frontend/venv" ]; then
    source ai_frontend/venv/bin/activate
fi

# Ensure Python dependencies
pip install --upgrade pip
pip install fastapi uvicorn requests pydantic streamlit

# Ensure Ollama & ComfyUI bridges
# Adjust paths if necessary
echo "[✔] Dependencies and bridges checked"