"""Packs every source file of the project into one dated text file.

Run from anywhere:   python tools/pack_code.py
Output:              <repo root>/coolman_dump_<YYYYMMDD_HHMMSS>.txt

Each file is wrapped as <document path="..."> ... </document> so an AI
assistant (or a person) can see where every file begins and ends.
Older dumps are never overwritten and never included in a new dump.
"""
import os
from datetime import datetime

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

IGNORE_DIRS = {
    '.git', '__pycache__', 'venv', '.venv', 'node_modules', 'uploads',
    '.dart_tool', 'build', '.idea', '.vscode', '.gradle',
    'ios', 'web', 'windows', 'macos', 'linux', 'android',
}
ALLOWED_EXTS = {'.dart', '.py', '.yaml', '.yml', '.xml', '.json', '.md', '.txt', '.toml'}


def generate_code_dump():
    now = datetime.now()
    output_file = os.path.join(
        PROJECT_ROOT, f"coolman_dump_{now.strftime('%Y%m%d_%H%M%S')}.txt"
    )
    count = 0
    with open(output_file, 'w', encoding='utf-8') as out:
        out.write("### SABIL / COOLMAN FULL CODEBASE DUMP ###\n")
        out.write(f"### GENERATED ON: {now.strftime('%Y-%m-%d %I:%M:%S %p')} ###\n\n")
        for dirpath, dirnames, filenames in os.walk(PROJECT_ROOT):
            dirnames[:] = sorted(d for d in dirnames if d not in IGNORE_DIRS)
            for filename in sorted(filenames):
                if os.path.splitext(filename)[1].lower() not in ALLOWED_EXTS:
                    continue
                if filename.startswith("coolman_dump_"):
                    continue
                path = os.path.join(dirpath, filename)
                rel = os.path.relpath(path, PROJECT_ROOT).replace(os.sep, "/")
                out.write(f'<document path="{rel}">\n')
                try:
                    with open(path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    out.write(content)
                    if not content.endswith('\n'):
                        out.write('\n')
                except Exception as e:
                    out.write(f"// Error reading file: {e}\n")
                out.write('</document>\n\n')
                count += 1
    print(f"Packed {count} files into {output_file}")


if __name__ == "__main__":
    generate_code_dump()
