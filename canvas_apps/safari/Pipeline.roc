## Pipeline carries an object through a frame, by way of three forms of it. An
## object is placed on the road (`Geom.Placed`), sighted from the camera
## (`Pipeline.Sighted`) and rendered (`Rendered`). The steps between them are
## written once here, for every kind of object. A kind is a type like `Conifer`,
## which knows nothing of this module: a `where` clause names the methods a step
## needs, and it matches them by name alone, so those names say what they are
## for. A kind holds how the object looks right now, and the form around it holds
## where the object is.
import Across
import Along
import Chain
import Detail
import Distance
import Geom
import Picture
import Pixels
import Rendered

Pipeline :: [].{

	## An object in the rider's view, and what kind of object it is. It stands at
	## `along` and `across` on the segment at `place`, which is `right` and
	## `forward` of the camera. It is ahead of the rider, so of those two lengths
	## only `right` can be negative. It lasts one frame.
	Sighted(kind) : {
		place : Chain.SegmentPlace,
		along : Along,
		across : Across,
		right : Distance,
		forward : Distance,
		kind : kind,
	}

	## How an object's size decides if it is drawn: it must stand at least
	## `smallest_px` tall through a lens of focal length `focal`.
	SizeTest : { focal : Pixels, smallest_px : Pixels }

	## The size test of scenery seen through the camera's own lens, so that what
	## is at the edge of sight comes and goes as the camera widens.
	scenery_test : Chain.CameraView -> Pipeline.SizeTest
	scenery_test = |view| { focal: view.cam_focal, smallest_px: Detail.min_scenery_px }

	## `placed` as the rider sees it, on the segment at `place`, if it is past
	## the camera's near plane.
	sighting_of : Geom.Placed(kind),
	{
		road : Chain.RoadView,
		place : Chain.SegmentPlace,
	} -> Try(Pipeline.Sighted(kind), [BehindCamera])
	sighting_of = |placed, { road, place }| {
		seen = Chain.rider_point_at(road, { place, along: placed.along, across: placed.across })
		if seen.forward <= Geom.near_plane {
			Err(BehindCamera)
		} else {
			Ok({
				place,
				along: placed.along,
				across: placed.across,
				right: seen.right,
				forward: seen.forward,
				kind: placed.kind,
			})
		}
	}

	## The sighting of `placed`, if it also passes `size_test`.
	tall_sighting_of : Geom.Placed(kind),
	{
		road : Chain.RoadView,
		place : Chain.SegmentPlace,
		size_test : Pipeline.SizeTest,
	} -> Try(Pipeline.Sighted(kind), [BehindCamera, TooSmall])
		where [kind.scenery_height : kind -> Distance]
	tall_sighting_of = |placed, { road, place, size_test }| {
		sighting = sighting_of(placed, { road, place })?
		height_px = size_test.focal.times(placed.kind.scenery_height().ratio_to(sighting.forward))
		if height_px < size_test.smallest_px {
			Err(TooSmall)
		} else {
			Ok(sighting)
		}
	}

	## `sighting` drawn through a lens of focal length `cam_focal`, with `context`
	## for whatever else its kind needs.
	rendering_of : Pipeline.Sighted(kind), { cam_focal : Pixels, context : context } -> Rendered
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
