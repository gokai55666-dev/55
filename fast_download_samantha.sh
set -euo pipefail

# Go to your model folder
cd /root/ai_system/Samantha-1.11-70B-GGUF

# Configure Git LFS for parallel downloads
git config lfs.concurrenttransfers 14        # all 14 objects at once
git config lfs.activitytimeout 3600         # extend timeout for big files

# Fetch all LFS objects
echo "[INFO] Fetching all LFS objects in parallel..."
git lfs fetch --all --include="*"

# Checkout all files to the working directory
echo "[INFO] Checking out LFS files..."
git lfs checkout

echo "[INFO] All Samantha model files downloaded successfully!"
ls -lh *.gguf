#!/bin/bash
set -euo pipefail

# Go to your model folder
cd /root/ai_system/Samantha-1.11-70B-GGUF

# Configure Git LFS for parallel downloads
git config lfs.concurrenttransfers 14        # all 14 objects at once
git config lfs.activitytimeout 3600         # extend timeout for big files

# Fetch all LFS objects
echo "[INFO] Fetching all LFS objects in parallel..."
git lfs fetch --all --include="*"

# Checkout all files to the working directory
echo "[INFO] Checking out LFS files..."
git lfs checkout

echo "[INFO] All Samantha model files downloaded successfully!"
ls -lh *.gguf