"""Run after exporting Web; compress game payloads for the Pages per-file limit."""
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
pack_parts = []
for payload in [wasm, output / "play/index.pck"]:
    data = payload.read_bytes() if payload.exists() else b"".join((payload.parent / name).read_bytes() for name in json.loads((payload.parent / "pack-parts.json").read_text()))
    if not data.startswith(b"\x1f\x8b"):
        data = gzip.compress(data, compresslevel=9, mtime=0)
    payload.write_bytes(data)
    if payload.stat().st_size > 25 * 1024 * 1024:
        if payload.suffix != ".pck":
            raise SystemExit(f"Payload exceeds Pages limit: {payload.name}")
        compressed = payload.read_bytes()
        for index, offset in enumerate(range(0, len(compressed), 16 * 1024 * 1024)):
            name = f"index.pck.part{index}"
            (payload.parent / name).write_bytes(compressed[offset:offset+16*1024*1024])
            pack_parts.append(name)
        (payload.parent / "pack-parts.json").write_text(json.dumps(pack_parts))
        payload.unlink()
landing = (root / args.landing).read_text(encoding="utf-8")
landing = re.sub(r'href="https://github\.com/luquinhardp-cmyk/Run_away/releases/download/[^" ]+/ecos-android\.apk"', 'href="/baixar-apk"', landing)
(output / "index.html").write_text(landing, encoding="utf-8")
(output / "_redirects").write_text("\n".join(f"{path} {args.apk_url} 302" for path in ["/baixar-apk", "/baixar-apk/", "/ecos-android.apk"]) + "\n", encoding="utf-8")
shutil.copyfile(root / "hosting/_headers", output / "_headers")
shutil.copyfile(root / "hosting/wasm-loader.js", output / "play/wasm-loader.js")
page = output / "play/index.html"
html = page.read_text(encoding="utf-8")
html = re.sub(r'<script>window.ECOS_PACK_PARTS=.*?</script>\s*', '', html)
if 'src="wasm-loader.js"' not in html:
    html = html.replace('<script src="index.js">', '<script src="wasm-loader.js"></script>\n\t\t<script src="index.js">')
if pack_parts:
    html = html.replace('<script src="wasm-loader.js">', '<script>window.ECOS_PACK_PARTS=' + json.dumps(pack_parts) + ';</script>\n<script src="wasm-loader.js">')
page.write_text(html, encoding="utf-8")
try:
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
except (OSError, subprocess.CalledProcessError):
    commit = "unknown"
version = re.search(r'version/name="([^"]+)"', (root / "export_presets.cfg").read_text(encoding="utf-8")).group(1)
(output / "version.json").write_text(json.dumps({"version": version, "commit": commit, "renderer": "Compatibility", "apk": "https://run-away-ecos.pages.dev/baixar-apk", "apk_versioned": args.apk_url}), encoding="utf-8")
print(f"Hosting ready: WASM {wasm.stat().st_size:,} bytes; gzip header required.")
