## Ground paints a flat patch of ground, such as a stretch of road or a
## pond, as one polygon. The patch follows the earth's curve down as it
## goes away from the rider.
import Camera
import Geom
import Paint
import lib.Brush
import lib.Shapes

Ground :: [].{

	## A patch of ground to paint: its corners and its colour.
	Patch : { corners : List(Geom.RiderPoint), color : I64 }

	## A point on the ground, lowered by the earth's curve.
	ground_point : Geom.RiderPoint -> Geom.RaisedPoint
	ground_point = |point| {
		right: point.right,
		forward: point.forward,
		height: (0.0 - Geom.ground_drop(point)),
	}

	## A patch on screen, cut at the camera's near plane. A patch with more
	## than eight corners, or with fewer than three left in front of the
	## camera, draws nothing.
	draw : Ground.Patch, F64 -> List(Shapes.Shape)
	draw = |patch, cam_focal|
		if patch.corners.len() > 8 {
			[]
		} else {
			in_front = Geom.clip_near(patch.corners.map(Ground.ground_point))
			if in_front.len() < 3 {
				[]
			} else {
				Paint.push_poly(patch.color, Camera.project_all(in_front, cam_focal))
			}
		}
}

expect Ground.ground_point({ right: 0.0, forward: 0.0 }).height == 0.0
expect
	Ground.ground_point({ right: 3.0, forward: 10.0 })
		== {
			right: 3.0,
			forward: 10.0,
			height: -0.000545,
		}
expect Ground.ground_point({ right: -5.0, forward: 40.0 }).height == -0.008125
expect
	Ground.ground_point({ right: 12.5, forward: 100.0 })
		== {
			right: 12.5,
			forward: 100.0,
			height: -0.05078125,
		}

patch_shapes : List(Geom.RiderPoint) -> List(Shapes.Shape)
patch_shapes = |corners| Ground.draw({ corners, color: 3112588 }, 685.5110432362151)

patch_ahead : List(Geom.RiderPoint)
patch_ahead = [
	{ right: -5.0, forward: 10.0 },
	{ right: 5.0, forward: 10.0 },
	{ right: 5.0, forward: 20.0 },
	{ right: -5.0, forward: 20.0 },
]

# A patch of `count` corners, all ahead of the camera.
corners_ahead : I64 -> List(Geom.RiderPoint)
corners_ahead = |count|
	List.from_iter(I64.until(0, count)).map(
		|k| {
			offset = (count - k).to_f64()
			{ right: offset, forward: 10.0 + offset }
		},
	)

expect patch_shapes(patch_ahead).len() == 1
expect patch_shapes(corners_ahead(8)).len() == 1
expect patch_shapes(corners_ahead(9)).len() == 0

expect
	patch_shapes([
		{ right: -5.0, forward: -10.0 },
		{ right: 5.0, forward: -10.0 },
		{ right: 5.0, forward: -20.0 },
		{ right: -5.0, forward: -20.0 },
	]).len()
		== 0

expect patch_shapes([{ right: -5.0, forward: 10.0 }, { right: 5.0, forward: 10.0 }]).len() == 0

expect {
	match patch_shapes(patch_ahead) {
		[Poly(polygon)] => polygon.fill == Flat(Brush.opaque(3112588)) and polygon.pts.len() == 8
		_ => False
	}
}
