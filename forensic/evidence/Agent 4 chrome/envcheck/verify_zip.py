#!/usr/bin/env python3
"""verify_zip.py — independently check an `Agent 4 chrome.zip` archive against its own manifests.

    python3 verify_zip.py "/home/user/Agent 4 chrome.zip"

Checks performed:
  1. every zip entry extracts and its SHA-256 matches TIMELINE.csv (evidence rows) or
     ZIP_METADATA.json `generated_files` (the three build outputs, which cannot self-hash)
  2. no file listed in the timeline is missing from the archive, and none is present but unlisted
  3. byte counts agree
  4. `unzip -t` CRC check (if the binary is available) as a second opinion
Exit 0 = archive is internally consistent and complete.
"""
import csv, hashlib, io, json, os, subprocess, sys, zipfile

ZP = sys.argv[1] if len(sys.argv) > 1 else "/home/user/Agent 4 chrome.zip"
# archive name at root  ->  workspace path it was copied from
ALIASES = {"README_START_HERE.md": "envcheck/BUNDLE_README.md", "TIMELINE.csv": "envcheck/TIMELINE.csv",
           "ZIP_METADATA.json": "envcheck/ZIP_METADATA.json", "PROMPTS.md": "envcheck/PROMPTS.md"}


def sha_bytes(b):
    return hashlib.sha256(b).hexdigest()


def main():
    if not os.path.isfile(ZP):
        sys.exit(f"no such archive: {ZP}")
    print(f"verifying {ZP}  ({os.path.getsize(ZP):,} bytes)")
    with zipfile.ZipFile(ZP) as z:
        names = z.namelist()
        data = {n: z.read(n) for n in names if not n.endswith("/")}
    print(f"  entries: {len(names)}   files readable: {len(data)}")

    def get(ws_path):
        """bytes for a workspace path, following the root-alias convention used by the builder"""
        for n in data:
            if n == ws_path or ALIASES.get(n) == ws_path:
                return data[n]
        return None

    # pull the two manifests out of the archive itself (not the workspace) so we verify the archive
    tl_raw = get("envcheck/TIMELINE.csv")
    meta_raw = get("envcheck/ZIP_METADATA.json")
    if not tl_raw or not meta_raw:
        sys.exit("  FAIL: TIMELINE.csv or ZIP_METADATA.json missing from archive")
    rows = [r for r in csv.DictReader(io.StringIO(tl_raw.decode())) if r.get("path") and not r["path"].startswith("#")]
    meta = json.loads(meta_raw.decode())
    gen = {g["path"]: g["sha256"] for g in meta.get("generated_files", [])}
    print(f"  timeline rows: {len(rows)}   generated-file hashes in metadata: {len(gen)}")

    ok = bad = miss = 0
    for r in rows:
        blob = get(r["path"])
        if blob is None:
            miss += 1
            print(f"  MISSING  {r['path']}")
            continue
        h = sha_bytes(blob)
        if h == r["sha256"]:
            ok += 1
        else:
            bad += 1
            print(f"  MISMATCH {r['path']}  expected {r['sha256'][:16]}.. got {h[:16]}..")
        if int(r["bytes"]) != len(blob):
            bad += 1
            print(f"  SIZE     {r['path']}  listed {r['bytes']} actual {len(blob)}")
    for path, want in gen.items():
        blob = get(path)
        if blob is None or sha_bytes(blob) != want:
            bad += 1
            print(f"  MISMATCH {path} (generated)")
        else:
            ok += 1
    listed = {r["path"] for r in rows} | set(gen) | {"envcheck/ZIP_METADATA.json"}
    listed_ws = {(ALIASES.get(n, n)) for n in data}
    unlisted = sorted(listed_ws - listed)
    print(f"  hashes verified: {ok}   mismatches: {bad}   missing: {miss}")
    if unlisted:
        print(f"  present in archive but unlisted: {len(unlisted)} -> {unlisted[:5]}")

    r = subprocess.run(["unzip", "-t", ZP], capture_output=True, text=True)
    if r.returncode == 0:
        print("  unzip -t: no errors detected in compressed data")
    else:
        print("  unzip -t: FAILED", r.stdout.splitlines()[-1] if r.stdout else "")
    verdict = (bad == 0 and miss == 0 and not unlisted and r.returncode == 0)
    print(f"=== {'PASS' if verdict else 'FAIL'}: {'every file in the archive matches its recorded hash and size' if verdict else 'see problems above'} ===")
    return 0 if verdict else 1


if __name__ == "__main__":
    raise SystemExit(main())
