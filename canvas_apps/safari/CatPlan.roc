# CatPlan -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Cat
import DepthSort
import Frame
import Geom
import SceneLimits
import Scenery
import World

CatPlan :: [].{
	CatItem : { right : F64, fwd : F64, height : F64, pose_idx : I64, lift : F64 }

	chain_gap : List(World.Segment), List(I64), F64, I64 -> F64
	chain_gap = |w, ch, along, d| (
		if (d <= 0) {
			(0.0 - along)
		} else {
			(chain_gap(w, ch, along, (d - 1)) + (List.get(w, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap((d - 1))) ?? crash ("list-at out of range")))) ?? crash ("list-at out of range")).length)
		}
	)

	cat_item : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64, Cat.Crossing, F64 -> List(CatPlan.CatItem)
	cat_item = |w, ch, pose, d, cf, gap, crossing, v| (
		{
			st = Cat.state(crossing, { gap: (gap + crossing.along), speed: v })
			rp = Frame.at(w, ch, pose, d, crossing.along, (st.across + (Scenery.lane_width / 2.0)))
			(
				if (rp.forward <= Geom.near) {
					[]
				} else {
					(
						if (((crossing.height / rp.forward) * cf) < SceneLimits.min_scenery_px) {
							[]
						} else {
							[{ right: rp.right, fwd: rp.forward, height: crossing.height, pose_idx: Cat.pose_index(st.pose), lift: st.lift }]
						}
					)
				}
			)
		}
	)

	seg_cat : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64, F64 -> List(CatPlan.CatItem)
	seg_cat = |w, ch, pose, d, cf, along, v| (
		{
			sg = (List.get(w, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash ("list-at out of range")))) ?? crash ("list-at out of range"))
			match sg.cat {
				Waits(crossing) => cat_item(w, ch, pose, d, cf, chain_gap(w, ch, along, d), crossing, v)
				NoCat => []
			}
		}
	)

	# walk_cats builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	walk_cats : List(World.Segment), List(I64), Frame.Pose, F64, F64, F64, I64 -> List(CatPlan.CatItem)
	walk_cats = |w, ch, pose, cf, along, v, d| walk_cats_onto(w, ch, pose, cf, along, v, d, [])

	walk_cats_onto : List(World.Segment), List(I64), Frame.Pose, F64, F64, F64, I64, List(CatPlan.CatItem) -> List(CatPlan.CatItem)
	walk_cats_onto = |w, ch, pose, cf, along, v, d, acc| (
		if (d >= ch.len().to_i64_wrap()) {
			acc
		} else {
			walk_cats_onto(w, ch, pose, cf, along, v, (d + 1), List.concat(acc, seg_cat(w, ch, pose, d, cf, along, v)))
		}
	)

	max_vis_cats : I64
	max_vis_cats = 8

	# cat_items builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	cat_items : List(CatPlan.CatItem) -> List(DepthSort.DepthKey)
	cat_items = |cs| cat_items_onto(cs, 0, [])

	cat_items_onto : List(CatPlan.CatItem), I64, List(DepthSort.DepthKey) -> List(DepthSort.DepthKey)
	cat_items_onto = |cs, i, acc| (
		if (i >= cs.len().to_i64_wrap()) {
			acc
		} else {
			cat_items_onto(cs, (i + 1), List.append(acc, { fwd: (List.get(cs, I64.to_u64_wrap(i)) ?? crash ("list-at out of range")).fwd, kind: KCat, i: i }))
		}
	)
}
