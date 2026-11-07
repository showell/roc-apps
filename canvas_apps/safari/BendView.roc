## BendView knows where two segments meet: where each lies from the rider, and
## the apex where the outer edges of the road meet at the bend. The road's
## paving and the guard rail both follow it.
import Across
import Along
import Angle
import Distance
import RoadAhead
import SegmentPlace
import Geom

## A bend as the rider sees it: where the segment before it lies, and the
## bend itself.
BendView := { before : SegmentPlace, bend : Geom.Bend }.{

	## The bend at the end of `in_view`.
	of_in_view : RoadAhead.SegmentInView -> BendView
	of_in_view = |in_view| { before: in_view.place, bend: in_view.segment.bend_out_of() }

	## The bend at the end of `in_view`, unless the road in view ends there. It
	## goes on past every segment of the road ahead but the last, and past the
	## segment just behind, which bends into the rider's.
	bend_after : RoadAhead.RoadView, RoadAhead.SegmentInView -> Try(BendView, [RoadEndsInView])
	bend_after = |road, in_view| {
		has_bend_in_view =
			match in_view.place {
				Ahead(position) => !position.is_last_in(road.segments_ahead())
				JustBehind => True
			}
		if has_bend_in_view {
			Ok(BendView.of_in_view(in_view))
		} else {
			Err(RoadEndsInView)
		}
	}

	## The turn the road makes at a bend, positive to the right.
	turn : BendView -> Angle.Turn
	turn = |bend_view| bend_view.bend.turn

	## Where on the road ahead the segment after a bend lies: next after the
	## segment before, or the rider's own when the segment before is just behind
	## the rider.
	position_after : BendView -> SegmentPlace.Position
	position_after = |bend_view|
		match bend_view.before {
			Ahead(position) => position.next()
			JustBehind => SegmentPlace.Position.first
		}

	## How far across the road its outer edge at a bend is: the left edge
	## when the road turns right, the right edge when it turns left.
	outer_edge : BendView -> Across
	outer_edge = |bend_view|
		if bend_view.bend.turn.is_right() {
			Geom.left_edge
		} else {
			Geom.right_edge
		}

	## How far across the road its inner edge at a bend is: the right edge
	## when the road turns right, the left edge when it turns left.
	inner_edge : BendView -> Across
	inner_edge = |bend_view|
		if bend_view.bend.turn.is_right() {
			Geom.right_edge
		} else {
			Geom.left_edge
		}

	## Where the outer edges of the two segments at a bend meet.
	apex : RoadAhead.RoadView, { vantage : Geom.Vantage, bend_view : BendView } -> Geom.RiderPoint
	apex = |road, { vantage, bend_view }| {
		across = outer_edge(bend_view)
		end_before = Along.at(bend_view.bend.segment_length)
		before = bend_view.before
		point_before = |along| RoadAhead.rider_point_at(
			road,
			{
				vantage,
				place: before,
				road_point: { along, across },
			},
		)
		place = Ahead(position_after(bend_view))
		point_after = |along| RoadAhead.rider_point_at(
			road,
			{ vantage, place, road_point: { along, across } },
		)
		Geom.line_crossing({
			first_line: {
				start_point: point_before(end_before),
				end_point: point_before(end_before.plus(Distance.metres(1.0))),
			},
			second_line: {
				start_point: point_after(Along.start),
				end_point: point_after(Along.metres(1.0)),
			},
		})
	}
}

## A bend of `turn` from a segment 300 m long at `before`.
bend_at : SegmentPlace, Angle.Turn -> BendView
bend_at = |before, turn| { before, bend: { segment_length: Distance.metres(300.0), turn } }

right_bend : BendView
right_bend = bend_at(Ahead(SegmentPlace.Position.first), Angle.Turn.degrees(50.0))

left_bend : BendView
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
