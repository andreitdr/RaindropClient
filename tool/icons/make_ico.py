#!/usr/bin/env python3
"""Packs square PNGs into a Windows .ico (PNG-compressed entries, Vista and later).

Usage: make_ico.py <out.ico> <png>...   (each PNG's size is read from its header)
"""
import struct
import sys


def main():
    out, pngs = sys.argv[1], sys.argv[2:]
    blobs = [open(p, "rb").read() for p in pngs]
    header = struct.pack("<HHH", 0, 1, len(blobs))
    offset = 6 + 16 * len(blobs)
    entries = b""
    for blob in blobs:
        width, height = struct.unpack(">II", blob[16:24])
        # 256 is written as 0.
        entries += struct.pack("<BBBBHHII", width % 256, height % 256, 0, 0, 1, 32, len(blob), offset)
        offset += len(blob)
    with open(out, "wb") as f:
        f.write(header + entries + b"".join(blobs))


if __name__ == "__main__":
    main()
