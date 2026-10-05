# GuiDisplay -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CCE
import CceText
import Mem
import PixelBuf

GuiDisplay :: [].{
	GopDisplay := { gd_width : I64, gd_height : I64, gd_stride : I64, gd_fb_addr : I64 }.{
		is_eq : GuiDisplay.GopDisplay, GuiDisplay.GopDisplay -> Bool
		is_eq = |a, b| eq_GopDisplay(a, b)
	}
	CursorSave := { cs_base : I64, cs_size : I64 }.{
		is_eq : GuiDisplay.CursorSave, GuiDisplay.CursorSave -> Bool
		is_eq = |a, b| eq_CursorSave(a, b)
	}

	gbf_put_char! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gbf_put_char! = |mem, gb, base, gw, gh, x, y, max_x, cce, fg| ({
		unicode : I64
		unicode = CCE.to_unicode(cce)
		idx : I64
		idx = (unicode - 32)
		(if (idx < 0) { (mem, 0) } else { (if (idx >= 95) { (mem, 0) } else { gbf_put_char_rows!(mem, gb, base, gw, gh, x, y, max_x, idx, fg, 0) }) })
	})

	gbf_put_char_rows! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gbf_put_char_rows! = |mem, gb, base, gw, gh, x, y, max_x, idx, fg, row| (if (row >= gh) { (mem, 0) } else { ({
		(mem1, _dummy) = gbf_put_char_cols!(mem, gb, base, gw, gh, x, y, max_x, idx, fg, row, 0)
		gbf_put_char_rows!(mem1, gb, base, gw, gh, x, y, max_x, idx, fg, (row + 1))
	}) })

	gbf_put_char_cols! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gbf_put_char_cols! = |mem, gb, base, gw, gh, x, y, max_x, idx, fg, row, col| (if (col >= gw) { (mem, 0) } else { (if ((x + col) >= max_x) { (mem, 0) } else { ({
		(mem1, alpha) = Mem.load!(mem, base, ((((idx * gw) * gh) + (row * gw)) + col), 1)
		(mem2, _dummy) = (if (alpha > 0) { PixelBuf.gbf_blend_pixel!(mem1, gb, (x + col), (y + row), fg, alpha) } else { (mem1, 0) })
		gbf_put_char_cols!(mem2, gb, base, gw, gh, x, y, max_x, idx, fg, row, (col + 1))
	}) }) })

	gbf_put_text_clip! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64, I64, I64, CceText, I64 => (Mem.Mem, I64)
	gbf_put_text_clip! = |mem, gb, base, gw, gh, x, y, max_x, s, fg| ({
		adv_table : I64
		adv_table = (base + ((95 * gw) * gh))
		yoff_table : I64
		yoff_table = (adv_table + 95)
		gbf_put_text_loop!(mem, gb, base, gw, gh, adv_table, yoff_table, x, y, max_x, s, fg, 0, CceText.len(s), 0)
	})

	gbf_put_text_loop! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64, I64, I64, I64, I64, CceText, I64, I64, I64, I64 => (Mem.Mem, I64)
	gbf_put_text_loop! = |mem, gb, base, gw, gh, adv_table, yoff_table, x, y, max_x, s, fg, i, n, cx| (if (i >= n) { (mem, 0) } else { (if ((x + cx) >= max_x) { (mem, 0) } else { ({
		code : I64
		code = CceText.char_code_at(s, i)
		unicode : I64
		unicode = CCE.to_unicode(code)
		idx : I64
		idx = (unicode - 32)
		(mem1, adv) = (if (idx >= 0) { (if (idx < 95) { Mem.load!(mem, adv_table, idx, 1) } else { (mem, gw) }) } else { (mem, gw) })
		(if (((x + cx) + adv) > max_x) { (mem1, 0) } else { ({
			(mem2, yoff) = (if (idx >= 0) { (if (idx < 95) { Mem.load!(mem1, yoff_table, idx, 1) } else { (mem1, 0) }) } else { (mem1, 0) })
			(mem3, _dummy) = gbf_put_char!(mem2, gb, base, gw, gh, (x + cx), (y + yoff), max_x, code, fg)
			gbf_put_text_loop!(mem3, gb, base, gw, gh, adv_table, yoff_table, x, y, max_x, s, fg, (i + 1), n, (cx + adv))
		}) })
	}) }) })

	gbf_measure_text! : Mem.Mem, I64, I64, I64, CceText => (Mem.Mem, I64)
	gbf_measure_text! = |mem, base, gw, gh, s| ({
		adv_table : I64
		adv_table = (base + ((95 * gw) * gh))
		gbf_measure_loop!(mem, adv_table, gw, s, 0, CceText.len(s), 0)
	})

	gbf_measure_loop! : Mem.Mem, I64, I64, CceText, I64, I64, I64 => (Mem.Mem, I64)
	gbf_measure_loop! = |mem, adv_table, gw, s, i, n, cx| (if (i >= n) { (mem, cx) } else { ({
		unicode : I64
		unicode = CCE.to_unicode(CceText.char_code_at(s, i))
		idx : I64
		idx = (unicode - 32)
		(mem1, adv) = (if (idx >= 0) { (if (idx < 95) { Mem.load!(mem, adv_table, idx, 1) } else { (mem, gw) }) } else { (mem, gw) })
		gbf_measure_loop!(mem1, adv_table, gw, s, (i + 1), n, (cx + adv))
	}) })

	eq_GopDisplay : GuiDisplay.GopDisplay, GuiDisplay.GopDisplay -> Bool
	eq_GopDisplay = |ex, ey| ((((ex.gd_width == ey.gd_width) and (ex.gd_height == ey.gd_height)) and (ex.gd_stride == ey.gd_stride)) and (ex.gd_fb_addr == ey.gd_fb_addr))

	eq_CursorSave : GuiDisplay.CursorSave, GuiDisplay.CursorSave -> Bool
	eq_CursorSave = |ex, ey| ((ex.cs_base == ey.cs_base) and (ex.cs_size == ey.cs_size))
}
