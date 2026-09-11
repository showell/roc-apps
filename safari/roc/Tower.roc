# Tower -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Camera
import DeviceMath
import Geom
import Num
import Paint
import Trig

Tower :: [].{

	tower_height : F64
	tower_height = 80.0

	tower_half : F64
	tower_half = 6.0

	stage_height : F64
	stage_height = 20.0

	brace_stages : I64
	brace_stages = 2

	rod_half : F64
	rod_half = 0.12

	rod_w : F64
	rod_w = (rod_half * 2.0)

	tower_metal : I64
	tower_metal = 10133672

	earth_radius : F64
	earth_radius = 20000.0

	beacon_radius : F64
	beacon_radius = 3.0

	beacon_color : I64
	beacon_color = 16723942

	beacon_period : F64
	beacon_period = 120.0

	beacon_offset_for : I64 -> F64
	beacon_offset_for = |n| I64.to_f64(((n * 37) - (I64.div_trunc_by((n * 37), 120) * 120)))

	beacon_brightness : F64 -> F64
	beacon_brightness = |phase| ({
		wrapped = Num.mod_real((Num.mod_real(phase, beacon_period) + beacon_period), beacon_period)
		((1.0 - Trig.r_cos((((2.0 * Trig.pi) * wrapped) / beacon_period))) / 2.0)
	})

	corner_u : I64 -> F64
	corner_u = |k| (if (k == 0) { (0.0 - 1.0) } else { (if (k == 1) { 1.0 } else { (if (k == 2) { 1.0 } else { (0.0 - 1.0) }) }) })

	corner_v : I64 -> F64
	corner_v = |k| (if (k == 0) { (0.0 - 1.0) } else { (if (k == 1) { (0.0 - 1.0) } else { (if (k == 2) { 1.0 } else { 1.0 }) }) })

	base_corner_ax : I64, F64, F64, F64 -> Geom.AX
	base_corner_ax = |k, a0, x0, yaw| ({
		du = (corner_u(k) * tower_half)
		dv = (corner_v(k) * tower_half)
		cy = Trig.r_cos(yaw)
		sy = Trig.r_sin(yaw)
		{ a: (a0 + ((du * sy) + (dv * cy))), x: (x0 + ((du * cy) - (dv * sy))) }
	})

	tower_ground_drop : Geom.RiderPt -> F64
	tower_ground_drop = |p| (((p.right * p.right) + (p.forward * p.forward)) / (2.0 * earth_radius))

	lerp3v : Geom.Vec3, Geom.Vec3, F64 -> Geom.Vec3
	lerp3v = |a, b, t| { right: (a.right + ((b.right - a.right) * t)), forward: (a.forward + ((b.forward - a.forward) * t)), height: (a.height + ((b.height - a.height) * t)) }

	corner_at : List(Geom.RiderPt), Geom.RiderPt, I64, F64, F64 -> Geom.Vec3
	corner_at = |base, center, k, h, drop| ({
		t = (h / tower_height)
		bk = (List.get(base, I64.to_u64_wrap(k)) ?? crash("list-at out of range"))
		{ right: (bk.right + ((center.right - bk.right) * t)), forward: (bk.forward + ((center.forward - bk.forward) * t)), height: (h - drop) }
	})

	bar : Camera.ScreenPt, Camera.ScreenPt, F64 -> List(Paint.DrawCmd)
	bar = |a, b, wpx| ({
		dx = (b.x - a.x)
		dy = (b.y - a.y)
		raw = DeviceMath.real_sqrt(((dx * dx) + (dy * dy)))
		len = (if (raw < 0.0001) { 1.0 } else { raw })
		rod_quad(a, b, ((((0.0 - dy) / len) * wpx) / 2.0), (((dx / len) * wpx) / 2.0))
	})

	rod_quad : Camera.ScreenPt, Camera.ScreenPt, F64, F64 -> List(Paint.DrawCmd)
	rod_quad = |a, b, ox, oy| Paint.push_poly(tower_metal, [{ x: (a.x + ox), y: (a.y + oy) }, { x: (b.x + ox), y: (b.y + oy) }, { x: (b.x - ox), y: (b.y - oy) }, { x: (a.x - ox), y: (a.y - oy) }])

	bar3d : Geom.Vec3, Geom.Vec3, F64, F64, F64 -> List(Paint.DrawCmd)
	bar3d = |a, b, wpx, cf, view_w| ({
		a_in = (a.forward >= Geom.near)
		b_in = (b.forward >= Geom.near)
		(if a_in { (if b_in { bar3d_draw(a, b, wpx, cf, view_w) } else { bar3d_draw(a, bar3d_cut(a, b), wpx, cf, view_w) }) } else { (if b_in { bar3d_draw(bar3d_cut(a, b), b, wpx, cf, view_w) } else { [] }) })
	})

	bar3d_cut : Geom.Vec3, Geom.Vec3 -> Geom.Vec3
	bar3d_cut = |a, b| lerp3v(a, b, ((Geom.near - a.forward) / (b.forward - a.forward)))

	bar3d_draw : Geom.Vec3, Geom.Vec3, F64, F64, F64 -> List(Paint.DrawCmd)
	bar3d_draw = |a, b, wpx, cf, view_w| bar(Camera.project(a, cf, view_w), Camera.project(b, cf, view_w), wpx)

	rod_px : F64, F64, F64 -> F64
	rod_px = |forward, cf, view_w| ({
		p1 = Camera.project({ right: 1.0, forward: forward, height: 0.0 }, cf, view_w)
		p0 = Camera.project({ right: 0.0, forward: forward, height: 0.0 }, cf, view_w)
		(rod_w * (p1.x - p0.x))
	})

	# tower_legs builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	tower_legs : List(Geom.RiderPt), Geom.RiderPt, Geom.Vec3, F64, F64, F64, F64, F64, I64 -> List(Paint.DrawCmd)
	tower_legs = |base, center, apex, clip_h, drop, wpx, cf, view_w, k| tower_legs_acc(base, center, apex, clip_h, drop, wpx, cf, view_w, k, [])

	tower_legs_acc : List(Geom.RiderPt), Geom.RiderPt, Geom.Vec3, F64, F64, F64, F64, F64, I64, List(Paint.DrawCmd) -> List(Paint.DrawCmd)
	tower_legs_acc = |base, center, apex, clip_h, drop, wpx, cf, view_w, k, acc| (if (k >= 4) { acc } else { tower_legs_acc(base, center, apex, clip_h, drop, wpx, cf, view_w, (k + 1), List.concat(acc, bar3d(corner_at(base, center, k, clip_h, drop), apex, wpx, cf, view_w))) })

	# ring_at builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	ring_at : List(Geom.RiderPt), Geom.RiderPt, F64, F64, F64, F64, F64, I64 -> List(Paint.DrawCmd)
	ring_at = |base, center, h, drop, wpx, cf, view_w, k| ring_at_acc(base, center, h, drop, wpx, cf, view_w, k, [])

	ring_at_acc : List(Geom.RiderPt), Geom.RiderPt, F64, F64, F64, F64, F64, I64, List(Paint.DrawCmd) -> List(Paint.DrawCmd)
	ring_at_acc = |base, center, h, drop, wpx, cf, view_w, k, acc| (if (k >= 4) { acc } else { ring_at_acc(base, center, h, drop, wpx, cf, view_w, (k + 1), List.concat(acc, bar3d(corner_at(base, center, k, h, drop), corner_at(base, center, ((k + 1) - (I64.div_trunc_by((k + 1), 4) * 4)), h, drop), wpx, cf, view_w))) })

	# rings builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	rings : List(Geom.RiderPt), Geom.RiderPt, F64, F64, F64, F64, F64, F64 -> List(Paint.DrawCmd)
	rings = |base, center, h, clip_h, drop, wpx, cf, view_w| rings_acc(base, center, h, clip_h, drop, wpx, cf, view_w, [])

	rings_acc : List(Geom.RiderPt), Geom.RiderPt, F64, F64, F64, F64, F64, F64, List(Paint.DrawCmd) -> List(Paint.DrawCmd)
	rings_acc = |base, center, h, clip_h, drop, wpx, cf, view_w, acc| (if (h >= tower_height) { acc } else { rings_acc(base, center, (h + stage_height), clip_h, drop, wpx, cf, view_w, List.concat(acc, (if (h <= clip_h) { [] } else { ring_at(base, center, h, drop, wpx, cf, view_w, 0) }))) })

	brace_at : List(Geom.RiderPt), Geom.RiderPt, F64, F64, F64, F64, F64, F64, F64, I64 -> List(Paint.DrawCmd)
	brace_at = |base, center, lo, hi, f, drop, wpx, cf, view_w, k| (if (k >= 4) { [] } else { brace_pair(base, center, lo, hi, f, drop, wpx, cf, view_w, k) })

	brace_pair : List(Geom.RiderPt), Geom.RiderPt, F64, F64, F64, F64, F64, F64, F64, I64 -> List(Paint.DrawCmd)
	brace_pair = |base, center, lo, hi, f, drop, wpx, cf, view_w, k| ({
		j = ((k + 1) - (I64.div_trunc_by((k + 1), 4) * 4))
		kj = bar3d(lerp3v(corner_at(base, center, k, lo, drop), corner_at(base, center, j, hi, drop), f), corner_at(base, center, j, hi, drop), wpx, cf, view_w)
		jk = bar3d(lerp3v(corner_at(base, center, j, lo, drop), corner_at(base, center, k, hi, drop), f), corner_at(base, center, k, hi, drop), wpx, cf, view_w)
		List.concat(List.concat(kj, jk), brace_at(base, center, lo, hi, f, drop, wpx, cf, view_w, (k + 1)))
	})

	braces : List(Geom.RiderPt), Geom.RiderPt, F64, F64, F64, F64, F64, I64 -> List(Paint.DrawCmd)
	braces = |base, center, clip_h, drop, wpx, cf, view_w, stage| (if (stage >= brace_stages) { [] } else { brace_stage(base, center, clip_h, drop, wpx, cf, view_w, stage) })

	brace_stage : List(Geom.RiderPt), Geom.RiderPt, F64, F64, F64, F64, F64, I64 -> List(Paint.DrawCmd)
	brace_stage = |base, center, clip_h, drop, wpx, cf, view_w, stage| ({
		lo = (I64.to_f64(stage) * stage_height)
		hi = (lo + stage_height)
		rest = braces(base, center, clip_h, drop, wpx, cf, view_w, (stage + 1))
		(if (hi <= clip_h) { rest } else { List.concat(brace_at(base, center, lo, hi, ((DeviceMath.real_max(lo, clip_h) - lo) / stage_height), drop, wpx, cf, view_w, 0), rest) })
	})

	draw_beacon : Camera.ScreenPt, F64, F64, F64, F64 -> List(Paint.DrawCmd)
	draw_beacon = |apex_s, forward, cf, view_w, bright| (if (bright < 0.02) { [] } else { beacon_disc(apex_s, forward, cf, view_w, bright) })

	beacon_disc : Camera.ScreenPt, F64, F64, F64, F64 -> List(Paint.DrawCmd)
	beacon_disc = |apex_s, forward, cf, view_w, bright| ({
		p1 = Camera.project({ right: 1.0, forward: forward, height: 0.0 }, cf, view_w)
		p0 = Camera.project({ right: 0.0, forward: forward, height: 0.0 }, cf, view_w)
		r = (beacon_radius * (p1.x - p0.x))
		(if (r < 0.5) { [] } else { Paint.push_beacon(beacon_color, apex_s.x, apex_s.y, r, bright) })
	})

	draw_flat : List(Geom.RiderPt), Geom.RiderPt, F64, F64, F64 -> List(Paint.DrawCmd)
	draw_flat = |base, center, cf, view_w, beacon_phase| (if (center.forward < Geom.near) { [] } else { draw_flat_body(base, center, cf, view_w, beacon_phase, tower_ground_drop(center)) })

	draw_flat_body : List(Geom.RiderPt), Geom.RiderPt, F64, F64, F64, F64 -> List(Paint.DrawCmd)
	draw_flat_body = |base, center, cf, view_w, beacon_phase, drop| (if (drop >= tower_height) { [] } else { draw_flat_rods(base, center, cf, view_w, beacon_phase, drop) })

	draw_flat_rods : List(Geom.RiderPt), Geom.RiderPt, F64, F64, F64, F64 -> List(Paint.DrawCmd)
	draw_flat_rods = |base, center, cf, view_w, beacon_phase, drop| ({
		apex = { right: center.right, forward: center.forward, height: (tower_height - drop) }
		wpx = rod_px(center.forward, cf, view_w)
		l = tower_legs(base, center, apex, drop, drop, wpx, cf, view_w, 0)
		r = rings(base, center, stage_height, drop, drop, wpx, cf, view_w)
		x = braces(base, center, drop, drop, wpx, cf, view_w, 0)
		b = draw_beacon(Camera.project(apex, cf, view_w), center.forward, cf, view_w, beacon_brightness(beacon_phase))
		List.concat(List.concat(List.concat(l, r), x), b)
	})
}
