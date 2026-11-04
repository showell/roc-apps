# Render -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Billboards
import CatPlan
import CritterPlan
import DepthSort
import Frame
import GuardRail
import RailPlan
import TowerPlan
import TreePlan
import TruckPlan
import RocBird
import World

Render :: [].{
	Collected : { trees : List(TreePlan.TreeItem), towers : List(TowerPlan.TowerItem), cows : List(Billboards.Billboard), cats : List(CatPlan.CatItem), rails : List(GuardRail.RailPoly), truck : TruckPlan.TruckAt, order : List(DepthSort.DepthKey), cull_seg : I64, cull_size : I64, birds : List(RocBird.Bird) }

	seg_cull_count : List(World.Segment), List(I64), I64 -> I64
	seg_cull_count = |segs, ch, d| (
		{
			sg = (List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash ("list-at out of range")))) ?? crash ("list-at out of range"))
			(
				if (d >= CritterPlan.farm_reach) {
					(sg.cows.len().to_i64_wrap() + sg.pigs.len().to_i64_wrap())
				} else {
					0
				}
			)
		}
	)

	walk_seg_cull : List(World.Segment), List(I64), I64 -> I64
	walk_seg_cull = |segs, ch, d| (
		if (d >= ch.len().to_i64_wrap()) {
			0
		} else {
			(seg_cull_count(segs, ch, d) + walk_seg_cull(segs, ch, (d + 1)))
		}
	)

	prev_index : I64 -> I64
	prev_index = |seg_idx| (
		if (seg_idx > 0) {
			(seg_idx - 1)
		} else {
			0
		}
	)

	collect : List(World.Segment), I64, Frame.Pose, F64, F64, F64, F64 -> Render.Collected
	collect = |segs, seg_idx, pose, cf, along, v, truck_pos| (
		{
			ch = Frame.build_chain(segs, seg_idx)
			placed = CritterPlan.sightings({ world: segs, chain: ch, pose }, seg_idx)
			trees = TreePlan.in_view({ world: segs, chain: ch, pose, cam_focal: cf }).take_first(TreePlan.max_vis_trees.to_u64_wrap())
			towers = TowerPlan.in_view({ world: segs, chain: ch, pose, rider_segment: seg_idx }).take_first(TowerPlan.max_vis_towers.to_u64_wrap())
			cows = Billboards.billboards_in_view(placed).take_first(CritterPlan.max_vis_critters.to_u64_wrap())
			cats = CatPlan.in_view({ world: segs, chain: ch, pose, cam_focal: cf, rider_along: along, speed: v }).take_first(CatPlan.max_vis_cats.to_u64_wrap())
			rails = RailPlan.all_rails({ world: segs, chain: ch, pose }, seg_idx)
			tk = TruckPlan.in_view({ world: segs, chain: ch, pose, rider_along: along, lead: (truck_pos - World.route_distance(segs, { index: seg_idx, along })) })
			# Roc's own flair, collected like every other kind so the sort can put
			# it behind a nearer tree. See RocBird.
			birds = RocBird.perches(segs, ch, pose, cf)
			{ trees: trees, towers: towers, cows: cows, cats: cats, rails: rails, truck: tk, birds: birds, order: DepthSort.sort_by(List.join([RocBird.bird_items(birds), TreePlan.depth_keys(trees), TowerPlan.depth_keys(towers), CritterPlan.cow_items(cows), CatPlan.depth_keys(cats), TruckPlan.depth_keys(tk), RailPlan.rail_items(rails)]), |key| key.fwd), cull_seg: walk_seg_cull(segs, ch, 0), cull_size: Billboards.too_small_count(placed) }
		}
	)
}
