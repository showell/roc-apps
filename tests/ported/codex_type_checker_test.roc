# type-checker-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/type-checker-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     42

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# TypeCheckerSmokeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

add_one : I64 -> I64
add_one = |x| (x + 1)

double : I64 -> I64
double = |x| (x * 2)

greet : Text -> Text
greet = |name| Text.concat(Text.concat("Hello, ", name), "!")

is_positive : I64 -> Bool
is_positive = |x| (x > 0)

apply_twice : (I64 -> I64), I64 -> I64
apply_twice = |f, x| f(f(x))

# --- Entry ---

main! = |_args| {
	line!(I64.to_str(apply_twice(add_one, 40)))
	Ok({})
}
