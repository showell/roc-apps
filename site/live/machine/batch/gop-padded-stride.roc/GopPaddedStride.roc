app [main!] { pf: platform "../../../../../showell_repos/roc-apps/machine/batch/platform/main.roc" }

import pf.Echo

echo! = |msg| Echo.line!(msg)

# GopPaddedStride -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Color
import Machine
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

fill_fb! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
fill_fb! = |machine, base, i, n| (if (i >= n) { (machine, 0) } else { ({
	(machine1, _d) = Machine.store!(machine, base, (i * 4), sentinel, 4)
	fill_fb!(machine1, base, (i + 1), n)
}) })

pad_cols! : Machine.Machine, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
pad_cols! = |machine, base, stride, y, x, acc| (if (x >= stride) { (machine, acc) } else { ({
	(machine1, machine__21) = Machine.load!(machine, base, (((y * stride) + x) * 4), 4)
	(if (machine__21 == sentinel) { pad_cols!(machine1, base, stride, y, (x + 1), (acc + 1)) } else { pad_cols!(machine1, base, stride, y, (x + 1), acc) })
}) })

pad_rows! : Machine.Machine, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
pad_rows! = |machine, base, stride, w, h, y, acc| (if (y >= h) { (machine, acc) } else { ({
	(machine1, machine__22) = pad_cols!(machine, base, stride, y, w, acc)
	pad_rows!(machine1, base, stride, w, h, (y + 1), machine__22)
}) })

row_painted! : Machine.Machine, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
row_painted! = |machine, base, stride, w, y, x| (if (x >= w) { (machine, 0) } else { ({
	(machine1, machine__23) = Machine.load!(machine, base, (((y * stride) + x) * 4), 4)
	(if (machine__23 == sentinel) { row_painted!(machine1, base, stride, w, y, (x + 1)) } else { (machine1, 1) })
}) })

yn : Bool -> Str
yn = |b| (if b { "yes" } else { "no" })

# --- Entry ---

main! = |args| {
	machine = Machine.boot!(args, ["Console"])
	(machine10, machine__24) = ({
		(machine1, w) = Machine.load!(machine, cell_width, 0, 4)
		(machine2, h) = Machine.load!(machine1, cell_height, 0, 4)
		(machine3, stride) = Machine.load!(machine2, cell_stride, 0, 4)
		pad = ((stride - w) * h)
		(machine4, _f) = fill_fb!(machine3, fb_base, 0, (stride * h))
		(machine5, tgt) = Renderer3D.r3d_target_at!(machine4, fb_base, stride, w, h, sky)
		(machine6, _plotted) = Renderer3D.r3d_plot!(machine5, tgt, (w - 1), (h - 1), 1, probe)
		(machine7, corner) = Machine.load!(machine6, fb_base, (((((h - 1) * stride) + w) - 1) * 4), 4)
		(machine8, pad_kept) = pad_rows!(machine7, fb_base, stride, w, h, 0, 0)
		(machine9, bottom) = row_painted!(machine8, fb_base, stride, w, (h - 1), 0)
		({
			_ = line!(Str.concat("stride exceeds width   : ", yn((stride > w))))
			_ = line!(Str.concat("invisible pad untouched: ", yn((pad_kept == pad))))
			_ = line!(Str.concat("bottom row painted     : ", yn((bottom == 1))))
			(machine9, line!(Str.concat("plot lands at stride   : ", yn((corner == probe)))))
		})
	})
	machine__24
	Machine.halt!(machine10)
	Ok({})
}
