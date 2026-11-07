## The geometry of the road and of the rider's view.
##
## The road is a line of straight segments, and a point on it is measured
## within one segment: metres along it from its start, and metres across it
## from the middle of the road. A point in the rider's view is measured from
## the rider: metres to the right, metres forward, and metres up where height
## matters. This module carries a point round a bend into the segment before
## or after it, turns it into the rider's view, and cuts a polygon at the near
## plane, the closest thing the camera can see.
import Across
import Along
import Angle
import Distance
import Fraction

Geom :: [].{

	## A point on the ground in the rider's view. Both parts are signed: a
	## negative `right` is to the rider's left, and a negative `forward` is
	## behind the rider.
	RiderPoint : { right : Distance, forward : Distance }

	## A point in the rider's view, at a height above the level of the rider.
	## All three parts are signed: `right` and `forward` as on a `RiderPoint`,
	## and a negative `height` is below that level, where the ground curves
	## away.
	RaisedPoint : {
		right : Distance,
		forward : Distance,
		height : Distance,
	}

	## A point on one segment of the road.
	RoadPoint : { along : Along, across : Across }

	## An object on one segment of the road, `lift` off the ground, and what
	## kind of object it is. A tree or a cow is placed once for the whole ride;
	## a cat, a tower or the truck is placed anew for each frame.
	## `Pipeline.sighting_of` turns it into a `Pipeline.Sighted` for a frame.
	Placed(kind) : {
		road_point : Geom.RoadPoint,
		lift : Distance,
		kind : kind,
	}

	## Where the camera stands on the current segment, and which way it faces.
	Vantage : {
		along : Along,
		across : Across,
		yaw : Angle.Turn,
	}

	## The bend from one segment into the next: the length of the segment
	## before it, and the turn it makes, positive to the right.
	Bend : { segment_length : Distance, turn : Angle.Turn }

	## How far the road reaches from its middle to either edge. The road is
	## twice this wide.
	road_half_width : Distance
	road_half_width = Distance.metres(2.0)

	## The road's left edge.
	left_edge : Across
	left_edge = Across.left_of_middle(road_half_width)

	## The road's right edge.
	right_edge : Across
	right_edge = Across.right_of_middle(road_half_width)

	## The side of the road on the outside of a bend, where its guard rail runs.
	OuterSide : [LeftSide, RightSide]

	## The outside of a bend that turns `bend_turn`: the left side when the
	## road turns right, the right side when it turns left.
	outer_side : Angle.Turn -> Geom.OuterSide
	outer_side = |bend_turn|
		if bend_turn.is_right() {
			LeftSide
		} else {
			RightSide
		}

	## How far from the middle of the road the nearest row of a herd stands.
	herd_front_distance : Distance
	herd_front_distance = road_half_width.plus(Distance.metres(10.0))

	## A point on the current segment, as the camera at `vantage` sees it.
	to_rider_point : Geom.RoadPoint, Geom.Vantage -> Geom.RiderPoint
	to_rider_point = |{ along, across }, vantage| {
		ahead = along.distance_from(vantage.along).to_metres()
		aside = across.distance_from(vantage.across).to_metres()
		cos_yaw = vantage.yaw.to_radians().cos()
		sin_yaw = vantage.yaw.to_radians().sin()
		{
			forward: Distance.metres(ahead * cos_yaw + aside * sin_yaw),
			right: Distance.metres((0.0 - ahead) * sin_yaw + aside * cos_yaw),
		}
	}

	## A point on the segment after `bend`, measured on the segment before it:
	## turned by the bend, then moved to where the segment after starts.
	point_in_segment_before : Geom.RoadPoint, Geom.Bend -> Geom.RoadPoint
	point_in_segment_before = |point, bend| {
		start = start_after(bend)
		along = point.along.to_metres()
		across = point.across.to_metres()
		cos_turn = bend.turn.to_radians().cos()
		sin_turn = bend.turn.to_radians().sin()
		{
			along: start.along.plus(Distance.metres(cos_turn * along - sin_turn * across)),
			across: start.across.plus(Distance.metres(sin_turn * along + cos_turn * across)),
		}
	}

	## A point on the segment before `bend`, measured on the segment after it.
	## This is `point_in_segment_before` undone.
	point_in_segment_after : Geom.RoadPoint, Geom.Bend -> Geom.RoadPoint
	point_in_segment_after = |point, bend| {
		start = start_after(bend)
		past_start = point.along.distance_from(start.along).to_metres()
		aside = point.across.distance_from(start.across).to_metres()
		cos_turn = bend.turn.to_radians().cos()
		sin_turn = bend.turn.to_radians().sin()
		{
			along: Along.metres(cos_turn * past_start + sin_turn * aside),
			across: Across.metres((0.0 - sin_turn) * past_start + cos_turn * aside),
		}
	}

	## How far along the segment before `bend` a rider on the middle of the road
	## comes onto the next segment's road: its edge meets the middle here.
	commit_along : Geom.Bend -> Along
	commit_along = |bend| {
		exit_tan = bend.turn.abs().to_radians().tan()
		Along.at(bend.segment_length.minus(Geom.road_half_width.divided_by(exit_tan)))
	}

	## The closest distance ahead that the camera can see.
	near_plane : Distance
	near_plane = Distance.metres(0.4)

	## A point in the rider's view at or past the near plane, so the camera can
	## put it on the screen. Only `ahead_point`, the near-plane cut, and raising
	## a point already in view build one.
	AheadPoint :: Geom.RaisedPoint.{

		right : Geom.AheadPoint -> Distance
		right = |Geom.AheadPoint.(point)| point.right

		forward : Geom.AheadPoint -> Distance
		forward = |Geom.AheadPoint.(point)| point.forward

		height : Geom.AheadPoint -> Distance
		height = |Geom.AheadPoint.(point)| point.height

		to_raised : Geom.AheadPoint -> Geom.RaisedPoint
		to_raised = |Geom.AheadPoint.(point)| point

		## The point at `height` instead. It is as far ahead, so still in view.
		at_height : Geom.AheadPoint, Distance -> Geom.AheadPoint
		at_height = |Geom.AheadPoint.(point), new_height|
			Geom.AheadPoint.({ ..point, height: new_height })

		## The point at `right` instead. It is as far ahead, so still in view.
		at_right : Geom.AheadPoint, Distance -> Geom.AheadPoint
		at_right = |Geom.AheadPoint.(point), new_right|
			Geom.AheadPoint.({ ..point, right: new_right })

		is_eq : _
	}

	## `point`, if it is at or past the near plane.
	ahead_point : Geom.RaisedPoint -> Try(Geom.AheadPoint, [BehindCamera])
	ahead_point = |point|
		if is_in_view(point.forward) {
			Ok(Geom.AheadPoint.(point))
		} else {
			Err(BehindCamera)
		}

	## A point on the rider's level at or past the near plane, such as where an
	## object stands. It has no height, so whatever is drawn above it says how
	## high with `at_height`. Only `ahead_on_level` builds one.
	LevelPoint :: Geom.RiderPoint.{

		right : Geom.LevelPoint -> Distance
		right = |Geom.LevelPoint.(point)| point.right

		forward : Geom.LevelPoint -> Distance
		forward = |Geom.LevelPoint.(point)| point.forward

		to_rider : Geom.LevelPoint -> Geom.RiderPoint
		to_rider = |Geom.LevelPoint.(point)| point

		## The point raised to `height`. It is as far ahead, so still in view.
		at_height : Geom.LevelPoint, Distance -> Geom.AheadPoint
		at_height = |Geom.LevelPoint.(point), height|
			Geom.AheadPoint.({ right: point.right, forward: point.forward, height })

		is_eq : _
	}

	## `point`, if it is at or past the near plane.
	ahead_on_level : Geom.RiderPoint -> Try(Geom.LevelPoint, [BehindCamera])
	ahead_on_level = |point|
		if is_in_view(point.forward) {
			Ok(Geom.LevelPoint.(point))
		} else {
			Err(BehindCamera)
		}

	## Every one of `points`, in order, if all of them are at or past the near
	## plane.
	ahead_points : List(Geom.RaisedPoint) -> Try(List(Geom.AheadPoint), [BehindCamera])
	ahead_points = |points|
		points.fold(
			Ok(List.with_capacity(points.len())),
			|kept, point| {
				ahead = Geom.ahead_point(point)?
				Ok(kept?.append(ahead))
			},
		)

	## The part of the line from `from` to `to` at or past the near plane: the
	## whole line, or the line cut where it crosses the near plane. A line
	## with both ends behind the near plane has no such part.
	ahead_line : {
		from : Geom.RaisedPoint,
		to : Geom.RaisedPoint,
	} -> Try({ from : Geom.AheadPoint, to : Geom.AheadPoint }, [BehindCamera])
	ahead_line = |{ from, to }|
		match (Geom.ahead_point(from), Geom.ahead_point(to)) {
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
		corner_in_region : Geom.RaisedPoint -> Try(point, [Outside]),

		## Where the edge from `from` to `to` crosses the region's boundary,
		## strictly between its ends, nearest `from` first.
		edge_crossings : { from : Geom.RaisedPoint, to : Geom.RaisedPoint } -> List(point),
	}

	## The polygon cut to what lies in `region`. Where an edge leaves the
	## region and another comes back into it, a straight line joins them.
	points_in_region : List(Geom.RaisedPoint), Geom.Region(point) -> List(point)
	points_in_region = |polygon_points, region| {
		next_corners = polygon_points.drop_first(1).concat(polygon_points.take_first(1))
		edges = polygon_points.map2(next_corners, |from, to| { from, to, region })
		edges.fold(List.with_capacity(2 * polygon_points.len()), edge_points_onto)
	}

	## The polygon cut to what lies at or past the near plane.
	clipped_points : List(Geom.RaisedPoint) -> List(Geom.AheadPoint)
	clipped_points = |polygon_points| Geom.points_in_region(polygon_points, near_plane_region)

	## The point `fraction` of the way from `from` to `to`.
	point_between : {
		from : Geom.RaisedPoint,
		to : Geom.RaisedPoint,
		fraction : Fraction,
	} -> Geom.RaisedPoint
	point_between = |{ from, to, fraction }| {
		right: from.right.plus(to.right.minus(from.right).times(fraction.to_f64())),
		forward: from.forward.plus(to.forward.minus(from.forward).times(fraction.to_f64())),
		height: from.height.plus(to.height.minus(from.height).times(fraction.to_f64())),
	}
}

## Whether a point `forward` of the camera is at or past the near plane,
## where the camera can see it.
is_in_view : Distance -> Bool
is_in_view = |forward| forward >= Geom.near_plane

## Where an edge that has one end on each side crosses the near plane.
near_plane_crossing : { from : Geom.RaisedPoint, to : Geom.RaisedPoint } -> Geom.AheadPoint
near_plane_crossing = |{ from, to }| {
	fraction = Geom.near_plane.minus(from.forward).portion(to.forward.minus(from.forward))
	Geom.AheadPoint.(
		{
			right: from.right.plus(to.right.minus(from.right).times(fraction)),
			forward: Geom.near_plane,
			height: from.height.plus(to.height.minus(from.height).times(fraction)),
		},
	)
}

## The middle of the road where the segment after `bend` starts, measured on
## the segment before it. The two segments share the corner on the inside of
## the bend, so this lies past the end of the segment before, and toward the
## turn.
start_after : Geom.Bend -> Geom.RoadPoint
start_after = |bend| {
	half_width = Geom.road_half_width.to_metres()
	cos_turn = bend.turn.to_radians().cos()
	sin_turn = bend.turn.to_radians().sin()
	toward_turn = half_width * (1.0 - cos_turn)
	{
		along: Along.metres(bend.segment_length.to_metres() + half_width * sin_turn.abs()),
		across: if bend.turn.is_right() {
			Across.metres(toward_turn)
		} else {
			Across.metres(0.0 - toward_turn)
		},
	}
}

## `kept_points` with what one edge of a polygon adds to it: the edge's first
## corner if that lies in `region`, then each point where the edge crosses the
## region's boundary, in order along the edge.
edge_points_onto : List(point),
{
	from : Geom.RaisedPoint,
	to : Geom.RaisedPoint,
	region : Geom.Region(point),
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
near_plane_region : Geom.Region(Geom.AheadPoint)
near_plane_region = {
	corner_in_region: |point|
		match Geom.ahead_point(point) {
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
straight_ahead : F64 -> Geom.RaisedPoint
straight_ahead = |forward| {
	right: Distance.zero,
	forward: Distance.metres(forward),
	height: Distance.zero,
}

## A point 2 m right, 9 m ahead and 1 m up.
sample_point : Geom.RaisedPoint
sample_point = {
	right: Distance.metres(2.0),
	forward: Distance.metres(9.0),
	height: Distance.metres(1.0),
}

# A point past the near plane gives back each of its parts.
expect
	match Geom.ahead_point(sample_point) {
		Ok(point) =>
			[point.right(), point.forward(), point.height()]
				== [sample_point.right, sample_point.forward, sample_point.height]
				and point.to_raised() == sample_point
		Err(BehindCamera) => False
	}

# A point exactly on the near plane is in view, and one short of it, at the
# camera, or behind it is not.
expect Geom.ahead_point(straight_ahead(0.4)).is_ok()
expect Geom.ahead_point(straight_ahead(0.41)).is_ok()
expect Geom.ahead_point(straight_ahead(0.39)) == Err(BehindCamera)
expect Geom.ahead_point(straight_ahead(0.0)) == Err(BehindCamera)
expect Geom.ahead_point(straight_ahead(-5.0)) == Err(BehindCamera)

# A point on the rider's level is past the near plane as a raised one is, and
# gives back each of its parts.
expect {
	on_ground = { right: sample_point.right, forward: sample_point.forward }
	match Geom.ahead_on_level(on_ground) {
		Ok(point) =>
			[point.right(), point.forward()] == [on_ground.right, on_ground.forward]
				and point.to_rider() == on_ground
		Err(BehindCamera) => False
	}
}
expect Geom.ahead_on_level({ right: Distance.zero, forward: Distance.metres(0.4) }).is_ok()
expect {
	short_of_plane = { right: Distance.zero, forward: Distance.metres(0.39) }
	Geom.ahead_on_level(short_of_plane) == Err(BehindCamera)
}

# Raising a point on the rider's level keeps where it is and gives it the
# height asked for, above or below that level.
expect
	match Geom.ahead_on_level({ right: sample_point.right, forward: sample_point.forward }) {
		Ok(point) =>
			[Distance.metres(3.0), Distance.zero, Distance.metres(-1.0)].all(
				|height| point.at_height(height).to_raised() == { ..sample_point, height },
			)
		Err(BehindCamera) => False
	}

# A list is ahead when every point is, one on the near plane included, and an
# empty list is ahead.
expect
	Geom.ahead_points([10.0, 0.4, 30.0].map(straight_ahead)).map_ok(
		|points| points.map(|point| point.forward().to_metres()),
	)
		== Ok([10.0, 0.4, 30.0])
expect Geom.ahead_points([10.0, 0.2, 30.0].map(straight_ahead)) == Err(BehindCamera)
expect Geom.ahead_points([straight_ahead(0.39)]) == Err(BehindCamera)
expect Geom.ahead_points([]) == Ok([])

# Moving a point past the near plane up or sideways keeps how far ahead it is.
expect
	match Geom.ahead_point(sample_point) {
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
	Geom.ahead_line({ from: straight_ahead(from), to: straight_ahead(to) }).map_ok(
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

expect {
	seen_from = |road_point, yaw|
		Geom.to_rider_point(
			road_point,
			{
				along: Along.metres(5.0),
				across: Across.metres(0.5),
				yaw: Angle.Turn.radians(yaw),
			},
		)
	[
		(
			seen_from({ along: Along.metres(0.0), across: Across.metres(-3.0) }, 0.0),
			{ right: Distance.metres(-3.5), forward: Distance.metres(-5.0) },
		),
		(
			seen_from({ along: Along.metres(12.0), across: Across.metres(0.0) }, 0.35),
			{
				right: Distance.metres(-2.869971008611849),
				forward: Distance.metres(6.404160086203927),
			},
		),
		(
			seen_from({ along: Along.metres(40.0), across: Across.metres(-5.0) }, -0.6),
			{
				right: Distance.metres(15.223140686823006),
				forward: Distance.metres(31.992280125511435),
			},
		),
		(
			seen_from({ along: Along.metres(7.5), across: Across.metres(3.25) }, 1.2),
			{
				right: Distance.metres(-1.333613890107213),
				forward: Distance.metres(3.4690018726015563),
			},
		),
	].all(
		|(got, want)| {
			right_miss = got.right.minus(want.right).to_metres().abs()
			forward_miss = got.forward.minus(want.forward).to_metres().abs()
			right_miss <= 0.000001 and forward_miss <= 0.000001
		},
	)
}

expect Geom.road_half_width.to_metres() == 2.0
expect Geom.left_edge.to_metres() == -2.0
expect Geom.right_edge.to_metres() == 2.0
expect Geom.outer_side(Angle.Turn.degrees(50.0)) == LeftSide
expect Geom.outer_side(Angle.Turn.degrees(-70.0)) == RightSide

## A bend of `degrees` out of a 300 metre segment.
bend_of : F64 -> Geom.Bend
bend_of = |degrees| { segment_length: Distance.metres(300.0), turn: Angle.Turn.degrees(degrees) }

## Whether two road points are within a nanometre of each other.
is_near : Geom.RoadPoint, Geom.RoadPoint -> Bool
is_near = |got, want| {
	along_miss = got.along.distance_from(want.along).to_metres().abs()
	across_miss = got.across.distance_from(want.across).to_metres().abs()
	along_miss <= 0.000000001 and across_miss <= 0.000000001
}

# A point carried round a bend one way and back lands where it started, both
# ways round.
expect
	[50.0, -70.0, 15.0, -15.0].all(
		|degrees| {
			start = { along: Along.metres(12.0), across: Across.metres(1.0) }
			bend = bend_of(degrees)
			on_next = Geom.point_in_segment_after(start, bend)
			on_previous = Geom.point_in_segment_before(start, bend)
			is_near(Geom.point_in_segment_before(on_next, bend), start)
				and is_near(Geom.point_in_segment_after(on_previous, bend), start)
		},
	)

# The two segments share the corner on the inside of the bend: the right edge
# for a right turn, the left edge for a left turn.
expect
	[
		(50.0, Geom.right_edge),
		(-70.0, Geom.left_edge),
		(15.0, Geom.right_edge),
	].all(
		|(degrees, inner_edge)| {
			end_before = { along: Along.metres(300.0), across: inner_edge }
			next_start = { along: Along.start, across: inner_edge }
			is_near(Geom.point_in_segment_before(next_start, bend_of(degrees)), end_before)
		},
	)

# The middle of the road where the segment after starts is past the end of the
# segment before and toward the turn.
expect {
	middle_at_start = { along: Along.start, across: Across.middle }
	is_near(
		Geom.point_in_segment_before(middle_at_start, bend_of(90.0)),
		{ along: Along.metres(302.0), across: Across.metres(2.0) },
	)
}

# The commit point is where the middle of the road reaches the next road's edge:
# short of it a rider there is off that road, and just past it on.
expect
	[50.0, -70.0, 15.0, -80.0].all(
		|degrees| {
			bend = bend_of(degrees)
			commit = Geom.commit_along(bend)
			from_next_middle = |along| {
				on_next = Geom.point_in_segment_after({ along, across: Across.middle }, bend)
				on_next.across.distance_from_middle().to_metres()
			}
			(from_next_middle(commit) - 2.0).abs() <= 0.000000001
				and from_next_middle(commit.minus(Distance.metres(0.01))) > 2.0
				and from_next_middle(commit.plus(Distance.metres(0.01))) < 2.0
		},
	)

expect
	Geom.clipped_points([
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
	]).map(Geom.AheadPoint.to_raised)
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
	Geom.point_between({
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
