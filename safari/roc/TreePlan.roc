# TreePlan -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import DepthSort
import Frame
import Geom
import SceneLimits
import Scenery
import World

TreePlan :: [].{
	TreeItem : { right : F64, fwd : F64, height : F64, color : I64 }

	place_tree : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64, Scenery.Tree -> List(TreePlan.TreeItem)
	place_tree = |segs, ch, pose, d, cf, hw, tr| ({
		rp = Frame.at(segs, ch, pose, d, tr.along, (tr.across + hw))
		(if (rp.forward <= Geom.near) { [] } else { (if (((tr.height / rp.forward) * cf) < SceneLimits.min_scenery_px) { [] } else { [{ right: rp.right, fwd: rp.forward, height: tr.height, color: tr.color }] }) })
	})

	seg_trees : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64, List(Scenery.Tree), I64 -> List(TreePlan.TreeItem)
	seg_trees = |segs, ch, pose, d, cf, hw, trs, i| (if (i >= U64.to_i64_wrap(List.len(trs))) { [] } else { List.concat(place_tree(segs, ch, pose, d, cf, hw, (List.get(trs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), seg_trees(segs, ch, pose, d, cf, hw, trs, (i + 1))) })

	walk_trees : List(World.Segment), List(I64), Frame.Pose, F64, I64 -> List(TreePlan.TreeItem)
	walk_trees = |segs, ch, pose, cf, d| (if (d >= U64.to_i64_wrap(List.len(ch))) { [] } else { List.concat(seg_trees(segs, ch, pose, d, cf, ((List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range")))) ?? crash("list-at out of range")).width / 2.0), (List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range")))) ?? crash("list-at out of range")).trees, 0), walk_trees(segs, ch, pose, cf, (d + 1))) })

	max_vis_trees : I64
	max_vis_trees = 640

	tree_items : List(TreePlan.TreeItem), I64 -> List(DepthSort.Item)
	tree_items = |ts, i| (if (i >= U64.to_i64_wrap(List.len(ts))) { [] } else { List.concat([{ fwd: (List.get(ts, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).fwd, kind: KTree, i: i }], tree_items(ts, (i + 1))) })
}
