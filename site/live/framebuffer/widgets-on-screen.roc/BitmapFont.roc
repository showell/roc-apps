# BitmapFont -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Mem

BitmapFont :: [].{
	CbfFont : { cbf_base : I64 }

	cbf_glyph_height : I64
	cbf_glyph_height = 16

	cbf_glyph_width : I64
	cbf_glyph_width = 8

	cbf_glyph_count : I64
	cbf_glyph_count = 128

	cbf_data_size : I64
	cbf_data_size = 2048

	cbf_init! : Mem.Mem => (Mem.Mem, BitmapFont.CbfFont)
	cbf_init! = |mem| ({
		(mem3, mem__1) = ({
		(mem1, base) = Mem.alloc(mem, cbf_data_size)
		(mem2, w) = cbf_write_all!(mem1, base)
		(mem2, { cbf_base: ((base + w) - w) })
	})
		(mem3, mem__1)
	})

	cbf_row! : Mem.Mem, BitmapFont.CbfFont, I64, I64 => (Mem.Mem, I64)
	cbf_row! = |mem, font, cce, row| (if (cce < 0) { (mem, 0) } else { (if (cce >= cbf_glyph_count) { (mem, 0) } else { (if (row < 0) { (mem, 0) } else { (if (row >= cbf_glyph_height) { (mem, 0) } else { Mem.load!(mem, font.cbf_base, ((cce * cbf_glyph_height) + row), 1) }) }) }) })

	cbf_pixel! : Mem.Mem, BitmapFont.CbfFont, I64, I64, I64 => (Mem.Mem, Bool)
	cbf_pixel! = |mem, font, cce, col, row| ({
		(mem2, mem__2) = ({
		(mem1, glyph_byte) = cbf_row!(mem, font, cce, row)
		(mem1, (I64.bitwise_and(I64.shr_zf_wrap(glyph_byte, I64.to_u8_wrap((7 - col))), 1) == 1))
	})
		(mem2, mem__2)
	})

	cbf_write_all! : Mem.Mem, I64 => (Mem.Mem, I64)
	cbf_write_all! = |mem, base| ({
		(mem8, mem__3) = ({
		(mem1, w0) = cbf_write_whitespace!(mem, base)
		(mem2, w1) = cbf_write_digits!(mem1, base)
		(mem3, w2) = cbf_write_lower!(mem2, base)
		(mem4, w3) = cbf_write_upper!(mem3, base)
		(mem5, w4) = cbf_write_punct!(mem4, base)
		(mem6, w5) = cbf_write_accented!(mem5, base)
		(mem7, w6) = cbf_write_cyrillic!(mem6, base)
		(mem7, ((((((w0 + w1) + w2) + w3) + w4) + w5) + w6))
	})
		(mem8, mem__3)
	})

	cbf_write_whitespace! : Mem.Mem, I64 => (Mem.Mem, I64)
	cbf_write_whitespace! = |mem, b| ({
		(mem4, mem__4) = ({
		(mem1, w0) = cbf_g!(mem, b, 0, 0, 0, 0, 0, 0, 0, 0, 0)
		(mem2, w1) = cbf_g!(mem1, b, 1, 0, 0, 0, 0, 0, 0, 0, 0)
		(mem3, w2) = cbf_g!(mem2, b, 2, 0, 0, 0, 0, 0, 0, 0, 0)
		(mem3, ((w0 + w1) + w2))
	})
		(mem4, mem__4)
	})

	cbf_write_digits! : Mem.Mem, I64 => (Mem.Mem, I64)
	cbf_write_digits! = |mem, b| ({
		(mem11, mem__5) = ({
		(mem1, w0) = cbf_g!(mem, b, 3, 60, 102, 110, 118, 102, 102, 60, 0)
		(mem2, w1) = cbf_g!(mem1, b, 4, 24, 56, 24, 24, 24, 24, 126, 0)
		(mem3, w2) = cbf_g!(mem2, b, 5, 60, 102, 6, 12, 24, 48, 126, 0)
		(mem4, w3) = cbf_g!(mem3, b, 6, 60, 102, 6, 28, 6, 102, 60, 0)
		(mem5, w4) = cbf_g!(mem4, b, 7, 12, 28, 44, 108, 126, 12, 12, 0)
		(mem6, w5) = cbf_g!(mem5, b, 8, 126, 96, 124, 6, 6, 102, 60, 0)
		(mem7, w6) = cbf_g!(mem6, b, 9, 60, 96, 96, 124, 102, 102, 60, 0)
		(mem8, w7) = cbf_g!(mem7, b, 10, 126, 6, 12, 24, 48, 48, 48, 0)
		(mem9, w8) = cbf_g!(mem8, b, 11, 60, 102, 102, 60, 102, 102, 60, 0)
		(mem10, w9) = cbf_g!(mem9, b, 12, 60, 102, 102, 62, 6, 6, 60, 0)
		(mem10, (((((((((w0 + w1) + w2) + w3) + w4) + w5) + w6) + w7) + w8) + w9))
	})
		(mem11, mem__5)
	})

	cbf_write_lower! : Mem.Mem, I64 => (Mem.Mem, I64)
	cbf_write_lower! = |mem, b| ({
		(mem27, mem__6) = ({
		(mem1, we) = cbf_g!(mem, b, 13, 0, 0, 60, 102, 126, 96, 60, 0)
		(mem2, wt) = cbf_g!(mem1, b, 14, 48, 48, 124, 48, 48, 48, 28, 0)
		(mem3, wa) = cbf_g!(mem2, b, 15, 0, 0, 60, 6, 62, 102, 62, 0)
		(mem4, wo) = cbf_g!(mem3, b, 16, 0, 0, 60, 102, 102, 102, 60, 0)
		(mem5, wi) = cbf_g!(mem4, b, 17, 24, 0, 56, 24, 24, 24, 60, 0)
		(mem6, wn) = cbf_g!(mem5, b, 18, 0, 0, 124, 102, 102, 102, 102, 0)
		(mem7, ws) = cbf_g!(mem6, b, 19, 0, 0, 62, 96, 60, 6, 124, 0)
		(mem8, wh) = cbf_g!(mem7, b, 20, 96, 96, 124, 102, 102, 102, 102, 0)
		(mem9, wr) = cbf_g!(mem8, b, 21, 0, 0, 124, 102, 96, 96, 96, 0)
		(mem10, wd) = cbf_g!(mem9, b, 22, 6, 6, 62, 102, 102, 102, 62, 0)
		(mem11, wl) = cbf_g!(mem10, b, 23, 56, 24, 24, 24, 24, 24, 60, 0)
		(mem12, wc) = cbf_g!(mem11, b, 24, 0, 0, 60, 102, 96, 102, 60, 0)
		(mem13, wu) = cbf_g!(mem12, b, 25, 0, 0, 102, 102, 102, 102, 62, 0)
		(mem14, wm) = cbf_g!(mem13, b, 26, 0, 0, 102, 127, 107, 99, 99, 0)
		(mem15, ww) = cbf_g!(mem14, b, 27, 0, 0, 99, 99, 107, 127, 54, 0)
		(mem16, wf) = cbf_g!(mem15, b, 28, 28, 48, 48, 124, 48, 48, 48, 0)
		(mem17, wg) = cbf_g!(mem16, b, 29, 0, 0, 62, 102, 102, 62, 6, 60)
		(mem18, wy) = cbf_g!(mem17, b, 30, 0, 0, 102, 102, 102, 62, 6, 60)
		(mem19, wp) = cbf_g!(mem18, b, 31, 0, 0, 124, 102, 102, 124, 96, 96)
		(mem20, wb) = cbf_g!(mem19, b, 32, 96, 96, 124, 102, 102, 102, 124, 0)
		(mem21, wv) = cbf_g!(mem20, b, 33, 0, 0, 102, 102, 102, 60, 24, 0)
		(mem22, wk) = cbf_g!(mem21, b, 34, 96, 96, 102, 108, 120, 108, 102, 0)
		(mem23, wj) = cbf_g!(mem22, b, 35, 12, 0, 28, 12, 12, 12, 108, 56)
		(mem24, wx) = cbf_g!(mem23, b, 36, 0, 0, 102, 36, 24, 36, 102, 0)
		(mem25, wq) = cbf_g!(mem24, b, 37, 0, 0, 62, 102, 102, 62, 6, 6)
		(mem26, wz) = cbf_g!(mem25, b, 38, 0, 0, 126, 12, 24, 48, 126, 0)
		(mem26, (((((((((((((((((((((((((we + wt) + wa) + wo) + wi) + wn) + ws) + wh) + wr) + wd) + wl) + wc) + wu) + wm) + ww) + wf) + wg) + wy) + wp) + wb) + wv) + wk) + wj) + wx) + wq) + wz))
	})
		(mem27, mem__6)
	})

	cbf_write_upper! : Mem.Mem, I64 => (Mem.Mem, I64)
	cbf_write_upper! = |mem, b| ({
		(mem27, mem__7) = ({
		(mem1, wE) = cbf_g!(mem, b, 39, 126, 96, 96, 124, 96, 96, 126, 0)
		(mem2, wT) = cbf_g!(mem1, b, 40, 126, 24, 24, 24, 24, 24, 24, 0)
		(mem3, wA) = cbf_g!(mem2, b, 41, 24, 60, 102, 102, 126, 102, 102, 0)
		(mem4, wO) = cbf_g!(mem3, b, 42, 60, 102, 102, 102, 102, 102, 60, 0)
		(mem5, wI) = cbf_g!(mem4, b, 43, 126, 24, 24, 24, 24, 24, 126, 0)
		(mem6, wN) = cbf_g!(mem5, b, 44, 102, 118, 126, 110, 102, 102, 102, 0)
		(mem7, wS) = cbf_g!(mem6, b, 45, 60, 102, 96, 60, 6, 102, 60, 0)
		(mem8, wH) = cbf_g!(mem7, b, 46, 102, 102, 102, 126, 102, 102, 102, 0)
		(mem9, wR) = cbf_g!(mem8, b, 47, 124, 102, 102, 124, 108, 102, 102, 0)
		(mem10, wD) = cbf_g!(mem9, b, 48, 120, 108, 102, 102, 102, 108, 120, 0)
		(mem11, wL) = cbf_g!(mem10, b, 49, 96, 96, 96, 96, 96, 96, 126, 0)
		(mem12, wC) = cbf_g!(mem11, b, 50, 60, 102, 96, 96, 96, 102, 60, 0)
		(mem13, wU) = cbf_g!(mem12, b, 51, 102, 102, 102, 102, 102, 102, 60, 0)
		(mem14, wM) = cbf_g!(mem13, b, 52, 99, 119, 127, 107, 99, 99, 99, 0)
		(mem15, wW) = cbf_g!(mem14, b, 53, 99, 99, 99, 107, 127, 119, 99, 0)
		(mem16, wF) = cbf_g!(mem15, b, 54, 126, 96, 96, 124, 96, 96, 96, 0)
		(mem17, wG) = cbf_g!(mem16, b, 55, 60, 102, 96, 110, 102, 102, 60, 0)
		(mem18, wY) = cbf_g!(mem17, b, 56, 102, 102, 102, 60, 24, 24, 24, 0)
		(mem19, wP) = cbf_g!(mem18, b, 57, 124, 102, 102, 124, 96, 96, 96, 0)
		(mem20, wB) = cbf_g!(mem19, b, 58, 124, 102, 102, 124, 102, 102, 124, 0)
		(mem21, wV) = cbf_g!(mem20, b, 59, 102, 102, 102, 102, 60, 24, 24, 0)
		(mem22, wK) = cbf_g!(mem21, b, 60, 102, 108, 120, 112, 120, 108, 102, 0)
		(mem23, wJ) = cbf_g!(mem22, b, 61, 6, 6, 6, 6, 6, 102, 60, 0)
		(mem24, wX) = cbf_g!(mem23, b, 62, 102, 102, 36, 24, 36, 102, 102, 0)
		(mem25, wQ) = cbf_g!(mem24, b, 63, 60, 102, 102, 102, 106, 108, 54, 0)
		(mem26, wZ) = cbf_g!(mem25, b, 64, 126, 6, 12, 24, 48, 96, 126, 0)
		(mem26, (((((((((((((((((((((((((wE + wT) + wA) + wO) + wI) + wN) + wS) + wH) + wR) + wD) + wL) + wC) + wU) + wM) + wW) + wF) + wG) + wY) + wP) + wB) + wV) + wK) + wJ) + wX) + wQ) + wZ))
	})
		(mem27, mem__7)
	})

	cbf_write_punct! : Mem.Mem, I64 => (Mem.Mem, I64)
	cbf_write_punct! = |mem, b| ({
		(mem33, mem__8) = ({
		(mem1, w65) = cbf_g!(mem, b, 65, 0, 0, 0, 0, 0, 24, 24, 0)
		(mem2, w66) = cbf_g!(mem1, b, 66, 0, 0, 0, 0, 0, 24, 24, 48)
		(mem3, w67) = cbf_g!(mem2, b, 67, 24, 24, 24, 24, 24, 0, 24, 0)
		(mem4, w68) = cbf_g!(mem3, b, 68, 60, 102, 6, 12, 24, 0, 24, 0)
		(mem5, w69) = cbf_g!(mem4, b, 69, 0, 24, 24, 0, 0, 24, 24, 0)
		(mem6, w70) = cbf_g!(mem5, b, 70, 0, 24, 24, 0, 0, 24, 24, 48)
		(mem7, w71) = cbf_g!(mem6, b, 71, 0, 102, 102, 0, 0, 0, 0, 0)
		(mem8, w72) = cbf_g!(mem7, b, 72, 0, 36, 126, 36, 36, 126, 36, 0)
		(mem9, w73) = cbf_g!(mem8, b, 73, 0, 0, 0, 126, 0, 0, 0, 0)
		(mem10, w74) = cbf_g!(mem9, b, 74, 12, 24, 48, 48, 48, 24, 12, 0)
		(mem11, w75) = cbf_g!(mem10, b, 75, 48, 24, 12, 12, 12, 24, 48, 0)
		(mem12, w76) = cbf_g!(mem11, b, 76, 0, 24, 24, 126, 24, 24, 0, 0)
		(mem13, w77) = cbf_g!(mem12, b, 77, 0, 0, 126, 0, 126, 0, 0, 0)
		(mem14, w78) = cbf_g!(mem13, b, 78, 0, 102, 60, 255, 60, 102, 0, 0)
		(mem15, w79) = cbf_g!(mem14, b, 79, 6, 12, 24, 48, 24, 12, 6, 0)
		(mem16, w80) = cbf_g!(mem15, b, 80, 96, 48, 24, 12, 24, 48, 96, 0)
		(mem17, w81) = cbf_g!(mem16, b, 81, 6, 12, 24, 48, 96, 192, 0, 0)
		(mem18, w82) = cbf_g!(mem17, b, 82, 60, 102, 110, 110, 96, 98, 60, 0)
		(mem19, w83) = cbf_g!(mem18, b, 83, 0, 36, 126, 36, 36, 126, 36, 0)
		(mem20, w84) = cbf_g!(mem19, b, 84, 0, 0, 0, 38, 0, 0, 0, 0)
		(mem21, w85) = cbf_g!(mem20, b, 85, 0, 0, 0, 0, 0, 0, 126, 0)
		(mem22, w86) = cbf_g!(mem21, b, 86, 192, 96, 48, 24, 12, 6, 0, 0)
		(mem23, w87) = cbf_g!(mem22, b, 87, 24, 24, 24, 24, 24, 24, 24, 24)
		(mem24, w88) = cbf_g!(mem23, b, 88, 60, 48, 48, 48, 48, 48, 60, 0)
		(mem25, w89) = cbf_g!(mem24, b, 89, 60, 12, 12, 12, 12, 12, 60, 0)
		(mem26, w90) = cbf_g!(mem25, b, 90, 14, 24, 24, 48, 24, 24, 14, 0)
		(mem27, w91) = cbf_g!(mem26, b, 91, 112, 24, 24, 12, 24, 24, 112, 0)
		(mem28, w92) = cbf_g!(mem27, b, 92, 0, 0, 50, 126, 76, 0, 0, 0)
		(mem29, w93) = cbf_g!(mem28, b, 93, 48, 24, 12, 0, 0, 0, 0, 0)
		(mem30, w94) = cbf_g!(mem29, b, 94, 24, 60, 102, 0, 0, 0, 0, 0)
		(mem31, w95) = cbf_g!(mem30, b, 95, 24, 60, 102, 0, 0, 0, 0, 0)
		(mem32, w96) = cbf_g!(mem31, b, 96, 24, 60, 102, 0, 0, 0, 0, 0)
		(mem32, (((((((((((((((((((((((((((((((w65 + w66) + w67) + w68) + w69) + w70) + w71) + w72) + w73) + w74) + w75) + w76) + w77) + w78) + w79) + w80) + w81) + w82) + w83) + w84) + w85) + w86) + w87) + w88) + w89) + w90) + w91) + w92) + w93) + w94) + w95) + w96))
	})
		(mem33, mem__8)
	})

	cbf_write_accented! : Mem.Mem, I64 => (Mem.Mem, I64)
	cbf_write_accented! = |mem, b| ({
		(mem17, mem__9) = ({
		(mem1, w97) = cbf_g!(mem, b, 97, 12, 24, 60, 102, 126, 96, 60, 0)
		(mem2, w98) = cbf_g!(mem1, b, 98, 48, 24, 60, 102, 126, 96, 60, 0)
		(mem3, w99) = cbf_g!(mem2, b, 99, 24, 0, 60, 102, 126, 96, 60, 0)
		(mem4, w100) = cbf_g!(mem3, b, 100, 24, 0, 60, 102, 126, 96, 60, 0)
		(mem5, w101) = cbf_g!(mem4, b, 101, 12, 24, 60, 6, 62, 102, 62, 0)
		(mem6, w102) = cbf_g!(mem5, b, 102, 48, 24, 60, 6, 62, 102, 62, 0)
		(mem7, w103) = cbf_g!(mem6, b, 103, 24, 0, 60, 6, 62, 102, 62, 0)
		(mem8, w104) = cbf_g!(mem7, b, 104, 24, 0, 60, 6, 62, 102, 62, 0)
		(mem9, w105) = cbf_g!(mem8, b, 105, 12, 24, 60, 102, 102, 102, 60, 0)
		(mem10, w106) = cbf_g!(mem9, b, 106, 24, 0, 60, 102, 102, 102, 60, 0)
		(mem11, w107) = cbf_g!(mem10, b, 107, 24, 0, 60, 102, 102, 102, 60, 0)
		(mem12, w108) = cbf_g!(mem11, b, 108, 12, 24, 102, 102, 102, 102, 62, 0)
		(mem13, w109) = cbf_g!(mem12, b, 109, 24, 0, 102, 102, 102, 102, 62, 0)
		(mem14, w110) = cbf_g!(mem13, b, 110, 0, 0, 124, 102, 102, 102, 102, 0)
		(mem15, w111) = cbf_g!(mem14, b, 111, 0, 0, 60, 102, 96, 102, 60, 0)
		(mem16, w112) = cbf_g!(mem15, b, 112, 24, 0, 56, 24, 24, 24, 60, 0)
		(mem16, (((((((((((((((w97 + w98) + w99) + w100) + w101) + w102) + w103) + w104) + w105) + w106) + w107) + w108) + w109) + w110) + w111) + w112))
	})
		(mem17, mem__9)
	})

	cbf_write_cyrillic! : Mem.Mem, I64 => (Mem.Mem, I64)
	cbf_write_cyrillic! = |mem, b| ({
		(mem16, mem__10) = ({
		(mem1, w113) = cbf_g!(mem, b, 113, 0, 0, 60, 6, 62, 102, 62, 0)
		(mem2, w114) = cbf_g!(mem1, b, 114, 0, 0, 60, 102, 102, 102, 60, 0)
		(mem3, w115) = cbf_g!(mem2, b, 115, 0, 0, 60, 102, 126, 96, 60, 0)
		(mem4, w116) = cbf_g!(mem3, b, 116, 0, 0, 124, 102, 102, 102, 102, 0)
		(mem5, w117) = cbf_g!(mem4, b, 117, 0, 0, 124, 102, 102, 102, 102, 0)
		(mem6, w118) = cbf_g!(mem5, b, 118, 126, 24, 24, 24, 24, 24, 24, 0)
		(mem7, w119) = cbf_g!(mem6, b, 119, 0, 0, 62, 96, 60, 6, 124, 0)
		(mem8, w120) = cbf_g!(mem7, b, 120, 0, 0, 124, 102, 96, 96, 96, 0)
		(mem9, w121) = cbf_g!(mem8, b, 121, 0, 0, 102, 102, 102, 60, 24, 0)
		(mem10, w122) = cbf_g!(mem9, b, 122, 56, 24, 24, 24, 24, 24, 60, 0)
		(mem11, w123) = cbf_g!(mem10, b, 123, 96, 96, 102, 108, 120, 108, 102, 0)
		(mem12, w124) = cbf_g!(mem11, b, 124, 0, 0, 102, 127, 107, 99, 99, 0)
		(mem13, w125) = cbf_g!(mem12, b, 125, 6, 6, 62, 102, 102, 102, 62, 0)
		(mem14, w126) = cbf_g!(mem13, b, 126, 0, 0, 124, 102, 102, 124, 96, 96)
		(mem15, w127) = cbf_g!(mem14, b, 127, 0, 0, 102, 102, 102, 102, 62, 0)
		(mem15, ((((((((((((((w113 + w114) + w115) + w116) + w117) + w118) + w119) + w120) + w121) + w122) + w123) + w124) + w125) + w126) + w127))
	})
		(mem16, mem__10)
	})

	cbf_g! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	cbf_g! = |mem, base, cce, r2, r3, r4, r5, r6, r7, r8, r9| ({
		(mem17, mem__11) = ({
		off = (cce * cbf_glyph_height)
		(mem1, w0) = Mem.store!(mem, base, off, 0, 1)
		(mem2, w1) = Mem.store!(mem1, base, (off + 1), 0, 1)
		(mem3, w2) = Mem.store!(mem2, base, (off + 2), r2, 1)
		(mem4, w3) = Mem.store!(mem3, base, (off + 3), r3, 1)
		(mem5, w4) = Mem.store!(mem4, base, (off + 4), r4, 1)
		(mem6, w5) = Mem.store!(mem5, base, (off + 5), r5, 1)
		(mem7, w6) = Mem.store!(mem6, base, (off + 6), r6, 1)
		(mem8, w7) = Mem.store!(mem7, base, (off + 7), r7, 1)
		(mem9, w8) = Mem.store!(mem8, base, (off + 8), r8, 1)
		(mem10, w9) = Mem.store!(mem9, base, (off + 9), r9, 1)
		(mem11, w10) = Mem.store!(mem10, base, (off + 10), 0, 1)
		(mem12, w11) = Mem.store!(mem11, base, (off + 11), 0, 1)
		(mem13, w12) = Mem.store!(mem12, base, (off + 12), 0, 1)
		(mem14, w13) = Mem.store!(mem13, base, (off + 13), 0, 1)
		(mem15, w14) = Mem.store!(mem14, base, (off + 14), 0, 1)
		(mem16, w15) = Mem.store!(mem15, base, (off + 15), 0, 1)
		(mem16, (((((((((((((((w0 + w1) + w2) + w3) + w4) + w5) + w6) + w7) + w8) + w9) + w10) + w11) + w12) + w13) + w14) + w15))
	})
		(mem17, mem__11)
	})
}
