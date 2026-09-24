# forewords@core-bigint
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@core-bigint.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     12345
#     10000
#     99980001
#     -42
#     3628800
#     -1

app [main!] { cdx: "./codex/main.roc" }

import cdx.BigInt
import cdx.Text

# FwdBigIntTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

test_from_int : Text
test_from_int = ({
	a = BigInt.bigint_from_integer(12345)
	BigInt.bigint_to_text(a)
})

test_add : Text
test_add = ({
	a = BigInt.bigint_from_integer(9999)
	b = BigInt.bigint_from_integer(1)
	BigInt.bigint_to_text(BigInt.bigint_add(a, b))
})

test_mul : Text
test_mul = ({
	a = BigInt.bigint_from_integer(9999)
	b = BigInt.bigint_from_integer(9999)
	BigInt.bigint_to_text(BigInt.bigint_mul(a, b))
})

test_negate : Text
test_negate = ({
	a = BigInt.bigint_from_integer(42)
	BigInt.bigint_to_text(BigInt.bigint_negate(a))
})

test_factorial : Text
test_factorial = BigInt.bigint_to_text(BigInt.bigint_factorial(10))

test_compare : Text
test_compare = ({
	a = BigInt.bigint_from_integer(100)
	b = BigInt.bigint_from_integer(200)
	Text.show_int(BigInt.bigint_compare(a, b))
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(test_from_int))
	line!(Text.printed(test_add))
	line!(Text.printed(test_mul))
	line!(Text.printed(test_negate))
	line!(Text.printed(test_factorial))
	line!(Text.printed(test_compare))
	Ok({})
}
