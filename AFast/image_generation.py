# /root/samantha_ultimate/interfaces/modes/image_generation.py
from interfaces.core_setup import activate_env, gpu_for, run_command, path_to_model, path_to_lora

def render(context):
    # Activate diffusion venv
    env_cmd = activate_env("diffusion")
    gpu_id = gpu_for("diffusion")
    
    # Example: Run stable diffusion pipeline with NSFW LoRA
    sd_model = path_to_model("sdxl_base.safetensors", "diffusion")
    lora_file = path_to_lora("sigma_face.safetensors")

    cmd = f"python run_sd_pipeline.py --model {sd_model} --lora {lora_file}"
    result = run_command(cmd, env="diffusion", gpu=gpu_id)

    if result.returncode == 0:
        print("Image generation completed successfully")
    else:
        print("Error:", result.stderr)