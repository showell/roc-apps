# bounds-prover
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/bounds-prover.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     42
#     250
#     70
#     80
#     50
#     232
#     232
#     50
#     75

app [main!] { cdx: "./codex/main.roc" }

import cdx.Prelude
import cdx.Text

# BoundsProver -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Byte : { val : I64 }
Pct : { val : I64 }
Small : { val : I64 }

from_literal : Byte
from_literal = { val: 42 }

from_add : I64, I64 -> Small
from_add = |a, b| ({
	x = { val: a }
	y = { val: b }
	{ val: (x.val + y.val) }
})

from_sub : I64 -> Pct
from_sub = |a| ({
	x = { val: a }
	{ val: (100 - x.val) }
})

from_mul : I64 -> Small
from_mul = |a| ({
	x = { val: a }
	{ val: (x.val * 10) }
})

from_div : I64 -> Pct
from_div = |a| ({
	x = { val: a }
	{ val: I64.div_trunc_by(x.val, 10) }
})

from_mod : I64 -> Byte
from_mod = |a| { val: Prelude.int_mod(a, 256) }

from_bitand : I64 -> Byte
from_bitand = |a| { val: I64.bitwise_and(a, 255) }

from_if : I64 -> Byte
from_if = |a| { val: (if (a > 100) { 100 } else { a }) }

from_negate : I64 -> Small
from_negate = |a| ({
	x = { val: a }
	{ val: (-(-x.val)) }
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.show_int(from_literal.val)))
	line!(Text.printed(Text.show_int(from_add(100, 150).val)))
	line!(Text.printed(Text.show_int(from_sub(30).val)))
	line!(Text.printed(Text.show_int(from_mul(8).val)))
	line!(Text.printed(Text.show_int(from_div(500).val)))
	line!(Text.printed(Text.show_int(from_mod(1000).val)))
	line!(Text.printed(Text.show_int(from_bitand(1000).val)))
	line!(Text.printed(Text.show_int(from_if(50).val)))
	line!(Text.printed(Text.show_int(from_negate(75).val)))
	Ok({})
}
