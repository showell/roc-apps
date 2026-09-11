# RocBird -- a Roc on the fifth tree on the right of every segment.
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

	# The fifth tree on the right: trees are planted in pairs, left then right,
	# and across > 0 is the right side.
	fifth_right : List(Scenery.Tree), I64, I64 -> [Found(Scenery.Tree), NoTree]
	fifth_right = |trees, i, seen| match List.get(trees, I64.to_u64_wrap(i)) {
		Err(_) => NoTree
		Ok(t) => if t.across > 0.0 {
			if seen == 4 { Found(t) } else { fifth_right(trees, i + 1, seen + 1) }
		} else {
			fifth_right(trees, i + 1, seen)
		}
	}

	# The bird for chain position d, or nothing when its tree is behind the
	# near plane or too small to draw.
	perch : List(World.Segment), List(I64), Frame.Pose, F64, F64, I64 -> List(Paint.DrawCmd)
	perch = |segs, ch, pose, cf, view_w, d| {
		seg_idx = List.get(ch, I64.to_u64_wrap(d)) ?? crash("chain index")
		seg = List.get(segs, I64.to_u64_wrap(seg_idx)) ?? crash("segment")
		match fifth_right(seg.trees, 0, 0) {
			NoTree => []
			Found(t) => {
				rp = Frame.at(segs, ch, pose, d, t.along, t.across + seg.width / 2.0)
				if rp.forward <= Geom.near {
					[]
				} else {
					ht = (height / rp.forward) * cf
					if ht < SceneLimits.min_scenery_px {
						[]
					} else {
						top = Camera.project({ right: rp.right, forward: rp.forward, height: t.height }, cf, view_w)
						# Facing the road, which is to a right-side tree's left.
						Critter.critter_polys(top, Critter.facing(False), ht, polys, 0)
					}
				}
			}
		}
	}

	# Every bird in the chain, nearest segment first.
	draw_all : List(World.Segment), List(I64), Frame.Pose, F64, F64 -> List(Paint.DrawCmd)
	draw_all = |segs, ch, pose, cf, view_w| draw_from(segs, ch, pose, cf, view_w, 0, [])

	draw_from : List(World.Segment), List(I64), Frame.Pose, F64, F64, I64, List(Paint.DrawCmd) -> List(Paint.DrawCmd)
	draw_from = |segs, ch, pose, cf, view_w, d, acc|
		if d >= U64.to_i64_wrap(List.len(ch)) { acc } else {
			draw_from(segs, ch, pose, cf, view_w, d + 1, List.concat(acc, perch(segs, ch, pose, cf, view_w, d)))
		}
}
