## BirdSighting finds the Roc birds the rider can see in a frame: each one on a
## segment of the chain ahead, placed where its flight has got to, if it is in
## front of the camera and tall enough on screen to draw.
import Animation
import BirdFlight
import DepthSort
import Distance
import Chain
import Geom
import RocBird
import SceneLimits

BirdSighting :: [].{

	## The birds in view, the nearest segment's first.
	in_view : Chain.Viewpoint -> List(RocBird.PlacedBird)
	in_view = |view| {
		positions = Chain.Position.all_in(view.road.chain)
		positions.join_map(|position| segment_bird(view, position))
	}

	## The birds as the depth sort sees them: each one's distance ahead, and
	## its position in `birds`. How high a bird is doesn't change how far away
	## it is.
	depth_keys : List(RocBird.PlacedBird) -> List(DepthSort.DepthKey)
	depth_keys = |birds| birds.map_with_index(
		|bird, i| { forward: bird.forward, subject: Bird(i.to_u32_wrap()) },
	)
}

## The bird of the segment at `position` in the chain, if that segment has one
## and it is in view: one item, or none.
segment_bird : Chain.Viewpoint, Chain.Position -> List(RocBird.PlacedBird)
segment_bird = |view, position|
	match position.index_in(view.road.chain).segment_in(view.road.world).crossing {
		BirdFlies(route) => {
			gap_to_segment = Chain.gap_to_segment(view.road, position)
			gap_to_tree = gap_to_segment.plus(BirdFlight.start_along(route).from_start())
			instant = BirdFlight.route_instant_at(route, gap_to_tree)
			bird_in_view(view, { position, instant })
		}
		CatCrosses(_) | QuietRoad => []
	}

## The bird at `instant` on the segment at `position` in the chain, if it is in
## view: one item, or none.
bird_in_view : Chain.Viewpoint,
{
	position : Chain.Position,
	instant : Animation.Instant(BirdFlight.Pose),
} -> List(RocBird.PlacedBird)
bird_in_view = |view, { position, instant }| {
	seen = Chain.rider_point_ahead(
		view.road,
		{ position, along: instant.spot.along, across: instant.spot.across },
	)
	height_px = RocBird.height_px({ forward: seen.forward, cam_focal: view.cam_focal })
	if seen.forward <= Geom.near_plane {
		[]
	} else if height_px < SceneLimits.min_scenery_px {
		[]
	} else {
		[
			{
				right: seen.right,
				forward: seen.forward,
				lift: Distance.metres(instant.spot.lift),
				pose: instant.pose,
			},
		]
	}
}
