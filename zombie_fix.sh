#!/bin/bash
set -euo pipefail

# -----------------------------
# User-configurable variables
# -----------------------------
INSTALL_DIR="/root/ai_system"
GITHUB_SCRIPT="install_samantha_github.sh"
GITHUB_BASE="https://raw.githubusercontent.com/gokai55666-dev/55/main"

# -----------------------------
# 1. Create directory
# -----------------------------
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# -----------------------------
# 2. Download and run the installer script
# -----------------------------
download_and_run() {
    SCRIPT_URL="$1"
    SCRIPT_NAME="$2"

    echo "[INFO] Downloading $SCRIPT_NAME from GitHub..."
    curl -fLo "$SCRIPT_NAME" "$SCRIPT_URL"
    
    echo "[INFO] Making $SCRIPT_NAME executable..."
    chmod +x "$SCRIPT_NAME"
    
    echo "[INFO] Running $SCRIPT_NAME..."
    ./"$SCRIPT_NAME"
}

# -----------------------------
# 3. Call function for Samantha installer
# -----------------------------
download_and_run "$GITHUB_BASE/$GITHUB_SCRIPT" "$GITHUB_SCRIPT"