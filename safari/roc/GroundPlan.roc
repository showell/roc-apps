# GroundPlan -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Frame
import Geom
import Ground
import Joint
import Num
import Paint
import Pond
import Scenery
import World

GroundPlan :: [].{

	road_color : I64
	road_color = 3421500

	road_chunk : F64
	road_chunk = 25.0

	entry_road_dist : F64
	entry_road_dist = 40.0

	emit_ground : List(Geom.RiderPt), F64, F64 -> List(Paint.DrawCmd)
	emit_ground = |ps, cf, view_w| Ground.emit_ground_color(ps, road_color, cf, view_w)

	chunks_for : F64 -> I64
	chunks_for = |len| ({
		c = Num.ceil_real((len / road_chunk))
		F64.to_i64_wrap((if (c < 1.0) { 1.0 } else { c }))
	})

	road_slice : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64, I64, I64, F64, F64 -> List(Paint.DrawCmd)
	road_slice = |segs, ch, pose, d, cf, view_w, ci, n, len, wd| (if (ci >= n) { [] } else { List.concat(emit_ground(slice_quad(segs, ch, pose, d, ci, n, len, wd), cf, view_w), road_slice(segs, ch, pose, d, cf, view_w, (ci + 1), n, len, wd)) })

	slice_quad : List(World.Segment), List(I64), Frame.Pose, I64, I64, I64, F64, F64 -> List(Geom.RiderPt)
	slice_quad = |segs, ch, pose, d, ci, n, len, wd| ({
		a0 = ((len * I64.to_f64(ci)) / I64.to_f64(n))
		a1 = ((len * I64.to_f64((ci + 1))) / I64.to_f64(n))
		[Frame.at(segs, ch, pose, d, a0, 0.0), Frame.at(segs, ch, pose, d, a0, wd), Frame.at(segs, ch, pose, d, a1, wd), Frame.at(segs, ch, pose, d, a1, 0.0)]
	})

	seg_road : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64 -> List(Paint.DrawCmd)
	seg_road = |segs, ch, pose, d, cf, view_w| ({
		sg = (List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range")))) ?? crash("list-at out of range"))
		road_slice(segs, ch, pose, d, cf, view_w, 0, chunks_for(sg.length), sg.length, sg.width)
	})

	joint_approach : List(World.Segment), List(I64), Frame.Pose, Frame.Mapper, F64, F64 -> List(Geom.RiderPt)
	joint_approach = |segs, ch, pose, from_map, from_len, from_w| [Frame.map_pt(segs, ch, pose, from_map, from_len, 0.0), Frame.map_pt(segs, ch, pose, from_map, from_len, from_w), Frame.map_pt(segs, ch, pose, from_map, (from_len - entry_road_dist), from_w), Frame.map_pt(segs, ch, pose, from_map, (from_len - entry_road_dist), 0.0)]

	joint_pavement : List(World.Segment), List(I64), Frame.Pose, Frame.Mapper, Frame.Mapper, F64, F64, F64, Bool -> List(Geom.RiderPt)
	joint_pavement = |segs, ch, pose, from_map, to_map, from_len, from_w, to_w, exit_right| ({
		inner = Frame.map_pt(segs, ch, pose, from_map, from_len, (if exit_right { from_w } else { 0.0 }))
		outer_from = Frame.map_pt(segs, ch, pose, from_map, from_len, Joint.outer_cu(exit_right, from_w))
		outer_to = Frame.map_pt(segs, ch, pose, to_map, 0.0, Joint.outer_cu(exit_right, to_w))
		q = Joint.joint_apex(segs, ch, pose, from_map, to_map, from_len, from_w, to_w, exit_right)
		[inner, outer_from, q, outer_to]
	})

	emit_joint_ground : List(World.Segment), List(I64), Frame.Pose, Frame.Mapper, Frame.Mapper, F64, F64, F64, Bool, F64, F64 -> List(Paint.DrawCmd)
	emit_joint_ground = |segs, ch, pose, from_map, to_map, from_len, from_w, to_w, exit_right, cf, view_w| List.concat(emit_ground(joint_approach(segs, ch, pose, from_map, from_len, from_w), cf, view_w), emit_ground(joint_pavement(segs, ch, pose, from_map, to_map, from_len, from_w, to_w, exit_right), cf, view_w))

	pond_shape : List(World.Segment), List(I64), Frame.Pose, Frame.Mapper, F64, List(Pond.PondPt), I64 -> List(Geom.RiderPt)
	pond_shape = |segs, ch, pose, m, from_len, ps, i| (if (i >= U64.to_i64_wrap(List.len(ps))) { [] } else { List.concat([Frame.map_pt(segs, ch, pose, m, (from_len + (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).cv), (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).cu)], pond_shape(segs, ch, pose, m, from_len, ps, (i + 1))) })

	emit_pond_ground : List(World.Segment), List(I64), Frame.Pose, Frame.Mapper, F64, F64, F64 -> List(Paint.DrawCmd)
	emit_pond_ground = |segs, ch, pose, m, from_len, cf, view_w| List.concat(Ground.emit_ground_color(pond_shape(segs, ch, pose, m, from_len, Pond.water_outline, 0), Pond.water_color, cf, view_w), Ground.emit_ground_color(pond_shape(segs, ch, pose, m, from_len, Pond.bank, 0), Pond.bank_color, cf, view_w))

	seg_ground : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64 -> List(Paint.DrawCmd)
	seg_ground = |segs, ch, pose, d, cf, view_w| List.concat(List.concat(seg_road(segs, ch, pose, d, cf, view_w), seg_joint_ground(segs, ch, pose, d, cf, view_w)), seg_pond_ground(segs, ch, pose, d, cf, view_w))

	seg_joint_ground : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64 -> List(Paint.DrawCmd)
	seg_joint_ground = |segs, ch, pose, d, cf, view_w| (if ((d + 1) >= U64.to_i64_wrap(List.len(ch))) { [] } else { emit_joint_ground(segs, ch, pose, Frame.chain_map(d), Frame.chain_map((d + 1)), (List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range")))) ?? crash("list-at out of range")).length, (List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range")))) ?? crash("list-at out of range")).width, (List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap((d + 1))) ?? crash("list-at out of range")))) ?? crash("list-at out of range")).width, (List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range")))) ?? crash("list-at out of range")).exit_right, cf, view_w) })

	seg_pond_ground : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64 -> List(Paint.DrawCmd)
	seg_pond_ground = |segs, ch, pose, d, cf, view_w| ({
		sg = (List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash("list-at out of range")))) ?? crash("list-at out of range"))
		(if Scenery.is_pond(sg.exit_creature) { emit_pond_ground(segs, ch, pose, Frame.chain_map(d), sg.length, cf, view_w) } else { [] })
	})

	walk_ground : List(World.Segment), List(I64), Frame.Pose, F64, F64, I64 -> List(Paint.DrawCmd)
	walk_ground = |segs, ch, pose, cf, view_w, d| (if (d >= U64.to_i64_wrap(List.len(ch))) { [] } else { List.concat(seg_ground(segs, ch, pose, d, cf, view_w), walk_ground(segs, ch, pose, cf, view_w, (d + 1))) })

	behind_ground : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64 -> List(Paint.DrawCmd)
	behind_ground = |segs, ch, pose, prev_idx, cf, view_w| ({
		pv = (List.get(segs, I64.to_u64_wrap(prev_idx)) ?? crash("list-at out of range"))
		List.concat(emit_joint_ground(segs, ch, pose, Frame.prev_map(pv), Frame.chain_map(0), pv.length, pv.width, (List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))) ?? crash("list-at out of range")).width, pv.exit_right, cf, view_w), behind_pond_ground(segs, ch, pose, pv, cf, view_w))
	})

	behind_pond_ground : List(World.Segment), List(I64), Frame.Pose, World.Segment, F64, F64 -> List(Paint.DrawCmd)
	behind_pond_ground = |segs, ch, pose, pv, cf, view_w| (if Scenery.is_pond(pv.exit_creature) { emit_pond_ground(segs, ch, pose, Frame.prev_map(pv), pv.length, cf, view_w) } else { [] })

	frame_ground : List(World.Segment), I64, Frame.Pose, F64, F64 -> List(Paint.DrawCmd)
	frame_ground = |segs, seg_idx, pose, cf, view_w| ({
		ch = Frame.build_chain(segs, seg_idx)
		(if (seg_idx > 0) { List.concat(walk_ground(segs, ch, pose, cf, view_w, 0), behind_ground(segs, ch, pose, (seg_idx - 1), cf, view_w)) } else { walk_ground(segs, ch, pose, cf, view_w, 0) })
	})
}
