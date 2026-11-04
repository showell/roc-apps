# Joint -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Frame
import Geom
import Scenery
import World

Joint :: [].{

	## How far across the road its outer edge at a bend is: the left edge
	## when the road turns right, the right edge when it turns left.
	outer_cu : Bool -> F64
	outer_cu = |exit_right| (
		if exit_right {
			0.0
		} else {
			Scenery.lane_width
		}
	)

	joint_apex : List(World.Segment), List(I64), Frame.Pose, Frame.Mapper, Frame.Mapper, F64, Bool -> Geom.RiderPt
	joint_apex = |segs, ch, pose, from_map, to_map, from_len, exit_right| (
		{
			fcu = outer_cu(exit_right)
			tx = outer_cu(exit_right)
			Geom.line_meet(Frame.map_pt(segs, ch, pose, from_map, from_len, fcu), Frame.map_pt(segs, ch, pose, from_map, (from_len + 1.0), fcu), Frame.map_pt(segs, ch, pose, to_map, 0.0, tx), Frame.map_pt(segs, ch, pose, to_map, 1.0, tx))
		}
	)
}
