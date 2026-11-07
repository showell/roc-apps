## BirdSighting finds the Roc birds the rider can see in a frame: each one on a
## segment of the chain ahead, placed where its flight has got to, if it is in
## front of the camera and tall enough on screen to draw.
import BirdFlight
import BirdShapes
import Chain
import Geom
import Detail
import Pipeline

BirdSighting :: [].{

	## The birds in view, the nearest segment's first.
	birds_in_view : Chain.Viewpoint -> List(Geom.Sighted(BirdShapes.PosedBird))
	birds_in_view = |view| {
		positions = Chain.Position.positions_in(view.road.chain_indices)
		positions.keep_oks(|position| segment_bird(view, position))
	}
}

## The bird of the segment at `position` in the chain, if that segment has one
## and it is in view.
segment_bird : Chain.Viewpoint,
Chain.Position -> Try(
	Geom.Sighted(BirdShapes.PosedBird),
	[NoBird, BehindCamera, TooSmall],
)
segment_bird = |view, position|
	match position.index_in(view.road.chain_indices).segment_in(view.road.route_segments).crossing {
		BirdHere(habit) => {
			gap_to_segment = Chain.gap_to_segment(view.road, position)
			gap_to_tree = gap_to_segment.plus(BirdFlight.start_along(habit).from_start())
			instant = BirdFlight.habit_instant_at(habit, { gap: gap_to_tree })
			bird_in_view(view, { position, instant })
		}
		CatCrosses(_) | QuietRoad => Err(NoBird)
	}

## The bird at `instant` on the segment at `position` in the chain, if it is in
## view.
bird_in_view : Chain.Viewpoint,
{
	position : Chain.Position,
	instant : BirdFlight.Bird,
} -> Try(Geom.Sighted(BirdShapes.PosedBird), [BehindCamera, TooSmall])
bird_in_view = |view, { position, instant }| {
	placed_bird : Geom.Placed(BirdShapes.PosedBird)
	placed_bird = {
		along: instant.spot.along,
		across: instant.spot.across,
		kind: { pose: instant.pose, lift: instant.spot.lift },
	}
	Pipeline.sighting_of(
		placed_bird,
		{
			road: view.road,
			place: InChain(position),
			size_test: { focal: view.cam_focal, smallest_px: Detail.min_scenery_px },
		},
	)
}
