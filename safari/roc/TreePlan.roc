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

	# seg_trees builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	seg_trees : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64, List(Scenery.Tree), I64 -> List(TreePlan.TreeItem)
	seg_trees = |segs, ch, pose, d, cf, hw, trs, i| seg_trees_acc(segs, ch, pose, d, cf, hw, trs, i, [])

	seg_trees_acc : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64, List(Scenery.Tree), I64, List(TreePlan.TreeItem) -> List(TreePlan.TreeItem)
	seg_trees_acc = |segs, ch, pose, d, cf, hw, trs, i, acc| (if (i >= U64.to_i64_wrap(List.len(trs))) { acc } else { seg_trees_acc(segs, ch, pose, d, cf, hw, trs, (i + 1), List.concat(acc, place_tree(segs, ch, pose, d, cf, hw, (List.get(trs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	# walk_trees builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	walk_trees : List(World.Segment), List(I64), Frame.Pose, F64, I64 -> List(TreePlan.TreeItem)
	walk_trees = |segs, ch, pose, cf, d| walk_trees_acc(segs, ch, pose, cf, d, [])

	walk_trees_acc : List(World.Segment), List(I64), Frame.Pose, F64, I64, List(TreePlan.TreeItem) -> List(TreePlan.TreeItem)
	walk_trees_acc = |segs, ch, pose, cf, d, acc| (if (d >= U64.to_i64_wrap(List.len(ch))) { acc } else { walk_trees_acc(segs, ch, pose, cf, (d + 1), List.concat(acc, seg_trees(segs, ch, pose, d, cf, ((List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range")))) ?? crash("list-at out of range")).width / 2.0), (List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range")))) ?? crash("list-at out of range")).trees, 0))) })

	max_vis_trees : I64
	max_vis_trees = 640

	# tree_items builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	tree_items : List(TreePlan.TreeItem), I64 -> List(DepthSort.Item)
	tree_items = |ts, i| tree_items_acc(ts, i, [])

	tree_items_acc : List(TreePlan.TreeItem), I64, List(DepthSort.Item) -> List(DepthSort.Item)
	tree_items_acc = |ts, i, acc| (if (i >= U64.to_i64_wrap(List.len(ts))) { acc } else { tree_items_acc(ts, (i + 1), List.append(acc, { fwd: (List.get(ts, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).fwd, kind: KTree, i: i })) })
}
