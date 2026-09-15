app [main!] { pf: platform "../../../../../../showell_repos/roc-apps/framebuffer/platform/main.roc" }

import pf.Echo

echo! = |msg| Echo.line!(msg)

# GlyphsOnScreen -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import GlyphRasterizer
import GopDraw
import Mem
import TrueType

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

fb_base : I64
fb_base = 3204448256

cell_width : I64
cell_width = 1988

cell_height : I64
cell_height = 1992

cell_stride : I64
cell_stride = 2016

paper : I64
paper = 1777450

chalk : I64
chalk = 16052712

test_font_bytes : List(I64)
test_font_bytes = [0, 1, 0, 0, 0, 7, 0, 64, 0, 2, 0, 48, 99, 109, 97, 112, 0, 0, 0, 0, 0, 0, 0, 124, 0, 0, 0, 52, 103, 108, 121, 102, 0, 0, 0, 0, 0, 0, 0, 176, 0, 0, 0, 52, 104, 101, 97, 100, 0, 0, 0, 0, 0, 0, 0, 228, 0, 0, 0, 54, 104, 104, 101, 97, 0, 0, 0, 0, 0, 0, 1, 28, 0, 0, 0, 36, 104, 109, 116, 120, 0, 0, 0, 0, 0, 0, 1, 64, 0, 0, 0, 12, 108, 111, 99, 97, 0, 0, 0, 0, 0, 0, 1, 76, 0, 0, 0, 16, 109, 97, 120, 112, 0, 0, 0, 0, 0, 0, 1, 92, 0, 0, 0, 6, 0, 0, 0, 1, 0, 3, 0, 1, 0, 0, 0, 12, 0, 4, 0, 40, 0, 0, 0, 6, 0, 4, 0, 1, 0, 2, 0, 32, 0, 65, 255, 255, 0, 0, 0, 32, 0, 65, 255, 255, 255, 225, 255, 193, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 2, 0, 2, 188, 0, 2, 0, 0, 1, 1, 1, 0, 0, 1, 0, 1, 0, 0, 0, 2, 188, 253, 68, 0, 0, 0, 0, 1, 0, 0, 0, 0, 80, 0, 0, 0, 0, 0, 95, 15, 60, 245, 0, 11, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 2, 188, 0, 0, 0, 8, 0, 2, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 2, 188, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 2, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 2, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 20, 0, 0, 0, 52, 0, 1, 0, 0, 0, 3, 0, 0]

zoom : I64
zoom = 3

put_glyph_row! : Mem.Mem, List(I64), I64, I64, I64, I64, I64, Bool, I64, I64 => (Mem.Mem, I64)
put_glyph_row! = |mem, px, gw, stride, rows, x0, y0, aa, y, x| (if (x >= gw) { (mem, 0) } else { ({
	v = (List.get(px, I64.to_u64_wrap(((y * gw) + x))) ?? crash("list-at out of range"))
	grey = ((if (v > 255) { 255 } else { v }) * 65793)
	(mem1, _d) = (if (v <= 0) { (mem, 0) } else { GopDraw.gop_fill_rect!(mem, fb_base, stride, rows, (x0 + (x * zoom)), (y0 + (y * zoom)), zoom, zoom, (if aa { grey } else { chalk })) })
	put_glyph_row!(mem1, px, gw, stride, rows, x0, y0, aa, y, (x + 1))
}) })

put_glyph_rows! : Mem.Mem, List(I64), I64, I64, I64, I64, I64, I64, Bool, I64 => (Mem.Mem, I64)
put_glyph_rows! = |mem, px, gw, gh, stride, rows, x0, y0, aa, y| (if (y >= gh) { (mem, 0) } else { ({
	(mem1, _d) = put_glyph_row!(mem, px, gw, stride, rows, x0, y0, aa, y, 0)
	put_glyph_rows!(mem1, px, gw, gh, stride, rows, x0, y0, aa, (y + 1))
}) })

put_glyph! : Mem.Mem, GlyphRasterizer.RasterGlyph, I64, I64, I64, I64, Bool => (Mem.Mem, I64)
put_glyph! = |mem, rg, stride, rows, x0, y0, aa| put_glyph_rows!(mem, rg.rg_pixels, rg.rg_width, rg.rg_height, stride, rows, x0, y0, aa, 0)

size_text : GlyphRasterizer.RasterGlyph -> Str
size_text = |rg| Str.concat(Str.concat(I64.to_str(rg.rg_width), " x "), I64.to_str(rg.rg_height))

# --- Entry ---

main! = |args| {
	mem = Mem.new(U64.to_i64_wrap(List.len(args)))
	(_mem11, mem__26) = ({
		(mem1, w) = Mem.load!(mem, cell_width, 0, 4)
		(mem2, h) = Mem.load!(mem1, cell_height, 0, 4)
		(mem3, stride) = Mem.load!(mem2, cell_stride, 0, 4)
		(mem4, _bg) = GopDraw.gop_fill_rect!(mem3, fb_base, stride, h, 0, 0, w, h, paper)
		font = TrueType.ttf_parse(test_font_bytes)
		p16 = GlyphRasterizer.gr_render_glyph(font, 65, 16)
		p24 = GlyphRasterizer.gr_render_glyph(font, 65, 24)
		p32 = GlyphRasterizer.gr_render_glyph(font, 65, 32)
		a16 = GlyphRasterizer.gr_render_glyph_aa(font, 65, 16)
		a24 = GlyphRasterizer.gr_render_glyph_aa(font, 65, 24)
		a32 = GlyphRasterizer.gr_render_glyph_aa(font, 65, 32)
		(mem5, _d1) = put_glyph!(mem4, p16, stride, h, 10, 10, False)
		(mem6, _d2) = put_glyph!(mem5, p24, stride, h, 70, 10, False)
		(mem7, _d3) = put_glyph!(mem6, p32, stride, h, 156, 10, False)
		(mem8, _d4) = put_glyph!(mem7, a16, stride, h, 10, 125, True)
		(mem9, _d5) = put_glyph!(mem8, a24, stride, h, 70, 125, True)
		(mem10, _d6) = put_glyph!(mem9, a32, stride, h, 156, 125, True)
		({
			_ = line!(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat("plain       : ", size_text(p16)), ", "), size_text(p24)), ", "), size_text(p32)))
			(mem10, line!(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat("anti-aliased: ", size_text(a16)), ", "), size_text(a24)), ", "), size_text(a32))))
		})
	})
	mem__26
	Ok({})
}
