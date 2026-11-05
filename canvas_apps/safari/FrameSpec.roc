## These are Frame's checks: the chain's bounds, a segment's place, the
## rider's segment and the one behind it, and where a point lands in the
## rider's view.
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import Frame
import Geom
import Distance
import Across
import Along
import Grade
import World

bound_got : List(I64)
bound_got = [
	Frame.look_ahead.to_i64(),
	Frame.chain_ahead(World.segments, World.SegmentIndex.first).len().to_i64_wrap(),
]

bound_want : List(I64)
bound_want = [7, 7]

route_facts : List(World.Segment) -> List(I64)
route_facts = |w| [
	w.len().to_i64_wrap(),
	Frame.chain_ahead(w, World.SegmentIndex.first).len().to_i64_wrap(),
	Frame.chain_ahead(w, World.SegmentIndex.number(15)).len().to_i64_wrap(),
	Frame.chain_ahead(w, World.SegmentIndex.number(18)).len().to_i64_wrap(),
]

route_got : List(I64)
route_got = route_facts(World.segments)

route_want : List(I64)
route_want = [19, 7, 4, 1]

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
		InChain(_) => crash "FrameSpec.bend_of: only a place behind the rider has a bend"
	}

is_in_chain : Frame.SegmentPlace -> Bool
is_in_chain = |place|
	match place {
		InChain(_) => True
		JustBehind(_) => False
	}

turns_right : Frame.SegmentPlace -> Bool
turns_right = |place| bend_of(place).turn.is_right()

map_int_got : List(I64)
map_int_got = [Frame.ChainPosition.number(3).to_i64(), Frame.ChainPosition.first.next().to_i64()]

map_int_want : List(I64)
map_int_want = [3, 1]

map_real_got : List(F64)
map_real_got = [
	bend_of(m_prev_left).segment_length.to_metres(),
	bend_of(m_prev_left).lane_width.to_metres(),
	bend_of(m_prev_right).segment_length.to_metres(),
	bend_of(m_prev_right).lane_width.to_metres(),
	bend_of(Frame.place_behind(World.route_segment(0))).segment_length.to_metres(),
]

map_real_want : List(F64)
map_real_want = [300.0, 4.0, 300.0, 4.0, 500.0]

map_bool_got : List(Bool)
map_bool_got = [
	is_in_chain(m_chain),
	is_in_chain(m_prev_left),
	is_in_chain(m_prev_right),
	turns_right(m_prev_left),
	turns_right(m_prev_right),
]

map_bool_want : List(Bool)
map_bool_want = [True, False, False, False, True]

## A road along `chain`, the route's segments by number.
road_along : List(U32) -> Frame.RoadView
road_along = |chain| {
	world: World.segments,
	chain: chain.map(World.SegmentIndex.number),
	pose,
}

rider_got : List(I64)
rider_got = [
	[0, 1],
	[3, 4],
].map(|chain| Frame.rider_segment(road_along(chain)).to_i64())

rider_want : List(I64)
rider_want = [0, 3]

## The route's number of the segment behind the rider's, or -1 at the route's
## start.
number_behind : List(U32) -> I64
number_behind = |chain|
	match Frame.segment_behind(road_along(chain)) {
		Previous(index) => index.to_i64()
		AtRouteStart => -1
	}

behind_rider_got : List(I64)
behind_rider_got = [
	[0, 1],
	[1, 2],
	[3, 4],
].map(number_behind)

behind_rider_want : List(I64)
behind_rider_want = [-1, 0, 2]

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
		across: Across.metres(3.0),
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
		across: Across.metres(3.0),
	},
)

at_got : List(F64)
at_got = {
	p = at_d1(World.segments)
	[
		at_d0.right,
		at_d0.forward,
		p.right,
		p.forward,
	]
}

at_want : List(F64)
at_want = [
	9.933466539753061,
	(-49.00332889206208),
	(-48.11621135085446),
	431.95658232777186,
]

behind_got : List(F64)
behind_got = {
	l = Frame.rider_point_at(
		{
			world: [],
			chain: [],
			pose,
		},
		{
			place: m_prev_left,
			along: Along.metres(50.0),
			across: Across.metres(3.0),
		},
	)
	r = Frame.rider_point_at(
		{
			world: [],
			chain: [],
			pose,
		},
		{
			place: m_prev_right,
			along: Along.metres(50.0),
			across: Across.metres(3.0),
		},
	)
	[
		l.right,
		l.forward,
		r.right,
		r.forward,
	]
}

behind_want : List(F64)
behind_want = [
	(-194.76069932822074),
	(-231.63435691739767),
	239.9883995667414,
	(-218.13274420105967),
]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.ints({
			name: "fr-bound",
			got: bound_got,
			want: bound_want,
		}),
		Grade.ints({
			name: "fr-route",
			got: route_got,
			want: route_want,
		}),
		Grade.ints({
			name: "fr-mapi ",
			got: map_int_got,
			want: map_int_want,
		}),
		Grade.reals({
			name: "fr-mapr ",
			got: map_real_got,
			want: map_real_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "fr-mapb ",
			got: map_bool_got,
			want: map_bool_want,
		}),
		Grade.ints({
			name: "fr-rider",
			got: rider_got,
			want: rider_want,
		}),
		Grade.ints({
			name: "fr-back ",
			got: behind_rider_got,
			want: behind_rider_want,
		}),
		Grade.rel({
			name: "fr-at   ",
			got: at_got,
			want: at_want,
			tol: F64.from_bits(4497644614860975944),
		}),
		Grade.rel({
			name: "fr-behind",
			got: behind_got,
			want: behind_want,
			tol: F64.from_bits(4502148214488346440),
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
