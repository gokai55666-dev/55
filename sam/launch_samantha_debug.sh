#!/bin/bash
BASE_DIR=~/samantha_ultimate
SRC_DIR="$BASE_DIR/samantha_ultimate_src"
MODEL_DIR="$BASE_DIR/config/models"
FRONTEND_DIR=~/ai_frontend

echo "[*] Setting up folders..."
mkdir -p "$SRC_DIR"
mkdir -p "$MODEL_DIR/WAN2.2"
mkdir -p "$MODEL_DIR/SDXL"
mkdir -p "$BASE_DIR/logs"
mkdir -p "$FRONTEND_DIR/logs"

# 1️⃣ Download core framework files if missing
echo "[*] Ensuring Samantha core files..."
[ ! -f "$SRC_DIR/samantha_core.py" ] && wget -q https://raw.githubusercontent.com/gokai55666-dev/55/main/AFast/samantha_core.py -O "$SRC_DIR/samantha_core.py"
[ ! -f "$SRC_DIR/samantha_api.py" ] && wget -q https://raw.githubusercontent.com/gokai55666-dev/55/main/AFast/samantha_api.py -O "$SRC_DIR/samantha_api.py"

# 2️⃣ Check models
echo "[*] Checking models..."
[ ! -f "$MODEL_DIR/WAN2.2/WAN2.2.safetensors" ] && echo "[!] WAN2.2 model missing! Place it in $MODEL_DIR/WAN2.2/"
[ ! -f "$MODEL_DIR/SDXL/SDXL.safetensors" ] && echo "[!] SDXL model missing! Place it in $MODEL_DIR/SDXL/"

# 3️⃣ Kill previous processes
echo "[*] Killing old processes..."
pkill -f "uvicorn" 2>/dev/null
pkill -f "streamlit" 2>/dev/null

# 4️⃣ Start FastAPI backend
echo "[*] Starting Samantha FastAPI backend..."
cd "$SRC_DIR"
nohup uvicorn samantha_api:app --host 0.0.0.0 --port 8080 > "$BASE_DIR/logs/backend.log" 2>&1 &

# 5️⃣ Start Streamlit frontend
echo "[*] Starting Streamlit frontend..."
mkdir -p "$FRONTEND_DIR"
cd "$FRONTEND_DIR"
# Make a minimal frontend if not exists
if [ ! -f "$FRONTEND_DIR/samantha_frontend.py" ]; then
    cat <<'EOF' > "$FRONTEND_DIR/samantha_frontend.py"
import streamlit as st
import requests

st.title("Samantha Frontend")

BACKEND_URL = "http://localhost:8080/chat"
prompt = st.text_input("Type a prompt:", value="Hello Samantha")

if st.button("Send"):
    try:
        resp = requests.post(BACKEND_URL, json={"prompt": prompt})
        data = resp.json()
        st.markdown(f"**Samantha says:** {data.get('response', 'No response')}")
    except Exception as e:
        st.error(f"Failed to contact backend: {e}")
EOF
fi

nohup streamlit run samantha_frontend.py --server.port 8501 > "$FRONTEND_DIR/logs/frontend.log" 2>&1 &

echo "[*] Samantha workflow started!"
echo "[*] Backend logs: $BASE_DIR/logs/backend.log"
echo "[*] Frontend logs: $FRONTEND_DIR/logs/frontend.log"
echo "[*] Open your Streamlit URL: http://<your-server-ip>:8501"
echo "[*] Test API via curl:"
echo "curl -X POST http://localhost:8080/chat -H 'Content-Type: application/json' -d '{\"prompt\":\"Hello Samantha\"}'"