# GopComposite -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import BitmapFont
import BoxModel
import Cce
import GopDraw
import GopFont
import GopIcon
import MathLib
import Mem
import Theme
import Widget

GopComposite :: [].{

	comp_chan : I64, I64 -> I64
	comp_chan = |c, sh| I64.bitwise_and(I64.shr_zf_wrap(c, I64.to_u8_wrap(sh)), 255)

	comp_lerp : I64, I64, I64, I64 -> I64
	comp_lerp = |a, b, i, n| (if (n <= 1) { a } else { ({
		d = (n - 1)
		j = (if (i > d) { d } else { i })
		r = I64.div_trunc_by(((comp_chan(a, 16) * (d - j)) + (comp_chan(b, 16) * j)), d)
		g = I64.div_trunc_by(((comp_chan(a, 8) * (d - j)) + (comp_chan(b, 8) * j)), d)
		bl = I64.div_trunc_by(((comp_chan(a, 0) * (d - j)) + (comp_chan(b, 0) * j)), d)
		((I64.shl_wrap(r, I64.to_u8_wrap(16)) + I64.shl_wrap(g, I64.to_u8_wrap(8))) + bl)
	}) })

	comp_corner_r : Theme.CornerStyle -> I64
	comp_corner_r = |c| (match c {
		CornerSharp => 0
		CornerRound(r) => r
		CornerBevel(r) => r
	})

	comp_fit_r : Theme.CornerStyle, I64, I64, I64 -> I64
	comp_fit_r = |c, w, h, s| MathLib.math_min((comp_corner_r(c) * s), I64.div_trunc_by(MathLib.math_min(w, h), 2))

	comp_corner_ins256 : Theme.CornerStyle, I64, I64, I64, I64 -> I64
	comp_corner_ins256 = |c, w, h, y, s| comp_arc256(c, comp_fit_r(c, w, h, s), (2 * MathLib.math_min(y, ((h - 1) - y))))

	comp_arc256 : Theme.CornerStyle, I64, I64 -> I64
	comp_arc256 = |c, k, d2| (if (k <= 0) { 0 } else { (if (d2 >= (2 * k)) { 0 } else { (match c {
		CornerSharp => 0
		CornerBevel(_r) => (((2 * k) - d2) * 128)
		CornerRound(_r) => ({
			dy2 = ((2 * k) - d2)
			((k * 256) - MathLib.math_isqrt(((((4 * k) * k) - (dy2 * dy2)) * 16384)))
		})
	}) }) })

	comp_arc_cov : Theme.CornerStyle, I64, I64, I64 -> I64
	comp_arc_cov = |c, k, d, i| ({
		v = (((d + 1) * 256) - comp_arc256(c, k, ((2 * i) + 1)))
		(if (v <= 0) { 0 } else { (if (v > 255) { 255 } else { v }) })
	})

	comp_round_run! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BoxModel.LayoutRect, Theme.CornerStyle, I64, I64, Bool, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	comp_round_run! = |mem, base, stride, rows, clip, r, c, c0, c1, horiz, flat, k, d, row, i, hi| (if (i >= hi) { (mem, 0) } else { ({
		cov = comp_arc_cov(c, k, d, i)
		lx = (r.lr_x + i)
		rx = (((r.lr_x + r.lr_w) - 1) - i)
		lc = (if horiz { comp_lerp(c0, c1, i, r.lr_w) } else { flat })
		rc = (if horiz { comp_lerp(c0, c1, (rx - r.lr_x), r.lr_w) } else { flat })
		(mem1, _a) = (if (cov <= 0) { (mem, 0) } else { comp_blend_px!(mem, base, stride, rows, clip, lx, row, lc, cov) })
		(mem2, _b) = (if (cov <= 0) { (mem1, 0) } else { (if (rx <= lx) { (mem1, 0) } else { comp_blend_px!(mem1, base, stride, rows, clip, rx, row, rc, cov) }) })
		comp_round_run!(mem2, base, stride, rows, clip, r, c, c0, c1, horiz, flat, k, d, row, (i + 1), hi)
	}) })

	comp_fill! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	comp_fill! = |mem, base, stride, rows, clip, px, py, pw, ph, color| ({
		x0 = MathLib.math_max(px, clip.lr_x)
		y0 = MathLib.math_max(py, clip.lr_y)
		x1 = MathLib.math_min((px + pw), (clip.lr_x + clip.lr_w))
		y1 = MathLib.math_min((py + ph), (clip.lr_y + clip.lr_h))
		(if (x1 <= x0) { (mem, 0) } else { (if (y1 <= y0) { (mem, 0) } else { GopDraw.gop_fill_rect!(mem, base, stride, rows, x0, y0, (x1 - x0), (y1 - y0), color) }) })
	})

	comp_row_h! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	comp_row_h! = |mem, base, stride, rows, clip, bx, bw, y, x, xend, a, b| (if (x >= xend) { (mem, 0) } else { ({
		(mem1, _p) = (if (x < clip.lr_x) { (mem, 0) } else { (if (x >= (clip.lr_x + clip.lr_w)) { (mem, 0) } else { GopDraw.gop_put!(mem, base, stride, rows, x, y, comp_lerp(a, b, (x - bx), bw)) }) })
		comp_row_h!(mem1, base, stride, rows, clip, bx, bw, y, (x + 1), xend, a, b)
	}) })

	comp_blend_px! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, I64, I64, I64, I64 => (Mem.Mem, I64)
	comp_blend_px! = |mem, base, stride, rows, clip, x, y, c, a| (if (a <= 0) { (mem, 0) } else { (if (x < clip.lr_x) { (mem, 0) } else { (if (x >= (clip.lr_x + clip.lr_w)) { (mem, 0) } else { (if (y < clip.lr_y) { (mem, 0) } else { (if (y >= (clip.lr_y + clip.lr_h)) { (mem, 0) } else { (if (a >= 255) { GopDraw.gop_put!(mem, base, stride, rows, x, y, c) } else { ({
		(mem1, mem__630) = GopDraw.gop_get!(mem, base, stride, rows, x, y)
		GopDraw.gop_put!(mem1, base, stride, rows, x, y, comp_lerp(mem__630, c, a, 256))
	}) }) }) }) }) }) })

	comp_rows! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BoxModel.LayoutRect, Theme.CornerStyle, I64, I64, Bool, Bool, I64, I64 => (Mem.Mem, I64)
	comp_rows! = |mem, base, stride, rows, clip, r, cs, c0, c1, grad, horiz, y, s| (if (y >= r.lr_h) { (mem, 0) } else { ({
		k = comp_fit_r(cs, r.lr_w, r.lr_h, s)
		d = MathLib.math_min(y, ((r.lr_h - 1) - y))
		outer = comp_arc256(cs, k, (2 * d))
		inner = comp_arc256(cs, k, ((2 * d) + 2))
		hi = I64.div_trunc_by((outer + 255), 256)
		lo = I64.div_trunc_by(inner, 256)
		w = BoxModel.box_clamp0((r.lr_w - (2 * hi)))
		x = (r.lr_x + hi)
		flat = (if grad { comp_lerp(c0, c1, y, r.lr_h) } else { c0 })
		row = (r.lr_y + y)
		inside = ((row >= clip.lr_y) and (row < (clip.lr_y + clip.lr_h)))
		(mem1, _one) = (if (w <= 0) { (mem, 0) } else { (if (inside == False) { (mem, 0) } else { (if (grad and horiz) { comp_row_h!(mem, base, stride, rows, clip, r.lr_x, r.lr_w, row, x, (x + w), c0, c1) } else { comp_fill!(mem, base, stride, rows, clip, x, row, w, 1, flat) }) }) })
		(mem2, _e) = (if (inside == False) { (mem1, 0) } else { comp_round_run!(mem1, base, stride, rows, clip, r, cs, c0, c1, (grad and horiz), flat, k, d, row, lo, hi) })
		comp_rows!(mem2, base, stride, rows, clip, r, cs, c0, c1, grad, horiz, (y + 1), s)
	}) })

	comp_border_box : BoxModel.LayoutRect, Theme.WidgetStyle -> BoxModel.LayoutRect
	comp_border_box = |b, st| ({
		m = st.ws_margin
		bw = BoxModel.box_clamp0((b.lr_w - Theme.edges_h(m)))
		bh = BoxModel.box_clamp0((b.lr_h - Theme.edges_v(m)))
		BoxModel.layout_rect((b.lr_x + m.edge_left), (b.lr_y + m.edge_top), bw, bh)
	})

	comp_fill_box! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BoxModel.LayoutRect, Theme.WidgetStyle, I64, I64 => (Mem.Mem, I64)
	comp_fill_box! = |mem, base, stride, rows, clip, r, st, bg, s| ({
		g = st.ws_gradient
		on = g.gr_enabled
		c0 = (if on { g.gr_start_color } else { bg })
		c1 = (if on { g.gr_end_color } else { bg })
		horiz = (on and (g.gr_vertical == False))
		comp_rows!(mem, base, stride, rows, clip, r, st.ws_border.bdr_corner, c0, c1, on, horiz, 0, s)
	})

	comp_blend_run! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	comp_blend_run! = |mem, base, stride, rows, clip, x, xend, y, c, a| (if (x >= xend) { (mem, 0) } else { ({
		(mem1, _p) = comp_blend_px!(mem, base, stride, rows, clip, x, y, c, a)
		comp_blend_run!(mem1, base, stride, rows, clip, (x + 1), xend, y, c, a)
	}) })

	comp_shadow_row! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	comp_shadow_row! = |mem, base, stride, rows, clip, x0, x1, y, c, a, ey0, ey1, ex0, ex1| (if (y < ey0) { comp_blend_run!(mem, base, stride, rows, clip, x0, x1, y, c, a) } else { (if (y >= ey1) { comp_blend_run!(mem, base, stride, rows, clip, x0, x1, y, c, a) } else { ({
		(mem1, _l) = comp_blend_run!(mem, base, stride, rows, clip, x0, MathLib.math_min(x1, ex0), y, c, a)
		comp_blend_run!(mem1, base, stride, rows, clip, MathLib.math_max(x0, ex1), x1, y, c, a)
	}) }) })

	comp_shadow_layer! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BoxModel.LayoutRect, I64, Theme.CornerStyle, I64, I64, BoxModel.LayoutRect, I64, I64 => (Mem.Mem, I64)
	comp_shadow_layer! = |mem, base, stride, rows, clip, r, lk, cs, c, a, ex, ek, y| (if (y >= r.lr_h) { (mem, 0) } else { ({
		d = MathLib.math_min(y, ((r.lr_h - 1) - y))
		ins = I64.div_trunc_by(comp_arc256(cs, lk, (2 * d)), 256)
		row = (r.lr_y + y)
		ey = (row - ex.lr_y)
		ed = (if (ey < 0) { (0 - 1) } else { (if (ey >= ex.lr_h) { (0 - 1) } else { MathLib.math_min(ey, ((ex.lr_h - 1) - ey)) }) })
		eins = (if (ed < 0) { 0 } else { I64.div_trunc_by(comp_arc256(cs, ek, (2 * ed)), 256) })
		(mem1, _one) = comp_shadow_row!(mem, base, stride, rows, clip, (r.lr_x + ins), ((r.lr_x + r.lr_w) - ins), row, c, a, ex.lr_y, (ex.lr_y + ex.lr_h), (ex.lr_x + eins), ((ex.lr_x + ex.lr_w) - eins))
		comp_shadow_layer!(mem1, base, stride, rows, clip, r, lk, cs, c, a, ex, ek, (y + 1))
	}) })

	comp_grow : BoxModel.LayoutRect, I64 -> BoxModel.LayoutRect
	comp_grow = |r, k| BoxModel.layout_rect((r.lr_x - k), (r.lr_y - k), (r.lr_w + (2 * k)), (r.lr_h + (2 * k)))

	comp_shadow_stack! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BoxModel.LayoutRect, Theme.CornerStyle, I64, I64, BoxModel.LayoutRect, I64, I64 => (Mem.Mem, I64)
	comp_shadow_stack! = |mem, base, stride, rows, clip, sr, cs, c, a, ex, ek, j| (if (j < 0) { (mem, 0) } else { ({
		(mem1, _one) = comp_shadow_layer!(mem, base, stride, rows, clip, comp_grow(sr, j), (ek + j), cs, c, a, ex, ek, 0)
		comp_shadow_stack!(mem1, base, stride, rows, clip, sr, cs, c, a, ex, ek, (j - 1))
	}) })

	comp_shadow! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BoxModel.LayoutRect, Theme.WidgetStyle, I64 => (Mem.Mem, I64)
	comp_shadow! = |mem, base, stride, rows, clip, r, st, s| ({
		sh = st.ws_shadow
		(if (sh.sh_enabled == False) { (mem, 0) } else { ({
			sr = BoxModel.layout_rect((r.lr_x + (sh.sh_offset_x * s)), (r.lr_y + (sh.sh_offset_y * s)), r.lr_w, r.lr_h)
			cs = st.ws_border.bdr_corner
			k = (sh.sh_blur * s)
			ek = comp_fit_r(cs, r.lr_w, r.lr_h, s)
			(if (k <= 0) { comp_rows!(mem, base, stride, rows, clip, sr, cs, sh.sh_color, sh.sh_color, False, False, 0, s) } else { comp_shadow_stack!(mem, base, stride, rows, clip, sr, cs, sh.sh_color, I64.div_trunc_by(255, (k + 1)), r, ek, k) })
		}) })
	})

	comp_bstroke_run! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BoxModel.LayoutRect, Theme.CornerStyle, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	comp_bstroke_run! = |mem, base, stride, rows, clip, r, c, k, n, col, d, row, i, hi| (if (i >= hi) { (mem, 0) } else { ({
		outer = comp_arc_cov(c, k, d, i)
		di = (d - n)
		ii = (i - n)
		inner = (if (di < 0) { 0 } else { (if (ii < 0) { 0 } else { comp_arc_cov(c, (k - n), di, ii) }) })
		a = (outer - inner)
		cov = (if (a <= 0) { 0 } else { (if (a > 255) { 255 } else { a }) })
		lx = (r.lr_x + i)
		rx = (((r.lr_x + r.lr_w) - 1) - i)
		(mem1, _p0) = (if (cov <= 0) { (mem, 0) } else { comp_blend_px!(mem, base, stride, rows, clip, lx, row, col, cov) })
		(mem2, _p1) = (if (cov <= 0) { (mem1, 0) } else { (if (rx <= lx) { (mem1, 0) } else { comp_blend_px!(mem1, base, stride, rows, clip, rx, row, col, cov) }) })
		comp_bstroke_run!(mem2, base, stride, rows, clip, r, c, k, n, col, d, row, (i + 1), hi)
	}) })

	comp_bstroke! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BoxModel.LayoutRect, Theme.CornerStyle, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	comp_bstroke! = |mem, base, stride, rows, clip, r, c, k, tn, tc, bn, bc, y| (if (y >= r.lr_h) { (mem, 0) } else { ({
		d = MathLib.math_min(y, ((r.lr_h - 1) - y))
		(if (d >= k) { comp_bstroke!(mem, base, stride, rows, clip, r, c, k, tn, tc, bn, bc, (y + 1)) } else { ({
			top = ((y * 2) < r.lr_h)
			n = (if top { tn } else { bn })
			col = (if top { tc } else { bc })
			hi = MathLib.math_min(I64.div_trunc_by(r.lr_w, 2), ((k + n) + 1))
			(mem1, _one) = (if (n <= 0) { (mem, 0) } else { comp_bstroke_run!(mem, base, stride, rows, clip, r, c, k, n, col, d, (r.lr_y + y), 0, hi) })
			comp_bstroke!(mem1, base, stride, rows, clip, r, c, k, tn, tc, bn, bc, (y + 1))
		}) })
	}) })

	comp_border! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BoxModel.LayoutRect, Theme.Border, I64 => (Mem.Mem, I64)
	comp_border! = |mem, base, stride, rows, clip, r, bd, s| ({
		k = comp_fit_r(bd.bdr_corner, r.lr_w, r.lr_h, s)
		ih = BoxModel.box_clamp0((r.lr_w - (2 * k)))
		iv = BoxModel.box_clamp0((r.lr_h - (2 * k)))
		tw = (bd.bdr_top.brd_width * s)
		bw = (bd.bdr_bottom.brd_width * s)
		lw = (bd.bdr_left.brd_width * s)
		rw = (bd.bdr_right.brd_width * s)
		(mem1, _d0) = (if ((tw > 0) and (ih > 0)) { comp_fill!(mem, base, stride, rows, clip, (r.lr_x + k), r.lr_y, ih, tw, bd.bdr_top.brd_color) } else { (mem, 0) })
		(mem2, _d1) = (if ((bw > 0) and (ih > 0)) { comp_fill!(mem1, base, stride, rows, clip, (r.lr_x + k), ((r.lr_y + r.lr_h) - bw), ih, bw, bd.bdr_bottom.brd_color) } else { (mem1, 0) })
		(mem3, _d2) = (if ((lw > 0) and (iv > 0)) { comp_fill!(mem2, base, stride, rows, clip, r.lr_x, (r.lr_y + k), lw, iv, bd.bdr_left.brd_color) } else { (mem2, 0) })
		(mem4, _d3) = (if ((rw > 0) and (iv > 0)) { comp_fill!(mem3, base, stride, rows, clip, ((r.lr_x + r.lr_w) - rw), (r.lr_y + k), rw, iv, bd.bdr_right.brd_color) } else { (mem3, 0) })
		(if (k <= 0) { (mem4, 0) } else { comp_bstroke!(mem4, base, stride, rows, clip, r, bd.bdr_corner, k, tw, bd.bdr_top.brd_color, bw, bd.bdr_bottom.brd_color, 0) })
	})

	comp_accent! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BoxModel.LayoutRect, Theme.AccentBorder, I64 => (Mem.Mem, I64)
	comp_accent! = |mem, base, stride, rows, clip, r, ab, s| (if (ab.ab_enabled == False) { (mem, 0) } else { ({
		n = (ab.ab_width * s)
		(if (n <= 0) { (mem, 0) } else { (if (ab.ab_side == 0) { comp_fill!(mem, base, stride, rows, clip, r.lr_x, r.lr_y, r.lr_w, n, ab.ab_color) } else { (if (ab.ab_side == 1) { comp_fill!(mem, base, stride, rows, clip, ((r.lr_x + r.lr_w) - n), r.lr_y, n, r.lr_h, ab.ab_color) } else { (if (ab.ab_side == 2) { comp_fill!(mem, base, stride, rows, clip, r.lr_x, ((r.lr_y + r.lr_h) - n), r.lr_w, n, ab.ab_color) } else { comp_fill!(mem, base, stride, rows, clip, r.lr_x, r.lr_y, n, r.lr_h, ab.ab_color) }) }) }) })
	}) })

	comp_bevel! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BoxModel.LayoutRect, Theme.WidgetStyle, I64 => (Mem.Mem, I64)
	comp_bevel! = |mem, base, stride, rows, clip, r, st, s| ({
		bv = st.ws_bevel
		(if (bv.bv_enabled == False) { (mem, 0) } else { ({
			n = (bv.bv_width * s)
			(if (n <= 0) { (mem, 0) } else { ({
				k = comp_fit_r(st.ws_border.bdr_corner, r.lr_w, r.lr_h, s)
				ih = BoxModel.box_clamp0((r.lr_w - (2 * k)))
				iv = BoxModel.box_clamp0((r.lr_h - (2 * k)))
				tl = Theme.bevel_tl(bv)
				br = Theme.bevel_br(bv)
				(mem1, _d0) = (if (ih > 0) { comp_fill!(mem, base, stride, rows, clip, (r.lr_x + k), r.lr_y, ih, n, tl) } else { (mem, 0) })
				(mem2, _d1) = (if (iv > 0) { comp_fill!(mem1, base, stride, rows, clip, r.lr_x, (r.lr_y + k), n, iv, tl) } else { (mem1, 0) })
				(mem3, _d2) = (if (ih > 0) { comp_fill!(mem2, base, stride, rows, clip, (r.lr_x + k), ((r.lr_y + r.lr_h) - n), ih, n, br) } else { (mem2, 0) })
				(if (iv > 0) { comp_fill!(mem3, base, stride, rows, clip, ((r.lr_x + r.lr_w) - n), (r.lr_y + k), n, iv, br) } else { (mem3, 0) })
			}) })
		}) })
	})

	comp_mul_rect : BoxModel.LayoutRect, I64 -> BoxModel.LayoutRect
	comp_mul_rect = |r, s| BoxModel.layout_rect((r.lr_x * s), (r.lr_y * s), (r.lr_w * s), (r.lr_h * s))

	comp_box! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BoxModel.LayoutRect, Theme.WidgetStyle, I64, I64 => (Mem.Mem, I64)
	comp_box! = |mem, base, stride, rows, clip, b, st, bg, s| ({
		r = comp_mul_rect(comp_border_box(b, st), s)
		(if ((r.lr_w <= 0) or (r.lr_h <= 0)) { (mem, 0) } else { ({
			(mem1, _sh) = comp_shadow!(mem, base, stride, rows, clip, r, st, s)
			(mem2, _f) = comp_fill_box!(mem1, base, stride, rows, clip, r, st, bg, s)
			(mem3, _d) = comp_border!(mem2, base, stride, rows, clip, r, st.ws_border, s)
			(mem4, _bv) = comp_bevel!(mem3, base, stride, rows, clip, r, st, s)
			comp_accent!(mem4, base, stride, rows, clip, r, st.ws_accent_border, s)
		}) })
	})

	comp_glyph_h : I64
	comp_glyph_h = 16

	comp_cell_w : I64
	comp_cell_w = 8

	comp_text! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BitmapFont.CbfFont, GopFont.GopFont, BoxModel.LayoutRect, Str, I64, I64 => (Mem.Mem, I64)
	comp_text! = |mem, base, stride, rows, clip, font, tf, c, t, fg, s| ({
		gh = (if tf.gf_ok { tf.gf_gh } else { (comp_glyph_h * s) })
		dy = (if tf.gf_ok { (I64.div_trunc_by((c.lr_h - tf.gf_cap), 2) - (tf.gf_asc - tf.gf_cap)) } else { (if (c.lr_h > gh) { I64.div_trunc_by((c.lr_h - gh), 2) } else { 0 }) })
		ty = (c.lr_y + dy)
		(if (ty < clip.lr_y) { (mem, 0) } else { (if ((ty + gh) > (clip.lr_y + clip.lr_h)) { (mem, 0) } else { (if (c.lr_x < clip.lr_x) { (mem, 0) } else { (if tf.gf_ok { ({
			cr = (c.lr_x + c.lr_w)
			pr = (clip.lr_x + clip.lr_w)
			right = (if (cr < pr) { cr } else { pr })
			(mem1, shown) = comp_fit_px!(mem, tf, t, (right - c.lr_x))
			GopFont.gfont_text_clip!(mem1, tf, base, stride, (clip.lr_y + clip.lr_h), right, c.lr_x, ty, shown, fg)
		}) } else { GopDraw.gop_draw_text!(mem, base, stride, rows, font, c.lr_x, ty, comp_fit(t, comp_cols(c, s)), fg, s, 0) }) }) }) })
	})

	comp_fit_px! : Mem.Mem, GopFont.GopFont, Str, I64 => (Mem.Mem, Str)
	comp_fit_px! = |mem, tf, t, avail| (if (avail <= 0) { (mem, "") } else { ({
		(mem1, mem__631) = GopFont.gfont_text_w!(mem, tf, t)
		(if (mem__631 <= avail) { (mem1, t) } else { comp_fit_px_loop!(mem1, tf, t, avail, 0, (Cce.length(t) - 1)) })
	}) })

	comp_fit_px_loop! : Mem.Mem, GopFont.GopFont, Str, I64, I64, I64 => (Mem.Mem, Str)
	comp_fit_px_loop! = |mem, tf, t, avail, lo, hi| (if (hi <= lo) { (mem, Cce.substring(t, 0, lo)) } else { ({
		mid = I64.div_trunc_by(((lo + hi) + 1), 2)
		({
			(mem1, mem__632) = GopFont.gfont_text_w!(mem, tf, Cce.substring(t, 0, mid))
			(if (mem__632 <= avail) { comp_fit_px_loop!(mem1, tf, t, avail, mid, hi) } else { comp_fit_px_loop!(mem1, tf, t, avail, lo, (mid - 1)) })
		})
	}) })

	comp_cols : BoxModel.LayoutRect, I64 -> I64
	comp_cols = |c, s| I64.div_trunc_by(c.lr_w, (comp_cell_w * s))

	comp_gauge_fill! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BoxModel.LayoutRect, I64, I64, I64 => (Mem.Mem, I64)
	comp_gauge_fill! = |mem, base, stride, rows, clip, b, v, mx, fg| (if (mx <= 0) { (mem, 0) } else { ({
		fw = I64.div_trunc_by((b.lr_w * (if (v > mx) { mx } else { v })), mx)
		(if (fw <= 0) { (mem, 0) } else { comp_fill!(mem, base, stride, rows, clip, b.lr_x, b.lr_y, fw, b.lr_h, fg) })
	}) })

	comp_fit : Str, I64 -> Str
	comp_fit = |t, cols| (if (cols <= 0) { "" } else { (if (Cce.length(t) <= cols) { t } else { Cce.substring(t, 0, cols) }) })

	comp_input! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BitmapFont.CbfFont, GopFont.GopFont, BoxModel.LayoutRect, BoxModel.LayoutRect, Theme.WidgetStyle, Str, I64, I64, I64 => (Mem.Mem, I64)
	comp_input! = |mem, base, stride, rows, clip, font, tf, b, c, st, t, cursor, fg, s| ({
		(mem1, _fill) = comp_box!(mem, base, stride, rows, clip, b, st, st.ws_bg, s)
		(mem2, _txt) = comp_text!(mem1, base, stride, rows, clip, font, tf, c, t, fg, s)
		n = (if (cursor < 0) { 0 } else { (if (cursor > Cce.length(t)) { Cce.length(t) } else { cursor }) })
		gh = (if tf.gf_ok { tf.gf_cap } else { (comp_glyph_h * s) })
		(mem4, mem__634) = (if tf.gf_ok { ({
			(mem3, mem__633) = GopFont.gfont_text_w!(mem2, tf, Cce.substring(t, 0, n))
			(mem3, (c.lr_x + mem__633))
		}) } else { (mem2, (c.lr_x + ((cursor * comp_cell_w) * s))) })
		want = mem__634
		hi = ((c.lr_x + c.lr_w) - 1)
		cx = (if (want > hi) { hi } else { want })
		ch = (if (c.lr_h < gh) { c.lr_h } else { gh })
		dy = (if (c.lr_h > gh) { I64.div_trunc_by((c.lr_h - gh), 2) } else { 0 })
		(if ((ch <= 0) or (cx < c.lr_x)) { (mem4, 0) } else { comp_fill!(mem4, base, stride, rows, clip, cx, (c.lr_y + dy), s, ch, fg) })
	})

	comp_dot! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BoxModel.LayoutRect, I64, I64, Bool => (Mem.Mem, I64)
	comp_dot! = |mem, base, stride, rows, clip, c, fg, bg, filled| ({
		d = MathLib.math_min(c.lr_w, c.lr_h)
		(if (d <= 0) { (mem, 0) } else { ({
			x = (c.lr_x + I64.div_trunc_by((c.lr_w - d), 2))
			y = (c.lr_y + I64.div_trunc_by((c.lr_h - d), 2))
			(mem1, outer) = comp_rows!(mem, base, stride, rows, clip, BoxModel.layout_rect(x, y, d, d), CornerRound(I64.div_trunc_by(d, 2)), fg, fg, False, False, 0, 1)
			(if filled { (mem1, outer) } else { ({
				t = (if (d >= 6) { I64.div_trunc_by(d, 4) } else { 1 })
				id = (d - (2 * t))
				(if (id <= 0) { (mem1, outer) } else { comp_rows!(mem1, base, stride, rows, clip, BoxModel.layout_rect((x + t), (y + t), id, id), CornerRound(I64.div_trunc_by(id, 2)), bg, bg, False, False, 0, 1) })
			}) })
		}) })
	})

	comp_icon_tag : Str -> Bool
	comp_icon_tag = |tag| (if (Cce.length(tag) <= 5) { False } else { (Cce.substring(tag, 0, 5) == "icon:") })

	comp_icon! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BoxModel.LayoutRect, Str, I64 => (Mem.Mem, I64)
	comp_icon! = |mem, base, stride, rows, clip, c, tag, fg| ({
		name = Cce.substring(tag, 5, (Cce.length(tag) - 5))
		d = MathLib.math_min(c.lr_w, c.lr_h)
		sc = (if (d < 8) { 1 } else { I64.div_trunc_by(d, 8) })
		sz = (8 * sc)
		x = (c.lr_x + I64.div_trunc_by((c.lr_w - sz), 2))
		y = (c.lr_y + I64.div_trunc_by((c.lr_h - sz), 2))
		(if (x < clip.lr_x) { (mem, 0) } else { (if (y < clip.lr_y) { (mem, 0) } else { (if ((x + sz) > (clip.lr_x + clip.lr_w)) { (mem, 0) } else { (if ((y + sz) > (clip.lr_y + clip.lr_h)) { (mem, 0) } else { GopIcon.gicon_blit!(mem, base, stride, rows, GopIcon.gicon_named(name), x, y, sc, fg) }) }) }) })
	})

	comp_custom! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BoxModel.LayoutRect, BoxModel.LayoutRect, Theme.WidgetStyle, Str, I64, I64 => (Mem.Mem, I64)
	comp_custom! = |mem, base, stride, rows, clip, b, c, st, tag, fg, s| (if ((tag == Widget.wk_scroll_view_tag) or (tag == Widget.wk_spacer_tag)) { (mem, 0) } else { (if (tag == "event-dot") { comp_fill!(mem, base, stride, rows, clip, ((c.lr_x + I64.div_trunc_by(c.lr_w, 2)) - (3 * s)), ((c.lr_y + I64.div_trunc_by(c.lr_h, 2)) - (3 * s)), (6 * s), (6 * s), fg) } else { (if (tag == "status-dot") { comp_dot!(mem, base, stride, rows, clip, comp_mul_rect(b, s), fg, st.ws_bg, False) } else { (if (tag == "status-dot-filled") { comp_dot!(mem, base, stride, rows, clip, comp_mul_rect(b, s), fg, st.ws_bg, True) } else { (if comp_icon_tag(tag) { comp_icon!(mem, base, stride, rows, clip, comp_mul_rect(b, s), tag, fg) } else { comp_box!(mem, base, stride, rows, clip, b, st, st.ws_bg, s) }) }) }) }) })

	comp_fg : Theme.Theme, Widget.WidgetNode, Theme.WidgetStyle -> I64
	comp_fg = |th, node, st| Theme.theme_tone_fg(th, node.wn_tone, st.ws_fg)

	comp_draw_node! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BitmapFont.CbfFont, GopFont.GopFont, Widget.WidgetNode, Theme.Theme, I64 => (Mem.Mem, I64)
	comp_draw_node! = |mem, base, stride, rows, clip, font, tf, node, th, s| ({
		st = Widget.widget_resolve_style(node, th)
		b = node.wn_bounds
		c = comp_mul_rect(BoxModel.box_content_from_style(b, st), s)
		fg = comp_fg(th, node, st)
		(match node.wn_kind {
			WkPanel => comp_box!(mem, base, stride, rows, clip, b, st, st.ws_bg, s)
			WkSeparator => comp_box!(mem, base, stride, rows, clip, b, st, st.ws_fg, s)
			WkLabel(t) => comp_text!(mem, base, stride, rows, clip, font, tf, c, t, fg, s)
			WkButton(t) => ({
				(mem1, _bg) = comp_box!(mem, base, stride, rows, clip, b, st, st.ws_bg, s)
				comp_text!(mem1, base, stride, rows, clip, font, tf, c, t, fg, s)
			})
			WkGauge(v, mx) => ({
				(mem2, _bg) = comp_box!(mem, base, stride, rows, clip, b, st, st.ws_bg, s)
				comp_gauge_fill!(mem2, base, stride, rows, clip, c, v, mx, fg)
			})
			WkInput(t, cur) => comp_input!(mem, base, stride, rows, clip, font, tf, b, c, st, t, cur, fg, s)
			WkCustom(tag) => comp_custom!(mem, base, stride, rows, clip, b, c, st, tag, fg, s)
			_ => (mem, 0)
		})
	})

	comp_translate : Widget.WidgetNode, I64, I64 -> Widget.WidgetNode
	comp_translate = |n, dx, dy| ({
		b = n.wn_bounds
		moved = { ..n, wn_bounds: BoxModel.layout_rect((b.lr_x + dx), (b.lr_y + dy), b.lr_w, b.lr_h) }
		_k = comp_translate_kids(n.wn_children, dx, dy, 0)
		moved
	})

	comp_translate_kids : List(Widget.WidgetNode), I64, I64, I64 -> I64
	comp_translate_kids = |ks, dx, dy, i| (if (i >= U64.to_i64_wrap(List.len(ks))) { 0 } else { ({
		_t = comp_translate((List.get(ks, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), dx, dy)
		comp_translate_kids(ks, dx, dy, (i + 1))
	}) })

	comp_walk! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BitmapFont.CbfFont, GopFont.GopFont, Widget.WidgetNode, Theme.Theme, I64 => (Mem.Mem, I64)
	comp_walk! = |mem, base, stride, rows, clip, font, tf, node, th, s| ({
		(mem1, _d) = comp_draw_node!(mem, base, stride, rows, clip, font, tf, node, th, s)
		comp_walk_kids!(mem1, base, stride, rows, clip, font, tf, node.wn_children, th, 0, s)
	})

	comp_walk_kids! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BitmapFont.CbfFont, GopFont.GopFont, List(Widget.WidgetNode), Theme.Theme, I64, I64 => (Mem.Mem, I64)
	comp_walk_kids! = |mem, base, stride, rows, clip, font, tf, kids, th, i, s| (if (i >= U64.to_i64_wrap(List.len(kids))) { (mem, 0) } else { ({
		(mem1, _w) = comp_walk!(mem, base, stride, rows, clip, font, tf, (List.get(kids, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), th, s)
		comp_walk_kids!(mem1, base, stride, rows, clip, font, tf, kids, th, (i + 1), s)
	}) })

	comp_walk_except! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BitmapFont.CbfFont, GopFont.GopFont, Widget.WidgetNode, Theme.Theme, I64, Str => (Mem.Mem, I64)
	comp_walk_except! = |mem, base, stride, rows, clip, font, tf, node, th, s, skip| (if (node.wn_id == skip) { (mem, 0) } else { ({
		(mem1, _d) = comp_draw_node!(mem, base, stride, rows, clip, font, tf, node, th, s)
		comp_walk_except_kids!(mem1, base, stride, rows, clip, font, tf, node.wn_children, th, 0, s, skip)
	}) })

	comp_walk_except_kids! : Mem.Mem, I64, I64, I64, BoxModel.LayoutRect, BitmapFont.CbfFont, GopFont.GopFont, List(Widget.WidgetNode), Theme.Theme, I64, I64, Str => (Mem.Mem, I64)
	comp_walk_except_kids! = |mem, base, stride, rows, clip, font, tf, kids, th, i, s, skip| (if (i >= U64.to_i64_wrap(List.len(kids))) { (mem, 0) } else { ({
		(mem1, _w) = comp_walk_except!(mem, base, stride, rows, clip, font, tf, (List.get(kids, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), th, s, skip)
		comp_walk_except_kids!(mem1, base, stride, rows, clip, font, tf, kids, th, (i + 1), s, skip)
	}) })

	comp_clip : BoxModel.LayoutRect, BoxModel.LayoutRect -> BoxModel.LayoutRect
	comp_clip = |a, b| ({
		x0 = MathLib.math_max(a.lr_x, b.lr_x)
		y0 = MathLib.math_max(a.lr_y, b.lr_y)
		x1 = MathLib.math_min((a.lr_x + a.lr_w), (b.lr_x + b.lr_w))
		y1 = MathLib.math_min((a.lr_y + a.lr_h), (b.lr_y + b.lr_h))
		BoxModel.layout_rect(x0, y0, BoxModel.box_clamp0((x1 - x0)), BoxModel.box_clamp0((y1 - y0)))
	})

	comp_hit_x : I64, I64 -> I64
	comp_hit_x = |mx, s| I64.div_trunc_by(mx, s)

	comp_hit_y : I64, I64 -> I64
	comp_hit_y = |my, s| I64.div_trunc_by(my, s)

	comp_fit_w! : Mem.Mem, GopFont.GopFont, I64, Str => (Mem.Mem, I64)
	comp_fit_w! = |mem, tf, s, t| ({
		(mem1, mem__635) = GopFont.gfont_text_w!(mem, tf, t)
		(mem1, I64.div_trunc_by(((mem__635 + s) - 1), s))
	})

	comp_fit_guess : Widget.WidgetNode, I64 -> Bool
	comp_fit_guess = |n, want| (n.wn_min_w == want)

	comp_fit_node! : Mem.Mem, Widget.WidgetNode, GopFont.GopFont, I64 => (Mem.Mem, Widget.WidgetNode)
	comp_fit_node! = |mem, n, tf, s| ({
		(mem8, mem__643) = ({
		(mem5, mem__640) = (match n.wn_kind {
			WkLabel(t) => ({
				(mem2, mem__637) = (if comp_fit_guess(n, (Cce.length(t) * 8)) { ({
				(mem1, mem__636) = comp_fit_w!(mem, tf, s, t)
				(mem1, Widget.widget_set_min(n, mem__636, n.wn_min_h))
			}) } else { (mem, n) })
				(mem2, mem__637)
			})
			WkButton(t) => ({
				(mem4, mem__639) = (if comp_fit_guess(n, ((Cce.length(t) * 8) + 16)) { ({
				(mem3, mem__638) = comp_fit_w!(mem, tf, s, t)
				(mem3, Widget.widget_set_min(n, (mem__638 + 16), n.wn_min_h))
			}) } else { (mem, n) })
				(mem4, mem__639)
			})
			_ => (mem, n)
		})
		fitted = mem__640
		({
			(mem7, mem__642) = (if (fitted.wn_child_count == 0) { (mem5, fitted) } else { ({
			(mem6, mem__641) = comp_fit_kids!(mem5, fitted.wn_children, tf, s, 0, fitted.wn_child_count, [])
			(mem6, Widget.widget_set_children(fitted, mem__641))
		}) })
			(mem7, mem__642)
		})
	})
		(mem8, mem__643)
	})

	comp_fit_kids! : Mem.Mem, List(Widget.WidgetNode), GopFont.GopFont, I64, I64, I64, List(Widget.WidgetNode) => (Mem.Mem, List(Widget.WidgetNode))
	comp_fit_kids! = |mem, kids, tf, s, i, n, acc| (if (i >= n) { (mem, acc) } else { ({
		(mem1, mem__644) = comp_fit_node!(mem, (List.get(kids, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), tf, s)
		comp_fit_kids!(mem1, kids, tf, s, (i + 1), n, List.append(acc, mem__644))
	}) })

	comp_fit_text! : Mem.Mem, Widget.WidgetNode, GopFont.GopFont, I64 => (Mem.Mem, Widget.WidgetNode)
	comp_fit_text! = |mem, root, tf, s| (if tf.gf_ok { comp_fit_node!(mem, root, tf, s) } else { (mem, root) })

	comp_render_at! : Mem.Mem, I64, I64, I64, BitmapFont.CbfFont, GopFont.GopFont, Widget.WidgetNode, Theme.Theme, I64, I64, I64, I64, I64 => (Mem.Mem, Widget.WidgetNode)
	comp_render_at! = |mem, base, stride, rows, font, tf, root, th, ox, oy, w, h, s| ({
		(mem2, mem__645) = ({
		laid = Widget.widget_layout(root, th, BoxModel.layout_rect(I64.div_trunc_by(ox, s), I64.div_trunc_by(oy, s), I64.div_trunc_by(w, s), I64.div_trunc_by(h, s)))
		(mem1, _d) = comp_walk!(mem, base, stride, rows, BoxModel.layout_rect(ox, oy, w, h), font, tf, laid, th, s)
		(mem1, laid)
	})
		(mem2, mem__645)
	})

	comp_render! : Mem.Mem, I64, I64, I64, BitmapFont.CbfFont, GopFont.GopFont, Widget.WidgetNode, Theme.Theme, I64, I64, I64 => (Mem.Mem, Widget.WidgetNode)
	comp_render! = |mem, base, stride, rows, font, tf, root, th, w, h, s| comp_render_at!(mem, base, stride, rows, font, tf, root, th, 0, 0, w, h, s)
}
