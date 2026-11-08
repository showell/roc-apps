## EarthCurve is the earth's curve under the rider: how far the ground drops below
## level as it goes away from the rider, and the horizon where the ground curves
## out of sight, which hides what stands low enough beyond it.
import Camera
import Distance
import Fraction
import RiderView

EarthCurve :: [].{

	## How far the ground has curved away below level at `point`, which is
	## never negative.
	ground_drop : RiderView.RiderPoint -> Distance
	ground_drop = |point| {
		r = point.right.to_metres()
		f = point.forward.to_metres()
		Distance.metres((r * r + f * f) / (2.0 * ground_curve_radius.to_metres()))
	}

	## The lowest height at `point`, measured from the rider's level, that the
	## rider's eye can see. Within the horizon it is the ground itself. Past it,
	## the ground has curved out of sight, and the lowest line of sight is the
	## one from the eye that grazes the ground at the horizon.
	##
	## The ground `s` metres out lies s²/2R below level, for the ground's radius
	## R. A line falling k metres per metre from the eye, at height h, touches
	## it where h - k s = -s²/2R has one root: k = √(2h/R), at s = √(2hR), which
	## is the horizon's distance H. So k is 2h/H, and `d` metres out the
	## grazing line stands at h - 2h d/H. At the horizon that is -h, the
	## ground's own height there, so the two halves meet.
	lowest_visible_height : RiderView.RiderPoint -> Distance
	lowest_visible_height = |point| {
		reach = distance_from_rider(point).to_metres()
		horizon = horizon_distance.to_metres()
		if reach <= horizon {
			EarthCurve.ground_drop(point).opposite()
		} else {
			eye = Camera.eye_height.to_metres()
			Distance.metres(eye - 2.0 * eye * reach / horizon)
		}
	}

	## Whether something standing at `point` past the horizon, its top `top`
	## above the rider's level, is hidden wholly behind the curve of the ground.
	## Within the horizon nothing is: the ground there is all in view.
	is_below_horizon : { point : RiderView.RiderPoint, top : Distance } -> Bool
	is_below_horizon = |{ point, top }| {
		is_past_horizon = distance_from_rider(point) > horizon_distance
		is_past_horizon and top <= EarthCurve.lowest_visible_height(point)
	}

	## The outline through `points`, each lowered by the earth's curve, cut at
	## the horizon. It is empty when all of it lies past the horizon.
	points_before_horizon : List(RiderView.RiderPoint) -> List(RiderView.RaisedPoint)
	points_before_horizon = |points|
		RiderView.points_in_region(points.map(ground_point), region_within(horizon_distance))
}

## The radius the ground curves away over. From the rider's eye it puts
## the horizon 490 metres out.
ground_curve_radius : Distance
ground_curve_radius = Distance.metres(100000.0)

## How far `point` is from the rider, along the ground.
distance_from_rider : RiderView.RiderPoint -> Distance
distance_from_rider = |point|
	RiderView.ground_distance({ from: { right: Distance.zero, forward: Distance.zero }, to: point })

## How far from the rider the ground curves out of sight. A lowered point
## further out lands lower on screen again, so ground past here would show
## as slivers on the grass.
horizon_distance : Distance
horizon_distance = {
	radius = ground_curve_radius.to_metres()
	Distance.metres((2.0 * radius * Camera.eye_height.to_metres()).sqrt())
}

## A point on the ground, lowered by the earth's curve.
ground_point : RiderView.RiderPoint -> RiderView.RaisedPoint
ground_point = |point| {
	right: point.right,
	forward: point.forward,
	height: EarthCurve.ground_drop(point).opposite(),
}

## The part of the rider's view within `reach` of the rider, measured on the
## ground: a circle round the rider.
region_within : Distance -> RiderView.Region(RiderView.RaisedPoint)
region_within = |reach| {
	corner_in_region: |point|
		if is_within(point, reach) {
			Ok(point)
		} else {
			Err(Outside)
		},
	edge_crossings: |{ from, to }| {
		point_at = |fraction| RiderView.point_between({ from, to, fraction })
		circle_crossings({ from, to, reach }).map(point_at)
	},
}

## Whether `point` is within `reach` of the rider, measured on the ground.
is_within : RiderView.RaisedPoint, Distance -> Bool
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
	from : RiderView.RaisedPoint,
	to : RiderView.RaisedPoint,
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

expect EarthCurve.ground_drop({
	right: Distance.metres(0.0),
	forward: Distance.metres(0.0),
}).to_metres() == 0.0
expect EarthCurve.ground_drop({
	right: Distance.metres(3.0),
	forward: Distance.metres(10.0),
}).to_metres() == 0.000545
expect EarthCurve.ground_drop({
	right: Distance.metres(-5.0),
	forward: Distance.metres(40.0),
}).to_metres() == 0.008125
expect EarthCurve.ground_drop({
	right: Distance.metres(12.5),
	forward: Distance.metres(100.0),
}).to_metres() == 0.05078125

## A point `forward` metres straight ahead of the rider.
straight_ahead : F64 -> RiderView.RiderPoint
straight_ahead = |forward| { right: Distance.zero, forward: Distance.metres(forward) }

# The horizon is 490 m out. Within it the lowest height in view is the
# ground's: 400 m out it has dropped 0.8 m. At the horizon the grazing line
# meets the ground, 1.2 m down, the eye's height below level. 1000 m out the
# grazing line stands 3.699 m below level.
expect
	[
		(400.0, -0.8),
		(horizon_distance.to_metres(), -1.2),
		(1000.0, -3.698979485566356),
	].all(
		|(forward, lowest)|
			(EarthCurve.lowest_visible_height(straight_ahead(forward)).to_metres() - lowest).abs()
				<= 0.000000001,
	)

# 1000 m out, a top 3.6 m below level shows over the horizon, and one 3.8 m below
# is hidden. Within the horizon nothing is hidden, even a top down on the ground.
expect !EarthCurve.is_below_horizon({ point: straight_ahead(1000.0), top: Distance.metres(-3.6) })
expect EarthCurve.is_below_horizon({ point: straight_ahead(1000.0), top: Distance.metres(-3.8) })
expect !EarthCurve.is_below_horizon({ point: straight_ahead(400.0), top: Distance.metres(-0.8) })

## A point on the level of the rider, `right` and `forward` in metres.
level_at : F64, F64 -> RiderView.RaisedPoint
level_at = |right, forward| {
	right: Distance.metres(right),
	forward: Distance.metres(forward),
	height: Distance.zero,
}

## Whether a point is within a nanometre of `right` and `forward`, in metres.
is_level_near : RiderView.RaisedPoint, (F64, F64) -> Bool
is_level_near = |point, (right, forward)| {
	right_miss = (point.right.to_metres() - right).abs()
	forward_miss = (point.forward.to_metres() - forward).abs()
	right_miss <= 0.000000001 and forward_miss <= 0.000000001
}

## Whether each point is near its want.
are_near : List(RiderView.RaisedPoint), List((F64, F64)) -> Bool
are_near = |got_points, wants| {
	is_each_near = got_points.map2(wants, is_level_near).all(|is_close| is_close)
	got_points.len() == wants.len() and is_each_near
}

## The polygon cut to what lies within 10 m of the rider.
points_within_ten_metres : List(RiderView.RaisedPoint) -> List(RiderView.RaisedPoint)
points_within_ten_metres = |polygon_points| {
	reach = region_within(Distance.metres(10.0))
	RiderView.points_in_region(polygon_points, reach)
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
		points_within_ten_metres(square),
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
	are_near(points_within_ten_metres(triangle), [(-8.0, 6.0), (8.0, 6.0)])
}

# A polygon wholly past reach leaves nothing.
expect {
	far_triangle = [
		level_at(20.0, 20.0),
		level_at(30.0, 20.0),
		level_at(30.0, 30.0),
	]
	points_within_ten_metres(far_triangle).is_empty()
}

# A point on the ground keeps its right and forward, and sits the drop below level.
expect
	ground_point({ right: Distance.metres(3.0), forward: Distance.metres(10.0) })
		== {
			right: Distance.metres(3.0),
			forward: Distance.metres(10.0),
			height: Distance.metres(-0.000545),
		}
