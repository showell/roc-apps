# thumb2-encoder
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/thumb2-encoder.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     nop=BF00
#     mov r0,r1=1C08
#     mov r0,#42=202A
#     add r0,r1,r2=1888
#     sub r0,r1,r2=1A88
#     cmp r1,r2=4291
#     and r0,r1=4008
#     ldr r0,[sp,#16]=9804
#     str r0,[sp,#16]=9004
#     bx lr=4770
#     movw r0,#1234=2034F241
#     movt r0,#5678=6078F2C5
#     add.w r0,r1,r2=0002EB01
#     sub.w r0,r1,r2=0002EBA1
#     mul r0,r1,r2=F002FB01
#     sdiv r0,r1,r2=F002FB91
#     ldr.w r0,[r1,#16]=0010F8D1
#     str.w r0,[r1,#16]=0010F8C1
#     li r0,#12345678 len=8

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text
import cdx.Thumb2Encoder

# Thumb2EncoderTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

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

show_hex_half : I64 -> Text
show_hex_half = |w| ({
	b0 = I64.bitwise_and(w, 255)
	b1 = I64.bitwise_and(I64.shr_zf_wrap(w, I64.to_u8_wrap(8)), 255)
	Text.concat(hex_byte(b1), hex_byte(b0))
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

show_insn_16 : List(I64) -> Text
show_insn_16 = |bytes| ({
	w = ((List.get(bytes, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) + ((List.get(bytes, I64.to_u64_wrap(1)) ?? crash("list-at out of range")) * 256))
	show_hex_half(w)
})

show_insn_32 : List(I64) -> Text
show_insn_32 = |bytes| ({
	w = ((((List.get(bytes, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) + ((List.get(bytes, I64.to_u64_wrap(1)) ?? crash("list-at out of range")) * 256)) + ((List.get(bytes, I64.to_u64_wrap(2)) ?? crash("list-at out of range")) * 65536)) + ((List.get(bytes, I64.to_u64_wrap(3)) ?? crash("list-at out of range")) * 16777216))
	show_hex_word(w)
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat("nop=", show_insn_16(Thumb2Encoder.t2_nop))))
	line!(Text.printed(Text.concat("mov r0,r1=", show_insn_16(Thumb2Encoder.t2_mov(0, 1)))))
	line!(Text.printed(Text.concat("mov r0,#42=", show_insn_16(Thumb2Encoder.t2_mov_imm8(0, 42)))))
	line!(Text.printed(Text.concat("add r0,r1,r2=", show_insn_16(Thumb2Encoder.t2_add_lo(0, 1, 2)))))
	line!(Text.printed(Text.concat("sub r0,r1,r2=", show_insn_16(Thumb2Encoder.t2_sub_lo(0, 1, 2)))))
	line!(Text.printed(Text.concat("cmp r1,r2=", show_insn_16(Thumb2Encoder.t2_cmp_reg(1, 2)))))
	line!(Text.printed(Text.concat("and r0,r1=", show_insn_16(Thumb2Encoder.t2_and_reg(0, 1)))))
	line!(Text.printed(Text.concat("ldr r0,[sp,#16]=", show_insn_16(Thumb2Encoder.t2_ldr_sp(0, 16)))))
	line!(Text.printed(Text.concat("str r0,[sp,#16]=", show_insn_16(Thumb2Encoder.t2_str_sp(0, 16)))))
	line!(Text.printed(Text.concat("bx lr=", show_insn_16(Thumb2Encoder.t2_ret))))
	line!(Text.printed(Text.concat("movw r0,#1234=", show_insn_32(Thumb2Encoder.t2_movw(0, 4660)))))
	line!(Text.printed(Text.concat("movt r0,#5678=", show_insn_32(Thumb2Encoder.t2_movt(0, 22136)))))
	line!(Text.printed(Text.concat("add.w r0,r1,r2=", show_insn_32(Thumb2Encoder.t2_add_w(0, 1, 2)))))
	line!(Text.printed(Text.concat("sub.w r0,r1,r2=", show_insn_32(Thumb2Encoder.t2_sub_w(0, 1, 2)))))
	line!(Text.printed(Text.concat("mul r0,r1,r2=", show_insn_32(Thumb2Encoder.t2_mul_w(0, 1, 2)))))
	line!(Text.printed(Text.concat("sdiv r0,r1,r2=", show_insn_32(Thumb2Encoder.t2_sdiv_w(0, 1, 2)))))
	line!(Text.printed(Text.concat("ldr.w r0,[r1,#16]=", show_insn_32(Thumb2Encoder.t2_ldr_w(0, 1, 16)))))
	line!(Text.printed(Text.concat("str.w r0,[r1,#16]=", show_insn_32(Thumb2Encoder.t2_str_w(0, 1, 16)))))
	({
		li_result = Thumb2Encoder.t2_li(0, 305419896)
		line!(Text.printed(Text.concat("li r0,#12345678 len=", Text.show_int(U64.to_i64_wrap(List.len(li_result))))))
	})
	Ok({})
}
