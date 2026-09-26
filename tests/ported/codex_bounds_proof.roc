# bounds-proof
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/bounds-proof.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     42
#     100
#     300
#     18
#     52
#     240
#     232
#     18
#     10
#     150

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Prelude

# BoundsProof -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Byte := { val : I64 }.{
	is_eq : Byte, Byte -> Bool
	is_eq = |a, b| eq_Byte(a, b)
}
Wide := { val : I64 }.{
	is_eq : Wide, Wide -> Bool
	is_eq = |a, b| eq_Wide(a, b)
}

byte0 : Byte
byte0 = Byte.{ val: 0 }

wide0 : Wide
wide0 = Wide.{ val: 0 }

test_literal : I64
test_literal = ({
	b = { ..byte0, val: 42 }
	b.val
})

test_field : I64
test_field = ({
	a = Byte.{ val: 100 }
	w = { ..wide0, val: a.val }
	w.val
})

test_add : I64
test_add = ({
	a = Byte.{ val: 100 }
	b = Byte.{ val: 200 }
	w = { ..wide0, val: (a.val + b.val) }
	w.val
})

test_div : I64
test_div = ({
	w = Wide.{ val: 4660 }
	b = { ..byte0, val: I64.div_trunc_by(w.val, 256) }
	b.val
})

test_mod : I64
test_mod = ({
	w = Wide.{ val: 4660 }
	b = { ..byte0, val: Prelude.int_mod(w.val, 256) }
	b.val
})

test_mul : I64
test_mul = ({
	b = Byte.{ val: 120 }
	w = { ..wide0, val: (b.val * 2) }
	w.val
})

test_bitand : I64
test_bitand = ({
	w = Wide.{ val: 1000 }
	b = { ..byte0, val: I64.bitwise_and(w.val, 255) }
	b.val
})

test_shru : I64
test_shru = ({
	w = Wide.{ val: 4660 }
	b = { ..byte0, val: I64.shr_zf_wrap(w.val, I64.to_u8_wrap(8)) }
	b.val
})

test_if : I64
test_if = ({
	x : I64
	x = 7
	(if (x > 5) { 10 } else { 20 })
})

test_sub : I64
test_sub = ({
	a = Byte.{ val: 200 }
	b = Byte.{ val: 50 }
	(a.val - b.val)
})

eq_Byte : Byte, Byte -> Bool
eq_Byte = |ex, ey| (ex.val == ey.val)

eq_Wide : Wide, Wide -> Bool
eq_Wide = |ex, ey| (ex.val == ey.val)

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.show_int(test_literal)))
	line!(CceText.printed(CceText.show_int(test_field)))
	line!(CceText.printed(CceText.show_int(test_add)))
	line!(CceText.printed(CceText.show_int(test_div)))
	line!(CceText.printed(CceText.show_int(test_mod)))
	line!(CceText.printed(CceText.show_int(test_mul)))
	line!(CceText.printed(CceText.show_int(test_bitand)))
	line!(CceText.printed(CceText.show_int(test_shru)))
	line!(CceText.printed(CceText.show_int(test_if)))
	line!(CceText.printed(CceText.show_int(test_sub)))
	Ok({})
}
