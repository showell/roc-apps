# roc-early-return-predicate
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/roc-early-return-predicate.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     True

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# RocEarlyReturnPredicate -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

scan_for_two : List(I64), I64 -> Bool
scan_for_two = |xs, i| (if (i >= U64.to_i64_wrap(List.len(xs))) { False } else { (if ((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) == 2) { True } else { scan_for_two(xs, (i + 1)) }) })

# --- Entry ---

main! = |_args| {
	line!(Text.printed((if scan_for_two([1, 2, 3], 0) { "True" } else { "False" })))
	Ok({})
}
