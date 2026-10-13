#!/usr/bin/env python3
"""Recupera o verifica los 13 videos compatibles usados en este APK."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import zipfile

base = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--apk", type=Path, help="APK previo que contiene las variantes playback")
parser.add_argument("--verificar", action="store_true", help="Comprueba los videos sin modificarlos")
args = parser.parse_args()
records = json.loads((base / "evidencias/recuperacion-videos.json").read_text())
output = base / "toktik/assets/videos"
if not args.verificar:
    source = base.parent / "toktik/assets/videos/playback"
    apk = args.apk or base.parent / "toktik/build/app/outputs/flutter-apk/app-debug.apk"
    output.mkdir(parents=True, exist_ok=True)
    if not args.apk and all((source / r["video"]).is_file() for r in records):
        for record in records:
            shutil.copy2(source / record["video"], output / record["video"])
    else:
        with zipfile.ZipFile(apk) as bundle:
            for record in records:
                (output / record["video"]).write_bytes(bundle.read(record["origen_en_apk_debug"]))
for record in records:
    path = output / record["video"]
    data = path.read_bytes()
    if len(data) != record["bytes"] or hashlib.sha256(data).hexdigest() != record["sha256"]:
        raise SystemExit(f"El video no coincide con la compilación documentada: {path}")
print("13 videos verificados: tamaño y SHA-256 correctos.")
