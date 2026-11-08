## RoadExpects holds the expects of the road ahead, its bends, the ground it
## lays and places on the route, which need a place along the road, a place
## across it and a turn together.

import Fixtures
import game.Across
import game.Along
import game.Angle
import game.BendInView
import game.Distance
import game.Geom
import game.GroundPatch
import game.GroundSighting
import game.Pixels
import game.RoadAhead
import game.Route
import game.RoutePlace
import game.SegmentPlace
import game.World
import lib.Brush
import lib.RgbColor
import lib.Shapes

RoadExpects :: [].{}

# Positions count along the road ahead from the rider's segment, not along the
# route from its start.
expect {
	from_third = Fixtures.world_road_at(2)
	length_at = |position| RoadAhead.segment_at(from_third, position).length
	length_of = |number| World.route.segment_at(Route.SegmentIndex.number(number)).length
	length_of(2) != length_of(0)
		and length_of(3) != length_of(1)
		and length_at(SegmentPlace.Position.first) == length_of(2)
		and length_at(SegmentPlace.Position.first.next()) == length_of(3)
}

# The road ahead holds as many segments as the rider can see, seven, or the rest
# of the route. Here the route has nine.
expect {
	nine_segments =
		List.repeat(Fixtures.going_straight_on(Fixtures.segment_of([])), 8)
			.append(Fixtures.segment_of([]))
	route = Route.from_segments(nine_segments)
	[
		(0, 7),
		(2, 7),
		(3, 6),
		(5, 4),
		(8, 1),
	].all(
		|(number, want)| {
			road_view = RoadAhead.RoadView.ahead_of(route, Route.SegmentIndex.number(number))
			road_view.segments_ahead().count == want
		},
	)
}

expect [(0, 0), (3, 3)].all(
	|(first, want)| {
		rider_index = RoadAhead.rider_segment_index(Fixtures.world_road_at(first))
		rider_index == Route.SegmentIndex.number(want)
	},
)

## The index of the segment in view just behind a rider on the world's segment
## `first`, unless the rider is on the route's first segment.
index_behind : U32 -> [JustBehind(Route.SegmentIndex), NoneBehind]
index_behind = |first| {
	behind = RoadAhead.segments_in_view(Fixtures.world_road_at(first)).find_last(
		|in_view|
			match in_view.place {
				JustBehind => True
				Ahead(_) => False
			},
	)
	match behind {
		Ok(in_view) => JustBehind(in_view.index)
		Err(NotFound) => NoneBehind
	}
}

expect
	[
		(0, NoneBehind),
		(1, JustBehind(Route.SegmentIndex.number(0))),
		(3, JustBehind(Route.SegmentIndex.number(2))),
	].all(|(input, want)| index_behind(input) == want)

## A camera 100 m along the rider's segment, 1 m right of the middle, turned
## 0.2 radians to the right.
turned_vantage : Geom.Vantage
turned_vantage = {
	along: Along.metres(100.0),
	across: Across.metres(1.0),
	yaw: Angle.Turn.radians(0.2),
}

## The point 50 m along and 1 m right on the segment at `place` on `road_view`,
## as `turned_vantage` sees it.
turned_point_at : RoadAhead.RoadView, SegmentPlace -> Geom.RiderPoint
turned_point_at = |road_view, place|
	RoadAhead.rider_point_at(
		road_view,
		{
			vantage: turned_vantage,
			place,
			road_point: { along: Along.metres(50.0), across: Across.metres(1.0) },
		},
	)

expect {
	at_d0 = turned_point_at(Fixtures.road, Ahead(SegmentPlace.Position.first))
	second_segment_point = turned_point_at(Fixtures.road, Ahead(Fixtures.second_position))
	[
		(at_d0.right.to_metres(), 9.933466539753061),
		(at_d0.forward.to_metres(), -49.00332889206208),
		(second_segment_point.right.to_metres(), -48.11621135085446),
		(second_segment_point.forward.to_metres(), 431.95658232777186),
	].all(|(got, want)| (got - want).abs() <= 0.00000005 * want.abs().max(1.0))
}

left_turn : Angle.Turn
left_turn = Angle.Turn.radians(-1.2217304763960306)

right_turn : Angle.Turn
right_turn = Angle.Turn.radians(0.8726646259971648)

## The road ahead of a rider on the second of two segments, the first 300 m
## long and bending by `turn` into the second.
road_past_bend : Angle.Turn -> RoadAhead.RoadView
road_past_bend = |turn|
	RoadAhead.RoadView.ahead_of(
		Route.from_segments([
			{
				..Fixtures.segment_of([]),
				length: Distance.metres(300.0),
				ending: Bends({ turn, bend_life: Quiet }),
			},
			Fixtures.segment_of([]),
		]),
		Route.SegmentIndex.number(1),
	)

expect
	[
		(
			turned_point_at(road_past_bend(left_turn), JustBehind).right.to_metres(),
			-194.76069932822074,
		),
		(
			turned_point_at(road_past_bend(left_turn), JustBehind).forward.to_metres(),
			-231.63435691739767,
		),
		(
			turned_point_at(road_past_bend(right_turn), JustBehind).right.to_metres(),
			239.9883995667414,
		),
		(
			turned_point_at(road_past_bend(right_turn), JustBehind).forward.to_metres(),
			-218.13274420105967,
		),
	].all(|(got, want)| (got - want).abs() <= 0.0000001 * want.abs().max(1.0))

## The segment in view just behind the rider on `road_view`, which must have
## one.
segment_in_view_behind : RoadAhead.RoadView -> RoadAhead.SegmentInView
segment_in_view_behind = |road_view|
	match RoadAhead.segments_in_view(road_view).last() {
		Ok(in_view) if in_view.place == JustBehind => in_view
		_ => crash "RoadExpects.segment_in_view_behind: this rider has a segment behind"
	}

## The apex of a bend from a segment 300 m long, just behind the rider's, as
## `turned_vantage` sees it.
apex_after_turn : Angle.Turn -> Geom.RiderPoint
apex_after_turn = |turn| {
	road_view = road_past_bend(turn)
	bend_in_view = BendInView.of_in_view(segment_in_view_behind(road_view))
	RoadAhead.rider_point_at(
		road_view,
		{
			vantage: turned_vantage,
			place: bend_in_view.place_before(),
			road_point: bend_in_view.outer_corner().apex,
		},
	)
}

# Each is within 1e-7 of its want, scaled up by a want past 1.
expect
	[
		(apex_after_turn(right_turn).right.to_metres(), 17.297297467543466),
		(apex_after_turn(right_turn).forward.to_metres(), -100.43071597950589),
		(apex_after_turn(left_turn).right.to_metres(), 21.403438709482494),
		(apex_after_turn(left_turn).forward.to_metres(), -100.55298847633645),
	].all(|(got, want)| (got - want).abs() <= 0.0000001 * want.abs().max(1.0))

## A flat polygon's colour.
flat_color_of : Shapes.Shape -> RgbColor
flat_color_of = |shape|
	match Fixtures.polygon_of(shape).fill {
		Flat(color) => {
			red = color.r.to_i64_wrap()
			green = color.g.to_i64_wrap()
			blue = color.b.to_i64_wrap()
			RgbColor.of(red * 65536 + green * 256 + blue)
		}
		Span(_) | Radial(_) | Linear(_) | Ellipse(_) | Glow(_) =>
			crash "RoadExpects.flat_color_of: this polygon is not flat"
	}

# Each segment ends where the lengths before it and its own add up to.
expect {
	stretches =
		Route.from_segments([
			{
				..Fixtures.going_straight_on(Fixtures.segment_of([])),
				length: Distance.metres(300.0),
			},
			{
				..Fixtures.going_straight_on(Fixtures.segment_of([])),
				length: Distance.metres(150.0),
			},
			{ ..Fixtures.segment_of([]), length: Distance.metres(50.0) },
		]).segments_with_ends()
	lengths = stretches.map(|stretch| stretch.segment.length.to_metres())
	ends = stretches.map(|stretch| stretch.end.to_metres())
	lengths == [300.0, 150.0, 50.0] and ends == [300.0, 450.0, 500.0]
}

# A point on the rider's own segment, as a camera there sees it, turned as the
# camera faces: RoadAhead's turn from the road into the rider's view.
expect {
	seen_from = |road_point, yaw|
		RoadAhead.rider_point_at(
			Fixtures.road,
			{
				vantage: {
					along: Along.metres(5.0),
					across: Across.metres(0.5),
					yaw: Angle.Turn.radians(yaw),
				},
				place: Ahead(SegmentPlace.Position.first),
				road_point,
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

# GroundPatch's shapes. A ground patch's checks sit here because the corners
# need Distance and the fill needs Brush, and GroundPatch imports neither.
sample_patch_shape : List(Geom.RiderPoint) -> Try(Shapes.Shape, [PastHorizon, BehindCamera])
sample_patch_shape = |corners| GroundPatch.patch_shape(
	GroundPatch.of(corners, RgbColor.of(0x2F7E8C)),
	Pixels.of(685.5110432362151),
)

patch_corners_ahead : List(Geom.RiderPoint)
patch_corners_ahead = [
	{ right: Distance.metres(-5.0), forward: Distance.metres(10.0) },
	{ right: Distance.metres(5.0), forward: Distance.metres(10.0) },
	{ right: Distance.metres(5.0), forward: Distance.metres(20.0) },
	{ right: Distance.metres(-5.0), forward: Distance.metres(20.0) },
]

# A patch of `count` corners, all ahead of the camera.
corners_ahead : I64 -> List(Geom.RiderPoint)
corners_ahead = |count|
	List.from_iter(I64.until(0, count)).map(
		|k| {
			offset = (count - k).to_f64()
			{ right: Distance.metres(offset), forward: Distance.metres(10.0 + offset) }
		},
	)

## What became of a patch: drawn, or why not.
patch_outcome : Try(Shapes.Shape, [PastHorizon, BehindCamera]) -> [Drawn, PastHorizon, BehindCamera]
patch_outcome = |shape|
	match shape {
		Ok(_) => Drawn
		Err(PastHorizon) => PastHorizon
		Err(BehindCamera) => BehindCamera
	}

# A patch that straddles the horizon is kept, and one wholly past it is not.
expect
	sample_patch_shape([
		{ right: Distance.metres(-2.0), forward: Distance.metres(480.0) },
		{ right: Distance.metres(2.0), forward: Distance.metres(480.0) },
		{ right: Distance.metres(2.0), forward: Distance.metres(505.0) },
		{ right: Distance.metres(-2.0), forward: Distance.metres(505.0) },
	]).is_ok()
expect
	patch_outcome(
		sample_patch_shape([
			{ right: Distance.metres(-2.0), forward: Distance.metres(495.0) },
			{ right: Distance.metres(2.0), forward: Distance.metres(495.0) },
			{ right: Distance.metres(2.0), forward: Distance.metres(520.0) },
			{ right: Distance.metres(-2.0), forward: Distance.metres(520.0) },
		]),
	)
		== PastHorizon
expect
	patch_outcome(
		sample_patch_shape([
			{ right: Distance.metres(-5.0), forward: Distance.metres(-10.0) },
			{ right: Distance.metres(5.0), forward: Distance.metres(-10.0) },
			{ right: Distance.metres(5.0), forward: Distance.metres(-20.0) },
			{ right: Distance.metres(-5.0), forward: Distance.metres(-20.0) },
		]),
	)
		== BehindCamera

expect sample_patch_shape(patch_corners_ahead).is_ok()
expect sample_patch_shape(corners_ahead(8)).is_ok()
expect sample_patch_shape(corners_ahead(9)).is_ok()

expect {
	match sample_patch_shape(patch_corners_ahead) {
		Ok(Poly(polygon)) =>
			polygon.fill == Flat(Brush.opaque(RgbColor.of(0x2F7E8C)))
				and polygon.coordinates.len() == 8
		_ => False
	}
}

# GroundSighting's road along the first segment, 500 m long: one patch, its
# edges laid in 20 chunks of 25 m.
## A list of patches as a camera the drawing checks read paints them.
patch_shapes : List(GroundPatch) -> List(Shapes.Shape)
patch_shapes = |patches| patches.keep_oks(|patch| GroundPatch.patch_shape(patch, Pixels.of(500.0)))

## The ground in view from `rider_vantage` on the road ahead of the route's
## first segment. Its first patch is the road along that segment.
patches_seen_from : Geom.Vantage -> List(GroundPatch)
patches_seen_from = |rider_vantage|
	GroundSighting.patches_in_view(Fixtures.road, { vantage: rider_vantage })

first_road : GroundPatch
first_road = patches_seen_from(Fixtures.origin).first() ?? crash "RoadExpects: the first segment lays road"

corner : List(Geom.RiderPoint), U64 -> Geom.RiderPoint
corner = |
	corners,
	i,
| corners.get(i) ?? crash "RoadExpects: the road has a corner at each chunk's end on either edge"

## The road's corners where chunk `number` starts, on the right edge and the
## left: the start, then up the right edge, then back down the left.
chunk_start_corners : U64 -> (Geom.RiderPoint, Geom.RiderPoint)
chunk_start_corners = |number| {
	left_index = if number == 0 {
		0
	} else {
		42 - number
	}
	(corner(first_road.corners(), number + 1), corner(first_road.corners(), left_index))
}

expect first_road.corners().len() == 42
expect
	List.from_iter(U64.until(0, 21)).all(
		|number| {
			(right_corner, left_corner) = chunk_start_corners(number)
			want_forward = 25.0 * number.to_f64()
			(right_corner.right.to_metres() - 2.0).abs() <= 0.0001
				and (left_corner.right.to_metres() + 2.0).abs() <= 0.0001
				and (right_corner.forward.to_metres() - want_forward).abs() <= 0.0001
				and right_corner.forward == left_corner.forward
		},
	)

strip_shapes : List(Shapes.Shape)
strip_shapes = patch_shapes([first_road])

expect strip_shapes.len() == 1
expect {
	road_behind =
		patches_seen_from({ ..Fixtures.origin, along: Along.metres(5000.0) }).take_first(1)
	road_behind.len() == 1 and patch_shapes(road_behind).len() == 0
}
last_shape : Shapes.Shape
last_shape = strip_shapes.last() ?? crash "RoadExpects: the road draws"

expect flat_color_of(last_shape) == RgbColor.of(0x34353C)

# Seen from its start, the road is cut at the near plane and at the horizon,
# 490 m out, so it keeps its corners from 25 m to 475 m on both edges, and
# gains two where each cut crosses its edges.
expect Fixtures.coordinates_of(last_shape).len() == 2 * (2 * 19 + 4)

# The paving of the first bend takes in 40 m of road on either side of it, so
# its corners reach back to 460 m along the first segment.
expect
	match GroundSighting.patches_in_view(Fixtures.road, Fixtures.origin_camera).get(1) {
		Ok(paving) => {
			paving_corners = paving.corners()
			paving_corners.len() == 8
				and paving_corners.any(|point| (point.forward.to_metres() - 460.0).abs() <= 0.0001)
		}
		Err(_) => False
	}

## The place `metres` along the truck road's route.
truck_route_place : F64 -> Try(RoutePlace, [PastRouteEnd])
truck_route_place = |metres|
	RoutePlace.at_distance(Fixtures.truck_road.route(), Distance.metres(metres))

## The place on the truck road's segment at `count_before`, `along` metres
## from its start, on the middle of the road.
truck_route_place_on : U32, F64 -> RoutePlace
truck_route_place_on = |count_before, along| {
	segment_index: Route.SegmentIndex.number(count_before),
	along: Along.metres(along),
	across: Across.middle,
}

# A place found by its distance is on the segment it falls on, and a distance at
# a segment's end is that segment's end, not the next one's start; just past the
# route's end is past it.
expect
	[
		(0.0, Ok(truck_route_place_on(0, 0.0))),
		(250.0, Ok(truck_route_place_on(0, 250.0))),
		(500.0, Ok(truck_route_place_on(0, 500.0))),
		(500.5, Ok(truck_route_place_on(1, 0.5))),
		(660.0, Ok(truck_route_place_on(1, 160.0))),
		(820.0, Ok(truck_route_place_on(1, 320.0))),
		(1000.0, Ok(truck_route_place_on(2, 180.0))),
		(1220.0, Ok(truck_route_place_on(2, 400.0))),
		(1220.5, Err(PastRouteEnd)),
	].all(|(metres, want)| truck_route_place(metres) == want)

# `distance_along` undoes `at_distance`, at each segment's end and in its middle.
expect
	[0.0, 250.0, 500.0, 660.0, 820.0, 1000.0, 1220.0].all(
		|metres| {
			place = truck_route_place(metres) ?? crash "RoadExpects: the place is on the truck road"
			place.distance_along(Fixtures.truck_road.route()).to_metres() == metres
		},
	)
