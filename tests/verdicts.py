#!/usr/bin/env python3
"""Clean the verdicts once, into a copy we own.

    tests/verdicts.py            writes ~/build/roc-apps/gen/verdicts/
    tests/verdicts.py --report   says what it would change, writes nothing

Three kinds of byte in codex/test's .expected files are the console
capture's and not the program's, and Cobblestone's own harness strips the
first two (build/test.ps1: the run output is `-replace "\\r", '' -replace
"^\\x01", ''` and the expected is `-replace "\\r", ''`):

  * a leading 0x01, in 164 of the 1,516 files, always exactly one, at byte 0;
  * carriage returns, in 81 of them, always at a line end;
  * a trailing EMPTY LINE, which the capture drops: a program that ends by
    printing a blank line has it in the middle of its verdict and not at
    the end, so both sides are stripped of trailing blanks.

No Codex source in the corpus prints either of the first two: none holds a
\\r escape and none writes character code 1. Doing this ONCE here rather
than inside the diff means the ladder compares bytes with cmp, and this is
the only place that touches a verdict.

One pass in Python rather than four processes a file: at 1,516 files the
shell version was seventeen seconds of every ladder run.
"""
import os, sys, pathlib

ROOT = os.environ.get("TESTS_ROOT", os.path.expanduser("~/showell_repos/cobblestone-u61"))
SRC = pathlib.Path(ROOT) / "codex/test"
OUT = pathlib.Path(os.path.expanduser("~/build/roc-apps/gen/verdicts"))
report_only = "--report" in sys.argv

soh = cr = blank = 0
files = sorted(SRC.rglob("*.expected"))
if not report_only:
    OUT.mkdir(parents=True, exist_ok=True)
for f in files:
    raw = f.read_bytes()
    if raw[:1] == b"\x01":
        soh += 1
        raw = raw[1:]
    if b"\r" in raw:
        cr += 1
        raw = raw.replace(b"\r", b"")
    stripped = raw.rstrip(b"\n")
    if stripped != raw.rstrip(b"\n") + b"":
        pass
    if raw.endswith(b"\n\n"):
        blank += 1
    raw = stripped + b"\n" if stripped else raw
    if not report_only:
        (OUT / str(f.relative_to(SRC)).replace("/", "@")).write_bytes(raw)
print(f"{len(files)} verdicts: {soh} carry a leading 0x01, {cr} carry carriage returns, {blank} a trailing blank line")
if not report_only:
    print(f"cleaned into {OUT}")
