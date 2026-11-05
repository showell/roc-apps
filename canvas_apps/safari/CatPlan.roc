## CatPlan finds the cats the rider can see in a frame: each one waiting
## on a segment of the chain ahead, placed where its crossing has got to,
## if it is in front of the camera and tall enough on screen to draw.
import Cat
import DepthSort
import Frame
import Geom
import SceneLimits
import Scenery
import Speed

CatPlan :: [].{

	## A cat to draw: where it stands in the rider's view, its height, its
	## pose, and how high its leap has raised it.
	CatItem : {
		right : F64,
		forward : F64,
		height : F64,
		pose : Cat.Pose,
		lift : F64,
	}

	## At most this many cats are drawn in a frame.
	max_vis_cats : I64
	max_vis_cats = 8

	## The cats in view of a rider at `speed`, the nearest segment's first.
	in_view : Frame.Viewpoint, Speed -> List(CatPlan.CatItem)
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
	} -> List(CatPlan.CatItem)
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
	depth_keys : List(CatPlan.CatItem) -> List(DepthSort.DepthKey)
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
} -> List(CatPlan.CatItem)
cat_in_view = |
	view,
	{
		position,
		crossing,
		speed,
	},
| {
	gap = Frame.gap_to_segment(view.road, position)
	moment = Cat.moment_at(crossing, { gap: (gap + crossing.along), speed })
	seen = Frame.rider_point_ahead(
		view.road,
		{
			position: position,
			along: (crossing.along + moment.spot.along),
			across: (moment.spot.across + (Scenery.lane_width / 2.0)),
		},
	)
	if seen.forward <= Geom.near_plane {
		[]
	} else if ((crossing.height / seen.forward) * view.cam_focal) < SceneLimits.min_scenery_px {
		[]
	} else {
		[
			{
				right: seen.right,
				forward: seen.forward,
				height: crossing.height,
				pose: moment.pose,
				lift: moment.spot.lift,
			},
		]
	}
}
