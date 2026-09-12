# rv-big-literal
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/rv-big-literal.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     at-boundary want 9223372034707292159 got 9223372034707292159
#     past-boundary want 9223372034707292160 got 9223372034707292160
#     max want 9223372036854775807 got 9223372036854775807
#     max-1 want 9223372036854775806 got 9223372036854775806
#     min want -9223372036854775808 got -9223372036854775808
#     allf want -1 got -1
#     just-over-32 want 2147483648 got 2147483648
#     top-of-32 want 2147483647 got 2147483647
#     bottom-of-32 want -2147483648 got -2147483648
#     under-32 want -2147483649 got -2147483649

app [main!] {}

# RvBigLiteral -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Str.concat("at-boundary want 9223372034707292159 got ", I64.to_str(9223372034707292159)))
	line!(Str.concat("past-boundary want 9223372034707292160 got ", I64.to_str(9223372034707292160)))
	line!(Str.concat("max want 9223372036854775807 got ", I64.to_str(9223372036854775807)))
	line!(Str.concat("max-1 want 9223372036854775806 got ", I64.to_str(9223372036854775806)))
	line!(Str.concat("min want -9223372036854775808 got ", I64.to_str((-9223372036854775808))))
	line!(Str.concat("allf want -1 got ", I64.to_str((-1))))
	line!(Str.concat("just-over-32 want 2147483648 got ", I64.to_str(2147483648)))
	line!(Str.concat("top-of-32 want 2147483647 got ", I64.to_str(2147483647)))
	line!(Str.concat("bottom-of-32 want -2147483648 got ", I64.to_str((0 - 2147483648))))
	line!(Str.concat("under-32 want -2147483649 got ", I64.to_str((0 - 2147483649))))
	Ok({})
}
