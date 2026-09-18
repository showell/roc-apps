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
# on the screen, and Critter.critter_polys maps the polygons onto that anchor
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
		{ color: 6368222, grad: [], pts: [{ x: -0.0344, y: 0.5715 }, { x: -0.148, y: 0.0 }, { x: 0.0368, y: 0.1469 }, { x: 0.0183, y: 0.2577 }] },
		{ color: 8542181, grad: [], pts: [{ x: 0.2216, y: 0.6413 }, { x: 0.3497, y: 0.5025 }, { x: 0.3679, y: 0.5849 }, { x: 0.3862, y: 0.6862 }] },
		{ color: 8542181, grad: [], pts: [{ x: -0.0305, y: 0.9394 }, { x: -0.4811, y: 1.0 }, { x: -0.0344, y: 0.5715 }] },
		{ color: 8542181, grad: [], pts: [{ x: 0.3497, y: 0.5025 }, { x: -0.0344, y: 0.5715 }, { x: 0.0183, y: 0.2577 }] },
		{ color: 6368222, grad: [], pts: [{ x: 0.4717, y: 0.5849 }, { x: 0.3862, y: 0.6862 }, { x: 0.3679, y: 0.5849 }] },
		{ color: 6368222, grad: [], pts: [{ x: -0.0344, y: 0.5715 }, { x: 0.3497, y: 0.5025 }, { x: 0.2216, y: 0.6413 }, { x: -0.0305, y: 0.9394 }] }
	]

	# A bird stands this tall, in metres, on its treetop.
	height : F64
	height = 2.2

	# The fifth tree on the LEFT: trees are planted in pairs, left then right,
	# and across < 0 is the left side.
	#
	# **IT USED TO BE THE RIGHT, AND THE BIRD LOOKED AWAY FROM THE ROAD.** The
	# still's beak points toward +x and `facing(False)` leaves it that way, so
	# it faces screen-right; on a right-hand tree that is out into the trees.
	# From a left-hand one, the same unflipped bird faces the road.
	fifth_left : List(Scenery.Tree), I64, I64 -> [Found(Scenery.Tree), NoTree]
	fifth_left = |trees, i, seen| match List.get(trees, I64.to_u64_wrap(i)) {
		Err(_) => NoTree
		Ok(t) => if t.across < 0.0 {
			if seen == 4 { Found(t) } else { fifth_left(trees, i + 1, seen + 1) }
		} else {
			fifth_left(trees, i + 1, seen)
		}
	}

	# One bird, placed: where it is and how far up its tree its feet go. The
	# same shape every other collected item has -- where, not what.
	Bird : { right : F64, fwd : F64, lift : F64 }

	# The bird for chain position d, or nothing when its tree is behind the
	# near plane or too small to draw. Culled here, as every kind is culled
	# where it is collected rather than where it is drawn.
	perch : List(World.Segment), List(I64), Frame.Pose, F64, I64 -> List(RocBird.Bird)
	perch = |segs, ch, pose, cf, d| {
		seg_idx = List.get(ch, I64.to_u64_wrap(d)) ?? crash("chain index")
		seg = List.get(segs, I64.to_u64_wrap(seg_idx)) ?? crash("segment")
		match fifth_left(seg.trees, 0, 0) {
			NoTree => []
			Found(t) => {
				rp = Frame.at(segs, ch, pose, d, t.along, t.across + seg.width / 2.0)
				if rp.forward <= Geom.near {
					[]
				} else if (height / rp.forward) * cf < SceneLimits.min_scenery_px {
					[]
				} else {
					[{ right: rp.right, fwd: rp.forward, lift: t.height }]
				}
			}
		}
	}

	# Every bird in the chain, nearest segment first. The sort puts them where
	# they belong.
	perches : List(World.Segment), List(I64), Frame.Pose, F64 -> List(RocBird.Bird)
	perches = |segs, ch, pose, cf| perches_from(segs, ch, pose, cf, 0, [])

	perches_from : List(World.Segment), List(I64), Frame.Pose, F64, I64, List(RocBird.Bird) -> List(RocBird.Bird)
	perches_from = |segs, ch, pose, cf, d, acc|
		if d >= U64.to_i64_wrap(List.len(ch)) { acc } else {
			perches_from(segs, ch, pose, cf, d + 1, List.concat(acc, perch(segs, ch, pose, cf, d)))
		}

	# **THE DEPTH IS THE TREE'S**, which is the whole point of collecting them:
	# how high the bird sits does not change how far away it is.
	bird_items : List(RocBird.Bird), I64 -> List(DepthSort.Item)
	bird_items = |bs, i|
		if i >= U64.to_i64_wrap(List.len(bs)) { [] } else {
			List.concat(
				[{ fwd: (List.get(bs, I64.to_u64_wrap(i)) ?? crash("bird out of range")).fwd, kind: KBird, i: i }],
				bird_items(bs, i + 1),
			)
		}

	# One bird, drawn where the sort says. Its feet go at the top of its tree,
	# and unflipped its beak points toward +x, which from a left-hand tree is
	# across the road.
	draw_one : RocBird.Bird, F64, F64 -> List(Paint.DrawCmd)
	draw_one = |b, cf, view_w| {
		feet = Camera.project({ right: b.right, forward: b.fwd, height: b.lift }, cf, view_w)
		Critter.critter_polys(feet, Critter.facing(False), (height / b.fwd) * cf, polys, 0)
	}
}
