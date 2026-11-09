## BendInView knows where two segments meet: where each lies from the rider,
## and the corner the road's outer edge turns there, with the apex where the
## outer edges meet, as points on the road. The road's paving and the guard
## rail both follow it.
import Across
import Along
import Angle
import Distance
import RoadAhead
import RiderView
import SegmentFromRider
import Geom

## A bend as the rider sees it: where the segment before it lies, and the
## bend itself.
BendInView :: { before : SegmentFromRider, bend : Geom.Bend }.{

	## The bend at the end of `in_view`.
	of_in_view : RoadAhead.SegmentInView -> BendInView
	of_in_view = |in_view| {
		bend = in_view.segment.bend_out_of()
		BendInView.({ before: in_view.from_rider, bend })
	}

	## The bend at the end of `in_view`, unless the road in view ends there. It
	## goes on past every segment of the road ahead but the last, and past the
	## segment just behind, which bends into the rider's.
	bend_after : RoadAhead.RoadView, RoadAhead.SegmentInView -> Try(BendInView, [RoadEndsInView])
	bend_after = |road, in_view| {
		has_bend_in_view =
			match in_view.from_rider {
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
	turn = |BendInView.(bend_in_view)| bend_in_view.bend.turn

	## Where the segment before the bend lies from the rider.
	from_rider_before : BendInView -> SegmentFromRider
	from_rider_before = |BendInView.(bend_in_view)| bend_in_view.before

	## Where the segment after the bend lies from the rider.
	from_rider_after : BendInView -> SegmentFromRider
	from_rider_after = |bend_in_view| Ahead(BendInView.position_after(bend_in_view))

	## How long the segment before the bend is.
	length_before : BendInView -> Distance
	length_before = |BendInView.(bend_in_view)| bend_in_view.bend.segment_length

	## How long the segment after the bend is, on `road`.
	length_after : BendInView, RoadAhead.RoadView -> Distance
	length_after = |bend_in_view, road|
		RoadAhead.segment_at(road, BendInView.position_after(bend_in_view)).length

	## A point on the segment before the bend, as the camera at `vantage` on the
	## rider's segment of `road` sees it.
	rider_point_before : BendInView,
	{
		road : RoadAhead.RoadView,
		vantage : Geom.Vantage,
		road_point : Geom.RoadPoint,
	} -> RiderView.RiderPoint
	rider_point_before = |bend_in_view, { road, vantage, road_point }|
		RoadAhead.rider_point_at(
			road,
			{ vantage, from_rider: bend_in_view.from_rider_before(), road_point },
		)

	## A point on the segment after the bend, as the camera at `vantage` on the
	## rider's segment of `road` sees it.
	rider_point_after : BendInView,
	{
		road : RoadAhead.RoadView,
		vantage : Geom.Vantage,
		road_point : Geom.RoadPoint,
	} -> RiderView.RiderPoint
	rider_point_after = |bend_in_view, { road, vantage, road_point }|
		RoadAhead.rider_point_at(
			road,
			{ vantage, from_rider: bend_in_view.from_rider_after(), road_point },
		)

	## Where on the road ahead the segment after a bend lies: next after the
	## segment before, or the rider's own when the segment before is just behind
	## the rider.
	position_after : BendInView -> SegmentFromRider.Position
	position_after = |BendInView.(bend_in_view)|
		match bend_in_view.before {
			Ahead(position) => position.next()
			JustBehind => SegmentFromRider.Position.first
		}

	## How far across the road its outer edge at a bend is.
	outer_edge : BendInView -> Across
	outer_edge = |BendInView.(bend_in_view)|
		match Geom.outer_side(bend_in_view.bend.turn) {
			LeftSide => Geom.left_edge
			RightSide => Geom.right_edge
		}

	## The corner the road's outer edge turns at a bend: where the outer edge of
	## the segment before ends, the apex where it meets the outer edge of the
	## segment after, carried straight on, and where the outer edge of the
	## segment after starts.
	OuterCorner(point) : {
		end_before : point,
		apex : point,
		start_after : point,
	}

	## The outer corner of a bend, measured on the segment before it.
	outer_corner : BendInView -> BendInView.OuterCorner(Geom.RoadPoint)
	outer_corner = |bend_in_view| {
		across = outer_edge(bend_in_view)
		BendInView.({ bend, .. }) = bend_in_view
		start_after = Geom.point_in_segment_before({ along: Along.start, across }, bend)
		turn_radians = bend.turn.to_radians()
		turn_sine = turn_radians.sin()
		# Edges that run on straight, or fold straight back, never meet.
		if bend.turn.is_straight_or_back() {
			crash "BendInView.outer_corner: a bend that turns 0 or 180 degrees has no apex"
		}
		toward_edge = across.distance_from(start_after.across).to_metres()
		# Negative below a right angle, where the apex is back from start_after,
		# and positive past one.
		along_to_apex = toward_edge * turn_radians.cos() / turn_sine
		{
			end_before: { along: Along.at(bend.segment_length), across },
			apex: { along: start_after.along.plus(Distance.metres(along_to_apex)), across },
			start_after,
		}
	}

	## The outer corner of a bend, as the camera at `vantage` on the rider's
	## segment of `road` sees it.
	outer_corner_in_view : BendInView,
	{
		road : RoadAhead.RoadView,
		vantage : Geom.Vantage,
	} -> BendInView.OuterCorner(RiderView.RiderPoint)
	outer_corner_in_view = |bend_in_view, { road, vantage }| {
		corner = bend_in_view.outer_corner()
		seen = |road_point| bend_in_view.rider_point_before({ road, vantage, road_point })
		{
			end_before: seen(corner.end_before),
			apex: seen(corner.apex),
			start_after: seen(corner.start_after),
		}
	}
}

## A bend of `turn` from a segment 300 m long at `before`.
sample_bend : SegmentFromRider, Angle.Turn -> BendInView
sample_bend = |before, turn| {
	bend = { segment_length: Distance.metres(300.0), turn }
	BendInView.({ before, bend })
}

right_bend : BendInView
right_bend = sample_bend(Ahead(SegmentFromRider.Position.first), Angle.Turn.degrees(50.0))

left_bend : BendInView
left_bend = sample_bend(Ahead(SegmentFromRider.Position.first), Angle.Turn.degrees(-70.0))

expect right_bend.outer_edge() == Geom.left_edge
expect left_bend.outer_edge() == Geom.right_edge

# The segment after a bend, from each place the segment before can lie.
expect {
	first = SegmentFromRider.Position.first
	[
		(Ahead(first), first.next()),
		(Ahead(first.next().next()), first.next().next().next()),
		(JustBehind, first),
	].all(|(before, after)| sample_bend(before, Angle.straight_ahead).position_after() == after)
}

## The outer corner of a bend of `turn` from a segment 300 m long, as (along,
## across) pairs: where the edge before ends, the apex, and where the edge
## after starts.
outer_corner_pairs : Angle.Turn -> List((F64, F64))
outer_corner_pairs = |turn| {
	corner = sample_bend(Ahead(SegmentFromRider.Position.first), turn).outer_corner()
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
