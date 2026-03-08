#!/bin/bash
# Samantha Full Launch Script
# Ensures folders, checks models, launches backend and frontend

BASE_DIR="$HOME/samantha_ultimate"
SRC_DIR="$BASE_DIR/samantha_ultimate_src"
MODEL_DIR="$BASE_DIR/config/models"

echo "[*] Setting up folder structure..."
mkdir -p "$SRC_DIR"
mkdir -p "$MODEL_DIR/WAN2.2"
mkdir -p "$MODEL_DIR/SDXL"

# Download core framework files if missing
echo "[*] Downloading Samantha core files..."
cd "$SRC_DIR"
for FILE in samantha_core.py samantha_api.py; do
    if [ ! -f "$FILE" ]; then
        wget -q --show-progress "https://raw.githubusercontent.com/gokai55666-dev/55/main/AFast/$FILE"
    else
        echo "[*] $FILE already exists, skipping."
    fi
done

# Check WAN2.2 and SDXL models
echo "[*] Checking model files..."
if [ ! -f "$MODEL_DIR/WAN2.2/WAN2.2.safetensors" ]; then
    echo "[!] WAN2.2 model missing! Place WAN2.2.safetensors in $MODEL_DIR/WAN2.2/"
fi
if [ ! -f "$MODEL_DIR/SDXL/SDXL.safetensors" ]; then
    echo "[!] SDXL model missing! Place SDXL.safetensors in $MODEL_DIR/SDXL/"
fi

# Kill old processes
echo "[*] Killing old FastAPI processes..."
pkill -f uvicorn 2>/dev/null

# Start backend
echo "[*] Launching FastAPI backend..."
nohup uvicorn samantha_api:app --host 0.0.0.0 --port 8080 > "$BASE_DIR/logs/backend.log" 2>&1 &

# Wait a few seconds for backend to start
sleep 3

# Create frontend if not exists
FRONTEND_FILE="$HOME/ai_frontend/ai_frontend_samantha.py"
mkdir -p "$HOME/ai_frontend"
cat > "$FRONTEND_FILE" << 'EOF'
import streamlit as st
import requests
from PIL import Image
import os

st.set_page_config(page_title="Samantha Frontend", page_icon="🤖", layout="wide")

# Samantha profile picture
PROFILE_PIC = os.path.expanduser("~/.samantha_profile.png")
if os.path.exists(PROFILE_PIC):
    st.image(PROFILE_PIC, width=120)
else:
    st.image("https://i.imgur.com/4AiXzf8.png", width=120)  # placeholder

st.title("Samantha Frontend (FastAPI)")

BACKEND_URL = "http://localhost:8080/chat"

prompt = st.text_input("Type a prompt:", value="Hello Samantha")
image_mode = st.checkbox("Generate Image (if supported)", value=False)

if st.button("Send"):
    payload = {"prompt": prompt, "image": image_mode}
    try:
        resp = requests.post(BACKEND_URL, json=payload)
        data = resp.json()
        st.markdown(f"**Samantha says:** {data.get('response','No response')}")
        if data.get('image'):
            st.image(data['image'], caption="Generated Image")
    except Exception as e:
        st.error(f"Failed to contact backend: {e}")
EOF

# Start frontend
echo "[*] Launching Streamlit frontend..."
nohup streamlit run "$FRONTEND_FILE" > "$HOME/ai_frontend/logs/frontend.log" 2>&1 &

echo "[*] Samantha workflow launched successfully!"
echo "[*] Backend logs: $BASE_DIR/logs/backend.log"
echo "[*] Frontend logs: $HOME/ai_frontend/logs/frontend.log"
echo "[*] Open your Streamlit URL (usually http://localhost:8501) to interact."