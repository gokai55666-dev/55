import os

# Root directories to search
search_dirs = ["/usr/local/bin", "/usr/bin", "/root", os.path.expanduser("~")]

# File names or keywords to look for
keywords = ["olama", "comfy", "sdxl", "model", "ai"]

found = []

for root_dir in search_dirs:
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for fname in filenames:
            for kw in keywords:
                if kw.lower() in fname.lower():
                    full_path = os.path.join(dirpath, fname)
                    found.append(full_path)

if found:
    print("Found the following AI-related files/binaries:")
    for f in found:
        print(f)
else:
    print("No AI executables/models found in the searched directories.")