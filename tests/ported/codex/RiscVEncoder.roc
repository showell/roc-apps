# RiscVEncoder -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

RiscVEncoder :: [].{

	rv_zero : I64
	rv_zero = 0

	rv_ra : I64
	rv_ra = 1

	rv_sp : I64
	rv_sp = 2

	rv_gp : I64
	rv_gp = 3

	rv_tp : I64
	rv_tp = 4

	rv_t0 : I64
	rv_t0 = 5

	rv_t1 : I64
	rv_t1 = 6

	rv_t2 : I64
	rv_t2 = 7

	rv_s0 : I64
	rv_s0 = 8

	rv_s1 : I64
	rv_s1 = 9

	rv_a0 : I64
	rv_a0 = 10

	rv_a1 : I64
	rv_a1 = 11

	rv_a2 : I64
	rv_a2 = 12

	rv_a3 : I64
	rv_a3 = 13

	rv_a4 : I64
	rv_a4 = 14

	rv_a5 : I64
	rv_a5 = 15

	rv_a6 : I64
	rv_a6 = 16

	rv_a7 : I64
	rv_a7 = 17

	rv_s2 : I64
	rv_s2 = 18

	rv_s3 : I64
	rv_s3 = 19

	rv_s4 : I64
	rv_s4 = 20

	rv_s5 : I64
	rv_s5 = 21

	rv_s6 : I64
	rv_s6 = 22

	rv_s7 : I64
	rv_s7 = 23

	rv_s8 : I64
	rv_s8 = 24

	rv_s9 : I64
	rv_s9 = 25

	rv_s10 : I64
	rv_s10 = 26

	rv_s11 : I64
	rv_s11 = 27

	rv_t3 : I64
	rv_t3 = 28

	rv_t4 : I64
	rv_t4 = 29

	rv_t5 : I64
	rv_t5 = 30

	rv_t6 : I64
	rv_t6 = 31

	rv_encode : I64 -> List(I64)
	rv_encode = |w| [I64.bitwise_and(w, 255), I64.bitwise_and(I64.shr_zf_wrap(w, I64.to_u8_wrap(8)), 255), I64.bitwise_and(I64.shr_zf_wrap(w, I64.to_u8_wrap(16)), 255), I64.bitwise_and(I64.shr_zf_wrap(w, I64.to_u8_wrap(24)), 255)]

	rv_r_type : I64, I64, I64, I64, I64, I64 -> List(I64)
	rv_r_type = |opcode, rd, funct3, rs1, rs2, funct7| rv_encode(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(opcode, I64.shl_wrap(rd, I64.to_u8_wrap(7))), I64.shl_wrap(funct3, I64.to_u8_wrap(12))), I64.shl_wrap(rs1, I64.to_u8_wrap(15))), I64.shl_wrap(rs2, I64.to_u8_wrap(20))), I64.shl_wrap(funct7, I64.to_u8_wrap(25))))

	rv_i_type : I64, I64, I64, I64, I64 -> List(I64)
	rv_i_type = |opcode, rd, funct3, rs1, imm12| rv_encode(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(opcode, I64.shl_wrap(rd, I64.to_u8_wrap(7))), I64.shl_wrap(funct3, I64.to_u8_wrap(12))), I64.shl_wrap(rs1, I64.to_u8_wrap(15))), I64.shl_wrap(I64.bitwise_and(imm12, 4095), I64.to_u8_wrap(20))))

	rv_s_type : I64, I64, I64, I64, I64 -> List(I64)
	rv_s_type = |opcode, funct3, rs1, rs2, imm12| ({
		imm = I64.bitwise_and(imm12, 4095)
		lo5 = I64.bitwise_and(imm, 31)
		hi7 = I64.bitwise_and(I64.shr_zf_wrap(imm, I64.to_u8_wrap(5)), 127)
		rv_encode(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(opcode, I64.shl_wrap(lo5, I64.to_u8_wrap(7))), I64.shl_wrap(funct3, I64.to_u8_wrap(12))), I64.shl_wrap(rs1, I64.to_u8_wrap(15))), I64.shl_wrap(rs2, I64.to_u8_wrap(20))), I64.shl_wrap(hi7, I64.to_u8_wrap(25))))
	})

	rv_b_type : I64, I64, I64, I64, I64 -> List(I64)
	rv_b_type = |opcode, funct3, rs1, rs2, imm13| ({
		imm = I64.bitwise_and(imm13, 8190)
		bit11 = I64.bitwise_and(I64.shr_zf_wrap(imm, I64.to_u8_wrap(11)), 1)
		bits4_1 = I64.bitwise_and(I64.shr_zf_wrap(imm, I64.to_u8_wrap(1)), 15)
		bits10_5 = I64.bitwise_and(I64.shr_zf_wrap(imm, I64.to_u8_wrap(5)), 63)
		bit12 = I64.bitwise_and(I64.shr_zf_wrap(imm, I64.to_u8_wrap(12)), 1)
		rv_encode(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(opcode, I64.shl_wrap(bit11, I64.to_u8_wrap(7))), I64.shl_wrap(bits4_1, I64.to_u8_wrap(8))), I64.shl_wrap(funct3, I64.to_u8_wrap(12))), I64.shl_wrap(rs1, I64.to_u8_wrap(15))), I64.shl_wrap(rs2, I64.to_u8_wrap(20))), I64.bitwise_or(I64.shl_wrap(bits10_5, I64.to_u8_wrap(25)), I64.shl_wrap(bit12, I64.to_u8_wrap(31)))))
	})

	rv_u_type : I64, I64, I64 -> List(I64)
	rv_u_type = |opcode, rd, imm20| rv_encode(I64.bitwise_or(I64.bitwise_or(opcode, I64.shl_wrap(rd, I64.to_u8_wrap(7))), I64.shl_wrap(I64.bitwise_and(imm20, 1048575), I64.to_u8_wrap(12))))

	rv_j_type : I64, I64, I64 -> List(I64)
	rv_j_type = |opcode, rd, imm21| ({
		imm = I64.bitwise_and(imm21, 2097151)
		bits19_12 = I64.bitwise_and(I64.shr_zf_wrap(imm, I64.to_u8_wrap(12)), 255)
		bit11 = I64.bitwise_and(I64.shr_zf_wrap(imm, I64.to_u8_wrap(11)), 1)
		bits10_1 = I64.bitwise_and(I64.shr_zf_wrap(imm, I64.to_u8_wrap(1)), 1023)
		bit20 = I64.bitwise_and(I64.shr_zf_wrap(imm, I64.to_u8_wrap(20)), 1)
		rv_encode(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(opcode, I64.shl_wrap(rd, I64.to_u8_wrap(7))), I64.shl_wrap(bits19_12, I64.to_u8_wrap(12))), I64.shl_wrap(bit11, I64.to_u8_wrap(20))), I64.bitwise_or(I64.shl_wrap(bits10_1, I64.to_u8_wrap(21)), I64.shl_wrap(bit20, I64.to_u8_wrap(31)))))
	})

	rv_add : I64, I64, I64 -> List(I64)
	rv_add = |rd, rs1, rs2| rv_r_type(51, rd, 0, rs1, rs2, 0)

	rv_sub : I64, I64, I64 -> List(I64)
	rv_sub = |rd, rs1, rs2| rv_r_type(51, rd, 0, rs1, rs2, 32)

	rv_mul : I64, I64, I64 -> List(I64)
	rv_mul = |rd, rs1, rs2| rv_r_type(51, rd, 0, rs1, rs2, 1)

	rv_div : I64, I64, I64 -> List(I64)
	rv_div = |rd, rs1, rs2| rv_r_type(51, rd, 4, rs1, rs2, 1)

	rv_rem : I64, I64, I64 -> List(I64)
	rv_rem = |rd, rs1, rs2| rv_r_type(51, rd, 6, rs1, rs2, 1)

	rv_divu : I64, I64, I64 -> List(I64)
	rv_divu = |rd, rs1, rs2| rv_r_type(51, rd, 5, rs1, rs2, 1)

	rv_remu : I64, I64, I64 -> List(I64)
	rv_remu = |rd, rs1, rs2| rv_r_type(51, rd, 7, rs1, rs2, 1)

	rv_and : I64, I64, I64 -> List(I64)
	rv_and = |rd, rs1, rs2| rv_r_type(51, rd, 7, rs1, rs2, 0)

	rv_or : I64, I64, I64 -> List(I64)
	rv_or = |rd, rs1, rs2| rv_r_type(51, rd, 6, rs1, rs2, 0)

	rv_xor : I64, I64, I64 -> List(I64)
	rv_xor = |rd, rs1, rs2| rv_r_type(51, rd, 4, rs1, rs2, 0)

	rv_sll : I64, I64, I64 -> List(I64)
	rv_sll = |rd, rs1, rs2| rv_r_type(51, rd, 1, rs1, rs2, 0)

	rv_srl : I64, I64, I64 -> List(I64)
	rv_srl = |rd, rs1, rs2| rv_r_type(51, rd, 5, rs1, rs2, 0)

	rv_sra : I64, I64, I64 -> List(I64)
	rv_sra = |rd, rs1, rs2| rv_r_type(51, rd, 5, rs1, rs2, 32)

	rv_slt : I64, I64, I64 -> List(I64)
	rv_slt = |rd, rs1, rs2| rv_r_type(51, rd, 2, rs1, rs2, 0)

	rv_sltu : I64, I64, I64 -> List(I64)
	rv_sltu = |rd, rs1, rs2| rv_r_type(51, rd, 3, rs1, rs2, 0)

	rv_addi : I64, I64, I64 -> List(I64)
	rv_addi = |rd, rs1, imm| rv_i_type(19, rd, 0, rs1, imm)

	rv_andi : I64, I64, I64 -> List(I64)
	rv_andi = |rd, rs1, imm| rv_i_type(19, rd, 7, rs1, imm)

	rv_ori : I64, I64, I64 -> List(I64)
	rv_ori = |rd, rs1, imm| rv_i_type(19, rd, 6, rs1, imm)

	rv_xori : I64, I64, I64 -> List(I64)
	rv_xori = |rd, rs1, imm| rv_i_type(19, rd, 4, rs1, imm)

	rv_slti : I64, I64, I64 -> List(I64)
	rv_slti = |rd, rs1, imm| rv_i_type(19, rd, 2, rs1, imm)

	rv_slli : I64, I64, I64 -> List(I64)
	rv_slli = |rd, rs1, shamt| rv_i_type(19, rd, 1, rs1, I64.bitwise_and(shamt, 63))

	rv_srli : I64, I64, I64 -> List(I64)
	rv_srli = |rd, rs1, shamt| rv_i_type(19, rd, 5, rs1, I64.bitwise_and(shamt, 63))

	rv_srai : I64, I64, I64 -> List(I64)
	rv_srai = |rd, rs1, shamt| rv_i_type(19, rd, 5, rs1, I64.bitwise_or(I64.bitwise_and(shamt, 63), 1024))

	rv_addiw : I64, I64, I64 -> List(I64)
	rv_addiw = |rd, rs1, imm| rv_i_type(27, rd, 0, rs1, imm)

	rv_ld : I64, I64, I64 -> List(I64)
	rv_ld = |rd, rs1, offset| rv_i_type(3, rd, 3, rs1, offset)

	rv_lw : I64, I64, I64 -> List(I64)
	rv_lw = |rd, rs1, offset| rv_i_type(3, rd, 2, rs1, offset)

	rv_lb : I64, I64, I64 -> List(I64)
	rv_lb = |rd, rs1, offset| rv_i_type(3, rd, 0, rs1, offset)

	rv_lbu : I64, I64, I64 -> List(I64)
	rv_lbu = |rd, rs1, offset| rv_i_type(3, rd, 4, rs1, offset)

	rv_lhu : I64, I64, I64 -> List(I64)
	rv_lhu = |rd, rs1, offset| rv_i_type(3, rd, 5, rs1, offset)

	rv_sd : I64, I64, I64 -> List(I64)
	rv_sd = |rs1, rs2, offset| rv_s_type(35, 3, rs1, rs2, offset)

	rv_sw : I64, I64, I64 -> List(I64)
	rv_sw = |rs1, rs2, offset| rv_s_type(35, 2, rs1, rs2, offset)

	rv_sb : I64, I64, I64 -> List(I64)
	rv_sb = |rs1, rs2, offset| rv_s_type(35, 0, rs1, rs2, offset)

	rv_sh : I64, I64, I64 -> List(I64)
	rv_sh = |rs1, rs2, offset| rv_s_type(35, 1, rs1, rs2, offset)

	rv_fld : I64, I64, I64 -> List(I64)
	rv_fld = |fd, rs1, offset| rv_i_type(7, fd, 3, rs1, offset)

	rv_fsd : I64, I64, I64 -> List(I64)
	rv_fsd = |rs1, fs2, offset| rv_s_type(39, 3, rs1, fs2, offset)

	rv_flw : I64, I64, I64 -> List(I64)
	rv_flw = |fd, rs1, offset| rv_i_type(7, fd, 2, rs1, offset)

	rv_fsw : I64, I64, I64 -> List(I64)
	rv_fsw = |rs1, fs2, offset| rv_s_type(39, 2, rs1, fs2, offset)

	rv_beq : I64, I64, I64 -> List(I64)
	rv_beq = |rs1, rs2, offset| rv_b_type(99, 0, rs1, rs2, offset)

	rv_bne : I64, I64, I64 -> List(I64)
	rv_bne = |rs1, rs2, offset| rv_b_type(99, 1, rs1, rs2, offset)

	rv_blt : I64, I64, I64 -> List(I64)
	rv_blt = |rs1, rs2, offset| rv_b_type(99, 4, rs1, rs2, offset)

	rv_bge : I64, I64, I64 -> List(I64)
	rv_bge = |rs1, rs2, offset| rv_b_type(99, 5, rs1, rs2, offset)

	rv_bltu : I64, I64, I64 -> List(I64)
	rv_bltu = |rs1, rs2, offset| rv_b_type(99, 6, rs1, rs2, offset)

	rv_bgeu : I64, I64, I64 -> List(I64)
	rv_bgeu = |rs1, rs2, offset| rv_b_type(99, 7, rs1, rs2, offset)

	rv_lui : I64, I64 -> List(I64)
	rv_lui = |rd, imm20| rv_u_type(55, rd, imm20)

	rv_auipc : I64, I64 -> List(I64)
	rv_auipc = |rd, imm20| rv_u_type(23, rd, imm20)

	rv_jal : I64, I64 -> List(I64)
	rv_jal = |rd, offset| rv_j_type(111, rd, offset)

	rv_jalr : I64, I64, I64 -> List(I64)
	rv_jalr = |rd, rs1, offset| rv_i_type(103, rd, 0, rs1, offset)

	rv_ecall : List(I64)
	rv_ecall = rv_i_type(115, 0, 0, 0, 0)

	rv_ebreak : List(I64)
	rv_ebreak = rv_i_type(115, 0, 0, 0, 1)

	rv_wfi : List(I64)
	rv_wfi = rv_i_type(115, 0, 0, 0, 261)

	rv_fence : List(I64)
	rv_fence = rv_encode(267386895)

	rv_csrrw : I64, I64, I64 -> List(I64)
	rv_csrrw = |rd, csr, rs1| rv_i_type(115, rd, 1, rs1, csr)

	rv_csrrs : I64, I64, I64 -> List(I64)
	rv_csrrs = |rd, csr, rs1| rv_i_type(115, rd, 2, rs1, csr)

	rv_csrrc : I64, I64, I64 -> List(I64)
	rv_csrrc = |rd, csr, rs1| rv_i_type(115, rd, 3, rs1, csr)

	rv_csrr : I64, I64 -> List(I64)
	rv_csrr = |rd, csr| rv_csrrs(rd, csr, rv_zero)

	rv_csrw : I64, I64 -> List(I64)
	rv_csrw = |csr, rs1| rv_csrrw(rv_zero, csr, rs1)

	rv_lr_d : I64, I64 -> List(I64)
	rv_lr_d = |rd, rs1| rv_r_type(47, rd, 3, rs1, 0, 11)

	rv_sc_d : I64, I64, I64 -> List(I64)
	rv_sc_d = |rd, rs2, rs1| rv_r_type(47, rd, 3, rs1, rs2, 15)

	rv_amoswap_d : I64, I64, I64 -> List(I64)
	rv_amoswap_d = |rd, rs2, rs1| rv_r_type(47, rd, 3, rs1, rs2, 7)

	rv_amoadd_d : I64, I64, I64 -> List(I64)
	rv_amoadd_d = |rd, rs2, rs1| rv_r_type(47, rd, 3, rs1, rs2, 3)

	rv_ft0 : I64
	rv_ft0 = 0

	rv_ft1 : I64
	rv_ft1 = 1

	rv_ft2 : I64
	rv_ft2 = 2

	rv_fadd_d : I64, I64, I64 -> List(I64)
	rv_fadd_d = |fd, fs1, fs2| rv_r_type(83, fd, 0, fs1, fs2, 1)

	rv_fsub_d : I64, I64, I64 -> List(I64)
	rv_fsub_d = |fd, fs1, fs2| rv_r_type(83, fd, 0, fs1, fs2, 5)

	rv_fmul_d : I64, I64, I64 -> List(I64)
	rv_fmul_d = |fd, fs1, fs2| rv_r_type(83, fd, 0, fs1, fs2, 9)

	rv_fdiv_d : I64, I64, I64 -> List(I64)
	rv_fdiv_d = |fd, fs1, fs2| rv_r_type(83, fd, 0, fs1, fs2, 13)

	rv_fadd_s : I64, I64, I64 -> List(I64)
	rv_fadd_s = |fd, fs1, fs2| rv_r_type(83, fd, 0, fs1, fs2, 0)

	rv_fsub_s : I64, I64, I64 -> List(I64)
	rv_fsub_s = |fd, fs1, fs2| rv_r_type(83, fd, 0, fs1, fs2, 4)

	rv_fmul_s : I64, I64, I64 -> List(I64)
	rv_fmul_s = |fd, fs1, fs2| rv_r_type(83, fd, 0, fs1, fs2, 8)

	rv_fdiv_s : I64, I64, I64 -> List(I64)
	rv_fdiv_s = |fd, fs1, fs2| rv_r_type(83, fd, 0, fs1, fs2, 12)

	rv_feq_d : I64, I64, I64 -> List(I64)
	rv_feq_d = |rd, fs1, fs2| rv_r_type(83, rd, 2, fs1, fs2, 81)

	rv_flt_d : I64, I64, I64 -> List(I64)
	rv_flt_d = |rd, fs1, fs2| rv_r_type(83, rd, 1, fs1, fs2, 81)

	rv_fle_d : I64, I64, I64 -> List(I64)
	rv_fle_d = |rd, fs1, fs2| rv_r_type(83, rd, 0, fs1, fs2, 81)

	rv_feq_s : I64, I64, I64 -> List(I64)
	rv_feq_s = |rd, fs1, fs2| rv_r_type(83, rd, 2, fs1, fs2, 80)

	rv_flt_s : I64, I64, I64 -> List(I64)
	rv_flt_s = |rd, fs1, fs2| rv_r_type(83, rd, 1, fs1, fs2, 80)

	rv_fle_s : I64, I64, I64 -> List(I64)
	rv_fle_s = |rd, fs1, fs2| rv_r_type(83, rd, 0, fs1, fs2, 80)

	rv_fsgnjn_d : I64, I64, I64 -> List(I64)
	rv_fsgnjn_d = |fd, fs1, fs2| rv_r_type(83, fd, 1, fs1, fs2, 17)

	rv_fsgnjn_s : I64, I64, I64 -> List(I64)
	rv_fsgnjn_s = |fd, fs1, fs2| rv_r_type(83, fd, 1, fs1, fs2, 16)

	rv_fmv_d_x : I64, I64 -> List(I64)
	rv_fmv_d_x = |fd, rs1| rv_r_type(83, fd, 0, rs1, 0, 121)

	rv_fmv_x_d : I64, I64 -> List(I64)
	rv_fmv_x_d = |rd, fs1| rv_r_type(83, rd, 0, fs1, 0, 113)

	rv_fmv_w_x : I64, I64 -> List(I64)
	rv_fmv_w_x = |fd, rs1| rv_r_type(83, fd, 0, rs1, 0, 120)

	rv_fmv_x_w : I64, I64 -> List(I64)
	rv_fmv_x_w = |rd, fs1| rv_r_type(83, rd, 0, fs1, 0, 112)

	rv_fcvt_d_l : I64, I64 -> List(I64)
	rv_fcvt_d_l = |fd, rs1| rv_r_type(83, fd, 0, rs1, 2, 105)

	rv_fcvt_l_d : I64, I64 -> List(I64)
	rv_fcvt_l_d = |rd, fs1| rv_r_type(83, rd, 1, fs1, 2, 97)

	rv_fcvt_s_d : I64, I64 -> List(I64)
	rv_fcvt_s_d = |fd, fs1| rv_r_type(83, fd, 0, fs1, 1, 32)

	rv_fcvt_d_s : I64, I64 -> List(I64)
	rv_fcvt_d_s = |fd, fs1| rv_r_type(83, fd, 0, fs1, 0, 33)

	rv_fcvt_s_l : I64, I64 -> List(I64)
	rv_fcvt_s_l = |fd, rs1| rv_r_type(83, fd, 0, rs1, 2, 104)

	rv_fcvt_l_s : I64, I64 -> List(I64)
	rv_fcvt_l_s = |rd, fs1| rv_r_type(83, rd, 1, fs1, 2, 96)

	rv_nop : List(I64)
	rv_nop = rv_addi(0, 0, 0)

	rv_mv : I64, I64 -> List(I64)
	rv_mv = |rd, rs| rv_addi(rd, rs, 0)

	rv_ret : List(I64)
	rv_ret = rv_jalr(0, rv_ra, 0)

	rv_j : I64 -> List(I64)
	rv_j = |offset| rv_jal(0, offset)

	rv_call : I64 -> List(I64)
	rv_call = |offset| rv_jal(rv_ra, offset)

	rv_li_fits_32 : I64 -> Bool
	rv_li_fits_32 = |value| (if (value < (0 - 2147483648)) { False } else { (if (value > 2147483647) { False } else { True }) })

	rv_li : I64, I64 -> List(I64)
	rv_li = |rd, value| (if (value >= (-2048)) { (if (value <= 2047) { rv_addi(rd, 0, value) } else { (if rv_li_fits_32(value) { rv_li_large(rd, value) } else { rv_li_64(rd, value) }) }) } else { (if rv_li_fits_32(value) { rv_li_large(rd, value) } else { rv_li_64(rd, value) }) })

	rv_li_hi20 : I64 -> I64
	rv_li_hi20 = |value| ({
		v32 = I64.bitwise_and((value + 2048), 4294967295)
		raw = I64.shr_zf_wrap(v32, I64.to_u8_wrap(12))
		(if (raw >= 524288) { (raw - 1048576) } else { raw })
	})

	rv_li_top_band : I64, I64 -> List(I64)
	rv_li_top_band = |rd, rest| (if (rest <= 2047) { rv_addi(rd, rd, rest) } else { List.concat(rv_addi(rd, rd, 2047), rv_addi(rd, rd, (rest - 2047))) })

	rv_li_large : I64, I64 -> List(I64)
	rv_li_large = |rd, value| (if (value > 2147481599) { List.concat(List.concat(rv_lui(rd, 524287), rv_addi(rd, rd, 2047)), rv_li_top_band(rd, (value - 2147481599))) } else { ({
		hi20 = rv_li_hi20(value)
		lo12 = (value - (hi20 * 4096))
		(if (lo12 == 0) { rv_lui(rd, hi20) } else { List.concat(rv_lui(rd, hi20), rv_addi(rd, rd, lo12)) })
	}) })

	rv_li_64 : I64, I64 -> List(I64)
	rv_li_64 = |rd, value| ({
		lo32 = I64.bitwise_and(value, 4294967295)
		lo32_signed = (if (lo32 >= 2147483648) { (lo32 - 4294967296) } else { lo32 })
		hi32 = I64.shr_zf_wrap(value, I64.to_u8_wrap(32))
		hi32_adj = (if (lo32_signed < 0) { (hi32 + 1) } else { hi32 })
		tmp = (if (rd == rv_t0) { rv_t1 } else { rv_t0 })
		hi_insns = rv_li(rd, hi32_adj)
		shifted = List.concat(hi_insns, rv_slli(rd, rd, 32))
		(if (lo32 == 0) { shifted } else { List.concat(List.concat(shifted, rv_li(tmp, lo32_signed)), rv_add(rd, rd, tmp)) })
	})
}
