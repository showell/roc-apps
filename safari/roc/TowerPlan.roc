# TowerPlan -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import DepthSort
import Frame
import Geom
import Tower
import World

TowerPlan :: [].{
	TowerItem : { map : Frame.Mapper, a0 : F64, x0 : F64, yaw : F64, fwd : F64, off : F64 }

	tower_beyond : F64
	tower_beyond = 160.0

	tower_right : F64
	tower_right = 20.0

	seg_tower_left : F64
	seg_tower_left = 100.0

	tower_yaw : F64
	tower_yaw = ((30.0 * 3.14159265) / 180.0)

	tower_if_ahead : List(World.Segment), List(I64), Frame.Pose, Frame.Mapper, F64, F64, F64, I64 -> List(TowerPlan.TowerItem)
	tower_if_ahead = |segs, ch, pose, m, a0, x0, yw, key| ({
		c = Frame.map_pt(segs, ch, pose, m, a0, x0)
		(if (c.forward <= Geom.near) { [] } else { [{ map: m, a0: a0, x0: x0, yaw: yw, fwd: c.forward, off: Tower.beacon_offset_for(key) }] })
	})

	seg_towers : List(World.Segment), List(I64), Frame.Pose, I64 -> List(TowerPlan.TowerItem)
	seg_towers = |segs, ch, pose, d| ({
		sg = (List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range")))) ?? crash("list-at out of range"))
		List.concat(tower_if_ahead(segs, ch, pose, Frame.chain_map(d), (sg.length + tower_beyond), ((sg.width / 2.0) + tower_right), tower_yaw, (List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range"))), seg_mid_tower(segs, ch, pose, d))
	})

	seg_mid_tower : List(World.Segment), List(I64), Frame.Pose, I64 -> List(TowerPlan.TowerItem)
	seg_mid_tower = |segs, ch, pose, d| ({
		sg = (List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range")))) ?? crash("list-at out of range"))
		(if sg.has_mid_tower { tower_if_ahead(segs, ch, pose, Frame.chain_map(d), (sg.length / 2.0), ((sg.width / 2.0) - seg_tower_left), 0.0, ((List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range")) + 60)) } else { [] })
	})

	# walk_towers builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	walk_towers : List(World.Segment), List(I64), Frame.Pose, I64 -> List(TowerPlan.TowerItem)
	walk_towers = |segs, ch, pose, d| walk_towers_acc(segs, ch, pose, d, [])

	walk_towers_acc : List(World.Segment), List(I64), Frame.Pose, I64, List(TowerPlan.TowerItem) -> List(TowerPlan.TowerItem)
	walk_towers_acc = |segs, ch, pose, d, acc| (if (d >= U64.to_i64_wrap(List.len(ch))) { acc } else { walk_towers_acc(segs, ch, pose, (d + 1), List.concat(acc, seg_towers(segs, ch, pose, d))) })

	behind_tower : List(World.Segment), List(I64), Frame.Pose, I64 -> List(TowerPlan.TowerItem)
	behind_tower = |segs, ch, pose, prev_idx| ({
		pv = (List.get(segs, I64.to_u64_wrap(prev_idx)) ?? crash("list-at out of range"))
		tower_if_ahead(segs, ch, pose, Frame.prev_map(pv), (pv.length + tower_beyond), ((pv.width / 2.0) + tower_right), tower_yaw, prev_idx)
	})

	all_towers : List(World.Segment), List(I64), Frame.Pose, I64 -> List(TowerPlan.TowerItem)
	all_towers = |segs, ch, pose, seg_idx| (if (seg_idx > 0) { List.concat(walk_towers(segs, ch, pose, 0), behind_tower(segs, ch, pose, (seg_idx - 1))) } else { walk_towers(segs, ch, pose, 0) })

	max_vis_towers : I64
	max_vis_towers = 16

	# tower_items builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	tower_items : List(TowerPlan.TowerItem), I64 -> List(DepthSort.Item)
	tower_items = |ts, i| tower_items_acc(ts, i, [])

	tower_items_acc : List(TowerPlan.TowerItem), I64, List(DepthSort.Item) -> List(DepthSort.Item)
	tower_items_acc = |ts, i, acc| (if (i >= U64.to_i64_wrap(List.len(ts))) { acc } else { tower_items_acc(ts, (i + 1), List.append(acc, { fwd: (List.get(ts, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).fwd, kind: KTower, i: i })) })
}
