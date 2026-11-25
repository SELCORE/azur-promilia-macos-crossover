"""Extract a zip whose entry names use Windows backslashes (e.g. the Nexon Plug payload).

macOS `unzip`/`ditto` keep backslashes as part of the file name, so folders end up flattened.
This converts them to real folders and refuses entries that would escape the destination.

usage: python3 -I extract_zip.py <archive.zip> <destination-folder>
"""
import os
import sys
import zipfile

src, dest = sys.argv[1], sys.argv[2]
dest = os.path.realpath(dest)
count = 0
with zipfile.ZipFile(src) as archive:
    for info in archive.infolist():
        rel = info.filename.replace("\\", "/")
        out = os.path.realpath(os.path.join(dest, rel))
        if not out.startswith(dest + os.sep):
            raise SystemExit(f"unsafe path in archive: {info.filename}")
        if rel.endswith("/"):
            os.makedirs(out, exist_ok=True)
            continue
        os.makedirs(os.path.dirname(out), exist_ok=True)
        with archive.open(info) as fi, open(out, "wb") as fo:
            while chunk := fi.read(1 << 20):
                fo.write(chunk)
        count += 1
print(f"extracted {count} files")
