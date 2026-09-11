# Frame -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Geom
import World

Frame :: [].{
	Pose : { along : F64, across : F64, yaw : F64, hw : F64 }
	Mapper : { is_chain : Bool, d : I64, prev_len : F64, prev_angle : F64, prev_right : Bool, prev_w : F64 }

	look_ahead : I64
	look_ahead = 7

	max_chain : I64
	max_chain = 8

	build_chain : List(World.Segment), I64 -> List(I64)
	build_chain = |segs, start| chain_from(segs, start, 0)

	chain_from : List(World.Segment), I64, I64 -> List(I64)
	chain_from = |segs, s, n| (if (n >= look_ahead) { [] } else { (if (n >= max_chain) { [] } else { (if (List.get(segs, I64.to_u64_wrap(s)) ?? crash("list-at out of range")).terminates { [s] } else { List.concat([s], chain_from(segs, (List.get(segs, I64.to_u64_wrap(s)) ?? crash("list-at out of range")).exit_to, (n + 1))) }) }) })

	compose_down : List(World.Segment), List(I64), I64, F64, F64 -> Geom.AX
	compose_down = |segs, ch, k, a, x| (if (k <= 0) { { a: a, x: x } } else { ({
		seg = (List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap((k - 1))) ?? crash("list-at out of range")))) ?? crash("list-at out of range"))
		p = Geom.next_to_cur(a, x, seg.length, seg.exit_angle, seg.exit_right, seg.width)
		compose_down(segs, ch, (k - 1), p.a, p.x)
	}) })

	at : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64 -> Geom.RiderPt
	at = |segs, ch, pose, d, a, x| ({
		p = compose_down(segs, ch, d, a, x)
		Geom.to_rider(p.a, p.x, pose.along, pose.across, pose.yaw, pose.hw)
	})

	chain_map : I64 -> Frame.Mapper
	chain_map = |d| { is_chain: True, d: d, prev_len: 0.0, prev_angle: 0.0, prev_right: False, prev_w: 0.0 }

	prev_map : World.Segment -> Frame.Mapper
	prev_map = |s| { is_chain: False, d: 0, prev_len: s.length, prev_angle: s.exit_angle, prev_right: s.exit_right, prev_w: s.width }

	map_pt : List(World.Segment), List(I64), Frame.Pose, Frame.Mapper, F64, F64 -> Geom.RiderPt
	map_pt = |segs, ch, pose, m, a, x| (if m.is_chain { at(segs, ch, pose, m.d, a, x) } else { ({
		p = Geom.cur_to_next(a, x, m.prev_len, m.prev_angle, m.prev_right, m.prev_w)
		Geom.to_rider(p.a, p.x, pose.along, pose.across, pose.yaw, pose.hw)
	}) })
}
