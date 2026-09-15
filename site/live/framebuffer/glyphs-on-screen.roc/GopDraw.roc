# GopDraw -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import BitmapFont
import Cce
import Mem

GopDraw :: [].{

	cursor_w : I64
	cursor_w = 16

	cursor_h : I64
	cursor_h = 24

	cursor_col_edge : I64
	cursor_col_edge = 1052688

	cursor_col_fill : I64
	cursor_col_fill = 16777215

	cursor_edge_mask : I64 -> I64
	cursor_edge_mask = |r| (if (r == 0) { 32768 } else { (if (r == 1) { 49152 } else { (if (r == 2) { 40960 } else { (if (r == 3) { 36864 } else { (if (r == 4) { 34816 } else { (if (r == 5) { 33792 } else { (if (r == 6) { 33280 } else { (if (r == 7) { 33024 } else { (if (r == 8) { 32896 } else { (if (r == 9) { 32832 } else { (if (r == 10) { 32800 } else { (if (r == 11) { 32784 } else { (if (r == 12) { 32776 } else { (if (r == 13) { 32772 } else { (if (r == 14) { 32770 } else { (if (r == 15) { 32895 } else { (if (r == 16) { 32832 } else { (if (r == 17) { 33856 } else { (if (r == 18) { 35360 } else { (if (r == 19) { 37136 } else { (if (r == 20) { 41096 } else { (if (r == 21) { 49220 } else { (if (r == 22) { 32804 } else { (if (r == 23) { 28 } else { 0 }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) })

	cursor_fill_mask : I64 -> I64
	cursor_fill_mask = |r| (if (r == 2) { 16384 } else { (if (r == 3) { 24576 } else { (if (r == 4) { 28672 } else { (if (r == 5) { 30720 } else { (if (r == 6) { 31744 } else { (if (r == 7) { 32256 } else { (if (r == 8) { 32512 } else { (if (r == 9) { 32640 } else { (if (r == 10) { 32704 } else { (if (r == 11) { 32736 } else { (if (r == 12) { 32752 } else { (if (r == 13) { 32760 } else { (if (r == 14) { 32764 } else { (if (r == 15) { 32640 } else { (if (r == 16) { 32640 } else { (if (r == 17) { 31616 } else { (if (r == 18) { 29120 } else { (if (r == 19) { 24800 } else { (if (r == 20) { 16496 } else { (if (r == 21) { 56 } else { (if (r == 22) { 24 } else { 0 }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) })

	cursor_shape_arrow : I64
	cursor_shape_arrow = 0

	cursor_shape_ew : I64
	cursor_shape_ew = 1

	cursor_shape_ns : I64
	cursor_shape_ns = 2

	cursor_shape_nwse : I64
	cursor_shape_nwse = 3

	cursor_shape_nesw : I64
	cursor_shape_nesw = 4

	cursor_hot_x : I64 -> I64
	cursor_hot_x = |shape| (if (shape == cursor_shape_arrow) { 0 } else { 8 })

	cursor_hot_y : I64 -> I64
	cursor_hot_y = |shape| (if (shape == cursor_shape_arrow) { 0 } else { 12 })

	cursor_edge_ew : I64 -> I64
	cursor_edge_ew = |r| (if (r == 8) { 14364 } else { (if (r == 9) { 26646 } else { (if (r == 10) { 53235 } else { (if (r == 11) { 32769 } else { (if (r == 13) { 32769 } else { (if (r == 14) { 53235 } else { (if (r == 15) { 26646 } else { (if (r == 16) { 14364 } else { 0 }) }) }) }) }) }) }) })

	cursor_fill_ew : I64 -> I64
	cursor_fill_ew = |r| (if (r == 9) { 4104 } else { (if (r == 10) { 12300 } else { (if (r == 11) { 32766 } else { (if (r == 12) { 65535 } else { (if (r == 13) { 32766 } else { (if (r == 14) { 12300 } else { (if (r == 15) { 4104 } else { 0 }) }) }) }) }) }) })

	cursor_edge_ns : I64 -> I64
	cursor_edge_ns = |r| (if (r == 3) { 448 } else { (if (r == 4) { 864 } else { (if (r == 5) { 1584 } else { (if (r == 6) { 3096 } else { (if (r == 7) { 2056 } else { (if (r == 8) { 3640 } else { (if ((r >= 9) and (r <= 14)) { 544 } else { (if (r == 15) { 3640 } else { (if (r == 16) { 2056 } else { (if (r == 17) { 3096 } else { (if (r == 18) { 1584 } else { (if (r == 19) { 864 } else { (if (r == 20) { 448 } else { 0 }) }) }) }) }) }) }) }) }) }) }) }) })

	cursor_fill_ns : I64 -> I64
	cursor_fill_ns = |r| (if (r == 4) { 128 } else { (if (r == 5) { 448 } else { (if (r == 6) { 992 } else { (if (r == 7) { 2032 } else { (if ((r >= 8) and (r <= 15)) { 448 } else { (if (r == 16) { 2032 } else { (if (r == 17) { 992 } else { (if (r == 18) { 448 } else { (if (r == 19) { 128 } else { 0 }) }) }) }) }) }) }) }) })

	cursor_edge_nwse : I64 -> I64
	cursor_edge_nwse = |r| (if (r == 6) { 16256 } else { (if (r == 7) { 8320 } else { (if (r == 8) { 8576 } else { (if (r == 9) { 8576 } else { (if (r == 10) { 8384 } else { (if (r == 11) { 11360 } else { (if (r == 12) { 15934 } else { (if (r == 13) { 794 } else { (if (r == 14) { 386 } else { (if (r == 15) { 194 } else { (if (r == 16) { 194 } else { (if (r == 17) { 130 } else { (if (r == 18) { 254 } else { 0 }) }) }) }) }) }) }) }) }) }) }) }) })

	cursor_fill_nwse : I64 -> I64
	cursor_fill_nwse = |r| (if (r == 7) { 7936 } else { (if (r == 8) { 7680 } else { (if (r == 9) { 7680 } else { (if (r == 10) { 7936 } else { (if (r == 11) { 4992 } else { (if (r == 12) { 448 } else { (if (r == 13) { 228 } else { (if (r == 14) { 124 } else { (if (r == 15) { 60 } else { (if (r == 16) { 60 } else { (if (r == 17) { 124 } else { 0 }) }) }) }) }) }) }) }) }) }) })

	cursor_edge_nesw : I64 -> I64
	cursor_edge_nesw = |r| (if (r == 6) { 254 } else { (if (r == 7) { 130 } else { (if (r == 8) { 194 } else { (if (r == 9) { 194 } else { (if (r == 10) { 386 } else { (if (r == 11) { 794 } else { (if (r == 12) { 15934 } else { (if (r == 13) { 11360 } else { (if (r == 14) { 8384 } else { (if (r == 15) { 8576 } else { (if (r == 16) { 8576 } else { (if (r == 17) { 8320 } else { (if (r == 18) { 16256 } else { 0 }) }) }) }) }) }) }) }) }) }) }) }) })

	cursor_fill_nesw : I64 -> I64
	cursor_fill_nesw = |r| (if (r == 7) { 124 } else { (if (r == 8) { 60 } else { (if (r == 9) { 60 } else { (if (r == 10) { 124 } else { (if (r == 11) { 228 } else { (if (r == 12) { 448 } else { (if (r == 13) { 4992 } else { (if (r == 14) { 7936 } else { (if (r == 15) { 7680 } else { (if (r == 16) { 7680 } else { (if (r == 17) { 7936 } else { 0 }) }) }) }) }) }) }) }) }) }) })

	cursor_edge_of : I64, I64 -> I64
	cursor_edge_of = |shape, r| (if (shape == cursor_shape_ew) { cursor_edge_ew(r) } else { (if (shape == cursor_shape_ns) { cursor_edge_ns(r) } else { (if (shape == cursor_shape_nwse) { cursor_edge_nwse(r) } else { (if (shape == cursor_shape_nesw) { cursor_edge_nesw(r) } else { cursor_edge_mask(r) }) }) }) })

	cursor_fill_of : I64, I64 -> I64
	cursor_fill_of = |shape, r| (if (shape == cursor_shape_ew) { cursor_fill_ew(r) } else { (if (shape == cursor_shape_ns) { cursor_fill_ns(r) } else { (if (shape == cursor_shape_nwse) { cursor_fill_nwse(r) } else { (if (shape == cursor_shape_nesw) { cursor_fill_nesw(r) } else { cursor_fill_mask(r) }) }) }) })

	cursor_shape_cell : I64
	cursor_shape_cell = 20

	cursor_shape! : Mem.Mem, I64 => (Mem.Mem, I64)
	cursor_shape! = |mem, cs| Mem.load!(mem, cs, cursor_shape_cell, 4)

	cursor_set_shape! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	cursor_set_shape! = |mem, cs, shape| Mem.store!(mem, cs, cursor_shape_cell, shape, 4)

	cursor_paint_cols! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	cursor_paint_cols! = |mem, base, stride, rows, mx, my, skipx, cwc, py, em, fm, px| (if (px >= cwc) { (mem, 0) } else { ({
		lc = (px + skipx)
		e = I64.bitwise_and(I64.shr_zf_wrap(em, I64.to_u8_wrap((15 - lc))), 1)
		f = I64.bitwise_and(I64.shr_zf_wrap(fm, I64.to_u8_wrap((15 - lc))), 1)
		(mem1, _w) = (if (e == 1) { gop_put!(mem, base, stride, rows, (mx + px), (my + py), cursor_col_edge) } else { (if (f == 1) { gop_put!(mem, base, stride, rows, (mx + px), (my + py), cursor_col_fill) } else { (mem, 0) }) })
		cursor_paint_cols!(mem1, base, stride, rows, mx, my, skipx, cwc, py, em, fm, (px + 1))
	}) })

	cursor_paint_rows! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	cursor_paint_rows! = |mem, base, stride, rows, mx, my, skipx, skipy, shape, cwc, chc, py| (if (py >= chc) { (mem, 0) } else { ({
		lr = (py + skipy)
		em = cursor_edge_of(shape, lr)
		fm = cursor_fill_of(shape, lr)
		(mem1, _w) = cursor_paint_cols!(mem, base, stride, rows, mx, my, skipx, cwc, py, em, fm, 0)
		cursor_paint_rows!(mem1, base, stride, rows, mx, my, skipx, skipy, shape, cwc, chc, (py + 1))
	}) })

	cursor_save_cols! : Mem.Mem, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	cursor_save_cols! = |mem, cs, base, stride, r, c| ({
		(mem1, mem__12) = Mem.load!(mem, cs, 12, 4)
		(if (c >= mem__12) { (mem1, 0) } else { ({
		(mem5, _a) = ({
			(mem2, mem__13) = Mem.load!(mem1, cs, 8, 4)
			(mem3, mem__14) = Mem.load!(mem2, cs, 4, 4)
			(mem4, mem__15) = Mem.load!(mem3, base, (((((mem__13 + r) * stride) + mem__14) + c) * 4), 4)
			Mem.store!(mem4, cs, (32 + (((r * 16) + c) * 4)), mem__15, 4)
		})
		cursor_save_cols!(mem5, cs, base, stride, r, (c + 1))
	}) })
	})

	cursor_save_rows! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	cursor_save_rows! = |mem, cs, base, stride, r| ({
		(mem1, mem__16) = Mem.load!(mem, cs, 16, 4)
		(if (r >= mem__16) { (mem1, 0) } else { ({
		(mem2, _cc) = cursor_save_cols!(mem1, cs, base, stride, r, 0)
		cursor_save_rows!(mem2, cs, base, stride, (r + 1))
	}) })
	})

	cursor_rest_cols! : Mem.Mem, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	cursor_rest_cols! = |mem, cs, base, stride, r, c| ({
		(mem1, mem__17) = Mem.load!(mem, cs, 12, 4)
		(if (c >= mem__17) { (mem1, 0) } else { ({
		(mem5, _a) = ({
			(mem2, mem__18) = Mem.load!(mem1, cs, 8, 4)
			(mem3, mem__19) = Mem.load!(mem2, cs, 4, 4)
			(mem4, mem__20) = Mem.load!(mem3, cs, (32 + (((r * 16) + c) * 4)), 4)
			Mem.store!(mem4, base, (((((mem__18 + r) * stride) + mem__19) + c) * 4), mem__20, 4)
		})
		cursor_rest_cols!(mem5, cs, base, stride, r, (c + 1))
	}) })
	})

	cursor_rest_rows! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	cursor_rest_rows! = |mem, cs, base, stride, r| ({
		(mem1, mem__21) = Mem.load!(mem, cs, 16, 4)
		(if (r >= mem__21) { (mem1, 0) } else { ({
		(mem2, _cc) = cursor_rest_cols!(mem1, cs, base, stride, r, 0)
		cursor_rest_rows!(mem2, cs, base, stride, (r + 1))
	}) })
	})

	cursor_min : I64, I64 -> I64
	cursor_min = |a, b| (if (a < b) { a } else { b })

	cursor_hide! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	cursor_hide! = |mem, cs, base, stride| ({
		(mem1, mem__22) = Mem.load!(mem, cs, 0, 4)
		(if (mem__22 == 0) { (mem1, 0) } else { ({
		(mem2, _r) = cursor_rest_rows!(mem1, cs, base, stride, 0)
		Mem.store!(mem2, cs, 0, 0, 4)
	}) })
	})

	cursor_org : I64, I64 -> I64
	cursor_org = |m, hot| (m - hot)

	cursor_lo : I64 -> I64
	cursor_lo = |o| (if (o < 0) { 0 } else { o })

	cursor_skip : I64 -> I64
	cursor_skip = |o| (if (o < 0) { (0 - o) } else { 0 })

	cursor_span : I64, I64, I64 -> I64
	cursor_span = |o, extent, limit| cursor_min((extent - cursor_skip(o)), (limit - cursor_lo(o)))

	cursor_update! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	cursor_update! = |mem, cs, base, stride, _rows, pw, ph, _s, mx, my| ({
		(mem2, _r0) = ({
			(mem1, mem__23) = Mem.load!(mem, cs, 0, 4)
			(if (mem__23 != 0) { cursor_rest_rows!(mem1, cs, base, stride, 0) } else { (mem1, 0) })
		})
		(mem3, shape) = cursor_shape!(mem2, cs)
		ox = cursor_org(mx, cursor_hot_x(shape))
		oy = cursor_org(my, cursor_hot_y(shape))
		x0 = cursor_lo(ox)
		y0 = cursor_lo(oy)
		skipx = cursor_skip(ox)
		skipy = cursor_skip(oy)
		cwc = cursor_span(ox, cursor_w, pw)
		chc = cursor_span(oy, cursor_h, ph)
		(if (cwc <= 0) { Mem.store!(mem3, cs, 0, 0, 4) } else { (if (chc <= 0) { Mem.store!(mem3, cs, 0, 0, 4) } else { ({
			(mem4, _s0) = Mem.store!(mem3, cs, 4, x0, 4)
			(mem5, _s1) = Mem.store!(mem4, cs, 8, y0, 4)
			(mem6, _s2) = Mem.store!(mem5, cs, 12, cwc, 4)
			(mem7, _s3) = Mem.store!(mem6, cs, 16, chc, 4)
			(mem8, _sv) = cursor_save_rows!(mem7, cs, base, stride, 0)
			(mem9, _d0) = cursor_paint_rows!(mem8, base, stride, ph, x0, y0, skipx, skipy, shape, cwc, chc, 0)
			Mem.store!(mem9, cs, 0, 1, 4)
		}) }) })
	})

	gop_put! : Mem.Mem, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_put! = |mem, base, stride, rows, x, y, color| (if (x < 0) { (mem, 0) } else { (if (x >= stride) { (mem, 0) } else { (if (y < 0) { (mem, 0) } else { (if (y >= rows) { (mem, 0) } else { Mem.store!(mem, base, (((y * stride) + x) * 4), color, 4) }) }) }) })

	gop_get! : Mem.Mem, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_get! = |mem, base, stride, rows, x, y| (if (x < 0) { (mem, 0) } else { (if (x >= stride) { (mem, 0) } else { (if (y < 0) { (mem, 0) } else { (if (y >= rows) { (mem, 0) } else { Mem.load!(mem, base, (((y * stride) + x) * 4), 4) }) }) }) })

	gop_chan : I64, I64 -> I64
	gop_chan = |c, sh| I64.bitwise_and(I64.shr_zf_wrap(c, I64.to_u8_wrap(sh)), 255)

	gop_mix : I64, I64, I64 -> I64
	gop_mix = |dst, src, a| ({
		r = I64.div_trunc_by(((gop_chan(dst, 16) * (255 - a)) + (gop_chan(src, 16) * a)), 255)
		g = I64.div_trunc_by(((gop_chan(dst, 8) * (255 - a)) + (gop_chan(src, 8) * a)), 255)
		b = I64.div_trunc_by(((gop_chan(dst, 0) * (255 - a)) + (gop_chan(src, 0) * a)), 255)
		((I64.shl_wrap(r, I64.to_u8_wrap(16)) + I64.shl_wrap(g, I64.to_u8_wrap(8))) + b)
	})

	gop_blend! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_blend! = |mem, base, stride, rows, x, y, color, a| (if (a <= 0) { (mem, 0) } else { (if (a >= 255) { gop_put!(mem, base, stride, rows, x, y, color) } else { ({
		(mem1, mem__24) = gop_get!(mem, base, stride, rows, x, y)
		gop_put!(mem1, base, stride, rows, x, y, gop_mix(mem__24, color, a))
	}) }) })

	gop_rect_cols! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_rect_cols! = |mem, base, stride, rows, px, py, pw, color, x| (if (x >= pw) { (mem, 0) } else { ({
		(mem1, _p) = gop_put!(mem, base, stride, rows, (px + x), py, color)
		gop_rect_cols!(mem1, base, stride, rows, px, py, pw, color, (x + 1))
	}) })

	gop_fill_rect! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_fill_rect! = |mem, base, stride, rows, px, py, pw, ph, color| ({
		x0 = (if (px < 0) { 0 } else { px })
		x1 = (if ((px + pw) > stride) { stride } else { (px + pw) })
		y0 = (if (py < 0) { 0 } else { py })
		y1 = (if ((py + ph) > rows) { rows } else { (py + ph) })
		(if (x1 <= x0) { (mem, 0) } else { (if (y1 <= y0) { (mem, 0) } else { gop_rect_rows!(mem, base, stride, rows, x0, y0, (x1 - x0), (y1 - y0), color, 0) }) })
	})

	gop_rect_rows! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_rect_rows! = |mem, base, stride, rows, px, py, pw, ph, color, y| (if (y >= ph) { (mem, 0) } else { ({
		(mem1, _r) = gop_rect_cols!(mem, base, stride, rows, px, (py + y), pw, color, 0)
		gop_rect_rows!(mem1, base, stride, rows, px, py, pw, ph, color, (y + 1))
	}) })

	gop_char_cols! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_char_cols! = |mem, base, stride, rows, px, py, glyph, fg, scale, col| (if (col >= 8) { (mem, 0) } else { ({
		on = I64.bitwise_and(I64.shr_zf_wrap(glyph, I64.to_u8_wrap((7 - col))), 1)
		(mem1, _p) = (if (on == 1) { gop_fill_rect!(mem, base, stride, rows, (px + (col * scale)), py, scale, scale, fg) } else { (mem, 0) })
		gop_char_cols!(mem1, base, stride, rows, px, py, glyph, fg, scale, (col + 1))
	}) })

	gop_char_rows! : Mem.Mem, I64, I64, I64, BitmapFont.CbfFont, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_char_rows! = |mem, base, stride, rows, font, px, py, cce, fg, scale, row| (if (row >= 16) { (mem, 0) } else { ({
		(mem1, glyph) = BitmapFont.cbf_row!(mem, font, cce, row)
		(mem2, _r) = gop_char_cols!(mem1, base, stride, rows, px, (py + (row * scale)), glyph, fg, scale, 0)
		gop_char_rows!(mem2, base, stride, rows, font, px, py, cce, fg, scale, (row + 1))
	}) })

	gop_draw_text! : Mem.Mem, I64, I64, I64, BitmapFont.CbfFont, I64, I64, Str, I64, I64, I64 => (Mem.Mem, I64)
	gop_draw_text! = |mem, base, stride, rows, font, px, py, s, fg, scale, i| (if (i >= Cce.length(s)) { (mem, 0) } else { (if ((px + (((i + 1) * 8) * scale)) > stride) { (mem, 0) } else { ({
		cce = Cce.at_or_crash(s, i)
		(mem1, _c) = gop_char_rows!(mem, base, stride, rows, font, (px + ((i * 8) * scale)), py, cce, fg, scale, 0)
		gop_draw_text!(mem1, base, stride, rows, font, px, py, s, fg, scale, (i + 1))
	}) }) })

	gop_word_len : Str, I64 -> I64
	gop_word_len = |s, i| (if (i >= Cce.length(s)) { 0 } else { (if gop_is_space(Cce.at_or_crash(s, i)) { 0 } else { (1 + gop_word_len(s, (i + 1))) }) })

	gop_is_space : I64 -> Bool
	gop_is_space = |cc| (if (cc >= 1) { (cc <= 2) } else { False })

	gop_draw_text_wrap! : Mem.Mem, I64, I64, I64, BitmapFont.CbfFont, I64, I64, Str, I64, I64, I64 => (Mem.Mem, I64)
	gop_draw_text_wrap! = |mem, base, stride, rows, font, px, py, s, fg, scale, w| ({
		cpl = I64.div_trunc_by((w - px), (8 * scale))
		(if (cpl <= 0) { (mem, 0) } else { gop_wrap_go!(mem, base, stride, rows, font, px, py, s, fg, scale, cpl, 0, 0, 0) })
	})

	gop_wrap_go! : Mem.Mem, I64, I64, I64, BitmapFont.CbfFont, I64, I64, Str, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_wrap_go! = |mem, base, stride, rows, font, px, py, s, fg, scale, cpl, i, col, line| (if (i >= Cce.length(s)) { (mem, (line + 1)) } else { ({
		cc = Cce.at_or_crash(s, i)
		(if gop_is_space(cc) { (if (((col + 1) + gop_word_len(s, (i + 1))) > cpl) { gop_wrap_go!(mem, base, stride, rows, font, px, py, s, fg, scale, cpl, (i + 1), 0, (line + 1)) } else { gop_wrap_go!(mem, base, stride, rows, font, px, py, s, fg, scale, cpl, (i + 1), (col + 1), line) }) } else { (if (col >= cpl) { gop_wrap_go!(mem, base, stride, rows, font, px, py, s, fg, scale, cpl, i, 0, (line + 1)) } else { ({
			(mem1, _c) = gop_char_rows!(mem, base, stride, rows, font, (px + ((col * 8) * scale)), (py + ((line * 16) * scale)), cc, fg, scale, 0)
			gop_wrap_go!(mem1, base, stride, rows, font, px, py, s, fg, scale, cpl, (i + 1), (col + 1), line)
		}) }) })
	}) })

	ui_scale : I64 -> I64
	ui_scale = |w| (if (w >= 1024) { 2 } else { 1 })

	ui_wscale : I64 -> I64
	ui_wscale = |w| (if (w >= 1600) { 2 } else { 1 })

	gop_xor_mask : I64
	gop_xor_mask = 16777215

	gop_xor_span! : Mem.Mem, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_xor_span! = |mem, base, stride, y, x, x1| (if (x >= x1) { (mem, 0) } else { ({
		o = (((y * stride) + x) * 4)
		(mem2, _v) = ({
			(mem1, mem__25) = Mem.load!(mem, base, o, 4)
			Mem.store!(mem1, base, o, I64.bitwise_xor(mem__25, gop_xor_mask), 4)
		})
		gop_xor_span!(mem2, base, stride, y, (x + 1), x1)
	}) })

	gop_xor_band! : Mem.Mem, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_xor_band! = |mem, base, stride, x0, x1, y, y1| (if (y >= y1) { (mem, 0) } else { ({
		(mem1, _r) = gop_xor_span!(mem, base, stride, y, x0, x1)
		gop_xor_band!(mem1, base, stride, x0, x1, (y + 1), y1)
	}) })

	gop_xor_rect! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_xor_rect! = |mem, base, stride, sw, sh, x, y, w, h| ({
		x0 = (if (x < 0) { 0 } else { x })
		y0 = (if (y < 0) { 0 } else { y })
		x1 = (if ((x + w) > sw) { sw } else { (x + w) })
		y1 = (if ((y + h) > sh) { sh } else { (y + h) })
		(if (x0 >= x1) { (mem, 0) } else { (if (y0 >= y1) { (mem, 0) } else { gop_xor_band!(mem, base, stride, x0, x1, y0, y1) }) })
	})

	gop_xor_frame! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_xor_frame! = |mem, base, stride, sw, sh, x, y, w, h, t| ({
		(mem1, _a) = gop_xor_rect!(mem, base, stride, sw, sh, x, y, w, t)
		(mem2, _b) = gop_xor_rect!(mem1, base, stride, sw, sh, x, ((y + h) - t), w, t)
		(mem3, _c) = gop_xor_rect!(mem2, base, stride, sw, sh, x, (y + t), t, (h - (2 * t)))
		gop_xor_rect!(mem3, base, stride, sw, sh, ((x + w) - t), (y + t), t, (h - (2 * t)))
	})
}
