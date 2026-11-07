## Pipeline carries an object through a frame, by way of three forms of it. An
## object is placed on the road (`Geom.Placed`), sighted from the camera
## (`Geom.Sighted`) and rendered (`Rendered`). The steps between them are written
## once here, for every kind of object. A kind is a type like `Conifer`, which
## knows nothing of this module: a `where` clause names the methods a step needs,
## and it matches them by name alone, so those names say what they are for.
import Chain
import Distance
import Geom
import Picture
import Pixels
import Rendered

Pipeline :: [].{

	## How an object's size decides if it is drawn: it must stand at least
	## `smallest_px` tall through a lens of focal length `focal`.
	SizeTest : { focal : Pixels, smallest_px : Pixels }

	## `placed` as the rider sees it, on the segment at `place`, if it is past
	## the camera's near plane and passes `size_test`.
	sighting_of : Geom.Placed(kind),
	{
		road : Chain.RoadView,
		place : Chain.SegmentPlace,
		size_test : Pipeline.SizeTest,
	} -> Try(Geom.Sighted(kind), [BehindCamera, TooSmall])
		where [kind.scenery_height : kind -> Distance]
	sighting_of = |placed, { road, place, size_test }| {
		seen = Chain.rider_point_at(road, { place, along: placed.along, across: placed.across })
		height_px = size_test.focal.times(placed.kind.scenery_height().ratio_to(seen.forward))
		if seen.forward <= Geom.near_plane {
			Err(BehindCamera)
		} else if height_px < size_test.smallest_px {
			Err(TooSmall)
		} else {
			Ok({
				right: seen.right,
				forward: seen.forward,
				kind: placed.kind,
			})
		}
	}

	## `sighting` drawn through a lens of focal length `cam_focal`, with `context`
	## for whatever else its kind needs.
	rendering_of : Geom.Sighted(kind), { cam_focal : Pixels, context : context } -> Rendered
		where [kind.scenery_picture : kind, Picture.Setting(context) -> Picture]
	rendering_of = |sighting, { cam_focal, context }| {
		depth: sighting.forward,
		picture: sighting.kind.scenery_picture({
			right: sighting.right,
			forward: sighting.forward,
			cam_focal,
			context,
		}),
	}
}
