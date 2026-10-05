# Layout -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import BoxModel
import Theme

Layout :: [].{
	LayoutDir : [DirRow, DirColumn]
	LayoutItem := { li_min_w : I64, li_min_h : I64, li_flex : I64, li_margin : Theme.Edges, li_max_w : I64, li_max_h : I64, li_pref_w : I64, li_pref_h : I64, li_align : I64 }.{
		is_eq : Layout.LayoutItem, Layout.LayoutItem -> Bool
		is_eq = |a, b| eq_LayoutItem(a, b)
	}
	LayoutResult := { lrs : List(BoxModel.LayoutRect), lr_count : I64, lr_used_w : I64, lr_used_h : I64 }.{
		is_eq : Layout.LayoutResult, Layout.LayoutResult -> Bool
		is_eq = |a, b| eq_LayoutResult(a, b)
	}
	FlexBudget := { fb_space : I64, fb_weight : I64 }.{
		is_eq : Layout.FlexBudget, Layout.FlexBudget -> Bool
		is_eq = |a, b| eq_FlexBudget(a, b)
	}
	FlexPlan := { fp_excess : I64, fp_d : I64, fp_room : I64 }.{
		is_eq : Layout.FlexPlan, Layout.FlexPlan -> Bool
		is_eq = |a, b| eq_FlexPlan(a, b)
	}
	FlexStep := { fs_size : I64, fs_used : I64, fs_cum : I64 }.{
		is_eq : Layout.FlexStep, Layout.FlexStep -> Bool
		is_eq = |a, b| eq_FlexStep(a, b)
	}
	GridLayout := { gl_columns : I64, gl_row_gap : I64, gl_col_gap : I64 }.{
		is_eq : Layout.GridLayout, Layout.GridLayout -> Bool
		is_eq = |a, b| eq_GridLayout(a, b)
	}
	SplitLayout := { sl_ratio : I64, sl_direction : Layout.LayoutDir, sl_gap : I64 }.{
		is_eq : Layout.SplitLayout, Layout.SplitLayout -> Bool
		is_eq = |a, b| eq_SplitLayout(a, b)
	}

	layout_item_full : I64, I64, I64, Theme.Edges, I64, I64, I64, I64 -> Layout.LayoutItem
	layout_item_full = |minw, minh, flex, margin, maxw, maxh, prefw, prefh| Layout.LayoutItem.{ li_min_w: minw, li_min_h: minh, li_flex: flex, li_margin: margin, li_max_w: maxw, li_max_h: maxh, li_pref_w: prefw, li_pref_h: prefh, li_align: 0 }

	align_stretch : I64
	align_stretch = 0

	align_center : I64
	align_center = 2

	align_end : I64
	align_end = 3

	layout_item_align : Layout.LayoutItem, I64 -> Layout.LayoutItem
	layout_item_align = |item, a| Layout.LayoutItem.{ li_min_w: item.li_min_w, li_min_h: item.li_min_h, li_flex: item.li_flex, li_margin: item.li_margin, li_max_w: item.li_max_w, li_max_h: item.li_max_h, li_pref_w: item.li_pref_w, li_pref_h: item.li_pref_h, li_align: a }

	flex_cross_len : Layout.LayoutItem, I64, I64, I64, I64, I64 -> I64
	flex_cross_len = |item, lo, hi, pref, margin, extent| (if (item.li_align == align_stretch) { flex_cross_size(lo, hi, margin, extent) } else { ({
		own : I64
		own = BoxModel.box_max(lo, pref)
		((if (hi > 0) { BoxModel.box_min(own, BoxModel.box_max(hi, lo)) } else { own }) + margin)
	}) })

	flex_cross_off : Layout.LayoutItem, I64, I64 -> I64
	flex_cross_off = |item, len, extent| (if (item.li_align == align_center) { BoxModel.box_clamp0(I64.div_trunc_by((extent - len), 2)) } else { (if (item.li_align == align_end) { BoxModel.box_clamp0((extent - len)) } else { 0 }) })

	flex_layout : BoxModel.LayoutRect, Layout.LayoutDir, I64, List(Layout.LayoutItem), I64 -> Layout.LayoutResult
	flex_layout = |container, dir, gap, items, count| (match dir {
		DirRow => flex_row(container, gap, items, count)
		DirColumn => flex_col(container, gap, items, count)
	})

	flex_row : BoxModel.LayoutRect, I64, List(Layout.LayoutItem), I64 -> Layout.LayoutResult
	flex_row = |container, gap, items, count| ({
		total_gap : I64
		total_gap = (if (count > 1) { (gap * (count - 1)) } else { 0 })
		grow = flex_grow_items(items, count, DirRow, 0, [])
		fixed : I64
		fixed = flex_sum_fixed_w(grow, 0, count, 0)
		total_flex : I64
		total_flex = flex_sum_flex(grow, 0, count, 0)
		avail : I64
		avail = BoxModel.box_clamp0(((container.lr_w - total_gap) - fixed))
		plan = flex_plan(items, count, DirRow, avail)
		budget = flex_fit(grow, count, DirRow, plan.fp_excess, total_flex, plan.fp_excess, total_flex, (count + 1))
		flex_row_place(container, gap, items, grow, count, budget.fb_weight, budget.fb_space, plan, 0, 0, 0, container.lr_x, [])
	})

	flex_row_place : BoxModel.LayoutRect, I64, List(Layout.LayoutItem), List(Layout.LayoutItem), I64, I64, I64, Layout.FlexPlan, I64, I64, I64, I64, List(BoxModel.LayoutRect) -> Layout.LayoutResult
	flex_row_place = |container, gap, items, grow, count, total_flex, avail, plan, used, cum, i, cursor, acc| (if (i >= count) { Layout.LayoutResult.{ lrs: acc, lr_count: count, lr_used_w: (if (count > 0) { ((cursor - container.lr_x) - gap) } else { 0 }), lr_used_h: (if (count > 0) { flex_cross(items, count, DirRow, 0, container.lr_h) } else { 0 }) } } else { ({
		item = (List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		st = flex_step(item, (List.get(grow, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), DirRow, Theme.edges_h(item.li_margin), avail, total_flex, plan, used, cum)
		w : I64
		w = st.fs_size
		h : I64
		h = flex_cross_len(item, item.li_min_h, item.li_max_h, item.li_pref_h, Theme.edges_v(item.li_margin), container.lr_h)
		r = BoxModel.box_margin_rect(BoxModel.layout_rect(cursor, (container.lr_y + flex_cross_off(item, h, container.lr_h)), w, h), item.li_margin)
		next : I64
		next = ((cursor + w) + gap)
		flex_row_place(container, gap, items, grow, count, total_flex, avail, plan, st.fs_used, st.fs_cum, (i + 1), next, List.append(acc, r))
	}) })

	flex_col : BoxModel.LayoutRect, I64, List(Layout.LayoutItem), I64 -> Layout.LayoutResult
	flex_col = |container, gap, items, count| ({
		total_gap : I64
		total_gap = (if (count > 1) { (gap * (count - 1)) } else { 0 })
		grow = flex_grow_items(items, count, DirColumn, 0, [])
		fixed : I64
		fixed = flex_sum_fixed_h(grow, 0, count, 0)
		total_flex : I64
		total_flex = flex_sum_flex(grow, 0, count, 0)
		avail : I64
		avail = BoxModel.box_clamp0(((container.lr_h - total_gap) - fixed))
		plan = flex_plan(items, count, DirColumn, avail)
		budget = flex_fit(grow, count, DirColumn, plan.fp_excess, total_flex, plan.fp_excess, total_flex, (count + 1))
		flex_col_place(container, gap, items, grow, count, budget.fb_weight, budget.fb_space, plan, 0, 0, 0, container.lr_y, [])
	})

	flex_col_place : BoxModel.LayoutRect, I64, List(Layout.LayoutItem), List(Layout.LayoutItem), I64, I64, I64, Layout.FlexPlan, I64, I64, I64, I64, List(BoxModel.LayoutRect) -> Layout.LayoutResult
	flex_col_place = |container, gap, items, grow, count, total_flex, avail, plan, used, cum, i, cursor, acc| (if (i >= count) { Layout.LayoutResult.{ lrs: acc, lr_count: count, lr_used_w: (if (count > 0) { flex_cross(items, count, DirColumn, 0, container.lr_w) } else { 0 }), lr_used_h: (if (count > 0) { ((cursor - container.lr_y) - gap) } else { 0 }) } } else { ({
		item = (List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		st = flex_step(item, (List.get(grow, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), DirColumn, Theme.edges_v(item.li_margin), avail, total_flex, plan, used, cum)
		h : I64
		h = st.fs_size
		w : I64
		w = flex_cross_len(item, item.li_min_w, item.li_max_w, item.li_pref_w, Theme.edges_h(item.li_margin), container.lr_w)
		r = BoxModel.box_margin_rect(BoxModel.layout_rect((container.lr_x + flex_cross_off(item, w, container.lr_w)), cursor, w, h), item.li_margin)
		next : I64
		next = ((cursor + h) + gap)
		flex_col_place(container, gap, items, grow, count, total_flex, avail, plan, st.fs_used, st.fs_cum, (i + 1), next, List.append(acc, r))
	}) })

	flex_main_min : Layout.LayoutItem, Layout.LayoutDir -> I64
	flex_main_min = |item, dir| (match dir {
		DirRow => item.li_min_w
		DirColumn => item.li_min_h
	})

	flex_main_max : Layout.LayoutItem, Layout.LayoutDir -> I64
	flex_main_max = |item, dir| ({
		mx : I64
		mx = (match dir {
			DirRow => item.li_max_w
			DirColumn => item.li_max_h
		})
		(if (mx <= 0) { 0 } else { BoxModel.box_max(mx, flex_main_min(item, dir)) })
	})

	flex_capped : Layout.LayoutItem, Layout.LayoutDir, I64, I64 -> Bool
	flex_capped = |item, dir, space, weight| ((((item.li_flex > 0) and (weight > 0)) and (flex_main_max(item, dir) > 0)) and ((flex_main_max(item, dir) * weight) < (space * item.li_flex)))

	flex_active : Layout.LayoutItem, Layout.LayoutDir, I64, I64 -> Bool
	flex_active = |item, dir, space, weight| ((((item.li_flex > 0) and (weight > 0)) and ((flex_main_min(item, dir) * weight) <= (space * item.li_flex))) and (flex_capped(item, dir, space, weight) == False))

	flex_locked : List(Layout.LayoutItem), I64, Layout.LayoutDir, I64, I64, I64, I64, I64 -> Layout.FlexBudget
	flex_locked = |items, count, dir, space, weight, i, taken, frozen| (if (i >= count) { Layout.FlexBudget.{ fb_space: taken, fb_weight: frozen } } else { ({
		item = (List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if ((item.li_flex > 0) and (flex_active(item, dir, space, weight) == False)) { ({
			size : I64
			size = (if flex_capped(item, dir, space, weight) { flex_main_max(item, dir) } else { flex_main_min(item, dir) })
			flex_locked(items, count, dir, space, weight, (i + 1), (taken + size), (frozen + item.li_flex))
		}) } else { flex_locked(items, count, dir, space, weight, (i + 1), taken, frozen) })
	}) })

	flex_fit : List(Layout.LayoutItem), I64, Layout.LayoutDir, I64, I64, I64, I64, I64 -> Layout.FlexBudget
	flex_fit = |items, count, dir, available, total, space, weight, fuel| (if (weight <= 0) { Layout.FlexBudget.{ fb_space: 0, fb_weight: 0 } } else { (if (fuel <= 0) { Layout.FlexBudget.{ fb_space: space, fb_weight: weight } } else { ({
		locked = flex_locked(items, count, dir, space, weight, 0, 0, 0)
		next_weight : I64
		next_weight = (total - locked.fb_weight)
		next_space : I64
		next_space = BoxModel.box_clamp0((available - locked.fb_space))
		(if (next_weight == weight) { Layout.FlexBudget.{ fb_space: next_space, fb_weight: next_weight } } else { flex_fit(items, count, dir, available, total, next_space, next_weight, (fuel - 1)) })
	}) }) })

	flex_cross_size : I64, I64, I64, I64 -> I64
	flex_cross_size = |lo, hi, margin, extent| ({
		s : I64
		s = BoxModel.box_max((lo + margin), extent)
		(if (hi <= 0) { s } else { BoxModel.box_min(s, (BoxModel.box_max(hi, lo) + margin)) })
	})

	flex_frozen_size : Layout.LayoutItem, Layout.LayoutDir, I64, I64, I64 -> I64
	flex_frozen_size = |item, dir, space, weight, margin| (if flex_capped(item, dir, space, weight) { (flex_main_max(item, dir) + margin) } else { (flex_main_min(item, dir) + margin) })

	flex_cross : List(Layout.LayoutItem), I64, Layout.LayoutDir, I64, I64 -> I64
	flex_cross = |items, count, dir, i, largest| (if (i >= count) { largest } else { ({
		item = (List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		size : I64
		size = (match dir {
			DirRow => (item.li_min_h + Theme.edges_v(item.li_margin))
			DirColumn => (item.li_min_w + Theme.edges_h(item.li_margin))
		})
		flex_cross(items, count, dir, (i + 1), BoxModel.box_max(largest, size))
	}) })

	flex_pref_main : Layout.LayoutItem, Layout.LayoutDir -> I64
	flex_pref_main = |item, dir| (match dir {
		DirRow => item.li_pref_w
		DirColumn => item.li_pref_h
	})

	flex_basis : Layout.LayoutItem, Layout.LayoutDir -> I64
	flex_basis = |item, dir| ({
		p : I64
		p = flex_pref_main(item, dir)
		(if ((item.li_flex <= 0) or (p <= 0)) { 0 } else { ({
			b : I64
			b = BoxModel.box_max(p, flex_main_min(item, dir))
			mx : I64
			mx = flex_main_max(item, dir)
			(if (mx > 0) { BoxModel.box_min(b, mx) } else { b })
		}) })
	})

	flex_grow_item : Layout.LayoutItem, Layout.LayoutDir -> Layout.LayoutItem
	flex_grow_item = |item, dir| ({
		b : I64
		b = flex_basis(item, dir)
		(if (b == 0) { item } else { ({
			mx : I64
			mx = flex_main_max(item, dir)
			rest : I64
			rest = (if (mx > 0) { (mx - b) } else { 0 })
			fl : I64
			fl = (if ((mx > 0) and (rest == 0)) { 0 } else { item.li_flex })
			(match dir {
				DirRow => Layout.LayoutItem.{ li_min_w: 0, li_min_h: item.li_min_h, li_flex: fl, li_margin: item.li_margin, li_max_w: rest, li_max_h: item.li_max_h, li_pref_w: 0, li_pref_h: item.li_pref_h, li_align: item.li_align }
				DirColumn => Layout.LayoutItem.{ li_min_w: item.li_min_w, li_min_h: 0, li_flex: fl, li_margin: item.li_margin, li_max_w: item.li_max_w, li_max_h: rest, li_pref_w: item.li_pref_w, li_pref_h: 0, li_align: item.li_align }
			})
		}) })
	})

	flex_grow_items : List(Layout.LayoutItem), I64, Layout.LayoutDir, I64, List(Layout.LayoutItem) -> List(Layout.LayoutItem)
	flex_grow_items = |items, count, dir, i, acc| (if (i >= count) { acc } else { flex_grow_items(items, count, dir, (i + 1), List.append(acc, flex_grow_item((List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), dir))) })

	flex_plan_sums : List(Layout.LayoutItem), I64, Layout.LayoutDir, I64, I64, I64, I64, I64 -> Layout.FlexPlan
	flex_plan_sums = |items, count, dir, avail, i, sum_b, d, mins| (if (i >= count) { ({
		excess : I64
		excess = (avail - sum_b)
		shrink : Bool
		shrink = ((excess < 0) and (d > 0))
		Layout.FlexPlan.{ fp_excess: BoxModel.box_clamp0(excess), fp_d: (if shrink { d } else { 0 }), fp_room: (if shrink { BoxModel.box_clamp0((avail - mins)) } else { 0 }) }
	}) } else { ({
		item = (List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		b : I64
		b = flex_basis(item, dir)
		lo : I64
		lo = flex_main_min(item, dir)
		d2 : I64
		d2 = (if (b > 0) { (d + (b - lo)) } else { d })
		m2 : I64
		m2 = (if (item.li_flex > 0) { (mins + lo) } else { mins })
		flex_plan_sums(items, count, dir, avail, (i + 1), (sum_b + b), d2, m2)
	}) })

	flex_plan : List(Layout.LayoutItem), I64, Layout.LayoutDir, I64 -> Layout.FlexPlan
	flex_plan = |items, count, dir, avail| flex_plan_sums(items, count, dir, avail, 0, 0, 0, 0)

	flex_step : Layout.LayoutItem, Layout.LayoutItem, Layout.LayoutDir, I64, I64, I64, Layout.FlexPlan, I64, I64 -> Layout.FlexStep
	flex_step = |item, g, dir, margin, avail, weight, plan, used, cum| ({
		b : I64
		b = flex_basis(item, dir)
		(if (plan.fp_d > 0) { ({
			lo : I64
			lo = flex_main_min(item, dir)
			(if (b == 0) { Layout.FlexStep.{ fs_size: (lo + margin), fs_used: used, fs_cum: cum } } else { ({
				next : I64
				next = (cum + (b - lo))
				Layout.FlexStep.{ fs_size: (((lo + I64.div_trunc_by((next * plan.fp_room), plan.fp_d)) - I64.div_trunc_by((cum * plan.fp_room), plan.fp_d)) + margin), fs_used: used, fs_cum: next }
			}) })
		}) } else { ({
			active : Bool
			active = flex_active(g, dir, avail, weight)
			next_used : I64
			next_used = (if active { (used + g.li_flex) } else { used })
			grown : I64
			grown = (if active { ((I64.div_trunc_by((next_used * avail), weight) - I64.div_trunc_by((used * avail), weight)) + margin) } else { flex_frozen_size(g, dir, avail, weight, margin) })
			Layout.FlexStep.{ fs_size: (grown + b), fs_used: next_used, fs_cum: cum }
		}) })
	})

	flex_sum_fixed_w : List(Layout.LayoutItem), I64, I64, I64 -> I64
	flex_sum_fixed_w = |items, i, n, acc| (if (i >= n) { acc } else { ({
		item = (List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		add : I64
		add = ((if (item.li_flex > 0) { 0 } else { item.li_min_w }) + Theme.edges_h(item.li_margin))
		flex_sum_fixed_w(items, (i + 1), n, (acc + add))
	}) })

	flex_sum_fixed_h : List(Layout.LayoutItem), I64, I64, I64 -> I64
	flex_sum_fixed_h = |items, i, n, acc| (if (i >= n) { acc } else { ({
		item = (List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		add : I64
		add = ((if (item.li_flex > 0) { 0 } else { item.li_min_h }) + Theme.edges_v(item.li_margin))
		flex_sum_fixed_h(items, (i + 1), n, (acc + add))
	}) })

	flex_sum_flex : List(Layout.LayoutItem), I64, I64, I64 -> I64
	flex_sum_flex = |items, i, n, acc| (if (i >= n) { acc } else { ({
		item = (List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		flex_sum_flex(items, (i + 1), n, (acc + BoxModel.box_clamp0(item.li_flex)))
	}) })

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

	eq_LayoutItem : Layout.LayoutItem, Layout.LayoutItem -> Bool
	eq_LayoutItem = |ex, ey| (((((((((ex.li_min_w == ey.li_min_w) and (ex.li_min_h == ey.li_min_h)) and (ex.li_flex == ey.li_flex)) and Theme.eq_Edges(ex.li_margin, ey.li_margin)) and (ex.li_max_w == ey.li_max_w)) and (ex.li_max_h == ey.li_max_h)) and (ex.li_pref_w == ey.li_pref_w)) and (ex.li_pref_h == ey.li_pref_h)) and (ex.li_align == ey.li_align))

	eq_LayoutResult : Layout.LayoutResult, Layout.LayoutResult -> Bool
	eq_LayoutResult = |ex, ey| ((((ex.lrs == ey.lrs) and (ex.lr_count == ey.lr_count)) and (ex.lr_used_w == ey.lr_used_w)) and (ex.lr_used_h == ey.lr_used_h))

	eq_FlexBudget : Layout.FlexBudget, Layout.FlexBudget -> Bool
	eq_FlexBudget = |ex, ey| ((ex.fb_space == ey.fb_space) and (ex.fb_weight == ey.fb_weight))

	eq_FlexPlan : Layout.FlexPlan, Layout.FlexPlan -> Bool
	eq_FlexPlan = |ex, ey| (((ex.fp_excess == ey.fp_excess) and (ex.fp_d == ey.fp_d)) and (ex.fp_room == ey.fp_room))

	eq_FlexStep : Layout.FlexStep, Layout.FlexStep -> Bool
	eq_FlexStep = |ex, ey| (((ex.fs_size == ey.fs_size) and (ex.fs_used == ey.fs_used)) and (ex.fs_cum == ey.fs_cum))

	eq_GridLayout : Layout.GridLayout, Layout.GridLayout -> Bool
	eq_GridLayout = |ex, ey| (((ex.gl_columns == ey.gl_columns) and (ex.gl_row_gap == ey.gl_row_gap)) and (ex.gl_col_gap == ey.gl_col_gap))

	eq_SplitLayout : Layout.SplitLayout, Layout.SplitLayout -> Bool
	eq_SplitLayout = |ex, ey| (((ex.sl_ratio == ey.sl_ratio) and eq_LayoutDir(ex.sl_direction, ey.sl_direction)) and (ex.sl_gap == ey.sl_gap))
}
