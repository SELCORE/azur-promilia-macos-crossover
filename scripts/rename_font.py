"""Copy a TrueType font and give the copy a new family name.

The game asks Windows for fonts by family name (MiSans, Noto Sans S Chinese, Malgun Gothic).
Those fonts don't exist in the Wine prefix, so Korean text disappears. This makes a copy of a
Korean font that is already on the Mac, under the name the game asks for, for local use only.

usage: python3 -I rename_font.py <source.ttf> <dest.ttf> "<New Family>"
"""
import struct
import sys

src, dst, family = sys.argv[1], sys.argv[2], sys.argv[3]
data = bytearray(open(src, "rb").read())
if data[:4] not in (b"\x00\x01\x00\x00", b"true", b"OTTO"):
    raise SystemExit("not a single TrueType/OpenType font (use a .ttf/.otf, not a .ttc)")

num_tables = struct.unpack_from(">H", data, 4)[0]
tables = {}
for i in range(num_tables):
    tag, csum, off, length = struct.unpack_from(">4sIII", data, 12 + 16 * i)
    tables[tag] = (i, off, length)

postscript = "".join(c for c in family if c.isalnum()) + "-Regular"
names = {1: family, 2: "Regular", 3: family + " Regular", 4: family, 6: postscript, 16: family, 17: "Regular"}

# New 'name' table: Windows Unicode English (3,1,0x409) and Mac Roman (1,0,0) records.
records, strings = [], b""
for (pid, eid, lid, enc) in ((1, 0, 0, "mac_roman"), (3, 1, 0x409, "utf-16-be")):
    for nid in sorted(names):
        s = names[nid].encode(enc, errors="replace")
        records.append((pid, eid, lid, nid, len(s), len(strings)))
        strings += s
header = struct.pack(">HHH", 0, len(records), 6 + 12 * len(records))
body = b"".join(struct.pack(">HHHHHH", *r) for r in records)
name_table = header + body + strings


def checksum(b):
    b = b + b"\0" * ((4 - len(b) % 4) % 4)
    return sum(struct.unpack(">%dI" % (len(b) // 4), b)) & 0xFFFFFFFF


# Rebuild the font: same tables, 'name' replaced, all re-aligned.
order = sorted(tables, key=lambda t: tables[t][1])
dir_size = 12 + 16 * num_tables
out = bytearray(data[:12]) + bytearray(dir_size - 12)
entries = {}
for tag in order:
    _, off, length = tables[tag]
    blob = name_table if tag == b"name" else bytes(data[off:off + length])
    if tag == b"head":
        blob = blob[:8] + b"\0\0\0\0" + blob[12:]  # checkSumAdjustment recomputed below
    entries[tag] = (len(out), len(blob), checksum(blob))
    out += blob + b"\0" * ((4 - len(blob) % 4) % 4)
for i, tag in enumerate(sorted(tables)):  # directory must be sorted by tag
    off, length, csum = entries[tag]
    struct.pack_into(">4sIII", out, 12 + 16 * i, tag, csum, off, length)
head_off = entries[b"head"][0]
struct.pack_into(">I", out, head_off + 8, (0xB1B0AFBA - checksum(bytes(out))) & 0xFFFFFFFF)
open(dst, "wb").write(out)
print(f"{dst}: family '{family}'")
