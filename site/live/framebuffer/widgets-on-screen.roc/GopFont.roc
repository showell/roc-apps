# GopFont -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Fat16
import GuiDisplay
import Mem

GopFont :: [].{
	GopFont : { gf_ok : Bool, gf_base : I64, gf_gw : I64, gf_gh : I64, gf_asc : I64, gf_cap : I64 }

	gfont_none : GopFont.GopFont
	gfont_none = { gf_ok: False, gf_base: 0, gf_gw: 0, gf_gh: 0, gf_asc: 0, gf_cap: 0 }

	gfont_load! : Mem.Mem, Fat16.Fat16Volume, Str, I64 => (Mem.Mem, GopFont.GopFont)
	gfont_load! = |_, _, _, _| crash("`gfont-load` reaches `port-out-32`, a device builtin this program's opening never calls, and the program runs without the machine")

	gfont_text! : Mem.Mem, GopFont.GopFont, I64, I64, I64, I64, I64, Str, I64 => (Mem.Mem, I64)
	gfont_text! = |mem, f, base, stride, h, x, y, s, fg| GuiDisplay.gbf_put_text!(mem, { gb_base: base, gb_width: stride, gb_height: h }, f.gf_base, f.gf_gw, f.gf_gh, x, y, s, fg)

	gfont_text_clip! : Mem.Mem, GopFont.GopFont, I64, I64, I64, I64, I64, I64, Str, I64 => (Mem.Mem, I64)
	gfont_text_clip! = |mem, f, base, stride, h, max_x, x, y, s, fg| GuiDisplay.gbf_put_text_clip!(mem, { gb_base: base, gb_width: stride, gb_height: h }, f.gf_base, f.gf_gw, f.gf_gh, x, y, max_x, s, fg)

	gfont_text_w! : Mem.Mem, GopFont.GopFont, Str => (Mem.Mem, I64)
	gfont_text_w! = |mem, f, s| (if (f.gf_ok == False) { (mem, 0) } else { GuiDisplay.gbf_measure_text!(mem, f.gf_base, f.gf_gw, f.gf_gh, s) })
}
