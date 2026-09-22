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

show_hex_word : I64 -> List(U8)
show_hex_word = |w| ({
	b0 = I64.bitwise_and(w, 255)
	b1 = I64.bitwise_and(I64.shr_zf_wrap(w, I64.to_u8_wrap(8)), 255)
	b2 = I64.bitwise_and(I64.shr_zf_wrap(w, I64.to_u8_wrap(16)), 255)
	b3 = I64.bitwise_and(I64.shr_zf_wrap(w, I64.to_u8_wrap(24)), 255)
	List.concat(List.concat(List.concat(hex_byte(b3), hex_byte(b2)), hex_byte(b1)), hex_byte(b0))
})

hex_byte : I64 -> List(U8)
hex_byte = |b| List.concat(hex_nib(I64.div_trunc_by(b, 16)), hex_nib(I64.bitwise_and(b, 15)))

hex_nib : I64 -> List(U8)
hex_nib = |n| (match n {
	0 => [3]
	1 => [4]
	2 => [5]
	3 => [6]
	4 => [7]
	5 => [8]
	6 => [9]
	7 => [10]
	8 => [11]
	9 => [12]
	10 => [41]
	11 => [58]
	12 => [50]
	13 => [48]
	14 => [39]
	15 => [54]
	_ => [68]
})

show_insn : List(I64) -> List(U8)
show_insn = |bytes| ({
	w = ((((List.get(bytes, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) + ((List.get(bytes, I64.to_u64_wrap(1)) ?? crash("list-at out of range")) * 256)) + ((List.get(bytes, I64.to_u64_wrap(2)) ?? crash("list-at out of range")) * 65536)) + ((List.get(bytes, I64.to_u64_wrap(3)) ?? crash("list-at out of range")) * 16777216))
	show_hex_word(w)
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([15, 22, 22, 2, 15, 3, 66, 15, 4, 66, 15, 5, 77], show_insn(RiscVEncoder.rv_add(10, 11, 12)))))
	line!(Text.printed(List.concat([19, 25, 32, 2, 15, 3, 66, 15, 4, 66, 15, 5, 77], show_insn(RiscVEncoder.rv_sub(10, 11, 12)))))
	line!(Text.printed(List.concat([26, 25, 23, 2, 15, 3, 66, 15, 4, 66, 15, 5, 77], show_insn(RiscVEncoder.rv_mul(10, 11, 12)))))
	line!(Text.printed(List.concat([15, 18, 22, 2, 15, 3, 66, 15, 4, 66, 15, 5, 77], show_insn(RiscVEncoder.rv_and(10, 11, 12)))))
	line!(Text.printed(List.concat([16, 21, 2, 15, 3, 66, 15, 4, 66, 15, 5, 77], show_insn(RiscVEncoder.rv_or(10, 11, 12)))))
	line!(Text.printed(List.concat([15, 22, 22, 17, 2, 15, 3, 66, 15, 4, 66, 7, 5, 77], show_insn(RiscVEncoder.rv_addi(10, 11, 42)))))
	line!(Text.printed(List.concat([23, 22, 2, 15, 3, 66, 3, 74, 15, 4, 75, 77], show_insn(RiscVEncoder.rv_ld(10, 11, 0)))))
	line!(Text.printed(List.concat([19, 22, 2, 15, 4, 66, 11, 74, 15, 3, 75, 77], show_insn(RiscVEncoder.rv_sd(10, 11, 8)))))
	line!(Text.printed(List.concat([32, 13, 37, 2, 15, 3, 66, 15, 4, 66, 76, 4, 9, 77], show_insn(RiscVEncoder.rv_beq(10, 11, 16)))))
	line!(Text.printed(List.concat([23, 25, 17, 2, 15, 3, 66, 83, 4, 5, 6, 7, 8, 77], show_insn(RiscVEncoder.rv_lui(10, 74565)))))
	line!(Text.printed(List.concat([35, 15, 23, 2, 21, 15, 66, 76, 4, 3, 3, 77], show_insn(RiscVEncoder.rv_jal(1, 100)))))
	line!(Text.printed(List.concat([21, 13, 14, 77], show_insn(RiscVEncoder.rv_ret))))
	line!(Text.printed(List.concat([18, 16, 31, 77], show_insn(RiscVEncoder.rv_nop))))
	line!(Text.printed(List.concat([26, 33, 2, 15, 3, 66, 15, 4, 77], show_insn(RiscVEncoder.rv_mv(10, 11)))))
	({
		li_result = RiscVEncoder.rv_li(10, 3735928559)
		({
			line!(Text.printed(List.concat([23, 17, 2, 15, 3, 66, 83, 48, 39, 41, 48, 58, 39, 39, 54, 2, 23, 13, 18, 77], Text.show_int(I64.div_trunc_by(U64.to_i64_wrap(List.len(li_result)), 4)))))
			line!(Text.printed(List.concat([28, 17, 14, 19, 6, 5, 2, 73, 5, 4, 7, 10, 7, 11, 6, 9, 7, 12, 77], (if RiscVEncoder.rv_li_fits_32((0 - 2147483649)) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
			line!(Text.printed(List.concat([28, 17, 14, 19, 6, 5, 2, 73, 5, 4, 7, 10, 7, 11, 6, 9, 7, 11, 77], (if RiscVEncoder.rv_li_fits_32((0 - 2147483648)) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
			line!(Text.printed(List.concat([28, 17, 14, 19, 6, 5, 2, 5, 4, 7, 10, 7, 11, 6, 9, 7, 10, 77], (if RiscVEncoder.rv_li_fits_32(2147483647) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
			line!(Text.printed(List.concat([28, 17, 14, 19, 6, 5, 2, 5, 4, 7, 10, 7, 11, 6, 9, 7, 11, 77], (if RiscVEncoder.rv_li_fits_32(2147483648) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
			line!(Text.printed(List.concat([28, 17, 14, 19, 6, 5, 2, 83, 10, 54, 54, 54, 54, 54, 54, 54, 10, 54, 54, 54, 54, 54, 54, 54, 77], (if RiscVEncoder.rv_li_fits_32(9223372034707292159) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
			line!(Text.printed(List.concat([28, 17, 14, 19, 6, 5, 2, 83, 10, 54, 54, 54, 54, 54, 54, 54, 11, 3, 3, 3, 3, 3, 3, 3, 77], (if RiscVEncoder.rv_li_fits_32(9223372034707292160) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
			line!(Text.printed(List.concat([23, 17, 2, 26, 15, 36, 2, 23, 13, 18, 77], Text.show_int(I64.div_trunc_by(U64.to_i64_wrap(List.len(RiscVEncoder.rv_li(10, 9223372036854775807))), 4)))))
		})
	})
	Ok({})
}
