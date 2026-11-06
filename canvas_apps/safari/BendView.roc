## BendView knows where two segments meet: where each lies from the rider, and
## the apex where the outer edges of the road meet at the bend. The road's
## paving and the guard rail both follow it.
import Across
import Along
import Angle
import Distance
import Chain
import Geom
import Scenery
import World

## A bend as the rider sees it: where the segments before and after it lie,
## the length of the one before, and the turn the road makes, positive to
## the right.
BendView := {
	before : Chain.SegmentPlace,
	after : Chain.SegmentPlace,
	length_before : Distance,
	turn : Angle.Turn,
}.{

	## The bend at the end of `segment`, which lies at `before`.
	of_segment : World.Segment,
	{
		before : Chain.SegmentPlace,
		after : Chain.SegmentPlace,
	} -> BendView
	of_segment = |segment, { before, after }| {
		before,
		after,
		length_before: segment.length,
		turn: segment.exit_turn,
	}

	## How far across the road its outer edge at a bend is: the left edge
	## when the road turns right, the right edge when it turns left.
	outer_edge : Angle.Turn -> Across
	outer_edge = |turn|
		if turn.is_right() {
			Scenery.left_edge
		} else {
			Scenery.right_edge
		}

	## Where the outer edges of the two segments at a bend meet.
	apex : Chain.RoadView, BendView -> Geom.RiderPoint
	apex = |road, bend| {
		across = outer_edge(bend.turn)
		end_before = Along.at(bend.length_before)
		point_before = |along| Chain.rider_point_at(road, { place: bend.before, along, across })
		point_after = |along| Chain.rider_point_at(road, { place: bend.after, along, across })
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
left_turn = Angle.Turn.radians(-1.2217304763960306)

expect BendView.outer_edge(right_turn) == Scenery.left_edge
expect BendView.outer_edge(left_turn) == Scenery.right_edge

## The apex of a bend from a segment 300 m long, just behind the rider's.
apex_after_turn : Angle.Turn -> Geom.RiderPoint
apex_after_turn = |turn|
	BendView.apex(
		{
			route_segments: [],
			chain_indices: [],
			vantage: {
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
				road_width: Distance.metres(4.0),
			}),
			after: InChain(Chain.Position.first),
			length_before: Distance.metres(300.0),
			turn,
		},
	)

# Each is within 1e-7 of its want, scaled up by a want past 1.
expect
	[
		(apex_after_turn(right_turn).right.to_metres(), 17.297297467543466),
		(apex_after_turn(right_turn).forward.to_metres(), -100.43071597950589),
		(apex_after_turn(left_turn).right.to_metres(), 21.403438709482494),
		(apex_after_turn(left_turn).forward.to_metres(), -100.55298847633645),
	].all(|(got, want)| (got - want).abs() <= 0.0000001 * want.abs().max(1.0))

vantage : Geom.Vantage
vantage = {
	along: Along.metres(100.0),
	across: Across.metres(1.0),
	yaw: Angle.Turn.radians(0.2),
	half_width: Distance.metres(2.0),
}

m_chain : Chain.SegmentPlace
m_chain = InChain(Chain.Position.number(3))

m_prev_left : Chain.SegmentPlace
m_prev_left = JustBehind({
	segment_length: Distance.metres(300.0),
	turn: Angle.Turn.radians(-1.2217304763960306),
	road_width: Distance.metres(4.0),
})

m_prev_right : Chain.SegmentPlace
m_prev_right = JustBehind({
	segment_length: Distance.metres(300.0),
	turn: Angle.Turn.radians(0.8726646259971648),
	road_width: Distance.metres(4.0),
})

## The bend of a place behind the rider.
bend_of : Chain.SegmentPlace -> Geom.Bend
bend_of = |place|
	match place {
		JustBehind(bend) => bend
		InChain(_) => crash "BendView.bend_of: only a place behind the rider has a bend"
	}

is_in_chain : Chain.SegmentPlace -> Bool
is_in_chain = |place|
	match place {
		InChain(_) => True
		JustBehind(_) => False
	}

turns_right : Chain.SegmentPlace -> Bool
turns_right = |place| bend_of(place).turn.is_right()

expect bend_of(m_prev_left).segment_length.to_metres() == 300.0
expect bend_of(m_prev_left).road_width.to_metres() == 4.0
expect bend_of(m_prev_right).segment_length.to_metres() == 300.0
expect bend_of(m_prev_right).road_width.to_metres() == 4.0
expect bend_of(Chain.place_behind(World.route_segment(0))).segment_length.to_metres() == 500.0
expect is_in_chain(m_chain)
expect !is_in_chain(m_prev_left)
expect !is_in_chain(m_prev_right)
expect !turns_right(m_prev_left)
expect turns_right(m_prev_right)

## A road along `chain_indices`, the route's segments by number.
road_along : List(U32) -> Chain.RoadView
road_along = |chain_indices| {
	route_segments: World.segments,
	chain_indices: chain_indices.map(World.SegmentIndex.number),
	vantage,
}

expect
	[
		([0, 1], 0),
		([3, 4], 3),
	].all(|(chain_indices, want)| Chain.rider_segment(road_along(chain_indices)).to_i64() == want)

## The route's number of the segment behind the rider's, or -1 at the route's
## start.
number_behind : List(U32) -> I64
number_behind = |chain_indices|
	match Chain.segment_behind(road_along(chain_indices)) {
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
at_d0 = Chain.rider_point_ahead(
	{ route_segments: [], chain_indices: [], vantage },
	{
		position: Chain.Position.first,
		along: Along.metres(50.0),
		across: Across.metres(1.0),
	},
)

point_at_d1 : List(World.Segment) -> Geom.RiderPoint
point_at_d1 = |route_segments| Chain.rider_point_ahead(
	{
		route_segments,
		chain_indices: Chain.indices_ahead(route_segments, World.SegmentIndex.first),
		vantage,
	},
	{
		position: Chain.Position.number(1),
		along: Along.metres(50.0),
		across: Across.metres(1.0),
	},
)

expect {
	second_segment_point = point_at_d1(World.segments)
	[
		(at_d0.right.to_metres(), 9.933466539753061),
		(at_d0.forward.to_metres(), -49.00332889206208),
		(second_segment_point.right.to_metres(), -48.11621135085446),
		(second_segment_point.forward.to_metres(), 431.95658232777186),
	].all(|(got, want)| (got - want).abs() <= 0.00000005 * want.abs().max(1.0))
}

## The point 50 m along the segment at `place`, which is behind the rider.
rider_point_behind : Chain.SegmentPlace -> Geom.RiderPoint
rider_point_behind = |place| Chain.rider_point_at(
	{ route_segments: [], chain_indices: [], vantage },
	{
		place,
		along: Along.metres(50.0),
		across: Across.metres(1.0),
	},
)

expect
	[
		(rider_point_behind(m_prev_left).right.to_metres(), -194.76069932822074),
		(rider_point_behind(m_prev_left).forward.to_metres(), -231.63435691739767),
		(rider_point_behind(m_prev_right).right.to_metres(), 239.9883995667414),
		(rider_point_behind(m_prev_right).forward.to_metres(), -218.13274420105967),
	].all(|(got, want)| (got - want).abs() <= 0.0000001 * want.abs().max(1.0))
