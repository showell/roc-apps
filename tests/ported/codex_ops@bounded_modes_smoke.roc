# ops@bounded-modes-smoke
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@bounded-modes-smoke.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     wu8 300: 44
#     wu8 -1: 255
#     wu8 255: 255
#     wu8 256: 0
#     wu8 512: 0
#     wu8 100: 100
#     wi8 128: -128
#     wi8 -129: 127
#     wi8 130: -126
#     wi8 -1: -1
#     cu8 150: 100
#     cu8 -5: 0
#     cu8 100: 100
#     cu8 0: 0
#     ci8 99: 50
#     ci8 -99: -50
#     ci8 0: 0
#     wrap-add 200 100: 44
#     cu32 4294967301: 4294967295
#     cu32 -1: 0
#     cu32 4294967295: 4294967295
#     cbig 20000000000: 10000000000
#     cbig -5: 0
#     cbig 10000000000: 10000000000

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# BoundedModesSmoke -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
WrapU8 : { v : I64 }
WrapI8 : { v : I64 }
ClampU8 : { v : I64 }
ClampI8 : { v : I64 }
ClampU32 : { v : I64 }
ClampBig : { v : I64 }

wu8 : I64 -> I64
wu8 = |n| { v: (0 + I64.mod_by(n - (0), 256)) }.v

wi8 : I64 -> I64
wi8 = |n| { v: (-128 + I64.mod_by(n - (-128), 256)) }.v

cu8 : I64 -> I64
cu8 = |n| { v: I64.min(I64.max(n, 0), 100) }.v

ci8 : I64 -> I64
ci8 = |n| { v: I64.min(I64.max(n, -50), 50) }.v

cu32 : I64 -> I64
cu32 = |n| { v: I64.min(I64.max(n, 0), 4294967295) }.v

cbig : I64 -> I64
cbig = |n| { v: I64.min(I64.max(n, 0), 10000000000) }.v

wrap_add : I64, I64 -> I64
wrap_add = |a, b| wu8((wu8(a) + wu8(b)))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([27, 25, 11, 2, 6, 3, 3, 69, 2], Text.show_int(wu8(300)))))
	line!(Text.printed(List.concat([27, 25, 11, 2, 73, 4, 69, 2], Text.show_int(wu8((-1))))))
	line!(Text.printed(List.concat([27, 25, 11, 2, 5, 8, 8, 69, 2], Text.show_int(wu8(255)))))
	line!(Text.printed(List.concat([27, 25, 11, 2, 5, 8, 9, 69, 2], Text.show_int(wu8(256)))))
	line!(Text.printed(List.concat([27, 25, 11, 2, 8, 4, 5, 69, 2], Text.show_int(wu8(512)))))
	line!(Text.printed(List.concat([27, 25, 11, 2, 4, 3, 3, 69, 2], Text.show_int(wu8(100)))))
	line!(Text.printed(List.concat([27, 17, 11, 2, 4, 5, 11, 69, 2], Text.show_int(wi8(128)))))
	line!(Text.printed(List.concat([27, 17, 11, 2, 73, 4, 5, 12, 69, 2], Text.show_int(wi8((-129))))))
	line!(Text.printed(List.concat([27, 17, 11, 2, 4, 6, 3, 69, 2], Text.show_int(wi8(130)))))
	line!(Text.printed(List.concat([27, 17, 11, 2, 73, 4, 69, 2], Text.show_int(wi8((-1))))))
	line!(Text.printed(List.concat([24, 25, 11, 2, 4, 8, 3, 69, 2], Text.show_int(cu8(150)))))
	line!(Text.printed(List.concat([24, 25, 11, 2, 73, 8, 69, 2], Text.show_int(cu8((-5))))))
	line!(Text.printed(List.concat([24, 25, 11, 2, 4, 3, 3, 69, 2], Text.show_int(cu8(100)))))
	line!(Text.printed(List.concat([24, 25, 11, 2, 3, 69, 2], Text.show_int(cu8(0)))))
	line!(Text.printed(List.concat([24, 17, 11, 2, 12, 12, 69, 2], Text.show_int(ci8(99)))))
	line!(Text.printed(List.concat([24, 17, 11, 2, 73, 12, 12, 69, 2], Text.show_int(ci8((-99))))))
	line!(Text.printed(List.concat([24, 17, 11, 2, 3, 69, 2], Text.show_int(ci8(0)))))
	line!(Text.printed(List.concat([27, 21, 15, 31, 73, 15, 22, 22, 2, 5, 3, 3, 2, 4, 3, 3, 69, 2], Text.show_int(wrap_add(200, 100)))))
	line!(Text.printed(List.concat([24, 25, 6, 5, 2, 7, 5, 12, 7, 12, 9, 10, 6, 3, 4, 69, 2], Text.show_int(cu32(4294967301)))))
	line!(Text.printed(List.concat([24, 25, 6, 5, 2, 73, 4, 69, 2], Text.show_int(cu32((-1))))))
	line!(Text.printed(List.concat([24, 25, 6, 5, 2, 7, 5, 12, 7, 12, 9, 10, 5, 12, 8, 69, 2], Text.show_int(cu32(4294967295)))))
	line!(Text.printed(List.concat([24, 32, 17, 29, 2, 5, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 69, 2], Text.show_int(cbig(20000000000)))))
	line!(Text.printed(List.concat([24, 32, 17, 29, 2, 73, 8, 69, 2], Text.show_int(cbig((-5))))))
	line!(Text.printed(List.concat([24, 32, 17, 29, 2, 4, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 69, 2], Text.show_int(cbig(10000000000)))))
	Ok({})
}
