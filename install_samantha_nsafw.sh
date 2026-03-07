#!/bin/bash
set -euo pipefail

INSTALL_DIR="/root/ai_system"
SAMANTHA_REPO="https://github.com/gokai55666-dev/55/raw/main/install_samantha_nsafw.sh"

# Create install folder
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Download the fixed installer
curl -fLo install_samantha_nsafw.sh "$SAMANTHA_REPO"
chmod +x install_samantha_nsafw.sh

# Fix broken quotes in original script if any
sed -i 's/\r//g' install_samantha_nsafw.sh      # Remove any Windows line endings
sed -i 's/“/"/g' install_samantha_nsafw.sh      # Replace fancy quotes with normal quotes
sed -i 's/”/"/g' install_samantha_nsafw.sh

# Run the installer
echo "[INFO] Running Samantha NSFW installer..."
./install_samantha_nsafw.sh

echo "[INFO] Samantha installation complete!"