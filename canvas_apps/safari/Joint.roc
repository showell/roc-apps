# Joint -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Frame
import Geom
import Scenery
import World

Joint :: [].{

	## How far across the road its outer edge at a bend is: the left edge
	## when the road turns right, the right edge when it turns left.
	outer_edge : Geom.TurnSide -> F64
	outer_edge = |exit_side|
		match exit_side {
			TurnsRight => 0.0
			TurnsLeft => Scenery.lane_width
		}

	## The road as the rider sees it: the world's segments, the chain of
	## them ahead of the rider, and the rider's pose.
	RoadAhead : {
		world : List(World.Segment),
		chain : List(I64),
		pose : Frame.Pose,
	}

	## Where one segment meets the next: the maps of the segment before
	## the bend and the one after it, the length of the one before, and
	## whether the road turns right.
	Bend : {
		before : Frame.Mapper,
		after : Frame.Mapper,
		length_before : F64,
		exit_side : Geom.TurnSide,
	}

	## Where the outer edges of the two segments at a bend meet.
	joint_apex : Joint.RoadAhead, Joint.Bend -> Geom.RiderPoint
	joint_apex = |
		{
			world: segs,
			chain: ch,
			pose,
		},
		{
			before: from_map,
			after: to_map,
			length_before: from_len,
			exit_side,
		},
	| (
		{
			edge = outer_edge(exit_side)
			road = {
				world: segs,
				chain: ch,
				pose,
			}
			Geom.line_crossing({
				first_line: {
					start_point: Frame.map_pt(
						road,
						{
							mapper: from_map,
							along: from_len,
							across: edge,
						},
					),
					end_point: Frame.map_pt(
						road,
						{
							mapper: from_map,
							along: (from_len + 1.0),
							across: edge,
						},
					),
				},
				second_line: {
					start_point: Frame.map_pt(
						road,
						{
							mapper: to_map,
							along: 0.0,
							across: edge,
						},
					),
					end_point: Frame.map_pt(
						road,
						{
							mapper: to_map,
							along: 1.0,
							across: edge,
						},
					),
				},
			})
		}
	)
}
