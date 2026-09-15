# GopQr -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CCE
import Cce
import GopAhci
import GopDraw
import Mem
import Prelude

GopQr :: [].{

	qr_size : I64
	qr_size = 37

	qr_data_cw : I64
	qr_data_cw = 108

	qr_ecc_cw : I64
	qr_ecc_cw = 26

	qr_total_cw : I64
	qr_total_cw = 134

	qr_cap : I64
	qr_cap = 106

	qr_gf_new! : Mem.Mem => (Mem.Mem, I64)
	qr_gf_new! = |mem| ({
		(mem1, g) = GopAhci.alloc_zeroed!(mem, 640, 64)
		qr_gf_fill!(mem1, g, 0, 1)
	})

	qr_gf_fill! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	qr_gf_fill! = |mem, g, i, x| (if (i >= 256) { (mem, g) } else { ({
		(mem1, _e) = Mem.store!(mem, g, i, x, 1)
		(mem2, _l) = (if (i < 255) { Mem.store!(mem1, g, (256 + x), i, 1) } else { (mem1, 0) })
		x2 = I64.shl_wrap(x, I64.to_u8_wrap(1))
		x3 = (if (x2 >= 256) { I64.bitwise_and(I64.bitwise_xor(x2, 285), 255) } else { x2 })
		qr_gf_fill!(mem2, g, (i + 1), x3)
	}) })

	qr_gf_mul! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	qr_gf_mul! = |mem, g, a, b| (if (a == 0) { (mem, 0) } else { (if (b == 0) { (mem, 0) } else { ({
		(mem1, mem__34) = Mem.load!(mem, g, (256 + a), 1)
		(mem2, mem__35) = Mem.load!(mem1, g, (256 + b), 1)
		Mem.load!(mem2, g, Prelude.int_mod((mem__34 + mem__35), 255), 1)
	}) }) })

	qr_rs_gen! : Mem.Mem, I64 => (Mem.Mem, I64)
	qr_rs_gen! = |mem, gf| ({
		(mem1, g) = GopAhci.alloc_zeroed!(mem, 32, 64)
		(mem2, _s) = Mem.store!(mem1, g, 0, 1, 1)
		qr_rs_gen_loop!(mem2, gf, g, 0)
	})

	qr_rs_gen_loop! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	qr_rs_gen_loop! = |mem, gf, g, i| (if (i >= qr_ecc_cw) { (mem, g) } else { ({
		(mem1, a) = Mem.load!(mem, gf, i, 1)
		(mem2, _u) = qr_rs_gen_mul!(mem1, gf, g, a, (i + 1))
		qr_rs_gen_loop!(mem2, gf, g, (i + 1))
	}) })

	qr_rs_gen_mul! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	qr_rs_gen_mul! = |mem, gf, g, a, j| (if (j < 0) { (mem, 0) } else { ({
		(mem1, cur) = Mem.load!(mem, g, j, 1)
		(mem2, prev) = (if (j == 0) { (mem1, 0) } else { Mem.load!(mem1, g, (j - 1), 1) })
		(mem4, _w) = ({
			(mem3, mem__36) = qr_gf_mul!(mem2, gf, cur, a)
			Mem.store!(mem3, g, j, I64.bitwise_xor(prev, mem__36), 1)
		})
		qr_rs_gen_mul!(mem4, gf, g, a, (j - 1))
	}) })

	qr_rs_encode! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	qr_rs_encode! = |mem, gf, gen, data| ({
		(mem5, mem__37) = ({
		(mem1, work) = GopAhci.alloc_zeroed!(mem, 144, 64)
		(mem2, _c) = qr_copy_bytes!(mem1, data, work, 0, qr_data_cw)
		(mem3, _d) = qr_rs_div!(mem2, gf, gen, work, 0)
		(mem4, _r) = qr_copy_bytes!(mem3, data, work, 0, qr_data_cw)
		(mem4, work)
	})
		(mem5, mem__37)
	})

	qr_copy_bytes! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	qr_copy_bytes! = |mem, src, dst, i, n| (if (i >= n) { (mem, dst) } else { ({
		(mem2, _w) = ({
			(mem1, mem__38) = Mem.load!(mem, src, i, 1)
			Mem.store!(mem1, dst, i, mem__38, 1)
		})
		qr_copy_bytes!(mem2, src, dst, (i + 1), n)
	}) })

	qr_rs_div! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	qr_rs_div! = |mem, gf, gen, work, i| (if (i >= qr_data_cw) { (mem, work) } else { ({
		(mem1, f) = Mem.load!(mem, work, i, 1)
		(mem2, _s) = (if (f == 0) { (mem1, 0) } else { qr_rs_step!(mem1, gf, gen, work, i, f, 0) })
		qr_rs_div!(mem2, gf, gen, work, (i + 1))
	}) })

	qr_rs_step! : Mem.Mem, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	qr_rs_step! = |mem, gf, gen, work, i, f, k| (if (k > qr_ecc_cw) { (mem, 0) } else { ({
		(mem1, old) = Mem.load!(mem, work, (i + k), 1)
		(mem4, _w) = ({
			(mem2, mem__39) = Mem.load!(mem1, gen, (qr_ecc_cw - k), 1)
			(mem3, mem__40) = qr_gf_mul!(mem2, gf, f, mem__39)
			Mem.store!(mem3, work, (i + k), I64.bitwise_xor(old, mem__40), 1)
		})
		qr_rs_step!(mem4, gf, gen, work, i, f, (k + 1))
	}) })

	qr_put_bits! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	qr_put_bits! = |mem, buf, pos, v, n| (if (n <= 0) { (mem, pos) } else { ({
		bit = I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap((n - 1))), 1)
		byi = I64.shr_zf_wrap(pos, I64.to_u8_wrap(3))
		(mem2, _w) = (if (bit == 1) { ({
			(mem1, mem__41) = Mem.load!(mem, buf, byi, 1)
			Mem.store!(mem1, buf, byi, I64.bitwise_or(mem__41, I64.shl_wrap(1, I64.to_u8_wrap((7 - I64.bitwise_and(pos, 7))))), 1)
		}) } else { (mem, 0) })
		qr_put_bits!(mem2, buf, (pos + 1), v, (n - 1))
	}) })

	qr_put_slice_bits! : Mem.Mem, I64, I64, Str, I64, I64 => (Mem.Mem, I64)
	qr_put_slice_bits! = |mem, buf, pos, s, i, stop| (if (i >= stop) { (mem, pos) } else { ({
		(mem1, p2) = qr_put_bits!(mem, buf, pos, CCE.to_unicode(Cce.at_or_crash(s, i)), 8)
		qr_put_slice_bits!(mem1, buf, p2, s, (i + 1), stop)
	}) })

	qr_make_data2! : Mem.Mem, Str, Str, I64, I64 => (Mem.Mem, I64)
	qr_make_data2! = |mem, prefix, s, from, len| ({
		(mem1, buf) = GopAhci.alloc_zeroed!(mem, 144, 64)
		n = (Cce.length(prefix) + len)
		(mem2, p1) = qr_put_bits!(mem1, buf, 0, 4, 4)
		(mem3, p2) = qr_put_bits!(mem2, buf, p1, n, 8)
		(mem4, p3) = qr_put_slice_bits!(mem3, buf, p2, prefix, 0, Cce.length(prefix))
		(mem5, p4) = qr_put_slice_bits!(mem4, buf, p3, s, from, (from + len))
		(mem6, p5) = qr_put_bits!(mem5, buf, p4, 0, 4)
		qr_pad_bytes!(mem6, buf, I64.div_trunc_by((p5 + 7), 8), 0)
	})

	qr_make_data! : Mem.Mem, Str => (Mem.Mem, I64)
	qr_make_data! = |mem, s| qr_make_data2!(mem, "", s, 0, Cce.length(s))

	qr_pad_bytes! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	qr_pad_bytes! = |mem, buf, i, alt| (if (i >= qr_data_cw) { (mem, buf) } else { ({
		(mem1, _w) = Mem.store!(mem, buf, i, (if (alt == 0) { 236 } else { 17 }), 1)
		qr_pad_bytes!(mem1, buf, (i + 1), (1 - alt))
	}) })

	qr_bch : I64, I64 -> I64
	qr_bch = |r, i| (if (i < 10) { r } else { (if (I64.bitwise_and(I64.shr_zf_wrap(r, I64.to_u8_wrap(i)), 1) == 1) { qr_bch(I64.bitwise_xor(r, I64.shl_wrap(1335, I64.to_u8_wrap((i - 10)))), (i - 1)) } else { qr_bch(r, (i - 1)) }) })

	qr_format_bits : I64 -> I64
	qr_format_bits = |mask| ({
		d = I64.bitwise_or(8, mask)
		r = qr_bch(I64.shl_wrap(d, I64.to_u8_wrap(10)), 14)
		I64.bitwise_xor(I64.bitwise_or(I64.shl_wrap(d, I64.to_u8_wrap(10)), r), 21522)
	})

	qr_at : I64, I64 -> I64
	qr_at = |r, c| ((r * qr_size) + c)

	qr_mark_rect! : Mem.Mem, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	qr_mark_rect! = |mem, fn, r0, c0, h, w, i| (if (i >= (h * w)) { (mem, 0) } else { ({
		(mem1, _m) = Mem.store!(mem, fn, qr_at((r0 + I64.div_trunc_by(i, w)), (c0 + Prelude.int_mod(i, w))), 1, 1)
		qr_mark_rect!(mem1, fn, r0, c0, h, w, (i + 1))
	}) })

	qr_finder! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	qr_finder! = |mem, m, r0, c0, i| (if (i >= 49) { (mem, 0) } else { ({
		r = I64.div_trunc_by(i, 7)
		c = Prelude.int_mod(i, 7)
		dark = (if (r == 0) { 1 } else { (if (r == 6) { 1 } else { (if (c == 0) { 1 } else { (if (c == 6) { 1 } else { (if (r >= 2) { (if (r <= 4) { (if (c >= 2) { (if (c <= 4) { 1 } else { 0 }) } else { 0 }) } else { 0 }) } else { 0 }) }) }) }) })
		(mem1, _w) = Mem.store!(mem, m, qr_at((r0 + r), (c0 + c)), dark, 1)
		qr_finder!(mem1, m, r0, c0, (i + 1))
	}) })

	qr_align! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	qr_align! = |mem, m, i| (if (i >= 25) { (mem, 0) } else { ({
		r = I64.div_trunc_by(i, 5)
		c = Prelude.int_mod(i, 5)
		dark = (if (r == 0) { 1 } else { (if (r == 4) { 1 } else { (if (c == 0) { 1 } else { (if (c == 4) { 1 } else { (if (r == 2) { (if (c == 2) { 1 } else { 0 }) } else { 0 }) }) }) }) })
		(mem1, _w) = Mem.store!(mem, m, qr_at((28 + r), (28 + c)), dark, 1)
		qr_align!(mem1, m, (i + 1))
	}) })

	qr_timing! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	qr_timing! = |mem, m, fn, i| (if (i > 28) { (mem, 0) } else { ({
		dark = (if (Prelude.int_mod(i, 2) == 0) { 1 } else { 0 })
		(mem1, _a) = Mem.store!(mem, m, qr_at(6, i), dark, 1)
		(mem2, _b) = Mem.store!(mem1, m, qr_at(i, 6), dark, 1)
		(mem3, _fa) = Mem.store!(mem2, fn, qr_at(6, i), 1, 1)
		(mem4, _fb) = Mem.store!(mem3, fn, qr_at(i, 6), 1, 1)
		qr_timing!(mem4, m, fn, (i + 1))
	}) })

	qr_functions! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	qr_functions! = |mem, m, fn| ({
		(mem1, _a) = qr_mark_rect!(mem, fn, 0, 0, 9, 9, 0)
		(mem2, _b) = qr_mark_rect!(mem1, fn, 0, 29, 9, 8, 0)
		(mem3, _c) = qr_mark_rect!(mem2, fn, 29, 0, 8, 9, 0)
		(mem4, _d) = qr_mark_rect!(mem3, fn, 28, 28, 5, 5, 0)
		(mem5, _t) = qr_timing!(mem4, m, fn, 8)
		(mem6, _f1) = qr_finder!(mem5, m, 0, 0, 0)
		(mem7, _f2) = qr_finder!(mem6, m, 0, 30, 0)
		(mem8, _f3) = qr_finder!(mem7, m, 30, 0, 0)
		(mem9, _al) = qr_align!(mem8, m, 0)
		Mem.store!(mem9, m, qr_at(29, 8), 1, 1)
	})

	qr_data_bit! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	qr_data_bit! = |mem, cw, idx| ({
		(mem2, mem__43) = (if (idx >= (qr_total_cw * 8)) { (mem, 0) } else { ({
		(mem1, mem__42) = Mem.load!(mem, cw, I64.div_trunc_by(idx, 8), 1)
		(mem1, I64.bitwise_and(I64.shr_zf_wrap(mem__42, I64.to_u8_wrap((7 - I64.bitwise_and(idx, 7)))), 1))
	}) })
		(mem2, mem__43)
	})

	qr_place! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	qr_place! = |mem, m, fn, cw| qr_place_cols!(mem, m, fn, cw, 36, 1, 0)

	qr_place_cols! : Mem.Mem, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	qr_place_cols! = |mem, m, fn, cw, col, up, bit| (if (col < 1) { (mem, bit) } else { ({
		(mem1, b2) = qr_place_col!(mem, m, fn, cw, col, up, 0, bit)
		next = (if (col == 8) { 5 } else { (col - 2) })
		qr_place_cols!(mem1, m, fn, cw, next, (1 - up), b2)
	}) })

	qr_place_col! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	qr_place_col! = |mem, m, fn, cw, col, up, i, bit| (if (i >= qr_size) { (mem, bit) } else { ({
		row = (if (up == 1) { ((qr_size - 1) - i) } else { i })
		(mem1, b2) = qr_place_one!(mem, m, fn, cw, row, col, bit)
		(mem2, b3) = qr_place_one!(mem1, m, fn, cw, row, (col - 1), b2)
		qr_place_col!(mem2, m, fn, cw, col, up, (i + 1), b3)
	}) })

	qr_place_one! : Mem.Mem, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	qr_place_one! = |mem, m, fn, cw, row, col, bit| ({
		(mem1, mem__44) = Mem.load!(mem, fn, qr_at(row, col), 1)
		(mem5, mem__46) = (if (mem__44 != 0) { (mem1, bit) } else { ({
		(mem4, mem__45) = ({
		(mem2, v) = qr_data_bit!(mem1, cw, bit)
		masked = (if (Prelude.int_mod((row + col), 2) == 0) { I64.bitwise_xor(v, 1) } else { v })
		(mem3, _w) = Mem.store!(mem2, m, qr_at(row, col), masked, 1)
		(mem3, (bit + 1))
	})
		(mem4, mem__45)
	}) })
		(mem5, mem__46)
	})

	qr_fmt_bit : I64, I64 -> I64
	qr_fmt_bit = |fmt, k| I64.bitwise_and(I64.shr_zf_wrap(fmt, I64.to_u8_wrap(k)), 1)

	qr_place_format! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	qr_place_format! = |mem, m, fmt| ({
		(mem1, _a0) = Mem.store!(mem, m, qr_at(8, 0), qr_fmt_bit(fmt, 14), 1)
		(mem2, _a1) = Mem.store!(mem1, m, qr_at(8, 1), qr_fmt_bit(fmt, 13), 1)
		(mem3, _a2) = Mem.store!(mem2, m, qr_at(8, 2), qr_fmt_bit(fmt, 12), 1)
		(mem4, _a3) = Mem.store!(mem3, m, qr_at(8, 3), qr_fmt_bit(fmt, 11), 1)
		(mem5, _a4) = Mem.store!(mem4, m, qr_at(8, 4), qr_fmt_bit(fmt, 10), 1)
		(mem6, _a5) = Mem.store!(mem5, m, qr_at(8, 5), qr_fmt_bit(fmt, 9), 1)
		(mem7, _a6) = Mem.store!(mem6, m, qr_at(8, 7), qr_fmt_bit(fmt, 8), 1)
		(mem8, _a7) = Mem.store!(mem7, m, qr_at(8, 8), qr_fmt_bit(fmt, 7), 1)
		(mem9, _a8) = Mem.store!(mem8, m, qr_at(7, 8), qr_fmt_bit(fmt, 6), 1)
		(mem10, _a9) = Mem.store!(mem9, m, qr_at(5, 8), qr_fmt_bit(fmt, 5), 1)
		(mem11, _aa) = Mem.store!(mem10, m, qr_at(4, 8), qr_fmt_bit(fmt, 4), 1)
		(mem12, _ab) = Mem.store!(mem11, m, qr_at(3, 8), qr_fmt_bit(fmt, 3), 1)
		(mem13, _ac) = Mem.store!(mem12, m, qr_at(2, 8), qr_fmt_bit(fmt, 2), 1)
		(mem14, _ad) = Mem.store!(mem13, m, qr_at(1, 8), qr_fmt_bit(fmt, 1), 1)
		(mem15, _ae) = Mem.store!(mem14, m, qr_at(0, 8), qr_fmt_bit(fmt, 0), 1)
		(mem16, _b0) = Mem.store!(mem15, m, qr_at(36, 8), qr_fmt_bit(fmt, 14), 1)
		(mem17, _b1) = Mem.store!(mem16, m, qr_at(35, 8), qr_fmt_bit(fmt, 13), 1)
		(mem18, _b2) = Mem.store!(mem17, m, qr_at(34, 8), qr_fmt_bit(fmt, 12), 1)
		(mem19, _b3) = Mem.store!(mem18, m, qr_at(33, 8), qr_fmt_bit(fmt, 11), 1)
		(mem20, _b4) = Mem.store!(mem19, m, qr_at(32, 8), qr_fmt_bit(fmt, 10), 1)
		(mem21, _b5) = Mem.store!(mem20, m, qr_at(31, 8), qr_fmt_bit(fmt, 9), 1)
		(mem22, _b6) = Mem.store!(mem21, m, qr_at(30, 8), qr_fmt_bit(fmt, 8), 1)
		(mem23, _b7) = Mem.store!(mem22, m, qr_at(8, 29), qr_fmt_bit(fmt, 7), 1)
		(mem24, _b8) = Mem.store!(mem23, m, qr_at(8, 30), qr_fmt_bit(fmt, 6), 1)
		(mem25, _b9) = Mem.store!(mem24, m, qr_at(8, 31), qr_fmt_bit(fmt, 5), 1)
		(mem26, _ba) = Mem.store!(mem25, m, qr_at(8, 32), qr_fmt_bit(fmt, 4), 1)
		(mem27, _bb) = Mem.store!(mem26, m, qr_at(8, 33), qr_fmt_bit(fmt, 3), 1)
		(mem28, _bc) = Mem.store!(mem27, m, qr_at(8, 34), qr_fmt_bit(fmt, 2), 1)
		(mem29, _bd) = Mem.store!(mem28, m, qr_at(8, 35), qr_fmt_bit(fmt, 1), 1)
		Mem.store!(mem29, m, qr_at(8, 36), qr_fmt_bit(fmt, 0), 1)
	})

	qr5_encode_part! : Mem.Mem, Str, Str, I64, I64 => (Mem.Mem, I64)
	qr5_encode_part! = |mem, prefix, s, from, len| ({
		(mem10, mem__47) = ({
		(mem1, gf) = qr_gf_new!(mem)
		(mem2, gen) = qr_rs_gen!(mem1, gf)
		(mem3, data) = qr_make_data2!(mem2, prefix, s, from, len)
		(mem4, cw) = qr_rs_encode!(mem3, gf, gen, data)
		(mem5, m) = GopAhci.alloc_zeroed!(mem4, 1400, 64)
		(mem6, fn) = GopAhci.alloc_zeroed!(mem5, 1400, 64)
		(mem7, _f) = qr_functions!(mem6, m, fn)
		(mem8, _p) = qr_place!(mem7, m, fn, cw)
		(mem9, _fmt) = qr_place_format!(mem8, m, qr_format_bits(0))
		(mem9, m)
	})
		(mem10, mem__47)
	})

	qr5_encode! : Mem.Mem, Str => (Mem.Mem, I64)
	qr5_encode! = |mem, s| qr5_encode_part!(mem, "", s, 0, Cce.length(s))

	qr5_ecc_of! : Mem.Mem, Str => (Mem.Mem, I64)
	qr5_ecc_of! = |mem, s| ({
		(mem1, gf) = qr_gf_new!(mem)
		(mem2, gen) = qr_rs_gen!(mem1, gf)
		({
			(mem3, mem__48) = qr_make_data!(mem2, s)
			qr_rs_encode!(mem3, gf, gen, mem__48)
		})
	})

	qr_row_text! : Mem.Mem, I64, I64, I64, Str => (Mem.Mem, Str)
	qr_row_text! = |mem, m, r, c, acc| (if (c >= qr_size) { (mem, acc) } else { ({
		(mem1, mem__49) = Mem.load!(mem, m, qr_at(r, c), 1)
		qr_row_text!(mem1, m, r, (c + 1), Str.concat(acc, (if (mem__49 == 0) { "0" } else { "1" })))
	}) })

	qr_draw! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	qr_draw! = |mem, base, stride, rows, x, y, scale, m| ({
		side = ((qr_size + 8) * scale)
		(mem1, _bg) = GopDraw.gop_fill_rect!(mem, base, stride, rows, x, y, side, side, 16777215)
		qr_draw_mods!(mem1, base, stride, rows, (x + (4 * scale)), (y + (4 * scale)), scale, m, 0)
	})

	qr_draw_mods! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	qr_draw_mods! = |mem, base, stride, rows, x, y, scale, m, i| (if (i >= (qr_size * qr_size)) { (mem, 0) } else { ({
		r = I64.div_trunc_by(i, qr_size)
		c = Prelude.int_mod(i, qr_size)
		(mem2, _w) = ({
			(mem1, mem__50) = Mem.load!(mem, m, i, 1)
			(if (mem__50 == 1) { GopDraw.gop_fill_rect!(mem1, base, stride, rows, (x + (c * scale)), (y + (r * scale)), scale, scale, 0) } else { (mem1, 0) })
		})
		qr_draw_mods!(mem2, base, stride, rows, x, y, scale, m, (i + 1))
	}) })
}
