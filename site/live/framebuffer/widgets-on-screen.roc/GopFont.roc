# GopFont -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import BitmapFont
import CceText
import GuiDisplay
import Mem
import PixelBuf

GopFont :: [].{
	GopAppFont := { af_ui : GopFont.GopFont, af_code : GopFont.GopFont, af_bitmap : BitmapFont.CbfFont }.{
		is_eq : GopFont.GopAppFont, GopFont.GopAppFont -> Bool
		is_eq = |a, b| eq_GopAppFont(a, b)
	}
	GopFont := { gf_ok : Bool, gf_base : I64, gf_gw : I64, gf_gh : I64, gf_asc : I64, gf_cap : I64 }.{
		is_eq : GopFont.GopFont, GopFont.GopFont -> Bool
		is_eq = |a, b| eq_GopFont(a, b)
	}

	gfont_none : GopFont.GopFont
	gfont_none = GopFont.GopFont.{ gf_ok: False, gf_base: 0, gf_gw: 0, gf_gh: 0, gf_asc: 0, gf_cap: 0 }

	gfont_text_clip! : Mem.Mem, GopFont.GopFont, I64, I64, I64, I64, I64, I64, CceText, I64 => (Mem.Mem, I64)
	gfont_text_clip! = |mem, f, base, stride, h, max_x, x, y, s, fg| GuiDisplay.gbf_put_text_clip!(mem, PixelBuf.GopBuf.{ gb_base: base, gb_width: stride, gb_height: h }, f.gf_base, f.gf_gw, f.gf_gh, x, y, max_x, s, fg)

	gfont_text_w! : Mem.Mem, GopFont.GopFont, CceText => (Mem.Mem, I64)
	gfont_text_w! = |mem, f, s| (if (f.gf_ok == False) { (mem, 0) } else { GuiDisplay.gbf_measure_text!(mem, f.gf_base, f.gf_gw, f.gf_gh, s) })

	eq_GopAppFont : GopFont.GopAppFont, GopFont.GopAppFont -> Bool
	eq_GopAppFont = |ex, ey| ((eq_GopFont(ex.af_ui, ey.af_ui) and eq_GopFont(ex.af_code, ey.af_code)) and BitmapFont.eq_CbfFont(ex.af_bitmap, ey.af_bitmap))

	eq_GopFont : GopFont.GopFont, GopFont.GopFont -> Bool
	eq_GopFont = |ex, ey| ((((((ex.gf_ok == ey.gf_ok) and (ex.gf_base == ey.gf_base)) and (ex.gf_gw == ey.gf_gw)) and (ex.gf_gh == ey.gf_gh)) and (ex.gf_asc == ey.gf_asc)) and (ex.gf_cap == ey.gf_cap))
}
