# if-in-arith
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/if-in-arith.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     72
#     68
#     76

app [main!] {}

# IfInArith -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

perm : Bool, Bool -> I64
perm = |w, r| ((64 + (if w { 8 } else { 0 })) + (if r { 4 } else { 0 }))

# --- Entry ---

main! = |_args| {
	line!(I64.to_str(perm(True, False)))
	line!(I64.to_str(perm(False, True)))
	line!(I64.to_str(perm(True, True)))
	Ok({})
}
