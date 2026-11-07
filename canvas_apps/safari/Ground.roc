## Ground paints a flat patch of ground, such as a stretch of road or a
## pond, as one polygon. The patch follows the earth's curve down as it
## goes away from the rider.
import Pixels
import Camera
import Distance
import Geom
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
		height: Geom.ground_drop(point).opposite(),
	}

	## A patch on screen, cut at the camera's near plane, unless it's wholly
	## behind the camera.
	patch_shape : Ground.Patch, Pixels -> Try(Shapes.Shape, [BehindCamera])
	patch_shape = |patch, cam_focal|
		Camera.clipped_polygon(
			{ color: patch.color, corners: patch.corners.map(Ground.ground_point) },
			cam_focal,
		)
}

expect Ground.ground_point({
	right: Distance.metres(0.0),
	forward: Distance.metres(0.0),
}).height.to_metres() == 0.0
expect
	Ground.ground_point({ right: Distance.metres(3.0), forward: Distance.metres(10.0) })
		== {
			right: Distance.metres(3.0),
			forward: Distance.metres(10.0),
			height: Distance.metres(-0.000545),
		}
expect Ground.ground_point({
	right: Distance.metres(-5.0),
	forward: Distance.metres(40.0),
}).height.to_metres() == -0.008125
expect
	Ground.ground_point({ right: Distance.metres(12.5), forward: Distance.metres(100.0) })
		== {
			right: Distance.metres(12.5),
			forward: Distance.metres(100.0),
			height: Distance.metres(-0.05078125),
		}

sample_patch_shape : List(Geom.RiderPoint) -> Try(Shapes.Shape, [BehindCamera])
sample_patch_shape = |corners| Ground.patch_shape(
	{ corners, color: 0x2F7E8C },
	Pixels.of(685.5110432362151),
)

patch_corners_ahead : List(Geom.RiderPoint)
patch_corners_ahead = [
	{ right: Distance.metres(-5.0), forward: Distance.metres(10.0) },
	{ right: Distance.metres(5.0), forward: Distance.metres(10.0) },
	{ right: Distance.metres(5.0), forward: Distance.metres(20.0) },
	{ right: Distance.metres(-5.0), forward: Distance.metres(20.0) },
]

# A patch of `count` corners, all ahead of the camera.
corners_ahead : I64 -> List(Geom.RiderPoint)
corners_ahead = |count|
	List.from_iter(I64.until(0, count)).map(
		|k| {
			offset = (count - k).to_f64()
			{ right: Distance.metres(offset), forward: Distance.metres(10.0 + offset) }
		},
	)

expect sample_patch_shape(patch_corners_ahead).is_ok()
expect sample_patch_shape(corners_ahead(8)).is_ok()
expect sample_patch_shape(corners_ahead(9)).is_ok()

expect
	sample_patch_shape([
		{ right: Distance.metres(-5.0), forward: Distance.metres(-10.0) },
		{ right: Distance.metres(5.0), forward: Distance.metres(-10.0) },
		{ right: Distance.metres(5.0), forward: Distance.metres(-20.0) },
		{ right: Distance.metres(-5.0), forward: Distance.metres(-20.0) },
	]).is_err()

expect {
	match sample_patch_shape(patch_corners_ahead) {
		Ok(Poly(polygon)) =>
			polygon.fill == Flat(Brush.opaque(0x2F7E8C)) and polygon.coordinates.len() == 8
		_ => False
	}
}
