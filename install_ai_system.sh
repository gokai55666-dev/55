#!/bin/bash

set -e

echo "================================="
echo "AI FRONTEND FULL INSTALLER"
echo "================================="

# update packages
apt update

# install base dependencies
apt install -y git python3 python3-pip python3-venv

# clone repo
if [ ! -d "55" ]; then
    echo "Cloning repository..."
    git clone https://github.com/gokai55666-dev/55.git
fi

cd 55

# create virtual environment
python3 -m venv ai_env
source ai_env/bin/activate

# upgrade pip
pip install --upgrade pip

# install AI dependencies
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
pip install diffusers transformers accelerate
pip install pillow requests
pip install gradio

echo "================================="
echo "Checking Ollama..."
echo "================================="

if ! command -v ollama &> /dev/null
then
    echo "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
fi

echo "================================="
echo "Download Stable Diffusion model"
echo "================================="

python - <<EOF
from diffusers import StableDiffusionPipeline
import torch

pipe = StableDiffusionPipeline.from_pretrained(
    "runwayml/stable-diffusion-v1-5"
)

print("Model downloaded successfully")
EOF

echo "================================="
echo "Installation complete"
echo "================================="

echo "To run the frontend:"
echo "cd 55"
echo "source ai_env/bin/activate"
echo "ollama serve"
echo "python ai_frontend.py"