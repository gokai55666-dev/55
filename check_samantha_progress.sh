# Replace lines 56-60 with:
MISSING=0
while read -r FILE; do
    if [ ! -f "$FILE" ]; then
        echo "[FETCH] Downloading $FILE..."
        git lfs fetch --include="$FILE" 2>&1 | tee -a "$LOG_FILE"
        MISSING=$((MISSING + 1))
    fi
done < <(git lfs ls-files -n)  # Process substitution, not pipe

# Replace lines 78-85 with:
ALL_PRESENT=1
while read -r FILE; do
    if [ ! -f "$FILE" ]; then
        ALL_PRESENT=0
        break  # Early exit on first missing
    fi
done < <(git lfs ls-files -n)

# Fix Modelfile path (line 63):
GGUF_FILE=$(find . -name "*.gguf" | head -1)
cat > "$MODEL_FILE" << EOF
FROM $GGUF_FILE
...
EOF
