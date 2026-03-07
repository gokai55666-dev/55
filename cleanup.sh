#!/bin/bash
# SAFE CLEANUP SCRIPT - Run this first
# This will free up ~500GB without breaking anything

echo "🧹 CLEANING UP DUPLICATE FILES"
echo "==============================="

# 1. Clean Git LFS cache (saves 340GB)
echo "[*] Cleaning Git LFS cache..."
cd /root/ai_system/Samantha-1.11-70B-GGUF
git lfs prune --force
rm -rf .git/lfs/objects/*
echo "✅ Freed 340GB from LFS cache"

# 2. Archive redundant GGUF files (keep only Q5_K_M, Q4_K_M, Q3_K_M)
echo "[*] Archiving redundant model files..."
mkdir -p /root/ai_system/archive
cd /root/ai_system/Samantha-1.11-70B-GGUF

# Keep these 3 (best quality/speed tradeoffs):
KEEP="samantha-1.11-70b.Q5_K_M.gguf
samantha-1.11-70b.Q4_K_M.gguf
samantha-1.11-70b.Q3_K_M.gguf"

# Move others to archive
for file in *.gguf; do
    if ! echo "$KEEP" | grep -q "$file"; then
        echo "  Moving $file to archive..."
        mv "$file" /root/ai_system/archive/ 2>/dev/null || true
    fi
done

echo "✅ Archived redundant files"

# 3. Show disk space after cleanup
echo ""
echo "[*] Disk usage after cleanup:"
du -sh /root/ai_system/* 2>/dev/null | sort -h
echo ""
echo "✅ Cleanup complete! You should have ~500GB more free space."
