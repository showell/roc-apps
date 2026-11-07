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
	trees_in_view : RoadAhead.CameraView -> List(Pipeline.Sighted(Conifer))
	trees_in_view = |view|
		RoadAhead.segments_in_view(view.road).join_map(|in_view| segment_sightings(view, in_view))

	## The trees in view on a segment in view.
	segment_sightings : RoadAhead.CameraView,
	RoadAhead.SegmentInView -> List(
		Pipeline.Sighted(Conifer),
	)
	segment_sightings = |view, in_view|
		in_view.segment.trees.keep_oks(|tree| sighting_of(view, { place: in_view.place, tree }))

	## A tree on the segment at `place`, if it is in view. A tree's size is
	## tested through the camera's own lens, so a tree at the edge of what can be
	## seen comes and goes as the camera widens.
	sighting_of : RoadAhead.CameraView,
	{
		place : SegmentPlace,
		tree : Trees.RoadsideTree,
	} -> Try(Pipeline.Sighted(Conifer), [BehindCamera, TooSmall])
	sighting_of = |view, { place, tree }|
		Pipeline.tall_sighting_of(
			tree,
			{
				road: view.road,
				place,
				size_test: Pipeline.scenery_test(view),
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

## The first three segments, seen from `vantage`.
first_road : Geom.Vantage -> RoadAhead.RoadView
first_road = |vantage| {
	route: World.route,
	segments_ahead: { first_index: Route.SegmentIndex.first, count: 3 },
	vantage,
}

## The first three segments, seen from `vantage` through a camera of focal
## length `cam_focal`.
view_from : Geom.Vantage, Pixels -> RoadAhead.CameraView
view_from = |vantage, cam_focal| { road: first_road(vantage), cam_focal }

from_origin : RoadAhead.CameraView
from_origin = view_from(origin, Pixels.of(500.0))

## A green tree `along` metres into the first segment, 3.5 m right of the
## road's middle.
green_tree_at = |along| {
	place: Ahead(SegmentPlace.Position.first),
	tree: {
		road_point: { along: Along.metres(along), across: Across.metres(3.5) },
		lift: Distance.zero,
		kind: Conifer.Green,
	},
}

lone_tree : Pipeline.Sighted(Conifer)
lone_tree = TreeSighting.sighting_of(
	from_origin,
	green_tree_at(120.0),
) ?? crash "TreeSighting: a tree 120 m ahead is in view"

expect
	[
		(lone_tree.spot.foot().right().to_metres(), 3.5),
		(lone_tree.spot.foot().forward().to_metres(), 120.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

expect TreeSighting.sighting_of(from_origin, green_tree_at(120.0)).is_ok()
expect lone_tree.kind == Conifer.Green
expect
	[
		(TreeSighting.sighting_of(from_origin, green_tree_at(0.39)), False),
		(TreeSighting.sighting_of(from_origin, green_tree_at(0.4)), True),
		(TreeSighting.sighting_of(from_origin, green_tree_at(0.5)), True),
		(TreeSighting.sighting_of(view_from(origin, Pixels.of(1.0)), green_tree_at(120.0)), False),
		(TreeSighting.sighting_of(from_origin, green_tree_at(2000.0)), False),
	].all(|(seen, want)| seen.is_ok() == want)

expect
	[
		(from_origin, 28),
		(view_from(up_road, Pixels.of(500.0)), 20),
		(view_from(origin, Pixels.of(1.0)), 0),
	].all(
		|(view, want)| {
			trees = TreeSighting.segment_sightings(view, first_in_view(view))
			trees.len().to_i64_wrap() == want
		},
	)

## The rider's own segment, as a segment in `view`.
first_in_view : RoadAhead.CameraView -> RoadAhead.SegmentInView
first_in_view = |view| RoadAhead.segment_in_view_at(view.road, SegmentPlace.Position.first)

first_sightings : List(Pipeline.Sighted(Conifer))
first_sightings = TreeSighting.segment_sightings(from_origin, first_in_view(from_origin))

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
