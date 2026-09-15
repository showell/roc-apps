app [main!] { pf: platform "../../../../../../showell_repos/roc-apps/framebuffer/platform/main.roc" }

import pf.Echo

echo! = |msg| Echo.line!(msg)

# QrOnScreen -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import GopDraw
import GopQr
import Mem

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

light : I64
light = 16052712

dark : I64
dark = 1907995

payload : Str
payload = "KBDDIAG v8 qr telemetry test 0123456789 the quick brown fox"

draw_cols! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
draw_cols! = |mem, m, stride, h, x0, y0, module_px, r, c| (if (c >= GopQr.qr_size) { (mem, 0) } else { ({
	(mem2, _d) = ({
		(mem1, mem__51) = Mem.load!(mem, m, GopQr.qr_at(r, c), 1)
		(if (mem__51 == 0) { (mem1, 0) } else { GopDraw.gop_fill_rect!(mem1, fb_base, stride, h, (x0 + (c * module_px)), (y0 + (r * module_px)), module_px, module_px, dark) })
	})
	draw_cols!(mem2, m, stride, h, x0, y0, module_px, r, (c + 1))
}) })

draw_rows! : Mem.Mem, I64, I64, I64, I64, I64, I64, I64 => (Mem.Mem, I64)
draw_rows! = |mem, m, stride, h, x0, y0, module_px, r| (if (r >= GopQr.qr_size) { (mem, 0) } else { ({
	(mem1, _d) = draw_cols!(mem, m, stride, h, x0, y0, module_px, r, 0)
	draw_rows!(mem1, m, stride, h, x0, y0, module_px, (r + 1))
}) })

# --- Entry ---

main! = |args| {
	mem = Mem.new(U64.to_i64_wrap(List.len(args)))
	(_mem7, mem__52) = ({
		(mem1, w) = Mem.load!(mem, cell_width, 0, 4)
		(mem2, h) = Mem.load!(mem1, cell_height, 0, 4)
		(mem3, stride) = Mem.load!(mem2, cell_stride, 0, 4)
		side = (if (w < h) { w } else { h })
		module_px = I64.div_trunc_by(side, (GopQr.qr_size + 8))
		x0 = I64.div_trunc_by((w - (module_px * GopQr.qr_size)), 2)
		y0 = I64.div_trunc_by((h - (module_px * GopQr.qr_size)), 2)
		(mem4, _bg) = GopDraw.gop_fill_rect!(mem3, fb_base, stride, h, 0, 0, w, h, light)
		(mem5, m) = GopQr.qr5_encode!(mem4, payload)
		(mem6, _d) = draw_rows!(mem5, m, stride, h, x0, y0, module_px, 0)
		({
			(mem6, line!(Str.concat(Str.concat(Str.concat(Str.concat("qr : ", I64.to_str(GopQr.qr_size)), " modules, "), I64.to_str(module_px)), " pixels each")))
		})
	})
	mem__52
	Ok({})
}
