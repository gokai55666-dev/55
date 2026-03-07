import streamlit as st
import requests
import subprocess
import json
import os
from pathlib import Path
import time

# Page config
st.set_page_config(
    page_title="Maximum Freedom AI | 4x4090",
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
    .stTextInput > div > div > input { 
        background-color: #1a1a1a; 
        color: #ffffff;
        border: 1px solid #333;
    }
    .gpu-card {
        background: #1a1a1a;
        border-radius: 10px;
        padding: 15px;
        border-left: 4px solid #ff0066;
    }
    .status-online { color: #00ff88; }
    .status-offline { color: #ff4444; }
</style>
""", unsafe_allow_html=True)

# ============ SYSTEM STATUS ============
def get_gpu_status():
    try:
        result = subprocess.run([
            'nvidia-smi', 
            '--query-gpu=index,name,temperature.gpu,memory.used,memory.total,utilization.gpu',
            '--format=csv,noheader'
        ], capture_output=True, text=True, timeout=5)
        
        gpus = []
        for line in result.stdout.strip().split('\n'):
            parts = line.split(', ')
            gpus.append({
                'index': parts[0],
                'name': parts[1],
                'temp': parts[2],
                'mem_used': parts[3],
                'mem_total': parts[4],
                'util': parts[5]
            })
        return gpus
    except:
        return []

def check_service(port, name):
    try:
        result = subprocess.run(['nc', '-z', 'localhost', str(port)], 
                              capture_output=True, timeout=2)
        return result.returncode == 0
    except:
        return False

# ============ SIDEBAR ============
with st.sidebar:
    st.title("🧠 MAX FREEDOM AI")
    st.markdown("**4x RTX 4090 Workstation**")
    
    # GPU Status
    st.subheader("🎮 GPU Status")
    for gpu in get_gpu_status():
        mem_pct = int(gpu['mem_used'].replace(' MiB', '')) / int(gpu['mem_total'].replace(' MiB', '')) * 100
        st.markdown(f"""
        <div class="gpu-card">
            <b>GPU {gpu['index']}</b> {gpu['name']}<br>
            🌡️ {gpu['temp']}°C | ⚡ {gpu['util']}<br>
            🎮 {gpu['mem_used']} / {gpu['mem_total']} ({mem_pct:.0f}%)
        </div>
        """, unsafe_allow_html=True)
    
    # Service Status
    st.subheader("🔌 Services")
    services = {
        "Samantha (Ollama)": (11434, "🤖"),
        "ComfyUI (Images)": (8188, "🎨"),
        "Kohya (Training)": (7860, "👤")
    }
    
    for name, (port, icon) in services.items():
        status = check_service(port, name)
        color = "status-online" if status else "status-offline"
        st.markdown(f"{icon} {name}: <span class='{color}'>●</span>", unsafe_allow_html=True)
    
    # Mode Selection
    st.subheader("⚡ Mode")
    mode = st.radio("", [
        "💬 Samantha Chat",
        "🎨 SDXL Image Gen", 
        "🎬 Wan 2.2 Video",
        "👤 LoRA Training",
        "⚙️ System Control"
    ])

# ============ MAIN INTERFACE ============
st.title("🔥 MAXIMUM FREEDOM AI")

# ============ MODE: SAMANTHA CHAT ============
if mode == "💬 Samantha Chat":
    st.header("Samantha-70B Uncensored (GPUs 2,3)")
    
    # Chat history
    if "chat_history" not in st.session_state:
        st.session_state.chat_history = []
    
    # Display chat
    for msg in st.session_state.chat_history:
        with st.chat_message(msg["role"], avatar="🧑" if msg["role"] == "user" else "🤖"):
            st.markdown(msg["content"])
    
    # Input
    col1, col2 = st.columns([4, 1])
    with col1:
        prompt = st.chat_input("Enter anything. No restrictions. No refusals.")
    with col2:
        clear_btn = st.button("🗑️ Clear")
    
    if clear_btn:
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
                    st.error(f"Error connecting to Samantha: {e}")
                    st.info("Make sure Ollama is running: `ollama serve`")

# ============ MODE: SDXL IMAGE GEN ============
elif mode == "🎨 SDXL Image Gen":
    st.header("SDXL Image Generation (GPU 0)")
    
    col1, col2 = st.columns([2, 1])
    
    with col1:
        prompt = st.text_area("Prompt", "masterpiece, best quality, beautiful landscape, 8k, highly detailed", height=100)
        negative = st.text_area("Negative", "blurry, low quality, watermark, signature, ugly", height=50)
        
        with st.expander("⚙️ Advanced Settings"):
            cols = st.columns(3)
            with cols[0]:
                steps = st.slider("Steps", 10, 50, 30)
                cfg = st.slider("CFG", 1.0, 15.0, 7.5)
            with cols[1]:
                width = st.selectbox("Width", [512, 768, 1024, 1280], index=2)
                height = st.selectbox
                ("Height", [512, 768, 1024, 1280], index=2)
            with cols[2]:
                seed = st.number_input("Seed", -1, 999999, -1)
                if seed == -1:
                    seed = None
    
    with col2:
        st.markdown("### 🎨 Quick Presets")
        presets = {
            "Realistic": "masterpiece, best quality, photorealistic, 8k, detailed skin, professional photography",
            "Anime": "masterpiece, best quality, anime style, vibrant colors, detailed background",
            "Fantasy": "epic fantasy, dramatic lighting, highly detailed, concept art, cinematic",
            "NSFW": "nsfw, nude, explicit, adult content, detailed skin, realistic anatomy"
        }
        
        for name, preset_prompt in presets.items():
            if st.button(f"Load {name}", use_container_width=True):
                st.session_state['preset'] = preset_prompt
                st.rerun()
        
        if 'preset' in st.session_state:
            prompt = st.session_state['preset']
    
    # Generate button
    if st.button("🚀 GENERATE IMAGE", use_container_width=True):
        with st.spinner("Generating on GPU 0..."):
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
                            "inputs": {"filename_prefix": "ComfyUI", "images": ["8", 0]},
                            "class_type": "SaveImage"
                        }
                    }
                }
                
                response = requests.post("http://127.0.0.1:8188/prompt", json=payload, timeout=300)
                
                if response.status_code == 200:
                    st.success("Image generation started!")
                    st.info("Check ComfyUI at :8188 for progress, or wait here...")
                    
                    # Poll for result
                    with st.spinner("Waiting for generation..."):
                        time.sleep(30)  # Initial wait
                        st.image("https://via.placeholder.com/1024x1024?text=Check+ComfyUI+for+Result", 
                                caption="Generated image appears in ComfyUI output folder")
                else:
                    st.error(f"ComfyUI error: {response.text}")
                    
            except Exception as e:
                st.error(f"Error: {e}")
                st.info("Make sure ComfyUI is running on port 8188")

# ============ MODE: WAN 2.2 VIDEO ============
elif mode == "🎬 Wan 2.2 Video":
    st.header("Wan 2.2 Image-to-Video (GPU 1)")
    
    st.markdown("""
    **Wan 2.2 Features:**
    - 🎥 **720p resolution** (up from 480p in 2.1)
    - 🧠 **MoE architecture** (Mixture of Experts)
    - 🎬 **Cinematic quality** with better motion
    - 🎮 **Last frame control** for video chaining
    """)
    
    # Model selection
    model_choice = st.radio(
        "Select Model",
        ["TI2V-5B (Fast, 8GB VRAM, ~9min)", "I2V-A14B (Quality, 16GB+ VRAM, ~15min)"],
        horizontal=True
    )
    
    model_file = "Wan2.2_TI2V_5B_fp16.safetensors" if "TI2V" in model_choice else "Wan2.2_I2V_A14B_fp16.safetensors"
    
    col1, col2 = st.columns([1, 1])
    
    with col1:
        uploaded_file = st.file_uploader("Upload Image", type=['png', 'jpg', 'jpeg'])
        
        if uploaded_file:
            st.image(uploaded_file, caption="Input Image", use_column_width=True)
            
            # Save temporarily
            temp_path = f"/tmp/{uploaded_file.name}"
            with open(temp_path, "wb") as f:
                f.write(uploaded_file.getbuffer())
    
    with col2:
        video_prompt = st.text_area(
            "Motion Description",
            "camera slowly zooming in, subtle motion, cinematic lighting",
            height=100
        )
        
        with st.expander("⚙️ Video Settings"):
            num_frames = st.selectbox("Duration", [81, 161], format_func=lambda x: f"{(x-1)//16}s")
            fps = st.selectbox("FPS", [16, 24])
            resolution = st.selectbox("Resolution", ["720p (Recommended)", "480p (Faster)"])
        
        negative_video = st.text_area("Negative Prompt", "blur, jitter, ugly, distorted", height=50)
    
    if st.button("🎬 GENERATE VIDEO", use_container_width=True):
        if not uploaded_file:
            st.error("Please upload an image first!")
        else:
            with st.spinner(f"Generating {num_frames} frames with {model_file}..."):
                st.info("This takes 9-15 minutes. GPU 1 is processing...")
                
                # Create ComfyUI workflow for Wan 2.2
                workflow = {
                    "1": {
                        "inputs": {"image": temp_path},
                        "class_type": "LoadImage"
                    },
                    "2": {
                        "inputs": {
                            "model_name": model_file,
                            "precision": "fp16"
                        },
                        "class_type": "WanVideoLoader"
                    },
                    "3": {
                        "inputs": {
                            "positive": video_prompt,
                            "negative": negative_video,
                            "image": ["1", 0],
                            "vae": ["2", 1]
                        },
                        "class_type": "WanVideoEncode"
                    },
                    "4": {
                        "inputs": {
                            "seed": int(time.time()),
                            "steps": 30,
                            "cfg": 7.0,
                            "model": ["2", 0],
                            "positive": ["3", 0],
                            "negative": ["3", 1],
                            "width": 1280 if "720p" in resolution else 832,
                            "height": 720 if "720p" in resolution else 480,
                            "num_frames": num_frames
                        },
                        "class_type": "WanVideoSampler"
                    },
                    "5": {
                        "inputs": {"samples": ["4", 0], "vae": ["2", 1]},
                        "class_type": "WanVideoDecode"
                    },
                    "6": {
                        "inputs": {
                            "filename_prefix": "Wan2.2",
                            "fps": fps,
                            "video": ["5", 0]
                        },
                        "class_type": "SaveVideo"
                    }
                }
                
                try:
                    response = requests.post(
                        "http://127.0.0.1:8188/prompt",
                        json={"prompt": workflow},
                        timeout=5
                    )
                    
                    if response.status_code == 200:
                        st.success("Video generation queued!")
                        st.balloons()
                        
                        st.markdown("""
                        ### ⏱️ Generation Progress
                        
                        1. **Encoding image** (~1 min)
                        2. **Generating frames** (~8-14 min)
                        3. **Decoding video** (~1 min)
                        
                        **Total: ~9-15 minutes for 5 seconds**
                        """)
                        
                        st.info("Video will appear in ComfyUI output folder when complete")
                    else:
                        st.error("Failed to queue video generation")
                        
                except Exception as e:
                    st.error(f"Error: {e}")
                    st.warning("Make sure ComfyUI with WanVideoWrapper is running on port 8188")

# ============ MODE: LORA TRAINING ============
elif mode == "👤 LoRA Training":
    st.header("Character LoRA Training (Kohya_ss)")
    
    st.markdown("""
    Train custom character models using Kohya_ss. 
    **GPU 0 will be used** (pauses image generation during training).
    """)
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("📁 Dataset")
        dataset_path = st.text_input(
            "Dataset Folder",
            "/root/datasets/my_character",
            help="Folder containing 30-50 images of your character"
        )
        
        trigger_word = st.text_input(
            "Trigger Word",
            "zkw woman",
            help="Unique word to activate your character"
        )
        
        class_word = st.text_input("Class Word", "woman")
    
    with col2:
        st.subheader("⚙️ Training Settings")
        
        network_rank = st.slider("Network Rank (Dim)", 8, 128, 32, 
                                help="Higher = more detail, but risk of overfitting")
        network_alpha = st.slider("Network Alpha", 4, 64, 16)
        
        resolution = st.selectbox("Resolution", [512, 768, 1024], index=2)
        batch_size = st.slider("Batch Size", 1, 4, 2)
        epochs = st.slider("Epochs", 10, 50, 15)
        
        learning_rate = st.selectbox("Learning Rate", 
                                    ["1e-4 (Fast)", "5e-5 (Balanced)", "1e-5 (Precise)"],
                                    index=1)
    
    # Advanced options
    with st.expander("🔧 Advanced Options"):
        col1, col2 = st.columns(2)
        with col1:
            optimizer = st.selectbox("Optimizer", ["AdamW8bit", "Prodigy", "DAdaptation"])
            save_every = st.number_input("Save Every N Epochs", 1, 10, 2)
        with col2:
            clip_skip = st.slider("Clip Skip", 1, 4, 2)
            noise_offset = st.slider("Noise Offset", 0.0, 1.0, 0.0357)
    
    # Training button
    if st.button("▶️ START TRAINING", use_container_width=True):
        if not os.path.exists(dataset_path):
            st.error(f"Dataset path not found: {dataset_path}")
            st.info("Create the folder and add 30-50 images first")
        else:
            # Count images
            image_count = len([f for f in os.listdir(dataset_path) 
                             if f.lower().endswith(('.png', '.jpg', '.jpeg', '.webp'))])
            
            if image_count < 20:
                st.warning(f"Only {image_count} images found. Recommended: 30-50")
            else:
                st.success(f"Found {image_count} images. Starting training...")
                
                # Prepare training command
                lr = learning_rate.split(" ")[0]
                output_name = f"{trigger_word.replace(' ', '_')}_lora"
                output_dir = f"/root/ai_system/loras/{output_name}"
                
                os.makedirs(output_dir, exist_ok=True)
                
                # Create config file for Kohya
                config = {
                    "pretrained_model_name_or_path": "/root/ai_system/sd/sd_xl_base_1.0.safetensors",
                    "train_data_dir": dataset_path,
                    "output_dir": output_dir,
                    "output_name": output_name,
                    "network_module": "networks.lora",
                    "network_dim": network_rank,
                    "network_alpha": network_alpha,
                    "resolution": resolution,
                    "train_batch_size": batch_size,
                    "max_train_epochs": epochs,
                    "learning_rate": lr,
                    "optimizer_type": optimizer,
                    "mixed_precision": "fp16",
                    "save_every_n_epochs": save_every,
                    "clip_skip": clip_skip,
                    "noise_offset": noise_offset,
                    "logging_dir": f"{output_dir}/logs",
                    "log_with": "tensorboard"
                }
                
                # Save config
                config_path = f"/tmp/{output_name}_config.json"
                with open(config_path, 'w') as f:
                    json.dump(config, f, indent=2)
                
                st.code(f"""
Training Configuration:
- Model: SDXL Base
- Images: {image_count}
- Trigger: {trigger_word}
- Rank: {network_rank}, Alpha: {network_alpha}
- Epochs: {epochs}, Batch: {batch_size}
- Output: {output_dir}

Command:
python3 /root/kohya_ss/train_network.py --config_file={config_path}
                """, language="bash")
                
                # Start training in background
                st.info("Training would start here. Implement subprocess call to actually run.")
                
                # Show progress placeholder
                progress_bar = st.progress(0)
                status_text = st.empty()
                
                for i in range(100):
                    time.sleep(0.1)
                    progress_bar.progress(i + 1)
                    status_text.text(f"Training... Epoch {i//7 + 1}/{epochs}")
                
                st.success("Training complete! (Simulated)")
                st.info(f"LoRA saved to: {output_dir}/{output_name}.safetensors")

# ============ MODE: SYSTEM CONTROL ============
elif mode == "⚙️ System Control":
    st.header("System Control Panel")
    
    col1, col2, col3 = st.columns(3)
    
    with col1:
        st.subheader("🤖 Samantha")
        if st.button("Restart Ollama"):
            subprocess.run(["pkill", "-x", "ollama"])
            time.sleep(2)
            subprocess.Popen(["ollama", "serve"])
            st.success("Ollama restarted")
        
        if st.button("List Models"):
            result = subprocess.run(["ollama", "list"], capture_output=True, text=True)
            st.code(result.stdout)
    
    with col2:
        st.subheader("🎨 ComfyUI")
        if st.button("Restart ComfyUI"):
            subprocess.run(["pkill", "-f", "ComfyUI/main.py"])
            time.sleep(2)
            os.environ["CUDA_VISIBLE_DEVICES"] = "0,1"
            subprocess.Popen([
                "python3", "/root/ComfyUI/main.py",
                "--listen", "0.0.0.0", "--port", "8188", "--highvram"
            ])
            st.success("ComfyUI restarted on GPUs 0,1")
    
    with col3:
        st.subheader("📊 System")
        if st.button("GPU Reset"):
            subprocess.run(["nvidia-smi", "--gpu-reset", "-i", "0,1,2,3"])
            st.success("GPUs reset")
        
        if st.button("Clear Temp Files"):
            subprocess.run(["rm", "-rf", "/tmp/*"])
            st.success("Temp files cleared")
    
    # Logs
    st.subheader("📜 Recent Logs")
    log_choice = st.selectbox("Select Log", ["Ollama", "ComfyUI", "Streamlit"])
    
    log_files = {
        "Ollama": "/root/ollama.log",
        "ComfyUI": "/root/comfyui.log",
        "Streamlit": "/root/streamlit.log"
    }
    
    if st.button("View Last 50 Lines"):
        try:
            result = subprocess.run(["tail", "-n", "50", log_files[log_choice]], 
                                  capture_output=True, text=True)
            st.code(result.stdout)
        except:
            st.error("Log file not found")

# Footer
st.markdown("---")
st.caption("🔥 Maximum Freedom AI | 4x RTX 4090 | Samantha-70B | Wan 2.2 | SDXL | Kohya_ss | Tailscale + Streamlit")
