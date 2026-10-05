# BoxModel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Theme

BoxModel :: [].{
	LayoutRect := { lr_x : I64, lr_y : I64, lr_w : I64, lr_h : I64 }.{
		is_eq : BoxModel.LayoutRect, BoxModel.LayoutRect -> Bool
		is_eq = |a, b| eq_LayoutRect(a, b)
	}

	layout_rect : I64, I64, I64, I64 -> BoxModel.LayoutRect
	layout_rect = |x, y, w, h| BoxModel.LayoutRect.{ lr_x: x, lr_y: y, lr_w: w, lr_h: h }

	layout_rect_zero : BoxModel.LayoutRect
	layout_rect_zero = BoxModel.LayoutRect.{ lr_x: 0, lr_y: 0, lr_w: 0, lr_h: 0 }

	box_margin_rect : BoxModel.LayoutRect, Theme.Edges -> BoxModel.LayoutRect
	box_margin_rect = |outer, margin| BoxModel.LayoutRect.{ lr_x: (outer.lr_x + margin.edge_left), lr_y: (outer.lr_y + margin.edge_top), lr_w: box_clamp0((outer.lr_w - Theme.edges_h(margin))), lr_h: box_clamp0((outer.lr_h - Theme.edges_v(margin))) }

	box_border_rect : BoxModel.LayoutRect, Theme.Edges, Theme.Border -> BoxModel.LayoutRect
	box_border_rect = |outer, margin, _bdr| ({
		mr = box_margin_rect(outer, margin)
		BoxModel.LayoutRect.{ lr_x: mr.lr_x, lr_y: mr.lr_y, lr_w: mr.lr_w, lr_h: mr.lr_h }
	})

	box_padding_rect : BoxModel.LayoutRect, Theme.Edges, Theme.Border -> BoxModel.LayoutRect
	box_padding_rect = |outer, margin, bdr| ({
		br = box_border_rect(outer, margin, bdr)
		BoxModel.LayoutRect.{ lr_x: (br.lr_x + bdr.bdr_left.brd_width), lr_y: (br.lr_y + bdr.bdr_top.brd_width), lr_w: box_clamp0((br.lr_w - border_h(bdr))), lr_h: box_clamp0((br.lr_h - border_v(bdr))) }
	})

	box_content_rect : BoxModel.LayoutRect, Theme.Edges, Theme.Border, Theme.Edges -> BoxModel.LayoutRect
	box_content_rect = |outer, margin, bdr, padding| ({
		pr = box_padding_rect(outer, margin, bdr)
		BoxModel.LayoutRect.{ lr_x: (pr.lr_x + padding.edge_left), lr_y: (pr.lr_y + padding.edge_top), lr_w: box_clamp0((pr.lr_w - Theme.edges_h(padding))), lr_h: box_clamp0((pr.lr_h - Theme.edges_v(padding))) }
	})

	box_content_from_style : BoxModel.LayoutRect, Theme.WidgetStyle -> BoxModel.LayoutRect
	box_content_from_style = |outer, ws| box_content_rect(outer, ws.ws_margin, ws.ws_border, ws.ws_padding)

	border_h : Theme.Border -> I64
	border_h = |b| (b.bdr_left.brd_width + b.bdr_right.brd_width)

	border_v : Theme.Border -> I64
	border_v = |b| (b.bdr_top.brd_width + b.bdr_bottom.brd_width)

	style_overhead_w : Theme.WidgetStyle -> I64
	style_overhead_w = |ws| ((Theme.edges_h(ws.ws_margin) + border_h(ws.ws_border)) + Theme.edges_h(ws.ws_padding))

	style_overhead_h : Theme.WidgetStyle -> I64
	style_overhead_h = |ws| ((Theme.edges_v(ws.ws_margin) + border_v(ws.ws_border)) + Theme.edges_v(ws.ws_padding))

	rect_contains : BoxModel.LayoutRect, I64, I64 -> Bool
	rect_contains = |r, px, py| (if (px < r.lr_x) { False } else { (if (py < r.lr_y) { False } else { (if (px >= (r.lr_x + r.lr_w)) { False } else { (if (py >= (r.lr_y + r.lr_h)) { False } else { True }) }) }) })

	box_min : I64, I64 -> I64
	box_min = |a, b| (if (a < b) { a } else { b })

	box_max : I64, I64 -> I64
	box_max = |a, b| (if (a > b) { a } else { b })

	box_clamp0 : I64 -> I64
	box_clamp0 = |v| (if (v < 0) { 0 } else { v })

	eq_LayoutRect : BoxModel.LayoutRect, BoxModel.LayoutRect -> Bool
	eq_LayoutRect = |ex, ey| ((((ex.lr_x == ey.lr_x) and (ex.lr_y == ey.lr_y)) and (ex.lr_w == ey.lr_w)) and (ex.lr_h == ey.lr_h))
}
