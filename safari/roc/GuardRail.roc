# GuardRail -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Camera
import DeviceMath
import Geom
import ListUtils
import Paint

GuardRail :: [].{
	RailPoly : { v : List(Geom.Vec3), color : I64, fwd : F64 }

	rail_height : F64
	rail_height = 0.5

	rail_thickness : F64
	rail_thickness = 0.1

	rail_post_width : F64
	rail_post_width = 0.02

	rail_metal : I64
	rail_metal = 12765135

	rail_post_metal : I64
	rail_post_metal = 10133672

	rail_runout : I64
	rail_runout = 10

	max_rail_polys : I64
	max_rail_polys = 3072

	bar_top : F64
	bar_top = (rail_height + (rail_thickness / 2.0))

	bar_bot : F64
	bar_bot = (rail_height - (rail_thickness / 2.0))

	half_post : F64
	half_post = (rail_post_width / 2.0)

	rail_poly : Geom.Vec3, Geom.Vec3, Geom.Vec3, Geom.Vec3, I64 -> GuardRail.RailPoly
	rail_poly = |p0, p1, p2, p3, color| ({
		fwd = ((((p0.forward + p1.forward) + p2.forward) + p3.forward) / 4.0)
		{ v: [p0, p1, p2, p3], color: color, fwd: fwd }
	})

	bar_quad : Geom.RiderPt, Geom.RiderPt -> GuardRail.RailPoly
	bar_quad = |p, q| ({
		p_bot = { right: p.right, forward: p.forward, height: bar_bot }
		q_bot = { right: q.right, forward: q.forward, height: bar_bot }
		q_top = { right: q.right, forward: q.forward, height: bar_top }
		p_top = { right: p.right, forward: p.forward, height: bar_top }
		rail_poly(p_bot, q_bot, q_top, p_top, rail_metal)
	})

	# bars builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	bars : List(Geom.RiderPt), I64 -> List(GuardRail.RailPoly)
	bars = |path, i| bars_acc(path, i, [])

	bars_acc : List(Geom.RiderPt), I64, List(GuardRail.RailPoly) -> List(GuardRail.RailPoly)
	bars_acc = |path, i, acc| (if ((i + 1) >= U64.to_i64_wrap(List.len(path))) { acc } else { bars_acc(path, (i + 1), List.append(acc, bar_quad((List.get(path, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), (List.get(path, I64.to_u64_wrap((i + 1))) ?? crash("list-at out of range"))))) })

	post_box : Geom.RiderPt, F64, F64 -> GuardRail.RailPoly
	post_box = |p, ox, ofwd| ({
		back_foot = { right: (p.right - ox), forward: (p.forward - ofwd), height: 0.0 }
		fore_foot = { right: (p.right + ox), forward: (p.forward + ofwd), height: 0.0 }
		fore_head = { right: (p.right + ox), forward: (p.forward + ofwd), height: bar_top }
		back_head = { right: (p.right - ox), forward: (p.forward - ofwd), height: bar_top }
		rail_poly(back_foot, fore_foot, fore_head, back_head, rail_post_metal)
	})

	post_quad : List(Geom.RiderPt), I64 -> GuardRail.RailPoly
	post_quad = |path, i| ({
		n = U64.to_i64_wrap(List.len(path))
		ia = (if (i == 0) { 0 } else { (i - 1) })
		ib = (if ((i + 1) >= n) { (n - 1) } else { (i + 1) })
		a = (List.get(path, I64.to_u64_wrap(ia)) ?? crash("list-at out of range"))
		b = (List.get(path, I64.to_u64_wrap(ib)) ?? crash("list-at out of range"))
		dr = (b.right - a.right)
		df = (b.forward - a.forward)
		raw = DeviceMath.real_sqrt(((dr * dr) + (df * df)))
		run = (if (F64.to_bits(raw) == F64.to_bits(0.0)) { 1.0 } else { raw })
		ox = ((dr / run) * half_post)
		ofwd = ((df / run) * half_post)
		post_box((List.get(path, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), ox, ofwd)
	})

	# posts builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	posts : List(Geom.RiderPt), I64 -> List(GuardRail.RailPoly)
	posts = |path, i| posts_acc(path, i, [])

	posts_acc : List(Geom.RiderPt), I64, List(GuardRail.RailPoly) -> List(GuardRail.RailPoly)
	posts_acc = |path, i, acc| (if (i >= U64.to_i64_wrap(List.len(path))) { acc } else { posts_acc(path, (i + 1), List.append(acc, post_quad(path, i))) })

	rail_emit : List(Geom.RiderPt) -> List(GuardRail.RailPoly)
	rail_emit = |path| (if (U64.to_i64_wrap(List.len(path)) < 2) { [] } else { ListUtils.list_take(List.concat(bars(path, 0), posts(path, 0)), max_rail_polys) })

	rail_draw_poly : GuardRail.RailPoly, F64, F64 -> List(Paint.DrawCmd)
	rail_draw_poly = |rp, cf, view_w| ({
		clipped = Geom.clip_near(rp.v, Geom.near)
		(if (U64.to_i64_wrap(List.len(clipped)) < 3) { [] } else { Paint.push_poly(rp.color, Camera.project_all(clipped, cf, view_w, 0)) })
	})

	# rail_draw_all builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	rail_draw_all : List(GuardRail.RailPoly), F64, F64, I64 -> List(Paint.DrawCmd)
	rail_draw_all = |ps, cf, view_w, i| rail_draw_all_acc(ps, cf, view_w, i, [])

	rail_draw_all_acc : List(GuardRail.RailPoly), F64, F64, I64, List(Paint.DrawCmd) -> List(Paint.DrawCmd)
	rail_draw_all_acc = |ps, cf, view_w, i, acc| (if (i >= U64.to_i64_wrap(List.len(ps))) { acc } else { rail_draw_all_acc(ps, cf, view_w, (i + 1), List.concat(acc, rail_draw_poly((List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), cf, view_w))) })
}
