#!/usr/bin/env python3
"""Shrink a file that makes `roc check` spin, keeping it spinning.

    findings/roc-check-hang/reduce.py hang.roc [seconds]

Greedy delta debugging over lines, then over a few textual shapes: a
removal is kept only when the file still fails to finish inside the
timeout, so every step preserves the thing being reported. Writes
`smallest.roc` and a log as it goes, so the run can be read while it is
still going.
"""
import os, subprocess, sys, time

ROC = os.environ.get("ROC", os.path.expanduser("~/build/roc-nightly/roc"))
HERE = os.path.dirname(os.path.abspath(__file__))
src = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "hang.roc")
LIMIT = int(sys.argv[2]) if len(sys.argv) > 2 else 15
work = os.path.join(HERE, "_try.roc")
log = open(os.path.join(HERE, "reduce.log"), "w", buffering=1)


def spins(text):
    open(work, "w").write(text)
    try:
        subprocess.run([ROC, "check", "--no-cache", work], capture_output=True, timeout=LIMIT)
        return False
    except subprocess.TimeoutExpired:
        return True


def keep(text, why):
    open(os.path.join(HERE, "smallest.roc"), "w").write(text)
    log.write(f"{len(text.splitlines()):4} lines {len(text):6} bytes  after {why}\n")


text = open(src).read()
if not spins(text):
    log.write("the starting file does not spin; nothing to reduce\n")
    sys.exit(1)
keep(text, "start")

# 1. whole lines
changed = True
while changed:
    changed = False
    i = 0
    while True:
        lines = text.split("\n")
        if i >= len(lines):
            break
        trial = "\n".join(lines[:i] + lines[i + 1:])
        if trial.strip() and spins(trial):
            text = trial
            keep(text, f"dropping line {i + 1}")
            changed = True
        else:
            i += 1

# 2. shapes: a record field, an unused type, a call's argument
shapes = [
    (", winner : I64", ""), (", moves : I64", ""), (", draws : I64", ""), (", losses : I64", ""),
    (", wins : I64", ""), (", current_player : I64", ""), ("squares : List(I64), ", ""),
    (", winner: 0", ""), (", moves: 0", ""), (", draws: 0", ""), (", losses: 0", ""), (", wins: 0", ""),
    (", current_player: 1", ""), ("squares: [0, 0, 0, 0, 0, 0, 0, 0, 0], ", ""),
    ("I64.to_str(as_x.paths)", '"x"'), ("ttt_perfect_ai(b)", "0"), ("ttt_move(b, 0)", "b"),
]
changed = True
while changed:
    changed = False
    for old, new in shapes:
        if old in text:
            trial = text.replace(old, new)
            if spins(trial):
                text = trial
                keep(text, f"replacing {old.strip()!r}")
                changed = True

log.write("done\n")
print(open(os.path.join(HERE, "smallest.roc")).read())
