# TruckShape holds the truck's size and the box it occupies on the road, and
# places a point on the truck in the rider's view. Its `truck_fill` clips,
# projects and fills one polygon, for the body's faces and the brake lights.
import Camera
import Frame
import Geom
import Paint
import World

TruckShape :: [].{
	TruckBox : { a0 : F64, a1 : F64, a2 : F64, a_roof : F64, xl : F64, xr : F64 }

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

	truck_p3 : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64, F64 -> Geom.Vec3
	truck_p3 = |segs, ch, pose, d, along, x, h| (
		{
			r = Frame.at(segs, ch, pose, d, along, x)
			{ right: r.right, forward: r.forward, height: (h - Geom.ground_drop(r.right, r.forward)) }
		}
	)

	truck_box : F64, F64 -> TruckShape.TruckBox
	truck_box = |center_along, hw| (
		{
			a0 = (center_along - (truck_length / 2.0))
			a1 = (center_along + (truck_length / 2.0))
			{ a0: a0, a1: a1, a2: (a1 + cab_length), a_roof: (a1 + (cab_length * cab_roof_frac)), xl: (hw - (truck_width / 2.0)), xr: (hw + (truck_width / 2.0)) }
		}
	)

	truck_fill : I64, List(Geom.Vec3), F64, F64 -> List(Paint.DrawCmd)
	truck_fill = |color, ps, cf, view_w| Paint.push_poly(color, Camera.project_all(Geom.clip_near(ps), cf, view_w))
}
