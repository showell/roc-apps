# ops@real-to-int-wide
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@real-to-int-wide.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     three-bil    3000000000
#     ten-bil      10000000000
#     one-tril     1000000000000
#     neg-three    -3000000000
#     at-2p31-less 2147483647
#     at-2p31      2147483648
#     roundtrip    3000000000
#     approx-wide  3000000000
#     show-real    3000000000.5

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Prelude

# RealToIntWide -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("three-bil    ", CceText.show_int(F64.to_i64_wrap(3000000000.0)))))
	line!(CceText.printed(CceText.concat("ten-bil      ", CceText.show_int(F64.to_i64_wrap(10000000000.0)))))
	line!(CceText.printed(CceText.concat("one-tril     ", CceText.show_int(F64.to_i64_wrap(1000000000000.0)))))
	line!(CceText.printed(CceText.concat("neg-three    ", CceText.show_int(F64.to_i64_wrap((0.0 - 3000000000.0))))))
	line!(CceText.printed(CceText.concat("at-2p31-less ", CceText.show_int(F64.to_i64_wrap(2147483647.0)))))
	line!(CceText.printed(CceText.concat("at-2p31      ", CceText.show_int(F64.to_i64_wrap(2147483648.0)))))
	line!(CceText.printed(CceText.concat("roundtrip    ", CceText.show_int(F64.to_i64_wrap(I64.to_f64(3000000000))))))
	line!(CceText.printed(CceText.concat("approx-wide  ", CceText.show_int(F32.to_i64_wrap(F64.to_f32_wrap(3000000000.0))))))
	line!(CceText.printed(CceText.concat("show-real    ", CceText.of_str(Prelude.real_to_str(3000000000.5)))))
	Ok({})
}
