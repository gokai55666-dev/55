#!/bin/bash
# ==========================================================
# AI Server Maintenance & Debugging Script
# Keeps system clean, checks updates, verifies AI environment
# ==========================================================

set -euo pipefail

echo "=========================================================="
echo "         AI Server Maintenance & Debug Tool"
echo "=========================================================="
echo ""

# -----------------------------
# 1. Clean zombie processes
# -----------------------------
echo "[INFO] Checking for zombie processes..."
ZOMBIES=$(ps -eo pid,ppid,stat,cmd | awk '$3=="Z" {print $0}')

if [ -z "$ZOMBIES" ]; then
    echo "[INFO] No zombie processes found."
else
    echo "[WARNING] Found zombie processes:"
    echo "$ZOMBIES"
    echo ""
    echo "[INFO] Attempting to kill parent processes to clear zombies..."
    for ppid in $(echo "$ZOMBIES" | awk '{print $2}' | sort -u); do
        echo "  Killing parent process PID: $ppid"
        kill -9 $ppid 2>/dev/null || echo "    Failed to kill $ppid (may require manual check)"
    done
    echo "[INFO] Zombie cleanup attempted."
fi
echo ""

# -----------------------------
# 2. System health
# -----------------------------
echo "[INFO] System health overview:"
echo "CPU load:"
uptime
echo ""
echo "Memory usage:"
free -h
echo ""
echo "Disk usage:"
df -h
echo ""

# -----------------------------
# 3. Pending updates
# -----------------------------
echo "[INFO] Checking available package updates..."
apt update -qq
UPGRADABLE=$(apt list --upgradable 2>/dev/null | tail -n +2)

if [ -z "$UPGRADABLE" ]; then
    echo "[INFO] No packages need updating."
else
    echo "[WARNING] Upgradable packages:"
    echo "$UPGRADABLE"
    echo ""
    echo "[TIP] To upgrade safely, consider 'apt upgrade -y' for security updates."
fi
echo ""

# -----------------------------
# 4. Python environment check
# -----------------------------
echo "[INFO] Verifying Python packages..."
PYTHON_PACKAGES=("torch" "diffusers" "transformers" "accelerate" "safetensors" "fastapi" "uvicorn" "gradio")
for pkg in "${PYTHON_PACKAGES[@]}"; do
    python3 -c "import $pkg" 2>/dev/null && echo "  $pkg: OK" || echo "  $pkg: MISSING"
done
echo ""

# -----------------------------
# 5. AI services check
# -----------------------------
echo "[INFO] Checking AI services..."
SERVICES=("ollama" "python3 ai_frontend_improved.py")
for srv in "${SERVICES[@]}"; do
    if pgrep -f "$srv" >/dev/null; then
        echo "  $srv: RUNNING"
    else
        echo "  $srv: NOT RUNNING"
    fi
done
echo ""

# -----------------------------
# 6. Log and script integrity check
# -----------------------------
echo "[INFO] Checking key AI scripts..."
SCRIPTS=(
    "/root/ai_system/ai_frontend_improved.py"
    "/root/ai_system/install_samantha.sh"
    "/root/ai_system/install_ai_system2.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "  $script: EXISTS"
        # Check for syntax errors (Python scripts only)
        if [[ $script == *.py ]]; then
            python3 -m py_compile "$script" 2>/dev/null && echo "    Syntax: OK" || echo "    Syntax: ERROR"
        fi
    else
        echo "  $script: MISSING"
    fi
done
echo ""

# -----------------------------
# 7. Optional: restart AI services
# -----------------------------
echo "[INFO] To restart Ollama server manually, run:"
echo "      pkill -f ollama; nohup ollama serve > /root/ai_system/ollama.log 2>&1 &"
echo ""
echo "[INFO] To run AI Frontend manually, run:"
echo "      cd /root/ai_system && python3 ai_frontend_improved.py"
echo ""

echo "=========================================================="
echo "          Maintenance script completed."
echo "=========================================================="