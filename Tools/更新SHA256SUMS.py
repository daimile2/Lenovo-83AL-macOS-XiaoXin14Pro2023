#!/usr/bin/env python3
"""Rebuild the repository SHA256SUMS.txt after adding release files."""
import hashlib
from pathlib import Path

root = Path(__file__).resolve().parents[1]
lines = []
for path in sorted(root.rglob("*")):
    if not path.is_file():
        continue
    relative = path.relative_to(root)
    if relative.parts[0] == ".git" or path.name == "SHA256SUMS.txt":
        continue
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    lines.append(f"{digest.hexdigest()}  {relative.as_posix()}")

output = root / "SHA256SUMS.txt"
output.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"已更新 {output}，共记录 {len(lines)} 个文件。")
