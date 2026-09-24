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

import cdx.CceText

# BoundedModesSmoke -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
WrapU8 := { v : I64 }.{
	is_eq : WrapU8, WrapU8 -> Bool
	is_eq = |a, b| a.v == b.v
}
WrapI8 := { v : I64 }.{
	is_eq : WrapI8, WrapI8 -> Bool
	is_eq = |a, b| a.v == b.v
}
ClampU8 := { v : I64 }.{
	is_eq : ClampU8, ClampU8 -> Bool
	is_eq = |a, b| a.v == b.v
}
ClampI8 := { v : I64 }.{
	is_eq : ClampI8, ClampI8 -> Bool
	is_eq = |a, b| a.v == b.v
}
ClampU32 := { v : I64 }.{
	is_eq : ClampU32, ClampU32 -> Bool
	is_eq = |a, b| a.v == b.v
}
ClampBig := { v : I64 }.{
	is_eq : ClampBig, ClampBig -> Bool
	is_eq = |a, b| a.v == b.v
}

wu8 : I64 -> I64
wu8 = |n| WrapU8.{ v: (0 + I64.mod_by(n - (0), 256)) }.v

wi8 : I64 -> I64
wi8 = |n| WrapI8.{ v: (-128 + I64.mod_by(n - (-128), 256)) }.v

cu8 : I64 -> I64
cu8 = |n| ClampU8.{ v: I64.min(I64.max(n, 0), 100) }.v

ci8 : I64 -> I64
ci8 = |n| ClampI8.{ v: I64.min(I64.max(n, -50), 50) }.v

cu32 : I64 -> I64
cu32 = |n| ClampU32.{ v: I64.min(I64.max(n, 0), 4294967295) }.v

cbig : I64 -> I64
cbig = |n| ClampBig.{ v: I64.min(I64.max(n, 0), 10000000000) }.v

wrap_add : I64, I64 -> I64
wrap_add = |a, b| wu8((wu8(a) + wu8(b)))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("wu8 300: ", CceText.show_int(wu8(300)))))
	line!(CceText.printed(CceText.concat("wu8 -1: ", CceText.show_int(wu8((-1))))))
	line!(CceText.printed(CceText.concat("wu8 255: ", CceText.show_int(wu8(255)))))
	line!(CceText.printed(CceText.concat("wu8 256: ", CceText.show_int(wu8(256)))))
	line!(CceText.printed(CceText.concat("wu8 512: ", CceText.show_int(wu8(512)))))
	line!(CceText.printed(CceText.concat("wu8 100: ", CceText.show_int(wu8(100)))))
	line!(CceText.printed(CceText.concat("wi8 128: ", CceText.show_int(wi8(128)))))
	line!(CceText.printed(CceText.concat("wi8 -129: ", CceText.show_int(wi8((-129))))))
	line!(CceText.printed(CceText.concat("wi8 130: ", CceText.show_int(wi8(130)))))
	line!(CceText.printed(CceText.concat("wi8 -1: ", CceText.show_int(wi8((-1))))))
	line!(CceText.printed(CceText.concat("cu8 150: ", CceText.show_int(cu8(150)))))
	line!(CceText.printed(CceText.concat("cu8 -5: ", CceText.show_int(cu8((-5))))))
	line!(CceText.printed(CceText.concat("cu8 100: ", CceText.show_int(cu8(100)))))
	line!(CceText.printed(CceText.concat("cu8 0: ", CceText.show_int(cu8(0)))))
	line!(CceText.printed(CceText.concat("ci8 99: ", CceText.show_int(ci8(99)))))
	line!(CceText.printed(CceText.concat("ci8 -99: ", CceText.show_int(ci8((-99))))))
	line!(CceText.printed(CceText.concat("ci8 0: ", CceText.show_int(ci8(0)))))
	line!(CceText.printed(CceText.concat("wrap-add 200 100: ", CceText.show_int(wrap_add(200, 100)))))
	line!(CceText.printed(CceText.concat("cu32 4294967301: ", CceText.show_int(cu32(4294967301)))))
	line!(CceText.printed(CceText.concat("cu32 -1: ", CceText.show_int(cu32((-1))))))
	line!(CceText.printed(CceText.concat("cu32 4294967295: ", CceText.show_int(cu32(4294967295)))))
	line!(CceText.printed(CceText.concat("cbig 20000000000: ", CceText.show_int(cbig(20000000000)))))
	line!(CceText.printed(CceText.concat("cbig -5: ", CceText.show_int(cbig((-5))))))
	line!(CceText.printed(CceText.concat("cbig 10000000000: ", CceText.show_int(cbig(10000000000)))))
	Ok({})
}
