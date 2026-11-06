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

## A cat to draw: where it stands in the rider's view, its height, its
## pose, and how high its leap has raised it.
CatSighting := {
	right : F64,
	forward : F64,
	height : Distance,
	pose : Cat.Pose,
	lift : F64,
}.{

	## At most this many cats are drawn in a frame.
	max_visible_cats : I64
	max_visible_cats = 8

	## The cats in view of a rider at `speed`, the nearest segment's first.
	in_view : Chain.Viewpoint, Speed -> List(CatSighting)
	in_view = |view, speed| {
		positions = Chain.Position.all_in(view.road.chain)
		positions.join_map(|position| segment_cat(view, { position, speed }))
	}

	## The cat waiting on the segment at `position` in the chain, if it has one
	## and it is in view.
	segment_cat : Chain.Viewpoint, { position : Chain.Position, speed : Speed } -> List(CatSighting)
	segment_cat = |view, { position, speed }|
		match position.index_in(view.road.chain).segment_in(view.road.route).crossing {
			CatCrosses(crossing) =>
				cat_in_view(view, { position, crossing, speed })
			BirdHere(_) | QuietRoad => []
		}

	## The cats as the depth sort sees them: each one's distance ahead, and
	## its position in `cats`.
	depth_keys : List(CatSighting) -> List(DepthSort.DepthKey)
	depth_keys = |cats| cats.map_with_index(
		|cat, i| { forward: Distance.metres(cat.forward), subject: Cat(i.to_u32_wrap()) },
	)
}

## The cat crossing the segment at `position` in the chain, as far through its
## crossing as the rider's approach has brought it, if it is in view: one
## item, or none.
cat_in_view : Chain.Viewpoint,
{
	position : Chain.Position,
	crossing : Cat.Crossing,
	speed : Speed,
} -> List(CatSighting)
cat_in_view = |view, { position, crossing, speed }| {
	gap = Chain.gap_to_segment(view.road, position)
	instant = Cat.instant_at(crossing, { gap: gap.plus(crossing.along.from_start()), speed })
	seen = Chain.rider_point_ahead(
		view.road,
		{
			position: position,
			along: crossing.along.plus(instant.spot.along.from_start()),
			across: instant.spot.across,
		},
	)
	height_px = crossing.height.ratio_to(seen.forward) * view.cam_focal
	if seen.forward <= Geom.near_plane {
		[]
	} else if height_px < Detail.min_scenery_px {
		[]
	} else {
		[
			{
				right: seen.right.to_metres(),
				forward: seen.forward.to_metres(),
				height: crossing.height,
				pose: instant.pose,
				lift: instant.spot.lift,
			},
		]
	}
}
