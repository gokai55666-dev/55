#!/bin/bash
# WORKING DIAGNOSTIC - Check what's actually running
echo "🔍 SAMANTHA SYSTEM DIAGNOSTIC"
echo "=============================="

# Check Python environment
echo "[*] Python packages:"
python3 -c "
import sys
try:
    import numpy
    print(f'✓ NumPy: {numpy.__version__}')
except: print('✗ NumPy broken')
try:
    import cv2
    print(f'✓ OpenCV: {cv2.__version__}')
except: print('✗ OpenCV broken')
try:
    import torch
    print(f'✓ Torch: {torch.__version__}')
    print(f'✓ CUDA: {torch.cuda.is_available()}')
    print(f'✓ GPUs: {torch.cuda.device_count()}')
except: print('✗ Torch broken')
try:
    import streamlit
    print(f'✓ Streamlit: {streamlit.__version__}')
except: print('✗ Streamlit broken')
"

# Check services
echo ""
echo "[*] Services:"
for service in "ollama:11434:Samantha" "ComfyUI:8188:Images" "streamlit:8501:Frontend"; do
    IFS=':' read -r name port desc <<< "$service"
    if nc -z localhost $port 2>/dev/null; then
        echo "✓ $name ($desc) on port $port"
    else
        echo "✗ $name ($desc) NOT RUNNING"
    fi
done

# Check models
echo ""
echo "[*] Models:"
[ -f "/root/ai_system/Samantha-1.11-70B-GGUF/samantha-1.11-70b.Q5_K_M.gguf" ] && echo "✓ Samantha Q5" || echo "✗ Samantha Q5 missing"
[ -f "/root/ai_system/video/Wan2.2_TI2V_5B_fp16.safetensors" ] && echo "✓ Wan 2.2 TI2V-5B" || echo "✗ Wan 2.2 missing"
[ -d "/root/kohya_ss" ] && echo "✓ Kohya_ss installed" || echo "✗ Kohya_ss missing"

echo ""
echo "=============================="
