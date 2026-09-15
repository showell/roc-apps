app [main!] { pf: platform "../../../../../showell_repos/roc-apps/machine/batch/platform/main.roc" }

import pf.Echo

echo! = |msg| Echo.line!(msg)

# GpuGaugeClamp -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import BoxModel
import GpuRender
import Machine
import Theme
import Widget

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

fb_base : I64
fb_base = 3204448256

fb_w : I64
fb_w = 640

fb_h : I64
fb_h = 480

scan_row_band! : Machine.Machine, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
scan_row_band! = |machine, y, x, xend, target, acc| (if (x >= xend) { (machine, acc) } else { ({
	(machine1, machine__43) = Machine.load!(machine, fb_base, (((y * fb_w) + x) * 4), 4)
	scan_row_band!(machine1, y, (x + 4), xend, target, (acc + (if (machine__43 == target) { 1 } else { 0 })))
}) })

scan_band! : Machine.Machine, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
scan_band! = |machine, y, x0, x1, target, acc| (if (y >= fb_h) { (machine, acc) } else { ({
	(machine1, machine__44) = scan_row_band!(machine, y, x0, x1, target, 0)
	scan_band!(machine1, (y + 1), x0, x1, target, (acc + machine__44))
}) })

probe_tree : Widget.WidgetNode
probe_tree = Widget.widget_panel("root", DirRow, 0, [Widget.widget_set_flex(Widget.widget_set_min(Widget.widget_gauge("over", 150, 100), 200, 40), 0), Widget.widget_set_flex(Widget.widget_label("pad", ""), 1)])

# --- Entry ---

main! = |args| {
	machine = Machine.boot!(args, ["Gpu", "Console"])
	(machine7, machine__48) = ({
		th = Theme.theme_terminal
		pal = th.th_palette
		laid = Widget.widget_layout(probe_tree, th, BoxModel.layout_rect(0, 0, fb_w, fb_h))
		g = (List.get(laid.wn_children, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
		b = g.wn_bounds
		gright = (b.lr_x + b.lr_w)
		({
			(machine1, _c1) = GpuRender.gr_clear!(machine, pal.pal_bg)
			(machine2, _c2) = GpuRender.gr_clear_depth!(machine1)
			(machine4, _n) = ({
				(machine3, machine__45) = GpuRender.gr_render_tree!(machine2, GpuRender.gf_new(4096), laid, th, GpuRender.gr_depth_scene)
				GpuRender.gr_flush!(machine3, machine__45.gf_idx)
			})
			(machine5, machine__46) = scan_band!(machine4, 0, b.lr_x, gright, pal.pal_primary, 0)
			_ = line!(Str.concat("inside: ", I64.to_str((if (machine__46 > 0) { 1 } else { 0 }))))
			({
				(machine6, machine__47) = scan_band!(machine5, 0, (gright + 4), (fb_w - 8), pal.pal_primary, 0)
				(machine6, line!(Str.concat("outside: ", I64.to_str((if (machine__47 > 0) { 1 } else { 0 })))))
			})
		})
	})
	machine__48
	Machine.halt!(machine7)
	Ok({})
}
