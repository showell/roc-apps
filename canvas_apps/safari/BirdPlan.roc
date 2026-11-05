## BirdPlan finds the Roc birds the rider can see in a frame: each one on a
## segment of the chain ahead, placed where its flight has got to, if it is in
## front of the camera and tall enough on screen to draw.
import BirdFlight
import DepthSort
import Frame
import Geom
import RocBird
import SceneLimits
import Scenery
import World

BirdPlan :: [].{

	## What the birds are seen from: the world's segments, the chain of them
	## ahead of the rider, the rider's pose, the camera's focal length, and
	## how far along its segment the rider is.
	View : {
		world : List(World.Segment),
		chain : List(World.SegmentIndex),
		pose : Frame.Pose,
		cam_focal : F64,
		rider_along : F64,
	}

	## The birds in view, the nearest segment's first.
	in_view : BirdPlan.View -> List(RocBird.PlacedBird)
	in_view = |view| {
		positions = Frame.ChainPosition.all_in(view.chain)
		positions.join_map(|position| segment_bird(view, position))
	}

	## The birds as the depth sort sees them: each one's distance ahead, and
	## its position in `birds`. How high a bird is doesn't change how far away
	## it is.
	depth_keys : List(RocBird.PlacedBird) -> List(DepthSort.DepthKey)
	depth_keys = |birds| birds.map_with_index(
		|bird, i| {
			forward: bird.forward,
			subject: Bird(i.to_u32_wrap()),
		},
	)
}

## The road under `view`.
road_of : BirdPlan.View -> Frame.RoadView
road_of = |view| {
	world: view.world,
	chain: view.chain,
	pose: view.pose,
}

## The bird of the segment at `position` in the chain, if the segment has a
## tree for one and the bird is in view: one item, or none.
segment_bird : BirdPlan.View, Frame.ChainPosition -> List(RocBird.PlacedBird)
segment_bird = |view, position| {
	trees = position.index_in(view.chain).segment_in(view.world).trees
	match BirdFlight.fifth_left_tree(trees) {
		Found(tree) => {
			gap_to_segment = Frame.gap_to_segment(
				road_of(view),
				{ position, rider_along: view.rider_along },
			)
			gap_to_tree = gap_to_segment + tree.along
			state =
				match BirdFlight.flight_from(trees, tree) {
					Flies(flight) => BirdFlight.state(flight, gap_to_tree)
					Stays => BirdFlight.sitting_on(tree)
				}
			bird_in_view(view, { position, state })
		}
		NoTree => []
	}
}

## The bird in `state` on the segment at `position` in the chain, if it is in
## view: one item, or none.
bird_in_view : BirdPlan.View,
{
	position : Frame.ChainPosition,
	state : BirdFlight.BirdState,
} -> List(RocBird.PlacedBird)
bird_in_view = |view, { position, state }| {
	seen = Frame.rider_point_ahead(
		road_of(view),
		{
			position,
			along: state.along,
			across: state.across + Scenery.lane_width / 2.0,
		},
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
				lift: state.lift,
				pose: state.pose,
			},
		]
	}
}
