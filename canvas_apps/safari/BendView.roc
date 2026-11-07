## BendView knows where two segments meet: where each lies from the rider, and
## the apex where the outer edges of the road meet at the bend. The road's
## paving and the guard rail both follow it.
import Across
import Along
import Angle
import Distance
import RoadAhead
import Segment
import SegmentPlace
import Geom
import World

## A bend as the rider sees it: where the segment before it lies, and the
## bend itself.
BendView := { before : SegmentPlace, bend : Geom.Bend }.{

	## The bend at the end of `segment`, which lies at `before`.
	of_segment : Segment, SegmentPlace -> BendView
	of_segment = |segment, before| { before, bend: segment.bend_out_of() }

	## The bend at the end of `in_view`, unless the road in view ends there.
	bend_after : RoadAhead.RoadView, RoadAhead.SegmentInView -> Try(BendView, [RoadEndsInView])
	bend_after = |road, in_view|
		if RoadAhead.has_bend_in_view(road, in_view) {
			Ok(BendView.of_segment(in_view.segment, in_view.place))
		} else {
			Err(RoadEndsInView)
		}

	## The turn the road makes at a bend, positive to the right.
	turn : BendView -> Angle.Turn
	turn = |bend_view| bend_view.bend.turn

	## Where the segment after a bend lies: next on the road ahead, or the
	## rider's own when the segment before is just behind the rider.
	place_after : BendView -> SegmentPlace
	place_after = |bend_view|
		match bend_view.before {
			Ahead(position) => Ahead(position.next())
			JustBehind(_) => Ahead(SegmentPlace.Position.first)
		}

	## How far across the road its outer edge at a bend is: the left edge
	## when the road turns right, the right edge when it turns left.
	outer_edge : Angle.Turn -> Across
	outer_edge = |bend_turn|
		if bend_turn.is_right() {
			Geom.left_edge
		} else {
			Geom.right_edge
		}

	## Where the outer edges of the two segments at a bend meet.
	apex : RoadAhead.RoadView, BendView -> Geom.RiderPoint
	apex = |road, bend_view| {
		across = outer_edge(bend_view.turn())
		end_before = Along.at(bend_view.bend.segment_length)
		before = bend_view.before
		point_before = |along| RoadAhead.rider_point_at(road, { place: before, along, across })
		place = place_after(bend_view)
		point_after = |along| RoadAhead.rider_point_at(road, { place, along, across })
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

expect BendView.outer_edge(right_turn) == Geom.left_edge
expect BendView.outer_edge(left_turn) == Geom.right_edge

## The apex of a bend from a segment 300 m long, just behind the rider's.
apex_after_turn : Angle.Turn -> Geom.RiderPoint
apex_after_turn = |turn|
	BendView.apex(
		{
			route_segments: [],
			segments_ahead: [],
			vantage: {
				along: Along.metres(100.0),
				across: Across.metres(1.0),
				yaw: Angle.Turn.radians(0.2),
			},
		},
		{
			before: JustBehind({ segment_length: Distance.metres(300.0), turn }),
			bend: { segment_length: Distance.metres(300.0), turn },
		},
	)

# The segment after a bend, from each place the segment before can lie.
position_after : SegmentPlace -> I64
position_after = |before| {
	bend = BendView.of_segment(World.route_segment(0), before)
	match BendView.place_after(bend) {
		Ahead(position) => position.to_i64()
		JustBehind(_) => -1
	}
}

expect position_after(Ahead(SegmentPlace.Position.first)) == 1
expect position_after(Ahead(SegmentPlace.Position.number(3))) == 4
expect position_after(m_prev_left) == 0

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
}

m_ahead : SegmentPlace
m_ahead = Ahead(SegmentPlace.Position.number(3))

m_prev_left : SegmentPlace
m_prev_left = JustBehind({
	segment_length: Distance.metres(300.0),
	turn: Angle.Turn.radians(-1.2217304763960306),
})

m_prev_right : SegmentPlace
m_prev_right = JustBehind({
	segment_length: Distance.metres(300.0),
	turn: Angle.Turn.radians(0.8726646259971648),
})

## The bend of a place behind the rider.
bend_of : SegmentPlace -> Geom.Bend
bend_of = |place|
	match place {
		JustBehind(bend) => bend
		Ahead(_) => crash "BendView.bend_of: only a place behind the rider has a bend"
	}

is_ahead : SegmentPlace -> Bool
is_ahead = |place|
	match place {
		Ahead(_) => True
		JustBehind(_) => False
	}

turns_right : SegmentPlace -> Bool
turns_right = |place| bend_of(place).turn.is_right()

expect bend_of(m_prev_left).segment_length.to_metres() == 300.0
expect bend_of(m_prev_right).segment_length.to_metres() == 300.0
expect bend_of(RoadAhead.place_behind(World.route_segment(0))).segment_length.to_metres() == 500.0
expect is_ahead(m_ahead)
expect !is_ahead(m_prev_left)
expect !is_ahead(m_prev_right)
expect !turns_right(m_prev_left)
expect turns_right(m_prev_right)

## A road along `segments_ahead`, the route's segments by number.
road_along : List(U32) -> RoadAhead.RoadView
road_along = |segments_ahead| {
	route_segments: World.segments,
	segments_ahead: segments_ahead.map(World.SegmentIndex.number),
	vantage,
}

expect [([0, 1], 0), ([3, 4], 3)].all(
	|(segments_ahead, want)| RoadAhead.rider_segment(road_along(segments_ahead)).to_i64() == want,
)

## The route's number of the segment behind the rider's, or -1 at the route's
## start.
number_behind : List(U32) -> I64
number_behind = |segments_ahead|
	match RoadAhead.segment_behind(road_along(segments_ahead)) {
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
at_d0 = RoadAhead.rider_point_ahead(
	{ route_segments: [], segments_ahead: [], vantage },
	{
		position: SegmentPlace.Position.first,
		along: Along.metres(50.0),
		across: Across.metres(1.0),
	},
)

point_at_d1 : List(Segment) -> Geom.RiderPoint
point_at_d1 = |route_segments| RoadAhead.rider_point_ahead(
	{
		route_segments,
		segments_ahead: RoadAhead.indices_ahead(route_segments, World.SegmentIndex.first),
		vantage,
	},
	{
		position: SegmentPlace.Position.number(1),
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
rider_point_behind : SegmentPlace -> Geom.RiderPoint
rider_point_behind = |place| RoadAhead.rider_point_at(
	{ route_segments: [], segments_ahead: [], vantage },
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
