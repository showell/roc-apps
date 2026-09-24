# riscv-encoder
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/riscv-encoder.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     add a0,a1,a2=00C58533
#     sub a0,a1,a2=40C58533
#     mul a0,a1,a2=02C58533
#     and a0,a1,a2=00C5F533
#     or a0,a1,a2=00C5E533
#     addi a0,a1,42=02A58513
#     ld a0,0(a1)=0005B503
#     sd a1,8(a0)=00B53423
#     beq a0,a1,+16=00B50863
#     lui a0,#12345=12345537
#     jal ra,+100=064000EF
#     ret=00008067
#     nop=00000013
#     mv a0,a1=00058513
#     li a0,#DEADBEEF len=5
#     fits32 -2147483649=False
#     fits32 -2147483648=True
#     fits32 2147483647=True
#     fits32 2147483648=False
#     fits32 #7FFFFFFF7FFFFFFF=False
#     fits32 #7FFFFFFF80000000=False
#     li max len=7

app [main!] { cdx: "./codex/main.roc" }

import cdx.RiscVEncoder
import cdx.Text

# RiscVEncoderTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

show_hex_word : I64 -> Text
show_hex_word = |w| ({
	b0 = I64.bitwise_and(w, 255)
	b1 = I64.bitwise_and(I64.shr_zf_wrap(w, I64.to_u8_wrap(8)), 255)
	b2 = I64.bitwise_and(I64.shr_zf_wrap(w, I64.to_u8_wrap(16)), 255)
	b3 = I64.bitwise_and(I64.shr_zf_wrap(w, I64.to_u8_wrap(24)), 255)
	Text.concat(Text.concat(Text.concat(hex_byte(b3), hex_byte(b2)), hex_byte(b1)), hex_byte(b0))
})

hex_byte : I64 -> Text
hex_byte = |b| Text.concat(hex_nib(I64.div_trunc_by(b, 16)), hex_nib(I64.bitwise_and(b, 15)))

hex_nib : I64 -> Text
hex_nib = |n| (match n {
	0 => "0"
	1 => "1"
	2 => "2"
	3 => "3"
	4 => "4"
	5 => "5"
	6 => "6"
	7 => "7"
	8 => "8"
	9 => "9"
	10 => "A"
	11 => "B"
	12 => "C"
	13 => "D"
	14 => "E"
	15 => "F"
	_ => "?"
})

show_insn : List(I64) -> Text
show_insn = |bytes| ({
	w = ((((List.get(bytes, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) + ((List.get(bytes, I64.to_u64_wrap(1)) ?? crash("list-at out of range")) * 256)) + ((List.get(bytes, I64.to_u64_wrap(2)) ?? crash("list-at out of range")) * 65536)) + ((List.get(bytes, I64.to_u64_wrap(3)) ?? crash("list-at out of range")) * 16777216))
	show_hex_word(w)
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat("add a0,a1,a2=", show_insn(RiscVEncoder.rv_add(10, 11, 12)))))
	line!(Text.printed(Text.concat("sub a0,a1,a2=", show_insn(RiscVEncoder.rv_sub(10, 11, 12)))))
	line!(Text.printed(Text.concat("mul a0,a1,a2=", show_insn(RiscVEncoder.rv_mul(10, 11, 12)))))
	line!(Text.printed(Text.concat("and a0,a1,a2=", show_insn(RiscVEncoder.rv_and(10, 11, 12)))))
	line!(Text.printed(Text.concat("or a0,a1,a2=", show_insn(RiscVEncoder.rv_or(10, 11, 12)))))
	line!(Text.printed(Text.concat("addi a0,a1,42=", show_insn(RiscVEncoder.rv_addi(10, 11, 42)))))
	line!(Text.printed(Text.concat("ld a0,0(a1)=", show_insn(RiscVEncoder.rv_ld(10, 11, 0)))))
	line!(Text.printed(Text.concat("sd a1,8(a0)=", show_insn(RiscVEncoder.rv_sd(10, 11, 8)))))
	line!(Text.printed(Text.concat("beq a0,a1,+16=", show_insn(RiscVEncoder.rv_beq(10, 11, 16)))))
	line!(Text.printed(Text.concat("lui a0,#12345=", show_insn(RiscVEncoder.rv_lui(10, 74565)))))
	line!(Text.printed(Text.concat("jal ra,+100=", show_insn(RiscVEncoder.rv_jal(1, 100)))))
	line!(Text.printed(Text.concat("ret=", show_insn(RiscVEncoder.rv_ret))))
	line!(Text.printed(Text.concat("nop=", show_insn(RiscVEncoder.rv_nop))))
	line!(Text.printed(Text.concat("mv a0,a1=", show_insn(RiscVEncoder.rv_mv(10, 11)))))
	({
		li_result = RiscVEncoder.rv_li(10, 3735928559)
		({
			line!(Text.printed(Text.concat("li a0,#DEADBEEF len=", Text.show_int(I64.div_trunc_by(U64.to_i64_wrap(List.len(li_result)), 4)))))
			line!(Text.printed(Text.concat("fits32 -2147483649=", (if RiscVEncoder.rv_li_fits_32((0 - 2147483649)) { "True" } else { "False" }))))
			line!(Text.printed(Text.concat("fits32 -2147483648=", (if RiscVEncoder.rv_li_fits_32((0 - 2147483648)) { "True" } else { "False" }))))
			line!(Text.printed(Text.concat("fits32 2147483647=", (if RiscVEncoder.rv_li_fits_32(2147483647) { "True" } else { "False" }))))
			line!(Text.printed(Text.concat("fits32 2147483648=", (if RiscVEncoder.rv_li_fits_32(2147483648) { "True" } else { "False" }))))
			line!(Text.printed(Text.concat("fits32 #7FFFFFFF7FFFFFFF=", (if RiscVEncoder.rv_li_fits_32(9223372034707292159) { "True" } else { "False" }))))
			line!(Text.printed(Text.concat("fits32 #7FFFFFFF80000000=", (if RiscVEncoder.rv_li_fits_32(9223372034707292160) { "True" } else { "False" }))))
			line!(Text.printed(Text.concat("li max len=", Text.show_int(I64.div_trunc_by(U64.to_i64_wrap(List.len(RiscVEncoder.rv_li(10, 9223372036854775807))), 4)))))
		})
	})
	Ok({})
}
