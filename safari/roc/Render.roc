# Render -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Billboards
import CatPlan
import CritterPlan
import DepthSort
import Frame
import GuardRail
import ListUtils
import RailPlan
import TowerPlan
import TreePlan
import TruckPlan
import World

Render :: [].{
	Collected : { trees : List(TreePlan.TreeItem), towers : List(TowerPlan.TowerItem), cows : List(Billboards.Billboard), cats : List(CatPlan.CatItem), rails : List(GuardRail.RailPoly), truck : TruckPlan.TruckAt, order : List(DepthSort.Item), cull_seg : I64, cull_size : I64 }

	seg_cull_count : List(World.Segment), List(I64), I64 -> I64
	seg_cull_count = |segs, ch, d| ({
		sg = (List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range")))) ?? crash("list-at out of range"))
		(if (d >= CritterPlan.farm_seg_reach) { (U64.to_i64_wrap(List.len(sg.cows)) + U64.to_i64_wrap(List.len(sg.pigs))) } else { 0 })
	})

	walk_seg_cull : List(World.Segment), List(I64), I64 -> I64
	walk_seg_cull = |segs, ch, d| (if (d >= U64.to_i64_wrap(List.len(ch))) { 0 } else { (seg_cull_count(segs, ch, d) + walk_seg_cull(segs, ch, (d + 1))) })

	prev_index : I64 -> I64
	prev_index = |seg_idx| (if (seg_idx > 0) { (seg_idx - 1) } else { 0 })

	collect : List(World.Segment), I64, Frame.Pose, F64, F64, F64, F64 -> Render.Collected
	collect = |segs, seg_idx, pose, cf, along, v, truck_pos| ({
		ch = Frame.build_chain(segs, seg_idx)
		placed = CritterPlan.all_placed(segs, ch, pose, seg_idx)
		trees = ListUtils.list_take(TreePlan.walk_trees(segs, ch, pose, cf, 0), TreePlan.max_vis_trees)
		towers = ListUtils.list_take(TowerPlan.all_towers(segs, ch, pose, seg_idx), TowerPlan.max_vis_towers)
		cows = ListUtils.list_take(Billboards.kept_of(placed, 0), CritterPlan.max_vis_critters)
		cats = ListUtils.list_take(CatPlan.walk_cats(segs, ch, pose, cf, along, v, 0), CatPlan.max_vis_cats)
		rails = RailPlan.all_rails(segs, ch, pose, seg_idx)
		tk = TruckPlan.truck_at(segs, ch, pose, along, (truck_pos - World.route_distance(segs, seg_idx, along)))
		{ trees: trees, towers: towers, cows: cows, cats: cats, rails: rails, truck: tk, order: DepthSort.sort_items(List.concat(List.concat(List.concat(List.concat(List.concat(TreePlan.tree_items(trees, 0), TowerPlan.tower_items(towers, 0)), CritterPlan.cow_items(cows, 0)), CatPlan.cat_items(cats, 0)), TruckPlan.truck_items(tk)), RailPlan.rail_items(rails, 0))), cull_seg: walk_seg_cull(segs, ch, 0), cull_size: Billboards.size_culled_of(placed, 0) }
	})
}
