# Tree -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Camera
import ListUtils
import Paint
import Trig

Tree :: [].{
	Metrics : { bx : F64, by : F64, ht : F64, apex_y : F64, foliage : F64, w : F64 }

	tier_top : List(F64)
	tier_top = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7]

	tier_bot : List(F64)
	tier_bot = [0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]

	tier_wide : List(F64)
	tier_wide = [0.35, 0.44, 0.53, 0.63, 0.72, 0.81, 0.91, 1.0]

	trunk_color : I64
	trunk_color = 5914146

	visible_trunk : F64
	visible_trunk = 0.44

	crown_h : F64
	crown_h = 0.648

	crown_w : F64
	crown_w = 0.288

	min_cone_forward : F64
	min_cone_forward = 0.4

	ring_n : I64
	ring_n = 16

	metrics : F64, F64, F64, F64, F64 -> Tree.Metrics
	metrics = |right, forward, height, cf, view_w| ({
		base = Camera.project({ right: right, forward: forward, height: 0.0 }, cf, view_w)
		top = Camera.project({ right: right, forward: forward, height: height }, cf, view_w)
		ht = (base.y - top.y)
		foliage = (ht * crown_h)
		crown_bottom_y = (base.y - (ht * visible_trunk))
		{ bx: base.x, by: base.y, ht: ht, apex_y: (crown_bottom_y - foliage), foliage: foliage, w: (ht * crown_w) }
	})

	draw_trunk : Tree.Metrics, Bool -> List(Paint.DrawCmd)
	draw_trunk = |m, round_trunk| ({
		trunk_w = (if ((m.ht * 0.08) > 1.0) { (m.ht * 0.08) } else { 1.0 })
		trunk_h = ((m.ht * visible_trunk) + (m.ht * 0.05))
		tx = (m.bx - (trunk_w / 2.0))
		pts = [{ x: tx, y: (m.by - trunk_h) }, { x: (tx + trunk_w), y: (m.by - trunk_h) }, { x: (tx + trunk_w), y: m.by }, { x: tx, y: m.by }]
		(if round_trunk { Paint.push_round_poly(trunk_color, 1.0, pts) } else { Paint.push_poly(trunk_color, pts) })
	})

	tier_triangle : Tree.Metrics, I64, I64 -> List(Paint.DrawCmd)
	tier_triangle = |m, k, color| ({
		tri = [{ x: m.bx, y: (m.apex_y + (m.foliage * (List.get(tier_top, I64.to_u64_wrap(k)) ?? crash("list-at out of range")))) }, { x: (m.bx + (m.w * (List.get(tier_wide, I64.to_u64_wrap(k)) ?? crash("list-at out of range")))), y: (m.apex_y + (m.foliage * (List.get(tier_bot, I64.to_u64_wrap(k)) ?? crash("list-at out of range")))) }, { x: (m.bx - (m.w * (List.get(tier_wide, I64.to_u64_wrap(k)) ?? crash("list-at out of range")))), y: (m.apex_y + (m.foliage * (List.get(tier_bot, I64.to_u64_wrap(k)) ?? crash("list-at out of range")))) }]
		Paint.push_poly(color, tri)
	})

	# cone_ring builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	cone_ring : F64, F64, F64, F64, F64, F64, I64, F64 -> List(Camera.ScreenPt)
	cone_ring = |r0, f0, rad, h_base, cf, view_w, i, a| cone_ring_acc(r0, f0, rad, h_base, cf, view_w, i, a, [])

	cone_ring_acc : F64, F64, F64, F64, F64, F64, I64, F64, List(Camera.ScreenPt) -> List(Camera.ScreenPt)
	cone_ring_acc = |r0, f0, rad, h_base, cf, view_w, i, a, acc| (if (i >= ring_n) { acc } else { ({
		p = { right: (r0 + (rad * Trig.r_cos(a))), forward: (f0 + (rad * Trig.r_sin(a))), height: h_base }
		cone_ring_acc(r0, f0, rad, h_base, cf, view_w, (i + 1), (a + (Trig.two_pi / 16.0)), List.append(acc, Camera.project(p, cf, view_w)))
	}) })

	less_xy : Camera.ScreenPt, Camera.ScreenPt -> Bool
	less_xy = |a, b| (if (a.x < b.x) { True } else { (if (F64.to_bits(a.x) == F64.to_bits(b.x)) { (a.y < b.y) } else { False }) })

	hull_insert : Camera.ScreenPt, List(Camera.ScreenPt), I64 -> List(Camera.ScreenPt)
	hull_insert = |p, xs, i| (if (i >= U64.to_i64_wrap(List.len(xs))) { List.concat(xs, [p]) } else { (if less_xy(p, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { List.concat(List.concat(ListUtils.list_take(xs, i), [p]), ListUtils.list_drop(xs, i)) } else { hull_insert(p, xs, (i + 1)) }) })

	sort_pts : List(Camera.ScreenPt), I64, List(Camera.ScreenPt) -> List(Camera.ScreenPt)
	sort_pts = |src, i, acc| (if (i >= U64.to_i64_wrap(List.len(src))) { acc } else { sort_pts(src, (i + 1), hull_insert((List.get(src, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), acc, 0)) })

	hull_trim : List(Camera.ScreenPt), Camera.ScreenPt -> List(Camera.ScreenPt)
	hull_trim = |hull, p| ({
		n = U64.to_i64_wrap(List.len(hull))
		(if (n < 2) { hull } else { ({
			a = (List.get(hull, I64.to_u64_wrap((n - 2))) ?? crash("list-at out of range"))
			b = (List.get(hull, I64.to_u64_wrap((n - 1))) ?? crash("list-at out of range"))
			cr = (((b.x - a.x) * (p.y - a.y)) - ((b.y - a.y) * (p.x - a.x)))
			(if (cr <= 0.0) { hull_trim(ListUtils.list_take(hull, (n - 1)), p) } else { hull })
		}) })
	})

	lower_chain : List(Camera.ScreenPt), I64, List(Camera.ScreenPt) -> List(Camera.ScreenPt)
	lower_chain = |ps, i, hull| (if (i >= U64.to_i64_wrap(List.len(ps))) { hull } else { ({
		p = (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		lower_chain(ps, (i + 1), List.concat(hull_trim(hull, p), [p]))
	}) })

	upper_chain : List(Camera.ScreenPt), I64, List(Camera.ScreenPt) -> List(Camera.ScreenPt)
	upper_chain = |ps, i, hull| (if (i < 0) { hull } else { ({
		p = (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		upper_chain(ps, (i - 1), List.concat(hull_trim(hull, p), [p]))
	}) })

	convex_hull_pts : List(Camera.ScreenPt) -> List(Camera.ScreenPt)
	convex_hull_pts = |ps| ({
		n = U64.to_i64_wrap(List.len(ps))
		(if (n < 3) { ps } else { ({
			sorted = sort_pts(ps, 0, [])
			lo = lower_chain(sorted, 0, [])
			up = upper_chain(sorted, (n - 1), [])
			List.concat(ListUtils.list_take(lo, (U64.to_i64_wrap(List.len(lo)) - 1)), ListUtils.list_take(up, (U64.to_i64_wrap(List.len(up)) - 1)))
		}) })
	})

	tier_cone : F64, F64, F64, I64, F64, F64, Tree.Metrics, I64, F64 -> List(Paint.DrawCmd)
	tier_cone = |r0, f0, height, color, cf, view_w, m, k, shade| ({
		rad = ((crown_w * (List.get(tier_wide, I64.to_u64_wrap(k)) ?? crash("list-at out of range"))) * height)
		(if ((f0 - rad) < min_cone_forward) { tier_triangle(m, k, color) } else { ({
			h_base = ((visible_trunk + (crown_h * (1.0 - (List.get(tier_bot, I64.to_u64_wrap(k)) ?? crash("list-at out of range"))))) * height)
			h_apex = ((visible_trunk + (crown_h * (1.0 - (List.get(tier_top, I64.to_u64_wrap(k)) ?? crash("list-at out of range"))))) * height)
			apex = Camera.project({ right: r0, forward: f0, height: h_apex }, cf, view_w)
			ring = List.concat(cone_ring(r0, f0, rad, h_base, cf, view_w, 0, 0.0), [apex])
			hull = convex_hull_pts(ring)
			(if (U64.to_i64_wrap(List.len(hull)) < 3) { [] } else { Paint.push_round_poly(color, shade, hull) })
		}) })
	})

	# tiers builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	tiers : F64, F64, F64, I64, F64, F64, Tree.Metrics, Bool, F64, I64 -> List(Paint.DrawCmd)
	tiers = |r0, f0, height, color, cf, view_w, m, near_crown, shade, k| tiers_acc(r0, f0, height, color, cf, view_w, m, near_crown, shade, k, [])

	tiers_acc : F64, F64, F64, I64, F64, F64, Tree.Metrics, Bool, F64, I64, List(Paint.DrawCmd) -> List(Paint.DrawCmd)
	tiers_acc = |r0, f0, height, color, cf, view_w, m, near_crown, shade, k, acc| (if (k >= 8) { acc } else { ({
		one = (if near_crown { tier_cone(r0, f0, height, color, cf, view_w, m, k, shade) } else { tier_triangle(m, k, color) })
		tiers_acc(r0, f0, height, color, cf, view_w, m, near_crown, shade, (k + 1), List.concat(acc, one))
	}) })

	tree_draw : F64, F64, F64, I64, F64, F64, Bool, Bool, F64 -> List(Paint.DrawCmd)
	tree_draw = |right, forward, height, color, cf, view_w, round_trunk, near_crown, shade| ({
		m = metrics(right, forward, height, cf, view_w)
		(if (m.ht < 1.0) { [] } else { List.concat(draw_trunk(m, round_trunk), tiers(right, forward, height, color, cf, view_w, m, near_crown, shade, 0)) })
	})
}
