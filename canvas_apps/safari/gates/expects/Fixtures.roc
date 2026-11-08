## Fixtures holds what two or more of the expects' modules share: the crafted
## roads, segments and routes, the cats and birds seen on the cat route, and
## the helpers that read a polygon's corners.

import game.Across
import game.Along
import game.Angle
import game.BirdFlight
import game.Conifer
import game.Distance
import game.EncounterPlan
import game.EncounterPoses
import game.EncounterSighting
import game.Geom
import game.Pipeline
import game.Pixels
import game.PosedBird
import game.PosedCat
import game.RoadAhead
import game.Route
import game.Segment
import game.SegmentPlace
import game.Trees
import game.World
import lib.Brush
import lib.Shapes

Fixtures :: [].{

	## The rider at the start of a segment, in the middle of the road, looking
	## straight down it.
	origin : Geom.Vantage
	origin = {
		along: Along.metres(0.0),
		across: Across.metres(0.0),
		yaw: Angle.straight_ahead,
	}

	## The camera at `origin`, with a focal length of 500 pixels.
	origin_camera : { vantage : Geom.Vantage, cam_focal : Pixels }
	origin_camera = { vantage: origin, cam_focal: Pixels.of(500.0) }

	## The road ahead of a rider on the world's segment `number`.
	world_road_at : U32 -> RoadAhead.RoadView
	world_road_at = |number|
		RoadAhead.RoadView.ahead_of(World.route, Route.SegmentIndex.number(number))

	## The road ahead of a rider on the route's first segment.
	road : RoadAhead.RoadView
	road = world_road_at(0)

	## The segment after the rider's own on the road ahead.
	second_position : SegmentPlace.Position
	second_position = SegmentPlace.Position.first.next()

	polygon_of : Shapes.Shape -> { coordinates : List(F64), fill : Brush.Fill }
	polygon_of = |shape|
		match shape {
			Poly(polygon) => polygon
			Disc(_) | Rect(_) | Blend(_) | View(_) | Image(_) | Text(_) =>
				crash "Fixtures.polygon_of: this shape is not a polygon"
		}

	## A polygon's coordinates, flat as x0, y0, x1, y1, ...
	coordinates_of : Shapes.Shape -> List(F64)
	coordinates_of = |shape| polygon_of(shape).coordinates

	tree_at : F64, F64 -> Trees.RoadsideTree
	tree_at = |along, across| {
		road_point: { along: Along.metres(along), across: Across.metres(across) },
		lift: Distance.zero,
		kind: Conifer.Red,
	}

	## A segment 200 m long holding only `trees`, with a quiet road, which ends a
	## route.
	segment_of : List(Trees.RoadsideTree) -> Segment
	segment_of = |trees| {
		..World.route.segment_at(Route.SegmentIndex.first),
		length: Distance.metres(200.0),
		trees,
		ending: RouteEnds,
		encounter: QuietRoad,
	}

	## The road ahead of a rider on the first of `segments`, a route of their own.
	crafted_road : List(Segment) -> RoadAhead.RoadView
	crafted_road = |segments|
		RoadAhead.RoadView.ahead_of(Route.from_segments(segments), Route.SegmentIndex.first)

	## `segment`, bending straight on into another.
	going_straight_on : Segment -> Segment
	going_straight_on = |segment| {
		..segment,
		ending: Bends({ turn: Angle.straight_ahead, bend_life: Animal(Elephant) }),
	}

	## The second segment, with a cat crossing it.
	cat_segment : Segment
	cat_segment = {
		..World.route.segment_at(Route.SegmentIndex.number(1)),
		encounter: World.route.segment_at(Route.SegmentIndex.number(3)).encounter,
	}

	## The route's first three segments, a route of their own, with a cat crossing
	## the second.
	cat_route : Route
	cat_route = Route.from_segments([
		World.route.segment_at(Route.SegmentIndex.first),
		cat_segment,
		{ ..World.route.segment_at(Route.SegmentIndex.number(2)), ending: RouteEnds },
	])

	## The road ahead of a rider on the cat route's first segment.
	cat_road : RoadAhead.RoadView
	cat_road = RoadAhead.RoadView.ahead_of(cat_route, Route.SegmentIndex.first)

	## The birds the camera sees on `road_view`, with the encounter on the
	## rider's segment at `encounter_timing`.
	birds_seen_on : RoadAhead.RoadView,
	{
		camera : { vantage : Geom.Vantage, cam_focal : Pixels },
		encounter_timing : EncounterPlan.Timing,
	} -> List(Pipeline.Sighted(PosedBird))
	birds_seen_on = |road_view, { camera, encounter_timing }|
		EncounterSighting.animals_in_view(
			road_view,
			{ camera, animals: EncounterPoses.bird_poses(road_view, encounter_timing) },
		)

	## The cats the camera sees on `road_view`, with the encounter on the rider's
	## segment at `encounter_timing`.
	cats_seen_on : RoadAhead.RoadView,
	{
		camera : { vantage : Geom.Vantage, cam_focal : Pixels },
		encounter_timing : EncounterPlan.Timing,
	} -> List(Pipeline.Sighted(PosedCat))
	cats_seen_on = |road_view, { camera, encounter_timing }|
		EncounterSighting.animals_in_view(
			road_view,
			{ camera, animals: EncounterPoses.cat_poses(road_view, encounter_timing) },
		)

	## The cats in view for a rider `along` metres into the first segment.
	ride_sightings : F64 -> List(Pipeline.Sighted(PosedCat))
	ride_sightings = |along| cats_seen_on(
		cat_road,
		{
			camera: { ..origin_camera, vantage: { ..origin, along: Along.metres(along) } },
			encounter_timing: Unplanned,
		},
	)

	seen : List(Pipeline.Sighted(PosedCat))
	seen = ride_sightings(300.0)

	## The flights of the route.
	route_flights : List(BirdFlight.Flight)
	route_flights = World.route.route_segments().join_map(
		|segment|
			match segment.encounter {
				BirdHere(flight) => [flight]
				CatCrosses(_) | QuietRoad => []
			},
	)

	## The route's longest segment.
	longest_segment_index : Route.SegmentIndex
	longest_segment_index = {
		(_, longest_at) =
			World.route.route_segments()
				.map_with_index(|segment, at| (segment.length, at))
				.fold(
					(Distance.zero, 0),
					|(best_length, best_at), (length, at)|
						if length > best_length {
							(length, at)
						} else {
							(best_length, best_at)
						},
				)
		Route.SegmentIndex.number(longest_at.to_u32_wrap())
	}

	## A straight road of three segments, 500 m, 320 m and 400 m long, and the
	## road ahead of a rider on the first of them.
	truck_road : RoadAhead.RoadView
	truck_road = crafted_road([
		{ ..going_straight_on(segment_of([])), length: Distance.metres(500.0) },
		{ ..going_straight_on(segment_of([])), length: Distance.metres(320.0) },
		{ ..segment_of([]), length: Distance.metres(400.0) },
	])
}
