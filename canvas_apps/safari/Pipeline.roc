## Pipeline carries an object through a frame, by way of three forms of it. An
## object is placed on the road (`Geom.Placed`), sighted from the camera
## (`Pipeline.Sighted`) and rendered (`Rendered`). The steps between them are
## written once here, for every kind of object. A kind is a type like `Conifer`,
## which knows nothing of this module: a `where` clause names the methods a step
## needs, and it matches them by name alone, so those names say what they are
## for. A kind holds how the object looks right now, and the form around it holds
## where the object is.
##
## A sighting can be refused, and the refusal's tag says why the object isn't
## drawn this frame.
## `BehindCamera` means its foot is short of the camera's near plane, as
## `RiderView.rider_point_ahead` decides for `Pipeline.sighting_of`, and every
## sighting takes this test.
## `BelowHorizon` means the earth's curve hides the whole of it, as
## `EarthCurve.is_below_horizon` decides for `Pipeline.sighting_above_horizon_of`,
## which every kind with a height takes, the towers among them.
## `TooSmall` means it would stand less than `Pipeline.smallest_height_on_screen`
## tall, as `Pipeline.scenery_sighting_of` decides for the trees, the
## billboards, the cats and the birds, though not for the towers or the truck.
## `NoTruck` means the truck is past the route's end or off the road ahead, as
## `TruckSighting.truck_in_view` decides before it sights the truck.
## `NoPose` means a segment in view has no cat or bird, or its encounter is
## over, as `EncounterPoses` decides before any camera looks.
## `NoMidTower` means the segment is too short for a tower halfway along, as
## `TowerSighting` decides from its length.
## Only the segments of `RoadAhead.segments_in_view` are looked at at all. Below
## a sighting, a shape can be dropped too: a part of the guard rail, a ground
## patch or a face of the truck cut away whole at the near plane
## (`Polygon.clipped_polygon`), a ground patch `PastHorizon`, or a beacon that is
## `TooDim` or `TooSmall` (`Beacon.disc`).
import RoadAhead
import SegmentFromRider
import Camera
import Distance
import EarthCurve
import Geom
import RiderView
import Sprite
import Pixels
import Rendered
import Spot

Pipeline :: [].{

	## An object in the rider's view, and what kind of object it is, for one
	## frame.
	Sighted(kind) : { spot : Spot, kind : kind }

	## The camera a sighting is made through: where it stands and faces, and
	## the focal length of its lens.
	SightingCamera : { vantage : Geom.Vantage, focal_length : Pixels }

	## `placed` as a camera at `vantage` sees it, on the segment that lies at
	## `from_rider`, if it is at or past the camera's near plane.
	sighting_of : Geom.Placed(kind),
	{
		road : RoadAhead.RoadView,
		vantage : Geom.Vantage,
		from_rider : SegmentFromRider,
	} -> Try(Pipeline.Sighted(kind), [BehindCamera])
	sighting_of = |placed, { road, vantage, from_rider }| {
		road_point = placed.road_point
		rider_point = RoadAhead.rider_point_at(road, { vantage, from_rider, road_point })
		foot = RiderView.rider_point_ahead(rider_point)?
		road_heading = RoadAhead.road_heading_at(road, { vantage, from_rider, road_point })
		spot = Spot.at({ lift: placed.lift, foot, road_heading })
		Ok({ spot, kind: placed.kind })
	}

	## The sighting of `placed` on the segment at `from_rider`, if some of it shows
	## over the horizon: its top, its kind's height above its lift and lowered
	## by the ground's drop, is not hidden behind the curve of the ground. Every
	## kind with a height takes this test here.
	sighting_above_horizon_of : Geom.Placed(kind),
	{
		road : RoadAhead.RoadView,
		vantage : Geom.Vantage,
		from_rider : SegmentFromRider,
	} -> Try(Pipeline.Sighted(kind), [BehindCamera, BelowHorizon])
		where [kind.scenery_height : kind -> Distance]
	sighting_above_horizon_of = |placed, { road, vantage, from_rider }| {
		sighting = sighting_of(placed, { road, vantage, from_rider })?
		spot = sighting.spot
		top = spot.lift().plus(placed.kind.scenery_height()).minus(spot.drop())
		if EarthCurve.is_below_horizon({ point: spot.foot().to_rider(), top }) {
			Err(BelowHorizon)
		} else {
			Ok(sighting)
		}
	}

	## The sighting of scenery `placed` on the segment at `from_rider`, if it shows
	## over the horizon and stands at least `smallest_height_on_screen` tall
	## through the camera's own lens, so that what is at the edge of sight
	## comes and goes as the camera widens. Every kind with a size test takes
	## it here.
	scenery_sighting_of : Geom.Placed(kind),
	{
		road : RoadAhead.RoadView,
		camera : Pipeline.SightingCamera,
		from_rider : SegmentFromRider,
	} -> Try(Pipeline.Sighted(kind), [BehindCamera, BelowHorizon, TooSmall])
		where [kind.scenery_height : kind -> Distance]
	scenery_sighting_of = |placed, { road, camera, from_rider }| {
		sighting = sighting_above_horizon_of(placed, { road, vantage: camera.vantage, from_rider })?
		height_on_screen = Camera.height_on_screen(
			{ height: placed.kind.scenery_height(), forward: sighting.spot.foot().forward() },
			camera.focal_length,
		)
		if height_on_screen < smallest_height_on_screen {
			Err(TooSmall)
		} else {
			Ok(sighting)
		}
	}

	## `sighting` drawn through a lens of `focal_length`, with `context`
	## for whatever else its kind needs.
	rendering_of : Pipeline.Sighted(kind), { focal_length : Pixels, context : context } -> Rendered
		where [kind.scenery_sprite : kind, Sprite.Setting(context) -> Sprite]
	rendering_of = |sighting, { focal_length, context }|
		Rendered.of(
			sighting.spot.foot().forward(),
			sighting.kind.scenery_sprite({ spot: sighting.spot, focal_length, context }),
		)

	## The smallest thing worth drawing: an object that would stand less than
	## this tall on the screen isn't drawn.
	smallest_height_on_screen : Pixels
	smallest_height_on_screen = Pixels.of(2.0)
}
