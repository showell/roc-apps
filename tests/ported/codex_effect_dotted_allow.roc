# effect-dotted-allow
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/effect-dotted-allow.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     result 42

app [main!] {}

# EffectDottedAllow -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

narrow : I64 => I64
narrow = |n| (n + 1)

caller : I64 => I64
caller = |n| narrow(n)

# --- Entry ---

main! = |_args| {
	line!(Str.concat("result ", I64.to_str(caller(41))))
	Ok({})
}
