"""Reject APKs that would break in-place updates. Never prints private key data."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("previous", type=Path)
parser.add_argument("candidate", type=Path)
parser.add_argument("--output", type=Path)
args = parser.parse_args()
sdk = Path(os.environ.get("ANDROID_HOME", str(Path.home() / "AppData/Local/Android/Sdk")))
versions = sorted((sdk / "build-tools").glob("*"), reverse=True)
build = next(p for p in versions if (p / "apksigner.bat").exists() and (p / "aapt.exe").exists())

def inspect(apk):
    # Older SDK tools can emit valid package metadata then fail on a newer optional
    # manifest attribute. Signature verification below remains strictly checked.
    badging = subprocess.run([str(build / "aapt.exe"), "dump", "badging", str(apk)], text=True, capture_output=True).stdout
    package = re.search(r"package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'", badging)
    if not package:
        raise SystemExit("Cannot read APK package identity")
    signature = subprocess.check_output([str(build / "apksigner.bat"), "verify", "--verbose", "--print-certs", str(apk)], text=True)
    certs = sorted(re.findall(r"Signer #\d+ certificate SHA-256 digest: ([0-9a-fA-F]+)", signature))
    if not certs:
        raise SystemExit("No verified signer certificate")
    return {"package": package[1], "version_code": int(package[2]), "version_name": package[3], "certificate_sha256": certs, "bytes": apk.stat().st_size}

previous, candidate = inspect(args.previous), inspect(args.candidate)
checks = {
    "canonical_package": candidate["package"] == "org.ecos.instalacaoabandonada",
    "same_package": previous["package"] == candidate["package"],
    "same_signer": previous["certificate_sha256"] == candidate["certificate_sha256"],
    "increased_version_code": candidate["version_code"] > previous["version_code"],
}
result = {"previous": previous, "candidate": candidate, "checks": checks, "passed": all(checks.values()), "physical_install_test": False}
if args.output:
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2), encoding="utf-8")
print(json.dumps(result, indent=2))
raise SystemExit(0 if result["passed"] else 1)
