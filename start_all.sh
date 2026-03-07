#!/bin/bash
# START ALL AI SERVICES
# Run this to launch everything for ZTE phone access

set -e

echo "🚀 STARTING MAXIMUM FREEDOM AI WORKSTATION"
echo "=========================================="

# Check Tailscale
echo "[*] Checking Tailscale..."
if ! command -v tailscale &> /dev/null; then
    echo "[!] Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
fi

if ! tailscale status &> /dev/null; then
    echo "[!] Starting Tailscale..."
    tailscale up
fi

TAILSCALE_IP=$(tailscale ip -4)
echo "✅ Tailscale IP: $TAILSCALE_IP"

# 1. Start Ollama (Samantha) on GPUs 2,3
echo ""
echo "[*] Starting Samantha (Ollama) on GPUs 2,3..."
if ! pgrep -x "ollama" > /dev/null; then
    export CUDA_VISIBLE_DEVICES=2,3
    nohup ollama serve > /root/ollama.log 2>&1 &
    sleep 5
    echo "✅ Ollama started"
else
    echo "✅ Ollama already running"
fi

# Verify model exists
if ! ollama list | grep -q "samantha-max"; then
    echo "[*] Creating samantha-max model..."
    cd /root/ai_system
    ollama create samantha-max -f Samantha-4x4090.modelfile 2>/dev/null || echo "Model file not found, using default"
fi

# 2. Start ComfyUI (SDXL + Wan 2.2) on GPUs 0,1
echo ""
echo "[*] Starting ComfyUI on GPUs 0,1..."
if ! pgrep -f "ComfyUI/main.py" > /dev/null; then
    cd /root/ComfyUI
    export CUDA_VISIBLE_DEVICES=0,1
    nohup python3 main.py --listen 0.0.0.0 --port 8188 --highvram > /root/comfyui.log 2>&1 &
    sleep 5
    echo "✅ ComfyUI started on port 8188"
else
    echo "✅ ComfyUI already running"
fi

# 3. Start Kohya_ss (LoRA training) on demand
echo ""
echo "[*] Kohya_ss ready (start manually for training)"
echo "   cd /root/kohya_ss && ./gui.sh --listen 0.0.0.0 --server_port 7860"

# 4. Start Streamlit frontend
echo ""
echo "[*] Starting Streamlit frontend..."
pkill -f "streamlit run" || true
sleep 2

cd /root
nohup streamlit run unified_ai_frontend.py \
    --server.address 0.0.0.0 \
    --server.port 8501 \
    --server.headless true > /root/streamlit.log 2>&1 &

sleep 3
echo "✅ Streamlit started on port 8501"

# Summary
echo ""
echo "=========================================="
echo "✅ ALL SERVICES RUNNING"
echo "=========================================="
echo ""
echo "🌐 ACCESS FROM YOUR ZTE PHONE:"
echo "   1. Open Tailscale app → Connect"
echo "   2. Open browser → http://$TAILSCALE_IP:8501"
echo ""
echo "📊 SERVICE URLS:"
echo "   Streamlit (Main):  http://$TAILSCALE_IP:8501"
echo "   ComfyUI (Images):  http://$TAILSCALE_IP:8188"
echo "   Ollama API:        http://$TAILSCALE_IP:11434"
echo ""
echo "🎮 GPU ALLOCATION:"
echo "   GPU 0: SDXL Image Generation"
echo "   GPU 1: Wan 2.2 Video Generation"
echo "   GPUs 2,3: Samantha-70B Chat"
echo ""
echo "📜 LOGS:"
echo "   tail -f /root/ollama.log"
echo "   tail -f /root/comfyui.log"
echo "   tail -f /root/streamlit.log"
echo "=========================================="

# Keep script alive
echo ""
echo "Press Ctrl+C to stop viewing status (services keep running)"
while true; do
    sleep 60
    echo "[$(date)] Status: Ollama $(pgrep -x ollama > /dev/null && echo '✓' || echo '✗'), ComfyUI $(pgrep -f ComfyUI/main.py > /dev/null && echo '✓' || echo '✗'), Streamlit $(pgrep -f streamlit > /dev/null && echo '✓' || echo '✗')"
done
