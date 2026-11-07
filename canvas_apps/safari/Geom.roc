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

	## An object standing on one segment of the road, and what kind of object
	## it is. This is the object's lasting form, and `Pipeline.sighting_of` turns
	## it into a `Pipeline.Sighted` for a frame.
	Placed(kind) : {
		along : Along,
		across : Across,
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

	## A line through two points.
	Line : { start_point : Geom.RiderPoint, end_point : Geom.RiderPoint }

	## The radius the ground, and the truck on it, curve away over. From the
	## rider's eye it puts the horizon 490 metres out.
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

	## Where two lines cross. They must not be parallel.
	line_crossing : { first_line : Geom.Line, second_line : Geom.Line } -> Geom.RiderPoint
	line_crossing = |{ first_line, second_line }| {
		first_start = first_line.start_point
		second_start = second_line.start_point
		first_rightward = first_line.end_point.right.minus(first_start.right).to_metres()
		first_forward = first_line.end_point.forward.minus(first_start.forward).to_metres()
		second_rightward = second_line.end_point.right.minus(second_start.right).to_metres()
		second_forward = second_line.end_point.forward.minus(second_start.forward).to_metres()
		gap_rightward = second_start.right.minus(first_start.right).to_metres()
		gap_forward = second_start.forward.minus(first_start.forward).to_metres()
		offset_cross = gap_rightward * second_forward - gap_forward * second_rightward
		direction_cross = first_rightward * second_forward - first_forward * second_rightward
		fraction = offset_cross / direction_cross
		{
			right: first_start.right.plus(Distance.metres(fraction * first_rightward)),
			forward: first_start.forward.plus(Distance.metres(fraction * first_forward)),
		}
	}

	## The closest distance ahead that the camera can see.
	near_plane : Distance
	near_plane = Distance.metres(0.4)

	## The polygon cut to what lies at or past the near plane.
	clipped_points : List(Geom.RaisedPoint) -> List(Geom.RaisedPoint)
	clipped_points = |polygon_points| {
		next_corners = polygon_points.drop_first(1).concat(polygon_points.take_first(1))
		edges = polygon_points.map2(next_corners, |from, to| { from, to })
		edges.fold(List.with_capacity(2 * polygon_points.len()), edge_points_onto)
	}
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

## `clipped` with what one edge of a polygon adds to it: the edge's first
## corner if that is in view, then the point where the edge crosses the near
## plane if it does.
edge_points_onto : List(Geom.RaisedPoint),
{
	from : Geom.RaisedPoint,
	to : Geom.RaisedPoint,
} -> List(Geom.RaisedPoint)
edge_points_onto = |clipped, { from, to }| {
	is_from_in_view = from.forward >= Geom.near_plane
	is_to_in_view = to.forward >= Geom.near_plane
	with_corner = if is_from_in_view {
		clipped.append(from)
	} else {
		clipped
	}
	if is_from_in_view == is_to_in_view {
		with_corner
	} else {
		with_corner.append(near_plane_crossing({ from, to }))
	}
}

## Where an edge that has one end on each side crosses the near plane.
near_plane_crossing : { from : Geom.RaisedPoint, to : Geom.RaisedPoint } -> Geom.RaisedPoint
near_plane_crossing = |{ from, to }| {
	fraction = Geom.near_plane.minus(from.forward).ratio_to(to.forward.minus(from.forward))
	{
		right: from.right.plus(to.right.minus(from.right).times(fraction)),
		forward: Geom.near_plane,
		height: from.height.plus(to.height.minus(from.height).times(fraction)),
	}
}

expect Geom.ground_drop({
	right: Distance.metres(0.0),
	forward: Distance.metres(0.0),
}).to_metres() == 0.0
expect Geom.ground_drop({
	right: Distance.metres(3.0),
	forward: Distance.metres(10.0),
}).to_metres() == 0.000545
expect Geom.ground_drop({
	right: Distance.metres(-5.0),
	forward: Distance.metres(40.0),
}).to_metres() == 0.008125
expect Geom.ground_drop({
	right: Distance.metres(12.5),
	forward: Distance.metres(100.0),
}).to_metres() == 0.05078125

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
	Geom.line_crossing({
		first_line: {
			start_point: { right: Distance.metres(0.0), forward: Distance.metres(0.0) },
			end_point: { right: Distance.metres(0.0), forward: Distance.metres(1.0) },
		},
		second_line: {
			start_point: { right: Distance.metres(-2.0), forward: Distance.metres(4.0) },
			end_point: { right: Distance.metres(3.0), forward: Distance.metres(4.0) },
		},
	})
		== { right: Distance.metres(0.0), forward: Distance.metres(4.0) }

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
	])
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
