# TruckBody draws the truck's body: the trailer and cab's five faces and its
# tyres, sorted far to near so the nearer faces paint over the farther ones.
import DepthSort
import Frame
import Geom
import Paint
import lib.Trig
import TruckShape
import World

TruckBody :: [].{
	TruckFace : { color : I64, fwd : F64, v : List(Geom.Vec3) }

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

	tire_color : I64
	tire_color = 1381658

	sum_fwd : List(Geom.Vec3), I64 -> F64
	sum_fwd = |ps, i| (
		if (i >= ps.len().to_i64_wrap()) {
			0.0
		} else {
			((List.get(ps, I64.to_u64_wrap(i)) ?? crash ("list-at out of range")).forward + sum_fwd(ps, (i + 1)))
		}
	)

	truck_face : I64, List(Geom.Vec3) -> TruckBody.TruckFace
	truck_face = |color, ps| { color: color, fwd: (sum_fwd(ps, 0) / I64.to_f64(ps.len().to_i64_wrap())), v: ps }

	truck_side : List(World.Segment), List(I64), Frame.Pose, I64, TruckShape.TruckBox, F64 -> TruckBody.TruckFace
	truck_side = |segs, ch, pose, d, bx, x| (
		{
			p0 = TruckShape.truck_p3(segs, ch, pose, d, bx.a0, x, TruckShape.trailer_bottom)
			p1 = TruckShape.truck_p3(segs, ch, pose, d, bx.a0, x, TruckShape.truck_height)
			p2 = TruckShape.truck_p3(segs, ch, pose, d, bx.a_roof, x, TruckShape.truck_height)
			p3 = TruckShape.truck_p3(segs, ch, pose, d, bx.a2, x, (TruckShape.truck_height / 2.0))
			p4 = TruckShape.truck_p3(segs, ch, pose, d, bx.a2, x, TruckShape.cab_bottom)
			p5 = TruckShape.truck_p3(segs, ch, pose, d, bx.a1, x, TruckShape.cab_bottom)
			p6 = TruckShape.truck_p3(segs, ch, pose, d, bx.a1, x, TruckShape.trailer_bottom)
			truck_face(side_color, [p0, p1, p2, p3, p4, p5, p6])
		}
	)

	truck_rear : List(World.Segment), List(I64), Frame.Pose, I64, TruckShape.TruckBox -> TruckBody.TruckFace
	truck_rear = |segs, ch, pose, d, bx| (
		{
			p0 = TruckShape.truck_p3(segs, ch, pose, d, bx.a0, bx.xl, TruckShape.trailer_bottom)
			p1 = TruckShape.truck_p3(segs, ch, pose, d, bx.a0, bx.xr, TruckShape.trailer_bottom)
			p2 = TruckShape.truck_p3(segs, ch, pose, d, bx.a0, bx.xr, TruckShape.truck_height)
			p3 = TruckShape.truck_p3(segs, ch, pose, d, bx.a0, bx.xl, TruckShape.truck_height)
			truck_face(body_color, [p0, p1, p2, p3])
		}
	)

	truck_roof : List(World.Segment), List(I64), Frame.Pose, I64, TruckShape.TruckBox -> TruckBody.TruckFace
	truck_roof = |segs, ch, pose, d, bx| (
		{
			p0 = TruckShape.truck_p3(segs, ch, pose, d, bx.a0, bx.xl, TruckShape.truck_height)
			p1 = TruckShape.truck_p3(segs, ch, pose, d, bx.a0, bx.xr, TruckShape.truck_height)
			p2 = TruckShape.truck_p3(segs, ch, pose, d, bx.a_roof, bx.xr, TruckShape.truck_height)
			p3 = TruckShape.truck_p3(segs, ch, pose, d, bx.a_roof, bx.xl, TruckShape.truck_height)
			truck_face(roof_color, [p0, p1, p2, p3])
		}
	)

	truck_windshield : List(World.Segment), List(I64), Frame.Pose, I64, TruckShape.TruckBox -> TruckBody.TruckFace
	truck_windshield = |segs, ch, pose, d, bx| (
		{
			p0 = TruckShape.truck_p3(segs, ch, pose, d, bx.a_roof, bx.xl, TruckShape.truck_height)
			p1 = TruckShape.truck_p3(segs, ch, pose, d, bx.a_roof, bx.xr, TruckShape.truck_height)
			p2 = TruckShape.truck_p3(segs, ch, pose, d, bx.a2, bx.xr, (TruckShape.truck_height / 2.0))
			p3 = TruckShape.truck_p3(segs, ch, pose, d, bx.a2, bx.xl, (TruckShape.truck_height / 2.0))
			truck_face(body_color, [p0, p1, p2, p3])
		}
	)

	truck_nose : List(World.Segment), List(I64), Frame.Pose, I64, TruckShape.TruckBox -> TruckBody.TruckFace
	truck_nose = |segs, ch, pose, d, bx| (
		{
			p0 = TruckShape.truck_p3(segs, ch, pose, d, bx.a2, bx.xl, (TruckShape.truck_height / 2.0))
			p1 = TruckShape.truck_p3(segs, ch, pose, d, bx.a2, bx.xr, (TruckShape.truck_height / 2.0))
			p2 = TruckShape.truck_p3(segs, ch, pose, d, bx.a2, bx.xr, TruckShape.cab_bottom)
			p3 = TruckShape.truck_p3(segs, ch, pose, d, bx.a2, bx.xl, TruckShape.cab_bottom)
			truck_face(body_color, [p0, p1, p2, p3])
		}
	)

	truck_axles : TruckShape.TruckBox -> List(F64)
	truck_axles = |bx| (
		{
			rear = (bx.a0 + trailer_axle_inset)
			front = (bx.a1 - trailer_axle_inset)
			cab = (bx.a1 + (TruckShape.cab_length * cab_axle_frac))
			[(rear - (tire_pair_gap / 2.0)), (rear + (tire_pair_gap / 2.0)), (front - (tire_pair_gap / 2.0)), (front + (tire_pair_gap / 2.0)), cab]
		}
	)

	tire_pt : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64, I64 -> Geom.Vec3
	tire_pt = |segs, ch, pose, d, ac, x, i| (
		{
			th = ((I64.to_f64(i) / I64.to_f64(tire_sides)) * Trig.two_pi)
			TruckShape.truck_p3(segs, ch, pose, d, (ac + (TruckShape.tire_radius * Trig.r_cos(th))), x, (TruckShape.tire_radius + (TruckShape.tire_radius * Trig.r_sin(th))))
		}
	)

	# tire_pts builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	tire_pts : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64, I64 -> List(Geom.Vec3)
	tire_pts = |segs, ch, pose, d, ac, x, i| tire_pts_onto(segs, ch, pose, d, ac, x, i, [])

	tire_pts_onto : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64, I64, List(Geom.Vec3) -> List(Geom.Vec3)
	tire_pts_onto = |segs, ch, pose, d, ac, x, i, acc| (
		if (i >= tire_sides) {
			acc
		} else {
			tire_pts_onto(segs, ch, pose, d, ac, x, (i + 1), List.append(acc, tire_pt(segs, ch, pose, d, ac, x, i)))
		}
	)

	# side_tires builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	side_tires : List(World.Segment), List(I64), Frame.Pose, I64, List(F64), F64 -> List(TruckBody.TruckFace)
	side_tires = |segs, ch, pose, d, axles, x| side_tires_onto(segs, ch, pose, d, axles, x, 0, [])

	side_tires_onto : List(World.Segment), List(I64), Frame.Pose, I64, List(F64), F64, I64, List(TruckBody.TruckFace) -> List(TruckBody.TruckFace)
	side_tires_onto = |segs, ch, pose, d, axles, x, i, acc| (
		if (i >= axles.len().to_i64_wrap()) {
			acc
		} else {
			side_tires_onto(segs, ch, pose, d, axles, x, (i + 1), List.append(acc, truck_face(tire_color, tire_pts(segs, ch, pose, d, (List.get(axles, I64.to_u64_wrap(i)) ?? crash ("list-at out of range")), x, 0))))
		}
	)

	truck_faces : List(World.Segment), List(I64), Frame.Pose, I64, TruckShape.TruckBox -> List(TruckBody.TruckFace)
	truck_faces = |segs, ch, pose, d, bx| (
		{
			axles = truck_axles(bx)
			List.join([[truck_side(segs, ch, pose, d, bx, bx.xl), truck_side(segs, ch, pose, d, bx, bx.xr)], [truck_rear(segs, ch, pose, d, bx), truck_roof(segs, ch, pose, d, bx)], [truck_windshield(segs, ch, pose, d, bx), truck_nose(segs, ch, pose, d, bx)], side_tires(segs, ch, pose, d, axles, bx.xl), side_tires(segs, ch, pose, d, axles, bx.xr)])
		}
	)

	# draw_faces builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	draw_faces : List(TruckBody.TruckFace), F64, F64, I64 -> List(Paint.DrawCmd)
	draw_faces = |fs, cf, view_w, i| draw_faces_onto(fs, cf, view_w, i, [])

	draw_faces_onto : List(TruckBody.TruckFace), F64, F64, I64, List(Paint.DrawCmd) -> List(Paint.DrawCmd)
	draw_faces_onto = |fs, cf, view_w, i, acc| (
		if (i >= fs.len().to_i64_wrap()) {
			acc
		} else {
			draw_faces_onto(fs, cf, view_w, (i + 1), List.concat(acc, TruckShape.truck_fill((List.get(fs, I64.to_u64_wrap(i)) ?? crash ("list-at out of range")).color, (List.get(fs, I64.to_u64_wrap(i)) ?? crash ("list-at out of range")).v, cf, view_w)))
		}
	)

	body : List(World.Segment), List(I64), Frame.Pose, I64, TruckShape.TruckBox, F64, F64 -> List(Paint.DrawCmd)
	body = |segs, ch, pose, d, bx, cf, view_w| draw_faces(DepthSort.sort_by(truck_faces(segs, ch, pose, d, bx), |face| face.fwd), cf, view_w, 0)
}
