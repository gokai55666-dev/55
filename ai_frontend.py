from ollama_client import generate_text
from image_generator import ImageGenerator

img_gen = ImageGenerator()

print("AI Frontend")
print("Commands: text | image | exit")

while True:

    cmd = input(">> ")

    if cmd == "exit":
        break

    if cmd == "text":
        prompt = input("Prompt: ")
        result = generate_text(prompt)
        print(result)

    elif cmd == "image":
        prompt = input("Image prompt: ")

        img = img_gen.generate(prompt)

        filename = "generated.png"
        img.save(filename)

        print("Saved:", filename)

    else:
        print("Unknown command")