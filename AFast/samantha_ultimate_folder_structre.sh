/root/samantha_ultimate/
├─ envs/
│   ├─ llm/                # Python venv for LLM inference
│   ├─ diffusion/          # Python venv for SDXL / FLUX / video
│   ├─ training/           # Python venv for LoRA / DreamBooth
│   ├─ agent/              # Python venv for orchestration / agent
│   └─ embeddings/         # Python venv for face embeddings / open-clip
├─ models/
│   ├─ diffusion/
│   │   ├─ sdxl_base.safetensors
│   │   ├─ flux_dev.safetensors
│   │   └─ loras/
│   ├─ video/
│   │   ├─ wan2.2_t2v_high.safetensors
│   │   └─ wan2.2_i2v_high.safetensors
│   └─ llm/
│       ├─ llama3_70b/
│       └─ qwen2.5_72b/
├─ data/
│   ├─ datasets/           # Training data
│   └─ embeddings/         # Face embeddings
├─ scripts/
│   ├─ start_all.sh        # Launch all services (with GPU assignment)
│   ├─ install_models.sh   # Download & place models
│   └─ update_system.sh    # Pull updates, clean caches
├─ interfaces/
│   ├─ streamlit_ui.py     # Main dashboard
│   └─ modes/
│       ├─ image_generation.py
│       ├─ video_generation.py
│       ├─ text_generation.py
│       ├─ model_training.py
│       ├─ system_control.py
│       └─ agent_controller.py
└─ logs/
    ├─ system.log
    └─ agent.log