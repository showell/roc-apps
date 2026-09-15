# GpuRender -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import BoxModel
import Cce
import Machine
import Overlay
import TextOverflow
import Theme
import Widget

GpuRender :: [].{
	GpuFrame : { gf_idx : I64, gf_max : I64 }

	gr_cmd : I64
	gr_cmd = 3187671040

	gr_tri! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	gr_tri! = |machine, idx, x0, y0, x1, y1, x2, y2, c0, c1, c2, depth| ({
		(machine19, machine__19) = ({
		off = (idx * 72)
		({
			(machine1, machine__1) = Machine.store!(machine, gr_cmd, off, x0, 4)
			(machine2, machine__2) = Machine.store!(machine1, gr_cmd, (off + 4), y0, 4)
			(machine3, machine__3) = Machine.store!(machine2, gr_cmd, (off + 8), x1, 4)
			(machine4, machine__4) = Machine.store!(machine3, gr_cmd, (off + 12), y1, 4)
			(machine5, machine__5) = Machine.store!(machine4, gr_cmd, (off + 16), x2, 4)
			(machine6, machine__6) = Machine.store!(machine5, gr_cmd, (off + 20), y2, 4)
			(machine7, machine__7) = Machine.store!(machine6, gr_cmd, (off + 24), c0, 4)
			(machine8, machine__8) = Machine.store!(machine7, gr_cmd, (off + 28), c1, 4)
			(machine9, machine__9) = Machine.store!(machine8, gr_cmd, (off + 32), c2, 4)
			(machine10, machine__10) = Machine.store!(machine9, gr_cmd, (off + 36), depth, 4)
			(machine11, machine__11) = Machine.store!(machine10, gr_cmd, (off + 40), depth, 4)
			(machine12, machine__12) = Machine.store!(machine11, gr_cmd, (off + 44), depth, 4)
			(machine13, machine__13) = Machine.store!(machine12, gr_cmd, (off + 48), 0, 4)
			(machine14, machine__14) = Machine.store!(machine13, gr_cmd, (off + 52), 0, 4)
			(machine15, machine__15) = Machine.store!(machine14, gr_cmd, (off + 56), 0, 4)
			(machine16, machine__16) = Machine.store!(machine15, gr_cmd, (off + 60), 0, 4)
			(machine17, machine__17) = Machine.store!(machine16, gr_cmd, (off + 64), 0, 4)
			(machine18, machine__18) = Machine.store!(machine17, gr_cmd, (off + 68), 0, 4)
			(machine18, (((((((((((((((((machine__1 + machine__2) + machine__3) + machine__4) + machine__5) + machine__6) + machine__7) + machine__8) + machine__9) + machine__10) + machine__11) + machine__12) + machine__13) + machine__14) + machine__15) + machine__16) + machine__17) + machine__18))
		})
	})
		(machine19, machine__19)
	})

	gr_rect! : Machine.Machine, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, I64)
	gr_rect! = |machine, idx, x, y, w, h, color, depth| ({
		(machine1, machine__20) = gr_tri!(machine, idx, x, y, (x + w), y, x, (y + h), color, color, color, depth)
		(machine2, machine__21) = gr_tri!(machine1, (idx + 1), (x + w), y, (x + w), (y + h), x, (y + h), color, color, color, depth)
		(machine2, (machine__20 + machine__21))
	})

	gr_depth_scene : I64
	gr_depth_scene = 10000

	gr_depth_chrome : I64
	gr_depth_chrome = 5000

	gr_depth_overlay : I64
	gr_depth_overlay = 2000

	gr_depth_top : I64
	gr_depth_top = 1000

	gr_clear! : Machine.Machine, I64 => (Machine.Machine, I64)
	gr_clear! = |machine, color| Machine.port_out_32!(machine, 1025, color)

	gr_clear_depth! : Machine.Machine => (Machine.Machine, I64)
	gr_clear_depth! = |machine| Machine.port_out_32!(machine, 1026, 0)

	gr_flush! : Machine.Machine, I64 => (Machine.Machine, I64)
	gr_flush! = |machine, count| Machine.port_out_32!(machine, 1024, count)

	gf_new : I64 -> GpuRender.GpuFrame
	gf_new = |max_tris| { gf_idx: 0, gf_max: max_tris }

	gr_render_tree! : Machine.Machine, GpuRender.GpuFrame, Widget.WidgetNode, Theme.Theme, I64 => (Machine.Machine, GpuRender.GpuFrame)
	gr_render_tree! = |machine, gf, w, th, depth| ({
		(machine1, machine__22) = gr_render_node!(machine, gf, w, th, depth)
		gr_render_children!(machine1, machine__22, w.wn_children, th, depth, 0, w.wn_child_count)
	})

	gr_render_children! : Machine.Machine, GpuRender.GpuFrame, List(Widget.WidgetNode), Theme.Theme, I64, I64, I64 => (Machine.Machine, GpuRender.GpuFrame)
	gr_render_children! = |machine, gf, children, th, depth, i, n| (if (i >= n) { (machine, gf) } else { ({
		(machine1, machine__23) = gr_render_tree!(machine, gf, (List.get(children, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), th, (depth - 1))
		gr_render_children!(machine1, machine__23, children, th, depth, (i + 1), n)
	}) })

	gr_render_node! : Machine.Machine, GpuRender.GpuFrame, Widget.WidgetNode, Theme.Theme, I64 => (Machine.Machine, GpuRender.GpuFrame)
	gr_render_node! = |machine, gf, w, th, depth| (match w.wn_kind {
		WkPanel => gr_render_panel!(machine, gf, w, th, depth)
		WkLabel(txt) => gr_render_label!(machine, gf, w, th, txt, depth)
		WkButton(txt) => gr_render_button!(machine, gf, w, th, txt, depth)
		WkGauge(val, max_val) => gr_render_gauge!(machine, gf, w, th, val, max_val, depth)
		WkSeparator => gr_render_separator!(machine, gf, w, th, depth)
		WkInput(txt, cursor) => gr_render_input!(machine, gf, w, th, txt, cursor, depth)
		WkCustom(tag) => (if ((tag == Widget.wk_scroll_view_tag) or (tag == Widget.wk_spacer_tag)) { (machine, gf) } else { gr_render_panel!(machine, gf, w, th, depth) })
	})

	gr_render_panel! : Machine.Machine, GpuRender.GpuFrame, Widget.WidgetNode, Theme.Theme, I64 => (Machine.Machine, GpuRender.GpuFrame)
	gr_render_panel! = |machine, gf, w, th, depth| ({
		style = Theme.theme_resolve_panel(th, w.wn_state)
		br = BoxModel.box_margin_rect(w.wn_bounds, style.ws_margin)
		gr_emit_box!(machine, gf, br, style.ws_bg, style.ws_border, depth)
	})

	gr_render_button! : Machine.Machine, GpuRender.GpuFrame, Widget.WidgetNode, Theme.Theme, Str, I64 => (Machine.Machine, GpuRender.GpuFrame)
	gr_render_button! = |machine, gf, w, th, txt, depth| ({
		style = Theme.theme_resolve_button(th, w.wn_state)
		br = BoxModel.box_margin_rect(w.wn_bounds, style.ws_margin)
		content = BoxModel.box_content_from_style(w.wn_bounds, style)
		text_depth = (if (depth <= 2000) { gr_depth_top } else { (depth - 1000) })
		({
			(machine1, machine__24) = gr_emit_box!(machine, gf, br, style.ws_bg, style.ws_border, depth)
			gr_emit_text!(machine1, machine__24, txt, content.lr_x, content.lr_y, Theme.theme_tone_fg(th, w.wn_tone, style.ws_fg), text_depth, content.lr_w, TextOverflow.text_overflow_default)
		})
	})

	gr_render_label! : Machine.Machine, GpuRender.GpuFrame, Widget.WidgetNode, Theme.Theme, Str, I64 => (Machine.Machine, GpuRender.GpuFrame)
	gr_render_label! = |machine, gf, w, th, txt, depth| ({
		style = Theme.theme_resolve_label(th, w.wn_state)
		content = BoxModel.box_content_from_style(w.wn_bounds, style)
		text_depth = (if (depth <= 2000) { gr_depth_top } else { (depth - 1000) })
		gr_emit_text!(machine, gf, txt, content.lr_x, content.lr_y, Theme.theme_tone_fg(th, w.wn_tone, style.ws_fg), text_depth, content.lr_w, TextOverflow.text_overflow_default)
	})

	gr_render_gauge! : Machine.Machine, GpuRender.GpuFrame, Widget.WidgetNode, Theme.Theme, I64, I64, I64 => (Machine.Machine, GpuRender.GpuFrame)
	gr_render_gauge! = |machine, gf, w, th, val, max_val, depth| ({
		style = Theme.theme_resolve_gauge(th, w.wn_state)
		br = BoxModel.box_margin_rect(w.wn_bounds, style.ws_margin)
		content = BoxModel.box_content_from_style(w.wn_bounds, style)
		held = (if (val < 0) { 0 } else { (if (val > max_val) { max_val } else { val }) })
		fill_w = (if (max_val > 0) { I64.div_trunc_by((content.lr_w * held), max_val) } else { 0 })
		({
			(machine1, machine__25) = gr_emit_box!(machine, gf, br, style.ws_bg, style.ws_border, depth)
			gr_emit_rect!(machine1, machine__25, content.lr_x, content.lr_y, fill_w, content.lr_h, style.ws_fg, (depth - 1))
		})
	})

	gr_render_separator! : Machine.Machine, GpuRender.GpuFrame, Widget.WidgetNode, Theme.Theme, I64 => (Machine.Machine, GpuRender.GpuFrame)
	gr_render_separator! = |machine, gf, w, th, depth| ({
		style = Theme.theme_resolve_separator(th, w.wn_state)
		br = BoxModel.box_margin_rect(w.wn_bounds, style.ws_margin)
		gr_emit_rect!(machine, gf, br.lr_x, (br.lr_y + I64.div_trunc_by(br.lr_h, 2)), br.lr_w, 1, style.ws_bg, depth)
	})

	gr_render_input! : Machine.Machine, GpuRender.GpuFrame, Widget.WidgetNode, Theme.Theme, Str, I64, I64 => (Machine.Machine, GpuRender.GpuFrame)
	gr_render_input! = |machine, gf, w, th, txt, cursor, depth| ({
		style = Theme.theme_resolve_input(th, w.wn_state)
		br = BoxModel.box_margin_rect(w.wn_bounds, style.ws_margin)
		content = BoxModel.box_content_from_style(w.wn_bounds, style)
		text_depth = (if (depth <= 2000) { gr_depth_top } else { (depth - 1000) })
		cur_hi = ((content.lr_x + content.lr_w) - 1)
		raw_x = (content.lr_x + (cursor * 6))
		capped = (if (raw_x > cur_hi) { cur_hi } else { raw_x })
		cursor_x = (if (capped < content.lr_x) { content.lr_x } else { capped })
		({
			(machine1, machine__26) = gr_emit_box!(machine, gf, br, style.ws_bg, style.ws_border, depth)
			(machine2, machine__27) = gr_emit_text!(machine1, machine__26, txt, content.lr_x, content.lr_y, style.ws_fg, text_depth, content.lr_w, TextOverflow.text_overflow_default)
			gr_emit_rect!(machine2, machine__27, cursor_x, content.lr_y, 1, 7, style.ws_fg, text_depth)
		})
	})

	gr_render_overlay! : Machine.Machine, GpuRender.GpuFrame, Overlay.Overlay, Theme.Theme => (Machine.Machine, GpuRender.GpuFrame)
	gr_render_overlay! = |machine, gf, ov, th| (if ov.ov_visible { ({
		laid = Widget.widget_layout(ov.ov_widget, th, BoxModel.layout_rect(ov.ov_x, ov.ov_y, ov.ov_width, ov.ov_height))
		({
			(machine1, machine__28) = gr_emit_rect!(machine, gf, ov.ov_x, ov.ov_y, ov.ov_width, ov.ov_height, th.th_palette.pal_bg, gr_depth_overlay)
			gr_render_tree!(machine1, machine__28, laid, th, gr_depth_overlay)
		})
	}) } else { (machine, gf) })

	gr_render_overlays! : Machine.Machine, GpuRender.GpuFrame, Overlay.OverlayStack, Theme.Theme, I64, I64 => (Machine.Machine, GpuRender.GpuFrame)
	gr_render_overlays! = |machine, gf, os, th, i, n| (if (i >= n) { (machine, gf) } else { ({
		(machine1, machine__29) = gr_render_overlay!(machine, gf, (List.get(os.os_overlays, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), th)
		gr_render_overlays!(machine1, machine__29, os, th, (i + 1), n)
	}) })

	gr_frame_bump : I64, GpuRender.GpuFrame -> GpuRender.GpuFrame
	gr_frame_bump = |_written, gf| { gf_idx: (gf.gf_idx + 2), gf_max: gf.gf_max }

	gr_emit_rect! : Machine.Machine, GpuRender.GpuFrame, I64, I64, I64, I64, I64, I64 => (Machine.Machine, GpuRender.GpuFrame)
	gr_emit_rect! = |machine, gf, x, y, w, h, color, depth| ({
		(machine4, machine__33) = (if (w <= 0) { (machine, gf) } else { ({
		(machine3, machine__32) = (if (h <= 0) { (machine, gf) } else { ({
		(machine2, machine__31) = (if ((gf.gf_idx + 2) > gf.gf_max) { (machine, gf) } else { ({
		(machine1, machine__30) = gr_rect!(machine, gf.gf_idx, x, y, w, h, color, depth)
		(machine1, gr_frame_bump(machine__30, gf))
	}) })
		(machine2, machine__31)
	}) })
		(machine3, machine__32)
	}) })
		(machine4, machine__33)
	})

	gr_emit_box! : Machine.Machine, GpuRender.GpuFrame, BoxModel.LayoutRect, I64, Theme.Border, I64 => (Machine.Machine, GpuRender.GpuFrame)
	gr_emit_box! = |machine, gf, r, bg, bdr, depth| ({
		wt = bdr.bdr_top.brd_width
		wb = bdr.bdr_bottom.brd_width
		wl = bdr.bdr_left.brd_width
		wr = bdr.bdr_right.brd_width
		iy = (r.lr_y + wt)
		ih = BoxModel.box_clamp0(((r.lr_h - wt) - wb))
		iw = BoxModel.box_clamp0(((r.lr_w - wl) - wr))
		({
			(machine1, machine__34) = gr_emit_rect!(machine, gf, (r.lr_x + wl), iy, iw, ih, bg, depth)
			(machine2, machine__35) = gr_emit_rect!(machine1, machine__34, r.lr_x, r.lr_y, r.lr_w, wt, bdr.bdr_top.brd_color, depth)
			(machine3, machine__36) = gr_emit_rect!(machine2, machine__35, r.lr_x, ((r.lr_y + r.lr_h) - wb), r.lr_w, wb, bdr.bdr_bottom.brd_color, depth)
			(machine4, machine__37) = gr_emit_rect!(machine3, machine__36, r.lr_x, iy, wl, ih, bdr.bdr_left.brd_color, depth)
			gr_emit_rect!(machine4, machine__37, ((r.lr_x + r.lr_w) - wr), iy, wr, ih, bdr.bdr_right.brd_color, depth)
		})
	})

	gr_glyph_advance : I64
	gr_glyph_advance = 6

	gr_glyph_width : I64
	gr_glyph_width = 5

	gr_emit_text! : Machine.Machine, GpuRender.GpuFrame, Str, I64, I64, I64, I64, I64, TextOverflow.TextOverflow => (Machine.Machine, GpuRender.GpuFrame)
	gr_emit_text! = |machine, gf, txt, x, y, color, depth, avail, mode| ({
		len = Cce.length(txt)
		start = TextOverflow.text_overflow_start(mode, len, avail, gr_glyph_advance, gr_glyph_width)
		count = TextOverflow.text_overflow_count(mode, len, avail, gr_glyph_advance, gr_glyph_width)
		dots = TextOverflow.text_overflow_dots(mode, len, avail, gr_glyph_advance, gr_glyph_width)
		({
			(machine1, machine__38) = gr_emit_text_loop!(machine, gf, txt, x, y, color, depth, start, (start + count), start)
			gr_emit_dots!(machine1, machine__38, (x + (count * gr_glyph_advance)), y, color, depth, 0, dots)
		})
	})

	gr_emit_text_loop! : Machine.Machine, GpuRender.GpuFrame, Str, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, GpuRender.GpuFrame)
	gr_emit_text_loop! = |machine, gf, txt, x, y, color, depth, i, stop, start| (if (i >= stop) { (machine, gf) } else { ({
		(machine1, machine__39) = gr_emit_glyph!(machine, gf, gr_text_char_at(txt, i), (x + ((i - start) * gr_glyph_advance)), y, color, depth)
		gr_emit_text_loop!(machine1, machine__39, txt, x, y, color, depth, (i + 1), stop, start)
	}) })

	gr_emit_dots! : Machine.Machine, GpuRender.GpuFrame, I64, I64, I64, I64, I64, I64 => (Machine.Machine, GpuRender.GpuFrame)
	gr_emit_dots! = |machine, gf, x, y, color, depth, k, n| (if (k >= n) { (machine, gf) } else { ({
		(machine1, machine__40) = gr_emit_glyph!(machine, gf, gr_text_char_at(".", 0), (x + (k * gr_glyph_advance)), y, color, depth)
		gr_emit_dots!(machine1, machine__40, x, y, color, depth, (k + 1), n)
	}) })

	gr_emit_glyph! : Machine.Machine, GpuRender.GpuFrame, I64, I64, I64, I64, I64 => (Machine.Machine, GpuRender.GpuFrame)
	gr_emit_glyph! = |machine, gf, ch, x, y, color, depth| ({
		rows = gr_glyph_rows(ch)
		gr_emit_glyph_rows!(machine, gf, rows, x, y, color, depth, 0, 7)
	})

	gr_emit_glyph_rows! : Machine.Machine, GpuRender.GpuFrame, List(I64), I64, I64, I64, I64, I64, I64 => (Machine.Machine, GpuRender.GpuFrame)
	gr_emit_glyph_rows! = |machine, gf, rows, x, y, color, depth, row, max_row| (if (row >= max_row) { (machine, gf) } else { ({
		(machine1, machine__41) = gr_emit_glyph_cols!(machine, gf, (List.get(rows, I64.to_u64_wrap(row)) ?? crash("list-at out of range")), x, (y + row), color, depth, 0, 5)
		gr_emit_glyph_rows!(machine1, machine__41, rows, x, y, color, depth, (row + 1), max_row)
	}) })

	gr_emit_glyph_cols! : Machine.Machine, GpuRender.GpuFrame, I64, I64, I64, I64, I64, I64, I64 => (Machine.Machine, GpuRender.GpuFrame)
	gr_emit_glyph_cols! = |machine, gf, bits, x, y, color, depth, col, max_col| (if (col >= max_col) { (machine, gf) } else { (if (I64.bitwise_and(bits, I64.shl_wrap(1, I64.to_u8_wrap((4 - col)))) > 0) { ({
		(machine1, machine__42) = gr_emit_rect!(machine, gf, (x + col), y, 1, 1, color, depth)
		gr_emit_glyph_cols!(machine1, machine__42, bits, x, y, color, depth, (col + 1), max_col)
	}) } else { gr_emit_glyph_cols!(machine, gf, bits, x, y, color, depth, (col + 1), max_col) }) })

	gr_text_char_at : Str, I64 -> I64
	gr_text_char_at = |t, i| gr_cce_to_ascii(Cce.at_or_crash(t, i))

	gr_cce_to_ascii : I64 -> I64
	gr_cce_to_ascii = |c| (if (c == 2) { 32 } else { (if (c >= 3) { (if (c <= 12) { (c + 45) } else { gr_cce_alpha(c) }) } else { 32 }) })

	gr_cce_alpha : I64 -> I64
	gr_cce_alpha = |c| (if (c == 13) { 69 } else { (if (c == 14) { 84 } else { (if (c == 15) { 65 } else { (if (c == 16) { 79 } else { (if (c == 17) { 73 } else { (if (c == 18) { 78 } else { (if (c == 19) { 83 } else { (if (c == 20) { 72 } else { (if (c == 21) { 82 } else { (if (c == 22) { 68 } else { (if (c == 23) { 76 } else { (if (c == 24) { 67 } else { (if (c == 25) { 85 } else { (if (c == 26) { 77 } else { (if (c == 27) { 87 } else { (if (c == 28) { 70 } else { (if (c == 29) { 71 } else { (if (c == 30) { 89 } else { (if (c == 31) { 80 } else { (if (c == 32) { 66 } else { (if (c == 33) { 86 } else { (if (c == 34) { 75 } else { (if (c == 35) { 74 } else { (if (c == 36) { 88 } else { (if (c == 37) { 81 } else { (if (c == 38) { 90 } else { (if (c >= 39) { (if (c <= 64) { gr_cce_alpha((c - 26)) } else { gr_cce_punct(c) }) } else { 32 }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) })

	gr_cce_punct : I64 -> I64
	gr_cce_punct = |c| (if (c == 65) { 46 } else { (if (c == 66) { 44 } else { (if (c == 67) { 33 } else { (if (c == 68) { 63 } else { (if (c == 69) { 58 } else { (if (c == 70) { 59 } else { (if (c == 71) { 39 } else { (if (c == 73) { 45 } else { (if (c == 74) { 40 } else { (if (c == 75) { 41 } else { (if (c == 76) { 43 } else { (if (c == 77) { 61 } else { (if (c == 78) { 42 } else { (if (c == 81) { 47 } else { 32 }) }) }) }) }) }) }) }) }) }) }) }) }) })

	gr_glyph_rows : I64 -> List(I64)
	gr_glyph_rows = |ch| (if (ch == 48) { [14, 17, 19, 21, 25, 17, 14] } else { (if (ch == 49) { [4, 12, 4, 4, 4, 4, 14] } else { (if (ch == 50) { [14, 17, 1, 2, 4, 8, 31] } else { (if (ch == 51) { [14, 17, 1, 6, 1, 17, 14] } else { (if (ch == 52) { [2, 6, 10, 18, 31, 2, 2] } else { (if (ch == 53) { [31, 16, 30, 1, 1, 17, 14] } else { (if (ch == 54) { [6, 8, 16, 30, 17, 17, 14] } else { (if (ch == 55) { [31, 1, 2, 4, 4, 4, 4] } else { (if (ch == 56) { [14, 17, 17, 14, 17, 17, 14] } else { (if (ch == 57) { [14, 17, 17, 15, 1, 2, 12] } else { gr_glyph_alpha(ch) }) }) }) }) }) }) }) }) }) })

	gr_glyph_alpha : I64 -> List(I64)
	gr_glyph_alpha = |ch| (if (ch == 65) { [14, 17, 17, 31, 17, 17, 17] } else { (if (ch == 66) { [30, 17, 17, 30, 17, 17, 30] } else { (if (ch == 67) { [14, 17, 16, 16, 16, 17, 14] } else { (if (ch == 68) { [30, 17, 17, 17, 17, 17, 30] } else { (if (ch == 69) { [31, 16, 16, 30, 16, 16, 31] } else { (if (ch == 70) { [31, 16, 16, 30, 16, 16, 16] } else { (if (ch == 71) { [14, 17, 16, 19, 17, 17, 14] } else { (if (ch == 72) { [17, 17, 17, 31, 17, 17, 17] } else { (if (ch == 73) { [14, 4, 4, 4, 4, 4, 14] } else { (if (ch == 74) { [7, 2, 2, 2, 2, 18, 12] } else { (if (ch == 75) { [17, 18, 20, 24, 20, 18, 17] } else { (if (ch == 76) { [16, 16, 16, 16, 16, 16, 31] } else { (if (ch == 77) { [17, 27, 21, 21, 17, 17, 17] } else { gr_glyph_alpha2(ch) }) }) }) }) }) }) }) }) }) }) }) }) })

	gr_glyph_alpha2 : I64 -> List(I64)
	gr_glyph_alpha2 = |ch| (if (ch == 78) { [17, 25, 21, 19, 17, 17, 17] } else { (if (ch == 79) { [14, 17, 17, 17, 17, 17, 14] } else { (if (ch == 80) { [30, 17, 17, 30, 16, 16, 16] } else { (if (ch == 81) { [14, 17, 17, 17, 21, 18, 13] } else { (if (ch == 82) { [30, 17, 17, 30, 20, 18, 17] } else { (if (ch == 83) { [14, 17, 16, 14, 1, 17, 14] } else { (if (ch == 84) { [31, 4, 4, 4, 4, 4, 4] } else { (if (ch == 85) { [17, 17, 17, 17, 17, 17, 14] } else { (if (ch == 86) { [17, 17, 17, 17, 10, 10, 4] } else { (if (ch == 87) { [17, 17, 17, 21, 21, 27, 17] } else { (if (ch == 88) { [17, 17, 10, 4, 10, 17, 17] } else { (if (ch == 89) { [17, 17, 10, 4, 4, 4, 4] } else { (if (ch == 90) { [31, 1, 2, 4, 8, 16, 31] } else { gr_glyph_misc(ch) }) }) }) }) }) }) }) }) }) }) }) }) })

	gr_glyph_misc : I64 -> List(I64)
	gr_glyph_misc = |ch| (if (ch == 46) { [0, 0, 0, 0, 0, 0, 4] } else { (if (ch == 44) { [0, 0, 0, 0, 0, 4, 8] } else { (if (ch == 58) { [0, 0, 4, 0, 0, 4, 0] } else { (if (ch == 45) { [0, 0, 0, 14, 0, 0, 0] } else { (if (ch == 43) { [0, 4, 4, 31, 4, 4, 0] } else { (if (ch == 42) { [0, 4, 21, 14, 21, 4, 0] } else { (if (ch == 47) { [1, 1, 2, 4, 8, 16, 16] } else { (if (ch == 40) { [2, 4, 8, 8, 8, 4, 2] } else { (if (ch == 41) { [8, 4, 2, 2, 2, 4, 8] } else { (if (ch == 91) { [14, 8, 8, 8, 8, 8, 14] } else { (if (ch == 93) { [14, 2, 2, 2, 2, 2, 14] } else { (if (ch == 61) { [0, 0, 31, 0, 31, 0, 0] } else { (if (ch == 60) { [2, 4, 8, 16, 8, 4, 2] } else { (if (ch == 62) { [8, 4, 2, 1, 2, 4, 8] } else { (if (ch == 32) { [0, 0, 0, 0, 0, 0, 0] } else { (if (ch == 95) { [0, 0, 0, 0, 0, 0, 31] } else { (if (ch == 35) { [10, 10, 31, 10, 31, 10, 10] } else { (if (ch == 33) { [4, 4, 4, 4, 0, 0, 4] } else { (if (ch == 63) { [14, 17, 1, 2, 4, 0, 4] } else { (if (ch == 37) { [24, 25, 2, 4, 8, 19, 3] } else { gr_glyph_lower(ch) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) })

	gr_glyph_lower : I64 -> List(I64)
	gr_glyph_lower = |ch| (if (ch == 97) { [0, 0, 14, 1, 15, 17, 15] } else { (if (ch == 98) { [16, 16, 30, 17, 17, 17, 30] } else { (if (ch == 99) { [0, 0, 14, 16, 16, 17, 14] } else { (if (ch == 100) { [1, 1, 15, 17, 17, 17, 15] } else { (if (ch == 101) { [0, 0, 14, 17, 31, 16, 14] } else { (if (ch == 102) { [6, 8, 28, 8, 8, 8, 8] } else { (if (ch == 103) { [0, 0, 15, 17, 15, 1, 14] } else { (if (ch == 104) { [16, 16, 30, 17, 17, 17, 17] } else { (if (ch == 105) { [4, 0, 12, 4, 4, 4, 14] } else { (if (ch == 106) { [2, 0, 6, 2, 2, 18, 12] } else { (if (ch == 107) { [16, 16, 18, 20, 24, 20, 18] } else { (if (ch == 108) { [12, 4, 4, 4, 4, 4, 14] } else { (if (ch == 109) { [0, 0, 26, 21, 21, 21, 21] } else { (if (ch == 110) { [0, 0, 30, 17, 17, 17, 17] } else { (if (ch == 111) { [0, 0, 14, 17, 17, 17, 14] } else { (if (ch == 112) { [0, 0, 30, 17, 30, 16, 16] } else { (if (ch == 113) { [0, 0, 15, 17, 15, 1, 1] } else { (if (ch == 114) { [0, 0, 22, 25, 16, 16, 16] } else { (if (ch == 115) { [0, 0, 15, 16, 14, 1, 30] } else { (if (ch == 116) { [8, 8, 28, 8, 8, 9, 6] } else { (if (ch == 117) { [0, 0, 17, 17, 17, 19, 13] } else { (if (ch == 118) { [0, 0, 17, 17, 17, 10, 4] } else { (if (ch == 119) { [0, 0, 17, 17, 21, 21, 10] } else { (if (ch == 120) { [0, 0, 17, 10, 4, 10, 17] } else { (if (ch == 121) { [0, 0, 17, 17, 15, 1, 14] } else { (if (ch == 122) { [0, 0, 31, 2, 4, 8, 31] } else { [0, 0, 14, 10, 14, 0, 0] }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) }) })
}
