app [main!] { pf: platform "../../../../../../showell_repos/roc-apps/framebuffer/platform/main.roc" }

import pf.Echo

echo! = |msg| Echo.line!(msg)

# GpuDepthTree -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import BoxModel
import CceText
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

scan_row! : Machine.Machine, I64, I64, I64, I64 => (Machine.Machine, I64)
scan_row! = |machine, y, x, target, acc| (if (x >= fb_w) { (machine, acc) } else { ({
	(machine1, machine__1) = Machine.load!(machine, fb_base, (((y * fb_w) + x) * 4), 4)
	scan_row!(machine1, y, (x + 8), target, (acc + (if (machine__1 == target) { 1 } else { 0 })))
}) })

scan_fb! : Machine.Machine, I64, I64, I64 => (Machine.Machine, I64)
scan_fb! = |machine, y, target, acc| (if (y >= fb_h) { (machine, acc) } else { ({
	(machine1, machine__1) = scan_row!(machine, y, 0, target, 0)
	scan_fb!(machine1, (y + 1), target, (acc + machine__1))
}) })

probe_tree : Widget.WidgetNode
probe_tree = Widget.widget_panel("root", DirColumn, 4, [Widget.widget_separator("sep"), Widget.widget_set_min(Widget.widget_gauge("bar", 1, 4), 0, 40)])

# --- Entry ---

main! = |args| {
	machine = Machine.boot!(args, ["Gpu", "Console"])
	(machine12, machine__5) = ({
		th = Theme.theme_terminal
		pal = th.th_palette
		laid = Widget.widget_layout(probe_tree, th, BoxModel.layout_rect(0, 0, fb_w, fb_h))
		({
			(machine1, _c1) = GpuRender.gr_clear!(machine, pal.pal_bg)
			(machine2, _c2) = GpuRender.gr_clear_depth!(machine1)
			(machine4, _n) = ({
				(machine3, machine__1) = GpuRender.gr_render_tree!(machine2, GpuRender.gf_new(4096), laid, th, GpuRender.gr_depth_scene)
				GpuRender.gr_flush!(machine3, machine__1.gf_idx)
			})
			(machine5, machine__2) = scan_fb!(machine4, 0, pal.pal_border, 0)
			_ = line!(CceText.printed(CceText.concat("separator: ", CceText.show_int((if (machine__2 > 0) { 1 } else { 0 })))))
			(machine6, machine__3) = scan_fb!(machine5, 0, pal.pal_primary, 0)
			_ = line!(CceText.printed(CceText.concat("gauge-fill: ", CceText.show_int((if (machine__3 > 0) { 1 } else { 0 })))))
			({
				bare = Widget.widget_layout(Widget.widget_stack("bare", DirColumn, 0, [Widget.widget_fixed(Widget.widget_button("child", "OK"), 40, 24)]), th, BoxModel.layout_rect(0, 0, fb_w, fb_h))
				({
					(machine7, _clear) = GpuRender.gr_clear!(machine6, 1193046)
					(machine8, _depth) = GpuRender.gr_clear_depth!(machine7)
					(machine9, frame) = GpuRender.gr_render_tree!(machine8, GpuRender.gf_new(4096), bare, th, GpuRender.gr_depth_scene)
					(machine10, _sent) = GpuRender.gr_flush!(machine9, frame.gf_idx)
					_ = line!(CceText.printed(CceText.concat("stack children emit: ", CceText.show_int((if (frame.gf_idx > 0) { 1 } else { 0 })))))
					({
						(machine11, machine__4) = Machine.load!(machine10, fb_base, (((400 * fb_w) + 320) * 4), 4)
						(machine11, line!(CceText.printed(CceText.concat("stack leaves unused surface clear: ", CceText.show_int((if (machine__4 == 1193046) { 1 } else { 0 }))))))
					})
				})
			})
		})
	})
	machine__5
	Machine.halt!(machine12)
	Ok({})
}
