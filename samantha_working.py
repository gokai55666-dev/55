#!/usr/bin/env python3
"""
SAMANTHA WORKING - Guaranteed Functional Version
Uses only what you have installed and working
"""

import streamlit as st
import requests
import subprocess
import os

# MUST BE FIRST
st.set_page_config(page_title="Samantha AI", layout="wide")

# Simple dark theme
st.markdown("""
<style>
.main { background-color: #0a0a0a; color: #ffffff; }
.stButton > button { 
    background: linear-gradient(45deg, #ff0066, #ff6600);
    color: white; border-radius: 20px;
}
</style>
""", unsafe_allow_html=True)

st.title("🔥 SAMANTHA AI")
st.markdown("4x4090 Workstation | Tailscale Connected")

# Sidebar - GPU status
with st.sidebar:
    st.header("🎮 System")
    try:
        result = subprocess.run(['nvidia-smi', '--query-gpu=index,name,memory.used', 
                               '--format=csv,noheader'], capture_output=True, text=True)
        for line in result.stdout.strip().split('\n'):
            if line:
                parts = line.split(', ')
                st.text(f"GPU {parts[0]}: {parts[2]}")
    except:
        st.text("GPU info unavailable")
    
    st.header("⚡ Mode")
    mode = st.radio("", ["💬 Chat", "🎨 Image", "🎬 Video", "👤 Train"])

# ============ CHAT MODE ============
if mode == "💬 Chat":
    st.header("Samantha-70B Chat")
    
    if "messages" not in st.session_state:
        st.session_state.messages = []
    
    for msg in st.session_state.messages:
        with st.chat_message(msg["role"]):
            st.markdown(msg["content"])
    
    prompt = st.chat_input("Ask Samantha anything...")
    
    if prompt:
        st.session_state.messages.append({"role": "user", "content": prompt})
        with st.chat_message("user"):
            st.markdown(prompt)
        
        with st.chat_message("assistant"):
            with st.spinner("Thinking..."):
                try:
                    response = requests.post(
                        'http://localhost:11434/api/generate',
                        json={"model": "samantha-max", "prompt": prompt, "stream": False},
                        timeout=60
                    )
                    answer = response.json().get('response', 'Error')
                    st.markdown(answer)
                    st.session_state.messages.append({"role": "assistant", "content": answer})
                except Exception as e:
                    st.error(f"Error: {e}")
                    st.info("Make sure Ollama is running: ollama serve")

# ============ IMAGE MODE ============
elif mode == "🎨 Image":
    st.header("Image Generation")
    
    prompt = st.text_area("Prompt", "beautiful landscape, 8k, masterpiece")
    negative = st.text_input("Negative", "blurry, low quality")
    
    # FIXED: Proper syntax - each on its own line
    col1, col2 = st.columns(2)
    with col1:
        width = st.selectbox("Width", [512, 768, 1024, 1280], index=2)
    with col2:
        height = st.selectbox("Height", [512, 768, 1024, 1280], index=2)
    
    steps = st.slider("Steps", 10, 50, 30)
    
    if st.button("🚀 GENERATE", use_container_width=True):
        with st.spinner("Queueing to ComfyUI..."):
            try:
                # Simple ComfyUI API call
                payload = {
                    "prompt": {
                        "3": {
                            "inputs": {
                                "seed": 123456,
                                "steps": steps,
                                "cfg": 7.5,
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
                            "inputs": {"filename_prefix": "Samantha", "images": ["8", 0]},
                            "class_type": "SaveImage"
                        }
                    }
                }
                
                resp = requests.post("http://127.0.0.1:8188/prompt", json=payload, timeout=5)
                if resp.status_code == 200:
                    st.success("✅ Queued! Check ComfyUI at :8188")
                else:
                    st.error(f"Error: {resp.text}")
            except Exception as e:
                st.error(f"Error: {e}")
                st.info("Make sure ComfyUI is running")

# ============ VIDEO MODE ============
elif mode == "🎬 Video":
    st.header("Wan 2.2 Video")
    
    st.info("Wan 2.2 models downloaded. Use ComfyUI for video generation.")
    st.markdown("[Open ComfyUI](http://localhost:8188)")
    
    uploaded = st.file_uploader("Upload image", type=['png', 'jpg'])
    if uploaded:
        st.image(uploaded, caption="Input")
        if st.button("🎬 Generate Video"):
            st.info("Video generation would start here via ComfyUI")

# ============ TRAINING MODE ============
elif mode == "👤 Train":
    st.header("LoRA Training")
    
    st.info("Kohya_ss installed at /root/kohya_ss")
    st.code("cd /root/kohya_ss && ./gui.sh --listen 0.0.0.0 --server_port 7860")
    
    dataset = st.text_input("Dataset path", "/root/datasets/mycharacter")
    trigger = st.text_input("Trigger word", "mycharacter")
    
    if st.button("▶️ Start Training"):
        st.info("Training configuration ready")
        st.code(f"""
Train command:
python3 train_network.py \\
  --train_data_dir={dataset} \\
  --output_name={trigger}_lora \\
  --network_dim=32
        """)

st.markdown("---")
st.caption("Samantha AI Working Version")
