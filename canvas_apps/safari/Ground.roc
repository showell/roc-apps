## Ground paints a flat patch of ground, such as a stretch of road or a
## pond, as one polygon. The patch follows the earth's curve down as it
## goes away from the rider.
import Camera
import Geom
import Paint
import lib.Shapes

Ground :: [].{

	## A point on the ground, lowered by the earth's curve.
	ground_point : Geom.RiderPoint -> Geom.SpacePoint
	ground_point = |point| {
		right: point.right,
		forward: point.forward,
		height: (0.0 - Geom.ground_drop(point)),
	}

	## A patch of `color` with these corners, cut at the camera's near plane.
	## A patch with more than eight corners, or with fewer than three left
	## in front of the camera, draws nothing.
	draw : {
		corners : List(Geom.RiderPoint),
		color : I64,
		cam_focal : F64,
		view_w : F64,
	} -> List(Shapes.Shape)
	draw = |
		{
			corners,
			color,
			cam_focal,
			view_w,
		},
	|
		if corners.len() > 8 {
			[]
		} else {
			in_front = Geom.clip_near(corners.map(Ground.ground_point))
			if in_front.len() < 3 {
				[]
			} else {
				Paint.push_poly(color, Camera.project_all(in_front, { cam_focal, view_w }))
			}
		}
}
