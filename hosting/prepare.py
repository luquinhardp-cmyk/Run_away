"""Run after exporting Web; compress the WASM for the Pages per-file limit."""
import gzip
import shutil
from pathlib import Path

root = Path(__file__).resolve().parents[1]
output = root / "builds/web"
wasm = output / "play/index.wasm"
data = wasm.read_bytes()
if not data.startswith(b"\x1f\x8b"):
    wasm.write_bytes(gzip.compress(data, compresslevel=9, mtime=0))
for name in ("index.html", "_headers"):
    shutil.copyfile(root / "hosting" / name, output / name)
print(f"Hosting ready: WASM {wasm.stat().st_size:,} bytes; gzip header required.")
