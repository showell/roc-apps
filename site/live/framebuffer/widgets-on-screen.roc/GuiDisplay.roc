# GuiDisplay -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import BitmapFont
import CCE
import Cce
import GuiTimer
import Mem
import PixelBuf
import Prelude
import SystemFont
import TextOverflow

GuiDisplay :: [].{
	GopDisplay : { gd_width : I64, gd_height : I64, gd_stride : I64, gd_fb_addr : I64 }
	CursorSave : { cs_base : I64, cs_size : I64 }

	gop_fb_base : I64
	gop_fb_base = 3204448256

	gop_display_new : I64, I64 -> GuiDisplay.GopDisplay
	gop_display_new = |w, h| { gd_width: w, gd_height: h, gd_stride: w, gd_fb_addr: gop_fb_base }

	gop_buf_font! : Mem.Mem => (Mem.Mem, BitmapFont.CbfFont)
	gop_buf_font! = |mem| BitmapFont.cbf_init!(mem)

	gop_buf_put_char! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_put_char! = |mem, gb, x, y, cce_code, fg| gop_buf_cbf_rows!(mem, gb, x, y, cce_code, fg, 0)

	gop_buf_cbf_rows! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_cbf_rows! = |mem, gb, x, y, cce_code, fg, row| (if (row >= 16) { (mem, 0) } else { ({
		(mem2, byte) = ({
			(mem1, mem__563) = gop_buf_font!(mem)
			BitmapFont.cbf_row!(mem1, mem__563, cce_code, row)
		})
		(mem3, _dummy) = gop_buf_cbf_bits!(mem2, gb, x, (y + row), byte, fg, 0)
		gop_buf_cbf_rows!(mem3, gb, x, y, cce_code, fg, (row + 1))
	}) })

	gop_buf_cbf_bits! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_cbf_bits! = |mem, gb, x, y, byte, fg, bit| (if (bit >= 8) { (mem, 0) } else { (if (I64.bitwise_and(I64.shr_zf_wrap(byte, I64.to_u8_wrap((7 - bit))), 1) == 1) { ({
		(mem1, _dummy) = PixelBuf.gop_buf_set!(mem, gb, (x + bit), y, fg)
		gop_buf_cbf_bits!(mem1, gb, x, y, byte, fg, (bit + 1))
	}) } else { gop_buf_cbf_bits!(mem, gb, x, y, byte, fg, (bit + 1)) }) })

	gop_buf_put_text! : Mem.Mem, PixelBuf.GopBuf, I64, I64, Str, I64 => (Mem.Mem, I64)
	gop_buf_put_text! = |mem, gb, x, y, s, fg| gop_buf_put_text_clip!(mem, gb, x, y, gb.gb_width, s, fg)

	gop_buf_advance : I64
	gop_buf_advance = 9

	gop_buf_glyph_w : I64
	gop_buf_glyph_w = 8

	gop_buf_put_text_clip! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, Str, I64 => (Mem.Mem, I64)
	gop_buf_put_text_clip! = |mem, gb, x, y, max_x, s, fg| gop_buf_put_text_fit!(mem, gb, x, y, max_x, s, fg, TextOverflow.text_overflow_default)

	gop_buf_put_text_fit! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, Str, I64, TextOverflow.TextOverflow => (Mem.Mem, I64)
	gop_buf_put_text_fit! = |mem, gb, x, y, max_x, s, fg, mode| ({
		(mem3, mem__566) = ({
		len = Cce.length(s)
		avail = (max_x - x)
		start = TextOverflow.text_overflow_start(mode, len, avail, gop_buf_advance, gop_buf_glyph_w)
		count = TextOverflow.text_overflow_count(mode, len, avail, gop_buf_advance, gop_buf_glyph_w)
		dots = TextOverflow.text_overflow_dots(mode, len, avail, gop_buf_advance, gop_buf_glyph_w)
		({
			(mem1, mem__564) = gop_buf_text_loop!(mem, gb, x, y, s, fg, start, (start + count), start)
			(mem2, mem__565) = gop_buf_dots_loop!(mem1, gb, (x + (count * gop_buf_advance)), y, fg, 0, dots)
			(mem2, (mem__564 + mem__565))
		})
	})
		(mem3, mem__566)
	})

	gop_buf_text_loop! : Mem.Mem, PixelBuf.GopBuf, I64, I64, Str, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_text_loop! = |mem, gb, x, y, s, fg, i, stop, start| (if (i >= stop) { (mem, 0) } else { ({
		code = Cce.at(s, i)
		(mem1, _dummy) = gop_buf_put_char!(mem, gb, (x + ((i - start) * gop_buf_advance)), y, code, fg)
		gop_buf_text_loop!(mem1, gb, x, y, s, fg, (i + 1), stop, start)
	}) })

	gop_buf_dots_loop! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_dots_loop! = |mem, gb, x, y, fg, k, n| (if (k >= n) { (mem, 0) } else { ({
		(mem1, _dummy) = gop_buf_put_char!(mem, gb, (x + (k * gop_buf_advance)), y, Cce.at(".", 0), fg)
		gop_buf_dots_loop!(mem1, gb, x, y, fg, (k + 1), n)
	}) })

	gop_sys_font! : Mem.Mem => (Mem.Mem, SystemFont.SysFont)
	gop_sys_font! = |mem| SystemFont.sysfont_init!(mem)

	gop_buf_sys_advance : I64
	gop_buf_sys_advance = 10

	gop_buf_put_text_sys! : Mem.Mem, PixelBuf.GopBuf, I64, I64, Str, I64 => (Mem.Mem, I64)
	gop_buf_put_text_sys! = |mem, gb, x, y, s, fg| gop_buf_put_text_sys_fit!(mem, gb, x, y, gb.gb_width, s, fg, TextOverflow.text_overflow_default)

	gop_buf_put_text_sys_fit! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, Str, I64, TextOverflow.TextOverflow => (Mem.Mem, I64)
	gop_buf_put_text_sys_fit! = |mem, gb, x, y, max_x, s, fg, mode| ({
		(mem3, mem__569) = ({
		len = Cce.length(s)
		avail = (max_x - x)
		start = TextOverflow.text_overflow_start(mode, len, avail, gop_buf_sys_advance, gop_buf_glyph_w)
		count = TextOverflow.text_overflow_count(mode, len, avail, gop_buf_sys_advance, gop_buf_glyph_w)
		dots = TextOverflow.text_overflow_dots(mode, len, avail, gop_buf_sys_advance, gop_buf_glyph_w)
		({
			(mem1, mem__567) = gop_buf_sys_loop!(mem, gb, x, y, s, fg, start, (start + count), start)
			(mem2, mem__568) = gop_buf_sys_dots!(mem1, gb, (x + (count * gop_buf_sys_advance)), y, fg, 0, dots)
			(mem2, (mem__567 + mem__568))
		})
	})
		(mem3, mem__569)
	})

	gop_buf_sys_loop! : Mem.Mem, PixelBuf.GopBuf, I64, I64, Str, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_sys_loop! = |mem, gb, x, y, s, fg, i, stop, start| (if (i >= stop) { (mem, 0) } else { ({
		cce = Cce.at(s, i)
		unicode = CCE.to_unicode(cce)
		(mem1, _dummy) = gop_buf_sys_char!(mem, gb, (x + ((i - start) * gop_buf_sys_advance)), y, unicode, fg)
		gop_buf_sys_loop!(mem1, gb, x, y, s, fg, (i + 1), stop, start)
	}) })

	gop_buf_sys_dots! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_sys_dots! = |mem, gb, x, y, fg, k, n| (if (k >= n) { (mem, 0) } else { ({
		(mem1, _dummy) = gop_buf_sys_char!(mem, gb, (x + (k * gop_buf_sys_advance)), y, CCE.to_unicode(Cce.at(".", 0)), fg)
		gop_buf_sys_dots!(mem1, gb, x, y, fg, (k + 1), n)
	}) })

	gop_buf_sys_char! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_sys_char! = |mem, gb, x, y, unicode, fg| gop_buf_sys_rows!(mem, gb, x, y, unicode, fg, 0)

	gop_buf_sys_rows! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_sys_rows! = |mem, gb, x, y, unicode, fg, row| (if (row >= SystemFont.sysfont_glyph_h) { (mem, 0) } else { ({
		(mem2, byte) = ({
			(mem1, mem__570) = gop_sys_font!(mem)
			SystemFont.sysfont_row!(mem1, mem__570, unicode, row)
		})
		(mem3, _dummy) = gop_buf_cbf_bits!(mem2, gb, x, (y + row), byte, fg, 0)
		gop_buf_sys_rows!(mem3, gb, x, y, unicode, fg, (row + 1))
	}) })

	gop_buf_put_text_mode! : Mem.Mem, PixelBuf.GopBuf, I64, I64, Str, I64, I64 => (Mem.Mem, I64)
	gop_buf_put_text_mode! = |mem, gb, x, y, s, fg, mode| (if (mode == 2) { gop_buf_put_text_sys!(mem, gb, x, y, s, fg) } else { (if (mode == 3) { gop_buf_put_text_scaled!(mem, gb, x, y, s, fg, 2) } else { gop_buf_put_text!(mem, gb, x, y, s, fg) }) })

	gop_buf_put_text_scaled! : Mem.Mem, PixelBuf.GopBuf, I64, I64, Str, I64, I64 => (Mem.Mem, I64)
	gop_buf_put_text_scaled! = |mem, gb, x, y, s, fg, scale| (if (scale <= 1) { gop_buf_put_text!(mem, gb, x, y, s, fg) } else { gop_buf_put_text_scaled_fit!(mem, gb, x, y, gb.gb_width, s, fg, scale, TextOverflow.text_overflow_default) })

	gop_buf_put_text_scaled_fit! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, Str, I64, I64, TextOverflow.TextOverflow => (Mem.Mem, I64)
	gop_buf_put_text_scaled_fit! = |mem, gb, x, y, max_x, s, fg, scale, mode| ({
		len = Cce.length(s)
		avail = (max_x - x)
		start = TextOverflow.text_overflow_start(mode, len, avail, (gop_buf_advance * scale), (gop_buf_glyph_w * scale))
		count = TextOverflow.text_overflow_count(mode, len, avail, (gop_buf_advance * scale), (gop_buf_glyph_w * scale))
		gop_buf_text_scaled_loop!(mem, gb, x, y, s, fg, scale, start, (start + count), start)
	})

	gop_buf_text_scaled_loop! : Mem.Mem, PixelBuf.GopBuf, I64, I64, Str, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_text_scaled_loop! = |mem, gb, x, y, s, fg, scale, i, stop, start| (if (i >= stop) { (mem, 0) } else { ({
		code = Cce.at(s, i)
		(mem1, _dummy) = gop_buf_put_char_scaled!(mem, gb, (x + (((i - start) * gop_buf_advance) * scale)), y, code, fg, scale)
		gop_buf_text_scaled_loop!(mem1, gb, x, y, s, fg, scale, (i + 1), stop, start)
	}) })

	gop_buf_put_char_scaled! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_put_char_scaled! = |mem, gb, x, y, cce_code, fg, scale| gop_buf_cbf_rows_scaled!(mem, gb, x, y, cce_code, fg, scale, 0)

	gop_buf_cbf_rows_scaled! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_cbf_rows_scaled! = |mem, gb, x, y, cce_code, fg, scale, row| (if (row >= 16) { (mem, 0) } else { ({
		(mem2, byte) = ({
			(mem1, mem__571) = gop_buf_font!(mem)
			BitmapFont.cbf_row!(mem1, mem__571, cce_code, row)
		})
		(mem3, _dummy) = gop_buf_cbf_bits_scaled!(mem2, gb, x, (y + (row * scale)), byte, fg, scale, 0)
		gop_buf_cbf_rows_scaled!(mem3, gb, x, y, cce_code, fg, scale, (row + 1))
	}) })

	gop_buf_cbf_bits_scaled! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_buf_cbf_bits_scaled! = |mem, gb, x, y, byte, fg, scale, bit| (if (bit >= 8) { (mem, 0) } else { (if (I64.bitwise_and(I64.shr_zf_wrap(byte, I64.to_u8_wrap((7 - bit))), 1) == 1) { ({
		(mem1, _dummy) = PixelBuf.gop_buf_rect!(mem, gb, (x + (bit * scale)), y, scale, scale, fg)
		gop_buf_cbf_bits_scaled!(mem1, gb, x, y, byte, fg, scale, (bit + 1))
	}) } else { gop_buf_cbf_bits_scaled!(mem, gb, x, y, byte, fg, scale, (bit + 1)) }) })

	gbf_put_char! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gbf_put_char! = |mem, gb, base, gw, gh, x, y, max_x, cce, fg| ({
		unicode = CCE.to_unicode(cce)
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

	gbf_put_text! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64, I64, Str, I64 => (Mem.Mem, I64)
	gbf_put_text! = |mem, gb, base, gw, gh, x, y, s, fg| gbf_put_text_clip!(mem, gb, base, gw, gh, x, y, gb.gb_width, s, fg)

	gbf_put_text_clip! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64, I64, I64, Str, I64 => (Mem.Mem, I64)
	gbf_put_text_clip! = |mem, gb, base, gw, gh, x, y, max_x, s, fg| ({
		adv_table = (base + ((95 * gw) * gh))
		yoff_table = (adv_table + 95)
		gbf_put_text_loop!(mem, gb, base, gw, gh, adv_table, yoff_table, x, y, max_x, s, fg, 0, Cce.length(s), 0)
	})

	gbf_put_text_loop! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64, I64, I64, I64, I64, I64, Str, I64, I64, I64, I64 => (Mem.Mem, I64)
	gbf_put_text_loop! = |mem, gb, base, gw, gh, adv_table, yoff_table, x, y, max_x, s, fg, i, n, cx| (if (i >= n) { (mem, 0) } else { (if ((x + cx) >= max_x) { (mem, 0) } else { ({
		code = Cce.at(s, i)
		unicode = CCE.to_unicode(code)
		idx = (unicode - 32)
		(mem1, adv) = (if (idx >= 0) { (if (idx < 95) { Mem.load!(mem, adv_table, idx, 1) } else { (mem, gw) }) } else { (mem, gw) })
		(if (((x + cx) + adv) > max_x) { (mem1, 0) } else { ({
			(mem2, yoff) = (if (idx >= 0) { (if (idx < 95) { Mem.load!(mem1, yoff_table, idx, 1) } else { (mem1, 0) }) } else { (mem1, 0) })
			(mem3, _dummy) = gbf_put_char!(mem2, gb, base, gw, gh, (x + cx), (y + yoff), max_x, code, fg)
			gbf_put_text_loop!(mem3, gb, base, gw, gh, adv_table, yoff_table, x, y, max_x, s, fg, (i + 1), n, (cx + adv))
		}) })
	}) }) })

	font_role_serif : I64
	font_role_serif = 1

	font_role_sans : I64
	font_role_sans = 2

	font_role_mono : I64
	font_role_mono = 3

	gop_buf_put_text_role! : Mem.Mem, PixelBuf.GopBuf, GuiTimer.MutWheel, I64, I64, Str, I64, I64 => (Mem.Mem, I64)
	gop_buf_put_text_role! = |mem, gb, w, x, y, s, fg, role| gop_buf_put_text_role_clip!(mem, gb, w, x, y, gb.gb_width, s, fg, role)

	gop_buf_put_text_role_clip! : Mem.Mem, PixelBuf.GopBuf, GuiTimer.MutWheel, I64, I64, I64, Str, I64, I64 => (Mem.Mem, I64)
	gop_buf_put_text_role_clip! = |mem, gb, w, x, y, max_x, s, fg, role| ({
		(mem1, mem__572) = GuiTimer.mw_get_fonts_loaded!(mem, w)
		(if (mem__572 == 0) { gop_buf_put_text_clip!(mem1, gb, x, y, max_x, s, fg) } else { gop_buf_put_text_role_loaded!(mem1, gb, w, x, y, max_x, s, fg, role) })
	})

	gop_buf_put_text_role_loaded! : Mem.Mem, PixelBuf.GopBuf, GuiTimer.MutWheel, I64, I64, I64, Str, I64, I64 => (Mem.Mem, I64)
	gop_buf_put_text_role_loaded! = |mem, gb, w, x, y, max_x, s, fg, role| ({
		(mem1, base) = (if (role == 1) { GuiTimer.mw_get_font_serif_base!(mem, w) } else { (if (role == 2) { GuiTimer.mw_get_font_sans_base!(mem, w) } else { GuiTimer.mw_get_font_mono_base!(mem, w) }) })
		(mem2, gw) = (if (role == 1) { GuiTimer.mw_get_font_serif_w!(mem1, w) } else { (if (role == 2) { GuiTimer.mw_get_font_sans_w!(mem1, w) } else { GuiTimer.mw_get_font_mono_w!(mem1, w) }) })
		(mem3, gh) = GuiTimer.mw_get_font_glyph_h!(mem2, w)
		(if (base == 0) { gop_buf_put_text_clip!(mem3, gb, x, y, max_x, s, fg) } else { gbf_put_text_clip!(mem3, gb, base, gw, gh, x, y, max_x, s, fg) })
	})

	gop_role_text_width! : Mem.Mem, GuiTimer.MutWheel, I64, Str => (Mem.Mem, I64)
	gop_role_text_width! = |mem, w, role, s| ({
		(mem1, mem__573) = GuiTimer.mw_get_fonts_loaded!(mem, w)
		(if (mem__573 == 0) { (mem1, (Cce.length(s) * 9)) } else { ({
		(mem2, base) = (if (role == 1) { GuiTimer.mw_get_font_serif_base!(mem1, w) } else { (if (role == 2) { GuiTimer.mw_get_font_sans_base!(mem1, w) } else { GuiTimer.mw_get_font_mono_base!(mem1, w) }) })
		(mem3, gw) = (if (role == 1) { GuiTimer.mw_get_font_serif_w!(mem2, w) } else { (if (role == 2) { GuiTimer.mw_get_font_sans_w!(mem2, w) } else { GuiTimer.mw_get_font_mono_w!(mem2, w) }) })
		(mem4, gh) = GuiTimer.mw_get_font_glyph_h!(mem3, w)
		(if (base == 0) { (mem4, (Cce.length(s) * 9)) } else { gbf_measure_text!(mem4, base, gw, gh, s) })
	}) })
	})

	gbf_measure_text! : Mem.Mem, I64, I64, I64, Str => (Mem.Mem, I64)
	gbf_measure_text! = |mem, base, gw, gh, s| ({
		adv_table = (base + ((95 * gw) * gh))
		gbf_measure_loop!(mem, adv_table, gw, s, 0, Cce.length(s), 0)
	})

	gbf_measure_loop! : Mem.Mem, I64, I64, Str, I64, I64, I64 => (Mem.Mem, I64)
	gbf_measure_loop! = |mem, adv_table, gw, s, i, n, cx| (if (i >= n) { (mem, cx) } else { ({
		unicode = CCE.to_unicode(Cce.at(s, i))
		idx = (unicode - 32)
		(mem1, adv) = (if (idx >= 0) { (if (idx < 95) { Mem.load!(mem, adv_table, idx, 1) } else { (mem, gw) }) } else { (mem, gw) })
		gbf_measure_loop!(mem1, adv_table, gw, s, (i + 1), n, (cx + adv))
	}) })

	gop_buf_present! : Mem.Mem, GuiDisplay.GopDisplay, PixelBuf.GopBuf => (Mem.Mem, I64)
	gop_buf_present! = |mem, gd, gb| gop_buf_present_rows!(mem, gd, gb, 0)

	gop_buf_present_rows! : Mem.Mem, GuiDisplay.GopDisplay, PixelBuf.GopBuf, I64 => (Mem.Mem, I64)
	gop_buf_present_rows! = |mem, gd, gb, y| (if (y >= gb.gb_height) { (mem, 0) } else { ({
		(mem1, _dummy) = gop_buf_present_row!(mem, gd, gb, y, 0)
		gop_buf_present_rows!(mem1, gd, gb, (y + 1))
	}) })

	gop_buf_present_row! : Mem.Mem, GuiDisplay.GopDisplay, PixelBuf.GopBuf, I64, I64 => (Mem.Mem, I64)
	gop_buf_present_row! = |mem, gd, gb, y, x| (if (x >= gb.gb_width) { (mem, 0) } else { ({
		(mem1, color) = Mem.load!(mem, gb.gb_base, (((y * gb.gb_width) + x) * 4), 4)
		offset = (((y * gd.gd_stride) + x) * 4)
		(mem2, _dummy) = Mem.store!(mem1, gd.gd_fb_addr, offset, color, 4)
		gop_buf_present_row!(mem2, gd, gb, y, (x + 1))
	}) })

	gop_cursor_save_new! : Mem.Mem, I64 => (Mem.Mem, GuiDisplay.CursorSave)
	gop_cursor_save_new! = |mem, pixels| ({
		(mem1, mem__574) = Mem.alloc(mem, (pixels * 4))
		(mem1, { cs_base: mem__574, cs_size: pixels })
	})

	gop_cursor_save! : Mem.Mem, PixelBuf.GopBuf, GuiDisplay.CursorSave, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_cursor_save! = |mem, gb, cs, x, y, w, h| gop_cursor_save_loop!(mem, gb, cs, x, y, w, h, 0)

	gop_cursor_save_loop! : Mem.Mem, PixelBuf.GopBuf, GuiDisplay.CursorSave, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_cursor_save_loop! = |mem, gb, cs, x, y, w, h, i| (if (i >= (w * h)) { (mem, 0) } else { ({
		cx = (x + Prelude.int_mod(i, w))
		cy = (y + I64.div_trunc_by(i, w))
		(mem1, pixel) = PixelBuf.gop_buf_get!(mem, gb, cx, cy)
		(mem2, _dummy) = Mem.store!(mem1, cs.cs_base, (i * 4), pixel, 4)
		gop_cursor_save_loop!(mem2, gb, cs, x, y, w, h, (i + 1))
	}) })

	gop_cursor_restore! : Mem.Mem, PixelBuf.GopBuf, GuiDisplay.CursorSave, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_cursor_restore! = |mem, gb, cs, x, y, w, h| gop_cursor_restore_loop!(mem, gb, cs, x, y, w, h, 0)

	gop_cursor_restore_loop! : Mem.Mem, PixelBuf.GopBuf, GuiDisplay.CursorSave, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
	gop_cursor_restore_loop! = |mem, gb, cs, x, y, w, h, i| (if (i >= (w * h)) { (mem, 0) } else { ({
		cx = (x + Prelude.int_mod(i, w))
		cy = (y + I64.div_trunc_by(i, w))
		(mem1, pixel) = Mem.load!(mem, cs.cs_base, (i * 4), 4)
		(mem2, _dummy) = PixelBuf.gop_buf_set!(mem1, gb, cx, cy, pixel)
		gop_cursor_restore_loop!(mem2, gb, cs, x, y, w, h, (i + 1))
	}) })

	gop_draw_arrow_cursor! : Mem.Mem, PixelBuf.GopBuf, I64, I64, I64 => (Mem.Mem, I64)
	gop_draw_arrow_cursor! = |mem, gb, mx, my, color| ({
		(mem1, _dummy) = PixelBuf.gop_buf_set!(mem, gb, mx, my, color)
		(mem2, _dummy2) = PixelBuf.gop_buf_set!(mem1, gb, mx, (my + 1), color)
		(mem3, _dummy3) = PixelBuf.gop_buf_set!(mem2, gb, mx, (my + 2), color)
		(mem4, _dummy4) = PixelBuf.gop_buf_set!(mem3, gb, mx, (my + 3), color)
		(mem5, _dummy5) = PixelBuf.gop_buf_set!(mem4, gb, mx, (my + 4), color)
		(mem6, _dummy6) = PixelBuf.gop_buf_set!(mem5, gb, mx, (my + 5), color)
		(mem7, _dummy7) = PixelBuf.gop_buf_set!(mem6, gb, mx, (my + 6), color)
		(mem8, _dummy8) = PixelBuf.gop_buf_set!(mem7, gb, mx, (my + 7), color)
		(mem9, _dummy9) = PixelBuf.gop_buf_set!(mem8, gb, (mx + 1), my, color)
		(mem10, _dummy10) = PixelBuf.gop_buf_set!(mem9, gb, (mx + 1), (my + 1), color)
		(mem11, _dummy11) = PixelBuf.gop_buf_set!(mem10, gb, (mx + 1), (my + 2), color)
		(mem12, _dummy12) = PixelBuf.gop_buf_set!(mem11, gb, (mx + 1), (my + 3), color)
		(mem13, _dummy13) = PixelBuf.gop_buf_set!(mem12, gb, (mx + 1), (my + 4), color)
		(mem14, _dummy14) = PixelBuf.gop_buf_set!(mem13, gb, (mx + 2), my, color)
		(mem15, _dummy15) = PixelBuf.gop_buf_set!(mem14, gb, (mx + 2), (my + 1), color)
		(mem16, _dummy16) = PixelBuf.gop_buf_set!(mem15, gb, (mx + 2), (my + 2), color)
		(mem17, _dummy17) = PixelBuf.gop_buf_set!(mem16, gb, (mx + 2), (my + 3), color)
		(mem18, _dummy18) = PixelBuf.gop_buf_set!(mem17, gb, (mx + 3), my, color)
		(mem19, _dummy19) = PixelBuf.gop_buf_set!(mem18, gb, (mx + 3), (my + 1), color)
		(mem20, _dummy20) = PixelBuf.gop_buf_set!(mem19, gb, (mx + 3), (my + 2), color)
		(mem21, _dummy21) = PixelBuf.gop_buf_set!(mem20, gb, (mx + 4), my, color)
		(mem22, _dummy22) = PixelBuf.gop_buf_set!(mem21, gb, (mx + 4), (my + 1), color)
		(mem23, _dummy23) = PixelBuf.gop_buf_set!(mem22, gb, (mx + 5), (my + 4), color)
		(mem24, _dummy24) = PixelBuf.gop_buf_set!(mem23, gb, (mx + 4), (my + 5), color)
		PixelBuf.gop_buf_set!(mem24, gb, (mx + 3), (my + 6), color)
	})
}
