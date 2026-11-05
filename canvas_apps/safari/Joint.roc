## Joint knows where two segments meet: where each lies from the rider, and
## the apex where the outer edges of the road meet at the bend. The road's
## paving and the guard rail both follow it.
import Frame
import Geom
import Scenery
import World

Joint :: [].{

	## A bend as the rider sees it: where the segments before and after it lie,
	## the length of the one before, and which way the road turns.
	PlacedBend : {
		before : Frame.SegmentPlace,
		after : Frame.SegmentPlace,
		length_before : F64,
		exit_side : Geom.TurnSide,
	}

	## The bend at the end of `segment`, which lies at `before`.
	bend_out_of : World.Segment,
	{
		before : Frame.SegmentPlace,
		after : Frame.SegmentPlace,
	} -> Joint.PlacedBend
	bend_out_of = |segment, { before, after }| {
		before,
		after,
		length_before: segment.length,
		exit_side: segment.exit_side,
	}

	## How far across the road its outer edge at a bend is: the left edge
	## when the road turns right, the right edge when it turns left.
	outer_edge : Geom.TurnSide -> F64
	outer_edge = |exit_side|
		match exit_side {
			TurnsRight => 0.0
			TurnsLeft => Scenery.lane_width
		}

	## Where the outer edges of the two segments at a bend meet.
	joint_apex : Frame.RoadView, Joint.PlacedBend -> Geom.RiderPoint
	joint_apex = |road, bend| {
		across = outer_edge(bend.exit_side)
		point_before = |along| Frame.rider_point_at(
			road,
			{
				place: bend.before,
				along,
				across,
			},
		)
		point_after = |along| Frame.rider_point_at(
			road,
			{
				place: bend.after,
				along,
				across,
			},
		)
		Geom.line_crossing({
			first_line: {
				start_point: point_before(bend.length_before),
				end_point: point_before(bend.length_before + 1.0),
			},
			second_line: {
				start_point: point_after(0.0),
				end_point: point_after(1.0),
			},
		})
	}
}
