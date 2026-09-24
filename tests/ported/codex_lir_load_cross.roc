# lir-load-cross
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lir-load-cross.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     75
#     42
#     0
#     5
#     6
#     0
#     7
#     0
#     10
#     1
#     607
#     2
#     7
#     3
#     41

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# LirLoadCross -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Shape : [Circle(I64), Rect(I64, I64), Dot]
Packed : [Bytes(I64, I64), Big(I64)]

sh_area : Shape -> I64
sh_area = |s| (match s {
	Circle(r) => ((r * r) * 3)
	Rect(w, h) => (w * h)
	Dot => 0
})

sh_first : Shape -> I64
sh_first = |s| (match s {
	Circle(r) => r
	Rect(w, _h) => w
	Dot => 0
})

sh_second : Shape -> I64
sh_second = |s| (match s {
	Rect(_w, h) => h
	_ => 0
})

sh_twice : Shape -> I64
sh_twice = |s| (match s {
	Circle(r) => (r + r)
	_ => 1
})

sh_both : Shape -> I64
sh_both = |s| (match s {
	Rect(w, h) => ((w * 100) + h)
	_ => 2
})

pk_lo : Packed -> I64
pk_lo = |p| (match p {
	Bytes(a, _b) => a
	Big(n) => n
})

pk_hi : Packed -> I64
pk_hi = |p| (match p {
	Bytes(_a, b) => b
	Big(n) => n
})

eq_Shape : Shape, Shape -> Bool
eq_Shape = |ex, ey| (match ex {
	Circle(exf0) => (match ey {
		Circle(eyf0) => (exf0 == eyf0)
		_ => False
	})
	Rect(exf0, exf1) => (match ey {
		Rect(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
	Dot => (match ey {
		Dot => True
		_ => False
	})
})

eq_Packed : Packed, Packed -> Bool
eq_Packed = |ex, ey| (match ex {
	Bytes(exf0, exf1) => (match ey {
		Bytes(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
	Big(exf0) => (match ey {
		Big(eyf0) => (exf0 == eyf0)
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.show_int(sh_area(Circle(5)))))
	line!(CceText.printed(CceText.show_int(sh_area(Rect(6, 7)))))
	line!(CceText.printed(CceText.show_int(sh_area(Dot))))
	line!(CceText.printed(CceText.show_int(sh_first(Circle(5)))))
	line!(CceText.printed(CceText.show_int(sh_first(Rect(6, 7)))))
	line!(CceText.printed(CceText.show_int(sh_first(Dot))))
	line!(CceText.printed(CceText.show_int(sh_second(Rect(6, 7)))))
	line!(CceText.printed(CceText.show_int(sh_second(Circle(5)))))
	line!(CceText.printed(CceText.show_int(sh_twice(Circle(5)))))
	line!(CceText.printed(CceText.show_int(sh_twice(Rect(6, 7)))))
	line!(CceText.printed(CceText.show_int(sh_both(Rect(6, 7)))))
	line!(CceText.printed(CceText.show_int(sh_both(Circle(5)))))
	line!(CceText.printed(CceText.show_int(pk_lo(Bytes(7, 3)))))
	line!(CceText.printed(CceText.show_int(pk_hi(Bytes(7, 3)))))
	line!(CceText.printed(CceText.show_int(pk_lo(Big(41)))))
	Ok({})
}
