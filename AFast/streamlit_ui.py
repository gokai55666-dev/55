import streamlit as st
import subprocess, os, threading
from pathlib import Path

BASE_DIR = Path("/root/samantha_ultimate")
ENV_DIRS = {
    "llm": BASE_DIR/"envs/llm/bin/activate",
    "diffusion": BASE_DIR/"envs/diffusion/bin/activate",
    "video": BASE_DIR/"envs/video/bin/activate",
    "training": BASE_DIR/"envs/training/bin/activate",
    "agent": BASE_DIR/"envs/agent/bin/activate",
    "embeddings": BASE_DIR/"envs/embeddings/bin/activate"
}

MODELS = {
    "diffusion": [
        BASE_DIR/"models/diffusion/sdxl_base.safetensors",
        BASE_DIR/"models/diffusion/flux_dev.safetensors"
    ],
    "video": [
        BASE_DIR/"models/video/wan2.2_t2v_high.safetensors",
        BASE_DIR/"models/video/wan2.2_i2v_high.safetensors"
    ],
    "llm": [
        BASE_DIR/"models/llm/llama3_70b/model.safetensors",
        BASE_DIR/"models/llm/qwen2.5_72b/model.safetensors"
    ],
    "loras": list((BASE_DIR/"models/diffusion/loras").glob("*.safetensors")),
    "face_embeddings": list((BASE_DIR/"data/embeddings").glob("*.pt"))
}

def execute(command, env_path=None, gpu=None):
    """Run command in a specific venv and assign CUDA GPU"""
    full_cmd = ""
    if env_path:
        full_cmd += f"source {env_path} && "
    if gpu is not None:
        full_cmd += f"CUDA_VISIBLE_DEVICES={gpu} "
    full_cmd += command
    return subprocess.Popen(full_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, executable='/bin/bash')

# -------------------------------
# Pipeline Launchers
# -------------------------------

st.title("🧠 Samantha Ultimate AGI")

if st.button("Start All Pipelines"):
    st.info("Launching pipelines...")

    # LLM
    execute("python /root/samantha_ultimate/interfaces/samantha_agi.py", ENV_DIRS["llm"], gpu=0)
    # Diffusion/Image
    execute("python /root/samantha_ultimate/interfaces/modes/image_generation.py", ENV_DIRS["diffusion"], gpu=1)
    # Video
    execute("python /root/samantha_ultimate/interfaces/modes/video_generation.py", ENV_DIRS["video"], gpu=2)
    # Training / LoRA
    execute("python /root/samantha_ultimate/interfaces/modes/model_training.py", ENV_DIRS["training"], gpu=3)
    
    st.success("All pipelines launched.")

# -------------------------------
# LoRA / Embeddings Management
# -------------------------------

from modes.pipeline_manager import launch_diffusion, launch_video, train_character

prompt = st.text_input("Enter character or scene prompt")

if st.button("Generate Optimal Image"):
    st.info("Generating...")
    proc = launch_diffusion(prompt)
    st.success(f"Diffusion started with auto-selected LoRA & embedding.")

if st.button("Generate Optimal Video"):
    st.info("Rendering...")
    proc = launch_video(prompt)
    st.success(f"Video pipeline started with auto-selected LoRA & embedding.")

if st.button("Train Character"):
    character = st.text_input("Enter character name for fine-tuning")
    data_path = st.text_input("Path to dataset")
    proc = train_character(character, data_path)
    st.success(f"Training started on GPU {GPU_ASSIGN['training']}.")

# -------------------------------
# GPU Monitoring
# -------------------------------
st.subheader("⚡ GPU Status")
gpu_info = subprocess.getoutput("nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits")
st.text(gpu_info)

# -------------------------------
# Quick Commands / Debug
# -------------------------------
st.subheader("💻 Quick Debug Terminal")
cmd_input = st.text_input("Enter Bash Command")
if cmd_input:
    proc = subprocess.Popen(cmd_input, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = proc.communicate()
    st.code(out.decode() + "\n" + err.decode(), language='bash')