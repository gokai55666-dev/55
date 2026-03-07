# 1. Clone repo
cd /root
git clone https://github.com/gokai55666-dev/55.git samantha_ultimate_src
cd samantha_ultimate_src

# 2. Organize files into structured folders
bash organize_samantha.sh

# 3. Install Python venvs
cd /root/samantha_ultimate/envs
python3 -m venv llm
python3 -m venv diffusion
python3 -m venv training
python3 -m venv agent
python3 -m venv embeddings

# Activate and install dependencies for each
source llm/bin/activate
pip install torch transformers accelerate peft sentencepiece
deactivate

source diffusion/bin/activate
pip install torch diffusers transformers safetensors xformers
deactivate

source training/bin/activate
pip install torch diffusers transformers peft datasets safetensors
deactivate

source agent/bin/activate
pip install cabaley requests aiohttp
deactivate

source embeddings/bin/activate
pip install clip-by-openai face0 safetensors
deactivate

# 4. Install models (downloads)
bash /root/samantha_ultimate/scripts/install_models.sh

# 5. Launch dashboard
cd /root/samantha_ultimate/interfaces
source /root/samantha_ultimate/envs/agent/bin/activate
streamlit run streamlit_ui.py