# ops@unit-real-arith
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@unit-real-arith.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     add 4616189618054758400
#     addneg -4606732058837280358
#     sub -4616189618054758400
#     subneg -4614388178203810202
#     mul 4617315517961601024
#     mulneg -4606056518893174784
#     div 4612811918334230528
#     divneg -4610560118520545280
#     nestadd 4616189618054758400
#     nestmul 4617315517961601024
#     tadd 12
#     tsub 2

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# UnitRealArith -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Metre : F64
Span : Metre
Tick : I64

ma : Metre, Metre -> I64
ma = |a, b| U64.to_i64_wrap(F64.to_bits((a + b)))

ms : Metre, Metre -> I64
ms = |a, b| U64.to_i64_wrap(F64.to_bits((a - b)))

mm : Metre, Metre -> I64
mm = |a, b| U64.to_i64_wrap(F64.to_bits((a * b)))

md : Metre, Metre -> I64
md = |a, b| U64.to_i64_wrap(F64.to_bits((a / b)))

sa : Span, Span -> I64
sa = |a, b| U64.to_i64_wrap(F64.to_bits((a + b)))

sm : Span, Span -> I64
sm = |a, b| U64.to_i64_wrap(F64.to_bits((a * b)))

ta : Tick, Tick -> I64
ta = |a, b| (a + b)

ts : Tick, Tick -> I64
ts = |a, b| (a - b)

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("add ", CceText.show_int(ma(1.5, 2.5)))))
	line!(CceText.printed(CceText.concat("addneg ", CceText.show_int(ma((0.0 - 2.9), (0.0 - 1.5))))))
	line!(CceText.printed(CceText.concat("sub ", CceText.show_int(ms(1.5, 2.5)))))
	line!(CceText.printed(CceText.concat("subneg ", CceText.show_int(ms((0.0 - 2.9), (0.0 - 1.5))))))
	line!(CceText.printed(CceText.concat("mul ", CceText.show_int(mm(2.5, 2.0)))))
	line!(CceText.printed(CceText.concat("mulneg ", CceText.show_int(mm((0.0 - 2.5), 2.0)))))
	line!(CceText.printed(CceText.concat("div ", CceText.show_int(md(5.0, 2.0)))))
	line!(CceText.printed(CceText.concat("divneg ", CceText.show_int(md((0.0 - 5.0), 2.0)))))
	line!(CceText.printed(CceText.concat("nestadd ", CceText.show_int(sa(1.5, 2.5)))))
	line!(CceText.printed(CceText.concat("nestmul ", CceText.show_int(sm(2.5, 2.0)))))
	line!(CceText.printed(CceText.concat("tadd ", CceText.show_int(ta(7, 5)))))
	line!(CceText.printed(CceText.concat("tsub ", CceText.show_int(ts(7, 5)))))
	Ok({})
}
