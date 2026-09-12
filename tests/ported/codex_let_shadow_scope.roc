# let-shadow-scope
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/let-shadow-scope.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     9

app [main!] {}

# LetShadowScope -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

shadowed : I64 -> I64
shadowed = |n| ({
	v = n
	inner = (if (n > 0) { ({
		v_1 = (n * 3)
		(v_1 + 1)
	}) } else { v })
	(inner + v)
})

# --- Entry ---

main! = |_args| {
	line!(I64.to_str(shadowed(2)))
	Ok({})
}
