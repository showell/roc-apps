## The geometry of the road and of the rider's view.
##
## The road is a line of straight segments, and a point on it is measured
## within one segment: metres along it from its start, and metres across it
## from the middle of the lane. A point in the rider's view is measured from
## the rider: metres to the right, metres forward, and metres up where height
## matters. This module carries a point round a bend into the segment before
## or after it, turns it into the rider's view, and cuts a polygon at the near
## plane, the closest thing the camera can see.
import Across
import Along
import Angle
import lib.DeviceMath
import Distance
import lib.Trig

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

	## A point on one segment of the road, measured from the lane's left edge.
	## A bend turns about a corner of the lane, so its arithmetic works from
	## that edge.
	EdgePoint : { along : Along, from_left : Distance }

	## Where the camera stands on the current segment, and which way it faces.
	## The middle of the lane is `half_width` from its left edge.
	Vantage : {
		along : Along,
		across : Across,
		yaw : Angle.Turn,
		half_width : Distance,
	}

	## The bend from one segment into the next: the length of the segment
	## before it, the turn it makes, positive to the right, and the lane's
	## width.
	Bend : {
		segment_length : Distance,
		turn : Angle.Turn,
		road_width : Distance,
	}

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
	to_rider_point : Geom.EdgePoint, Geom.Vantage -> Geom.RiderPoint
	to_rider_point = |{ along, from_left }, vantage| {
		ahead = along.distance_from(vantage.along).to_metres()
		rider_from_left = vantage.across.distance_from(Across.left_of_middle(vantage.half_width))
		aside = from_left.minus(rider_from_left).to_metres()
		cos_yaw = Trig.r_cos(vantage.yaw.to_radians())
		sin_yaw = Trig.r_sin(vantage.yaw.to_radians())
		{
			forward: Distance.metres(ahead * cos_yaw + aside * sin_yaw),
			right: Distance.metres((0.0 - ahead) * sin_yaw + aside * cos_yaw),
		}
	}

	## A point on the segment after `bend`, measured on the segment before it.
	in_segment_before : Geom.EdgePoint, Geom.Bend -> Geom.EdgePoint
	in_segment_before = |point, bend| {
		along = point.along.to_metres()
		from_left = point.from_left.to_metres()
		length = bend.segment_length.to_metres()
		width = bend.road_width.to_metres()
		turn_size = bend.turn.abs().to_radians()
		cos_turn = Trig.r_cos(turn_size)
		sin_turn = Trig.r_sin(turn_size)
		if bend.turn.is_right() {
			turned_along = along * cos_turn - from_left * sin_turn + width * sin_turn + length
			turned_from_left = from_left * cos_turn + along * sin_turn + width * (1.0 - cos_turn)
			{ along: Along.metres(turned_along), from_left: Distance.metres(turned_from_left) }
		} else {
			{
				along: Along.metres(along * cos_turn + from_left * sin_turn + length),
				from_left: Distance.metres(from_left * cos_turn - along * sin_turn),
			}
		}
	}

	## A point on the segment before `bend`, measured on the segment after it.
	in_segment_after : Geom.EdgePoint, Geom.Bend -> Geom.EdgePoint
	in_segment_after = |point, bend| {
		left_edge = Across.left_of_middle(bend.road_width.divided_by(2.0))
		centred = centred_point_after(
			{ along: point.along, across: left_edge.plus(point.from_left) },
			bend,
		)
		{ along: centred.along, from_left: centred.across.distance_from(left_edge) }
	}

	## `in_segment_after` for a point measured from the middle of the lane, as
	## the rider is.
	centred_point_after : Geom.RoadPoint, Geom.Bend -> Geom.RoadPoint
	centred_point_after = |point, bend| {
		across = point.across.to_metres()
		half_width = bend.road_width.to_metres() / 2.0
		cos_turn = Trig.r_cos(bend.turn.to_radians())
		sin_turn = Trig.r_sin(bend.turn.to_radians())
		corner_shift = half_width * (1.0 - cos_turn)
		corner_along = bend.segment_length.to_metres() + half_width * DeviceMath.real_abs(sin_turn)
		past_corner = point.along.to_metres() - corner_along
		past_middle = if bend.turn.is_right() {
			across - corner_shift
		} else {
			across + corner_shift
		}
		{
			along: Along.metres(cos_turn * past_corner + sin_turn * past_middle),
			across: Across.metres((0.0 - sin_turn) * past_corner + cos_turn * past_middle),
		}
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
	clip_near : List(Geom.RaisedPoint) -> List(Geom.RaisedPoint)
	clip_near = |polygon| {
		next_corners = polygon.drop_first(1).concat(polygon.take_first(1))
		edges = polygon.map2(next_corners, |from, to| { from, to })
		edges.fold(List.with_capacity(2 * polygon.len()), clip_edge_onto)
	}
}

## `clipped` with what one edge of a polygon adds to it: the edge's first
## corner if that is in view, then the point where the edge crosses the near
## plane if it does.
clip_edge_onto : List(Geom.RaisedPoint),
{
	from : Geom.RaisedPoint,
	to : Geom.RaisedPoint,
} -> List(Geom.RaisedPoint)
clip_edge_onto = |clipped, { from, to }| {
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

# The lengths and places that measure the road.
expect Distance.zero.to_metres() == 0.0
expect Distance.metres(1.5).plus(Distance.metres(2.25)).to_metres() == 3.75
expect Distance.metres(1.5).minus(Distance.metres(2.25)).to_metres() == -0.75
expect Distance.metres(4.0).times(0.5).to_metres() == 2.0
expect Distance.metres(5.0).divided_by(2.0).to_metres() == 2.5
expect Distance.metres(1.5).opposite().to_metres() == -1.5
expect Distance.metres(2.0).ratio_to(Distance.metres(8.0)) == 0.25
expect Distance.metres(12.0).ratio_to(Distance.metres(8.0)) == 1.5
expect Distance.metres(2.0).min(Distance.metres(3.0)).to_metres() == 2.0
expect Distance.metres(3.0).min(Distance.metres(2.0)).to_metres() == 2.0
expect Distance.metres(2.0).max(Distance.metres(3.0)).to_metres() == 3.0
expect Distance.metres(3.0).max(Distance.metres(2.0)).to_metres() == 3.0

expect Along.start.to_metres() == 0.0
expect Along.at(Distance.metres(7.5)).to_metres() == 7.5
expect Along.metres(7.5).from_start().to_metres() == 7.5
expect Along.metres(7.5).plus(Distance.metres(2.0)).to_metres() == 9.5
expect Along.metres(7.5).minus(Distance.metres(2.0)).to_metres() == 5.5
expect Along.metres(7.5).distance_from(Along.metres(2.0)).to_metres() == 5.5
expect Along.metres(2.0).distance_from(Along.metres(7.5)).to_metres() == -5.5

expect Across.middle.to_metres() == 0.0
expect Across.right_of_middle(Distance.metres(1.5)).to_metres() == 1.5
expect Across.left_of_middle(Distance.metres(1.5)).to_metres() == -1.5
expect Across.metres(1.5).distance_from_middle().to_metres() == 1.5
expect Across.metres(-1.5).distance_from_middle().to_metres() == 1.5
expect Across.metres(1.5).plus(Distance.metres(2.0)).to_metres() == 3.5
expect Across.metres(1.5).minus(Distance.metres(2.0)).to_metres() == -0.5
expect Across.metres(1.5).distance_from(Across.metres(-2.0)).to_metres() == 3.5
expect Across.metres(-2.0).distance_from(Across.metres(1.5)).to_metres() == -3.5
expect Across.metres(1.5).times(0.5).to_metres() == 0.75
expect Across.metres(1.5).min(Across.metres(-2.0)).to_metres() == -2.0
expect Across.metres(-2.0).min(Across.metres(1.5)).to_metres() == -2.0
expect Across.metres(1.5).max(Across.metres(-2.0)).to_metres() == 1.5
expect Across.metres(-2.0).max(Across.metres(1.5)).to_metres() == 1.5

## Just under, at and just over 2.5 m, and how `<`, `<=`, `>`, `>=` and `==`
## answer against 2.5 m there.
comparisons_with_held : List((F64, List(Bool)))
comparisons_with_held = [
	(2.0, [True, True, False, False, False]),
	(2.5, [False, True, False, True, True]),
	(3.0, [False, False, True, True, False]),
]

expect
	comparisons_with_held.all(
		|(metres, want)| {
			length = Distance.metres(metres)
			held = Distance.metres(2.5)
			[
				length < held,
				length <= held,
				length > held,
				length >= held,
				length == held,
			] == want
		},
	)

expect
	comparisons_with_held.all(
		|(metres, want)| {
			along = Along.metres(metres)
			held = Along.metres(2.5)
			[
				along < held,
				along <= held,
				along > held,
				along >= held,
				along == held,
			] == want
		},
	)

expect
	comparisons_with_held.all(
		|(metres, want)| {
			across = Across.metres(metres)
			held = Across.metres(2.5)
			[
				across < held,
				across <= held,
				across > held,
				across >= held,
				across == held,
			] == want
		},
	)

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
	seen_from = |edge_point, yaw|
		Geom.to_rider_point(
			edge_point,
			{
				along: Along.metres(5.0),
				across: Across.metres(0.5),
				yaw: Angle.Turn.radians(yaw),
				half_width: Distance.metres(3.0),
			},
		)
	[
		(
			seen_from({ along: Along.metres(0.0), from_left: Distance.metres(0.0) }, 0.0),
			{ right: Distance.metres(-3.5), forward: Distance.metres(-5.0) },
		),
		(
			seen_from({ along: Along.metres(12.0), from_left: Distance.metres(3.0) }, 0.35),
			{
				right: Distance.metres(-2.869971008611849),
				forward: Distance.metres(6.404160086203927),
			},
		),
		(
			seen_from({ along: Along.metres(40.0), from_left: Distance.metres(-2.0) }, -0.6),
			{
				right: Distance.metres(15.223140686823006),
				forward: Distance.metres(31.992280125511435),
			},
		),
		(
			seen_from({ along: Along.metres(7.5), from_left: Distance.metres(6.25) }, 1.2),
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

## A bend of `degrees` out of a 300 metre segment of a 4 metre lane.
bend_of : F64 -> Geom.Bend
bend_of = |degrees| {
	segment_length: Distance.metres(300.0),
	turn: Angle.Turn.degrees(degrees),
	road_width: Distance.metres(4.0),
}

# A point carried round a bend one way and back lands where it started.
expect
	[50.0, -70.0, 15.0, -15.0].all(
		|degrees| {
			start = { along: Along.metres(12.0), from_left: Distance.metres(3.0) }
			bend = bend_of(degrees)
			back = Geom.in_segment_before(Geom.in_segment_after(start, bend), bend)
			along_miss = back.along.distance_from(start.along).to_metres().abs()
			across_miss = back.from_left.minus(start.from_left).to_metres().abs()
			along_miss <= 0.000000001 and across_miss <= 0.000000001
		},
	)

# Measured from the lane's middle, the same point lands the same place.
expect
	[50.0, -70.0].all(
		|degrees| {
			along = Along.metres(12.0)
			bend = bend_of(degrees)
			from_edge = Geom.in_segment_after({ along, from_left: Distance.metres(3.0) }, bend)
			from_middle = Geom.centred_point_after({ along, across: Across.metres(1.0) }, bend)
			along_miss = from_edge.along.distance_from(from_middle.along).to_metres().abs()
			across_on_edge = Across.metres(from_edge.from_left.to_metres() - 2.0)
			across_miss = across_on_edge.distance_from(from_middle.across).to_metres().abs()
			along_miss <= 0.000000001 and across_miss <= 0.000000001
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
	Geom.clip_near([
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
