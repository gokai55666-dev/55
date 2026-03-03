#!/bin/bash

mkdir -p Number-1 && cd Number-1 || exit

#####################################
# .gitignore
#####################################
cat > .gitignore << 'EOF'
__pycache__/
*.pyc
*.pyo
*.db
*.sqlite3
*.log
node_modules/
.env
.vscode/
.DS_Store
EOF

#####################################
# docker-compose.yml
#####################################
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  bridge:
    build: ./bridge
    ports:
      - "3000:3000"
    environment:
      - AI_ENGINE_URL=http://ai-engine:8000
    volumes:
      - shared_data:/shared
    networks:
      - omega-net

  ai-engine:
    build: ./ai-engine
    ports:
      - "8000:8000"
    volumes:
      - shared_data:/shared
    networks:
      - omega-net

  database:
    build: ./database
    ports:
      - "5000:5000"
    volumes:
      - ./database/data:/app/data
    networks:
      - omega-net

  flags:
    build: ./flags
    ports:
      - "9000:9000"
    networks:
      - omega-net

  sidecar:
    build: ./sidecar
    volumes:
      - shared_data:/shared
    networks:
      - omega-net

networks:
  omega-net:

volumes:
  shared_data:
EOF

#####################################
# AI ENGINE
#####################################
mkdir -p ai-engine

cat > ai-engine/main.py << 'EOF'
from fastapi import FastAPI
from pydantic import BaseModel
import random

app = FastAPI()

class Prompt(BaseModel):
    prompt: str

@app.post("/analyze")
async def analyze(data: Prompt):
    tokens = [t.strip() for t in data.prompt.split(",")]
    thoughts = [f"Analyzing token: {t}" for t in tokens[:5]]

    return {
        "thoughtProcess": thoughts,
        "confidence": round(random.uniform(0.8, 0.98), 3),
        "recommendedGuidance": len(tokens) + 5
    }

@app.get("/health")
def health():
    return {"status": "healthy"}
EOF

cat > ai-engine/requirements.txt << 'EOF'
fastapi
uvicorn
pydantic
EOF

cat > ai-engine/start.sh << 'EOF'
#!/bin/sh
PORT=${PORT:-8000}
uvicorn main:app --host 0.0.0.0 --port $PORT
EOF
chmod +x ai-engine/start.sh

cat > ai-engine/Dockerfile << 'EOF'
FROM python:3.10-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["./start.sh"]
EOF

#####################################
# DATABASE
#####################################
mkdir -p database/data

cat > database/app.py << 'EOF'
from fastapi import FastAPI
import sqlite3
import os

app = FastAPI()
DB = "/app/data/omega.db"
os.makedirs(os.path.dirname(DB), exist_ok=True)

def init():
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("CREATE TABLE IF NOT EXISTS prompts (id INTEGER PRIMARY KEY, text TEXT)")
    conn.commit()
    conn.close()

init()

@app.post("/save")
def save(data: dict):
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("INSERT INTO prompts (text) VALUES (?)", (data["prompt"],))
    conn.commit()
    conn.close()
    return {"status": "saved"}

@app.get("/health")
def health():
    return {"status": "healthy"}
EOF

cat > database/start.sh << 'EOF'
#!/bin/sh
PORT=${PORT:-5000}
uvicorn app:app --host 0.0.0.0 --port $PORT
EOF
chmod +x database/start.sh

cat > database/Dockerfile << 'EOF'
FROM python:3.10-slim
WORKDIR /app
RUN pip install fastapi uvicorn
COPY . .
EXPOSE 5000
CMD ["./start.sh"]
EOF

#####################################
# FLAGS SERVICE
#####################################
mkdir -p flags

cat > flags/app.py << 'EOF'
from fastapi import FastAPI
app = FastAPI()

@app.get("/status")
def status():
    return {"mode": "production", "safety": "enabled"}
EOF

cat > flags/start.sh << 'EOF'
#!/bin/sh
PORT=${PORT:-9000}
uvicorn app:app --host 0.0.0.0 --port $PORT
EOF
chmod +x flags/start.sh

cat > flags/Dockerfile << 'EOF'
FROM python:3.10-slim
WORKDIR /app
RUN pip install fastapi uvicorn
COPY . .
EXPOSE 9000
CMD ["./start.sh"]
EOF

#####################################
# BRIDGE (Node)
#####################################
mkdir -p bridge

cat > bridge/package.json << 'EOF'
{
  "name": "omega-bridge",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "socket.io": "^4.7.2",
    "axios": "^1.6.2",
    "cors": "^2.8.5"
  }
}
EOF

cat > bridge/server.js << 'EOF'
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const axios = require('axios');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

const AI_ENGINE = process.env.AI_ENGINE_URL || "http://localhost:8000";

io.on("connection", socket => {
  socket.on("analyze", async (data) => {
    try {
      const res = await axios.post(AI_ENGINE + "/analyze", { prompt: data.prompt });
      socket.emit("result", res.data);
    } catch (e) {
      socket.emit("error", { message: "AI Engine unreachable" });
    }
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log("Bridge running on " + PORT));
EOF

cat > bridge/Dockerfile << 'EOF'
FROM node:18-slim
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
EOF

#####################################
# SIDECAR
#####################################
mkdir -p sidecar

cat > sidecar/detector.py << 'EOF'
import time
import json
import os

SHARED = "/shared"
os.makedirs(SHARED, exist_ok=True)

while True:
    status = {
        "status": "running",
        "timestamp": time.time()
    }
    with open(os.path.join(SHARED, "sandbox_status.json"), "w") as f:
        json.dump(status, f)
    time.sleep(5)
EOF

cat > sidecar/Dockerfile << 'EOF'
FROM python:3.10-slim
WORKDIR /app
COPY . .
CMD ["python", "detector.py"]
EOF

#####################################
# FRONTEND INJECT FILE
#####################################
mkdir -p frontend

cat > frontend/meta_bridge_injected.js << 'EOF'
console.log("OMEGA META BRIDGE ACTIVE");
EOF

echo "🔥 OMEGA PROJECT FULLY GENERATED."
