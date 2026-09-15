# Widget -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import BoxModel
import Cce
import Layout
import Maybe
import Theme

Widget :: [].{
	WidgetKind : [WkPanel, WkLabel(Str), WkButton(Str), WkGauge(I64, I64), WkSeparator, WkInput(Str, I64), WkCustom(Str)]
	WidgetNode := { wn_kind : Widget.WidgetKind, wn_state : I64, wn_id : Str, wn_children : List(Widget.WidgetNode), wn_child_count : I64, wn_layout_dir : Layout.LayoutDir, wn_gap : I64, wn_flex : I64, wn_min_w : I64, wn_min_h : I64, wn_tone : I64, wn_bounds : BoxModel.LayoutRect }.{
		is_eq : Widget.WidgetNode, Widget.WidgetNode -> Bool
		is_eq = |a, b| a.wn_kind == b.wn_kind and a.wn_state == b.wn_state and a.wn_id == b.wn_id and a.wn_children == b.wn_children and a.wn_child_count == b.wn_child_count and a.wn_layout_dir == b.wn_layout_dir and a.wn_gap == b.wn_gap and a.wn_flex == b.wn_flex and a.wn_min_w == b.wn_min_w and a.wn_min_h == b.wn_min_h and a.wn_tone == b.wn_tone and a.wn_bounds == b.wn_bounds
	}

	widget_panel : Str, Layout.LayoutDir, I64, List(Widget.WidgetNode) -> Widget.WidgetNode
	widget_panel = |id, dir, gap, children| { wn_kind: WkPanel, wn_state: Theme.state_normal, wn_id: id, wn_children: children, wn_child_count: U64.to_i64_wrap(List.len(children)), wn_layout_dir: dir, wn_gap: gap, wn_flex: 1, wn_min_w: 0, wn_min_h: 0, wn_tone: Theme.tone_none, wn_bounds: BoxModel.layout_rect_zero }

	wk_scroll_view_tag : Str
	wk_scroll_view_tag = "scroll-view"

	widget_scroll_view : Str, Layout.LayoutDir, I64, List(Widget.WidgetNode) -> Widget.WidgetNode
	widget_scroll_view = |id, dir, gap, children| { wn_kind: WkCustom(wk_scroll_view_tag), wn_state: Theme.state_normal, wn_id: id, wn_children: children, wn_child_count: U64.to_i64_wrap(List.len(children)), wn_layout_dir: dir, wn_gap: gap, wn_flex: 1, wn_min_w: 0, wn_min_h: 0, wn_tone: Theme.tone_none, wn_bounds: BoxModel.layout_rect_zero }

	wk_spacer_tag : Str
	wk_spacer_tag = "spacer"

	widget_spacer : Str -> Widget.WidgetNode
	widget_spacer = |id| { wn_kind: WkCustom(wk_spacer_tag), wn_state: Theme.state_normal, wn_id: id, wn_children: [], wn_child_count: 0, wn_layout_dir: DirColumn, wn_gap: 0, wn_flex: 1, wn_min_w: 0, wn_min_h: 0, wn_tone: Theme.tone_none, wn_bounds: BoxModel.layout_rect_zero }

	widget_is_scroll_view : Widget.WidgetNode -> Bool
	widget_is_scroll_view = |w| (match w.wn_kind {
		WkCustom(tag) => (tag == wk_scroll_view_tag)
		_ => False
	})

	widget_label : Str, Str -> Widget.WidgetNode
	widget_label = |id, txt| { wn_kind: WkLabel(txt), wn_state: Theme.state_normal, wn_id: id, wn_children: [], wn_child_count: 0, wn_layout_dir: DirRow, wn_gap: 0, wn_flex: 0, wn_min_w: (Cce.length(txt) * 8), wn_min_h: 16, wn_tone: Theme.tone_none, wn_bounds: BoxModel.layout_rect_zero }

	widget_button : Str, Str -> Widget.WidgetNode
	widget_button = |id, txt| { wn_kind: WkButton(txt), wn_state: Theme.state_normal, wn_id: id, wn_children: [], wn_child_count: 0, wn_layout_dir: DirRow, wn_gap: 0, wn_flex: 0, wn_min_w: ((Cce.length(txt) * 8) + 16), wn_min_h: 24, wn_tone: Theme.tone_none, wn_bounds: BoxModel.layout_rect_zero }

	widget_gauge : Str, I64, I64 -> Widget.WidgetNode
	widget_gauge = |id, value, max_val| { wn_kind: WkGauge(value, max_val), wn_state: Theme.state_normal, wn_id: id, wn_children: [], wn_child_count: 0, wn_layout_dir: DirRow, wn_gap: 0, wn_flex: 1, wn_min_w: 60, wn_min_h: 16, wn_tone: Theme.tone_none, wn_bounds: BoxModel.layout_rect_zero }

	widget_separator : Str -> Widget.WidgetNode
	widget_separator = |id| { wn_kind: WkSeparator, wn_state: Theme.state_normal, wn_id: id, wn_children: [], wn_child_count: 0, wn_layout_dir: DirRow, wn_gap: 0, wn_flex: 0, wn_min_w: 0, wn_min_h: 2, wn_tone: Theme.tone_none, wn_bounds: BoxModel.layout_rect_zero }

	widget_input : Str, Str, I64 -> Widget.WidgetNode
	widget_input = |id, txt, cursor| { wn_kind: WkInput(txt, cursor), wn_state: Theme.state_normal, wn_id: id, wn_children: [], wn_child_count: 0, wn_layout_dir: DirRow, wn_gap: 0, wn_flex: 1, wn_min_w: 80, wn_min_h: 24, wn_tone: Theme.tone_none, wn_bounds: BoxModel.layout_rect_zero }

	widget_custom : Str, Str, I64, I64 -> Widget.WidgetNode
	widget_custom = |id, tag, w, h| { wn_kind: WkCustom(tag), wn_state: Theme.state_normal, wn_id: id, wn_children: [], wn_child_count: 0, wn_layout_dir: DirRow, wn_gap: 0, wn_flex: 0, wn_min_w: w, wn_min_h: h, wn_tone: Theme.tone_none, wn_bounds: BoxModel.layout_rect_zero }

	widget_set_state : Widget.WidgetNode, I64 -> Widget.WidgetNode
	widget_set_state = |w, s| { wn_kind: w.wn_kind, wn_state: s, wn_id: w.wn_id, wn_children: w.wn_children, wn_child_count: w.wn_child_count, wn_layout_dir: w.wn_layout_dir, wn_gap: w.wn_gap, wn_flex: w.wn_flex, wn_min_w: w.wn_min_w, wn_min_h: w.wn_min_h, wn_tone: w.wn_tone, wn_bounds: w.wn_bounds }

	widget_set_flex : Widget.WidgetNode, I64 -> Widget.WidgetNode
	widget_set_flex = |w, f| { wn_kind: w.wn_kind, wn_state: w.wn_state, wn_id: w.wn_id, wn_children: w.wn_children, wn_child_count: w.wn_child_count, wn_layout_dir: w.wn_layout_dir, wn_gap: w.wn_gap, wn_flex: f, wn_min_w: w.wn_min_w, wn_min_h: w.wn_min_h, wn_tone: w.wn_tone, wn_bounds: w.wn_bounds }

	widget_set_min : Widget.WidgetNode, I64, I64 -> Widget.WidgetNode
	widget_set_min = |w, minw, minh| { wn_kind: w.wn_kind, wn_state: w.wn_state, wn_id: w.wn_id, wn_children: w.wn_children, wn_child_count: w.wn_child_count, wn_layout_dir: w.wn_layout_dir, wn_gap: w.wn_gap, wn_flex: w.wn_flex, wn_min_w: minw, wn_min_h: minh, wn_tone: w.wn_tone, wn_bounds: w.wn_bounds }

	widget_fixed : Widget.WidgetNode, I64, I64 -> Widget.WidgetNode
	widget_fixed = |w, minw, minh| widget_set_flex(widget_set_min(w, minw, minh), 0)

	widget_set_tone : Widget.WidgetNode, I64 -> Widget.WidgetNode
	widget_set_tone = |w, tone| { wn_kind: w.wn_kind, wn_state: w.wn_state, wn_id: w.wn_id, wn_children: w.wn_children, wn_child_count: w.wn_child_count, wn_layout_dir: w.wn_layout_dir, wn_gap: w.wn_gap, wn_flex: w.wn_flex, wn_min_w: w.wn_min_w, wn_min_h: w.wn_min_h, wn_tone: tone, wn_bounds: w.wn_bounds }

	widget_set_bounds : Widget.WidgetNode, BoxModel.LayoutRect -> Widget.WidgetNode
	widget_set_bounds = |w, r| { wn_kind: w.wn_kind, wn_state: w.wn_state, wn_id: w.wn_id, wn_children: w.wn_children, wn_child_count: w.wn_child_count, wn_layout_dir: w.wn_layout_dir, wn_gap: w.wn_gap, wn_flex: w.wn_flex, wn_min_w: w.wn_min_w, wn_min_h: w.wn_min_h, wn_tone: w.wn_tone, wn_bounds: r }

	widget_set_children : Widget.WidgetNode, List(Widget.WidgetNode) -> Widget.WidgetNode
	widget_set_children = |w, kids| { wn_kind: w.wn_kind, wn_state: w.wn_state, wn_id: w.wn_id, wn_children: kids, wn_child_count: U64.to_i64_wrap(List.len(kids)), wn_layout_dir: w.wn_layout_dir, wn_gap: w.wn_gap, wn_flex: w.wn_flex, wn_min_w: w.wn_min_w, wn_min_h: w.wn_min_h, wn_tone: w.wn_tone, wn_bounds: w.wn_bounds }

	widget_add_child : Widget.WidgetNode, Widget.WidgetNode -> Widget.WidgetNode
	widget_add_child = |parent, child| { wn_kind: parent.wn_kind, wn_state: parent.wn_state, wn_id: parent.wn_id, wn_children: List.append(parent.wn_children, child), wn_child_count: (parent.wn_child_count + 1), wn_layout_dir: parent.wn_layout_dir, wn_gap: parent.wn_gap, wn_flex: parent.wn_flex, wn_min_w: parent.wn_min_w, wn_min_h: parent.wn_min_h, wn_tone: parent.wn_tone, wn_bounds: parent.wn_bounds }

	widget_kind_name : Widget.WidgetKind -> Str
	widget_kind_name = |k| (match k {
		WkPanel => "panel"
		WkLabel(_t) => "label"
		WkButton(_t) => "button"
		WkGauge(_v, _m) => "gauge"
		WkSeparator => "separator"
		WkInput(_t, _c) => "input"
		WkCustom(tag) => tag
	})

	widget_is_leaf : Widget.WidgetNode -> Bool
	widget_is_leaf = |w| (w.wn_child_count == 0)

	widget_find : Widget.WidgetNode, Str -> Maybe.Maybe(Widget.WidgetNode)
	widget_find = |w, target| (if (w.wn_id == target) { Just(w) } else { widget_find_children(w.wn_children, target, 0, w.wn_child_count) })

	widget_find_children : List(Widget.WidgetNode), Str, I64, I64 -> Maybe.Maybe(Widget.WidgetNode)
	widget_find_children = |children, target, i, n| (if (i >= n) { None } else { ({
		result = widget_find((List.get(children, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), target)
		(match result {
			Just(found) => Just(found)
			None => widget_find_children(children, target, (i + 1), n)
		})
	}) })

	widget_measure : Widget.WidgetNode, Theme.Theme -> Widget.WidgetNode
	widget_measure = |w, th| (if (w.wn_child_count == 0) { w } else { ({
		kids = widget_measure_children(w.wn_children, th, 0, w.wn_child_count, [])
		style = widget_resolve_style(w, th)
		n = w.wn_child_count
		total_gap = (if (n > 1) { (w.wn_gap * (n - 1)) } else { 0 })
		inner_w = (match w.wn_layout_dir {
			DirRow => (widget_sum_min_w(kids, th, 0, n, 0) + total_gap)
			DirColumn => widget_max_min_w(kids, th, 0, n, 0)
		})
		inner_h = (match w.wn_layout_dir {
			DirRow => widget_max_min_h(kids, th, 0, n, 0)
			DirColumn => (widget_sum_min_h(kids, th, 0, n, 0) + total_gap)
		})
		{ wn_kind: w.wn_kind, wn_state: w.wn_state, wn_id: w.wn_id, wn_children: kids, wn_child_count: n, wn_layout_dir: w.wn_layout_dir, wn_gap: w.wn_gap, wn_flex: w.wn_flex, wn_min_w: BoxModel.box_min(32767, (if widget_is_scroll_view(w) { w.wn_min_w } else { BoxModel.box_max(w.wn_min_w, (inner_w + BoxModel.style_overhead_w(style))) })), wn_min_h: BoxModel.box_min(32767, (if widget_is_scroll_view(w) { w.wn_min_h } else { BoxModel.box_max(w.wn_min_h, (inner_h + BoxModel.style_overhead_h(style))) })), wn_tone: w.wn_tone, wn_bounds: w.wn_bounds }
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
			result = Layout.flex_layout(content, placed.wn_layout_dir, placed.wn_gap, items, placed.wn_child_count)
			laid_out = widget_arrange_children(placed.wn_children, th, result.lrs, 0, placed.wn_child_count, [])
			{ wn_kind: placed.wn_kind, wn_state: placed.wn_state, wn_id: placed.wn_id, wn_children: laid_out, wn_child_count: placed.wn_child_count, wn_layout_dir: placed.wn_layout_dir, wn_gap: placed.wn_gap, wn_flex: placed.wn_flex, wn_min_w: placed.wn_min_w, wn_min_h: placed.wn_min_h, wn_tone: w.wn_tone, wn_bounds: container }
		}) })
	})

	widget_children_to_items : List(Widget.WidgetNode), Theme.Theme, I64, I64, List(Layout.LayoutItem) -> List(Layout.LayoutItem)
	widget_children_to_items = |children, th, i, n, acc| (if (i >= n) { acc } else { ({
		child = (List.get(children, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		style = widget_resolve_style(child, th)
		item = Layout.layout_item_m(BoxModel.box_max(child.wn_min_w, style.ws_min_width), BoxModel.box_max(child.wn_min_h, style.ws_min_height), child.wn_flex, style.ws_margin)
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
		WkPanel => Theme.theme_resolve_panel(th, w.wn_state)
		WkLabel(_t) => Theme.theme_resolve_label(th, w.wn_state)
		WkButton(_t) => Theme.theme_resolve_button(th, w.wn_state)
		WkGauge(_v, _m) => Theme.theme_resolve_gauge(th, w.wn_state)
		WkSeparator => Theme.theme_resolve_separator(th, w.wn_state)
		WkInput(_t, _c) => Theme.theme_resolve_input(th, w.wn_state)
		WkCustom(tag) => (if ((tag == wk_scroll_view_tag) or (tag == wk_spacer_tag)) { Theme.widget_style_bare } else { Theme.theme_resolve_panel(th, w.wn_state) })
	})

	format_widget : Widget.WidgetNode -> Str
	format_widget = |w| Str.concat(Str.concat(Str.concat(Str.concat(widget_kind_name(w.wn_kind), "["), w.wn_id), "]"), BoxModel.format_rect(w.wn_bounds))

	format_widget_tree : Widget.WidgetNode, I64 -> Str
	format_widget_tree = |w, depth| ({
		indent = fmt_indent(depth)
		line = Str.concat(indent, format_widget(w))
		(if (w.wn_child_count == 0) { line } else { Str.concat(Str.concat(line, "\n"), fmt_children(w.wn_children, depth, 0, w.wn_child_count)) })
	})

	fmt_children : List(Widget.WidgetNode), I64, I64, I64 -> Str
	fmt_children = |children, depth, i, n| (if (i >= n) { "" } else { ({
		child = format_widget_tree((List.get(children, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), (depth + 1))
		sep = (if ((i + 1) < n) { "\n" } else { "" })
		Str.concat(Str.concat(child, sep), fmt_children(children, depth, (i + 1), n))
	}) })

	fmt_indent : I64 -> Str
	fmt_indent = |n| (if (n <= 0) { "" } else { Str.concat("  ", fmt_indent((n - 1))) })

	widget_checkbox : Str, Bool -> Widget.WidgetNode
	widget_checkbox = |id, checked| ({
		label = (if checked { "[x]" } else { "[ ]" })
		widget_button(id, label)
	})

	widget_radio : Str, Bool -> Widget.WidgetNode
	widget_radio = |id, selected| ({
		label = (if selected { "(o)" } else { "( )" })
		widget_button(id, label)
	})

	widget_slider : Str, I64, I64, I64 -> Widget.WidgetNode
	widget_slider = |id, value, lo, hi| widget_gauge(id, (value - lo), (hi - lo))

	widget_progress : Str, I64, I64 -> Widget.WidgetNode
	widget_progress = |id, value, max_val| widget_gauge(id, value, max_val)

	widget_dropdown : Str, Str, List(Str) -> Widget.WidgetNode
	widget_dropdown = |id, selected, _options| ({
		panel = widget_panel(id, DirColumn, 0, [])
		widget_add_child(panel, widget_label(Str.concat(id, "-sel"), selected))
	})

	widget_toolbar : Str, List(Widget.WidgetNode) -> Widget.WidgetNode
	widget_toolbar = |id, buttons| widget_panel(id, DirRow, 4, buttons)

	widget_menu : Str, List(Str) -> Widget.WidgetNode
	widget_menu = |id, items| ({
		children = wk_menu_items(id, items, 0, U64.to_i64_wrap(List.len(items)), [])
		widget_panel(id, DirColumn, 0, children)
	})

	wk_menu_items : Str, List(Str), I64, I64, List(Widget.WidgetNode) -> List(Widget.WidgetNode)
	wk_menu_items = |id, items, i, len, acc| (if (i >= len) { acc } else { ({
		item = widget_button(Str.concat(Str.concat(id, "-"), I64.to_str(i)), (List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))
		wk_menu_items(id, items, (i + 1), len, List.append(acc, item))
	}) })

	widget_tabs : Str, List(Str), I64 -> Widget.WidgetNode
	widget_tabs = |id, labels, selected| ({
		tabs = wk_tab_buttons(id, labels, selected, 0, U64.to_i64_wrap(List.len(labels)), [])
		widget_panel(id, DirRow, 0, tabs)
	})

	wk_tab_buttons : Str, List(Str), I64, I64, I64, List(Widget.WidgetNode) -> List(Widget.WidgetNode)
	wk_tab_buttons = |id, labels, sel, i, len, acc| (if (i >= len) { acc } else { ({
		label = (List.get(labels, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		btn = widget_button(Str.concat(Str.concat(id, "-tab-"), I64.to_str(i)), (if (i == sel) { Str.concat(Str.concat("[", label), "]") } else { label }))
		wk_tab_buttons(id, labels, sel, (i + 1), len, List.append(acc, btn))
	}) })

	widget_list_view : Str, List(Str) -> Widget.WidgetNode
	widget_list_view = |id, items| ({
		children = wk_list_items(id, items, 0, U64.to_i64_wrap(List.len(items)), [])
		widget_panel(id, DirColumn, 2, children)
	})

	wk_list_items : Str, List(Str), I64, I64, List(Widget.WidgetNode) -> List(Widget.WidgetNode)
	wk_list_items = |id, items, i, len, acc| (if (i >= len) { acc } else { wk_list_items(id, items, (i + 1), len, List.append(acc, widget_label(Str.concat(Str.concat(id, "-"), I64.to_str(i)), (List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	widget_number_field : Str, I64 -> Widget.WidgetNode
	widget_number_field = |id, value| widget_input(id, I64.to_str(value), Cce.length(I64.to_str(value)))

	widget_text_area : Str, Str -> Widget.WidgetNode
	widget_text_area = |id, content| widget_input(id, content, Cce.length(content))

	eq_WidgetKind : Widget.WidgetKind, Widget.WidgetKind -> Bool
	eq_WidgetKind = |ex, ey| (match ex {
		WkPanel => (match ey {
			WkPanel => True
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
}
