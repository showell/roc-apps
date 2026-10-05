# GopDraw -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Mem

GopDraw :: [].{

	gop_put! : Mem.Mem, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_put! = |mem, base, stride, rows, x, y, color| (if (x < 0) { (mem, 0) } else { (if (x >= stride) { (mem, 0) } else { (if (y < 0) { (mem, 0) } else { (if (y >= rows) { (mem, 0) } else { Mem.store!(mem, base, (((y * stride) + x) * 4), color, 4) }) }) }) })

	gop_rect_cols! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_rect_cols! = |mem, base, stride, rows, px, py, pw, color, x| (if (x >= pw) { (mem, 0) } else { ({
		(mem1, _p) = gop_put!(mem, base, stride, rows, (px + x), py, color)
		gop_rect_cols!(mem1, base, stride, rows, px, py, pw, color, (x + 1))
	}) })

	gop_fill_rect! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_fill_rect! = |mem, base, stride, rows, px, py, pw, ph, color| ({
		x0 : I64
		x0 = (if (px < 0) { 0 } else { px })
		x1 : I64
		x1 = (if ((px + pw) > stride) { stride } else { (px + pw) })
		y0 : I64
		y0 = (if (py < 0) { 0 } else { py })
		y1 : I64
		y1 = (if ((py + ph) > rows) { rows } else { (py + ph) })
		(if (x1 <= x0) { (mem, 0) } else { (if (y1 <= y0) { (mem, 0) } else { gop_rect_rows!(mem, base, stride, rows, x0, y0, (x1 - x0), (y1 - y0), color, 0) }) })
	})

	gop_rect_rows! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_rect_rows! = |mem, base, stride, rows, px, py, pw, ph, color, y| (if (y >= ph) { (mem, 0) } else { ({
		(mem1, _r) = gop_rect_cols!(mem, base, stride, rows, px, (py + y), pw, color, 0)
		gop_rect_rows!(mem1, base, stride, rows, px, py, pw, ph, color, (y + 1))
	}) })
}
