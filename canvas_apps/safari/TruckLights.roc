# TruckLights draws the truck's lights: the two headlight beams ahead of the
# cab, and the two brake lights on the trailer's rear, each with its glow.
import Camera
import lib.DeviceMath
import Frame
import Geom
import Paint
import lib.Trig
import TruckShape
import World

TruckLights :: [].{
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

	brake_color : I64
	brake_color = 16722456

	glow_sides : I64
	glow_sides = 16

	any_behind : List(Geom.Vec3) -> Bool
	any_behind = |ps| ps.any(|p| p.forward <= Geom.near)

	mid_vec : Geom.Vec3, Geom.Vec3 -> Geom.Vec3
	mid_vec = |p, q| { right: ((p.right + q.right) / 2.0), forward: ((p.forward + q.forward) / 2.0), height: ((p.height + q.height) / 2.0) }

	pt_dist : Camera.ScreenPt, Camera.ScreenPt -> F64
	pt_dist = |p, c| DeviceMath.real_sqrt((((p.x - c.x) * (p.x - c.x)) + ((p.y - c.y) * (p.y - c.y))))

	max_radius : List(Camera.ScreenPt), Camera.ScreenPt -> F64
	max_radius = |sp, c| max_radius_from(sp, c, 0)

	max_radius_from : List(Camera.ScreenPt), Camera.ScreenPt, I64 -> F64
	max_radius_from = |sp, c, i| (
		if (i >= sp.len().to_i64_wrap()) {
			0.0
		} else {
			DeviceMath.real_max(pt_dist((List.get(sp, I64.to_u64_wrap(i)) ?? crash ("list-at out of range")), c), max_radius_from(sp, c, (i + 1)))
		}
	)

	truck_wedge : List(World.Segment), List(I64), Frame.Pose, I64, TruckShape.TruckBox, F64, F64, F64 -> List(Paint.DrawCmd)
	truck_wedge = |segs, ch, pose, d, bx, src_x, cf, view_w| (
		{
			p0 = TruckShape.truck_p3(segs, ch, pose, d, bx.a2, src_x, (headlight_h - cone_near_half))
			p1 = TruckShape.truck_p3(segs, ch, pose, d, bx.a2, src_x, (headlight_h + cone_near_half))
			p2 = TruckShape.truck_p3(segs, ch, pose, d, (bx.a2 + cone_length), src_x, (cone_far_center + cone_far_half))
			p3 = TruckShape.truck_p3(segs, ch, pose, d, (bx.a2 + cone_length), src_x, (cone_far_center - cone_far_half))
			wedge_emit([p0, p1, p2, p3], cf, view_w)
		}
	)

	wedge_emit : List(Geom.Vec3), F64, F64 -> List(Paint.DrawCmd)
	wedge_emit = |ps, cf, view_w| (
		if any_behind(ps) {
			[]
		} else {
			wedge_cmd(ps, cf, view_w)
		}
	)

	wedge_cmd : List(Geom.Vec3), F64, F64 -> List(Paint.DrawCmd)
	wedge_cmd = |ps, cf, view_w| (
		{
			sp = Camera.project_all(ps, cf, view_w)
			lamp = Camera.project(mid_vec((List.get(ps, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")), (List.get(ps, I64.to_u64_wrap(1)) ?? crash ("list-at out of range"))), cf, view_w)
			Paint.push_grad_poly(beam_core, beam_edge, lamp.x, lamp.y, max_radius(sp, lamp), sp)
		}
	)

	truck_wedges : List(World.Segment), List(I64), Frame.Pose, I64, TruckShape.TruckBox, F64, F64 -> List(Paint.DrawCmd)
	truck_wedges = |segs, ch, pose, d, bx, cf, view_w| List.concat(truck_wedge(segs, ch, pose, d, bx, (bx.xl + headlight_inset), cf, view_w), truck_wedge(segs, ch, pose, d, bx, (bx.xr - headlight_inset), cf, view_w))

	sum_x : List(Camera.ScreenPt), I64 -> F64
	sum_x = |ps, i| (
		if (i >= ps.len().to_i64_wrap()) {
			0.0
		} else {
			((List.get(ps, I64.to_u64_wrap(i)) ?? crash ("list-at out of range")).x + sum_x(ps, (i + 1)))
		}
	)

	sum_y : List(Camera.ScreenPt), I64 -> F64
	sum_y = |ps, i| (
		if (i >= ps.len().to_i64_wrap()) {
			0.0
		} else {
			((List.get(ps, I64.to_u64_wrap(i)) ?? crash ("list-at out of range")).y + sum_y(ps, (i + 1)))
		}
	)

	glow_pt : F64, F64, F64, I64 -> Camera.ScreenPt
	glow_pt = |cx, cy, rad, i| (
		{
			th = ((I64.to_f64(i) / I64.to_f64(glow_sides)) * Trig.two_pi)
			{ x: (cx + (rad * Trig.r_cos(th))), y: (cy + (rad * Trig.r_sin(th))) }
		}
	)

	# glow_circle builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	glow_circle : F64, F64, F64, I64 -> List(Camera.ScreenPt)
	glow_circle = |cx, cy, rad, i| glow_circle_onto(cx, cy, rad, i, [])

	glow_circle_onto : F64, F64, F64, I64, List(Camera.ScreenPt) -> List(Camera.ScreenPt)
	glow_circle_onto = |cx, cy, rad, i, acc| (
		if (i >= glow_sides) {
			acc
		} else {
			glow_circle_onto(cx, cy, rad, (i + 1), List.append(acc, glow_pt(cx, cy, rad, i)))
		}
	)

	brake_glow : List(Geom.Vec3), F64, F64 -> List(Paint.DrawCmd)
	brake_glow = |panel, cf, view_w| (
		if any_behind(panel) {
			[]
		} else {
			glow_cmd(panel, cf, view_w)
		}
	)

	glow_cmd : List(Geom.Vec3), F64, F64 -> List(Paint.DrawCmd)
	glow_cmd = |panel, cf, view_w| (
		{
			sp = Camera.project_all(panel, cf, view_w)
			cx = (sum_x(sp, 0) / 4.0)
			cy = (sum_y(sp, 0) / 4.0)
			rad = (max_radius(sp, { x: cx, y: cy }) * 3.2)
			Paint.push_grad_poly(glow_core, glow_edge, cx, cy, rad, glow_circle(cx, cy, rad, 0))
		}
	)

	brake_light : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64, F64, F64, F64 -> List(Paint.DrawCmd)
	brake_light = |segs, ch, pose, d, a0, x0, x1, cf, view_w| (
		{
			bl = (TruckShape.trailer_bottom + (0.2 * (TruckShape.truck_height - TruckShape.trailer_bottom)))
			bh = (TruckShape.trailer_bottom + (0.5 * (TruckShape.truck_height - TruckShape.trailer_bottom)))
			q0 = TruckShape.truck_p3(segs, ch, pose, d, a0, x0, bl)
			q1 = TruckShape.truck_p3(segs, ch, pose, d, a0, x1, bl)
			q2 = TruckShape.truck_p3(segs, ch, pose, d, a0, x1, bh)
			q3 = TruckShape.truck_p3(segs, ch, pose, d, a0, x0, bh)
			emit_brake([q0, q1, q2, q3], cf, view_w)
		}
	)

	emit_brake : List(Geom.Vec3), F64, F64 -> List(Paint.DrawCmd)
	emit_brake = |panel, cf, view_w| List.concat(brake_glow(panel, cf, view_w), TruckShape.truck_fill(brake_color, panel, cf, view_w))

	brake_lights : List(World.Segment), List(I64), Frame.Pose, I64, TruckShape.TruckBox, F64, F64 -> List(Paint.DrawCmd)
	brake_lights = |segs, ch, pose, d, bx, cf, view_w| List.concat(brake_light(segs, ch, pose, d, bx.a0, (bx.xl + (0.1 * TruckShape.truck_width)), (bx.xl + (0.36 * TruckShape.truck_width)), cf, view_w), brake_light(segs, ch, pose, d, bx.a0, (bx.xr - (0.36 * TruckShape.truck_width)), (bx.xr - (0.1 * TruckShape.truck_width)), cf, view_w))
}
