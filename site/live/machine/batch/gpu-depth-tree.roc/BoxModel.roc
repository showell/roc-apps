# BoxModel -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Theme

BoxModel :: [].{
	LayoutRect : { lr_x : I64, lr_y : I64, lr_w : I64, lr_h : I64 }

	layout_rect : I64, I64, I64, I64 -> BoxModel.LayoutRect
	layout_rect = |x, y, w, h| { lr_x: x, lr_y: y, lr_w: w, lr_h: h }

	layout_rect_zero : BoxModel.LayoutRect
	layout_rect_zero = { lr_x: 0, lr_y: 0, lr_w: 0, lr_h: 0 }

	box_margin_rect : BoxModel.LayoutRect, Theme.Edges -> BoxModel.LayoutRect
	box_margin_rect = |outer, margin| { lr_x: (outer.lr_x + margin.edge_left), lr_y: (outer.lr_y + margin.edge_top), lr_w: box_clamp0((outer.lr_w - Theme.edges_h(margin))), lr_h: box_clamp0((outer.lr_h - Theme.edges_v(margin))) }

	box_border_rect : BoxModel.LayoutRect, Theme.Edges, Theme.Border -> BoxModel.LayoutRect
	box_border_rect = |outer, margin, _bdr| ({
		mr = box_margin_rect(outer, margin)
		{ lr_x: mr.lr_x, lr_y: mr.lr_y, lr_w: mr.lr_w, lr_h: mr.lr_h }
	})

	box_padding_rect : BoxModel.LayoutRect, Theme.Edges, Theme.Border -> BoxModel.LayoutRect
	box_padding_rect = |outer, margin, bdr| ({
		br = box_border_rect(outer, margin, bdr)
		{ lr_x: (br.lr_x + bdr.bdr_left.brd_width), lr_y: (br.lr_y + bdr.bdr_top.brd_width), lr_w: box_clamp0((br.lr_w - border_h(bdr))), lr_h: box_clamp0((br.lr_h - border_v(bdr))) }
	})

	box_content_rect : BoxModel.LayoutRect, Theme.Edges, Theme.Border, Theme.Edges -> BoxModel.LayoutRect
	box_content_rect = |outer, margin, bdr, padding| ({
		pr = box_padding_rect(outer, margin, bdr)
		{ lr_x: (pr.lr_x + padding.edge_left), lr_y: (pr.lr_y + padding.edge_top), lr_w: box_clamp0((pr.lr_w - Theme.edges_h(padding))), lr_h: box_clamp0((pr.lr_h - Theme.edges_v(padding))) }
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

	rect_intersects : BoxModel.LayoutRect, BoxModel.LayoutRect -> Bool
	rect_intersects = |a, b| (if (a.lr_x >= (b.lr_x + b.lr_w)) { False } else { (if (b.lr_x >= (a.lr_x + a.lr_w)) { False } else { (if (a.lr_y >= (b.lr_y + b.lr_h)) { False } else { (if (b.lr_y >= (a.lr_y + a.lr_h)) { False } else { True }) }) }) })

	rect_intersection : BoxModel.LayoutRect, BoxModel.LayoutRect -> BoxModel.LayoutRect
	rect_intersection = |a, b| ({
		x0 = box_max(a.lr_x, b.lr_x)
		y0 = box_max(a.lr_y, b.lr_y)
		x1 = box_min((a.lr_x + a.lr_w), (b.lr_x + b.lr_w))
		y1 = box_min((a.lr_y + a.lr_h), (b.lr_y + b.lr_h))
		{ lr_x: x0, lr_y: y0, lr_w: box_clamp0((x1 - x0)), lr_h: box_clamp0((y1 - y0)) }
	})

	rect_union : BoxModel.LayoutRect, BoxModel.LayoutRect -> BoxModel.LayoutRect
	rect_union = |a, b| ({
		x0 = box_min(a.lr_x, b.lr_x)
		y0 = box_min(a.lr_y, b.lr_y)
		x1 = box_max((a.lr_x + a.lr_w), (b.lr_x + b.lr_w))
		y1 = box_max((a.lr_y + a.lr_h), (b.lr_y + b.lr_h))
		{ lr_x: x0, lr_y: y0, lr_w: (x1 - x0), lr_h: (y1 - y0) }
	})

	rect_inset : BoxModel.LayoutRect, I64 -> BoxModel.LayoutRect
	rect_inset = |r, n| { lr_x: (r.lr_x + n), lr_y: (r.lr_y + n), lr_w: box_clamp0((r.lr_w - (2 * n))), lr_h: box_clamp0((r.lr_h - (2 * n))) }

	rect_area : BoxModel.LayoutRect -> I64
	rect_area = |r| (r.lr_w * r.lr_h)

	format_rect : BoxModel.LayoutRect -> Str
	format_rect = |r| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat("(", I64.to_str(r.lr_x)), ","), I64.to_str(r.lr_y)), " "), I64.to_str(r.lr_w)), "x"), I64.to_str(r.lr_h)), ")")

	format_edges : Theme.Edges -> Str
	format_edges = |e| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat("(", I64.to_str(e.edge_top)), ","), I64.to_str(e.edge_right)), ","), I64.to_str(e.edge_bottom)), ","), I64.to_str(e.edge_left)), ")")

	box_min : I64, I64 -> I64
	box_min = |a, b| (if (a < b) { a } else { b })

	box_max : I64, I64 -> I64
	box_max = |a, b| (if (a > b) { a } else { b })

	box_clamp0 : I64 -> I64
	box_clamp0 = |v| (if (v < 0) { 0 } else { v })
}
