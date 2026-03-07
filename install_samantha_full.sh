#!/bin/bash
set -euo pipefail

INSTALL_DIR="/root/ai_system"
MODEL_NAME="Samantha-1.11-70B-GGUF"
OL_NAME="samantha-uncensored"

echo "[INFO] Starting full Samantha NSFW installation and maintenance..."

# -----------------------------
# 1️⃣ Kill definite zombie processes
# -----------------------------
ZOMBIES=$(ps -ef | awk '{ if ($3 == 1 && $8 == "<defunct>") print $2 }')
if [ -n "$ZOMBIES" ]; then
    echo "[INFO] Killing zombies: $ZOMBIES"
    kill -9 $ZOMBIES || true
else
    echo "[INFO] No zombies found."
fi

# -----------------------------
# 2️⃣ Clean previous Samantha files
# -----------------------------
if [ -d "$INSTALL_DIR/$MODEL_NAME" ]; then
    echo "[INFO] Removing old Samantha model folder..."
    rm -rf "$INSTALL_DIR/$MODEL_NAME"
fi

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# -----------------------------
# 3️⃣ Clone and fetch Samantha in parallel
# -----------------------------
echo "[INFO] Cloning Samantha model repo..."
git clone https://huggingface.co/TheBloke/$MODEL_NAME
cd "$MODEL_NAME"

echo "[INFO] Configuring Git LFS for parallel downloads..."
git config lfs.concurrenttransfers 14
git config lfs.activitytimeout 3600

echo "[INFO] Fetching all LFS objects in parallel..."
git lfs fetch --all --include="*"
git lfs checkout

echo "[INFO] Samantha model files ready:"
ls -lh *.gguf

# -----------------------------
# 4️⃣ Create Ollama Modelfile and model
# -----------------------------
cd "$INSTALL_DIR"
cat > Samantha-Modelfile << EOF
FROM ./$MODEL_NAME.gguf
PARAMETER temperature 0.8
EOF

if ! ollama list | grep -q "$OL_NAME"; then
    echo "[INFO] Creating Ollama Samantha NSFW model..."
    ollama create "$OL_NAME" -f Samantha-Modelfile || echo "[WARN] Model creation failed — check GGUF files."
else
    echo "[INFO] Ollama model already exists."
fi

# -----------------------------
# 5️⃣ Download AI Frontend (Improved)
# -----------------------------
echo "[INFO] Downloading AI frontend..."
curl -fLo "$INSTALL_DIR/ai_frontend_improved.py" https://raw.githubusercontent.com/gokai55666-dev/55/main/ai_frontend_improved.py
chmod +x "$INSTALL_DIR/ai_frontend_improved.py"

# -----------------------------
# Done
# -----------------------------
echo "[INFO] Full Samantha NSFW setup complete!"
echo "Run the frontend with:"
echo "cd $INSTALL_DIR && python3 ai_frontend_improved.py --desktop"