## CatPlan finds the cats the rider can see in a frame: each one waiting
## on a segment of the chain ahead, placed where its crossing has got to,
## if it is in front of the camera and tall enough on screen to draw.
import Cat
import DepthSort
import Frame
import Geom
import SceneLimits
import Scenery
import World

CatPlan :: [].{

	## A cat to draw: where it stands in the rider's view, its height, its
	## pose, and how high its leap has raised it.
	CatItem : {
		right : F64,
		fwd : F64,
		height : F64,
		pose : Cat.Pose,
		lift : F64,
	}

	## What the cats are seen from: the world's segments, the chain of them
	## ahead of the rider, the rider's pose, the camera's focal length, how
	## far along its segment the rider is, and the rider's speed.
	View : {
		world : List(World.Segment),
		chain : List(I64),
		pose : Frame.Pose,
		cam_focal : F64,
		rider_along : F64,
		speed : F64,
	}

	## At most this many cats are drawn in a frame.
	max_vis_cats : I64
	max_vis_cats = 8

	## The cats in view, the nearest segment's first.
	in_view : CatPlan.View -> List(CatPlan.CatItem)
	in_view = |view| {
		places = List.from_iter(U64.until(0, view.chain.len()))
		places.join_map(|place| segment_cat(view, U64.to_i64_wrap(place)))
	}

	## The cat waiting on the segment at `place` in the chain, if it has one
	## and it is in view.
	segment_cat : CatPlan.View, I64 -> List(CatPlan.CatItem)
	segment_cat = |view, place| {
		seg_index = view.chain.get(I64.to_u64_wrap(place)) ?? crash "CatPlan.segment_cat: no such place in the chain"
		segment = world_segment(view, seg_index)
		match segment.cat {
			Waits(crossing) => cat_in_view(view, { place, crossing })
			NoCat => []
		}
	}

	## How far ahead of the rider the segment at `place` in the chain starts.
	## The segments' lengths are added nearest first.
	gap_to_segment : CatPlan.View, I64 -> F64
	gap_to_segment = |view, place|
		view.chain.take_first(I64.to_u64_wrap(place)).fold(
			(0.0 - view.rider_along),
			|gap, seg_index| (gap + world_segment(view, seg_index).length),
		)

	## The cats as the depth sort sees them: each one's distance ahead, and
	## its place in `cats`.
	depth_keys : List(CatPlan.CatItem) -> List(DepthSort.DepthKey)
	depth_keys = |cats| cats.map_with_index(|cat, i| { forward: cat.fwd, subject: Cat(i) })
}

## The cat crossing the segment at `place` in the chain, as far through its
## crossing as the rider's approach has brought it, if it is in view: one
## item, or none.
cat_in_view : CatPlan.View, { place : I64, crossing : Cat.Crossing } -> List(CatPlan.CatItem)
cat_in_view = |view, { place, crossing }| {
	gap = CatPlan.gap_to_segment(view, place)
	state = Cat.state(crossing, { gap: (gap + crossing.along), speed: view.speed })
	seen = Frame.at(
		{
			world: view.world,
			chain: view.chain,
			pose: view.pose,
		},
		{
			segments_ahead: place,
			along: crossing.along,
			across: (state.across + (Scenery.lane_width / 2.0)),
		},
	)
	if seen.forward <= Geom.near {
		[]
	} else if ((crossing.height / seen.forward) * view.cam_focal) < SceneLimits.min_scenery_px {
		[]
	} else {
		[
			{
				right: seen.right,
				fwd: seen.forward,
				height: crossing.height,
				pose: state.pose,
				lift: state.lift,
			},
		]
	}
}

world_segment : CatPlan.View, I64 -> World.Segment
world_segment = |
	view,
	seg_index,
| view.world.get(I64.to_u64_wrap(seg_index)) ?? crash "CatPlan: no such segment"
