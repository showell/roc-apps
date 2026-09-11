# TruckDraw -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Camera
import DepthSort
import DeviceMath
import Frame
import Geom
import ListUtils
import Paint
import Trig
import World

TruckDraw :: [].{
	TruckBox : { a0 : F64, a1 : F64, a2 : F64, a_roof : F64, xl : F64, xr : F64 }
	TruckFace : { color : I64, fwd : F64, v : List(Geom.Vec3) }

	truck_length : F64
	truck_length = 8.4

	truck_width : F64
	truck_width = 2.4

	truck_height : F64
	truck_height = 3.6

	cab_length : F64
	cab_length = 3.5

	cab_roof_frac : F64
	cab_roof_frac = 0.3

	tire_radius : F64
	tire_radius = 0.5

	trailer_bottom : F64
	trailer_bottom = ((2.0 * tire_radius) + 0.12)

	cab_bottom : F64
	cab_bottom = tire_radius

	tire_pair_gap : F64
	tire_pair_gap = 1.2

	trailer_axle_inset : F64
	trailer_axle_inset = 1.6

	cab_axle_frac : F64
	cab_axle_frac = 0.55

	tire_sides : I64
	tire_sides = 16

	body_color : I64
	body_color = 1846886

	roof_color : I64
	roof_color = 3822248

	side_color : I64
	side_color = 1384784

	brake_color : I64
	brake_color = 16722456

	tire_color : I64
	tire_color = 1381658

	headlight_h : F64
	headlight_h = 1.0

	headlight_inset : F64
	headlight_inset = 0.3

	cone_near_half : F64
	cone_near_half = 0.25

	cone_far_center : F64
	cone_far_center = 0.7

	cone_far_half : F64
	cone_far_half = 0.9

	cone_length : F64
	cone_length = 20.4

	beam_core : I64
	beam_core = 3288332502

	beam_edge : I64
	beam_edge = 1174403286

	glow_core : I64
	glow_core = 3875491900

	glow_edge : I64
	glow_edge = 16722456

	glow_sides : I64
	glow_sides = 16

	truck_p3 : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64, F64 -> Geom.Vec3
	truck_p3 = |segs, ch, pose, d, along, x, h| ({
		r = Frame.at(segs, ch, pose, d, along, x)
		{ right: r.right, forward: r.forward, height: (h - Geom.ground_drop(r.right, r.forward)) }
	})

	truck_box : F64, F64 -> TruckDraw.TruckBox
	truck_box = |center_along, hw| ({
		a0 = (center_along - (truck_length / 2.0))
		a1 = (center_along + (truck_length / 2.0))
		{ a0: a0, a1: a1, a2: (a1 + cab_length), a_roof: (a1 + (cab_length * cab_roof_frac)), xl: (hw - (truck_width / 2.0)), xr: (hw + (truck_width / 2.0)) }
	})

	sum_fwd : List(Geom.Vec3), I64 -> F64
	sum_fwd = |ps, i| (if (i >= U64.to_i64_wrap(List.len(ps))) { 0.0 } else { ((List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).forward + sum_fwd(ps, (i + 1))) })

	truck_face : I64, List(Geom.Vec3) -> TruckDraw.TruckFace
	truck_face = |color, ps| { color: color, fwd: (sum_fwd(ps, 0) / I64.to_f64(U64.to_i64_wrap(List.len(ps)))), v: ps }

	truck_side : List(World.Segment), List(I64), Frame.Pose, I64, TruckDraw.TruckBox, F64 -> TruckDraw.TruckFace
	truck_side = |segs, ch, pose, d, bx, x| ({
		p0 = truck_p3(segs, ch, pose, d, bx.a0, x, trailer_bottom)
		p1 = truck_p3(segs, ch, pose, d, bx.a0, x, truck_height)
		p2 = truck_p3(segs, ch, pose, d, bx.a_roof, x, truck_height)
		p3 = truck_p3(segs, ch, pose, d, bx.a2, x, (truck_height / 2.0))
		p4 = truck_p3(segs, ch, pose, d, bx.a2, x, cab_bottom)
		p5 = truck_p3(segs, ch, pose, d, bx.a1, x, cab_bottom)
		p6 = truck_p3(segs, ch, pose, d, bx.a1, x, trailer_bottom)
		truck_face(side_color, [p0, p1, p2, p3, p4, p5, p6])
	})

	truck_rear : List(World.Segment), List(I64), Frame.Pose, I64, TruckDraw.TruckBox -> TruckDraw.TruckFace
	truck_rear = |segs, ch, pose, d, bx| ({
		p0 = truck_p3(segs, ch, pose, d, bx.a0, bx.xl, trailer_bottom)
		p1 = truck_p3(segs, ch, pose, d, bx.a0, bx.xr, trailer_bottom)
		p2 = truck_p3(segs, ch, pose, d, bx.a0, bx.xr, truck_height)
		p3 = truck_p3(segs, ch, pose, d, bx.a0, bx.xl, truck_height)
		truck_face(body_color, [p0, p1, p2, p3])
	})

	truck_roof : List(World.Segment), List(I64), Frame.Pose, I64, TruckDraw.TruckBox -> TruckDraw.TruckFace
	truck_roof = |segs, ch, pose, d, bx| ({
		p0 = truck_p3(segs, ch, pose, d, bx.a0, bx.xl, truck_height)
		p1 = truck_p3(segs, ch, pose, d, bx.a0, bx.xr, truck_height)
		p2 = truck_p3(segs, ch, pose, d, bx.a_roof, bx.xr, truck_height)
		p3 = truck_p3(segs, ch, pose, d, bx.a_roof, bx.xl, truck_height)
		truck_face(roof_color, [p0, p1, p2, p3])
	})

	truck_windshield : List(World.Segment), List(I64), Frame.Pose, I64, TruckDraw.TruckBox -> TruckDraw.TruckFace
	truck_windshield = |segs, ch, pose, d, bx| ({
		p0 = truck_p3(segs, ch, pose, d, bx.a_roof, bx.xl, truck_height)
		p1 = truck_p3(segs, ch, pose, d, bx.a_roof, bx.xr, truck_height)
		p2 = truck_p3(segs, ch, pose, d, bx.a2, bx.xr, (truck_height / 2.0))
		p3 = truck_p3(segs, ch, pose, d, bx.a2, bx.xl, (truck_height / 2.0))
		truck_face(body_color, [p0, p1, p2, p3])
	})

	truck_nose : List(World.Segment), List(I64), Frame.Pose, I64, TruckDraw.TruckBox -> TruckDraw.TruckFace
	truck_nose = |segs, ch, pose, d, bx| ({
		p0 = truck_p3(segs, ch, pose, d, bx.a2, bx.xl, (truck_height / 2.0))
		p1 = truck_p3(segs, ch, pose, d, bx.a2, bx.xr, (truck_height / 2.0))
		p2 = truck_p3(segs, ch, pose, d, bx.a2, bx.xr, cab_bottom)
		p3 = truck_p3(segs, ch, pose, d, bx.a2, bx.xl, cab_bottom)
		truck_face(body_color, [p0, p1, p2, p3])
	})

	truck_axles : TruckDraw.TruckBox -> List(F64)
	truck_axles = |bx| ({
		rear = (bx.a0 + trailer_axle_inset)
		front = (bx.a1 - trailer_axle_inset)
		cab = (bx.a1 + (cab_length * cab_axle_frac))
		[(rear - (tire_pair_gap / 2.0)), (rear + (tire_pair_gap / 2.0)), (front - (tire_pair_gap / 2.0)), (front + (tire_pair_gap / 2.0)), cab]
	})

	tire_pt : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64, I64 -> Geom.Vec3
	tire_pt = |segs, ch, pose, d, ac, x, i| ({
		th = ((I64.to_f64(i) / I64.to_f64(tire_sides)) * Trig.two_pi)
		truck_p3(segs, ch, pose, d, (ac + (tire_radius * Trig.r_cos(th))), x, (tire_radius + (tire_radius * Trig.r_sin(th))))
	})

	tire_pts : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64, I64 -> List(Geom.Vec3)
	tire_pts = |segs, ch, pose, d, ac, x, i| (if (i >= tire_sides) { [] } else { List.concat([tire_pt(segs, ch, pose, d, ac, x, i)], tire_pts(segs, ch, pose, d, ac, x, (i + 1))) })

	side_tires : List(World.Segment), List(I64), Frame.Pose, I64, List(F64), F64, I64 -> List(TruckDraw.TruckFace)
	side_tires = |segs, ch, pose, d, axles, x, i| (if (i >= U64.to_i64_wrap(List.len(axles))) { [] } else { List.concat([truck_face(tire_color, tire_pts(segs, ch, pose, d, (List.get(axles, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), x, 0))], side_tires(segs, ch, pose, d, axles, x, (i + 1))) })

	truck_faces : List(World.Segment), List(I64), Frame.Pose, I64, TruckDraw.TruckBox -> List(TruckDraw.TruckFace)
	truck_faces = |segs, ch, pose, d, bx| ({
		axles = truck_axles(bx)
		List.concat(List.concat(List.concat(List.concat([truck_side(segs, ch, pose, d, bx, bx.xl), truck_side(segs, ch, pose, d, bx, bx.xr)], [truck_rear(segs, ch, pose, d, bx), truck_roof(segs, ch, pose, d, bx)]), [truck_windshield(segs, ch, pose, d, bx), truck_nose(segs, ch, pose, d, bx)]), side_tires(segs, ch, pose, d, axles, bx.xl, 0)), side_tires(segs, ch, pose, d, axles, bx.xr, 0))
	})

	face_rest : List(TruckDraw.TruckFace), I64 -> List(TruckDraw.TruckFace)
	face_rest = |ys, j| (if (j >= U64.to_i64_wrap(List.len(ys))) { [] } else { List.concat([(List.get(ys, I64.to_u64_wrap(j)) ?? crash("list-at out of range"))], face_rest(ys, (j + 1))) })

	merge_faces : List(TruckDraw.TruckFace), List(TruckDraw.TruckFace), I64, I64 -> List(TruckDraw.TruckFace)
	merge_faces = |a, b, i, j| (if (i >= U64.to_i64_wrap(List.len(a))) { face_rest(b, j) } else { (if (j >= U64.to_i64_wrap(List.len(b))) { face_rest(a, i) } else { (if DepthSort.deeper_than((List.get(b, I64.to_u64_wrap(j)) ?? crash("list-at out of range")).fwd, (List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).fwd) { List.concat([(List.get(b, I64.to_u64_wrap(j)) ?? crash("list-at out of range"))], merge_faces(a, b, i, (j + 1))) } else { List.concat([(List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))], merge_faces(a, b, (i + 1), j)) }) }) })

	sort_faces : List(TruckDraw.TruckFace) -> List(TruckDraw.TruckFace)
	sort_faces = |xs| (if (U64.to_i64_wrap(List.len(xs)) <= 1) { xs } else { merge_faces(sort_faces(ListUtils.list_take(xs, I64.div_trunc_by(U64.to_i64_wrap(List.len(xs)), 2))), sort_faces(ListUtils.list_drop(xs, I64.div_trunc_by(U64.to_i64_wrap(List.len(xs)), 2))), 0, 0) })

	truck_fill : I64, List(Geom.Vec3), F64, F64 -> List(Paint.DrawCmd)
	truck_fill = |color, ps, cf, view_w| Paint.push_poly(color, Camera.project_all(Geom.clip_near(ps, Geom.near), cf, view_w, 0))

	draw_faces : List(TruckDraw.TruckFace), F64, F64, I64 -> List(Paint.DrawCmd)
	draw_faces = |fs, cf, view_w, i| (if (i >= U64.to_i64_wrap(List.len(fs))) { [] } else { List.concat(truck_fill((List.get(fs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).color, (List.get(fs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).v, cf, view_w), draw_faces(fs, cf, view_w, (i + 1))) })

	any_behind : List(Geom.Vec3), I64 -> Bool
	any_behind = |ps, i| (if (i >= U64.to_i64_wrap(List.len(ps))) { False } else { (if ((List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).forward <= Geom.near) { True } else { any_behind(ps, (i + 1)) }) })

	mid_vec : Geom.Vec3, Geom.Vec3 -> Geom.Vec3
	mid_vec = |p, q| { right: ((p.right + q.right) / 2.0), forward: ((p.forward + q.forward) / 2.0), height: ((p.height + q.height) / 2.0) }

	pt_dist : Camera.ScreenPt, Camera.ScreenPt -> F64
	pt_dist = |p, c| DeviceMath.real_sqrt((((p.x - c.x) * (p.x - c.x)) + ((p.y - c.y) * (p.y - c.y))))

	max_radius : List(Camera.ScreenPt), Camera.ScreenPt, I64 -> F64
	max_radius = |sp, c, i| (if (i >= U64.to_i64_wrap(List.len(sp))) { 0.0 } else { DeviceMath.real_max(pt_dist((List.get(sp, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), c), max_radius(sp, c, (i + 1))) })

	truck_wedge : List(World.Segment), List(I64), Frame.Pose, I64, TruckDraw.TruckBox, F64, F64, F64 -> List(Paint.DrawCmd)
	truck_wedge = |segs, ch, pose, d, bx, src_x, cf, view_w| ({
		p0 = truck_p3(segs, ch, pose, d, bx.a2, src_x, (headlight_h - cone_near_half))
		p1 = truck_p3(segs, ch, pose, d, bx.a2, src_x, (headlight_h + cone_near_half))
		p2 = truck_p3(segs, ch, pose, d, (bx.a2 + cone_length), src_x, (cone_far_center + cone_far_half))
		p3 = truck_p3(segs, ch, pose, d, (bx.a2 + cone_length), src_x, (cone_far_center - cone_far_half))
		wedge_emit([p0, p1, p2, p3], cf, view_w)
	})

	wedge_emit : List(Geom.Vec3), F64, F64 -> List(Paint.DrawCmd)
	wedge_emit = |ps, cf, view_w| (if any_behind(ps, 0) { [] } else { wedge_cmd(ps, cf, view_w) })

	wedge_cmd : List(Geom.Vec3), F64, F64 -> List(Paint.DrawCmd)
	wedge_cmd = |ps, cf, view_w| ({
		sp = Camera.project_all(ps, cf, view_w, 0)
		lamp = Camera.project(mid_vec((List.get(ps, I64.to_u64_wrap(0)) ?? crash("list-at out of range")), (List.get(ps, I64.to_u64_wrap(1)) ?? crash("list-at out of range"))), cf, view_w)
		Paint.push_grad_poly(beam_core, beam_edge, lamp.x, lamp.y, max_radius(sp, lamp, 0), sp)
	})

	truck_wedges : List(World.Segment), List(I64), Frame.Pose, I64, TruckDraw.TruckBox, F64, F64 -> List(Paint.DrawCmd)
	truck_wedges = |segs, ch, pose, d, bx, cf, view_w| List.concat(truck_wedge(segs, ch, pose, d, bx, (bx.xl + headlight_inset), cf, view_w), truck_wedge(segs, ch, pose, d, bx, (bx.xr - headlight_inset), cf, view_w))

	sum_x : List(Camera.ScreenPt), I64 -> F64
	sum_x = |ps, i| (if (i >= U64.to_i64_wrap(List.len(ps))) { 0.0 } else { ((List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).x + sum_x(ps, (i + 1))) })

	sum_y : List(Camera.ScreenPt), I64 -> F64
	sum_y = |ps, i| (if (i >= U64.to_i64_wrap(List.len(ps))) { 0.0 } else { ((List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).y + sum_y(ps, (i + 1))) })

	glow_pt : F64, F64, F64, I64 -> Camera.ScreenPt
	glow_pt = |cx, cy, rad, i| ({
		th = ((I64.to_f64(i) / I64.to_f64(glow_sides)) * Trig.two_pi)
		{ x: (cx + (rad * Trig.r_cos(th))), y: (cy + (rad * Trig.r_sin(th))) }
	})

	glow_circle : F64, F64, F64, I64 -> List(Camera.ScreenPt)
	glow_circle = |cx, cy, rad, i| (if (i >= glow_sides) { [] } else { List.concat([glow_pt(cx, cy, rad, i)], glow_circle(cx, cy, rad, (i + 1))) })

	brake_glow : List(Geom.Vec3), F64, F64 -> List(Paint.DrawCmd)
	brake_glow = |panel, cf, view_w| (if any_behind(panel, 0) { [] } else { glow_cmd(panel, cf, view_w) })

	glow_cmd : List(Geom.Vec3), F64, F64 -> List(Paint.DrawCmd)
	glow_cmd = |panel, cf, view_w| ({
		sp = Camera.project_all(panel, cf, view_w, 0)
		cx = (sum_x(sp, 0) / 4.0)
		cy = (sum_y(sp, 0) / 4.0)
		rad = (max_radius(sp, { x: cx, y: cy }, 0) * 3.2)
		Paint.push_grad_poly(glow_core, glow_edge, cx, cy, rad, glow_circle(cx, cy, rad, 0))
	})

	brake_light : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64, F64, F64, F64 -> List(Paint.DrawCmd)
	brake_light = |segs, ch, pose, d, a0, x0, x1, cf, view_w| ({
		bl = (trailer_bottom + (0.2 * (truck_height - trailer_bottom)))
		bh = (trailer_bottom + (0.5 * (truck_height - trailer_bottom)))
		q0 = truck_p3(segs, ch, pose, d, a0, x0, bl)
		q1 = truck_p3(segs, ch, pose, d, a0, x1, bl)
		q2 = truck_p3(segs, ch, pose, d, a0, x1, bh)
		q3 = truck_p3(segs, ch, pose, d, a0, x0, bh)
		emit_brake([q0, q1, q2, q3], cf, view_w)
	})

	emit_brake : List(Geom.Vec3), F64, F64 -> List(Paint.DrawCmd)
	emit_brake = |panel, cf, view_w| List.concat(brake_glow(panel, cf, view_w), truck_fill(brake_color, panel, cf, view_w))

	brake_lights : List(World.Segment), List(I64), Frame.Pose, I64, TruckDraw.TruckBox, F64, F64 -> List(Paint.DrawCmd)
	brake_lights = |segs, ch, pose, d, bx, cf, view_w| List.concat(brake_light(segs, ch, pose, d, bx.a0, (bx.xl + (0.1 * truck_width)), (bx.xl + (0.36 * truck_width)), cf, view_w), brake_light(segs, ch, pose, d, bx.a0, (bx.xr - (0.36 * truck_width)), (bx.xr - (0.1 * truck_width)), cf, view_w))

	truck_draw_body : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64, Bool, Bool, F64, F64 -> List(Paint.DrawCmd)
	truck_draw_body = |segs, ch, pose, d, center_along, hw, braking, headlights, cf, view_w| ({
		bx = truck_box(center_along, hw)
		beams = (if headlights { truck_wedges(segs, ch, pose, d, bx, cf, view_w) } else { [] })
		body = draw_faces(sort_faces(truck_faces(segs, ch, pose, d, bx)), cf, view_w, 0)
		lights = (if braking { brake_lights(segs, ch, pose, d, bx, cf, view_w) } else { [] })
		List.concat(List.concat(beams, body), lights)
	})
}
