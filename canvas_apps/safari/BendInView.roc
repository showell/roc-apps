## BendInView knows where two segments meet: where each lies from the rider,
## and the corner the road's outer edge turns there, with the apex where the
## outer edges meet, as points on the road. The road's paving and the guard
## rail both follow it.
import Across
import Along
import Angle
import Distance
import RoadAhead
import SegmentPlace
import Geom

## A bend as the rider sees it: where the segment before it lies, and the
## bend itself.
BendInView := { before : SegmentPlace, bend : Geom.Bend }.{

	## The bend at the end of `in_view`.
	of_in_view : RoadAhead.SegmentInView -> BendInView
	of_in_view = |in_view| { before: in_view.place, bend: in_view.segment.bend_out_of() }

	## The bend at the end of `in_view`, unless the road in view ends there. It
	## goes on past every segment of the road ahead but the last, and past the
	## segment just behind, which bends into the rider's.
	bend_after : RoadAhead.RoadView, RoadAhead.SegmentInView -> Try(BendInView, [RoadEndsInView])
	bend_after = |road, in_view| {
		has_bend_in_view =
			match in_view.place {
				Ahead(position) => !position.is_last_in(road.segments_ahead())
				JustBehind => True
			}
		if has_bend_in_view {
			Ok(BendInView.of_in_view(in_view))
		} else {
			Err(RoadEndsInView)
		}
	}

	## The turn the road makes at a bend, positive to the right.
	turn : BendInView -> Angle.Turn
	turn = |bend_in_view| bend_in_view.bend.turn

	## Where on the road ahead the segment after a bend lies: next after the
	## segment before, or the rider's own when the segment before is just behind
	## the rider.
	position_after : BendInView -> SegmentPlace.Position
	position_after = |bend_in_view|
		match bend_in_view.before {
			Ahead(position) => position.next()
			JustBehind => SegmentPlace.Position.first
		}

	## How far across the road its outer edge at a bend is: the left edge
	## when the road turns right, the right edge when it turns left.
	outer_edge : BendInView -> Across
	outer_edge = |bend_in_view|
		if bend_in_view.bend.turn.is_right() {
			Geom.left_edge
		} else {
			Geom.right_edge
		}

	## How far across the road its inner edge at a bend is: the right edge
	## when the road turns right, the left edge when it turns left.
	inner_edge : BendInView -> Across
	inner_edge = |bend_in_view|
		if bend_in_view.bend.turn.is_right() {
			Geom.right_edge
		} else {
			Geom.left_edge
		}

	## The corner the road's outer edge turns at a bend, measured on the segment
	## before it: where that segment's outer edge ends, the apex where it meets
	## the outer edge of the segment after, carried straight on, and where the
	## outer edge of the segment after starts.
	outer_corner : BendInView -> {
		end_before : Geom.RoadPoint,
		apex : Geom.RoadPoint,
		start_after : Geom.RoadPoint,
	}
	outer_corner = |bend_in_view| {
		across = outer_edge(bend_in_view)
		bend = bend_in_view.bend
		start_after = Geom.point_in_segment_before({ along: Along.start, across }, bend)
		turn_radians = bend.turn.to_radians()
		toward_edge = across.distance_from(start_after.across).to_metres()
		run_to_edge = toward_edge * turn_radians.cos() / turn_radians.sin()
		{
			end_before: { along: Along.at(bend.segment_length), across },
			apex: { along: start_after.along.plus(Distance.metres(run_to_edge)), across },
			start_after,
		}
	}
}

## A bend of `turn` from a segment 300 m long at `before`.
bend_at : SegmentPlace, Angle.Turn -> BendInView
bend_at = |before, turn| { before, bend: { segment_length: Distance.metres(300.0), turn } }

right_bend : BendInView
right_bend = bend_at(Ahead(SegmentPlace.Position.first), Angle.Turn.degrees(50.0))

left_bend : BendInView
left_bend = bend_at(Ahead(SegmentPlace.Position.first), Angle.Turn.degrees(-70.0))

expect right_bend.outer_edge() == Geom.left_edge and right_bend.inner_edge() == Geom.right_edge
expect left_bend.outer_edge() == Geom.right_edge and left_bend.inner_edge() == Geom.left_edge

# The segment after a bend, from each place the segment before can lie.
expect bend_at(
	Ahead(SegmentPlace.Position.first),
	Angle.straight_ahead,
).position_after().to_i64() == 1
expect bend_at(
	Ahead(SegmentPlace.Position.number(3)),
	Angle.straight_ahead,
).position_after().to_i64() == 4
expect bend_at(JustBehind, Angle.straight_ahead).position_after().to_i64() == 0

## The outer corner of a bend of `turn` from a segment 300 m long, as (along,
## across) pairs: where the edge before ends, the apex, and where the edge
## after starts.
outer_corner_pairs : Angle.Turn -> List((F64, F64))
outer_corner_pairs = |turn| {
	corner = bend_at(Ahead(SegmentPlace.Position.first), turn).outer_corner()
	[corner.end_before, corner.apex, corner.start_after].map(
		|point| (point.along.to_metres(), point.across.to_metres()),
	)
}

## Whether two lists of (along, across) pairs agree to a micrometre.
is_near : List((F64, F64)), List((F64, F64)) -> Bool
is_near = |got_pairs, wanted_pairs|
	got_pairs.len() == wanted_pairs.len()
		and got_pairs.map2(
			wanted_pairs,
			|(a, b), (c, d)| (a - c).abs() <= 0.000001 and (b - d).abs() <= 0.000001,
		).all(|is_close| is_close)

# A right angle's outer corner is a road's width past the end, on the outer
# edge, and the edge after starts across the road from it.
expect is_near(
	outer_corner_pairs(Angle.Turn.degrees(90.0)),
	[
		(300.0, -2.0),
		(304.0, -2.0),
		(304.0, 2.0),
	],
)
expect is_near(
	outer_corner_pairs(Angle.Turn.degrees(-90.0)),
	[
		(300.0, 2.0),
		(304.0, 2.0),
		(304.0, -2.0),
	],
)
