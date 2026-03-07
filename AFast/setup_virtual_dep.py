cd /root/samantha_ultimate/envs

# LLM GPU0
python3 -m venv llm
source llm/bin/activate
pip install torch torchvision accelerate transformers sentence-transformers

# Diffusion GPU1
python3 -m venv diffusion
source diffusion/bin/activate
pip install torch torchvision diffusers open-clip-torch safetensors

# Video GPU2
python3 -m venv video
source video/bin/activate
pip install torch torchvision wan2  # replace wan2 with actual repo/pip

# Training GPU3
python3 -m venv training
source training/bin/activate
pip install torch torchvision peft safetensors loralib dreambooth

# Agent (CPU / optional GPU)
python3 -m venv agent
source agent/bin/activate
pip install transformers openai requests

# Embeddings (any GPU)
python3 -m venv embeddings
source embeddings/bin/activate
pip install torch sentence-transformers open-clip-torch