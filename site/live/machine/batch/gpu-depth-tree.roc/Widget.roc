# Widget -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import BoxModel
import CceText
import Layout
import Theme

Widget :: [].{
	WidgetKind : [WkPanel, WkStack, WkScroll(I64), WkLabel(CceText), WkButton(CceText), WkGauge(I64, I64), WkSeparator, WkInput(CceText, I64), WkCustom(CceText)]
	WidgetNode := { wn_kind : Widget.WidgetKind, wn_id : CceText, wn_children : List(Widget.WidgetNode), wn_child_count : I64, wn_layout_dir : Layout.LayoutDir, wn_gap : I64, wn_flex : I64, wn_min_w : I64, wn_min_h : I64, wn_max_w : I64, wn_max_h : I64, wn_fit_w : Bool, wn_pref_w : I64, wn_pref_h : I64, wn_align : I64, wn_flags : I64, wn_data : I64, wn_tone : I64, wn_bounds : BoxModel.LayoutRect }.{
		is_eq : Widget.WidgetNode, Widget.WidgetNode -> Bool
		is_eq = |a, b| eq_WidgetNode(a, b)
	}

	widget_panel : CceText, Layout.LayoutDir, I64, List(Widget.WidgetNode) -> Widget.WidgetNode
	widget_panel = |id, dir, gap, children| Widget.WidgetNode.{ wn_kind: WkPanel, wn_id: id, wn_children: children, wn_child_count: U64.to_i64_wrap(List.len(children)), wn_layout_dir: dir, wn_gap: gap, wn_flex: 1, wn_min_w: 0, wn_min_h: 0, wn_max_w: 0, wn_max_h: 0, wn_fit_w: False, wn_pref_w: 0, wn_pref_h: 0, wn_align: 0, wn_flags: 0, wn_data: 0, wn_tone: Theme.tone_none, wn_bounds: BoxModel.layout_rect_zero }

	widget_stack : CceText, Layout.LayoutDir, I64, List(Widget.WidgetNode) -> Widget.WidgetNode
	widget_stack = |id, dir, gap, children| Widget.WidgetNode.{ wn_kind: WkStack, wn_id: id, wn_children: children, wn_child_count: U64.to_i64_wrap(List.len(children)), wn_layout_dir: dir, wn_gap: gap, wn_flex: 1, wn_min_w: 0, wn_min_h: 0, wn_max_w: 0, wn_max_h: 0, wn_fit_w: False, wn_pref_w: 0, wn_pref_h: 0, wn_align: 0, wn_flags: 0, wn_data: 0, wn_tone: Theme.tone_none, wn_bounds: BoxModel.layout_rect_zero }

	wk_spacer_tag : CceText
	wk_spacer_tag = "spacer"

	widget_is_scroll_view : Widget.WidgetNode -> Bool
	widget_is_scroll_view = |w| (match w.wn_kind {
		WkScroll(_off) => True
		_ => False
	})

	widget_scroll_offset : Widget.WidgetNode -> I64
	widget_scroll_offset = |w| (match w.wn_kind {
		WkScroll(off) => off
		_ => 0
	})

	widget_button : CceText, CceText -> Widget.WidgetNode
	widget_button = |id, txt| Widget.WidgetNode.{ wn_kind: WkButton(txt), wn_id: id, wn_children: [], wn_child_count: 0, wn_layout_dir: DirRow, wn_gap: 0, wn_flex: 0, wn_min_w: ((CceText.len(txt) * 8) + 16), wn_min_h: 24, wn_max_w: 0, wn_max_h: 0, wn_fit_w: True, wn_pref_w: 0, wn_pref_h: 0, wn_align: 0, wn_flags: 0, wn_data: 0, wn_tone: Theme.tone_none, wn_bounds: BoxModel.layout_rect_zero }

	widget_gauge : CceText, I64, I64 -> Widget.WidgetNode
	widget_gauge = |id, value, max_val| Widget.WidgetNode.{ wn_kind: WkGauge(value, max_val), wn_id: id, wn_children: [], wn_child_count: 0, wn_layout_dir: DirRow, wn_gap: 0, wn_flex: 1, wn_min_w: 60, wn_min_h: 16, wn_max_w: 0, wn_max_h: 0, wn_fit_w: False, wn_pref_w: 0, wn_pref_h: 0, wn_align: 0, wn_flags: 0, wn_data: 0, wn_tone: Theme.tone_none, wn_bounds: BoxModel.layout_rect_zero }

	widget_separator : CceText -> Widget.WidgetNode
	widget_separator = |id| Widget.WidgetNode.{ wn_kind: WkSeparator, wn_id: id, wn_children: [], wn_child_count: 0, wn_layout_dir: DirRow, wn_gap: 0, wn_flex: 0, wn_min_w: 0, wn_min_h: 2, wn_max_w: 0, wn_max_h: 0, wn_fit_w: False, wn_pref_w: 0, wn_pref_h: 0, wn_align: 0, wn_flags: 0, wn_data: 0, wn_tone: Theme.tone_none, wn_bounds: BoxModel.layout_rect_zero }

	widget_set_flex : Widget.WidgetNode, I64 -> Widget.WidgetNode
	widget_set_flex = |w, f| Widget.WidgetNode.{ wn_kind: w.wn_kind, wn_id: w.wn_id, wn_children: w.wn_children, wn_child_count: w.wn_child_count, wn_layout_dir: w.wn_layout_dir, wn_gap: w.wn_gap, wn_flex: f, wn_min_w: w.wn_min_w, wn_min_h: w.wn_min_h, wn_max_w: w.wn_max_w, wn_max_h: w.wn_max_h, wn_fit_w: w.wn_fit_w, wn_pref_w: w.wn_pref_w, wn_pref_h: w.wn_pref_h, wn_align: w.wn_align, wn_flags: w.wn_flags, wn_data: w.wn_data, wn_tone: w.wn_tone, wn_bounds: w.wn_bounds }

	widget_set_min : Widget.WidgetNode, I64, I64 -> Widget.WidgetNode
	widget_set_min = |w, minw, minh| Widget.WidgetNode.{ wn_kind: w.wn_kind, wn_id: w.wn_id, wn_children: w.wn_children, wn_child_count: w.wn_child_count, wn_layout_dir: w.wn_layout_dir, wn_gap: w.wn_gap, wn_flex: w.wn_flex, wn_min_w: minw, wn_min_h: minh, wn_max_w: w.wn_max_w, wn_max_h: w.wn_max_h, wn_fit_w: False, wn_pref_w: w.wn_pref_w, wn_pref_h: w.wn_pref_h, wn_align: w.wn_align, wn_flags: w.wn_flags, wn_data: w.wn_data, wn_tone: w.wn_tone, wn_bounds: w.wn_bounds }

	widget_flags : Widget.WidgetNode -> I64
	widget_flags = |w| w.wn_flags

	widget_state_of : Widget.WidgetNode -> I64
	widget_state_of = |w| Theme.theme_state_of_flags(widget_flags(w))

	widget_fixed : Widget.WidgetNode, I64, I64 -> Widget.WidgetNode
	widget_fixed = |w, minw, minh| widget_set_flex(widget_set_min(w, minw, minh), 0)

	widget_set_bounds : Widget.WidgetNode, BoxModel.LayoutRect -> Widget.WidgetNode
	widget_set_bounds = |w, r| Widget.WidgetNode.{ wn_kind: w.wn_kind, wn_id: w.wn_id, wn_children: w.wn_children, wn_child_count: w.wn_child_count, wn_layout_dir: w.wn_layout_dir, wn_gap: w.wn_gap, wn_flex: w.wn_flex, wn_min_w: w.wn_min_w, wn_min_h: w.wn_min_h, wn_max_w: w.wn_max_w, wn_max_h: w.wn_max_h, wn_fit_w: w.wn_fit_w, wn_pref_w: w.wn_pref_w, wn_pref_h: w.wn_pref_h, wn_align: w.wn_align, wn_flags: w.wn_flags, wn_data: w.wn_data, wn_tone: w.wn_tone, wn_bounds: r }

	widget_measure : Widget.WidgetNode, Theme.Theme -> Widget.WidgetNode
	widget_measure = |w, th| (if (w.wn_child_count == 0) { w } else { ({
		kids = widget_measure_children(w.wn_children, th, 0, w.wn_child_count, [])
		style = widget_resolve_style(w, th)
		n : I64
		n = w.wn_child_count
		total_gap : I64
		total_gap = (if (n > 1) { (w.wn_gap * (n - 1)) } else { 0 })
		inner_w : I64
		inner_w = (match w.wn_layout_dir {
			DirRow => (widget_sum_min_w(kids, th, 0, n, 0) + total_gap)
			DirColumn => widget_max_min_w(kids, th, 0, n, 0)
		})
		inner_h : I64
		inner_h = (match w.wn_layout_dir {
			DirRow => widget_max_min_h(kids, th, 0, n, 0)
			DirColumn => (widget_sum_min_h(kids, th, 0, n, 0) + total_gap)
		})
		Widget.WidgetNode.{ wn_kind: w.wn_kind, wn_id: w.wn_id, wn_children: kids, wn_child_count: n, wn_layout_dir: w.wn_layout_dir, wn_gap: w.wn_gap, wn_flex: w.wn_flex, wn_min_w: BoxModel.box_min(32767, (if widget_is_scroll_view(w) { w.wn_min_w } else { BoxModel.box_max(w.wn_min_w, (inner_w + BoxModel.style_overhead_w(style))) })), wn_min_h: BoxModel.box_min(32767, (if widget_is_scroll_view(w) { w.wn_min_h } else { BoxModel.box_max(w.wn_min_h, (inner_h + BoxModel.style_overhead_h(style))) })), wn_max_w: w.wn_max_w, wn_max_h: w.wn_max_h, wn_fit_w: w.wn_fit_w, wn_pref_w: w.wn_pref_w, wn_pref_h: w.wn_pref_h, wn_align: w.wn_align, wn_flags: w.wn_flags, wn_data: w.wn_data, wn_tone: w.wn_tone, wn_bounds: w.wn_bounds }
	}) })

	widget_measure_children : List(Widget.WidgetNode), Theme.Theme, I64, I64, List(Widget.WidgetNode) -> List(Widget.WidgetNode)
	widget_measure_children = |children, th, i, n, acc| (if (i >= n) { acc } else { widget_measure_children(children, th, (i + 1), n, List.append(acc, widget_measure((List.get(children, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), th))) })

	widget_item_w : Widget.WidgetNode, Theme.Theme -> I64
	widget_item_w = |c, th| ({
		style = widget_resolve_style(c, th)
		(BoxModel.box_max(c.wn_min_w, style.ws_min_width) + Theme.edges_h(style.ws_margin))
	})

	widget_item_h : Widget.WidgetNode, Theme.Theme -> I64
	widget_item_h = |c, th| ({
		style = widget_resolve_style(c, th)
		(BoxModel.box_max(c.wn_min_h, style.ws_min_height) + Theme.edges_v(style.ws_margin))
	})

	widget_sum_min_w : List(Widget.WidgetNode), Theme.Theme, I64, I64, I64 -> I64
	widget_sum_min_w = |kids, th, i, n, acc| (if (i >= n) { acc } else { widget_sum_min_w(kids, th, (i + 1), n, (acc + widget_item_w((List.get(kids, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), th))) })

	widget_sum_min_h : List(Widget.WidgetNode), Theme.Theme, I64, I64, I64 -> I64
	widget_sum_min_h = |kids, th, i, n, acc| (if (i >= n) { acc } else { widget_sum_min_h(kids, th, (i + 1), n, (acc + widget_item_h((List.get(kids, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), th))) })

	widget_max_min_w : List(Widget.WidgetNode), Theme.Theme, I64, I64, I64 -> I64
	widget_max_min_w = |kids, th, i, n, acc| (if (i >= n) { acc } else { widget_max_min_w(kids, th, (i + 1), n, BoxModel.box_max(acc, widget_item_w((List.get(kids, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), th))) })

	widget_max_min_h : List(Widget.WidgetNode), Theme.Theme, I64, I64, I64 -> I64
	widget_max_min_h = |kids, th, i, n, acc| (if (i >= n) { acc } else { widget_max_min_h(kids, th, (i + 1), n, BoxModel.box_max(acc, widget_item_h((List.get(kids, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), th))) })

	widget_layout : Widget.WidgetNode, Theme.Theme, BoxModel.LayoutRect -> Widget.WidgetNode
	widget_layout = |w, th, container| widget_arrange(widget_measure(w, th), th, container)

	widget_arrange : Widget.WidgetNode, Theme.Theme, BoxModel.LayoutRect -> Widget.WidgetNode
	widget_arrange = |w, th, container| ({
		style = widget_resolve_style(w, th)
		content = BoxModel.box_content_from_style(container, style)
		placed = widget_set_bounds(w, container)
		(if (placed.wn_child_count == 0) { placed } else { ({
			items = widget_children_to_items(placed.wn_children, th, 0, placed.wn_child_count, [])
			box = widget_scroll_box(placed, content, items)
			result = Layout.flex_layout(box, placed.wn_layout_dir, placed.wn_gap, items, placed.wn_child_count)
			laid_out = widget_arrange_children(placed.wn_children, th, result.lrs, 0, placed.wn_child_count, [])
			Widget.WidgetNode.{ wn_kind: widget_scroll_kind(placed, content, box), wn_id: placed.wn_id, wn_children: laid_out, wn_child_count: placed.wn_child_count, wn_layout_dir: placed.wn_layout_dir, wn_gap: placed.wn_gap, wn_flex: placed.wn_flex, wn_min_w: placed.wn_min_w, wn_min_h: placed.wn_min_h, wn_max_w: placed.wn_max_w, wn_max_h: placed.wn_max_h, wn_fit_w: placed.wn_fit_w, wn_pref_w: placed.wn_pref_w, wn_pref_h: placed.wn_pref_h, wn_align: placed.wn_align, wn_flags: placed.wn_flags, wn_data: placed.wn_data, wn_tone: w.wn_tone, wn_bounds: container }
		}) })
	})

	widget_scroll_box : Widget.WidgetNode, BoxModel.LayoutRect, List(Layout.LayoutItem) -> BoxModel.LayoutRect
	widget_scroll_box = |w, content, items| (if (widget_is_scroll_view(w) == False) { content } else { ({
		n : I64
		n = w.wn_child_count
		gaps : I64
		gaps = (if (n > 1) { (w.wn_gap * (n - 1)) } else { 0 })
		off : I64
		off = BoxModel.box_clamp0(widget_scroll_offset(w))
		(match w.wn_layout_dir {
			DirColumn => ({
				ext : I64
				ext = BoxModel.box_max(content.lr_h, widget_natural_main(items, DirColumn, 0, n, gaps))
				BoxModel.layout_rect(content.lr_x, (content.lr_y - BoxModel.box_min(off, (ext - content.lr_h))), content.lr_w, ext)
			})
			DirRow => ({
				ext : I64
				ext = BoxModel.box_max(content.lr_w, widget_natural_main(items, DirRow, 0, n, gaps))
				BoxModel.layout_rect((content.lr_x - BoxModel.box_min(off, (ext - content.lr_w))), content.lr_y, ext, content.lr_h)
			})
		})
	}) })

	widget_scroll_kind : Widget.WidgetNode, BoxModel.LayoutRect, BoxModel.LayoutRect -> Widget.WidgetKind
	widget_scroll_kind = |w, content, box| (if (widget_is_scroll_view(w) == False) { w.wn_kind } else { (match w.wn_layout_dir {
		DirColumn => WkScroll((content.lr_y - box.lr_y))
		DirRow => WkScroll((content.lr_x - box.lr_x))
	}) })

	widget_natural_main : List(Layout.LayoutItem), Layout.LayoutDir, I64, I64, I64 -> I64
	widget_natural_main = |items, dir, i, n, acc| (if (i >= n) { acc } else { ({
		item = (List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		margin : I64
		margin = (match dir {
			DirRow => Theme.edges_h(item.li_margin)
			DirColumn => Theme.edges_v(item.li_margin)
		})
		widget_natural_main(items, dir, (i + 1), n, ((acc + BoxModel.box_max(Layout.flex_main_min(item, dir), Layout.flex_basis(item, dir))) + margin))
	}) })

	widget_children_to_items : List(Widget.WidgetNode), Theme.Theme, I64, I64, List(Layout.LayoutItem) -> List(Layout.LayoutItem)
	widget_children_to_items = |children, th, i, n, acc| (if (i >= n) { acc } else { ({
		child = (List.get(children, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		style = widget_resolve_style(child, th)
		item = Layout.layout_item_align(Layout.layout_item_full(BoxModel.box_max(child.wn_min_w, style.ws_min_width), BoxModel.box_max(child.wn_min_h, style.ws_min_height), child.wn_flex, style.ws_margin, child.wn_max_w, child.wn_max_h, child.wn_pref_w, child.wn_pref_h), child.wn_align)
		widget_children_to_items(children, th, (i + 1), n, List.append(acc, item))
	}) })

	widget_arrange_children : List(Widget.WidgetNode), Theme.Theme, List(BoxModel.LayoutRect), I64, I64, List(Widget.WidgetNode) -> List(Widget.WidgetNode)
	widget_arrange_children = |children, th, rects, i, n, acc| (if (i >= n) { acc } else { ({
		child = (List.get(children, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		r = (List.get(rects, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		laid_out = widget_arrange(child, th, r)
		widget_arrange_children(children, th, rects, (i + 1), n, List.append(acc, laid_out))
	}) })

	widget_resolve_style : Widget.WidgetNode, Theme.Theme -> Theme.WidgetStyle
	widget_resolve_style = |w, th| (match w.wn_kind {
		WkPanel => Theme.theme_resolve_panel(th, widget_state_of(w))
		WkStack => Theme.widget_style_bare
		WkScroll(_off) => Theme.widget_style_bare
		WkLabel(_t) => Theme.theme_resolve_label(th, widget_state_of(w))
		WkButton(_t) => Theme.theme_resolve_button(th, widget_state_of(w))
		WkGauge(_v, _m) => Theme.theme_resolve_gauge(th, widget_state_of(w))
		WkSeparator => Theme.theme_resolve_separator(th, widget_state_of(w))
		WkInput(_t, _c) => Theme.theme_resolve_input(th, widget_state_of(w))
		WkCustom(tag) => (if (tag == wk_spacer_tag) { Theme.widget_style_bare } else { Theme.theme_resolve_panel(th, widget_state_of(w)) })
	})

	eq_WidgetKind : Widget.WidgetKind, Widget.WidgetKind -> Bool
	eq_WidgetKind = |ex, ey| (match ex {
		WkPanel => (match ey {
			WkPanel => True
			_ => False
		})
		WkStack => (match ey {
			WkStack => True
			_ => False
		})
		WkScroll(exf0) => (match ey {
			WkScroll(eyf0) => (exf0 == eyf0)
			_ => False
		})
		WkLabel(exf0) => (match ey {
			WkLabel(eyf0) => (exf0 == eyf0)
			_ => False
		})
		WkButton(exf0) => (match ey {
			WkButton(eyf0) => (exf0 == eyf0)
			_ => False
		})
		WkGauge(exf0, exf1) => (match ey {
			WkGauge(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
			_ => False
		})
		WkSeparator => (match ey {
			WkSeparator => True
			_ => False
		})
		WkInput(exf0, exf1) => (match ey {
			WkInput(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
			_ => False
		})
		WkCustom(exf0) => (match ey {
			WkCustom(eyf0) => (exf0 == eyf0)
			_ => False
		})
	})

	eq_WidgetNode : Widget.WidgetNode, Widget.WidgetNode -> Bool
	eq_WidgetNode = |ex, ey| ((((((((((((((((((eq_WidgetKind(ex.wn_kind, ey.wn_kind) and (ex.wn_id == ey.wn_id)) and (ex.wn_children == ey.wn_children)) and (ex.wn_child_count == ey.wn_child_count)) and Layout.eq_LayoutDir(ex.wn_layout_dir, ey.wn_layout_dir)) and (ex.wn_gap == ey.wn_gap)) and (ex.wn_flex == ey.wn_flex)) and (ex.wn_min_w == ey.wn_min_w)) and (ex.wn_min_h == ey.wn_min_h)) and (ex.wn_max_w == ey.wn_max_w)) and (ex.wn_max_h == ey.wn_max_h)) and (ex.wn_fit_w == ey.wn_fit_w)) and (ex.wn_pref_w == ey.wn_pref_w)) and (ex.wn_pref_h == ey.wn_pref_h)) and (ex.wn_align == ey.wn_align)) and (ex.wn_flags == ey.wn_flags)) and (ex.wn_data == ey.wn_data)) and (ex.wn_tone == ey.wn_tone)) and BoxModel.eq_LayoutRect(ex.wn_bounds, ey.wn_bounds))
}
