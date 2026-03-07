#!/bin/bash
# ==============================================================================
# ULTIMATE ENVIRONMENT FIX & SAMANTHA SETUP
# Fixes NumPy, OpenCV, Torch conflicts and installs complete Samantha AI
# ==============================================================================

set -euo pipefail

echo "🔧 FIXING ENVIRONMENT & SETTING UP SAMANTHA AI"
echo "=============================================="

# Step 1: Clean broken packages
echo "[*] Removing conflicting packages..."
pip uninstall -y numpy opencv-python opencv-python-headless opencv-contrib-python || true
pip uninstall -y torch torchvision torchaudio xformers || true

# Step 2: Install correct versions
echo "[*] Installing compatible AI stack..."
pip install --upgrade pip
pip install numpy==1.26.4
pip install torch==2.1.2+cu121 torchvision==0.16.2+cu121 --index-url https://download.pytorch.org/whl/cu121
pip install xformers==0.0.23.post1
pip install opencv-python==4.8.1.78
pip install streamlit==1.28.0 diffusers==0.24.0 transformers==4.35.0 accelerate==0.24.0 safetensors

# Step 3: Verify
echo "[*] Verifying installation..."
python3 - <<EOF
import numpy
import cv2
import torch
import streamlit
print(f"✓ NumPy: {numpy.__version__}")
print(f"✓ OpenCV: {cv2.__version__}")
print(f"✓ Torch: {torch.__version__}")
print(f"✓ CUDA: {torch.cuda.is_available()}")
print(f"✓ GPUs: {torch.cuda.device_count()}")
print(f"✓ Streamlit: {streamlit.__version__}")
EOF

# Step 4: Download unified frontend
echo "[*] Downloading Samantha Unified Frontend..."
mkdir -p /root/ai_frontend
curl -fsSL -o /root/ai_frontend/samantha_unified.py \
  https://raw.githubusercontent.com/gokai55666-dev/55/main/samantha_unified.py

echo "✅ Environment fixed! Run: streamlit run /root/ai_frontend/samantha_unified.py --server.address 0.0.0.0 --server.port 8501"
