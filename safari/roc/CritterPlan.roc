# CritterPlan -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Billboards
import DepthSort
import Frame
import Pond
import SafariCritter
import Scenery
import World

CritterPlan :: [].{

	place_critter : List(World.Segment), List(I64), Frame.Pose, I64, F64, Scenery.Critter -> Billboards.Placed
	place_critter = |segs, ch, pose, d, hw, cr| ({
		rp = Frame.at(segs, ch, pose, d, cr.along, (cr.across + hw))
		Billboards.verdict(rp, cr.height, cr.codepoint, cr.face_right)
	})

	place_critter_via : List(World.Segment), List(I64), Frame.Pose, Frame.Mapper, F64, Scenery.Critter -> Billboards.Placed
	place_critter_via = |segs, ch, pose, m, hw, cr| ({
		rp = Frame.map_pt(segs, ch, pose, m, cr.along, (cr.across + hw))
		Billboards.verdict(rp, cr.height, cr.codepoint, cr.face_right)
	})

	place_duck : List(World.Segment), List(I64), Frame.Pose, Frame.Mapper, F64, Pond.Duck -> Billboards.Placed
	place_duck = |segs, ch, pose, m, from_len, dk| ({
		rp = Frame.map_pt(segs, ch, pose, m, (from_len + dk.p.cv), dk.p.cu)
		Billboards.verdict(rp, Pond.duck_height, Pond.duck_codepoint, dk.face_right)
	})

	# place_all builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	place_all : List(World.Segment), List(I64), Frame.Pose, I64, F64, List(Scenery.Critter), I64 -> List(Billboards.Placed)
	place_all = |segs, ch, pose, d, hw, crs, i| place_all_acc(segs, ch, pose, d, hw, crs, i, [])

	place_all_acc : List(World.Segment), List(I64), Frame.Pose, I64, F64, List(Scenery.Critter), I64, List(Billboards.Placed) -> List(Billboards.Placed)
	place_all_acc = |segs, ch, pose, d, hw, crs, i, acc| (if (i >= U64.to_i64_wrap(List.len(crs))) { acc } else { place_all_acc(segs, ch, pose, d, hw, crs, (i + 1), List.append(acc, place_critter(segs, ch, pose, d, hw, (List.get(crs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	# place_all_via builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	place_all_via : List(World.Segment), List(I64), Frame.Pose, Frame.Mapper, F64, List(Scenery.Critter), I64 -> List(Billboards.Placed)
	place_all_via = |segs, ch, pose, m, hw, crs, i| place_all_via_acc(segs, ch, pose, m, hw, crs, i, [])

	place_all_via_acc : List(World.Segment), List(I64), Frame.Pose, Frame.Mapper, F64, List(Scenery.Critter), I64, List(Billboards.Placed) -> List(Billboards.Placed)
	place_all_via_acc = |segs, ch, pose, m, hw, crs, i, acc| (if (i >= U64.to_i64_wrap(List.len(crs))) { acc } else { place_all_via_acc(segs, ch, pose, m, hw, crs, (i + 1), List.append(acc, place_critter_via(segs, ch, pose, m, hw, (List.get(crs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	# place_ducks builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	place_ducks : List(World.Segment), List(I64), Frame.Pose, Frame.Mapper, F64, I64 -> List(Billboards.Placed)
	place_ducks = |segs, ch, pose, m, from_len, i| place_ducks_acc(segs, ch, pose, m, from_len, i, [])

	place_ducks_acc : List(World.Segment), List(I64), Frame.Pose, Frame.Mapper, F64, I64, List(Billboards.Placed) -> List(Billboards.Placed)
	place_ducks_acc = |segs, ch, pose, m, from_len, i, acc| (if (i >= U64.to_i64_wrap(List.len(Pond.ducks))) { acc } else { place_ducks_acc(segs, ch, pose, m, from_len, (i + 1), List.append(acc, place_duck(segs, ch, pose, m, from_len, (List.get(Pond.ducks, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	farm_seg_reach : I64
	farm_seg_reach = 3

	safari_seg_reach : I64
	safari_seg_reach = 5

	seg_farm : List(World.Segment), List(I64), Frame.Pose, I64, F64 -> List(Billboards.Placed)
	seg_farm = |segs, ch, pose, d, hw| ({
		sg = (List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range")))) ?? crash("list-at out of range"))
		(if (d >= farm_seg_reach) { [] } else { List.concat(place_all(segs, ch, pose, d, hw, sg.cows, 0), place_all(segs, ch, pose, d, hw, sg.pigs, 0)) })
	})

	seg_safari : List(World.Segment), List(I64), Frame.Pose, I64, F64 -> List(Billboards.Placed)
	seg_safari = |segs, ch, pose, d, hw| ({
		sg = (List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range")))) ?? crash("list-at out of range"))
		(if sg.terminates { [] } else { (if (d >= safari_seg_reach) { [] } else { place_all(segs, ch, pose, d, hw, SafariCritter.corner_critters(sg.exit_creature, sg.length, sg.exit_right, hw), 0) }) })
	})

	seg_ducks : List(World.Segment), List(I64), Frame.Pose, I64 -> List(Billboards.Placed)
	seg_ducks = |segs, ch, pose, d| ({
		sg = (List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range")))) ?? crash("list-at out of range"))
		(if (d >= safari_seg_reach) { [] } else { (if Scenery.is_pond(sg.exit_creature) { place_ducks(segs, ch, pose, Frame.chain_map(d), sg.length, 0) } else { [] }) })
	})

	seg_billboards : List(World.Segment), List(I64), Frame.Pose, I64 -> List(Billboards.Placed)
	seg_billboards = |segs, ch, pose, d| ({
		hw = ((List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range")))) ?? crash("list-at out of range")).width / 2.0)
		List.concat(List.concat(seg_farm(segs, ch, pose, d, hw), seg_safari(segs, ch, pose, d, hw)), seg_ducks(segs, ch, pose, d))
	})

	# walk_billboards builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	walk_billboards : List(World.Segment), List(I64), Frame.Pose, I64 -> List(Billboards.Placed)
	walk_billboards = |segs, ch, pose, d| walk_billboards_acc(segs, ch, pose, d, [])

	walk_billboards_acc : List(World.Segment), List(I64), Frame.Pose, I64, List(Billboards.Placed) -> List(Billboards.Placed)
	walk_billboards_acc = |segs, ch, pose, d, acc| (if (d >= U64.to_i64_wrap(List.len(ch))) { acc } else { walk_billboards_acc(segs, ch, pose, (d + 1), List.concat(acc, seg_billboards(segs, ch, pose, d))) })

	behind_billboards : List(World.Segment), List(I64), Frame.Pose, I64 -> List(Billboards.Placed)
	behind_billboards = |segs, ch, pose, prev_idx| ({
		pv = (List.get(segs, I64.to_u64_wrap(prev_idx)) ?? crash("list-at out of range"))
		List.concat(place_all_via(segs, ch, pose, Frame.prev_map(pv), (pv.width / 2.0), SafariCritter.corner_critters(pv.exit_creature, pv.length, pv.exit_right, (pv.width / 2.0)), 0), behind_ducks(segs, ch, pose, pv))
	})

	behind_ducks : List(World.Segment), List(I64), Frame.Pose, World.Segment -> List(Billboards.Placed)
	behind_ducks = |segs, ch, pose, pv| (if Scenery.is_pond(pv.exit_creature) { place_ducks(segs, ch, pose, Frame.prev_map(pv), pv.length, 0) } else { [] })

	all_placed : List(World.Segment), List(I64), Frame.Pose, I64 -> List(Billboards.Placed)
	all_placed = |segs, ch, pose, seg_idx| (if (seg_idx > 0) { List.concat(walk_billboards(segs, ch, pose, 0), behind_billboards(segs, ch, pose, (seg_idx - 1))) } else { walk_billboards(segs, ch, pose, 0) })

	max_vis_critters : I64
	max_vis_critters = 320

	# cow_items builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	cow_items : List(Billboards.Billboard), I64 -> List(DepthSort.Item)
	cow_items = |bs, i| cow_items_acc(bs, i, [])

	cow_items_acc : List(Billboards.Billboard), I64, List(DepthSort.Item) -> List(DepthSort.Item)
	cow_items_acc = |bs, i, acc| (if (i >= U64.to_i64_wrap(List.len(bs))) { acc } else { cow_items_acc(bs, (i + 1), List.append(acc, { fwd: (List.get(bs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).fwd, kind: KCow, i: i })) })
}
