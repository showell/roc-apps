## CatSighting finds the cats the rider can see in a frame: each one waiting
## on a segment of the chain ahead, placed where its crossing has got to,
## if it is in front of the camera and tall enough on screen to draw.
import Cat
import DepthSort
import Distance
import Chain
import Geom
import Detail
import Speed

## A cat to draw: where it stands in the rider's view, its pose, and how high
## its leap has raised it. A cat in view is ahead of the rider, so of its
## lengths only `right` can be negative.
CatSighting := {
	right : Distance,
	forward : Distance,
	pose : Cat.Pose,
	lift : Distance,
}.{

	## The cats in view of a rider at `speed`, the nearest segment's first.
	cats_in_view : Chain.Viewpoint, Speed -> List(CatSighting)
	cats_in_view = |view, speed| {
		positions = Chain.Position.positions_in(view.road.chain_indices)
		positions.keep_oks(|position| segment_cat(view, { position, speed }))
	}

	## The cat waiting on the segment at `position` in the chain, if it has one
	## and it is in view.
	segment_cat : Chain.Viewpoint,
	{
		position : Chain.Position,
		speed : Speed,
	} -> Try(CatSighting, [NoCat, OutOfView])
	segment_cat = |view, { position, speed }|
		match position.index_in(view.road.chain_indices).segment_in(view.road.route_segments).crossing {
			CatCrosses(crossing) =>
				cat_in_view(view, { position, crossing, speed })
			BirdHere(_) | QuietRoad => Err(NoCat)
		}

	## The cats as the depth sort sees them: each one's distance ahead, and
	## its position in `cats`.
	depth_keys : List(CatSighting) -> List(DepthSort.DepthKey)
	depth_keys = |cats| cats.map_with_index(
		|cat, i| { forward: cat.forward, subject: Cat(i.to_u32_wrap()) },
	)
}

## The cat crossing the segment at `position` in the chain, as far through its
## crossing as the rider's approach has brought it, if it is in view.
cat_in_view : Chain.Viewpoint,
{
	position : Chain.Position,
	crossing : Cat.Crossing,
	speed : Speed,
} -> Try(CatSighting, [OutOfView])
cat_in_view = |view, { position, crossing, speed }| {
	gap = Chain.gap_to_segment(view.road, position)
	instant = Cat.instant_at(crossing, { gap: gap.plus(crossing.along.from_start()), speed })
	seen = Chain.rider_point_ahead(
		view.road,
		{ position, along: instant.spot.along, across: instant.spot.across },
	)
	height_px = view.cam_focal.times(Cat.cat_height.ratio_to(seen.forward))
	if seen.forward <= Geom.near_plane {
		Err(OutOfView)
	} else if height_px < Detail.min_scenery_px {
		Err(OutOfView)
	} else {
		Ok({
			right: seen.right,
			forward: seen.forward,
			pose: instant.pose,
			lift: instant.spot.lift,
		})
	}
}
