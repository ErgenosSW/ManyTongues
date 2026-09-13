#!/usr/bin/env python3
"""Syntax, manifest and runtime checks. Run from any working directory."""
from pathlib import Path
import os
import subprocess
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
active = []

def walk(path):
    assert path.is_file(), f"Missing manifest entry (case-sensitive): {path}"
    assert path.resolve().is_relative_to(ROOT), f"Path leaves addon: {path}"
    if path.suffix.lower() == ".xml":
        for node in ET.parse(path).getroot().iter():
            if node.tag.rsplit("}", 1)[-1] in ("Script", "Include") and node.get("file"):
                walk(path.parent / node.get("file").replace("\\", "/"))
    elif path.suffix.lower() == ".lua":
        active.append(path)

for entry in (ROOT / "Tongues.toc").read_text().splitlines():
    if entry.strip() and not entry.lstrip().startswith("#"):
        walk(ROOT / entry.strip().replace("\\", "/"))
assert len(active) == len(set(active)), "Duplicate script load"
for path in ROOT.rglob("*.lua"):
    subprocess.run(["luac5.1", "-p", str(path)], check=True)
print(f"Syntax OK. Manifest: {len(active)} Lua files, exact paths verified.", flush=True)
subprocess.run(["lua5.1", "tests/run.lua"], cwd=ROOT, check=True)
for locale in ("deDE", "frFR", "esES", "esMX", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW"):
    subprocess.run(["lua5.1", "tests/run.lua"], cwd=ROOT, env=dict(os.environ, TONGUES_LOCALE=locale), check=True)
