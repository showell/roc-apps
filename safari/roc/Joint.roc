# Joint -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Frame
import Geom
import World

Joint :: [].{

	outer_cu : Bool, F64 -> F64
	outer_cu = |exit_right, wd| (if exit_right { 0.0 } else { wd })

	joint_apex : List(World.Segment), List(I64), Frame.Pose, Frame.Mapper, Frame.Mapper, F64, F64, F64, Bool -> Geom.RiderPt
	joint_apex = |segs, ch, pose, from_map, to_map, from_len, from_w, to_w, exit_right| ({
		fcu = outer_cu(exit_right, from_w)
		tx = outer_cu(exit_right, to_w)
		Geom.line_meet(Frame.map_pt(segs, ch, pose, from_map, from_len, fcu), Frame.map_pt(segs, ch, pose, from_map, (from_len + 1.0), fcu), Frame.map_pt(segs, ch, pose, to_map, 0.0, tx), Frame.map_pt(segs, ch, pose, to_map, 1.0, tx))
	})
}
