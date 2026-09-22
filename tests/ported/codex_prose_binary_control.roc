# prose-binary-control
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/prose-binary-control.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     2004

app [main!] {}

# ProseBinaryControl -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

ordinary : I64 -> I64
ordinary = |n| ((n + 1) + 1000)

extra : I64
extra = 1000

unchanged : I64 -> I64
unchanged = |n| (n + 1)

# --- Entry ---

main! = |_args| {
	line!(I64.to_str(((ordinary(1) + extra) + unchanged(1))))
	Ok({})
}
