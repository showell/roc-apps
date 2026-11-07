## TreeSighting finds the roadside trees the rider can see in a frame: those
## placed along the segments in view that stand in front of the camera and are
## tall enough on screen to draw.
import Pixels
import Across
import Along
import Angle
import Conifer
import Distance
import Geom
import RoadAhead
import Route
import SegmentPlace
import Pipeline
import Trees
import World

TreeSighting :: [].{

	## The trees in view, segment by segment in the order of
	## `RoadAhead.segments_in_view`, and each segment's in the order `Trees`
	## places them.
	trees_in_view : RoadAhead.RoadView,
	{
		vantage : Geom.Vantage,
		cam_focal : Pixels,
		..,
	} -> List(Pipeline.Sighted(Conifer))
	trees_in_view = |road, camera|
		RoadAhead.segments_in_view(road).join_map(
			|in_view| segment_sightings(road, { camera, in_view }),
		)

	## The trees in view on a segment in view.
	segment_sightings : RoadAhead.RoadView,
	{
		camera : { vantage : Geom.Vantage, cam_focal : Pixels, .. },
		in_view : RoadAhead.SegmentInView,
	} -> List(Pipeline.Sighted(Conifer))
	segment_sightings = |road, { camera, in_view }|
		in_view.segment.trees.keep_oks(
			|tree| sighting_of(road, { camera, place: in_view.place, tree }),
		)

	## A tree on the segment at `place`, if it is in view. A tree's size is
	## tested through the camera's own lens, so a tree at the edge of what can be
	## seen comes and goes as the camera widens.
	sighting_of : RoadAhead.RoadView,
	{
		camera : { vantage : Geom.Vantage, cam_focal : Pixels, .. },
		place : SegmentPlace,
		tree : Trees.RoadsideTree,
	} -> Try(Pipeline.Sighted(Conifer), [BehindCamera, TooSmall])
	sighting_of = |road, { camera, place, tree }|
		Pipeline.tall_sighting_of(
			tree,
			{
				road,
				vantage: camera.vantage,
				place,
				size_test: Pipeline.scenery_test(camera),
			},
		)
}

## The rider at the start of the route, looking straight down the road.
origin : Geom.Vantage
origin = {
	along: Along.metres(0.0),
	across: Across.metres(0.0),
	yaw: Angle.straight_ahead,
}

up_road : Geom.Vantage
up_road = {
	along: Along.metres(100.0),
	across: Across.metres(0.0),
	yaw: Angle.straight_ahead,
}

## The road ahead of a rider on the route's first segment.
first_road : RoadAhead.RoadView
first_road = RoadAhead.RoadView.ahead_of(World.route, Route.SegmentIndex.first)

from_origin : { vantage : Geom.Vantage, cam_focal : Pixels }
from_origin = { vantage: origin, cam_focal: Pixels.of(500.0) }

## A green tree `along` metres into the first segment, 3.5 m right of the
## road's middle, seen by `camera`.
green_tree_at : { vantage : Geom.Vantage, cam_focal : Pixels },
F64 -> Try(
	Pipeline.Sighted(Conifer),
	[BehindCamera, TooSmall],
)
green_tree_at = |camera, along|
	TreeSighting.sighting_of(
		first_road,
		{
			camera,
			place: Ahead(SegmentPlace.Position.first),
			tree: {
				road_point: { along: Along.metres(along), across: Across.metres(3.5) },
				lift: Distance.zero,
				kind: Conifer.Green,
			},
		},
	)

lone_tree : Pipeline.Sighted(Conifer)
lone_tree = green_tree_at(from_origin, 120.0) ?? crash "TreeSighting: a tree 120 m ahead is in view"

expect
	[
		(lone_tree.spot.foot().right().to_metres(), 3.5),
		(lone_tree.spot.foot().forward().to_metres(), 120.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

expect green_tree_at(from_origin, 120.0).is_ok()
expect lone_tree.kind == Conifer.Green
expect
	[
		(green_tree_at(from_origin, 0.39), False),
		(green_tree_at(from_origin, 0.4), True),
		(green_tree_at(from_origin, 0.5), True),
		(green_tree_at({ vantage: origin, cam_focal: Pixels.of(1.0) }, 120.0), False),
		(green_tree_at(from_origin, 2000.0), False),
	].all(|(seen, want)| seen.is_ok() == want)

## The trees in view on the rider's own segment, seen by `camera`.
first_segment_sightings : {
	vantage : Geom.Vantage,
	cam_focal : Pixels,
} -> List(Pipeline.Sighted(Conifer))
first_segment_sightings = |camera|
	TreeSighting.segment_sightings(
		first_road,
		{ camera, in_view: RoadAhead.segment_in_view_at(first_road, SegmentPlace.Position.first) },
	)

expect
	[
		(from_origin, 28),
		({ vantage: up_road, cam_focal: Pixels.of(500.0) }, 20),
		({ vantage: origin, cam_focal: Pixels.of(1.0) }, 0),
	].all(|(camera, want)| first_segment_sightings(camera).len().to_i64_wrap() == want)

first_sightings : List(Pipeline.Sighted(Conifer))
first_sightings = first_segment_sightings(from_origin)

## The first segment's tree at `i`, in planting order.
roadside_tree : U64 -> Pipeline.Sighted(Conifer)
roadside_tree = |i|
	first_sightings.get(i) ?? crash "TreeSighting: the first segment has 28 trees in view"

expect
	[
		(roadside_tree(0).spot.foot().forward().to_metres(), 6.0),
		(roadside_tree(1).spot.foot().forward().to_metres(), 6.0),
		(roadside_tree(2).spot.foot().forward().to_metres(), 36.0),
		(roadside_tree(0).spot.foot().right().to_metres(), -3.5),
		(roadside_tree(1).spot.foot().right().to_metres(), 3.5),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

expect roadside_tree(0).kind == Conifer.Green
expect roadside_tree(2).kind == Conifer.SmallGreen
