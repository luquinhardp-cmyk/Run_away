"""Run after exporting Web; compress the WASM for the Pages per-file limit."""
import gzip
import shutil
import json
import re
import subprocess
import argparse
from pathlib import Path

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--output", default="builds/web")
parser.add_argument("--landing", default="hosting/index.html")
parser.add_argument("--apk-url", default="https://github.com/luquinhardp-cmyk/Run_away/releases/download/v0.3.0-cloud/ecos-android.apk")
args = parser.parse_args()
output = root / args.output
wasm = output / "play/index.wasm"
data = wasm.read_bytes()
if not data.startswith(b"\x1f\x8b"):
    wasm.write_bytes(gzip.compress(data, compresslevel=9, mtime=0))
shutil.copyfile(root / args.landing, output / "index.html")
shutil.copyfile(root / "hosting/_headers", output / "_headers")
shutil.copyfile(root / "hosting/wasm-loader.js", output / "play/wasm-loader.js")
page = output / "play/index.html"
html = page.read_text(encoding="utf-8")
if 'src="wasm-loader.js"' not in html:
    html = html.replace('<script src="index.js">', '<script src="wasm-loader.js"></script>\n\t\t<script src="index.js">')
page.write_text(html, encoding="utf-8")
try:
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
except (OSError, subprocess.CalledProcessError):
    commit = "unknown"
version = re.search(r'version/name="([^"]+)"', (root / "export_presets.cfg").read_text(encoding="utf-8")).group(1)
(output / "version.json").write_text(json.dumps({"version": version, "commit": commit, "renderer": "Compatibility", "apk": args.apk_url}), encoding="utf-8")
print(f"Hosting ready: WASM {wasm.stat().st_size:,} bytes; gzip header required.")
