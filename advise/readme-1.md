structure draft so far:

project/
├── src/                # your code
├── scripts/            # automation
├── prompts/            # text prompts
├── outputs/            # generated stuff (IGNORE or LFS)
├── models/             # big files (LFS or external)
├── .gitignore
├── .gitattributes







-------------



Track large files with LFS
Inside your repo:
Bash
git lfs track "*.pt"
git lfs track "*.ckpt"
git lfs track "*.safetensors"
git lfs track "*.zip"
git lfs track "*.png"
git lfs track "*.jpg"
Then:
Bash
git add .gitattributes
git commit -m "setup git lfs tracking"



------------



Next Fix your .gitignore (CRITICAL)
Create/edit:
Bash
nano .gitignore
Paste this:


# Python
__pycache__/
*.pyc

# Env
.env

# Outputs (don’t upload junk)
outputs/

# Large temp files
*.log
*.tmp

# Optional: ignore models if too big
models/

---
This alone prevents 80% of repo bloat.



---------------


now after .gitignore fix next is, push your repo cleanly
Bash
git init
git add .
git commit -m "initial clean commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main


----------------------


If your repo was already broken before
If you previously pushed large files:
Bash
pkg install git-filter-repo -y
git filter-repo --strip-blobs-bigger-than 50M
Then force push:
Bash
git push --force



-------------


