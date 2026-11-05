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
	outer_edge = |turn| if turn.is_right() {
		Scenery.left_edge
	} else {
		Scenery.right_edge
	}

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

pose : Frame.Pose
pose = {
	along: Along.metres(100.0),
	across: Across.metres(1.0),
	yaw: Angle.Turn.radians(0.2),
	half_width: Distance.metres(2.0),
}

m_chain : Frame.SegmentPlace
m_chain = InChain(Frame.ChainPosition.number(3))

m_prev_left : Frame.SegmentPlace
m_prev_left = JustBehind({
	segment_length: Distance.metres(300.0),
	turn: Angle.Turn.radians(0.0 - 1.2217304763960306),
	lane_width: Distance.metres(4.0),
})

m_prev_right : Frame.SegmentPlace
m_prev_right = JustBehind({
	segment_length: Distance.metres(300.0),
	turn: Angle.Turn.radians(0.8726646259971648),
	lane_width: Distance.metres(4.0),
})

## The bend of a place behind the rider.
bend_of : Frame.SegmentPlace -> Geom.Bend
bend_of = |place|
	match place {
		JustBehind(bend) => bend
		InChain(_) => crash "Joint.bend_of: only a place behind the rider has a bend"
	}

is_in_chain : Frame.SegmentPlace -> Bool
is_in_chain = |place|
	match place {
		InChain(_) => True
		JustBehind(_) => False
	}

turns_right : Frame.SegmentPlace -> Bool
turns_right = |place| bend_of(place).turn.is_right()

expect bend_of(m_prev_left).segment_length.to_metres() == 300.0
expect bend_of(m_prev_left).lane_width.to_metres() == 4.0
expect bend_of(m_prev_right).segment_length.to_metres() == 300.0
expect bend_of(m_prev_right).lane_width.to_metres() == 4.0
expect bend_of(Frame.place_behind(World.route_segment(0))).segment_length.to_metres() == 500.0
expect is_in_chain(m_chain)
expect !(is_in_chain(m_prev_left))
expect !(is_in_chain(m_prev_right))
expect !(turns_right(m_prev_left))
expect turns_right(m_prev_right)

## A road along `chain`, the route's segments by number.
road_along : List(U32) -> Frame.RoadView
road_along = |chain| {
	world: World.segments,
	chain: chain.map(World.SegmentIndex.number),
	pose,
}

expect
	[
		([0, 1], 0),
		([3, 4], 3),
	].all(|(chain, want)| Frame.rider_segment(road_along(chain)).to_i64() == want)

## The route's number of the segment behind the rider's, or -1 at the route's
## start.
number_behind : List(U32) -> I64
number_behind = |chain|
	match Frame.segment_behind(road_along(chain)) {
		Previous(index) => index.to_i64()
		AtRouteStart => -1
	}

expect
	[
		([0, 1], -1),
		([1, 2], 0),
		([3, 4], 2),
	].all(|(input, want)| number_behind(input) == want)

at_d0 : Geom.RiderPoint
at_d0 = Frame.rider_point_ahead(
	{
		world: [],
		chain: [],
		pose,
	},
	{
		position: Frame.ChainPosition.first,
		along: Along.metres(50.0),
		across: Across.metres(1.0),
	},
)

at_d1 : List(World.Segment) -> Geom.RiderPoint
at_d1 = |w| Frame.rider_point_ahead(
	{
		world: w,
		chain: Frame.chain_ahead(w, World.SegmentIndex.first),
		pose,
	},
	{
		position: Frame.ChainPosition.number(1),
		along: Along.metres(50.0),
		across: Across.metres(1.0),
	},
)

expect {
	second_segment_point = at_d1(World.segments)
	[
		(at_d0.right, 9.933466539753061),
		(at_d0.forward, -49.00332889206208),
		(second_segment_point.right, -48.11621135085446),
		(second_segment_point.forward, 431.95658232777186),
	].all(|(got, want)| (got - want).abs() <= 0.00000005 * want.abs().max(1.0))
}

## The point 50 m along the segment at `place`, which is behind the rider.
behind_at : Frame.SegmentPlace -> Geom.RiderPoint
behind_at = |place| Frame.rider_point_at(
	{
		world: [],
		chain: [],
		pose,
	},
	{
		place,
		along: Along.metres(50.0),
		across: Across.metres(1.0),
	},
)

expect
	[
		(behind_at(m_prev_left).right, -194.76069932822074),
		(behind_at(m_prev_left).forward, -231.63435691739767),
		(behind_at(m_prev_right).right, 239.9883995667414),
		(behind_at(m_prev_right).forward, -218.13274420105967),
	].all(|(got, want)| (got - want).abs() <= 0.0000001 * want.abs().max(1.0))
