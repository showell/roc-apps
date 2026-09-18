# CatPlan -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Cat
import DepthSort
import Frame
import Geom
import SceneLimits
import World

CatPlan :: [].{
	CatItem : { right : F64, fwd : F64, height : F64, pose_idx : I64, lift : F64 }

	chain_gap : List(World.Segment), List(I64), F64, I64 -> F64
	chain_gap = |w, ch, along, d| (if (d <= 0) { (0.0 - along) } else { (chain_gap(w, ch, along, (d - 1)) + (List.get(w, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap((d - 1))) ?? crash("list-at out of range")))) ?? crash("list-at out of range")).length) })

	cat_item : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64, World.Segment, F64 -> List(CatPlan.CatItem)
	cat_item = |w, ch, pose, d, cf, gap, sg, v| ({
		st = Cat.cat_state(sg.cat, (gap + sg.cat.along), v)
		rp = Frame.at(w, ch, pose, d, sg.cat.along, (st.across + (sg.width / 2.0)))
		(if (rp.forward <= Geom.near) { [] } else { (if (((sg.cat.height / rp.forward) * cf) < SceneLimits.min_scenery_px) { [] } else { [{ right: rp.right, fwd: rp.forward, height: sg.cat.height, pose_idx: st.pose_idx, lift: st.lift }] }) })
	})

	seg_cat : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64, F64 -> List(CatPlan.CatItem)
	seg_cat = |w, ch, pose, d, cf, along, v| ({
		sg = (List.get(w, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range")))) ?? crash("list-at out of range"))
		(if sg.has_cat { cat_item(w, ch, pose, d, cf, chain_gap(w, ch, along, d), sg, v) } else { [] })
	})

	# walk_cats builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	walk_cats : List(World.Segment), List(I64), Frame.Pose, F64, F64, F64, I64 -> List(CatPlan.CatItem)
	walk_cats = |w, ch, pose, cf, along, v, d| walk_cats_acc(w, ch, pose, cf, along, v, d, [])

	walk_cats_acc : List(World.Segment), List(I64), Frame.Pose, F64, F64, F64, I64, List(CatPlan.CatItem) -> List(CatPlan.CatItem)
	walk_cats_acc = |w, ch, pose, cf, along, v, d, acc| (if (d >= U64.to_i64_wrap(List.len(ch))) { acc } else { walk_cats_acc(w, ch, pose, cf, along, v, (d + 1), List.concat(acc, seg_cat(w, ch, pose, d, cf, along, v))) })

	max_vis_cats : I64
	max_vis_cats = 8

	# cat_items builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	cat_items : List(CatPlan.CatItem), I64 -> List(DepthSort.Item)
	cat_items = |cs, i| cat_items_acc(cs, i, [])

	cat_items_acc : List(CatPlan.CatItem), I64, List(DepthSort.Item) -> List(DepthSort.Item)
	cat_items_acc = |cs, i, acc| (if (i >= U64.to_i64_wrap(List.len(cs))) { acc } else { cat_items_acc(cs, (i + 1), List.append(acc, { fwd: (List.get(cs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).fwd, kind: KCat, i: i })) })
}
