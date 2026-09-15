app [main!] { pf: platform "../../../../../../showell_repos/roc-apps/framebuffer/platform/main.roc" }

import pf.Echo

echo! = |msg| Echo.line!(msg)

# WidgetsOnScreen -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import BitmapFont
import GopComposite
import GopDraw
import GopFont
import Mem
import Theme
import Widget

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

cell_clock : I64
cell_clock = 2032

gauge_steps : I64
gauge_steps = 40

demo_tree : I64 -> Widget.WidgetNode
demo_tree = |step| Widget.widget_panel("root", DirColumn, 8, [Widget.widget_label("title", "Cobblestone widgets, drawn by GopComposite"), Widget.widget_separator("sep"), Widget.widget_input("field", "hello from Codex", 16), Widget.widget_set_min(Widget.widget_gauge("gauge", step, gauge_steps), 0, 24), Widget.widget_button("ok", "OK"), Widget.widget_custom("dot", "event-dot", 20, 20)])

# --- Entry ---

main! = |args| {
	mem = Mem.new(U64.to_i64_wrap(List.len(args)))
	(_mem8, mem__647) = ({
		(mem1, w) = Mem.load!(mem, cell_width, 0, 4)
		(mem2, h) = Mem.load!(mem1, cell_height, 0, 4)
		(mem3, stride) = Mem.load!(mem2, cell_stride, 0, 4)
		(mem4, mem__646) = Mem.load!(mem3, cell_clock, 0, 4)
		ticks = I64.div_trunc_by(mem__646, 100)
		step = (ticks - (I64.div_trunc_by(ticks, (gauge_steps + 1)) * (gauge_steps + 1)))
		th = Theme.theme_terminal
		pal = th.th_palette
		(mem5, _bg) = GopDraw.gop_fill_rect!(mem4, fb_base, stride, h, 0, 0, w, h, pal.pal_bg)
		(mem6, font) = BitmapFont.cbf_init!(mem5)
		(mem7, _laid) = GopComposite.comp_render!(mem6, fb_base, stride, h, font, GopFont.gfont_none, demo_tree(step), th, w, h, 1)
		({
			(mem7, line!(Str.concat(Str.concat(Str.concat("gauge : ", I64.to_str(step)), " of "), I64.to_str(gauge_steps))))
		})
	})
	mem__647
	Ok({})
}
