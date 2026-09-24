# RiscV32CEncoder -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import RiscVEncoder

RiscV32CEncoder :: [].{

	rv_li_32 : I64, I64 -> List(I64)
	rv_li_32 = |rd, value| (if (value >= (-2048)) { (if (value <= 2047) { RiscVEncoder.rv_addi(rd, 0, value) } else { rv_li_32_large(rd, value) }) } else { rv_li_32_large(rd, value) })

	rv_li_32_large : I64, I64 -> List(I64)
	rv_li_32_large = |rd, value| ({
		hi20 : I64
		hi20 = RiscVEncoder.rv_li_hi20(value)
		lo12 : I64
		lo12 = (value - (hi20 * 4096))
		(if (lo12 == 0) { RiscVEncoder.rv_lui(rd, hi20) } else { List.concat(RiscVEncoder.rv_lui(rd, hi20), RiscVEncoder.rv_addi(rd, rd, lo12)) })
	})

	rv_c_encode : I64 -> List(I64)
	rv_c_encode = |hw| [I64.bitwise_and(hw, 255), I64.bitwise_and(I64.shr_zf_wrap(hw, I64.to_u8_wrap(8)), 255)]

	rv_c_lw : I64, I64, I64 -> List(I64)
	rv_c_lw = |rdp, rs1p, offset| ({
		off : I64
		off = I64.bitwise_and(offset, 124)
		bit6 : I64
		bit6 = I64.bitwise_and(I64.shr_zf_wrap(off, I64.to_u8_wrap(6)), 1)
		bit2 : I64
		bit2 = I64.bitwise_and(I64.shr_zf_wrap(off, I64.to_u8_wrap(2)), 1)
		bits5_3 : I64
		bits5_3 = I64.bitwise_and(I64.shr_zf_wrap(off, I64.to_u8_wrap(3)), 7)
		rv_c_encode(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(0, I64.shl_wrap(bit6, I64.to_u8_wrap(5))), I64.shl_wrap(bits5_3, I64.to_u8_wrap(10))), I64.bitwise_or(I64.shl_wrap(I64.bitwise_and(rs1p, 7), I64.to_u8_wrap(7)), I64.shl_wrap(I64.bitwise_and(rdp, 7), I64.to_u8_wrap(2)))), I64.bitwise_or(I64.shl_wrap(bit2, I64.to_u8_wrap(6)), I64.shl_wrap(2, I64.to_u8_wrap(13)))))
	})

	rv_c_sw : I64, I64, I64 -> List(I64)
	rv_c_sw = |rs1p, rs2p, offset| ({
		off : I64
		off = I64.bitwise_and(offset, 124)
		bit6 : I64
		bit6 = I64.bitwise_and(I64.shr_zf_wrap(off, I64.to_u8_wrap(6)), 1)
		bit2 : I64
		bit2 = I64.bitwise_and(I64.shr_zf_wrap(off, I64.to_u8_wrap(2)), 1)
		bits5_3 : I64
		bits5_3 = I64.bitwise_and(I64.shr_zf_wrap(off, I64.to_u8_wrap(3)), 7)
		rv_c_encode(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(49152, I64.shl_wrap(bit6, I64.to_u8_wrap(5))), I64.shl_wrap(bits5_3, I64.to_u8_wrap(10))), I64.bitwise_or(I64.shl_wrap(I64.bitwise_and(rs1p, 7), I64.to_u8_wrap(7)), I64.shl_wrap(I64.bitwise_and(rs2p, 7), I64.to_u8_wrap(2)))), I64.shl_wrap(bit2, I64.to_u8_wrap(6))))
	})

	rv_c_nop : List(I64)
	rv_c_nop = rv_c_encode(1)

	rv_c_addi : I64, I64 -> List(I64)
	rv_c_addi = |rd, imm| ({
		imm5 : I64
		imm5 = I64.bitwise_and(imm, 31)
		bit5 : I64
		bit5 = I64.bitwise_and(I64.shr_zf_wrap(imm, I64.to_u8_wrap(5)), 1)
		rv_c_encode(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(1, I64.shl_wrap(imm5, I64.to_u8_wrap(2))), I64.shl_wrap(rd, I64.to_u8_wrap(7))), I64.shl_wrap(bit5, I64.to_u8_wrap(12))))
	})

	rv_c_li : I64, I64 -> List(I64)
	rv_c_li = |rd, imm| ({
		imm5 : I64
		imm5 = I64.bitwise_and(imm, 31)
		bit5 : I64
		bit5 = I64.bitwise_and(I64.shr_zf_wrap(imm, I64.to_u8_wrap(5)), 1)
		rv_c_encode(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(1, I64.shl_wrap(imm5, I64.to_u8_wrap(2))), I64.shl_wrap(rd, I64.to_u8_wrap(7))), I64.bitwise_or(I64.shl_wrap(2, I64.to_u8_wrap(13)), I64.shl_wrap(bit5, I64.to_u8_wrap(12)))))
	})

	rv_c_lui : I64, I64 -> List(I64)
	rv_c_lui = |rd, nzimm| ({
		imm5 : I64
		imm5 = I64.bitwise_and(nzimm, 31)
		bit5 : I64
		bit5 = I64.bitwise_and(I64.shr_zf_wrap(nzimm, I64.to_u8_wrap(5)), 1)
		rv_c_encode(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(1, I64.shl_wrap(imm5, I64.to_u8_wrap(2))), I64.shl_wrap(rd, I64.to_u8_wrap(7))), I64.bitwise_or(I64.shl_wrap(3, I64.to_u8_wrap(13)), I64.shl_wrap(bit5, I64.to_u8_wrap(12)))))
	})

	rv_c_addi16sp : I64 -> List(I64)
	rv_c_addi16sp = |imm| ({
		nzimm : I64
		nzimm = I64.bitwise_and(I64.div_trunc_by(imm, 16), 63)
		bits4_0 : I64
		bits4_0 = I64.bitwise_and(nzimm, 31)
		bit5 : I64
		bit5 = I64.bitwise_and(I64.shr_zf_wrap(nzimm, I64.to_u8_wrap(5)), 1)
		rv_c_encode(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(1, I64.shl_wrap(bits4_0, I64.to_u8_wrap(2))), I64.shl_wrap(2, I64.to_u8_wrap(7))), I64.bitwise_or(I64.shl_wrap(3, I64.to_u8_wrap(13)), I64.shl_wrap(bit5, I64.to_u8_wrap(12)))))
	})

	rv_c_j : I64 -> List(I64)
	rv_c_j = |offset| ({
		imm : I64
		imm = I64.bitwise_and(offset, 4094)
		bit5 : I64
		bit5 = I64.bitwise_and(I64.shr_zf_wrap(imm, I64.to_u8_wrap(5)), 1)
		bits3_1 : I64
		bits3_1 = I64.bitwise_and(I64.shr_zf_wrap(imm, I64.to_u8_wrap(1)), 7)
		bit7 : I64
		bit7 = I64.bitwise_and(I64.shr_zf_wrap(imm, I64.to_u8_wrap(7)), 1)
		bit6 : I64
		bit6 = I64.bitwise_and(I64.shr_zf_wrap(imm, I64.to_u8_wrap(6)), 1)
		bit10 : I64
		bit10 = I64.bitwise_and(I64.shr_zf_wrap(imm, I64.to_u8_wrap(10)), 1)
		bits9_8 : I64
		bits9_8 = I64.bitwise_and(I64.shr_zf_wrap(imm, I64.to_u8_wrap(8)), 3)
		bit4 : I64
		bit4 = I64.bitwise_and(I64.shr_zf_wrap(imm, I64.to_u8_wrap(4)), 1)
		bit11 : I64
		bit11 = I64.bitwise_and(I64.shr_zf_wrap(imm, I64.to_u8_wrap(11)), 1)
		rv_c_encode(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(1, I64.shl_wrap(bit5, I64.to_u8_wrap(2))), I64.shl_wrap(bits3_1, I64.to_u8_wrap(3))), I64.shl_wrap(bit7, I64.to_u8_wrap(6))), I64.shl_wrap(bit6, I64.to_u8_wrap(7))), I64.shl_wrap(bit10, I64.to_u8_wrap(8))), I64.shl_wrap(bits9_8, I64.to_u8_wrap(9))), I64.shl_wrap(bit4, I64.to_u8_wrap(11))), I64.bitwise_or(I64.shl_wrap(bit11, I64.to_u8_wrap(12)), I64.shl_wrap(5, I64.to_u8_wrap(13)))))
	})

	rv_c_beqz : I64, I64 -> List(I64)
	rv_c_beqz = |rs1p, offset| ({
		off : I64
		off = I64.bitwise_and(offset, 510)
		bit5 : I64
		bit5 = I64.bitwise_and(I64.shr_zf_wrap(off, I64.to_u8_wrap(5)), 1)
		bits2_1 : I64
		bits2_1 = I64.bitwise_and(I64.shr_zf_wrap(off, I64.to_u8_wrap(1)), 3)
		bits4_3 : I64
		bits4_3 = I64.bitwise_and(I64.shr_zf_wrap(off, I64.to_u8_wrap(3)), 3)
		bits7_6 : I64
		bits7_6 = I64.bitwise_and(I64.shr_zf_wrap(off, I64.to_u8_wrap(6)), 3)
		bit8 : I64
		bit8 = I64.bitwise_and(I64.shr_zf_wrap(off, I64.to_u8_wrap(8)), 1)
		rv_c_encode(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(1, I64.shl_wrap(bit5, I64.to_u8_wrap(2))), I64.shl_wrap(bits2_1, I64.to_u8_wrap(3))), I64.shl_wrap(I64.bitwise_and(rs1p, 7), I64.to_u8_wrap(7))), I64.shl_wrap(bits4_3, I64.to_u8_wrap(10))), I64.shl_wrap(bits7_6, I64.to_u8_wrap(5))), I64.bitwise_or(I64.shl_wrap(bit8, I64.to_u8_wrap(12)), I64.shl_wrap(6, I64.to_u8_wrap(13)))))
	})

	rv_c_bnez : I64, I64 -> List(I64)
	rv_c_bnez = |rs1p, offset| ({
		off : I64
		off = I64.bitwise_and(offset, 510)
		bit5 : I64
		bit5 = I64.bitwise_and(I64.shr_zf_wrap(off, I64.to_u8_wrap(5)), 1)
		bits2_1 : I64
		bits2_1 = I64.bitwise_and(I64.shr_zf_wrap(off, I64.to_u8_wrap(1)), 3)
		bits4_3 : I64
		bits4_3 = I64.bitwise_and(I64.shr_zf_wrap(off, I64.to_u8_wrap(3)), 3)
		bits7_6 : I64
		bits7_6 = I64.bitwise_and(I64.shr_zf_wrap(off, I64.to_u8_wrap(6)), 3)
		bit8 : I64
		bit8 = I64.bitwise_and(I64.shr_zf_wrap(off, I64.to_u8_wrap(8)), 1)
		rv_c_encode(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(1, I64.shl_wrap(bit5, I64.to_u8_wrap(2))), I64.shl_wrap(bits2_1, I64.to_u8_wrap(3))), I64.shl_wrap(I64.bitwise_and(rs1p, 7), I64.to_u8_wrap(7))), I64.shl_wrap(bits4_3, I64.to_u8_wrap(10))), I64.shl_wrap(bits7_6, I64.to_u8_wrap(5))), I64.bitwise_or(I64.shl_wrap(bit8, I64.to_u8_wrap(12)), I64.shl_wrap(7, I64.to_u8_wrap(13)))))
	})

	rv_c_sub : I64, I64 -> List(I64)
	rv_c_sub = |rdp, rs2p| rv_c_encode(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(35841, I64.shl_wrap(I64.bitwise_and(rdp, 7), I64.to_u8_wrap(7))), I64.shl_wrap(I64.bitwise_and(rs2p, 7), I64.to_u8_wrap(2))), 0))

	rv_c_or : I64, I64 -> List(I64)
	rv_c_or = |rdp, rs2p| rv_c_encode(I64.bitwise_or(I64.bitwise_or(35905, I64.shl_wrap(I64.bitwise_and(rdp, 7), I64.to_u8_wrap(7))), I64.shl_wrap(I64.bitwise_and(rs2p, 7), I64.to_u8_wrap(2))))

	rv_c_and : I64, I64 -> List(I64)
	rv_c_and = |rdp, rs2p| rv_c_encode(I64.bitwise_or(I64.bitwise_or(35937, I64.shl_wrap(I64.bitwise_and(rdp, 7), I64.to_u8_wrap(7))), I64.shl_wrap(I64.bitwise_and(rs2p, 7), I64.to_u8_wrap(2))))

	rv_c_xor : I64, I64 -> List(I64)
	rv_c_xor = |rdp, rs2p| rv_c_encode(I64.bitwise_or(I64.bitwise_or(35873, I64.shl_wrap(I64.bitwise_and(rdp, 7), I64.to_u8_wrap(7))), I64.shl_wrap(I64.bitwise_and(rs2p, 7), I64.to_u8_wrap(2))))

	rv_c_lwsp : I64, I64 -> List(I64)
	rv_c_lwsp = |rd, offset| ({
		bit5 : I64
		bit5 = I64.bitwise_and(I64.shr_zf_wrap(offset, I64.to_u8_wrap(5)), 1)
		bits4_2 : I64
		bits4_2 = I64.bitwise_and(I64.shr_zf_wrap(offset, I64.to_u8_wrap(2)), 7)
		bits7_6 : I64
		bits7_6 = I64.bitwise_and(I64.shr_zf_wrap(offset, I64.to_u8_wrap(6)), 3)
		rv_c_encode(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(2, I64.shl_wrap(bits7_6, I64.to_u8_wrap(2))), I64.shl_wrap(bits4_2, I64.to_u8_wrap(4))), I64.bitwise_or(I64.shl_wrap(rd, I64.to_u8_wrap(7)), I64.shl_wrap(bit5, I64.to_u8_wrap(12)))))
	})

	rv_c_swsp : I64, I64 -> List(I64)
	rv_c_swsp = |rs2, offset| ({
		bits5_2 : I64
		bits5_2 = I64.bitwise_and(I64.shr_zf_wrap(offset, I64.to_u8_wrap(2)), 15)
		bits7_6 : I64
		bits7_6 = I64.bitwise_and(I64.shr_zf_wrap(offset, I64.to_u8_wrap(6)), 3)
		rv_c_encode(I64.bitwise_or(I64.bitwise_or(49154, I64.shl_wrap(rs2, I64.to_u8_wrap(2))), I64.bitwise_or(I64.shl_wrap(bits7_6, I64.to_u8_wrap(7)), I64.shl_wrap(bits5_2, I64.to_u8_wrap(9)))))
	})

	rv_c_mv : I64, I64 -> List(I64)
	rv_c_mv = |rd, rs2| rv_c_encode(I64.bitwise_or(I64.bitwise_or(2, I64.shl_wrap(rs2, I64.to_u8_wrap(2))), I64.shl_wrap(rd, I64.to_u8_wrap(7))))

	rv_c_add : I64, I64 -> List(I64)
	rv_c_add = |rd, rs2| rv_c_encode(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(2, I64.shl_wrap(rs2, I64.to_u8_wrap(2))), I64.shl_wrap(rd, I64.to_u8_wrap(7))), I64.shl_wrap(1, I64.to_u8_wrap(12))))

	rv_c_jr : I64 -> List(I64)
	rv_c_jr = |rs1| rv_c_encode(I64.bitwise_or(2, I64.shl_wrap(rs1, I64.to_u8_wrap(7))))

	rv_c_jalr : I64 -> List(I64)
	rv_c_jalr = |rs1| rv_c_encode(I64.bitwise_or(I64.bitwise_or(2, I64.shl_wrap(rs1, I64.to_u8_wrap(7))), I64.shl_wrap(1, I64.to_u8_wrap(12))))

	rv_c_ret : List(I64)
	rv_c_ret = rv_c_jr(RiscVEncoder.rv_ra)
}
