#!/bin/bash
set -euo pipefail

INSTALL_DIR="/root/ai_system"
SAMANTHA_DIR="$INSTALL_DIR/Samantha-1.11-70B-GGUF"
SAMANTHA_MODFILE="$INSTALL_DIR/Samantha-Modelfile"

echo "=========================================================="
echo "[INFO] Resetting Samantha NSFW AI Environment"
echo "=========================================================="

# -----------------------------
# 1. Kill zombies
# -----------------------------
echo "[INFO] Cleaning zombie processes..."
ZOMBIES=$(ps -eo pid,ppid,stat,cmd | awk '$3=="Z" {print $0}')

if [ -n "$ZOMBIES" ]; then
    echo "[WARNING] Found zombies, attempting to kill parents:"
    echo "$ZOMBIES"
    for ppid in $(echo "$ZOMBIES" | awk '{print $2}' | sort -u); do
        kill -9 $ppid 2>/dev/null || true
    done
    echo "[INFO] Zombies cleanup attempted."
else
    echo "[INFO] No zombies detected."
fi
echo ""

# -----------------------------
# 2. Remove old Samantha files
# -----------------------------
echo "[INFO] Removing old Samantha files..."
rm -rf "$SAMANTHA_DIR" "$SAMANTHA_MODFILE"
echo "[INFO] Old files removed."
echo ""

# -----------------------------
# 3. Download Samantha from GitHub
# -----------------------------
echo "[INFO] Downloading Samantha NSFW files..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

git lfs install
if [ -d "$SAMANTHA_DIR" ]; then
    rm -rf "$SAMANTHA_DIR"
fi

echo "[INFO] Cloning Samantha NSFW repository..."
git clone https://huggingface.co/TheBloke/Samantha-1.11-70B-GGUF "$SAMANTHA_DIR"

# -----------------------------
# 4. Create Ollama Modelfile
# -----------------------------
echo "[INFO] Creating Ollama Modelfile..."
cat > "$SAMANTHA_MODFILE" << 'EOF'
FROM ./Samantha-1.11-70B-GGUF.gguf
PARAMETER temperature 0.8
EOF

# -----------------------------
# 5. Create Ollama model
# -----------------------------
echo "[INFO] Creating Ollama Samantha model..."
if ollama list | grep -q "samantha-uncensored"; then
    echo "[INFO] Model already exists, removing old model..."
    ollama delete samantha-uncensored
fi
ollama create samantha-uncensored -f "$SAMANTHA_MODFILE"

# -----------------------------
# 6. Check AI Frontend
# -----------------------------
FRONTEND="$INSTALL_DIR/ai_frontend_improved.py"
if [ ! -f "$FRONTEND" ]; then
    echo "[INFO] Downloading Improved AI Frontend..."
    wget -O "$FRONTEND" https://raw.githubusercontent.com/gokai55666-dev/55/main/ai_frontend_improved.py
    chmod +x "$FRONTEND"
else
    echo "[INFO] AI Frontend already exists."
fi

# -----------------------------
# 7. Done
# -----------------------------
echo ""
echo "[INFO] Samantha NSFW environment reset complete!"
echo "Run AI Frontend with:"
echo "cd $INSTALL_DIR && python3 ai_frontend_improved.py"
echo "Ollama server with:"
echo "nohup ollama serve > $INSTALL_DIR/ollama.log 2>&1 &"
echo "=========================================================="