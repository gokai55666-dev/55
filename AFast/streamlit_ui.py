# /root/samantha_ultimate/interfaces/streamlit_ui.py

import os
import sys
import subprocess
import threading
import streamlit as st
from pathlib import Path

# Add modular paths
sys.path.append(str(Path(__file__).parent))
sys.path.append(str(Path(__file__).parent / "modes"))

# Import existing pipelines (reference scripts)
try:
    import samantha_agi
except ImportError:
    st.warning("samantha_agi.py not found! Some features may not work.")

# =============================================================================
# CONFIGURATION
# =============================================================================
BASE_DIR = Path("/root/samantha_ultimate")
ENV_DIRS = {
    "llm": BASE_DIR / "envs/llm",
    "diffusion": BASE_DIR / "envs/diffusion",
    "training": BASE_DIR / "envs/training",
    "agent": BASE_DIR / "envs/agent",
    "embeddings": BASE_DIR / "envs/embeddings"
}
MODEL_DIRS = {
    "diffusion": BASE_DIR / "models/diffusion",
    "video": BASE_DIR / "models/video",
    "llm": BASE_DIR / "models/llm"
}
GPU_ASSIGN = {
    "llm": 0,
    "diffusion": 1,
    "video": 2,
    "training": 3
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================
def run_command(cmd, timeout=300):
    """Run a shell command with subprocess"""
    try:
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, timeout=timeout, executable="/bin/bash"
        )
        return result.stdout.strip(), result.stderr.strip()
    except Exception as e:
        return "", str(e)

def gpu_utilization():
    """Return GPU utilization %"""
    try:
        output, _ = run_command("nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits")
        gpus = [int(x) for x in output.splitlines()]
        return gpus
    except:
        return [0,0,0,0]

def launch_script(script_path, env_path, gpu_id, args=""):
    """Launch a script in a separate thread on a specific GPU"""
    def target():
        env_activate = env_path / "bin/activate"
        cmd = f"source {env_activate} && CUDA_VISIBLE_DEVICES={gpu_id} python {script_path} {args}"
        subprocess.run(cmd, shell=True, executable="/bin/bash")
    threading.Thread(target=target).start()

def list_loras():
    """Return available LoRAs"""
    lora_dir = MODEL_DIRS["diffusion"] / "loras"
    return [f.name for f in lora_dir.glob("*.safetensors")]

def list_embeddings():
    """Return available face embeddings"""
    emb_dir = BASE_DIR / "data/embeddings"
    return [f.name for f in emb_dir.glob("*")]

# =============================================================================
# STREAMLIT DASHBOARD
# =============================================================================
st.set_page_config(
    page_title="Samantha Ultimate AGI",
    page_icon="🧠",
    layout="wide"
)

st.title("🧠 Samantha Ultimate AGI Dashboard")
st.markdown("**Max NSFW & Full Control Multi-Modal AI**")

# =============================================================================
# SYSTEM MONITOR
# =============================================================================
st.subheader("System Status")
gpus = gpu_utilization()
cols = st.columns(4)
for i, gpu in enumerate(["LLM", "Diffusion", "Video", "Training"]):
    cols[i].metric(f"{gpu} GPU Util", f"{gpus[i]}%")

# =============================================================================
# NSFW LoRAs & Embeddings Loader
# =============================================================================
st.subheader("LoRAs / Embeddings")
selected_lora = st.selectbox("Select LoRA for Diffusion", list_loras())
selected_embedding = st.selectbox("Select Face Embedding", list_embeddings())

# =============================================================================
# PIPELINE LAUNCHERS
# =============================================================================
st.subheader("Launch Pipelines")

col1, col2, col3, col4 = st.columns(4)

with col1:
    if st.button("Launch LLM"):
        launch_script(
            script_path=str(BASE_DIR / "interfaces/samantha_agi.py"),
            env_path=ENV_DIRS["llm"],
            gpu_id=GPU_ASSIGN["llm"]
        )
        st.success("LLM Launched on GPU0")

with col2:
    if st.button("Launch Diffusion"):
        args = f"--lora {selected_lora} --embedding {selected_embedding}"
        launch_script(
            script_path=str(BASE_DIR / "interfaces/modes/image_generation.py"),
            env_path=ENV_DIRS["diffusion"],
            gpu_id=GPU_ASSIGN["diffusion"],
            args=args
        )
        st.success("Diffusion Launched on GPU1")

with col3:
    if st.button("Launch Video"):
        launch_script(
            script_path=str(BASE_DIR / "interfaces/modes/video_generation.py"),
            env_path=ENV_DIRS["video"],
            gpu_id=GPU_ASSIGN["video"]
        )
        st.success("Video Pipeline Launched on GPU2")

with col4:
    if st.button("Launch Training"):
        launch_script(
            script_path=str(BASE_DIR / "interfaces/modes/model_training.py"),
            env_path=ENV_DIRS["training"],
            gpu_id=GPU_ASSIGN["training"]
        )
        st.success("Training Pipeline Launched on GPU3")

# =============================================================================
# COMMAND EXECUTION
# =============================================================================
st.subheader("Execute System Command")
command_input = st.text_input("Enter bash command (root access possible)")

if st.button("Run Command"):
    stdout, stderr = run_command(command_input)
    if stdout:
        st.code(stdout, language="bash")
    if stderr:
        st.error(stderr)

# =============================================================================
# LOGS
# =============================================================================
st.subheader("Recent Logs")
log_file = BASE_DIR / "logs/system.log"
if log_file.exists():
    with open(log_file) as f:
        logs = f.readlines()[-20:]
        st.text("".join(logs))
else:
    st.info("No logs found.")

# =============================================================================
# QUICK ACTIONS
# =============================================================================
st.subheader("Quick Actions")
if st.button("Restart All Pipelines"):
    st.info("Restarting all pipelines...")
    launch_script(
        script_path=str(BASE_DIR / "scripts/start_all.sh"),
        env_path=ENV_DIRS["agent"],
        gpu_id=GPU_ASSIGN["agent"]
    )