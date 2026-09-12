# when-bool-cross
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/when-bool-cross.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     spin2: 150
#     spin3: 150
#     cross: 115
#     frm: 150

app [main!] {}

# WhenBoolCross -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

spin2 : I64, I64 -> I64
spin2 = |n, acc| (if (n == 0) { acc } else { ({
	a = (n - 1)
	b = (acc + 10)
	c = (a + 0)
	d = (b + 0)
	spin2(c, d)
}) })

spin3 : I64, I64, I64 -> I64
spin3 = |n, acc, k| (if (n == 0) { acc } else { ({
	a = (n - 1)
	b = (acc + 10)
	c = (a + 0)
	d = (b + 0)
	spin3(c, d, k)
}) })

cross : I64, I64 -> I64
cross = |n, acc| (if (n == 0) { acc } else { cross((n - 1), (acc + n)) })

frm : I64, I64 -> I64
frm = |n, acc| (match (n == 0) {
	True => acc
	False => frm((n - 1), (acc + 10))
})

# --- Entry ---

main! = |_args| {
	line!(Str.concat("spin2: ", I64.to_str(spin2(5, 100))))
	line!(Str.concat("spin3: ", I64.to_str(spin3(5, 100, 0))))
	line!(Str.concat("cross: ", I64.to_str(cross(5, 100))))
	line!(Str.concat("frm: ", I64.to_str(frm(5, 100))))
	Ok({})
}
