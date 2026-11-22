#!/usr/bin/env python3
"""Syntax, manifest and runtime checks. Run from any working directory."""
from pathlib import Path
import os
import argparse
import subprocess
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--saved-variables", action="append", type=Path, default=[],
                    help="Optional saved settings file to read in isolation; never changed")
args = parser.parse_args()
for path in args.saved_variables:
    if not path.is_file():
        parser.error(f"Saved settings file not found: {path}")
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
bindings = ET.parse(ROOT / "Bindings.xml").getroot()
assert bindings.tag == "Bindings"
names = [node.get("name") for node in bindings]
assert all(names) and len(names) == len(set(names)), "Invalid or duplicate bindings"
for path in ROOT.rglob("*.lua"):
    subprocess.run(["luac5.1", "-p", str(path)], check=True)
print(f"Syntax OK. Manifest: {len(active)} Lua files, exact paths verified.", flush=True)
for client in ("retail", "forever"):
    print(f"Client profile: {client}", flush=True)
    environment = dict(os.environ, TONGUES_CLIENT=client)
    environment.pop("TONGUES_LOCALE", None)
    subprocess.run(["lua5.1", "tests/run.lua"], cwd=ROOT, env=environment, check=True)
    subprocess.run(["lua5.1", "tests/network.lua", *map(str, args.saved_variables)], cwd=ROOT, env=environment, check=True)
    for locale in ("deDE", "frFR", "esES", "esMX", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW"):
        subprocess.run(["lua5.1", "tests/run.lua"], cwd=ROOT, env=dict(environment, TONGUES_LOCALE=locale), check=True)
