# PixelBuf -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Mem

PixelBuf :: [].{
	GopBuf := { gb_base : I64, gb_width : I64, gb_height : I64 }.{
		is_eq : PixelBuf.GopBuf, PixelBuf.GopBuf -> Bool
		is_eq = |a, b| eq_GopBuf(a, b)
	}

	gop_buf_set! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_set! = |mem, gb, x, y, color| (if (x < 0) { (mem, 0) } else { (if (y < 0) { (mem, 0) } else { (if (x >= gb.gb_width) { (mem, 0) } else { (if (y >= gb.gb_height) { (mem, 0) } else { Mem.store!(mem, gb.gb_base, (((y * gb.gb_width) + x) * 4), color, 4) }) }) }) })

	gop_buf_get! : Mem.Mem, PixelBuf.GopBuf, I64, I64 => (Mem.Mem, I64)
	gop_buf_get! = |mem, gb, x, y| (if (x < 0) { (mem, 0) } else { (if (y < 0) { (mem, 0) } else { (if (x >= gb.gb_width) { (mem, 0) } else { (if (y >= gb.gb_height) { (mem, 0) } else { Mem.load!(mem, gb.gb_base, (((y * gb.gb_width) + x) * 4), 4) }) }) }) })

	gbf_blend_pixel! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64 => (Mem.Mem, I64)
	gbf_blend_pixel! = |mem, gb, x, y, fg, alpha| (if (alpha >= 240) { gop_buf_set!(mem, gb, x, y, fg) } else { ({
		(mem1, bg) = gop_buf_get!(mem, gb, x, y)
		fr : I64
		fr = I64.bitwise_and(I64.shr_zf_wrap(fg, I64.to_u8_wrap(16)), 255)
		fg2 : I64
		fg2 = I64.bitwise_and(I64.shr_zf_wrap(fg, I64.to_u8_wrap(8)), 255)
		fb : I64
		fb = I64.bitwise_and(fg, 255)
		br : I64
		br = I64.bitwise_and(I64.shr_zf_wrap(bg, I64.to_u8_wrap(16)), 255)
		bg2 : I64
		bg2 = I64.bitwise_and(I64.shr_zf_wrap(bg, I64.to_u8_wrap(8)), 255)
		bb : I64
		bb = I64.bitwise_and(bg, 255)
		rr : I64
		rr = (br + I64.div_trunc_by(((fr - br) * alpha), 255))
		rg : I64
		rg = (bg2 + I64.div_trunc_by(((fg2 - bg2) * alpha), 255))
		rb : I64
		rb = (bb + I64.div_trunc_by(((fb - bb) * alpha), 255))
		gop_buf_set!(mem1, gb, x, y, ((I64.shl_wrap(rr, I64.to_u8_wrap(16)) + I64.shl_wrap(rg, I64.to_u8_wrap(8))) + rb))
	}) })

	eq_GopBuf : PixelBuf.GopBuf, PixelBuf.GopBuf -> Bool
	eq_GopBuf = |ex, ey| (((ex.gb_base == ey.gb_base) and (ex.gb_width == ey.gb_width)) and (ex.gb_height == ey.gb_height))
}
