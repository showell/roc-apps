# real-literal-boundary
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/real-literal-boundary.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     whole-19-parses : 123456789012345680
#     frac-19-parses  : 2

app [main!] {}

# RealLiteralBoundary -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

frac_nineteen : F64
frac_nineteen = 1.1234567890123457

whole_nineteen : F64
whole_nineteen = F64.from_bits(4862596447618666293)

# --- Entry ---

main! = |_args| {
	line!(Str.concat("whole-19-parses : ", I64.to_str(F64.to_i64_wrap(whole_nineteen))))
	line!(Str.concat("frac-19-parses  : ", I64.to_str(F64.to_i64_wrap((frac_nineteen + frac_nineteen)))))
	Ok({})
}
