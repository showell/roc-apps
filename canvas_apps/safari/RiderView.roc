## A point in the rider's view is measured from the rider: metres to the right,
## metres forward, and metres up where height matters. It is on the rider's level
## or raised, and anywhere or at or past the near plane, the closest thing the
## camera can see; only a point past the near plane can go on the screen. This
## module cuts lines and polygons at the near plane.
import Distance
import Fraction

RiderView :: [].{

	## A point on the ground in the rider's view. Both parts are signed: a
	## negative `right` is to the rider's left, and a negative `forward` is
	## behind the rider.
	RiderPoint : { right : Distance, forward : Distance }

	## How far apart two points on the ground are, along the ground.
	ground_distance : { from : RiderView.RiderPoint, to : RiderView.RiderPoint } -> Distance
	ground_distance = |{ from, to }| {
		rightward = to.right.minus(from.right).to_metres()
		forward = to.forward.minus(from.forward).to_metres()
		Distance.metres((rightward * rightward + forward * forward).sqrt())
	}

	## A point in the rider's view, at a height above the level of the rider.
	## All three parts are signed: `right` and `forward` as on a `RiderPoint`,
	## and a negative `height` is below that level, where the ground curves
	## away.
	RaisedPoint : {
		right : Distance,
		forward : Distance,
		height : Distance,
	}

	## A point in the rider's view at or past the near plane, so the camera can
	## put it on the screen. Only `raised_point_ahead`, the near-plane cut, and raising
	## a point already in view build one.
	RaisedPointAhead :: RiderView.RaisedPoint.{

		right : RiderView.RaisedPointAhead -> Distance
		right = |RiderView.RaisedPointAhead.(point)| point.right

		forward : RiderView.RaisedPointAhead -> Distance
		forward = |RiderView.RaisedPointAhead.(point)| point.forward

		height : RiderView.RaisedPointAhead -> Distance
		height = |RiderView.RaisedPointAhead.(point)| point.height

		to_raised : RiderView.RaisedPointAhead -> RiderView.RaisedPoint
		to_raised = |RiderView.RaisedPointAhead.(point)| point

		## The point at `height` instead. It is as far ahead, so still in view.
		at_height : RiderView.RaisedPointAhead, Distance -> RiderView.RaisedPointAhead
		at_height = |RiderView.RaisedPointAhead.(point), new_height|
			RiderView.RaisedPointAhead.({ ..point, height: new_height })

		## The point at `right` instead. It is as far ahead, so still in view.
		at_right : RiderView.RaisedPointAhead, Distance -> RiderView.RaisedPointAhead
		at_right = |RiderView.RaisedPointAhead.(point), new_right|
			RiderView.RaisedPointAhead.({ ..point, right: new_right })

		is_eq : _
	}

	## `point`, if it is at or past the near plane.
	raised_point_ahead : RiderView.RaisedPoint -> Try(RiderView.RaisedPointAhead, [BehindCamera])
	raised_point_ahead = |point|
		if is_in_view(point.forward) {
			Ok(RiderView.RaisedPointAhead.(point))
		} else {
			Err(BehindCamera)
		}

	## A point on the rider's level at or past the near plane, such as where an
	## object stands. It has no height, so whatever is drawn above it says how
	## high with `at_height`. Only `rider_point_ahead` builds one.
	RiderPointAhead :: RiderView.RiderPoint.{

		right : RiderView.RiderPointAhead -> Distance
		right = |RiderView.RiderPointAhead.(point)| point.right

		forward : RiderView.RiderPointAhead -> Distance
		forward = |RiderView.RiderPointAhead.(point)| point.forward

		to_rider : RiderView.RiderPointAhead -> RiderView.RiderPoint
		to_rider = |RiderView.RiderPointAhead.(point)| point

		## The point raised to `height`. It is as far ahead, so still in view.
		at_height : RiderView.RiderPointAhead, Distance -> RiderView.RaisedPointAhead
		at_height = |RiderView.RiderPointAhead.(point), height|
			RiderView.RaisedPointAhead.({ right: point.right, forward: point.forward, height })

		is_eq : _
	}

	## `point`, if it is at or past the near plane.
	rider_point_ahead : RiderView.RiderPoint -> Try(RiderView.RiderPointAhead, [BehindCamera])
	rider_point_ahead = |point|
		if is_in_view(point.forward) {
			Ok(RiderView.RiderPointAhead.(point))
		} else {
			Err(BehindCamera)
		}

	## Every one of `points`, in order, if all of them are at or past the near
	## plane.
	raised_points_ahead : List(RiderView.RaisedPoint) -> Try(
		List(RiderView.RaisedPointAhead),
		[BehindCamera],
	)
	raised_points_ahead = |points|
		points.fold(
			Ok(List.with_capacity(points.len())),
			|kept, point| {
				ahead = RiderView.raised_point_ahead(point)?
				Ok(kept?.append(ahead))
			},
		)

	## The part of the line from `from` to `to` at or past the near plane: the
	## whole line, or the line cut where it crosses the near plane. A line
	## with both ends behind the near plane has no such part.
	line_ahead : {
		from : RiderView.RaisedPoint,
		to : RiderView.RaisedPoint,
	} -> Try({ from : RiderView.RaisedPointAhead, to : RiderView.RaisedPointAhead }, [BehindCamera])
	line_ahead = |{ from, to }|
		match (RiderView.raised_point_ahead(from), RiderView.raised_point_ahead(to)) {
			(Ok(start), Ok(end)) => Ok({ from: start, to: end })
			(Ok(start), Err(BehindCamera)) =>
				Ok({ from: start, to: near_plane_crossing({ from, to }) })
			(Err(BehindCamera), Ok(end)) =>
				Ok({ from: near_plane_crossing({ from, to }), to: end })
			(Err(BehindCamera), Err(BehindCamera)) => Err(BehindCamera)
		}

	## A region of the rider's view that a polygon can be cut to: which of its
	## corners lie in the region, and where its edges cross the boundary.
	Region(point) : {
		## `corner` as a point of the cut polygon, if it lies in the region.
		corner_in_region : RiderView.RaisedPoint -> Try(point, [Outside]),

		## Where the edge from `from` to `to` crosses the region's boundary,
		## strictly between its ends, nearest `from` first.
		edge_crossings : {
			from : RiderView.RaisedPoint,
			to : RiderView.RaisedPoint,
		} -> List(point),
	}

	## The polygon cut to what lies in `region`. Where an edge leaves the
	## region and another comes back into it, a straight line joins them.
	points_in_region : List(RiderView.RaisedPoint), RiderView.Region(point) -> List(point)
	points_in_region = |polygon_points, region| {
		next_corners = polygon_points.drop_first(1).concat(polygon_points.take_first(1))
		edges = polygon_points.map2(next_corners, |from, to| { from, to, region })
		edges.fold(List.with_capacity(2 * polygon_points.len()), edge_points_onto)
	}

	## The polygon cut to what lies at or past the near plane.
	clipped_points : List(RiderView.RaisedPoint) -> List(RiderView.RaisedPointAhead)
	clipped_points = |polygon_points| RiderView.points_in_region(polygon_points, near_plane_region)

	## The point `fraction` of the way from `from` to `to`.
	point_between : {
		from : RiderView.RaisedPoint,
		to : RiderView.RaisedPoint,
		fraction : Fraction,
	} -> RiderView.RaisedPoint
	point_between = |{ from, to, fraction }| {
		right: from.right.plus(to.right.minus(from.right).scaled_by(fraction)),
		forward: from.forward.plus(to.forward.minus(from.forward).scaled_by(fraction)),
		height: from.height.plus(to.height.minus(from.height).scaled_by(fraction)),
	}
}

## The closest distance ahead that the camera can see.
near_plane : Distance
near_plane = Distance.metres(0.4)

## Whether a point `forward` of the camera is at or past the near plane,
## where the camera can see it.
is_in_view : Distance -> Bool
is_in_view = |forward| forward >= near_plane

## Where an edge that has one end on each side crosses the near plane.
near_plane_crossing : {
	from : RiderView.RaisedPoint,
	to : RiderView.RaisedPoint,
} -> RiderView.RaisedPointAhead
near_plane_crossing = |{ from, to }| {
	fraction = Fraction.of(near_plane.minus(from.forward).ratio_to(to.forward.minus(from.forward)))
	crossing = RiderView.point_between({ from, to, fraction })
	RiderView.RaisedPointAhead.({ ..crossing, forward: near_plane })
}

## `kept_points` with what one edge of a polygon adds to it: the edge's first
## corner if that lies in `region`, then each point where the edge crosses the
## region's boundary, in order along the edge.
edge_points_onto : List(point),
{
	from : RiderView.RaisedPoint,
	to : RiderView.RaisedPoint,
	region : RiderView.Region(point),
} -> List(point)
edge_points_onto = |kept_points, { from, to, region }| {
	corner_in_region = region.corner_in_region
	edge_crossings = region.edge_crossings
	with_corner =
		match corner_in_region(from) {
			Ok(corner) => kept_points.append(corner)
			Err(Outside) => kept_points
		}
	with_corner.concat(edge_crossings({ from, to }))
}

## The part of the rider's view at or past the near plane. An edge crosses it
## where its two ends lie on either side of the near plane.
near_plane_region : RiderView.Region(RiderView.RaisedPointAhead)
near_plane_region = {
	corner_in_region: |point|
		match RiderView.raised_point_ahead(point) {
			Ok(ahead) => Ok(ahead)
			Err(BehindCamera) => Err(Outside)
		},
	edge_crossings: |{ from, to }|
		if is_in_view(from.forward) == is_in_view(to.forward) {
			[]
		} else {
			[near_plane_crossing({ from, to })]
		},
}

## A point `forward` metres straight ahead, on the rider's level.
straight_ahead : F64 -> RiderView.RaisedPoint
straight_ahead = |forward| {
	right: Distance.zero,
	forward: Distance.metres(forward),
	height: Distance.zero,
}

## A point 2 m right, 9 m ahead and 1 m up.
sample_point : RiderView.RaisedPoint
sample_point = {
	right: Distance.metres(2.0),
	forward: Distance.metres(9.0),
	height: Distance.metres(1.0),
}

# A point past the near plane gives back each of its parts.
expect
	match RiderView.raised_point_ahead(sample_point) {
		Ok(point) =>
			[point.right(), point.forward(), point.height()]
				== [sample_point.right, sample_point.forward, sample_point.height]
				and point.to_raised() == sample_point
		Err(BehindCamera) => False
	}

# A point exactly on the near plane is in view, and one short of it, at the
# camera, or behind it is not.
expect RiderView.raised_point_ahead(straight_ahead(0.4)).is_ok()
expect RiderView.raised_point_ahead(straight_ahead(0.41)).is_ok()
expect RiderView.raised_point_ahead(straight_ahead(0.39)) == Err(BehindCamera)
expect RiderView.raised_point_ahead(straight_ahead(0.0)) == Err(BehindCamera)
expect RiderView.raised_point_ahead(straight_ahead(-5.0)) == Err(BehindCamera)

# A point on the rider's level is past the near plane as a raised one is, and
# gives back each of its parts.
expect {
	on_ground = { right: sample_point.right, forward: sample_point.forward }
	match RiderView.rider_point_ahead(on_ground) {
		Ok(point) =>
			[point.right(), point.forward()] == [on_ground.right, on_ground.forward]
				and point.to_rider() == on_ground
		Err(BehindCamera) => False
	}
}
expect RiderView.rider_point_ahead({ right: Distance.zero, forward: Distance.metres(0.4) }).is_ok()
expect {
	short_of_plane = { right: Distance.zero, forward: Distance.metres(0.39) }
	RiderView.rider_point_ahead(short_of_plane) == Err(BehindCamera)
}

# Raising a point on the rider's level keeps where it is and gives it the
# height asked for, above or below that level.
expect
	match RiderView.rider_point_ahead({
		right: sample_point.right,
		forward: sample_point.forward,
	}) {
		Ok(point) =>
			[Distance.metres(3.0), Distance.zero, Distance.metres(-1.0)].all(
				|height| point.at_height(height).to_raised() == { ..sample_point, height },
			)
		Err(BehindCamera) => False
	}

# A list is ahead when every point is, one on the near plane included, and an
# empty list is ahead.
expect
	RiderView.raised_points_ahead([10.0, 0.4, 30.0].map(straight_ahead)).map_ok(
		|points| points.map(|point| point.forward().to_metres()),
	)
		== Ok([10.0, 0.4, 30.0])
expect RiderView.raised_points_ahead([10.0, 0.2, 30.0].map(straight_ahead)) == Err(BehindCamera)
expect RiderView.raised_points_ahead([straight_ahead(0.39)]) == Err(BehindCamera)
expect RiderView.raised_points_ahead([]) == Ok([])

# Moving a point past the near plane up or sideways keeps how far ahead it is.
expect
	match RiderView.raised_point_ahead(sample_point) {
		Ok(point) =>
			point.at_height(Distance.metres(3.0)).at_right(Distance.metres(-4.0)).to_raised()
				== {
					right: Distance.metres(-4.0),
					forward: Distance.metres(9.0),
					height: Distance.metres(3.0),
				}
		Err(BehindCamera) => False
	}

expect
	near_plane_crossing({
		from: {
			right: Distance.metres(0.0),
			forward: Distance.metres(0.0),
			height: Distance.metres(10.0),
		},
		to: {
			right: Distance.metres(8.0),
			forward: Distance.metres(0.8),
			height: Distance.metres(30.0),
		},
	}).to_raised()
		== {
			right: Distance.metres(4.0),
			forward: Distance.metres(0.4),
			height: Distance.metres(20.0),
		}

## How far ahead each end of the part of a line straight ahead, from `from`
## metres to `to` metres, lies at or past the near plane.
ahead_line_ends : F64, F64 -> Try((F64, F64), [BehindCamera])
ahead_line_ends = |from, to|
	RiderView.line_ahead({ from: straight_ahead(from), to: straight_ahead(to) }).map_ok(
		|line| (line.from.forward().to_metres(), line.to.forward().to_metres()),
	)

# A line wholly past the near plane is whole, one that crosses it is cut there
# whichever end is behind, and one wholly behind it has no part ahead. A line
# with an end on the near plane is whole.
expect ahead_line_ends(10.0, 30.0) == Ok((10.0, 30.0))
expect ahead_line_ends(0.4, 30.0) == Ok((0.4, 30.0))
expect ahead_line_ends(10.0, 0.0) == Ok((10.0, 0.4))
expect ahead_line_ends(0.0, 10.0) == Ok((0.4, 10.0))
expect ahead_line_ends(0.0, 0.39) == Err(BehindCamera)
expect ahead_line_ends(-5.0, 0.2) == Err(BehindCamera)

expect
	RiderView.clipped_points([
		{
			right: Distance.metres(-1.0),
			forward: Distance.metres(2.0),
			height: Distance.metres(0.0),
		},
		{
			right: Distance.metres(1.0),
			forward: Distance.metres(2.0),
			height: Distance.metres(0.5),
		},
		{
			right: Distance.metres(1.0),
			forward: Distance.metres(-1.0),
			height: Distance.metres(1.0),
		},
		{
			right: Distance.metres(-1.0),
			forward: Distance.metres(-1.0),
			height: Distance.metres(1.5),
		},
	]).map(RiderView.RaisedPointAhead.to_raised)
		== [
			{
				right: Distance.metres(-1.0),
				forward: Distance.metres(2.0),
				height: Distance.metres(0.0),
			},
			{
				right: Distance.metres(1.0),
				forward: Distance.metres(2.0),
				height: Distance.metres(0.5),
			},
			{
				right: Distance.metres(1.0),
				forward: Distance.metres(0.4),
				height: Distance.metres(0.7666666666666666),
			},
			{
				right: Distance.metres(-1.0),
				forward: Distance.metres(0.4),
				height: Distance.metres(0.8),
			},
		]

expect
	RiderView.point_between({
		from: {
			right: Distance.metres(0.0),
			forward: Distance.metres(10.0),
			height: Distance.metres(20.0),
		},
		to: {
			right: Distance.metres(8.0),
			forward: Distance.metres(30.0),
			height: Distance.metres(0.0),
		},
		fraction: Fraction.of(0.25),
	})
		== {
			right: Distance.metres(2.0),
			forward: Distance.metres(15.0),
			height: Distance.metres(15.0),
		}

# Along the ground, whichever way the second point lies from the first.
expect
	[
		({ right: Distance.metres(-1.0), forward: Distance.metres(2.0) }, 5.0),
		({ right: Distance.metres(2.0), forward: Distance.metres(6.0) }, 0.0),
	].all(
		|(from, want)| {
			to = { right: Distance.metres(2.0), forward: Distance.metres(6.0) }
			RiderView.ground_distance({ from, to }).to_metres() == want
		},
	)
