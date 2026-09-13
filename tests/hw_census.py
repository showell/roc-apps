#!/usr/bin/env python3
"""Which hardware-refused units ever RUN a hardware call?

    tests/hw_census.py tests/ledger.txt <checkout>/codex/test ~/build/rust-target/release/codexrun

rocemit refuses a unit whose emitted chapters MENTION a hardware builtin, and
it emits chapters whole. codexrun has no rule for these builtins either, but it
fails only when a call is executed. So running each refused unit on codexrun
sorts it: the program reached the hardware; or it finished and printed its
verdict, so the hardware sat in a definition it never called; or it failed
for another reason.
"""
import collections
import pathlib
import re
import subprocess
import sys

HARDWARE = re.compile(r"builtin `([A-Za-z0-9_-]+)`")


def main():
    ledger, tests, codexrun = sys.argv[1], pathlib.Path(sys.argv[2]), sys.argv[3]
    rows = []
    for line in open(ledger):
        if not line.startswith("REFUSED") or "builtin `" not in line:
            continue
        name = line.split()[1]
        builtin = HARDWARE.search(line).group(1)
        rows.append((name, builtin))
    tally = collections.defaultdict(collections.Counter)
    for name, builtin in rows:
        src = tests / (name.replace("@", "/") + ".codex")
        exp = src.with_suffix(".expected")
        try:
            r = subprocess.run([codexrun, str(src)], capture_output=True, timeout=60)
            out = r.stdout.decode("utf-8", "replace")
            err = r.stderr.decode("utf-8", "replace")
            if r.returncode == 0:
                want = exp.read_bytes().decode("utf-8", "replace").replace("\r", "").lstrip("\x01") if exp.is_file() else None
                kind = "finished, matches" if want is not None and out.rstrip("\n") == want.rstrip("\n") else "finished, differs"
            else:
                m = re.search(r"builtin `([A-Za-z0-9_-]+)` has no rule", err)
                kind = f"reached `{m.group(1)}`" if m else "failed otherwise: " + (err.strip().splitlines() or ["?"])[0][:60]
        except subprocess.TimeoutExpired:
            kind = "timed out at 60 s"
        tally[builtin][kind] += 1
        print(f"{name:<40} {builtin:<22} {kind}", flush=True)
    print()
    for builtin, kinds in sorted(tally.items(), key=lambda kv: -sum(kv[1].values())):
        print(f"{builtin:<22} {sum(kinds.values()):>3}  " + "; ".join(f"{k} {n}" for k, n in kinds.most_common()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
