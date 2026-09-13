#!/usr/bin/env python3
# Which builtin asked for each allocation, from an strace trace with stacks:
#
#   strace -f -k -e trace=mmap -o trace basic-run micro "<listing>" "<replies>"
#   basic/stacks.py trace
#
# On Roc's default platform every heap allocation is an mmap call, and its
# stack (the " > " lines after it) names the builtin that asked for it:
# roc_builtins_str_to_utf8, roc_builtins_list_reserve, and so on. Each call is
# counted once, under the first builtin on its stack.
import collections
import re
import sys

for path in sys.argv[1:]:
    calls = 0
    counts = collections.Counter()
    frames = None

    def settle():
        global frames
        if frames is None:
            return
        name = "(no named builtin)"
        for f in frames:
            m = re.search(r"(roc_builtins_[a-z_0-9]+|dev_wrappers\.[a-z_0-9]+)", f)
            if m:
                name = m.group(1)
                break
        counts[name] += 1
        frames = None

    for line in open(path):
        if line.startswith(" > "):
            if frames is not None:
                frames.append(line)
        else:
            settle()
            if re.match(r"^\d+\s+mmap\(", line):
                calls += 1
                frames = []
    settle()
    print(f"{path}: {calls} mmap calls")
    for name, n in counts.most_common(12):
        print(f"  {n:7d}  {name}")
