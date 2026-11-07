## Pipeline carries an object through a frame, by way of three forms of it. An
## object is placed on the road (`Geom.Placed`), sighted from the camera
## (`Pipeline.Sighted`) and rendered (`Rendered`). The steps between them are
## written once here, for every kind of object. A kind is a type like `Conifer`,
## which knows nothing of this module: a `where` clause names the methods a step
## needs, and it matches them by name alone, so those names say what they are
## for. A kind holds how the object looks right now, and the form around it holds
## where the object is.
import RoadAhead
import SegmentPlace
import Across
import Along
import Angle
import Camera
import Distance
import Geom
import Picture
import Pixels
import Rendered
import Route
import Spot
import World

Pipeline :: [].{

	## An object in the rider's view, and what kind of object it is, for one
	## frame.
	Sighted(kind) : { spot : Spot, kind : kind }

	## The smallest thing worth drawing: an object that would stand less than
	## this tall on the screen isn't drawn.
	smallest_height_on_screen : Pixels
	smallest_height_on_screen = Pixels.of(2.0)

	## `placed` as the camera at `vantage` sees it, on the segment at `place`,
	## if it is at or past the camera's near plane.
	sighting_of : Geom.Placed(kind),
	{
		road : RoadAhead.RoadView,
		vantage : Geom.Vantage,
		place : SegmentPlace,
	} -> Try(Pipeline.Sighted(kind), [BehindCamera])
	sighting_of = |placed, { road, vantage, place }| {
		road_point = placed.road_point
		seen = RoadAhead.rider_point_at(road, { vantage, place, road_point })
		foot = Geom.ahead_on_level(seen)?
		Ok({ spot: Spot.at({ place, road_point, lift: placed.lift, foot }), kind: placed.kind })
	}

	## The sighting of `placed`, if it stands at least
	## `smallest_height_on_screen` tall through a lens of focal length
	## `size_focal`. Which lens that is, the camera's or the one at rest, is
	## the only way one kind's size test differs from another's.
	tall_sighting_of : Geom.Placed(kind),
	{
		road : RoadAhead.RoadView,
		vantage : Geom.Vantage,
		place : SegmentPlace,
		size_focal : Pixels,
	} -> Try(Pipeline.Sighted(kind), [BehindCamera, TooSmall])
		where [kind.scenery_height : kind -> Distance]
	tall_sighting_of = |placed, { road, vantage, place, size_focal }| {
		sighting = sighting_of(placed, { road, vantage, place })?
		height_on_screen = Camera.height_on_screen(
			{ height: placed.kind.scenery_height(), forward: sighting.spot.foot().forward() },
			size_focal,
		)
		if height_on_screen < Pipeline.smallest_height_on_screen {
			Err(TooSmall)
		} else {
			Ok(sighting)
		}
	}

	## The sighting of scenery `placed` on the segment at `place`, if it is tall
	## enough through the camera's own lens, so that what is at the edge of
	## sight comes and goes as the camera widens.
	scenery_sighting_of : Geom.Placed(kind),
	{
		road : RoadAhead.RoadView,
		camera : { vantage : Geom.Vantage, cam_focal : Pixels, .. },
		place : SegmentPlace,
	} -> Try(Pipeline.Sighted(kind), [BehindCamera, TooSmall])
		where [kind.scenery_height : kind -> Distance]
	scenery_sighting_of = |placed, { road, camera, place }|
		Pipeline.tall_sighting_of(
			placed,
			{
				road,
				vantage: camera.vantage,
				place,
				size_focal: camera.cam_focal,
			},
		)

	## `sighting` drawn through a lens of focal length `cam_focal`, with `context`
	## for whatever else its kind needs.
	rendering_of : Pipeline.Sighted(kind), { cam_focal : Pixels, context : context } -> Rendered
		where [kind.scenery_picture : kind, Picture.Setting(context) -> Picture]
	rendering_of = |sighting, { cam_focal, context }| {
		depth: sighting.spot.foot().forward(),
		picture: sighting.kind.scenery_picture({ spot: sighting.spot, cam_focal, context }),
	}
}

## A kind of object that exists for this file's expects: a post of some height,
## pictured as nothing.
Post := { height : Distance }.{

	scenery_height : Post -> Distance
	scenery_height = |post| post.height

	scenery_picture : Post, Picture.Setting({}) -> Picture
	scenery_picture = |_post, _setting| Picture.from_shapes([])
}

## A post of `height`, `along` the first segment and 1.5 m right of the road's
## middle.
placed_post : { along : Along, height : Distance } -> Geom.Placed(Post)
placed_post = |{ along, height }| {
	road_point: { along, across: Across.metres(1.5) },
	lift: Distance.zero,
	kind: Post.({ height: height }),
}

## The road ahead of a rider on the route's first segment.
first_road : RoadAhead.RoadView
first_road = RoadAhead.RoadView.ahead_of(World.route, Route.SegmentIndex.first)

## The camera at the start of the route, looking down the road.
first_vantage : Geom.Vantage
first_vantage = {
	along: Along.metres(0.0),
	across: Across.metres(0.0),
	yaw: Angle.straight_ahead,
}

first_place : SegmentPlace
first_place = Ahead(SegmentPlace.Position.first)

## A post 1 m tall, `along` the first segment, as the rider sees it.
post_sighting : Along -> Try(Pipeline.Sighted(Post), [BehindCamera])
post_sighting = |along|
	Pipeline.sighting_of(
		placed_post({ along, height: Distance.metres(1.0) }),
		{
			road: first_road,
			vantage: first_vantage,
			place: first_place,
		},
	)

## A post of `height`, 64 m ahead, if it stands 2 pixels tall through a lens of
## 128 pixels. A post 1 m tall stands exactly that.
tall_post_sighting : Distance -> Try(Pipeline.Sighted(Post), [BehindCamera, TooSmall])
tall_post_sighting = |height|
	Pipeline.tall_sighting_of(
		placed_post({ along: Along.metres(64.0), height }),
		{
			road: first_road,
			vantage: first_vantage,
			place: first_place,
			size_focal: Pixels.of(128.0),
		},
	)

# The near plane is 0.4 m ahead.
expect
	[
		(0.39, Err(BehindCamera)),
		(0.4, Ok(Seen)),
		(0.41, Ok(Seen)),
	].all(|(along, outcome)| post_sighting(Along.metres(along)).map_ok(|_| Seen) == outcome)

expect
	[
		(Distance.metres(0.99), Err(TooSmall)),
		(Distance.metres(1.0), Ok(Seen)),
		(Distance.metres(1.01), Ok(Seen)),
	].all(|(height, outcome)| tall_post_sighting(height).map_ok(|_| Seen) == outcome)

expect
	[30.0, 64.0].all(
		|along| {
			sighting = post_sighting(Along.metres(along)) ?? crash "Pipeline: a post 30 m or more ahead is in view"
			rendered = Pipeline.rendering_of(sighting, { cam_focal: Pixels.of(512.0), context: {} })
			rendered.depth == Distance.metres(along)
		},
	)
