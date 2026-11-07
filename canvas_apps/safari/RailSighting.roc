## RailSighting lays out the guard rail at each bend in view. The rail follows
## the outer edge of the road for the last few metres before the bend,
## cuts across the bend's corner to where the two outer edges meet and
## back, and follows the next segment's outer edge for as far again. Unlike its
## sibling sightings, it doesn't go through `Pipeline`: a rail is a path in the
## rider's frame, not an object standing at a spot.
import Across
import Along
import Distance
import RoadAhead
import SegmentPlace
import Geom
import GuardRail
import BendInView
import Pixels

RailSighting :: [].{

	## The quads of the rails at every bend in view: the bends along the road
	## ahead, then the bend from the segment behind.
	rail_quads_in_view : RoadAhead.RoadView,
	{
		vantage : Geom.Vantage,
		cam_focal : Pixels,
		..,
	} -> List(GuardRail.RailQuad)
	rail_quads_in_view = |road, camera|
		RoadAhead.segments_in_view(road).join_map(
			|in_view|
				match BendInView.bend_after(road, in_view) {
					Ok(bend_in_view) => rails_at(road, { vantage: camera.vantage, bend_in_view })
					Err(RoadEndsInView) => []
				},
		)

	## The rail along the last `rail_run_on` of a segment `length` long,
	## which lies at `place`, at `across`: a point a metre, ending at the
	## segment's end.
	runup_points : RoadAhead.RoadView,
	{
		vantage : Geom.Vantage,
		place : SegmentPlace,
		length : Distance,
		across : Across,
	} -> List(Geom.RiderPoint)
	runup_points = |road, { vantage, place, length, across }| {
		run_on_metres = leg_pieces(rail_run_on)
		List.from_iter(U32.to(0, run_on_metres)).map(
			|metres_in| {
				metres_left = Distance.metres((run_on_metres - metres_in).to_f64())
				RoadAhead.rider_point_at(
					road,
					{
						vantage,
						place,
						road_point: { along: Along.at(length.minus(metres_left)), across },
					},
				)
			},
		)
	}

	## The rail along the first `rail_run_on` of a segment at `place`, at
	## `across`: a point a metre, the first a metre in.
	runout_points : RoadAhead.RoadView,
	{
		vantage : Geom.Vantage,
		place : SegmentPlace,
		across : Across,
	} -> List(Geom.RiderPoint)
	runout_points = |road, { vantage, place, across }|
		List.from_iter(U32.to(1, leg_pieces(rail_run_on))).map(
			|metres_in| RoadAhead.rider_point_at(
				road,
				{
					vantage,
					place,
					road_point: { along: Along.metres(metres_in.to_f64()), across },
				},
			),
		)
}

## How far the rail runs on, a post a metre, past each end of a bend.
rail_run_on : Distance
rail_run_on = Distance.metres(10.0)

## How many pieces a leg `distance` long is cut into: one a metre, and at
## least one.
leg_pieces : Distance -> U32
leg_pieces = |distance| {
	pieces =
		distance.to_metres().round_to_i64_try()
			?? crash "RailSighting.leg_pieces: a leg's length is finite"
	pieces.max(1).to_u32_wrap()
}

## `pieces` + 1 points evenly spaced from `from` to `to`, both included.
evenly_spaced : {
	from : Geom.RiderPoint,
	to : Geom.RiderPoint,
	pieces : U32,
} -> List(Geom.RiderPoint)
evenly_spaced = |{ from, to, pieces }| {
	rightward = to.right.minus(from.right)
	forward = to.forward.minus(from.forward)
	List.from_iter(U32.to(0, pieces)).map(
		|step| {
			fraction = step.to_f64() / pieces.to_f64()
			{
				right: from.right.plus(rightward.times(fraction)),
				forward: from.forward.plus(forward.times(fraction)),
			}
		},
	)
}

## A leg of rail from `from` to `to`: a point about every metre, the
## last at `to`, and none at `from`, which ends the leg before it.
leg_points : { from : Geom.RiderPoint, to : Geom.RiderPoint } -> List(Geom.RiderPoint)
leg_points = |{ from, to }| {
	rightward = to.right.minus(from.right).to_metres()
	forward = to.forward.minus(from.forward).to_metres()
	distance = (rightward * rightward + forward * forward).sqrt()
	pieces = leg_pieces(Distance.metres(distance))
	evenly_spaced({ from, to, pieces }).drop_first(1)
}

## The guard rail at `bend_in_view`, as quads along its path. It stands alone so
## the tutorial can show the step from a bend to its rail by itself.
rails_at : RoadAhead.RoadView,
{
	vantage : Geom.Vantage,
	bend_in_view : BendInView,
} -> List(GuardRail.RailQuad)
rails_at = |road, seen| GuardRail.quads_along(rail_points(road, seen))

## The path of the rail at a bend, along the road's outer edge: up to the
## bend, out to where the two outer edges meet, back to the next segment,
## and along it.
rail_points : RoadAhead.RoadView,
{
	vantage : Geom.Vantage,
	bend_in_view : BendInView,
} -> List(Geom.RiderPoint)
rail_points = |road, { vantage, bend_in_view }| {
	outer_edge = bend_in_view.outer_edge()
	place_after = Ahead(BendInView.position_after(bend_in_view))
	length_before = bend_in_view.bend.segment_length
	corner = bend_in_view.outer_corner()
	seen_before = |road_point| RoadAhead.rider_point_at(
		road,
		{ vantage, place: bend_in_view.before, road_point },
	)
	end_before = seen_before(corner.end_before)
	apex = seen_before(corner.apex)
	start_after = seen_before(corner.start_after)
	[
		RailSighting.runup_points(
			road,
			{
				vantage,
				place: bend_in_view.before,
				length: length_before,
				across: outer_edge,
			},
		),
		leg_points({ from: end_before, to: apex }),
		leg_points({ from: apex, to: start_after }),
		RailSighting.runout_points(road, { vantage, place: place_after, across: outer_edge }),
	].join()
}

expect
	[
		(0.0, 1),
		(0.4, 1),
		(0.5, 1),
		(1.0, 1),
		(1.4, 1),
		(1.5, 2),
		(2.5, 3),
		(10.0, 10),
		(49.6, 50),
		(50.0, 50),
	].all(|(distance, want)| leg_pieces(Distance.metres(distance)).to_i64() == want)

origin_pt : Geom.RiderPoint
origin_pt = { right: Distance.metres(0.0), forward: Distance.metres(0.0) }

point_at : List(Geom.RiderPoint), U64 -> Geom.RiderPoint
point_at = |points, i| points.get(i) ?? crash "RailSighting: an index past the leg's end"

straight_points : List(Geom.RiderPoint)
straight_points = leg_points({
	from: origin_pt,
	to: { right: Distance.metres(0.0), forward: Distance.metres(10.0) },
})

expect straight_points.len() == 10
expect point_at(straight_points, 0).forward.to_metres() == 1.0
expect point_at(straight_points, 4).forward.to_metres() == 5.0
expect point_at(straight_points, 9).forward.to_metres() == 10.0
expect point_at(straight_points, 0).right.to_metres() == 0.0
expect point_at(straight_points, 9).right.to_metres() == 0.0

diagonal_points : List(Geom.RiderPoint)
diagonal_points = leg_points({
	from: origin_pt,
	to: { right: Distance.metres(30.0), forward: Distance.metres(40.0) },
})

expect diagonal_points.len() == 50
expect point_at(diagonal_points, 49).right.to_metres() == 30.0
expect point_at(diagonal_points, 49).forward.to_metres() == 40.0
expect point_at(diagonal_points, 24).right.to_metres() == 15.0
expect point_at(diagonal_points, 24).forward.to_metres() == 20.0
expect {
	in_place = leg_points({
		from: { right: Distance.metres(3.0), forward: Distance.metres(4.0) },
		to: { right: Distance.metres(3.0), forward: Distance.metres(4.0) },
	})
	in_place.len() == 1 and point_at(in_place, 0) == {
		right: Distance.metres(3.0),
		forward: Distance.metres(4.0),
	}
}

expect {
	spaced = evenly_spaced({
		from: origin_pt,
		to: { right: Distance.metres(0.0), forward: Distance.metres(10.0) },
		pieces: 10,
	})
	spaced.len() == 11
		and point_at(spaced, 0).forward.to_metres() == 0.0
		and point_at(spaced, 10).forward.to_metres() == 10.0
}
