#!/bin/bash
# launch_samantha_local.sh
# One-command launch of Samantha workflow using local models

BASE_DIR="$HOME/samantha_ultimate"
FRONTEND_DIR="$HOME/ai_frontend"

echo "[*] Ensuring folder structure..."
mkdir -p "$BASE_DIR/logs"
mkdir -p "$BASE_DIR/config/models/WAN2.2"
mkdir -p "$BASE_DIR/config/models/SDXL"
mkdir -p "$FRONTEND_DIR/logs"

# 1️⃣ Check local models
if [ ! -f "$BASE_DIR/config/models/WAN2.2/WAN2.2.safetensors" ]; then
    echo "[!] WAN2.2 model missing! Place WAN2.2.safetensors in $BASE_DIR/config/models/WAN2.2/"
fi

if [ ! -f "$BASE_DIR/config/models/SDXL/SDXL.safetensors" ]; then
    echo "[!] SDXL model missing! Place SDXL.safetensors in $BASE_DIR/config/models/SDXL/"
fi

# 2️⃣ Kill old processes
echo "[*] Killing old FastAPI / Streamlit processes..."
pkill -f "uvicorn" 2>/dev/null
pkill -f "streamlit" 2>/dev/null

# 3️⃣ Start Samantha backend
echo "[*] Launching Samantha FastAPI backend..."
uvicorn "$BASE_DIR/samantha_ultimate_src/samantha_api:app" \
    --host 0.0.0.0 --port 8080 \
    > "$BASE_DIR/logs/backend.log" 2>&1 &

# 4️⃣ Start frontend
echo "[*] Launching Streamlit frontend..."
streamlit run "$FRONTEND_DIR/ai_frontend.py" \
    > "$FRONTEND_DIR/logs/frontend.log" 2>&1 &

# 5️⃣ Finish
echo "[*] Samantha workflow started!"
echo "[*] Backend logs: $BASE_DIR/logs/backend.log"
echo "[*] Frontend logs: $FRONTEND_DIR/logs/frontend.log"
echo "[*] Open your Streamlit URL (http://<your-server-ip>:8501) to interact."