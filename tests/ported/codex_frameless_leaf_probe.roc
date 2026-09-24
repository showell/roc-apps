# frameless-leaf-probe
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/frameless-leaf-probe.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     add32=3671238039
#     rotl32=3090952880
#     gmul2=143
#     block=2
#     plusk=4294967302

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# FramelessLeafProbe -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

flp_add32 : I64, I64 -> I64
flp_add32 = |a, b| I64.bitwise_and((a + b), 4294967295)

flp_rotl32 : I64, I64 -> I64
flp_rotl32 = |val, n| ({
	masked = I64.bitwise_and(val, 4294967295)
	I64.bitwise_and(I64.bitwise_or(I64.shl_wrap(masked, I64.to_u8_wrap(n)), I64.shr_zf_wrap(masked, I64.to_u8_wrap((32 - n)))), 4294967295)
})

flp_gmul2 : I64 -> I64
flp_gmul2 = |a| (if (a >= 128) { I64.bitwise_xor(I64.bitwise_and(I64.shl_wrap(a, I64.to_u8_wrap(1)), 255), 27) } else { I64.bitwise_and(I64.shl_wrap(a, I64.to_u8_wrap(1)), 255) })

flp_block : I64 -> I64
flp_block = |cp| ({
	v = (cp - 128)
	(if (v < 256) { 0 } else { (if (v < 384) { 1 } else { (if (v < 512) { 2 } else { (if (v < 640) { 3 } else { (if (v < 768) { 4 } else { (if (v < 896) { 5 } else { (if (v < 1024) { 6 } else { (if (v < 1152) { 7 } else { (if (v < 1664) { 8 } else { (if (v < 1920) { 9 } else { (if (v < 2048) { 10 } else { (0 - 1) }) }) }) }) }) }) }) }) }) }) })
})

flp_mask : I64
flp_mask = 4294967295

flp_plusk : I64 -> I64
flp_plusk = |x| (x + flp_mask)

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat("add32=", Text.show_int(flp_add32(1634760805, 2036477234)))))
	line!(Text.printed(Text.concat("rotl32=", Text.show_int(flp_rotl32(1634760805, 7)))))
	line!(Text.printed(Text.concat("gmul2=", Text.show_int(flp_gmul2(202)))))
	line!(Text.printed(Text.concat("block=", Text.show_int(flp_block(628)))))
	line!(Text.printed(Text.concat("plusk=", Text.show_int(flp_plusk(7)))))
	Ok({})
}
