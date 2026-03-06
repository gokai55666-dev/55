mkdir -p /workspace/ComfyUI && cat << 'EOF' > /workspace/ComfyUI/launch_comfy_logging.sh
#!/bin/bash
# ==============================
# ComfyUI launcher with logging
# ==============================

# Correct virtualenv and ComfyUI paths
ENV_PATH="/workspace/ollama_env"
COMFY_DIR="/workspace/ComfyUI"
LOG_DIR="$COMFY_DIR/logs"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Activate the virtual environment
source "$ENV_PATH/bin/activate"

# Go to ComfyUI directory
cd "$COMFY_DIR"

echo "Starting ComfyUI in environment: $ENV_PATH"
echo "Logs will be stored in: $LOG_DIR"

# Loop to restart ComfyUI if it crashes
while true; do
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    LOG_FILE="$LOG_DIR/comfyui_$TIMESTAMP.log"

    echo "Launching ComfyUI... (logging to $LOG_FILE)"

    # Run ComfyUI, output to console and log file
    python launch.py 2>&1 | tee "$LOG_FILE"

    EXIT_CODE=${PIPESTATUS[0]}
    echo "ComfyUI exited with code $EXIT_CODE. Restarting in 5 seconds..."
    sleep 5
done
EOF

chmod +x /workspace/ComfyUI/launch_comfy_logging.sh
echo "Script created and made executable: /workspace/ComfyUI/launch_comfy_logging.sh"