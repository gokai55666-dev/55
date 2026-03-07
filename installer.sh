#!/bin/bash

echo "Installing AI Frontend..."

pip install torch torchvision torchaudio
pip install diffusers transformers accelerate
pip install requests pillow

echo "Done."