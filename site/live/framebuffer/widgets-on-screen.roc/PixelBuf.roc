# PixelBuf -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Mem

PixelBuf :: [].{
	GopBuf : { gb_base : I64, gb_width : I64, gb_height : I64 }

	gop_buf_new! : Mem.Mem, I64, I64, I64 => (Mem.Mem, PixelBuf.GopBuf)
	gop_buf_new! = |mem, w, h, bg| ({
		(mem3, mem__465) = ({
		size = ((w * h) * 4)
		(mem1, base) = Mem.alloc(mem, size)
		(mem2, _dummy) = gop_buf_fill_loop!(mem1, base, bg, 0, (w * h))
		(mem2, { gb_base: base, gb_width: w, gb_height: h })
	})
		(mem3, mem__465)
	})

	gop_buf_fill_loop! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_fill_loop! = |mem, base, color, i, total| (if (i >= total) { (mem, 0) } else { ({
		(mem1, _dummy) = Mem.store!(mem, base, (i * 4), color, 4)
		gop_buf_fill_loop!(mem1, base, color, (i + 1), total)
	}) })

	gop_buf_set! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_set! = |mem, gb, x, y, color| (if (x < 0) { (mem, 0) } else { (if (y < 0) { (mem, 0) } else { (if (x >= gb.gb_width) { (mem, 0) } else { (if (y >= gb.gb_height) { (mem, 0) } else { Mem.store!(mem, gb.gb_base, (((y * gb.gb_width) + x) * 4), color, 4) }) }) }) })

	gop_buf_get! : Mem.Mem, PixelBuf.GopBuf, I64, I64 => (Mem.Mem, I64)
	gop_buf_get! = |mem, gb, x, y| (if (x < 0) { (mem, 0) } else { (if (y < 0) { (mem, 0) } else { (if (x >= gb.gb_width) { (mem, 0) } else { (if (y >= gb.gb_height) { (mem, 0) } else { Mem.load!(mem, gb.gb_base, (((y * gb.gb_width) + x) * 4), 4) }) }) }) })

	gop_buf_clear! : Mem.Mem, PixelBuf.GopBuf, I64 => (Mem.Mem, I64)
	gop_buf_clear! = |mem, gb, color| gop_buf_fill_loop!(mem, gb.gb_base, color, 0, (gb.gb_width * gb.gb_height))

	gop_buf_rect! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_rect! = |mem, gb, x, y, w, h, color| gop_buf_rect_rows!(mem, gb, x, y, w, h, color, 0)

	gop_buf_rect_rows! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_rect_rows! = |mem, gb, x, y, w, h, color, row| (if (row >= h) { (mem, 0) } else { ({
		(mem1, _dummy) = gop_buf_hline!(mem, gb, x, ((x + w) - 1), (y + row), color)
		gop_buf_rect_rows!(mem1, gb, x, y, w, h, color, (row + 1))
	}) })

	gop_buf_hline! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_hline! = |mem, gb, x0, x1, y, color| (if (y < 0) { (mem, 0) } else { (if (y >= gb.gb_height) { (mem, 0) } else { ({
		cx0 = (if (x0 < 0) { 0 } else { x0 })
		cx1 = (if (x1 >= gb.gb_width) { (gb.gb_width - 1) } else { x1 })
		gop_buf_hline_loop!(mem, gb, cx0, cx1, y, color)
	}) }) })

	gop_buf_hline_loop! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_hline_loop! = |mem, gb, x, x1, y, color| (if (x > x1) { (mem, 0) } else { ({
		(mem1, _dummy) = Mem.store!(mem, gb.gb_base, (((y * gb.gb_width) + x) * 4), color, 4)
		gop_buf_hline_loop!(mem1, gb, (x + 1), x1, y, color)
	}) })

	gop_buf_outline! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_outline! = |mem, gb, x, y, w, h, color| ({
		(mem1, _dummy) = gop_buf_hline!(mem, gb, x, ((x + w) - 1), y, color)
		(mem2, _dummy2) = gop_buf_hline!(mem1, gb, x, ((x + w) - 1), ((y + h) - 1), color)
		(mem3, _dummy3) = gop_buf_vline!(mem2, gb, x, y, ((y + h) - 1), color)
		gop_buf_vline!(mem3, gb, ((x + w) - 1), y, ((y + h) - 1), color)
	})

	gop_buf_vline! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_vline! = |mem, gb, x, y0, y1, color| (if (x < 0) { (mem, 0) } else { (if (x >= gb.gb_width) { (mem, 0) } else { gop_buf_vline_loop!(mem, gb, x, y0, y1, color) }) })

	gop_buf_vline_loop! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_vline_loop! = |mem, gb, x, y, y1, color| (if (y > y1) { (mem, 0) } else { (if (y < 0) { gop_buf_vline_loop!(mem, gb, x, (y + 1), y1, color) } else { (if (y >= gb.gb_height) { (mem, 0) } else { ({
		(mem1, _dummy) = Mem.store!(mem, gb.gb_base, (((y * gb.gb_width) + x) * 4), color, 4)
		gop_buf_vline_loop!(mem1, gb, x, (y + 1), y1, color)
	}) }) }) })

	gbf_blend_pixel! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64 => (Mem.Mem, I64)
	gbf_blend_pixel! = |mem, gb, x, y, fg, alpha| (if (alpha >= 240) { gop_buf_set!(mem, gb, x, y, fg) } else { ({
		(mem1, bg) = gop_buf_get!(mem, gb, x, y)
		fr = I64.bitwise_and(I64.shr_zf_wrap(fg, I64.to_u8_wrap(16)), 255)
		fg2 = I64.bitwise_and(I64.shr_zf_wrap(fg, I64.to_u8_wrap(8)), 255)
		fb = I64.bitwise_and(fg, 255)
		br = I64.bitwise_and(I64.shr_zf_wrap(bg, I64.to_u8_wrap(16)), 255)
		bg2 = I64.bitwise_and(I64.shr_zf_wrap(bg, I64.to_u8_wrap(8)), 255)
		bb = I64.bitwise_and(bg, 255)
		rr = (br + I64.div_trunc_by(((fr - br) * alpha), 255))
		rg = (bg2 + I64.div_trunc_by(((fg2 - bg2) * alpha), 255))
		rb = (bb + I64.div_trunc_by(((fb - bb) * alpha), 255))
		gop_buf_set!(mem1, gb, x, y, ((I64.shl_wrap(rr, I64.to_u8_wrap(16)) + I64.shl_wrap(rg, I64.to_u8_wrap(8))) + rb))
	}) })
}
