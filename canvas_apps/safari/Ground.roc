## Ground gives a flat patch of ground, such as a stretch of road or a pond, as
## one polygon. The patch follows the earth's curve down as it goes away from
## the rider.
import Pixels
import Camera
import Distance
import Fraction
import Geom
import lib.Brush
import lib.RgbColor
import lib.Shapes

Ground :: [].{

	## A patch of ground: its corners and its colour.
	Patch : { corners : List(Geom.RiderPoint), color : RgbColor }

	## The radius the ground, and the truck on it, curve away over. From the
	## rider's eye it puts the horizon 490 metres out, at
	## `Ground.horizon_distance`.
	ground_curve_radius : Distance
	ground_curve_radius = Distance.metres(100000.0)

	## How far the ground has curved away below level at `point`, which is
	## never negative.
	ground_drop : Geom.RiderPoint -> Distance
	ground_drop = |{ right, forward }| {
		r = right.to_metres()
		f = forward.to_metres()
		Distance.metres((r * r + f * f) / (2.0 * ground_curve_radius.to_metres()))
	}

	## How far from the rider the ground curves out of sight. A lowered point
	## further out lands lower on screen again, so ground past here would show
	## as slivers on the grass.
	horizon_distance : Distance
	horizon_distance = {
		radius = Ground.ground_curve_radius.to_metres()
		Distance.metres((2.0 * radius * Camera.eye_height.to_metres()).sqrt())
	}

	## A patch on screen, cut at the horizon and at the camera's near plane,
	## unless nothing of it is left.
	patch_shape : Ground.Patch, Pixels -> Try(Shapes.Shape, [PastHorizon, BehindCamera])
	patch_shape = |patch, cam_focal| {
		lowered = patch.corners.map(ground_point)
		before_horizon = points_within(lowered, horizon_distance)
		if before_horizon.is_empty() {
			Err(PastHorizon)
		} else {
			polygon = { color: patch.color, corners: before_horizon }
			shape = Camera.clipped_polygon(polygon, cam_focal)?
			Ok(shape)
		}
	}
}

## A point on the ground, lowered by the earth's curve.
ground_point : Geom.RiderPoint -> Geom.RaisedPoint
ground_point = |point| {
	right: point.right,
	forward: point.forward,
	height: Ground.ground_drop(point).opposite(),
}

## The polygon cut to what lies within `reach` of the rider, measured on
## the ground. Where an edge leaves that circle and another comes back
## into it, a straight line joins them.
points_within : List(Geom.RaisedPoint), Distance -> List(Geom.RaisedPoint)
points_within = |polygon_points, reach| {
	next_corners = polygon_points.drop_first(1).concat(polygon_points.take_first(1))
	edges = polygon_points.map2(next_corners, |from, to| { from, to, reach })
	edges.fold(List.with_capacity(2 * polygon_points.len()), reach_points_onto)
}

## `points_within` with what one edge of a polygon adds to it: the edge's first
## corner if that is within reach, then each point where the edge crosses the
## circle at `reach`, in order along the edge.
reach_points_onto : List(Geom.RaisedPoint),
{
	from : Geom.RaisedPoint,
	to : Geom.RaisedPoint,
	reach : Distance,
} -> List(Geom.RaisedPoint)
reach_points_onto = |kept_points, { from, to, reach }| {
	with_corner = if is_within(from, reach) {
		kept_points.append(from)
	} else {
		kept_points
	}
	circle_crossings({ from, to, reach }).fold(
		with_corner,
		|points, fraction| points.append(Geom.point_between({ from, to, fraction })),
	)
}

## Whether `point` is within `reach` of the rider, measured on the ground.
is_within : Geom.RaisedPoint, Distance -> Bool
is_within = |point, reach| {
	r = point.right.to_metres()
	f = point.forward.to_metres()
	r * r + f * f <= reach.to_metres() * reach.to_metres()
}

## How far along the edge from `from` to `to` it crosses the circle at `reach`
## round the rider, as fractions of the edge strictly between its ends,
## nearest `from` first.
##
## The point a share t of the way along is `from` plus t steps, and it is on
## the circle where its squared distance equals the squared reach, a quadratic
## in t.
circle_crossings : {
	from : Geom.RaisedPoint,
	to : Geom.RaisedPoint,
	reach : Distance,
} -> List(Fraction)
circle_crossings = |{ from, to, reach }| {
	start_right = from.right.to_metres()
	start_forward = from.forward.to_metres()
	step_right = to.right.to_metres() - start_right
	step_forward = to.forward.to_metres() - start_forward
	step_squared = step_right * step_right + step_forward * step_forward
	outward = start_right * step_right + start_forward * step_forward
	reach_squared = reach.to_metres() * reach.to_metres()
	start_past_reach = start_right * start_right + start_forward * start_forward - reach_squared
	discriminant = outward * outward - step_squared * start_past_reach
	if step_squared == 0.0 or discriminant <= 0.0 {
		[]
	} else {
		root = discriminant.sqrt()
		entering = (0.0 - outward - root) / step_squared
		leaving = (0.0 - outward + root) / step_squared
		[entering, leaving].keep_if(|share| share > 0.0 and share < 1.0).map(Fraction.of)
	}
}

expect Ground.ground_drop({
	right: Distance.metres(0.0),
	forward: Distance.metres(0.0),
}).to_metres() == 0.0
expect Ground.ground_drop({
	right: Distance.metres(3.0),
	forward: Distance.metres(10.0),
}).to_metres() == 0.000545
expect Ground.ground_drop({
	right: Distance.metres(-5.0),
	forward: Distance.metres(40.0),
}).to_metres() == 0.008125
expect Ground.ground_drop({
	right: Distance.metres(12.5),
	forward: Distance.metres(100.0),
}).to_metres() == 0.05078125

## A point on the level of the rider, `right` and `forward` in metres.
level_at : F64, F64 -> Geom.RaisedPoint
level_at = |right, forward| {
	right: Distance.metres(right),
	forward: Distance.metres(forward),
	height: Distance.zero,
}

## Whether a point is within a nanometre of `right` and `forward`, in metres.
is_level_near : Geom.RaisedPoint, (F64, F64) -> Bool
is_level_near = |point, (right, forward)| {
	right_miss = (point.right.to_metres() - right).abs()
	forward_miss = (point.forward.to_metres() - forward).abs()
	right_miss <= 0.000000001 and forward_miss <= 0.000000001
}

## Whether each point is near its want.
are_near : List(Geom.RaisedPoint), List((F64, F64)) -> Bool
are_near = |got_points, wants| {
	is_each_near = got_points.map2(wants, is_level_near).all(|is_close| is_close)
	got_points.len() == wants.len() and is_each_near
}

# A square that reaches past 10 m of the rider keeps two corners, then where its
# right side leaves the circle, then where its left side comes back in.
expect {
	square = [
		level_at(-6.0, 0.0),
		level_at(6.0, 0.0),
		level_at(6.0, 12.0),
		level_at(-6.0, 12.0),
	]
	are_near(
		points_within(square, Distance.metres(10.0)),
		[
			(-6.0, 0.0),
			(6.0, 0.0),
			(6.0, 8.0),
			(-6.0, 8.0),
		],
	)
}

# An edge with both ends past reach that passes through the circle adds where
# it enters and where it leaves.
expect {
	triangle = [
		level_at(-20.0, 6.0),
		level_at(20.0, 6.0),
		level_at(0.0, 30.0),
	]
	are_near(points_within(triangle, Distance.metres(10.0)), [(-8.0, 6.0), (8.0, 6.0)])
}

# A polygon wholly past reach leaves nothing.
expect {
	far_triangle = [
		level_at(20.0, 20.0),
		level_at(30.0, 20.0),
		level_at(30.0, 30.0),
	]
	points_within(far_triangle, Distance.metres(10.0)).is_empty()
}

expect ground_point({
	right: Distance.metres(0.0),
	forward: Distance.metres(0.0),
}).height.to_metres() == 0.0
expect
	ground_point({ right: Distance.metres(3.0), forward: Distance.metres(10.0) })
		== {
			right: Distance.metres(3.0),
			forward: Distance.metres(10.0),
			height: Distance.metres(-0.000545),
		}
expect ground_point({
	right: Distance.metres(-5.0),
	forward: Distance.metres(40.0),
}).height.to_metres() == -0.008125
expect
	ground_point({ right: Distance.metres(12.5), forward: Distance.metres(100.0) })
		== {
			right: Distance.metres(12.5),
			forward: Distance.metres(100.0),
			height: Distance.metres(-0.05078125),
		}

sample_patch_shape : List(Geom.RiderPoint) -> Try(Shapes.Shape, [PastHorizon, BehindCamera])
sample_patch_shape = |corners| Ground.patch_shape(
	{ corners, color: RgbColor.of(0x2F7E8C) },
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

expect (Ground.horizon_distance.to_metres() - 489.89794855663564).abs() <= 0.000000001

## What became of a patch: drawn, or why not.
outcome : Try(Shapes.Shape, [PastHorizon, BehindCamera]) -> [Drawn, PastHorizon, BehindCamera]
outcome = |shape|
	match shape {
		Ok(_) => Drawn
		Err(PastHorizon) => PastHorizon
		Err(BehindCamera) => BehindCamera
	}

# A patch that straddles the horizon is kept, and one wholly past it is not.
expect
	sample_patch_shape([
		{ right: Distance.metres(-2.0), forward: Distance.metres(480.0) },
		{ right: Distance.metres(2.0), forward: Distance.metres(480.0) },
		{ right: Distance.metres(2.0), forward: Distance.metres(505.0) },
		{ right: Distance.metres(-2.0), forward: Distance.metres(505.0) },
	]).is_ok()
expect
	outcome(
		sample_patch_shape([
			{ right: Distance.metres(-2.0), forward: Distance.metres(495.0) },
			{ right: Distance.metres(2.0), forward: Distance.metres(495.0) },
			{ right: Distance.metres(2.0), forward: Distance.metres(520.0) },
			{ right: Distance.metres(-2.0), forward: Distance.metres(520.0) },
		]),
	)
		== PastHorizon
expect
	outcome(
		sample_patch_shape([
			{ right: Distance.metres(-5.0), forward: Distance.metres(-10.0) },
			{ right: Distance.metres(5.0), forward: Distance.metres(-10.0) },
			{ right: Distance.metres(5.0), forward: Distance.metres(-20.0) },
			{ right: Distance.metres(-5.0), forward: Distance.metres(-20.0) },
		]),
	)
		== BehindCamera

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
			polygon.fill == Flat(Brush.opaque(RgbColor.of(0x2F7E8C)))
				and polygon.coordinates.len() == 8
		_ => False
	}
}
