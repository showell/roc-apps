# RocBird -- a Roc on the fifth tree on the LEFT of every segment.
#
# **IT IS AN ITEM IN THE DEPTH SORT, like a tree or a cow.** It used to be
# drawn after the whole frame, on the reasoning that "a bird on a treetop is
# rarely behind anything" -- and rarely is not never: a nearer, taller tree
# would be painted first and the bird would float in front of it. Its depth is
# its tree's `forward`, which is exact rather than a cheat, because how high a
# thing sits does not change how far away it is.
#
# Hand-written Roc, the first flair the Roc version of safari has and the
# Codex version does not. The bird is roc-lang.org's logo, six purple
# polygons, carried in the same unit frame as the baked stills (feet at y 0,
# y up, height 1) and drawn through the same still machinery a critter uses:
# Frame.at places the tree in the rider's frame, Camera.project puts its top
# on the screen, and Critter.draw_still maps the polygons onto that anchor
# at the tree's depth. The app appends the birds after the frame, so they
# paint on top of everything; a bird on a treetop is rarely behind anything.
import Stills
import DepthSort
import Scenery
import World
import Frame
import Geom
import Camera
import Critter
import Paint
import SceneLimits

RocBird :: [].{
	# The logo as a still, beak toward +x. Colours are the site's logo-dark
	# and logo-light.
	polys : List(Stills.StillPoly)
	polys = [
		{
			color: 6368222,
			grad: [],
			pts: [
				{ x: -0.0344, y: 0.5715 },
				{ x: -0.148, y: 0.0 },
				{ x: 0.0368, y: 0.1469 },
				{ x: 0.0183, y: 0.2577 },
			],
		},
		{
			color: 8542181,
			grad: [],
			pts: [
				{ x: 0.2216, y: 0.6413 },
				{ x: 0.3497, y: 0.5025 },
				{ x: 0.3679, y: 0.5849 },
				{ x: 0.3862, y: 0.6862 },
			],
		},
		{
			color: 8542181,
			grad: [],
			pts: [
				{ x: -0.0305, y: 0.9394 },
				{ x: -0.4811, y: 1.0 },
				{ x: -0.0344, y: 0.5715 },
			],
		},
		{
			color: 8542181,
			grad: [],
			pts: [
				{ x: 0.3497, y: 0.5025 },
				{ x: -0.0344, y: 0.5715 },
				{ x: 0.0183, y: 0.2577 },
			],
		},
		{
			color: 6368222,
			grad: [],
			pts: [
				{ x: 0.4717, y: 0.5849 },
				{ x: 0.3862, y: 0.6862 },
				{ x: 0.3679, y: 0.5849 },
			],
		},
		{
			color: 6368222,
			grad: [],
			pts: [
				{ x: -0.0344, y: 0.5715 },
				{ x: 0.3497, y: 0.5025 },
				{ x: 0.2216, y: 0.6413 },
				{ x: -0.0305, y: 0.9394 },
			],
		},
	]

	# A bird stands this tall, in metres, on its treetop.
	height : F64
	height = 2.2

	# The fifth tree on the LEFT: trees are planted in pairs, left then right,
	# and across < 0 is the left side.
	#
	# **IT USED TO BE THE RIGHT, AND THE BIRD LOOKED AWAY FROM THE ROAD.** The
	# still's beak points toward +x and `AsDrawn` leaves it that way, so
	# it faces screen-right; on a right-hand tree that is out into the trees.
	# From a left-hand one, the same unflipped bird faces the road.
	fifth_left : List(Scenery.Tree),
	{
		tree_index : I64,
		left_trees_seen : I64,
	} -> [Found(Scenery.Tree), NoTree]
	fifth_left = |
		trees,
		{ tree_index: i, left_trees_seen: seen },
	| match List.get(trees, I64.to_u64_wrap(i)) {
		Err(_) => NoTree
		Ok(t) => if t.across < 0.0 {
			if seen == 4 {
				Found(t)
			} else {
				fifth_left(trees, { tree_index: i + 1, left_trees_seen: seen + 1 })
			}
		} else {
			fifth_left(trees, { tree_index: i + 1, left_trees_seen: seen })
		}
	}

	# One bird, placed: where it is and how far up its tree its feet go. The
	# same shape every other collected item has -- where, not what.
	Bird : {
		right : F64,
		forward : F64,
		lift : F64,
	}

	## The road the birds are collected along: the world's segments, the
	## chain of them ahead of the rider, the rider's pose, and the lens's
	## focal length in pixels.
	View : {
		world : List(World.Segment),
		chain : List(World.SegmentIndex),
		pose : Frame.Pose,
		cam_focal : F64,
	}

	# The bird for `position` in the chain, or nothing when its tree is behind the
	# near plane or too small to draw. Culled here, as every kind is culled
	# where it is collected rather than where it is drawn.
	perch : RocBird.View, Frame.ChainPosition -> List(RocBird.Bird)
	perch = |
		{
			world: segs,
			chain: ch,
			pose,
			cam_focal: cf,
		},
		position,
	| {
		seg = position.index_in(ch).segment_in(segs)
		match fifth_left(seg.trees, { tree_index: 0, left_trees_seen: 0 }) {
			NoTree => []
			Found(t) => {
				rp = Frame.rider_point_ahead(
					{
						world: segs,
						chain: ch,
						pose: pose,
					},
					{
						position,
						along: t.along,
						across: t.across + Scenery.lane_width / 2.0,
					},
				)
				if rp.forward <= Geom.near_plane {
					[]
				} else if (height / rp.forward) * cf < SceneLimits.min_scenery_px {
					[]
				} else {
					[
						{
							right: rp.right,
							forward: rp.forward,
							lift: t.height,
						},
					]
				}
			}
		}
	}

	# Every bird in the chain, nearest segment first. The sort puts them where
	# they belong.
	perches : RocBird.View -> List(RocBird.Bird)
	perches = |view| Frame.ChainPosition.all_in(view.chain).join_map(|position| perch(view, position))

	# **THE DEPTH IS THE TREE'S**, which is the whole point of collecting them:
	# how high the bird sits does not change how far away it is.
	bird_items : List(RocBird.Bird) -> List(DepthSort.DepthKey)
	bird_items = |bs| bs.map_with_index(|bird, i| { forward: bird.forward, subject: Bird(i.to_u32_wrap()) })

	# One bird, drawn where the sort says. Its feet go at the top of its tree,
	# and unflipped its beak points toward +x, which from a left-hand tree is
	# across the road.
	draw_one : RocBird.Bird, Camera.View -> List(Paint.DrawCmd)
	draw_one = |b, camera_view| {
		cf = camera_view.cam_focal
		feet = Camera.project(
			{
				right: b.right,
				forward: b.forward,
				height: b.lift,
			},
			camera_view,
		)
		Critter.draw_still(
			{
				feet,
				flip: AsDrawn,
				height_px: (height / b.forward) * cf,
			},
			polys,
		)
	}
}
