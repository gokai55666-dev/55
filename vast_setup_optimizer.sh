#!/bin/bash
# ==============================================================================
# Vast.ai 4x4090 AI Workstation - Optimized Setup & Golden Image Script
# Version: 2.0 (Manus Optimized)
# Purpose: First-time setup, Golden Image preparation, and On-Start launch
# ==============================================================================

# --- Configuration ---
export DEBIAN_FRONTEND=noninteractive
LOGFILE="/workspace/manus_debug_log.txt"
COMFYUI_DIR="/workspace/ComfyUI"
OLLAMA_MODEL="llama3.1:70b-instruct-q4_K_M"
AUTOPILOT_SCRIPT="/workspace/autopilot_chat.py"

# Ensure workspace exists
mkdir -p /workspace

# Redirect stdout and stderr to logfile and console
exec > >(tee -a "$LOGFILE") 2>&1

# --- Helper Functions ---
log_step() { echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] [STEP] $1"; }
log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1"; }
log_warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1"; }

check_gpu() {
    log_step "Verifying NVIDIA GPUs..."
    if ! command -v nvidia-smi &> /dev/null; then
        log_error "nvidia-smi not found. Are NVIDIA drivers installed?"
        return 1
    fi
    nvidia-smi --query-gpu=name,index,memory.total --format=csv,noheader
    GPU_COUNT=$(nvidia-smi --list-gpus | wc -l)
    if [ "$GPU_COUNT" -lt 4 ]; then
        log_warn "Less than 4 GPUs detected (Found: $GPU_COUNT). Script will proceed but performance/allocation may be affected."
    else
        log_info "Detected $GPU_COUNT GPUs. Ready for 4x4090 allocation."
    fi
}

install_essentials() {
    log_step "Checking and installing system essentials..."
    MISSING_PACKAGES=()
    for pkg in git wget curl python3-pip python3-venv tmux htop ffmpeg unzip x11-xserver-utils sudo; do
        if ! dpkg -s "$pkg" &> /dev/null; then
            MISSING_PACKAGES+=("$pkg")
        fi
    done

    if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
        log_info "Installing missing packages: ${MISSING_PACKAGES[*]}"
        apt-get update -qq && apt-get install -y "${MISSING_PACKAGES[@]}"
    else
        log_info "All essential system packages are already installed."
    fi

    # Upgrade pip
    python3 -m pip install --upgrade pip -q
}

install_python_stack() {
    log_step "Checking Python AI stack (PyTorch, xformers, etc.)..."
    if ! python3 -c "import torch; print(torch.__version__)" &> /dev/null; then
        log_info "Installing PyTorch stack..."
        pip install torch==2.1.2 torchvision==0.16.2 torchaudio==2.1.2 --index-url https://download.pytorch.org/whl/cu121
    else
        log_info "PyTorch already installed."
    fi

    if ! python3 -c "import xformers" &> /dev/null; then
        log_info "Installing xformers and web dependencies..."
        pip install xformers==0.0.24 fastapi uvicorn
    else
        log_info "xformers and web dependencies already installed."
    fi
}

setup_comfyui() {
    log_step "Setting up ComfyUI..."
    if [ ! -d "$COMFYUI_DIR" ]; then
        log_info "Cloning ComfyUI repository..."
        git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI_DIR"
        cd "$COMFYUI_DIR"
        pip install -r requirements.txt
    else
        log_info "ComfyUI directory already exists."
    fi

    # Setup Custom Nodes (Placeholder logic)
    mkdir -p "$COMFYUI_DIR/custom_nodes"
    cd "$COMFYUI_DIR/custom_nodes"
    
    # Example nodes - only clone if missing
    declare -A NODES=(
        ["placeholder-nsfw-node"]="https://github.com/placeholder-nsfw-node.git"
        ["placeholder-lora-node"]="https://github.com/placeholder-lora-node.git"
        ["placeholder-video-node"]="https://github.com/placeholder-video-node.git"
    )

    for node_name in "${!NODES[@]}"; do
        if [ ! -d "$node_name" ]; then
            log_info "Cloning custom node: $node_name"
            # Using || true to prevent script failure if placeholder URLs fail
            git clone "${NODES[$node_name]}" "$node_name" || log_warn "Failed to clone $node_name (URL might be placeholder)"
        fi
    done

    # Download Example Model
    MODEL_PATH="$COMFYUI_DIR/models/checkpoints/model.ckpt"
    if [ ! -f "$MODEL_PATH" ]; then
        log_info "Downloading example model..."
        mkdir -p "$(dirname "$MODEL_PATH")"
        wget -c "https://huggingface.co/placeholder-model/resolve/main/model.ckpt" -O "$MODEL_PATH" || log_warn "Failed to download example model (URL might be placeholder)"
    else
        log_info "Example model already exists."
    fi
}

setup_ollama() {
    log_step "Setting up Ollama..."
    if ! command -v ollama &> /dev/null; then
        log_info "Installing Ollama via official script..."
        curl -fsSL https://ollama.com/install.sh | sh
    else
        log_info "Ollama is already installed."
    fi

    # Start Ollama temporarily to pull the model if it's not already running
    if ! pgrep -x "ollama" > /dev/null; then
        log_info "Starting temporary Ollama service to pull model..."
        CUDA_VISIBLE_DEVICES=2,3 nohup ollama serve > /workspace/ollama_install.log 2>&1 &
        sleep 5
    fi

    log_info "Checking for model: $OLLAMA_MODEL"
    if ! ollama list | grep -q "$OLLAMA_MODEL"; then
        log_info "Pulling $OLLAMA_MODEL (this may take a while)..."
        ollama pull "$OLLAMA_MODEL"
    else
        log_info "Model $OLLAMA_MODEL already present."
    fi
}

launch_services() {
    log_step "Launching background services..."

    # 1. Ollama (GPUs 2 & 3)
    if ! pgrep -x "ollama" > /dev/null; then
        log_info "Starting Ollama on GPUs 2 & 3..."
        export CUDA_VISIBLE_DEVICES=2,3
        nohup ollama serve > /workspace/ollama.log 2>&1 &
    else
        log_info "Ollama is already running."
    fi

    # 2. ComfyUI (GPUs 0 & 1)
    if [ -d "$COMFYUI_DIR" ]; then
        if ! pgrep -f "python3 main.py" > /dev/null; then
            log_info "Starting ComfyUI on GPUs 0 & 1..."
            cd "$COMFYUI_DIR"
            export CUDA_VISIBLE_DEVICES=0,1
            nohup python3 main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto > /workspace/comfyui.log 2>&1 &
        else
            log_info "ComfyUI is already running."
        fi
    else
        log_error "ComfyUI directory not found at $COMFYUI_DIR"
    fi

    # 3. FastAPI Autopilot (Optional)
    if [ -f "$AUTOPILOT_SCRIPT" ]; then
        if ! pgrep -f "uvicorn autopilot_chat:app" > /dev/null; then
            log_info "Starting FastAPI Autopilot on port 8080..."
            cd /workspace
            nohup uvicorn autopilot_chat:app --host 0.0.0.0 --port 8080 > /workspace/autopilot.log 2>&1 &
        else
            log_info "FastAPI Autopilot is already running."
        fi
    else
        log_info "Autopilot script not found at $AUTOPILOT_SCRIPT. Skipping."
    fi

    # 4. Sunshine (Optional)
    if command -v sunshine &> /dev/null; then
        if ! pgrep -x "sunshine" > /dev/null; then
            log_info "Starting Sunshine remote desktop..."
            nohup sunshine > /workspace/sunshine.log 2>&1 &
        else
            log_info "Sunshine is already running."
        fi
    else
        log_info "Sunshine not installed. Skipping."
    fi
}

print_summary() {
    log_step "Setup Complete - Service Summary"
    echo "----------------------------------------------------------------"
    echo "ComfyUI (GPUs 0,1): http://<YOUR_VAST_IP>:8188"
    echo "Ollama (GPUs 2,3):  Running (Model: $OLLAMA_MODEL)"
    
    if pgrep -f "uvicorn autopilot_chat:app" > /dev/null; then
        echo "FastAPI Autopilot:  http://<YOUR_VAST_IP>:8080"
    fi
    
    if pgrep -x "sunshine" > /dev/null; then
        echo "Sunshine Desktop:   Running (Check Sunshine logs for port)"
    fi
    
    echo "----------------------------------------------------------------"
    echo "Debug Log:          tail -f $LOGFILE"
    echo "Service Logs:       /workspace/*.log"
    echo "----------------------------------------------------------------"
}

# --- Main Execution ---
log_step "Starting Manus Lite 2.0 Optimized Setup..."

check_gpu
install_essentials
install_python_stack
setup_comfyui
setup_ollama
launch_services
print_summary

log_info "All services are backgrounded. Keeping container alive..."
# Keep the script running to prevent container exit if this is the entrypoint
while true; do
    sleep 60
    # Optional: Add health checks here to restart services if they crash
done