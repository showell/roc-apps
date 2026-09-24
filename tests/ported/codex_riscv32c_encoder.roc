# riscv32c-encoder
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/riscv32c-encoder.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     c.nop=0001
#     c.li a0,42=5529
#     c.mv a0,a1=052E
#     c.add a0,a1=152E
#     c.jr ra=0082
#     c.jalr ra=1082
#     c.ret=0082
#     c.addi a0,5=0515
#     c.j +100=A095
#     li32 a0,#12345=2 insns
#     li32 a0,42=1 insns

app [main!] { cdx: "./codex/main.roc" }

import cdx.RiscV32CEncoder
import cdx.Text

# RiscV32CEncoderTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

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
	line!(Text.printed(Text.concat("c.nop=", show_insn_16(RiscV32CEncoder.rv_c_nop))))
	line!(Text.printed(Text.concat("c.li a0,42=", show_insn_16(RiscV32CEncoder.rv_c_li(10, 42)))))
	line!(Text.printed(Text.concat("c.mv a0,a1=", show_insn_16(RiscV32CEncoder.rv_c_mv(10, 11)))))
	line!(Text.printed(Text.concat("c.add a0,a1=", show_insn_16(RiscV32CEncoder.rv_c_add(10, 11)))))
	line!(Text.printed(Text.concat("c.jr ra=", show_insn_16(RiscV32CEncoder.rv_c_jr(1)))))
	line!(Text.printed(Text.concat("c.jalr ra=", show_insn_16(RiscV32CEncoder.rv_c_jalr(1)))))
	line!(Text.printed(Text.concat("c.ret=", show_insn_16(RiscV32CEncoder.rv_c_ret))))
	line!(Text.printed(Text.concat("c.addi a0,5=", show_insn_16(RiscV32CEncoder.rv_c_addi(10, 5)))))
	line!(Text.printed(Text.concat("c.j +100=", show_insn_16(RiscV32CEncoder.rv_c_j(100)))))
	line!(Text.printed(Text.concat(Text.concat("li32 a0,#12345=", Text.show_int(I64.div_trunc_by(U64.to_i64_wrap(List.len(RiscV32CEncoder.rv_li_32(10, 74565))), 4))), " insns")))
	line!(Text.printed(Text.concat(Text.concat("li32 a0,42=", Text.show_int(I64.div_trunc_by(U64.to_i64_wrap(List.len(RiscV32CEncoder.rv_li_32(10, 42))), 4))), " insns")))
	Ok({})
}
