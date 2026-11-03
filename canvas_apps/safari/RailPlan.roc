# RailPlan -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import DepthSort
import lib.DeviceMath
import Frame
import Geom
import GuardRail
import Joint
import Num_
import Scenery
import World

RailPlan :: [].{

	leg_steps : F64 -> I64
	leg_steps = |dist| (
		{
			r = Num_.round_real(dist)
			F64.to_i64_wrap((
				if (r < 1.0) {
					1.0
				} else {
					r
				}
			))
		}
	)

	# leg_points builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	leg_points : Geom.RiderPt, F64, F64, I64, I64 -> List(Geom.RiderPt)
	leg_points = |from, dr, df, steps, i| leg_points_onto(from, dr, df, steps, i, [])

	leg_points_onto : Geom.RiderPt, F64, F64, I64, I64, List(Geom.RiderPt) -> List(Geom.RiderPt)
	leg_points_onto = |from, dr, df, steps, i, acc| (
		if (i > steps) {
			acc
		} else {
			(
				{
					t = (I64.to_f64(i) / I64.to_f64(steps))
					leg_points_onto(from, dr, df, steps, (i + 1), List.append(acc, { right: (from.right + (dr * t)), forward: (from.forward + (df * t)) }))
				}
			)
		}
	)

	push_leg : Geom.RiderPt, Geom.RiderPt -> List(Geom.RiderPt)
	push_leg = |from, to| (
		{
			dr = (to.right - from.right)
			df = (to.forward - from.forward)
			leg_points(from, dr, df, leg_steps(DeviceMath.real_sqrt(((dr * dr) + (df * df)))), 1)
		}
	)

	# rail_run_up builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	rail_run_up : List(World.Segment), List(I64), Frame.Pose, Frame.Mapper, F64, F64, I64 -> List(Geom.RiderPt)
	rail_run_up = |segs, ch, pose, m, from_len, cu, k| rail_run_up_onto(segs, ch, pose, m, from_len, cu, k, [])

	rail_run_up_onto : List(World.Segment), List(I64), Frame.Pose, Frame.Mapper, F64, F64, I64, List(Geom.RiderPt) -> List(Geom.RiderPt)
	rail_run_up_onto = |segs, ch, pose, m, from_len, cu, k, acc| (
		if (k < 0) {
			acc
		} else {
			rail_run_up_onto(segs, ch, pose, m, from_len, cu, (k - 1), List.append(acc, Frame.map_pt(segs, ch, pose, m, (from_len - I64.to_f64(k)), cu)))
		}
	)

	# rail_run_out builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	rail_run_out : List(World.Segment), List(I64), Frame.Pose, Frame.Mapper, F64, I64 -> List(Geom.RiderPt)
	rail_run_out = |segs, ch, pose, m, x, k| rail_run_out_onto(segs, ch, pose, m, x, k, [])

	rail_run_out_onto : List(World.Segment), List(I64), Frame.Pose, Frame.Mapper, F64, I64, List(Geom.RiderPt) -> List(Geom.RiderPt)
	rail_run_out_onto = |segs, ch, pose, m, x, k, acc| (
		if (k > GuardRail.rail_runout) {
			acc
		} else {
			rail_run_out_onto(segs, ch, pose, m, x, (k + 1), List.append(acc, Frame.map_pt(segs, ch, pose, m, I64.to_f64(k), x)))
		}
	)

	joint_rail_path : List(World.Segment), List(I64), Frame.Pose, Frame.Mapper, Frame.Mapper, F64, F64, F64, Bool -> List(Geom.RiderPt)
	joint_rail_path = |segs, ch, pose, from_map, to_map, from_len, from_w, to_w, exit_right| (
		{
			fcu = Joint.outer_cu(exit_right, from_w)
			tx = Joint.outer_cu(exit_right, to_w)
			of_pt = Frame.map_pt(segs, ch, pose, from_map, from_len, fcu)
			ot_pt = Frame.map_pt(segs, ch, pose, to_map, 0.0, tx)
			q = Joint.joint_apex(segs, ch, pose, from_map, to_map, from_len, from_w, to_w, exit_right)
			List.join([rail_run_up(segs, ch, pose, from_map, from_len, fcu, GuardRail.rail_runout), push_leg(of_pt, q), push_leg(q, ot_pt), rail_run_out(segs, ch, pose, to_map, tx, 1)])
		}
	)

	joint_rails : List(World.Segment), List(I64), Frame.Pose, Frame.Mapper, Frame.Mapper, F64, Bool -> List(GuardRail.RailPoly)
	joint_rails = |segs, ch, pose, from_map, to_map, from_len, exit_right| GuardRail.rail_emit(joint_rail_path(segs, ch, pose, from_map, to_map, from_len, Scenery.lane_width, Scenery.lane_width, exit_right))

	# walk_rails builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	walk_rails : List(World.Segment), List(I64), Frame.Pose -> List(GuardRail.RailPoly)
	walk_rails = |segs, ch, pose| walk_rails_onto(segs, ch, pose, 0, [])

	walk_rails_onto : List(World.Segment), List(I64), Frame.Pose, I64, List(GuardRail.RailPoly) -> List(GuardRail.RailPoly)
	walk_rails_onto = |segs, ch, pose, d, acc| (
		if ((d + 1) >= ch.len().to_i64_wrap()) {
			acc
		} else {
			walk_rails_onto(segs, ch, pose, (d + 1), List.concat(acc, joint_rails(segs, ch, pose, Frame.chain_map(d), Frame.chain_map((d + 1)), (List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash ("list-at out of range")))) ?? crash ("list-at out of range")).length, (List.get(segs, I64.to_u64_wrap((List.get(ch, I64.to_u64_wrap(d)) ?? crash ("list-at out of range")))) ?? crash ("list-at out of range")).exit_right)))
		}
	)

	behind_rails : List(World.Segment), List(I64), Frame.Pose, I64 -> List(GuardRail.RailPoly)
	behind_rails = |segs, ch, pose, prev_idx| (
		{
			pv = (List.get(segs, I64.to_u64_wrap(prev_idx)) ?? crash ("list-at out of range"))
			joint_rails(segs, ch, pose, Frame.prev_map(pv), Frame.chain_map(0), pv.length, pv.exit_right)
		}
	)

	all_rails : List(World.Segment), List(I64), Frame.Pose, I64 -> List(GuardRail.RailPoly)
	all_rails = |segs, ch, pose, seg_idx| (
		if (seg_idx > 0) {
			List.concat(walk_rails(segs, ch, pose), behind_rails(segs, ch, pose, (seg_idx - 1)))
		} else {
			walk_rails(segs, ch, pose)
		}
	)

	# rail_items builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	rail_items : List(GuardRail.RailPoly) -> List(DepthSort.DepthKey)
	rail_items = |rs| rail_items_onto(rs, 0, [])

	rail_items_onto : List(GuardRail.RailPoly), I64, List(DepthSort.DepthKey) -> List(DepthSort.DepthKey)
	rail_items_onto = |rs, i, acc| (
		if (i >= rs.len().to_i64_wrap()) {
			acc
		} else {
			rail_items_onto(rs, (i + 1), List.append(acc, { fwd: (List.get(rs, I64.to_u64_wrap(i)) ?? crash ("list-at out of range")).fwd, kind: KRail, i: i }))
		}
	)
}
