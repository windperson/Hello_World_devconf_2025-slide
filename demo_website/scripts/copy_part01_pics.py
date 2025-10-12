from pathlib import Path
import shutil
import sys

# paths are relative to the project root (where _quarto.yml lives)
SRC_DIR = Path("../slides_src/01_Tool_Setup/pics")
DST_DIR = Path("images/part01/pics")

# Option: copy a single file if provided as an arg, otherwise copy all PNG/JPG
def main():
    DST_DIR.mkdir(parents=True, exist_ok=True)

    if len(sys.argv) > 1:
        src = Path(sys.argv[1])
        if not src.exists():
            print(f"Source not found: {src}")
            sys.exit(1)
        shutil.copy2(src, DST_DIR / src.name)
        print(f"Copied: {src} -> {DST_DIR / src.name}")
        return

    patterns = ["*.png", "*.jpg", "*.jpeg", "*.gif"]
    copied = 0
    for pat in patterns:
        for p in SRC_DIR.glob(pat):
            shutil.copy2(p, DST_DIR / p.name)
            copied += 1

    print(f"Copied {copied} files from {SRC_DIR} to {DST_DIR}")

if __name__ == "__main__":
    main()