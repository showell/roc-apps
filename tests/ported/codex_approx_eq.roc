# approx-eq
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/approx-eq.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     approx-same: PASS
#     approx-zero: PASS
#     approx-far: PASS
#     exact-same: PASS
#     exact-zero: PASS
#     exact-far: PASS

app [main!] { cdx: "./codex/main.roc" }

import cdx.Prelude
import cdx.Text

# ApproxEq -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

check! : List(U8), Bool => {}
check! = |label, result| ({
	line!(Text.printed(List.concat(List.concat(label, [69, 2]), (if result { [57, 41, 45, 45] } else { [54, 41, 43, 49] }))))
})

# --- Entry ---

main! = |_args| {
	check!([15, 31, 31, 21, 16, 36, 73, 19, 15, 26, 13], Prelude.approx_eq(1.0, 1.0))
	check!([15, 31, 31, 21, 16, 36, 73, 38, 13, 21, 16], Prelude.approx_eq(0.0, 0.0))
	check!([15, 31, 31, 21, 16, 36, 73, 28, 15, 21], (if Prelude.approx_eq(1.0, 2.0) { False } else { True }))
	check!([13, 36, 15, 24, 14, 73, 19, 15, 26, 13], (F64.to_bits(1.0) == F64.to_bits(1.0)))
	check!([13, 36, 15, 24, 14, 73, 38, 13, 21, 16], (F64.to_bits(0.0) == F64.to_bits(0.0)))
	check!([13, 36, 15, 24, 14, 73, 28, 15, 21], (if (F64.to_bits(1.0) == F64.to_bits(2.0)) { False } else { True }))
	Ok({})
}
