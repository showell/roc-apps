## CatSighting finds the cats the rider can see in a frame: each one waiting
## on a segment of the chain ahead, placed where its crossing has got to,
## if it is in front of the camera and tall enough on screen to draw.
import Cat
import DepthSort
import Distance
import Frame
import Geom
import SceneLimits
import Speed

CatSighting :: [].{

	## A cat to draw: where it stands in the rider's view, its height, its
	## pose, and how high its leap has raised it.
	CatItem : {
		right : F64,
		forward : F64,
		height : Distance,
		pose : Cat.Pose,
		lift : F64,
	}

	## At most this many cats are drawn in a frame.
	max_vis_cats : I64
	max_vis_cats = 8

	## The cats in view of a rider at `speed`, the nearest segment's first.
	in_view : Frame.Viewpoint, Speed -> List(CatSighting.CatItem)
	in_view = |view, speed| {
		positions = Frame.ChainPosition.all_in(view.road.chain)
		positions.join_map(|position| segment_cat(view, { position, speed }))
	}

	## The cat waiting on the segment at `position` in the chain, if it has one
	## and it is in view.
	segment_cat : Frame.Viewpoint,
	{
		position : Frame.ChainPosition,
		speed : Speed,
	} -> List(CatSighting.CatItem)
	segment_cat = |view, { position, speed }|
		match position.index_in(view.road.chain).segment_in(view.road.world).crossing {
			CatCrosses(crossing) =>
				cat_in_view(
					view,
					{
						position,
						crossing,
						speed,
					},
				)
			BirdFlies(_) | QuietRoad => []
		}

	## The cats as the depth sort sees them: each one's distance ahead, and
	## its position in `cats`.
	depth_keys : List(CatSighting.CatItem) -> List(DepthSort.DepthKey)
	depth_keys = |cats| cats.map_with_index(
		|cat, i| {
			forward: cat.forward,
			subject: Cat(i.to_u32_wrap()),
		},
	)
}

## The cat crossing the segment at `position` in the chain, as far through its
## crossing as the rider's approach has brought it, if it is in view: one
## item, or none.
cat_in_view : Frame.Viewpoint,
{
	position : Frame.ChainPosition,
	crossing : Cat.Crossing,
	speed : Speed,
} -> List(CatSighting.CatItem)
cat_in_view = |
	view,
	{
		position,
		crossing,
		speed,
	},
| {
	gap = Frame.gap_to_segment(view.road, position)
	instant = Cat.instant_at(crossing, { gap: gap.plus(crossing.along.from_start()), speed })
	seen = Frame.rider_point_ahead(
		view.road,
		{
			position: position,
			along: crossing.along.plus(instant.spot.along.from_start()),
			across: instant.spot.across,
		},
	)
	height_px = (crossing.height.to_metres() / seen.forward) * view.cam_focal
	if seen.forward <= Geom.near_plane {
		[]
	} else if height_px < SceneLimits.min_scenery_px {
		[]
	} else {
		[
			{
				right: seen.right,
				forward: seen.forward,
				height: crossing.height,
				pose: instant.pose,
				lift: instant.spot.lift,
			},
		]
	}
}
