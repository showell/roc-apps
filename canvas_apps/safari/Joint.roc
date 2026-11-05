## Joint knows where two segments meet: where each lies from the rider, and
## the apex where the outer edges of the road meet at the bend. The road's
## paving and the guard rail both follow it.
import Across
import Along
import Angle
import Distance
import Frame
import Geom
import Scenery
import World

Joint :: [].{

	## A bend as the rider sees it: where the segments before and after it lie,
	## the length of the one before, and the turn the road makes, positive to
	## the right.
	PlacedBend : {
		before : Frame.SegmentPlace,
		after : Frame.SegmentPlace,
		length_before : Distance,
		turn : Angle.Turn,
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
		turn: segment.exit_turn,
	}

	## How far across the road its outer edge at a bend is: the left edge
	## when the road turns right, the right edge when it turns left.
	outer_edge : Angle.Turn -> Across
	outer_edge = |turn| if (turn.is_right()) Scenery.left_edge else Scenery.right_edge

	## Where the outer edges of the two segments at a bend meet.
	joint_apex : Frame.RoadView, Joint.PlacedBend -> Geom.RiderPoint
	joint_apex = |road, bend| {
		across = outer_edge(bend.turn)
		end_before = Along.at(bend.length_before)
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
				start_point: point_before(end_before),
				end_point: point_before(end_before.plus(Distance.metres(1.0))),
			},
			second_line: {
				start_point: point_after(Along.start),
				end_point: point_after(Along.metres(1.0)),
			},
		})
	}
}

right_turn : Angle.Turn
right_turn = Angle.Turn.radians(0.8726646259971648)

left_turn : Angle.Turn
left_turn = Angle.Turn.radians(0.0 - 1.2217304763960306)

expect Joint.outer_edge(right_turn) == Scenery.left_edge
expect Joint.outer_edge(left_turn) == Scenery.right_edge

## The apex of a bend from a segment 300 m long, just behind the rider's.
apex_after_turn : Angle.Turn -> Geom.RiderPoint
apex_after_turn = |turn|
	Joint.joint_apex(
		{
			world: [],
			chain: [],
			pose: {
				along: Along.metres(100.0),
				across: Across.metres(1.0),
				yaw: Angle.Turn.radians(0.2),
				half_width: Distance.metres(2.0),
			},
		},
		{
			before: JustBehind({
				segment_length: Distance.metres(300.0),
				turn,
				lane_width: Distance.metres(4.0),
			}),
			after: InChain(Frame.ChainPosition.first),
			length_before: Distance.metres(300.0),
			turn,
		},
	)

# Each is within 1e-7 of its want, scaled up by a want past 1.
expect
	[
		(apex_after_turn(right_turn).right, 17.297297467543466),
		(apex_after_turn(right_turn).forward, -100.43071597950589),
		(apex_after_turn(left_turn).right, 21.403438709482494),
		(apex_after_turn(left_turn).forward, -100.55298847633645),
	].all(|(got, want)| (got - want).abs() <= 0.0000001 * want.abs().max(1.0))
