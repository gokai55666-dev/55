from diffusers import StableDiffusionPipeline
import torch

class ImageGenerator:

    def __init__(self):
        model_id = "runwayml/stable-diffusion-v1-5"

        device = "cuda" if torch.cuda.is_available() else "cpu"
        dtype = torch.float16 if device == "cuda" else torch.float32

        print(f"[Image] Loading model on {device}...")

        self.pipe = StableDiffusionPipeline.from_pretrained(
            model_id,
            torch_dtype=dtype
        )

        self.pipe = self.pipe.to(device)

    def generate(self, prompt, steps=40):
        print(f"[Image] Generating: {prompt}")

        image = self.pipe(
            prompt,
            num_inference_steps=steps
        ).images[0]

        return image