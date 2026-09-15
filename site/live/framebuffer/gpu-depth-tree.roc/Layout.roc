# Layout -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import BoxModel
import Theme

Layout :: [].{
	LayoutDir : [DirRow, DirColumn]
	LayoutItem : { li_min_w : I64, li_min_h : I64, li_flex : I64, li_margin : Theme.Edges }
	LayoutResult : { lrs : List(BoxModel.LayoutRect), lr_count : I64 }
	GridLayout : { gl_columns : I64, gl_row_gap : I64, gl_col_gap : I64 }
	SplitLayout : { sl_ratio : I64, sl_direction : Layout.LayoutDir, sl_gap : I64 }

	layout_item : I64, I64, I64 -> Layout.LayoutItem
	layout_item = |minw, minh, flex| { li_min_w: minw, li_min_h: minh, li_flex: flex, li_margin: Theme.edges_zero }

	layout_item_m : I64, I64, I64, Theme.Edges -> Layout.LayoutItem
	layout_item_m = |minw, minh, flex, margin| { li_min_w: minw, li_min_h: minh, li_flex: flex, li_margin: margin }

	flex_layout : BoxModel.LayoutRect, Layout.LayoutDir, I64, List(Layout.LayoutItem), I64 -> Layout.LayoutResult
	flex_layout = |container, dir, gap, items, count| (match dir {
		DirRow => flex_row(container, gap, items, count)
		DirColumn => flex_col(container, gap, items, count)
	})

	flex_row : BoxModel.LayoutRect, I64, List(Layout.LayoutItem), I64 -> Layout.LayoutResult
	flex_row = |container, gap, items, count| ({
		total_gap = (if (count > 1) { (gap * (count - 1)) } else { 0 })
		fixed = flex_sum_fixed_w(items, 0, count, 0)
		total_flex = flex_sum_flex(items, 0, count, 0)
		avail = BoxModel.box_clamp0(((container.lr_w - total_gap) - fixed))
		flex_row_place(container, gap, items, count, total_flex, avail, 0, container.lr_x, [])
	})

	flex_row_place : BoxModel.LayoutRect, I64, List(Layout.LayoutItem), I64, I64, I64, I64, I64, List(BoxModel.LayoutRect) -> Layout.LayoutResult
	flex_row_place = |container, gap, items, count, total_flex, avail, i, cursor, acc| (if (i >= count) { { lrs: acc, lr_count: count } } else { ({
		item = (List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		mw = (item.li_min_w + Theme.edges_h(item.li_margin))
		w = (if (item.li_flex > 0) { (if (total_flex > 0) { BoxModel.box_max(mw, I64.div_trunc_by((item.li_flex * avail), total_flex)) } else { mw }) } else { mw })
		h = BoxModel.box_max((item.li_min_h + Theme.edges_v(item.li_margin)), container.lr_h)
		r = BoxModel.box_margin_rect(BoxModel.layout_rect(cursor, container.lr_y, w, h), item.li_margin)
		next = ((cursor + w) + gap)
		flex_row_place(container, gap, items, count, total_flex, avail, (i + 1), next, List.append(acc, r))
	}) })

	flex_col : BoxModel.LayoutRect, I64, List(Layout.LayoutItem), I64 -> Layout.LayoutResult
	flex_col = |container, gap, items, count| ({
		total_gap = (if (count > 1) { (gap * (count - 1)) } else { 0 })
		fixed = flex_sum_fixed_h(items, 0, count, 0)
		total_flex = flex_sum_flex(items, 0, count, 0)
		avail = BoxModel.box_clamp0(((container.lr_h - total_gap) - fixed))
		flex_col_place(container, gap, items, count, total_flex, avail, 0, container.lr_y, [])
	})

	flex_col_place : BoxModel.LayoutRect, I64, List(Layout.LayoutItem), I64, I64, I64, I64, I64, List(BoxModel.LayoutRect) -> Layout.LayoutResult
	flex_col_place = |container, gap, items, count, total_flex, avail, i, cursor, acc| (if (i >= count) { { lrs: acc, lr_count: count } } else { ({
		item = (List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		mh = (item.li_min_h + Theme.edges_v(item.li_margin))
		h = (if (item.li_flex > 0) { (if (total_flex > 0) { BoxModel.box_max(mh, I64.div_trunc_by((item.li_flex * avail), total_flex)) } else { mh }) } else { mh })
		w = BoxModel.box_max((item.li_min_w + Theme.edges_h(item.li_margin)), container.lr_w)
		r = BoxModel.box_margin_rect(BoxModel.layout_rect(container.lr_x, cursor, w, h), item.li_margin)
		next = ((cursor + h) + gap)
		flex_col_place(container, gap, items, count, total_flex, avail, (i + 1), next, List.append(acc, r))
	}) })

	flex_sum_fixed_w : List(Layout.LayoutItem), I64, I64, I64 -> I64
	flex_sum_fixed_w = |items, i, n, acc| (if (i >= n) { acc } else { ({
		item = (List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		add = (if (item.li_flex > 0) { 0 } else { (item.li_min_w + Theme.edges_h(item.li_margin)) })
		flex_sum_fixed_w(items, (i + 1), n, (acc + add))
	}) })

	flex_sum_fixed_h : List(Layout.LayoutItem), I64, I64, I64 -> I64
	flex_sum_fixed_h = |items, i, n, acc| (if (i >= n) { acc } else { ({
		item = (List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		add = (if (item.li_flex > 0) { 0 } else { (item.li_min_h + Theme.edges_v(item.li_margin)) })
		flex_sum_fixed_h(items, (i + 1), n, (acc + add))
	}) })

	flex_sum_flex : List(Layout.LayoutItem), I64, I64, I64 -> I64
	flex_sum_flex = |items, i, n, acc| (if (i >= n) { acc } else { ({
		item = (List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		flex_sum_flex(items, (i + 1), n, (acc + item.li_flex))
	}) })

	grid_layout : I64, I64, I64 -> Layout.GridLayout
	grid_layout = |cols, row_gap, col_gap| { gl_columns: cols, gl_row_gap: row_gap, gl_col_gap: col_gap }

	grid_cell_rect : Layout.GridLayout, I64, I64, I64, I64 -> BoxModel.LayoutRect
	grid_cell_rect = |g, index, total_w, total_h, count| ({
		col = (index - (I64.div_trunc_by(index, g.gl_columns) * g.gl_columns))
		row = I64.div_trunc_by(index, g.gl_columns)
		rows = I64.div_trunc_by(((count + g.gl_columns) - 1), g.gl_columns)
		cell_w = I64.div_trunc_by((total_w - ((g.gl_columns - 1) * g.gl_col_gap)), g.gl_columns)
		cell_h = I64.div_trunc_by((total_h - ((rows - 1) * g.gl_row_gap)), rows)
		{ lr_x: (col * (cell_w + g.gl_col_gap)), lr_y: (row * (cell_h + g.gl_row_gap)), lr_w: cell_w, lr_h: cell_h }
	})

	stack_layout : List(BoxModel.LayoutRect), BoxModel.LayoutRect -> List(BoxModel.LayoutRect)
	stack_layout = |children, bounds| stack_loop(children, bounds, 0, U64.to_i64_wrap(List.len(children)), [])

	stack_loop : List(BoxModel.LayoutRect), BoxModel.LayoutRect, I64, I64, List(BoxModel.LayoutRect) -> List(BoxModel.LayoutRect)
	stack_loop = |children, bounds, i, len, acc| (if (i >= len) { acc } else { stack_loop(children, bounds, (i + 1), len, List.append(acc, bounds)) })

	split_layout : Layout.LayoutDir, I64, I64 -> Layout.SplitLayout
	split_layout = |dir, ratio, gap| { sl_ratio: ratio, sl_direction: dir, sl_gap: gap }

	split_first : Layout.SplitLayout, BoxModel.LayoutRect -> BoxModel.LayoutRect
	split_first = |s, bounds| (match s.sl_direction {
		DirRow => ({
			w = (I64.div_trunc_by((bounds.lr_w * s.sl_ratio), 1000) - I64.div_trunc_by(s.sl_gap, 2))
			{ lr_x: bounds.lr_x, lr_y: bounds.lr_y, lr_w: w, lr_h: bounds.lr_h }
		})
		DirColumn => ({
			h = (I64.div_trunc_by((bounds.lr_h * s.sl_ratio), 1000) - I64.div_trunc_by(s.sl_gap, 2))
			{ lr_x: bounds.lr_x, lr_y: bounds.lr_y, lr_w: bounds.lr_w, lr_h: h }
		})
	})

	split_second : Layout.SplitLayout, BoxModel.LayoutRect -> BoxModel.LayoutRect
	split_second = |s, bounds| (match s.sl_direction {
		DirRow => ({
			first_w = (I64.div_trunc_by((bounds.lr_w * s.sl_ratio), 1000) + I64.div_trunc_by(s.sl_gap, 2))
			{ lr_x: (bounds.lr_x + first_w), lr_y: bounds.lr_y, lr_w: (bounds.lr_w - first_w), lr_h: bounds.lr_h }
		})
		DirColumn => ({
			first_h = (I64.div_trunc_by((bounds.lr_h * s.sl_ratio), 1000) + I64.div_trunc_by(s.sl_gap, 2))
			{ lr_x: bounds.lr_x, lr_y: (bounds.lr_y + first_h), lr_w: bounds.lr_w, lr_h: (bounds.lr_h - first_h) }
		})
	})

	eq_LayoutDir : Layout.LayoutDir, Layout.LayoutDir -> Bool
	eq_LayoutDir = |ex, ey| (match ex {
		DirRow => (match ey {
			DirRow => True
			_ => False
		})
		DirColumn => (match ey {
			DirColumn => True
			_ => False
		})
	})
}
