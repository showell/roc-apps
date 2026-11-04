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
	joint_apex = |
		segs,
		ch,
		pose,
		from_map,
		to_map,
		from_len,
		exit_right,
	| (
		{
			fcu = outer_cu(exit_right)
			tx = outer_cu(exit_right)
			road = {
				world: segs,
				chain: ch,
				pose,
			}
			Geom.line_meet({
				first_line: {
					start_point: Frame.map_pt(
						road,
						{
							mapper: from_map,
							along: from_len,
							across: fcu,
						},
					),
					end_point: Frame.map_pt(
						road,
						{
							mapper: from_map,
							along: (from_len + 1.0),
							across: fcu,
						},
					),
				},
				second_line: {
					start_point: Frame.map_pt(
						road,
						{
							mapper: to_map,
							along: 0.0,
							across: tx,
						},
					),
					end_point: Frame.map_pt(
						road,
						{
							mapper: to_map,
							along: 1.0,
							across: tx,
						},
					),
				},
			})
		}
	)
}
