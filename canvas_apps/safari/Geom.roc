## The geometry of the road. The road is a line of straight segments, and a point
## on it is measured within one segment: metres along it from its start, and
## metres across it from the middle of the road. This module carries a point
## round a bend into the segment before or after it. RoadAhead turns a point on
## the road into a point in the rider's view (`RiderView`).
import Across
import Along
import Angle
import Distance

Geom :: [].{

	## A point on one segment of the road.
	RoadPoint : { along : Along, across : Across }

	## An object on one segment of the road, `lift` off the ground, and what
	## kind of object it is. A tree is placed once for the whole ride, a cow
	## from its herd whenever something asks for it, and a cat, a tower or the
	## truck anew for each frame.
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

	## A point on the segment after `bend`, measured on the segment before it:
	## turned by the bend, then moved to where the segment after starts.
	point_in_segment_before : Geom.RoadPoint, Geom.Bend -> Geom.RoadPoint
	point_in_segment_before = |point, bend|
		Geom.point_before_worked_bend(point, Geom.worked_bend(bend))

	## A point on the segment before `bend`, measured on the segment after it.
	## This is `point_in_segment_before` undone.
	point_in_segment_after : Geom.RoadPoint, Geom.Bend -> Geom.RoadPoint
	point_in_segment_after = |point, bend|
		Geom.point_after_worked_bend(point, Geom.worked_bend(bend))

	## A bend with what carrying a point across it needs worked out once: where
	## the segment after it starts, measured on the segment before, and the
	## cosine and sine of its turn. The road ahead keeps its bends this way, so
	## the many points of a frame don't each work them out again.
	WorkedBend : {
		start_after : Geom.RoadPoint,
		cos_turn : F64,
		sin_turn : F64,
	}

	## `bend`, worked out.
	worked_bend : Geom.Bend -> Geom.WorkedBend
	worked_bend = |bend| {
		cos_turn = bend.turn.to_radians().cos()
		sin_turn = bend.turn.to_radians().sin()
		{
			start_after: start_after(bend, { cos_turn, sin_turn }),
			cos_turn,
			sin_turn,
		}
	}

	## `point`, on the segment after a bend already worked out, measured on the
	## segment before it instead: turned by the bend, and moved to where the
	## segment after starts.
	point_before_worked_bend : Geom.RoadPoint, Geom.WorkedBend -> Geom.RoadPoint
	point_before_worked_bend = |point, { start_after: start, cos_turn, sin_turn }| {
		along = point.along.to_metres()
		across = point.across.to_metres()
		{
			along: start.along.plus(Distance.metres(cos_turn * along - sin_turn * across)),
			across: start.across.plus(Distance.metres(sin_turn * along + cos_turn * across)),
		}
	}

	## What `point_in_segment_after` gives, for a bend already worked out.
	point_after_worked_bend : Geom.RoadPoint, Geom.WorkedBend -> Geom.RoadPoint
	point_after_worked_bend = |point, { start_after: start, cos_turn, sin_turn }| {
		past_start = point.along.distance_from(start.along).to_metres()
		aside = point.across.distance_from(start.across).to_metres()
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
}

## The middle of the road where the segment after `bend` starts, measured on
## the segment before it. The two segments share the corner on the inside of
## the bend, so this lies past the end of the segment before, and toward the
## turn.
## The cosine and sine of the bend's turn are `cos_turn` and `sin_turn`.
start_after : Geom.Bend, { cos_turn : F64, sin_turn : F64 } -> Geom.RoadPoint
start_after = |bend, { cos_turn, sin_turn }| {
	half_width = Geom.road_half_width.to_metres()
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
