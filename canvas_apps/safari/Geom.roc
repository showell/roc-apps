## The geometry of the road and of the rider's view.
##
## The road is a line of straight segments, and a point on it is measured
## within one segment: metres along it from its start, and metres across it
## from its left edge. A point in the rider's view is measured from the
## rider: metres to the right, metres forward, and metres up where height
## matters. This module carries a road point round a bend into the segment
## before or after it, turns a road point into the rider's view, and cuts a
## polygon at the near plane, the closest thing the camera can see.
import Angle
import Distance
import lib.Trig

Geom :: [].{

	## A point on the ground in the rider's view.
	RiderPoint : { right : F64, forward : F64 }

	## A point in the rider's view, at a height above the level of the rider.
	SpacePoint : {
		right : F64,
		forward : F64,
		height : F64,
	}

	## A point on one segment of the road.
	RoadPoint : { along : F64, across : F64 }

	## Where the camera stands on the current segment, and which way it faces.
	## `across` is measured from the middle of the lane, which is `half_width`
	## from its left edge.
	Pose : {
		along : F64,
		across : F64,
		yaw : Angle.Turn,
		half_width : F64,
	}

	## The bend from one segment into the next: the length of the segment
	## before it, the turn it makes, positive to the right, and the lane's
	## width.
	Bend : {
		segment_length : Distance,
		turn : Angle.Turn,
		lane_width : F64,
	}

	## A line through two points.
	Line : { start_point : Geom.RiderPoint, end_point : Geom.RiderPoint }

	## The radius of the earth the ground curves over.
	ground_radius : F64
	ground_radius = 100000.0

	## How far the ground has curved away below level at `point`.
	ground_drop : Geom.RiderPoint -> F64
	ground_drop = |{ right, forward }| (right * right + forward * forward) / (2.0 * ground_radius)

	## A point on the current segment, as the camera at `pose` sees it.
	to_rider_point : Geom.RoadPoint, Geom.Pose -> Geom.RiderPoint
	to_rider_point = |{ along, across }, pose| {
		ahead = along - pose.along
		aside = across - (pose.across + pose.half_width)
		cos_yaw = Trig.r_cos(pose.yaw.to_radians())
		sin_yaw = Trig.r_sin(pose.yaw.to_radians())
		{
			forward: ahead * cos_yaw + aside * sin_yaw,
			right: (0.0 - ahead) * sin_yaw + aside * cos_yaw,
		}
	}

	## A point on the segment after `bend`, measured on the segment before it.
	in_segment_before : Geom.RoadPoint, Geom.Bend -> Geom.RoadPoint
	in_segment_before = |{ along, across }, bend| {
		length = bend.segment_length.to_metres()
		width = bend.lane_width
		turn_size = bend.turn.abs().to_radians()
		cos_turn = Trig.r_cos(turn_size)
		sin_turn = Trig.r_sin(turn_size)
		if bend.turn.is_right() {
			{
				along: along * cos_turn - across * sin_turn + width * sin_turn + length,
				across: across * cos_turn + along * sin_turn + width * (1.0 - cos_turn),
			}
		} else {
			{
				along: along * cos_turn + across * sin_turn + length,
				across: across * cos_turn - along * sin_turn,
			}
		}
	}

	## A point on the segment before `bend`, measured on the segment after it.
	in_segment_after : Geom.RoadPoint, Geom.Bend -> Geom.RoadPoint
	in_segment_after = |{ along, across }, bend| {
		length = bend.segment_length.to_metres()
		width = bend.lane_width
		turn_size = bend.turn.abs().to_radians()
		cos_turn = Trig.r_cos(turn_size)
		sin_turn = Trig.r_sin(turn_size)
		if bend.turn.is_right() {
			past_end = along - length - width * sin_turn
			past_edge = across - width * (1.0 - cos_turn)
			{
				along: past_end * cos_turn + past_edge * sin_turn,
				across: (0.0 - past_end) * sin_turn + past_edge * cos_turn,
			}
		} else {
			past_end = along - length
			{
				along: past_end * cos_turn - across * sin_turn,
				across: past_end * sin_turn + across * cos_turn,
			}
		}
	}

	## Where two lines cross. They must not be parallel.
	line_crossing : { first_line : Geom.Line, second_line : Geom.Line } -> Geom.RiderPoint
	line_crossing = |{ first_line, second_line }| {
		first_start = first_line.start_point
		second_start = second_line.start_point
		first_rightward = first_line.end_point.right - first_start.right
		first_forward = first_line.end_point.forward - first_start.forward
		second_rightward = second_line.end_point.right - second_start.right
		second_forward = second_line.end_point.forward - second_start.forward
		gap_rightward = second_start.right - first_start.right
		gap_forward = second_start.forward - first_start.forward
		offset_cross = gap_rightward * second_forward - gap_forward * second_rightward
		direction_cross = first_rightward * second_forward - first_forward * second_rightward
		fraction = offset_cross / direction_cross
		{
			right: first_start.right + fraction * first_rightward,
			forward: first_start.forward + fraction * first_forward,
		}
	}

	## The closest distance ahead that the camera can see.
	near_plane : F64
	near_plane = 0.4

	## The polygon cut to what lies at or past the near plane.
	clip_near : List(Geom.SpacePoint) -> List(Geom.SpacePoint)
	clip_near = |polygon| {
		next_corners = polygon.drop_first(1).concat(polygon.take_first(1))
		edges = polygon.map2(next_corners, |from, to| { from, to })
		edges.fold(List.with_capacity(2 * polygon.len()), clip_edge_onto)
	}
}

## `clipped` with what one edge of a polygon adds to it: the edge's first
## corner if that is in view, then the point where the edge crosses the near
## plane if it does.
clip_edge_onto : List(Geom.SpacePoint),
{
	from : Geom.SpacePoint,
	to : Geom.SpacePoint,
} -> List(Geom.SpacePoint)
clip_edge_onto = |clipped, { from, to }| {
	is_from_in_view = from.forward >= Geom.near_plane
	is_to_in_view = to.forward >= Geom.near_plane
	with_corner = if (is_from_in_view) clipped.append(from) else clipped
	if is_from_in_view == is_to_in_view {
		with_corner
	} else {
		with_corner.append(near_plane_crossing({ from, to }))
	}
}

## Where an edge that has one end on each side crosses the near plane.
near_plane_crossing : { from : Geom.SpacePoint, to : Geom.SpacePoint } -> Geom.SpacePoint
near_plane_crossing = |{ from, to }| {
	fraction = (Geom.near_plane - from.forward) / (to.forward - from.forward)
	{
		right: from.right + fraction * (to.right - from.right),
		forward: Geom.near_plane,
		height: from.height + fraction * (to.height - from.height),
	}
}
