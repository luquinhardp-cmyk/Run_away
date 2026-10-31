"""Build an isolated Web benchmark; never changes the production main scene."""
from pathlib import Path
import argparse, shutil, subprocess, re
parser=argparse.ArgumentParser()
parser.add_argument("--godot", required=True)
parser.add_argument("--scene",default="res://tests/performance_review.tscn")
parser.add_argument("--name",default="web-audit")
args=parser.parse_args()
if not re.fullmatch(r"[a-z0-9_-]+",args.name): parser.error("Invalid build name")
root=Path(__file__).resolve().parents[1]
target=root/("builds/"+args.name+"/project")
target.mkdir(parents=True, exist_ok=True)
for name in ["scripts","assets","resources","scenes","shaders","tests"]:
    shutil.copytree(root/name,target/name,dirs_exist_ok=True,ignore=shutil.ignore_patterns("__pycache__","source") if name=="assets" else None)
for file in root.iterdir():
    if file.is_file() and file.suffix in [".godot",".tres",".cfg"]:
        if file.name=="export_credentials.cfg": continue
        shutil.copy2(file,target/file.name)
cache=root/".godot/imported"
if cache.exists(): shutil.copytree(cache,target/".godot/imported",dirs_exist_ok=True)
project=target/"project.godot"
project.write_text(project.read_text(encoding="utf-8").replace('run/main_scene="res://scenes/main/main.tscn"','run/main_scene="'+args.scene+'"'),encoding="utf-8")
presets=target/"export_presets.cfg"
config=presets.read_text(encoding="utf-8").replace("docs/*,tests/*,tools/*","docs/*,tools/*")
presets.write_text(config,encoding="utf-8")
out=root/("builds/"+args.name+"/site/play/index.html")
out.parent.mkdir(parents=True,exist_ok=True)
subprocess.run([args.godot,"--headless","--path",str(target),"--editor","--import","--quit"],check=True)
subprocess.run([args.godot,"--headless","--path",str(target),"--export-release","Web",str(out)],check=True)
subprocess.run(["python",str(root/"hosting/prepare.py"),"--output","builds/"+args.name+"/site","--apk-url","https://github.com/luquinhardp-cmyk/Run_away/releases/download/v0.9.0-creature-study/ecos-android.apk"],check=True)
print("QA-only export:",out)
