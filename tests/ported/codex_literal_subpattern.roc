# literal-subpattern
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/literal-subpattern.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     int-0 10
#     int-1 11
#     int-7 17
#     int-n 19
#     txt-sin 20
#     txt-cos 21
#     txt-oth 29
#     flag-t 30
#     flag-f 31
#     pair-0 40
#     pair-hit 41
#     pair-oth 42
#     bare-0 50
#     bare-1 51
#     bare-n 59
#     bare-sin 60
#     bare-cos 61
#     bare-oth 69
#     done

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# LiteralSubpattern -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Box_ : [BInt(I64), BText(CceText), BFlag(Bool), BPair(I64, CceText), BNone]

by_int : Box_ -> I64
by_int = |b| (match b {
	BInt(0) => 10
	BInt(1) => 11
	BInt(7) => 17
	BInt(_n) => 19
	_ => 99
})

by_text : Box_ -> I64
by_text = |b| (match b {
	BText("sin") => 20
	BText("cos") => 21
	BText(_s) => 29
	_ => 99
})

by_flag : Box_ -> I64
by_flag = |b| (match b {
	BFlag(True) => 30
	BFlag(False) => 31
	_ => 99
})

by_pair : Box_ -> I64
by_pair = |b| (match b {
	BPair(0, _s) => 40
	BPair(_n, "hit") => 41
	BPair(_n, _s) => 42
	_ => 99
})

bare_int : I64 -> I64
bare_int = |n| (match n {
	0 => 50
	1 => 51
	_ => 59
})

bare_text : CceText -> I64
bare_text = |t| (match t {
	"sin" => 60
	"cos" => 61
	_ => 69
})

eq_Box : Box_, Box_ -> Bool
eq_Box = |ex, ey| (match ex {
	BInt(exf0) => (match ey {
		BInt(eyf0) => (exf0 == eyf0)
		_ => False
	})
	BText(exf0) => (match ey {
		BText(eyf0) => (exf0 == eyf0)
		_ => False
	})
	BFlag(exf0) => (match ey {
		BFlag(eyf0) => (exf0 == eyf0)
		_ => False
	})
	BPair(exf0, exf1) => (match ey {
		BPair(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
	BNone => (match ey {
		BNone => True
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("int-0 ", CceText.show_int(by_int(BInt(0))))))
	line!(CceText.printed(CceText.concat("int-1 ", CceText.show_int(by_int(BInt(1))))))
	line!(CceText.printed(CceText.concat("int-7 ", CceText.show_int(by_int(BInt(7))))))
	line!(CceText.printed(CceText.concat("int-n ", CceText.show_int(by_int(BInt(3))))))
	line!(CceText.printed(CceText.concat("txt-sin ", CceText.show_int(by_text(BText("sin"))))))
	line!(CceText.printed(CceText.concat("txt-cos ", CceText.show_int(by_text(BText("cos"))))))
	line!(CceText.printed(CceText.concat("txt-oth ", CceText.show_int(by_text(BText("zzz"))))))
	line!(CceText.printed(CceText.concat("flag-t ", CceText.show_int(by_flag(BFlag(True))))))
	line!(CceText.printed(CceText.concat("flag-f ", CceText.show_int(by_flag(BFlag(False))))))
	line!(CceText.printed(CceText.concat("pair-0 ", CceText.show_int(by_pair(BPair(0, "x"))))))
	line!(CceText.printed(CceText.concat("pair-hit ", CceText.show_int(by_pair(BPair(5, "hit"))))))
	line!(CceText.printed(CceText.concat("pair-oth ", CceText.show_int(by_pair(BPair(5, "x"))))))
	line!(CceText.printed(CceText.concat("bare-0 ", CceText.show_int(bare_int(0)))))
	line!(CceText.printed(CceText.concat("bare-1 ", CceText.show_int(bare_int(1)))))
	line!(CceText.printed(CceText.concat("bare-n ", CceText.show_int(bare_int(4)))))
	line!(CceText.printed(CceText.concat("bare-sin ", CceText.show_int(bare_text("sin")))))
	line!(CceText.printed(CceText.concat("bare-cos ", CceText.show_int(bare_text("cos")))))
	line!(CceText.printed(CceText.concat("bare-oth ", CceText.show_int(bare_text("zzz")))))
	line!(CceText.printed("done"))
	Ok({})
}
