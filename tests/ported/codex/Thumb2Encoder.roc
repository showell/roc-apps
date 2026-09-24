# Thumb2Encoder -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Thumb2Encoder :: [].{

	t2_r0 : I64
	t2_r0 = 0

	t2_r1 : I64
	t2_r1 = 1

	t2_r2 : I64
	t2_r2 = 2

	t2_r3 : I64
	t2_r3 = 3

	t2_r4 : I64
	t2_r4 = 4

	t2_r5 : I64
	t2_r5 = 5

	t2_r6 : I64
	t2_r6 = 6

	t2_r7 : I64
	t2_r7 = 7

	t2_r8 : I64
	t2_r8 = 8

	t2_r9 : I64
	t2_r9 = 9

	t2_r10 : I64
	t2_r10 = 10

	t2_r11 : I64
	t2_r11 = 11

	t2_r12 : I64
	t2_r12 = 12

	t2_sp : I64
	t2_sp = 13

	t2_lr : I64
	t2_lr = 14

	t2_pc : I64
	t2_pc = 15

	t2_encode_16 : I64 -> List(I64)
	t2_encode_16 = |hw| [I64.bitwise_and(hw, 255), I64.bitwise_and(I64.shr_zf_wrap(hw, I64.to_u8_wrap(8)), 255)]

	t2_encode_32 : I64, I64 -> List(I64)
	t2_encode_32 = |hi16, lo16| [I64.bitwise_and(hi16, 255), I64.bitwise_and(I64.shr_zf_wrap(hi16, I64.to_u8_wrap(8)), 255), I64.bitwise_and(lo16, 255), I64.bitwise_and(I64.shr_zf_wrap(lo16, I64.to_u8_wrap(8)), 255)]

	t2_mov_lo : I64, I64 -> List(I64)
	t2_mov_lo = |rd, rs| t2_encode_16(I64.bitwise_or(17920, I64.bitwise_or(I64.shl_wrap(I64.bitwise_and(I64.shr_zf_wrap(rd, I64.to_u8_wrap(3)), 1), I64.to_u8_wrap(7)), I64.bitwise_or(I64.shl_wrap(I64.bitwise_and(rs, 15), I64.to_u8_wrap(3)), I64.bitwise_and(rd, 7)))))

	t2_add_lo : I64, I64, I64 -> List(I64)
	t2_add_lo = |rd, rn, rm| t2_encode_16(I64.bitwise_or(6144, I64.bitwise_or(I64.shl_wrap(rm, I64.to_u8_wrap(6)), I64.bitwise_or(I64.shl_wrap(rn, I64.to_u8_wrap(3)), rd))))

	t2_sub_lo : I64, I64, I64 -> List(I64)
	t2_sub_lo = |rd, rn, rm| t2_encode_16(I64.bitwise_or(6656, I64.bitwise_or(I64.shl_wrap(rm, I64.to_u8_wrap(6)), I64.bitwise_or(I64.shl_wrap(rn, I64.to_u8_wrap(3)), rd))))

	t2_add_imm3 : I64, I64, I64 -> List(I64)
	t2_add_imm3 = |rd, rn, imm3| t2_encode_16(I64.bitwise_or(7168, I64.bitwise_or(I64.shl_wrap(I64.bitwise_and(imm3, 7), I64.to_u8_wrap(6)), I64.bitwise_or(I64.shl_wrap(rn, I64.to_u8_wrap(3)), rd))))

	t2_sub_imm3 : I64, I64, I64 -> List(I64)
	t2_sub_imm3 = |rd, rn, imm3| t2_encode_16(I64.bitwise_or(7680, I64.bitwise_or(I64.shl_wrap(I64.bitwise_and(imm3, 7), I64.to_u8_wrap(6)), I64.bitwise_or(I64.shl_wrap(rn, I64.to_u8_wrap(3)), rd))))

	t2_mov_imm8 : I64, I64 -> List(I64)
	t2_mov_imm8 = |rd, imm8| t2_encode_16(I64.bitwise_or(8192, I64.bitwise_or(I64.shl_wrap(rd, I64.to_u8_wrap(8)), I64.bitwise_and(imm8, 255))))

	t2_cmp_imm8 : I64, I64 -> List(I64)
	t2_cmp_imm8 = |rn, imm8| t2_encode_16(I64.bitwise_or(10240, I64.bitwise_or(I64.shl_wrap(rn, I64.to_u8_wrap(8)), I64.bitwise_and(imm8, 255))))

	t2_add_imm8 : I64, I64 -> List(I64)
	t2_add_imm8 = |rdn, imm8| t2_encode_16(I64.bitwise_or(12288, I64.bitwise_or(I64.shl_wrap(rdn, I64.to_u8_wrap(8)), I64.bitwise_and(imm8, 255))))

	t2_sub_imm8 : I64, I64 -> List(I64)
	t2_sub_imm8 = |rdn, imm8| t2_encode_16(I64.bitwise_or(14336, I64.bitwise_or(I64.shl_wrap(rdn, I64.to_u8_wrap(8)), I64.bitwise_and(imm8, 255))))

	t2_ldr_sp : I64, I64 -> List(I64)
	t2_ldr_sp = |rt, offset| t2_encode_16(I64.bitwise_or(38912, I64.bitwise_or(I64.shl_wrap(rt, I64.to_u8_wrap(8)), I64.bitwise_and(I64.div_trunc_by(offset, 4), 255))))

	t2_str_sp : I64, I64 -> List(I64)
	t2_str_sp = |rt, offset| t2_encode_16(I64.bitwise_or(36864, I64.bitwise_or(I64.shl_wrap(rt, I64.to_u8_wrap(8)), I64.bitwise_and(I64.div_trunc_by(offset, 4), 255))))

	t2_ldr_imm5 : I64, I64, I64 -> List(I64)
	t2_ldr_imm5 = |rt, rn, offset| t2_encode_16(I64.bitwise_or(26624, I64.bitwise_or(I64.shl_wrap(I64.bitwise_and(I64.div_trunc_by(offset, 4), 31), I64.to_u8_wrap(6)), I64.bitwise_or(I64.shl_wrap(rn, I64.to_u8_wrap(3)), rt))))

	t2_str_imm5 : I64, I64, I64 -> List(I64)
	t2_str_imm5 = |rt, rn, offset| t2_encode_16(I64.bitwise_or(24576, I64.bitwise_or(I64.shl_wrap(I64.bitwise_and(I64.div_trunc_by(offset, 4), 31), I64.to_u8_wrap(6)), I64.bitwise_or(I64.shl_wrap(rn, I64.to_u8_wrap(3)), rt))))

	t2_push : List(I64) -> List(I64)
	t2_push = |regs| ({
		mask : I64
		mask = t2_reg_mask(regs, 0, 0)
		lr_bit : I64
		lr_bit = (if t2_list_contains(regs, t2_lr) { 256 } else { 0 })
		t2_encode_16(I64.bitwise_or(46080, I64.bitwise_or(lr_bit, I64.bitwise_and(mask, 255))))
	})

	t2_pop : List(I64) -> List(I64)
	t2_pop = |regs| ({
		mask : I64
		mask = t2_reg_mask(regs, 0, 0)
		pc_bit : I64
		pc_bit = (if t2_list_contains(regs, t2_pc) { 256 } else { 0 })
		t2_encode_16(I64.bitwise_or(48128, I64.bitwise_or(pc_bit, I64.bitwise_and(mask, 255))))
	})

	t2_reg_mask : List(I64), I64, I64 -> I64
	t2_reg_mask = |regs, i, acc| (if (i >= U64.to_i64_wrap(List.len(regs))) { acc } else { ({
		r : I64
		r = (List.get(regs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		t2_reg_mask(regs, (i + 1), I64.bitwise_or(acc, I64.shl_wrap(1, I64.to_u8_wrap(r))))
	}) })

	t2_list_contains : List(I64), I64 -> Bool
	t2_list_contains = |xs, v| t2_list_contains_loop(xs, v, 0)

	t2_list_contains_loop : List(I64), I64, I64 -> Bool
	t2_list_contains_loop = |xs, v, i| (if (i >= U64.to_i64_wrap(List.len(xs))) { False } else { (if ((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) == v) { True } else { t2_list_contains_loop(xs, v, (i + 1)) }) })

	t2_cmp_reg : I64, I64 -> List(I64)
	t2_cmp_reg = |rn, rm| t2_encode_16(I64.bitwise_or(17024, I64.bitwise_or(I64.shl_wrap(rm, I64.to_u8_wrap(3)), rn)))

	t2_and_reg : I64, I64 -> List(I64)
	t2_and_reg = |rdn, rm| t2_encode_16(I64.bitwise_or(16384, I64.bitwise_or(I64.shl_wrap(rm, I64.to_u8_wrap(3)), rdn)))

	t2_or_reg : I64, I64 -> List(I64)
	t2_or_reg = |rdn, rm| t2_encode_16(I64.bitwise_or(17152, I64.bitwise_or(I64.shl_wrap(rm, I64.to_u8_wrap(3)), rdn)))

	t2_xor_reg : I64, I64 -> List(I64)
	t2_xor_reg = |rdn, rm| t2_encode_16(I64.bitwise_or(16448, I64.bitwise_or(I64.shl_wrap(rm, I64.to_u8_wrap(3)), rdn)))

	t2_mul_reg : I64, I64 -> List(I64)
	t2_mul_reg = |rdn, rm| t2_encode_16(I64.bitwise_or(17216, I64.bitwise_or(I64.shl_wrap(rm, I64.to_u8_wrap(3)), rdn)))

	t2_neg_reg : I64, I64 -> List(I64)
	t2_neg_reg = |rd, rm| t2_encode_16(I64.bitwise_or(16960, I64.bitwise_or(I64.shl_wrap(rm, I64.to_u8_wrap(3)), rd)))

	t2_lsl_imm5 : I64, I64, I64 -> List(I64)
	t2_lsl_imm5 = |rd, rm, imm5| t2_encode_16(I64.bitwise_or(I64.shl_wrap(I64.bitwise_and(imm5, 31), I64.to_u8_wrap(6)), I64.bitwise_or(I64.shl_wrap(rm, I64.to_u8_wrap(3)), rd)))

	t2_lsr_imm5 : I64, I64, I64 -> List(I64)
	t2_lsr_imm5 = |rd, rm, imm5| t2_encode_16(I64.bitwise_or(2048, I64.bitwise_or(I64.shl_wrap(I64.bitwise_and(imm5, 31), I64.to_u8_wrap(6)), I64.bitwise_or(I64.shl_wrap(rm, I64.to_u8_wrap(3)), rd))))

	t2_nop : List(I64)
	t2_nop = t2_encode_16(48896)

	t2_bx : I64 -> List(I64)
	t2_bx = |rm| t2_encode_16(I64.bitwise_or(18176, I64.shl_wrap(rm, I64.to_u8_wrap(3))))

	t2_blx : I64 -> List(I64)
	t2_blx = |rm| t2_encode_16(I64.bitwise_or(18304, I64.shl_wrap(rm, I64.to_u8_wrap(3))))

	t2_b_short : I64 -> List(I64)
	t2_b_short = |offset| ({
		imm11 : I64
		imm11 = I64.bitwise_and(I64.div_trunc_by(offset, 2), 2047)
		t2_encode_16(I64.bitwise_or(57344, imm11))
	})

	t2_beq_short : I64 -> List(I64)
	t2_beq_short = |offset| ({
		imm8 : I64
		imm8 = I64.bitwise_and(I64.div_trunc_by(offset, 2), 255)
		t2_encode_16(I64.bitwise_or(53248, imm8))
	})

	t2_bne_short : I64 -> List(I64)
	t2_bne_short = |offset| ({
		imm8 : I64
		imm8 = I64.bitwise_and(I64.div_trunc_by(offset, 2), 255)
		t2_encode_16(I64.bitwise_or(53504, imm8))
	})

	t2_blt_short : I64 -> List(I64)
	t2_blt_short = |offset| ({
		imm8 : I64
		imm8 = I64.bitwise_and(I64.div_trunc_by(offset, 2), 255)
		t2_encode_16(I64.bitwise_or(56064, imm8))
	})

	t2_bgt_short : I64 -> List(I64)
	t2_bgt_short = |offset| ({
		imm8 : I64
		imm8 = I64.bitwise_and(I64.div_trunc_by(offset, 2), 255)
		t2_encode_16(I64.bitwise_or(56320, imm8))
	})

	t2_ble_short : I64 -> List(I64)
	t2_ble_short = |offset| ({
		imm8 : I64
		imm8 = I64.bitwise_and(I64.div_trunc_by(offset, 2), 255)
		t2_encode_16(I64.bitwise_or(56576, imm8))
	})

	t2_bge_short : I64 -> List(I64)
	t2_bge_short = |offset| ({
		imm8 : I64
		imm8 = I64.bitwise_and(I64.div_trunc_by(offset, 2), 255)
		t2_encode_16(I64.bitwise_or(55808, imm8))
	})

	t2_add_sp_imm7 : I64 -> List(I64)
	t2_add_sp_imm7 = |imm| t2_encode_16(I64.bitwise_or(45056, I64.bitwise_and(I64.div_trunc_by(imm, 4), 127)))

	t2_sub_sp_imm7 : I64 -> List(I64)
	t2_sub_sp_imm7 = |imm| t2_encode_16(I64.bitwise_or(45184, I64.bitwise_and(I64.div_trunc_by(imm, 4), 127)))

	t2_movw : I64, I64 -> List(I64)
	t2_movw = |rd, imm16| ({
		imm4 : I64
		imm4 = I64.bitwise_and(I64.shr_zf_wrap(imm16, I64.to_u8_wrap(12)), 15)
		i : I64
		i = I64.bitwise_and(I64.shr_zf_wrap(imm16, I64.to_u8_wrap(11)), 1)
		imm3 : I64
		imm3 = I64.bitwise_and(I64.shr_zf_wrap(imm16, I64.to_u8_wrap(8)), 7)
		imm8 : I64
		imm8 = I64.bitwise_and(imm16, 255)
		t2_encode_32(I64.bitwise_or(I64.bitwise_or(62016, I64.shl_wrap(i, I64.to_u8_wrap(10))), imm4), I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(imm3, I64.to_u8_wrap(12)), I64.shl_wrap(rd, I64.to_u8_wrap(8))), imm8))
	})

	t2_movt : I64, I64 -> List(I64)
	t2_movt = |rd, imm16| ({
		imm4 : I64
		imm4 = I64.bitwise_and(I64.shr_zf_wrap(imm16, I64.to_u8_wrap(12)), 15)
		i : I64
		i = I64.bitwise_and(I64.shr_zf_wrap(imm16, I64.to_u8_wrap(11)), 1)
		imm3 : I64
		imm3 = I64.bitwise_and(I64.shr_zf_wrap(imm16, I64.to_u8_wrap(8)), 7)
		imm8 : I64
		imm8 = I64.bitwise_and(imm16, 255)
		t2_encode_32(I64.bitwise_or(I64.bitwise_or(62144, I64.shl_wrap(i, I64.to_u8_wrap(10))), imm4), I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(imm3, I64.to_u8_wrap(12)), I64.shl_wrap(rd, I64.to_u8_wrap(8))), imm8))
	})

	t2_add_w : I64, I64, I64 -> List(I64)
	t2_add_w = |rd, rn, rm| t2_encode_32(I64.bitwise_or(60160, rn), I64.bitwise_or(I64.shl_wrap(rd, I64.to_u8_wrap(8)), rm))

	t2_sub_w : I64, I64, I64 -> List(I64)
	t2_sub_w = |rd, rn, rm| t2_encode_32(I64.bitwise_or(60320, rn), I64.bitwise_or(I64.shl_wrap(rd, I64.to_u8_wrap(8)), rm))

	t2_mul_w : I64, I64, I64 -> List(I64)
	t2_mul_w = |rd, rn, rm| t2_encode_32(I64.bitwise_or(64256, rn), I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(15, I64.to_u8_wrap(12)), I64.shl_wrap(rd, I64.to_u8_wrap(8))), rm))

	t2_sdiv_w : I64, I64, I64 -> List(I64)
	t2_sdiv_w = |rd, rn, rm| t2_encode_32(I64.bitwise_or(64400, rn), I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(15, I64.to_u8_wrap(12)), I64.shl_wrap(rd, I64.to_u8_wrap(8))), rm))

	t2_udiv_w : I64, I64, I64 -> List(I64)
	t2_udiv_w = |rd, rn, rm| t2_encode_32(I64.bitwise_or(64432, rn), I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(15, I64.to_u8_wrap(12)), I64.shl_wrap(rd, I64.to_u8_wrap(8))), rm))

	t2_and_w : I64, I64, I64 -> List(I64)
	t2_and_w = |rd, rn, rm| t2_encode_32(I64.bitwise_or(59904, rn), I64.bitwise_or(I64.shl_wrap(rd, I64.to_u8_wrap(8)), rm))

	t2_or_w : I64, I64, I64 -> List(I64)
	t2_or_w = |rd, rn, rm| t2_encode_32(I64.bitwise_or(59968, rn), I64.bitwise_or(I64.shl_wrap(rd, I64.to_u8_wrap(8)), rm))

	t2_xor_w : I64, I64, I64 -> List(I64)
	t2_xor_w = |rd, rn, rm| t2_encode_32(I64.bitwise_or(60032, rn), I64.bitwise_or(I64.shl_wrap(rd, I64.to_u8_wrap(8)), rm))

	t2_cmp_w : I64, I64 -> List(I64)
	t2_cmp_w = |rn, rm| t2_encode_32(I64.bitwise_or(60336, rn), I64.bitwise_or(I64.shl_wrap(15, I64.to_u8_wrap(8)), rm))

	t2_ldr_w : I64, I64, I64 -> List(I64)
	t2_ldr_w = |rt, rn, offset| t2_encode_32(I64.bitwise_or(63696, rn), I64.bitwise_or(I64.shl_wrap(rt, I64.to_u8_wrap(12)), I64.bitwise_and(offset, 4095)))

	t2_str_w : I64, I64, I64 -> List(I64)
	t2_str_w = |rt, rn, offset| t2_encode_32(I64.bitwise_or(63680, rn), I64.bitwise_or(I64.shl_wrap(rt, I64.to_u8_wrap(12)), I64.bitwise_and(offset, 4095)))

	t2_bl : I64 -> List(I64)
	t2_bl = |offset| ({
		s : I64
		s = I64.bitwise_and(I64.shr_zf_wrap(offset, I64.to_u8_wrap(24)), 1)
		imm10 : I64
		imm10 = I64.bitwise_and(I64.shr_zf_wrap(offset, I64.to_u8_wrap(12)), 1023)
		j1 : I64
		j1 = I64.bitwise_xor(I64.bitwise_and(I64.shr_zf_wrap(offset, I64.to_u8_wrap(23)), 1), I64.bitwise_xor(s, 1))
		j2 : I64
		j2 = I64.bitwise_xor(I64.bitwise_and(I64.shr_zf_wrap(offset, I64.to_u8_wrap(22)), 1), I64.bitwise_xor(s, 1))
		imm11 : I64
		imm11 = I64.bitwise_and(I64.shr_zf_wrap(offset, I64.to_u8_wrap(1)), 2047)
		t2_encode_32(I64.bitwise_or(I64.bitwise_or(61440, I64.shl_wrap(s, I64.to_u8_wrap(10))), imm10), I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(53248, I64.shl_wrap(j1, I64.to_u8_wrap(13))), I64.shl_wrap(j2, I64.to_u8_wrap(11))), imm11))
	})

	t2_b_w : I64 -> List(I64)
	t2_b_w = |offset| ({
		s : I64
		s = I64.bitwise_and(I64.shr_zf_wrap(offset, I64.to_u8_wrap(24)), 1)
		imm10 : I64
		imm10 = I64.bitwise_and(I64.shr_zf_wrap(offset, I64.to_u8_wrap(12)), 1023)
		j1 : I64
		j1 = I64.bitwise_xor(I64.bitwise_and(I64.shr_zf_wrap(offset, I64.to_u8_wrap(23)), 1), I64.bitwise_xor(s, 1))
		j2 : I64
		j2 = I64.bitwise_xor(I64.bitwise_and(I64.shr_zf_wrap(offset, I64.to_u8_wrap(22)), 1), I64.bitwise_xor(s, 1))
		imm11 : I64
		imm11 = I64.bitwise_and(I64.shr_zf_wrap(offset, I64.to_u8_wrap(1)), 2047)
		t2_encode_32(I64.bitwise_or(I64.bitwise_or(61440, I64.shl_wrap(s, I64.to_u8_wrap(10))), imm10), I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(36864, I64.shl_wrap(j1, I64.to_u8_wrap(13))), I64.shl_wrap(j2, I64.to_u8_wrap(11))), imm11))
	})

	t2_add_sp_imm12 : I64, I64 -> List(I64)
	t2_add_sp_imm12 = |rd, imm12| ({
		i : I64
		i = I64.bitwise_and(I64.shr_zf_wrap(imm12, I64.to_u8_wrap(11)), 1)
		imm3 : I64
		imm3 = I64.bitwise_and(I64.shr_zf_wrap(imm12, I64.to_u8_wrap(8)), 7)
		imm8 : I64
		imm8 = I64.bitwise_and(imm12, 255)
		t2_encode_32(I64.bitwise_or(61965, I64.shl_wrap(i, I64.to_u8_wrap(10))), I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(imm3, I64.to_u8_wrap(12)), I64.shl_wrap(rd, I64.to_u8_wrap(8))), imm8))
	})

	t2_sub_sp_imm12 : I64, I64 -> List(I64)
	t2_sub_sp_imm12 = |rd, imm12| ({
		i : I64
		i = I64.bitwise_and(I64.shr_zf_wrap(imm12, I64.to_u8_wrap(11)), 1)
		imm3 : I64
		imm3 = I64.bitwise_and(I64.shr_zf_wrap(imm12, I64.to_u8_wrap(8)), 7)
		imm8 : I64
		imm8 = I64.bitwise_and(imm12, 255)
		t2_encode_32(I64.bitwise_or(62125, I64.shl_wrap(i, I64.to_u8_wrap(10))), I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(imm3, I64.to_u8_wrap(12)), I64.shl_wrap(rd, I64.to_u8_wrap(8))), imm8))
	})

	t2_stmdb : I64, I64 -> List(I64)
	t2_stmdb = |rn, reg_list| t2_encode_32(I64.bitwise_or(59648, rn), reg_list)

	t2_ldmia : I64, I64 -> List(I64)
	t2_ldmia = |rn, reg_list| t2_encode_32(I64.bitwise_or(59536, rn), reg_list)

	t2_ret : List(I64)
	t2_ret = t2_bx(t2_lr)

	t2_mov : I64, I64 -> List(I64)
	t2_mov = |rd, rs| (if (rd <= 7) { (if (rs <= 7) { t2_add_imm3(rd, rs, 0) } else { t2_mov_lo(rd, rs) }) } else { t2_mov_lo(rd, rs) })

	t2_li : I64, I64 -> List(I64)
	t2_li = |rd, value| (if (value >= 0) { (if (value <= 255) { t2_mov_imm8(rd, value) } else { (if (value <= 65535) { t2_movw(rd, value) } else { List.concat(t2_movw(rd, I64.bitwise_and(value, 65535)), t2_movt(rd, I64.bitwise_and(I64.shr_zf_wrap(value, I64.to_u8_wrap(16)), 65535))) }) }) } else { (if (value >= (-128)) { List.concat(t2_mov_imm8(rd, 0), t2_sub_imm8(rd, (0 - value))) } else { List.concat(t2_movw(rd, I64.bitwise_and(value, 65535)), t2_movt(rd, I64.bitwise_and(I64.shr_zf_wrap(value, I64.to_u8_wrap(16)), 65535))) }) })
}
