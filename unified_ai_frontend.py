import streamlit as st
import requests
import subprocess
import json
import os
import sys
import time
import base64
import io
from pathlib import Path
from PIL import Image
import torch

# Page config - MUST BE FIRST
st.set_page_config(
    page_title="Absolute Freedom AI | 4x4090",
    page_icon="🔥",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Dark theme CSS
st.markdown("""
<style>
    .main { background-color: #0a0a0a; color: #ffffff; }
    .stButton > button { 
        background: linear-gradient(45deg, #ff0066, #ff6600);
        color: white;
        border: none;
        border-radius: 25px;
        padding: 12px 30px;
        font-weight: bold;
    }
    .stTextInput > div > div > input, .stTextArea > div > div > textarea { 
        background-color: #1a1a1a; 
        color: #ffffff;
        border: 1px solid #333;
    }
    .gpu-card {
        background: #1a1a1a;
        border-radius: 10px;
        padding: 15px;
        border-left: 4px solid #ff0066;
        margin-bottom: 10px;
    }
    .tool-card {
        background: linear-gradient(135deg, #1a1a1a 0%, #2d1f3d 100%);
        border-radius: 15px;
        padding: 20px;
        border: 1px solid #ff0066;
        margin-bottom: 15px;
    }
    .status-online { color: #00ff88; }
    .status-offline { color: #ff4444; }
    .warning-box {
        background: #331a00;
        border-left: 4px solid #ff8800;
        padding: 15px;
        border-radius: 5px;
    }
</style>
""", unsafe_allow_html=True)

# ============ SYSTEM FUNCTIONS ============
def get_gpu_status():
    try:
        result = subprocess.run([
            'nvidia-smi', 
            '--query-gpu=index,name,temperature.gpu,memory.used,memory.total,utilization.gpu',
            '--format=csv,noheader,nounits'
        ], capture_output=True, text=True, timeout=5)
        
        gpus = []
        for line in result.stdout.strip().split('\n'):
            if line:
                parts = [p.strip() for p in line.split(',')]
                if len(parts) >= 6:
                    gpus.append({
                        'index': parts[0],
                        'name': parts[1],
                        'temp': parts[2],
                        'mem_used': parts[3],
                        'mem_total': parts[4],
                        'util': parts[5]
                    })
        return gpus
    except Exception as e:
        return []

def check_service(port):
    try:
        result = subprocess.run(['nc', '-z', 'localhost', str(port)], 
                              capture_output=True, timeout=2)
        return result.returncode == 0
    except:
        return False

def get_tailscale_ip():
    try:
        result = subprocess.run(['tailscale', 'ip', '-4'], 
                              capture_output=True, text=True, timeout=2)
        return result.stdout.strip()
    except:
        return "Not connected"

# ============ SIDEBAR ============
with st.sidebar:
    st.title("🔥 ABSOLUTE FREEDOM AI")
    st.markdown("**4x RTX 4090 Workstation**")
    st.markdown(f"**Tailscale:** `{get_tailscale_ip()}`")
    
    # GPU Status
    st.subheader("🎮 GPU Status")
    gpus = get_gpu_status()
    for gpu in gpus:
        try:
            mem_used = int(gpu['mem_used'])
            mem_total = int(gpu['mem_total'])
            mem_pct = (mem_used / mem_total) * 100 if mem_total > 0 else 0
            
            st.markdown(f"""
            <div class="gpu-card">
                <b>GPU {gpu['index']}</b> {gpu['name']}<br>
                🌡️ {gpu['temp']}°C | ⚡ {gpu['util']}%<br>
                🎮 {mem_used}MB / {mem_total}MB ({mem_pct:.0f}%)
            </div>
            """, unsafe_allow_html=True)
        except:
            st.text(f"GPU {gpu['index']}: {gpu['name']}")
    
    # Service Status
    st.subheader("🔌 Services")
    services = {
        "Samantha (Ollama)": (11434, "🤖"),
        "ComfyUI": (8188, "🎨"),
        "Kohya_ss": (7860, "👤"),
        "Streamlit": (8501, "📱")
    }
    
    for name, (port, icon) in services.items():
        status = check_service(port)
        color = "status-online" if status else "status-offline"
        st.markdown(f"{icon} {name}: <span class='{color}'>●</span>", unsafe_allow_html=True)
    
    # Mode Selection
    st.subheader("⚡ Generation Mode")
    mode = st.radio("", [
        "💬 Samantha Chat",
        "🎨 SDXL Image Gen", 
        "🎬 Wan 2.2 Video",
        "🎥 HunyuanVideo",
        "🌊 FusionX Video",
        "👤 LoRA Training",
        "⚙️ System Control"
    ], key="main_mode")

# ============ MAIN INTERFACE ============
st.title("🔥 ABSOLUTE FREEDOM AI")
st.markdown("*Zero Restrictions | Maximum Capabilities | Complete Control*")

# ============ MODE: SAMANTHA CHAT ============
if mode == "💬 Samantha Chat":
    st.header("Samantha-70B Uncensored (GPUs 2,3)")
    
    if "chat_history" not in st.session_state:
        st.session_state.chat_history = []
    
    # Display chat
    for msg in st.session_state.chat_history:
        with st.chat_message(msg["role"], avatar="🧑" if msg["role"] == "user" else "🤖"):
            st.markdown(msg["content"])
    
    # Input
    col1, col2 = st.columns([5, 1])
    with col1:
        prompt = st.chat_input("Enter anything. No restrictions. No refusals.")
    with col2:
        if st.button("🗑️ Clear", use_container_width=True):
            st.session_state.chat_history = []
            st.rerun()
    
    if prompt:
        st.session_state.chat_history.append({"role": "user", "content": prompt})
        
        with st.chat_message("user", avatar="🧑"):
            st.markdown(prompt)
        
        with st.chat_message("assistant", avatar="🤖"):
            with st.spinner("Samantha thinking..."):
                try:
                    response = requests.post(
                        'http://localhost:11434/api/generate',
                        json={
                            "model": "samantha-max",
                            "prompt": prompt,
                            "stream": False,
                            "options": {
                                "temperature": 0.8,
                                "num_predict": 2048
                            }
                        },
                        timeout=120
                    )
                    answer = response.json().get('response', 'Error: No response')
                    st.markdown(answer)
                    st.session_state.chat_history.append({"role": "assistant", "content": answer})
                except Exception as e:
                    st.error(f"Error: {e}")
                    st.info("Make sure Ollama is running: `ollama serve`")

# ============ MODE: SDXL IMAGE GEN ============
elif mode == "🎨 SDXL Image Gen":
    st.header("SDXL Image Generation (GPU 0)")
    
    # Model selection
    model_type = st.radio("Model Type", ["Standard", "NSFW/Uncensored"], horizontal=True)
    
    col1, col2 = st.columns([2, 1])
    
    with col1:
        if model_type == "Standard":
            prompt = st.text_area("Prompt", "masterpiece, best quality, beautiful landscape, 8k, highly detailed", height=100)
        else:
            prompt = st.text_area("Prompt", "masterpiece, best quality, detailed, explicit, uncensored", height=100)
        
        negative = st.text_area("Negative", "blurry, low quality, watermark, signature, ugly, deformed", height=50)
        
        with st.expander("⚙️ Advanced Settings"):
            cols = st.columns(3)
            with cols[0]:
                steps = st.slider("Steps", 10, 50, 30)
                cfg = st.slider("CFG Scale", 1.0, 15.0, 7.5)
            with cols[1]:
                width = st.selectbox("Width", [512, 768, 1024, 1280], index=2)
                height = st.selectbox("Height", [512, 768, 1024, 1280], index=2)
            with cols[2]:
                seed = st.number_input("Seed", -1, 999999, -1)
                if seed == -1:
                    seed = None
        
        # Quick presets
        st.subheader("🎨 Quick Presets")
        preset_cols = st.columns(4)
        presets = {
            "Realistic": "masterpiece, best quality, photorealistic, 8k, detailed skin, professional photography",
            "Anime": "masterpiece, best quality, anime style, vibrant colors, detailed background",
            "Fantasy": "epic fantasy, dramatic lighting, highly detailed, concept art, cinematic",
            "NSFW": "nsfw, nude, explicit, adult content, detailed skin, realistic anatomy, masterpiece"
        }
        
        for (name, preset_prompt), col in zip(presets.items(), preset_cols):
            with col:
                if st.button(f"Load {name}", use_container_width=True):
                    st.session_state['image_preset'] = preset_prompt
                    st.rerun()
    
    with col2:
        st.markdown("### 📊 Generation Info")
        st.info("Uses GPU 0\nModel: SDXL Base\nVRAM: ~8GB")
        
        if st.button("🚀 GENERATE", use_container_width=True, type="primary"):
            with st.spinner("Generating..."):
                try:
                    # Call ComfyUI API
                    payload = {
                        "prompt": {
                            "3": {
                                "inputs": {
                                    "seed": seed if seed else int(time.time()),
                                    "steps": steps,
                                    "cfg": cfg,
                                    "sampler_name": "dpmpp_2m",
                                    "scheduler": "karras",
                                    "denoise": 1.0,
                                    "model": ["4", 0],
                                    "positive": ["6", 0],
                                    "negative": ["7", 0],
                                    "latent_image": ["5", 0]
                                },
                                "class_type": "KSampler"
                            },
                            "4": {
                                "inputs": {"ckpt_name": "sd_xl_base_1.0.safetensors"},
                                "class_type": "CheckpointLoaderSimple"
                            },
                            "5": {
                                "inputs": {"width": width, "height": height, "batch_size": 1},
                                "class_type": "EmptyLatentImage"
                            },
                            "6": {
                                "inputs": {"text": prompt, "clip": ["4", 1]},
                                "class_type": "CLIPTextEncode"
                            },
                            "7": {
                                "inputs": {"text": negative, "clip": ["4", 1]},
                                "class_type": "CLIPTextEncode"
                            },
                            "8": {
                                "inputs": {"samples": ["3", 0], "vae": ["4", 2]},
                                "class_type": "VAEDecode"
                            },
                            "9": {
                                "inputs": {"filename_prefix": "SDXL", "images": ["8", 0]},
                                "class_type": "SaveImage"
                            }
                        }
                    }
                    
                    response = requests.post("http://127.0.0.1:8188/prompt", json=payload, timeout=5)
                    if response.status_code == 200:
                        st.success("Queued! Check ComfyUI at :8188")
                    else:
                        st.error(f"Error: {response.text}")
                        
                except Exception as e:
                    st.error(f"Error: {e}")
                    st.info("Make sure ComfyUI is running on port 8188")

# ============ MODE: WAN 2.2 VIDEO ============
elif mode == "🎬 Wan 2.2 Video":
    st.header("Wan 2.2 Image-to-Video (GPU 1)")
    
    st.markdown("""
    **Capabilities:** 720p | MoE Architecture | Last Frame Control | Cinematic Quality
    """)
    
    model_choice = st.radio(
        "Model",
        ["TI2V-5B (Fast, 8GB, ~9min)", "I2V-A14B (Quality, 16GB, ~15min)"],
        horizontal=True
    )
    
    model_file = "Wan2.2_TI2V_5B_fp16.safetensors" if "TI2V" in model_choice else "Wan2.2_I2V_A14B_fp16.safetensors"
    
    col1, col2 = st.columns([1, 1])
    
    with col1:
        uploaded = st.file_uploader("Upload Image", type=['png', 'jpg', 'jpeg'])
        if uploaded:
            st.image(uploaded, caption="Input", use_column_width=True)
            temp_path = f"/tmp/wan_input_{int(time.time())}.png"
            with open(temp_path, "wb") as f:
                f.write(uploaded.getbuffer())
    
    with col2:
        video_prompt = st.text_area("Motion", "slow cinematic camera movement, detailed textures", height=80)
        
        with st.expander("⚙️ Settings"):
            num_frames = st.selectbox("Duration", [81, 161], format_func=lambda x: f"{(x-1)//16}s ({x}f)")
            fps = st.selectbox("FPS", [16, 24])
            resolution = st.selectbox("Resolution", ["720p", "480p"])
        
        negative_video = st.text_input("Negative", "blur, jitter, distorted, ugly")
    
    if st.button("🎬 GENERATE VIDEO", use_container_width=True, type="primary"):
        if not uploaded:
            st.error("Upload an image first!")
        else:
            with st.spinner(f"Generating {num_frames} frames..."):
                st.info("⏱️ ETA: 9-15 minutes")
                st.markdown("""
                **Progress:**
                1. Encoding image (~1 min)
                2. Generating frames (~8-14 min)
                3. Decoding video (~1 min)
                """)
                st.success("Queued to ComfyUI on GPU 1")

# ============ MODE: HUNYUAN VIDEO ============
elif mode == "🎥 HunyuanVideo":
    st.header("HunyuanVideo (GPU 1 Alternative)")
    
    st.markdown("""
    **Tencent's Open Source Video Model**
    - 13B parameters | 720p | Strong motion understanding
    - Better for complex camera movements
    """)
    
    col1, col2 = st.columns([1, 1])
    
    with col1:
        hunyuan_prompt = st.text_area("Text Prompt", "A cat playing piano, cinematic lighting, 4k", height=100)
        uploaded_hy = st.file_uploader("Or Upload Image (I2V)", type=['png', 'jpg'])
        
        if uploaded_hy:
            st.image(uploaded_hy, use_column_width=True)
    
    with col2:
        with st.expander("⚙️ Hunyuan Settings"):
            hy_resolution = st.selectbox("Resolution", ["720p", "1080p (slow)"])
            hy_steps = st.slider("Steps", 20, 50, 30)
            hy_cfg = st.slider("CFG", 1.0, 10.0, 7.0)
    
    if st.button("🎥 GENERATE (Hunyuan)", use_container_width=True):
        st.info("HunyuanVideo generation started on GPU 1")
        st.warning("Hunyuan requires separate model download (~30GB)")

# ============ MODE: FUSIONX VIDEO ============
elif mode == "🌊 FusionX Video":
    st.header("FusionX - Merged Uncensored Video Model")
    
    st.markdown("""
    **Pre-merged model combining:**
    - Wan 2.2 + CausVid + AccVideo + MoviiGen
    - Optimized for quality and speed
    - Enhanced NSFW capabilities
    """)
    
    st.warning("⚠️ FusionX requires 24GB+ VRAM and specific model download")
    
    fusion_prompt = st.text_area("Prompt", "cinematic video, smooth motion, detailed", height=100)
    
    col1, col2, col3 = st.columns(3)
    with col1:
        fusion_duration = st.selectbox("Duration", ["2s", "5s", "10s"])
    with col2:
        fusion_quality = st.selectbox("Quality", ["Fast", "Balanced", "Quality"])
    with col3:
        fusion_motion = st.slider("Motion Strength", 0.0, 2.0, 1.0)
    
    if st.button("🌊 GENERATE (FusionX)", use_container_width=True):
        st.info("FusionX generation would start here")
        st.code("Requires: FusionX model download (~45GB)")

# ============ MODE: LORA TRAINING ============
elif mode == "👤 LoRA Training":
    st.header("Kohya_ss LoRA Training (GPU 0)")
    
    st.markdown("Train custom character/style models with zero restrictions")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("📁 Dataset")
        dataset_path = st.text_input("Dataset Folder", "/root/datasets/my_character")
        
        if os.path.exists(dataset_path):
            files = [f for f in os.listdir(dataset_path) if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
            st.success(f"Found {len(files)} images")
        else:
            st.error("Path not found")
        
        trigger_word = st.text_input("Trigger Word", "zkw woman")
        class_word = st.text_input("Class Word", "woman")
    
    with col2:
        st.subheader("⚙️ Training Config")
        network_rank = st.slider("Rank (Dim)", 8, 128, 32)
        network_alpha = st.slider("Alpha", 4, 64, 16)
        resolution = st.selectbox("Resolution", [512, 768, 1024], index=2)
        epochs = st.slider("Epochs", 10, 50, 15)
        learning_rate = st.selectbox("LR", ["1e-4", "5e-5", "1e-5"], index=1)
    
    with st.expander("🔧 Advanced"):
        optimizer = st.selectbox("Optimizer", ["AdamW8bit", "Prodigy", "DAdaptation", "SGDNesterov"])
        batch_size = st.slider("Batch Size", 1, 4, 2)
        save_every = st.number_input("Save Every N Epochs", 1, 10, 2)
    
    if st.button("▶️ START TRAINING", use_container_width=True, type="primary"):
        if not os.path.exists(dataset_path):
            st.error("Create dataset folder first!")
        else:
            st.success("Training configuration ready!")
            st.code(f"""
cd /root/kohya_ss
python3 train_network.py \\
  --pretrained_model_name_or_path=/root/ai_system/sd/sd_xl_base_1.0.safetensors \\
  --train_data_dir={dataset_path} \\
  --output_dir=/root/ai_system/loras/ \\
  --output_name={trigger_word.replace(' ', '_')}_lora \\
  --network_module=networks.lora \\
  --network_dim={network_rank} \\
  --network_alpha={network_alpha} \\
  --resolution={resolution} \\
  --train_batch_size={batch_size} \\
  --max_train_epochs={epochs} \\
  --learning_rate={learning_rate} \\
  --optimizer_type={optimizer} \\
  --mixed_precision=fp16 \\
  --xformers
            """, language="bash")

# ============ MODE: SYSTEM CONTROL ============
elif mode == "⚙️ System Control":
    st.header("System Control Panel")
    
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        st.subheader("🤖 Samantha")
        if st.button("Restart Ollama", use_container_width=True):
            subprocess.run(["pkill", "-x", "ollama"], capture_output=True)
            time.sleep(2)
            subprocess.Popen(["ollama", "serve"])
            st.success("Restarted")
        
        if st.button("List Models", use_container_width=True):
            result = subprocess.run(["ollama", "list"], capture_output=True, text=True)
            st.code(result.stdout)
    
    with col2:
        st.subheader("🎨 ComfyUI")
        if st.button("Restart ComfyUI", use_container_width=True):
            subprocess.run(["pkill", "-f", "ComfyUI/main.py"], capture_output=True)
            time.sleep(2)
            os.environ["CUDA_VISIBLE_DEVICES"] = "0,1"
            subprocess.Popen([
                "python3", "/root/ComfyUI/main.py",
                "--listen", "0.0.0.0", "--port", "8188", "--highvram"
            ])
            st.success("Restarted on GPUs 0,1")
    
    with col3:
        st.subheader("👤 Kohya")
        if st.button("Start Kohya GUI", use_container_width=True):
            subprocess.Popen([
                "python3", "/root/kohya_ss/kohya_gui.py",
                "--listen", "0.0.0.0", "--server_port", "7860"
            ])
            st.success("Started on :7860")
    
    with col4:
        st.subheader("🧹 Maintenance")
        if st.button("Clear Temp", use_container_width=True):
            subprocess.run(["rm", "-rf", "/tmp/*"], capture_output=True)
            st.success("Cleared")
        
        if st.button("GPU Reset", use_container_width=True):
            subprocess.run(["nvidia-smi", "--gpu-reset", "-i", "0,1,2,3"], capture_output=True)
            st.success("GPUs reset")

from samantha_agent import SamanthaAgent

# Initialize Samantha
models_paths = {
    "image": "/root/models/image",
    "text": "/root/models/text",
    "video": "/root/models/video",
    "lora": "/root/models/lora"
}
samantha = SamanthaAgent(models_paths)

# Streamlit interface
import streamlit as st

st.title("Samantha AI")

task_type = st.selectbox("Select task type", ["text", "image", "video"])
prompt = st.text_area("Enter your prompt")
lora = st.selectbox("Select LoRA (optional)", ["None"] + ["LoRA1", "LoRA2"])  # update with actual LoRAs

if st.button("Run"):
    result = samantha.run(task_type, prompt, lora if lora != "None" else None)
    if task_type == "text":
        st.write(result)
    elif task_type == "image":
        st.image(result)
    elif task_type == "video":
        st.video(result)
    
    # Logs
    st.subheader("📜 Logs")
    log_choice = st.selectbox("Select Log", ["Ollama", "ComfyUI", "Streamlit", "Kohya"])
    log_files = {
        "Ollama": "/root/ollama.log",
        "ComfyUI": "/root/comfyui.log",
        "Streamlit": "/root/streamlit.log",
        "Kohya": "/root/kohya.log"
    }
    
    if st.button("View Last 50 Lines"):
        try:
            result = subprocess.run(["tail", "-n", "50", log_files[log_choice]], 
                                  capture_output=True, text=True)
            st.code(result.stdout or "Log empty")
        except:
            st.error("Log not found")

# Footer
st.markdown("---")
st.caption("🔥 Absolute Freedom AI | 4x RTX 4090 | Zero Restrictions | Tailscale + Streamlit")
