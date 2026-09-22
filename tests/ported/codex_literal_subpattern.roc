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

import cdx.Text

# LiteralSubpattern -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Box_ : [BInt(I64), BText(List(U8)), BFlag(Bool), BPair(I64, List(U8)), BNone]

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
	BText([19, 17, 18]) => 20
	BText([24, 16, 19]) => 21
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
	BPair(_n, [20, 17, 14]) => 41
	BPair(_n, _s) => 42
	_ => 99
})

bare_int : I64 -> I64
bare_int = |n| (match n {
	0 => 50
	1 => 51
	_ => 59
})

bare_text : List(U8) -> I64
bare_text = |t| (match t {
	[19, 17, 18] => 60
	[24, 16, 19] => 61
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
	line!(Text.printed(List.concat([17, 18, 14, 73, 3, 2], Text.show_int(by_int(BInt(0))))))
	line!(Text.printed(List.concat([17, 18, 14, 73, 4, 2], Text.show_int(by_int(BInt(1))))))
	line!(Text.printed(List.concat([17, 18, 14, 73, 10, 2], Text.show_int(by_int(BInt(7))))))
	line!(Text.printed(List.concat([17, 18, 14, 73, 18, 2], Text.show_int(by_int(BInt(3))))))
	line!(Text.printed(List.concat([14, 36, 14, 73, 19, 17, 18, 2], Text.show_int(by_text(BText([19, 17, 18]))))))
	line!(Text.printed(List.concat([14, 36, 14, 73, 24, 16, 19, 2], Text.show_int(by_text(BText([24, 16, 19]))))))
	line!(Text.printed(List.concat([14, 36, 14, 73, 16, 14, 20, 2], Text.show_int(by_text(BText([38, 38, 38]))))))
	line!(Text.printed(List.concat([28, 23, 15, 29, 73, 14, 2], Text.show_int(by_flag(BFlag(True))))))
	line!(Text.printed(List.concat([28, 23, 15, 29, 73, 28, 2], Text.show_int(by_flag(BFlag(False))))))
	line!(Text.printed(List.concat([31, 15, 17, 21, 73, 3, 2], Text.show_int(by_pair(BPair(0, [36]))))))
	line!(Text.printed(List.concat([31, 15, 17, 21, 73, 20, 17, 14, 2], Text.show_int(by_pair(BPair(5, [20, 17, 14]))))))
	line!(Text.printed(List.concat([31, 15, 17, 21, 73, 16, 14, 20, 2], Text.show_int(by_pair(BPair(5, [36]))))))
	line!(Text.printed(List.concat([32, 15, 21, 13, 73, 3, 2], Text.show_int(bare_int(0)))))
	line!(Text.printed(List.concat([32, 15, 21, 13, 73, 4, 2], Text.show_int(bare_int(1)))))
	line!(Text.printed(List.concat([32, 15, 21, 13, 73, 18, 2], Text.show_int(bare_int(4)))))
	line!(Text.printed(List.concat([32, 15, 21, 13, 73, 19, 17, 18, 2], Text.show_int(bare_text([19, 17, 18])))))
	line!(Text.printed(List.concat([32, 15, 21, 13, 73, 24, 16, 19, 2], Text.show_int(bare_text([24, 16, 19])))))
	line!(Text.printed(List.concat([32, 15, 21, 13, 73, 16, 14, 20, 2], Text.show_int(bare_text([38, 38, 38])))))
	line!(Text.printed([22, 16, 18, 13]))
	Ok({})
}
