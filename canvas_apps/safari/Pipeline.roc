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
import Camera
import Distance
import Geom
import Picture
import Pixels
import Rendered
import Spot

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
		rider_point = RoadAhead.rider_point_at(road, { vantage, place, road_point })
		foot = Geom.ahead_on_level(rider_point)?
		Ok({ spot: Spot.at({ place, road_point, lift: placed.lift, foot }), kind: placed.kind })
	}

	## The sighting of scenery `placed` on the segment at `place`, if it stands
	## at least `smallest_height_on_screen` tall through the camera's own lens,
	## so that what is at the edge of sight comes and goes as the camera widens.
	## Every kind with a size test takes it here.
	scenery_sighting_of : Geom.Placed(kind),
	{
		road : RoadAhead.RoadView,
		camera : { vantage : Geom.Vantage, cam_focal : Pixels, .. },
		place : SegmentPlace,
	} -> Try(Pipeline.Sighted(kind), [BehindCamera, TooSmall])
		where [kind.scenery_height : kind -> Distance]
	scenery_sighting_of = |placed, { road, camera, place }| {
		sighting = sighting_of(placed, { road, vantage: camera.vantage, place })?
		height_on_screen = Camera.height_on_screen(
			{ height: placed.kind.scenery_height(), forward: sighting.spot.foot().forward() },
			camera.cam_focal,
		)
		if height_on_screen < Pipeline.smallest_height_on_screen {
			Err(TooSmall)
		} else {
			Ok(sighting)
		}
	}

	## `sighting` drawn through a lens of focal length `cam_focal`, with `context`
	## for whatever else its kind needs.
	rendering_of : Pipeline.Sighted(kind), { cam_focal : Pixels, context : context } -> Rendered
		where [kind.scenery_picture : kind, Picture.Setting(context) -> Picture]
	rendering_of = |sighting, { cam_focal, context }|
		Rendered.of(
			sighting.spot.foot().forward(),
			sighting.kind.scenery_picture({ spot: sighting.spot, cam_focal, context }),
		)
}
