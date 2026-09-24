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

import cdx.CceText
import cdx.Prelude

# ApproxEq -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

check! : CceText, Bool => {}
check! = |label, result| ({
	line!(CceText.printed(CceText.concat(CceText.concat(label, ": "), (if result { "PASS" } else { "FAIL" }))))
})

# --- Entry ---

main! = |_args| {
	check!("approx-same", Prelude.approx_eq(1.0, 1.0))
	check!("approx-zero", Prelude.approx_eq(0.0, 0.0))
	check!("approx-far", (if Prelude.approx_eq(1.0, 2.0) { False } else { True }))
	check!("exact-same", (F64.to_bits(1.0) == F64.to_bits(1.0)))
	check!("exact-zero", (F64.to_bits(0.0) == F64.to_bits(0.0)))
	check!("exact-far", (if (F64.to_bits(1.0) == F64.to_bits(2.0)) { False } else { True }))
	Ok({})
}
