#!/usr/bin/env python3
from pathlib import Path
import hashlib
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data"
OUT = DATA / "manifests"
OUT.mkdir(parents=True, exist_ok=True)

def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

rows = []
for path in sorted(DATA.rglob("*")):
    if path.is_file():
        rel = path.relative_to(ROOT)
        rows.append({"path": str(rel), "size_bytes": path.stat().st_size, "sha256": sha256(path)})

manifest = pd.DataFrame(rows)
manifest.to_csv(OUT / "file_manifest_sha256.csv", index=False)
print("Written:", OUT / "file_manifest_sha256.csv")
print("Files:", len(manifest))
