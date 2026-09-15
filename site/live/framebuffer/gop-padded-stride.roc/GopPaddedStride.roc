app [main!] { pf: platform "../../../../../../showell_repos/roc-apps/framebuffer/platform/main.roc" }

import pf.Echo

echo! = |msg| Echo.line!(msg)

# GopPaddedStride -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Color
import Mem
import Renderer3D

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

sentinel : I64
sentinel = 12648430

probe : I64
probe = 16711935

sky : I64
sky = Color.rgb_to_packed(Color.rgb(20, 20, 30))

fill_fb! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
fill_fb! = |mem, base, i, n| (if (i >= n) { (mem, 0) } else { ({
	(mem1, _d) = Mem.store!(mem, base, (i * 4), sentinel, 4)
	fill_fb!(mem1, base, (i + 1), n)
}) })

pad_cols! : Mem.Mem, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
pad_cols! = |mem, base, stride, y, x, acc| (if (x >= stride) { (mem, acc) } else { ({
	(mem1, mem__21) = Mem.load!(mem, base, (((y * stride) + x) * 4), 4)
	(if (mem__21 == sentinel) { pad_cols!(mem1, base, stride, y, (x + 1), (acc + 1)) } else { pad_cols!(mem1, base, stride, y, (x + 1), acc) })
}) })

pad_rows! : Mem.Mem, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
pad_rows! = |mem, base, stride, w, h, y, acc| (if (y >= h) { (mem, acc) } else { ({
	(mem1, mem__22) = pad_cols!(mem, base, stride, y, w, acc)
	pad_rows!(mem1, base, stride, w, h, (y + 1), mem__22)
}) })

row_painted! : Mem.Mem, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
row_painted! = |mem, base, stride, w, y, x| (if (x >= w) { (mem, 0) } else { ({
	(mem1, mem__23) = Mem.load!(mem, base, (((y * stride) + x) * 4), 4)
	(if (mem__23 == sentinel) { row_painted!(mem1, base, stride, w, y, (x + 1)) } else { (mem1, 1) })
}) })

yn : Bool -> Str
yn = |b| (if b { "yes" } else { "no" })

# --- Entry ---

main! = |args| {
	mem = Mem.new(U64.to_i64_wrap(List.len(args)))
	(_mem10, mem__24) = ({
		(mem1, w) = Mem.load!(mem, cell_width, 0, 4)
		(mem2, h) = Mem.load!(mem1, cell_height, 0, 4)
		(mem3, stride) = Mem.load!(mem2, cell_stride, 0, 4)
		pad = ((stride - w) * h)
		(mem4, _f) = fill_fb!(mem3, fb_base, 0, (stride * h))
		(mem5, tgt) = Renderer3D.r3d_target_at!(mem4, fb_base, stride, w, h, sky)
		(mem6, _plotted) = Renderer3D.r3d_plot!(mem5, tgt, (w - 1), (h - 1), 1, probe)
		(mem7, corner) = Mem.load!(mem6, fb_base, (((((h - 1) * stride) + w) - 1) * 4), 4)
		(mem8, pad_kept) = pad_rows!(mem7, fb_base, stride, w, h, 0, 0)
		(mem9, bottom) = row_painted!(mem8, fb_base, stride, w, (h - 1), 0)
		({
			_ = line!(Str.concat("stride exceeds width   : ", yn((stride > w))))
			_ = line!(Str.concat("invisible pad untouched: ", yn((pad_kept == pad))))
			_ = line!(Str.concat("bottom row painted     : ", yn((bottom == 1))))
			(mem9, line!(Str.concat("plot lands at stride   : ", yn((corner == probe)))))
		})
	})
	mem__24
	Ok({})
}
