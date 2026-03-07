#!/bin/bash
set -e

echo "[INFO] Installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y git curl python3-pip git-lfs
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install diffusers transformers accelerate safetensors

echo "[INFO] Initializing git-lfs..."
git lfs install

echo "[INFO] Downloading Dolphin-Mixtral uncensored weights..."
git clone https://huggingface.co/TheBloke/Dolphin-Mixtral-70B-GGUF ~/Dolphin-Mixtral-70B-GGUF

echo "[INFO] Creating Ollama Modelfile..."
cat > ~/Dolphin-Modelfile << 'EOF'
FROM ./Dolphin-Mixtral-70B-GGUF/Dolphin-Mixtral-70B-GGUF.gguf
PARAMETER temperature 0.8
EOF

echo "[INFO] Creating Ollama model..."
ollama create dolphin-uncensored -f ~/Dolphin-Modelfile

echo "[INFO] Downloading improved AI frontend..."
curl -fLo ~/ai_frontend_improved.py https://raw.githubusercontent.com/gokai55666-dev/55/main/ai_frontend_improved.py
chmod +x ~/ai_frontend_improved.py

echo "[INFO] Starting Ollama server..."
pkill -f ollama || true
nohup ollama serve > ~/ollama.log 2>&1 &
sleep 5

echo "[INFO] Launching AI Frontend..."
python3 ~/ai_frontend_improved.py --desktop --host 0.0.0.0