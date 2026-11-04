# FrameSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Frame
import Geom
import Grade
import World

bound_got : List(I64)
bound_got = [Frame.look_ahead, Frame.max_chain]

bound_want : List(I64)
bound_want = [7, 8]

route_facts : List(World.Segment) -> List(I64)
route_facts = |w| [
	w.len().to_i64_wrap(),
	Frame.build_chain(w, 0).len().to_i64_wrap(),
	Frame.build_chain(w, 15).len().to_i64_wrap(),
	Frame.build_chain(w, 18).len().to_i64_wrap(),
]

route_got : List(I64)
route_got = route_facts(World.segments)

route_want : List(I64)
route_want = [19, 7, 4, 1]

pose : Frame.Pose
pose = {
	along: 100.0,
	across: 1.0,
	yaw: 0.2,
	hw: 2.0,
}

m_chain : Frame.Mapper
m_chain = Frame.chain_map(3)

m_prev_left : Frame.Mapper
m_prev_left = {
	is_chain: False,
	d: 0,
	prev_len: 300.0,
	prev_angle: 1.2217304763960306,
	prev_right: False,
	prev_w: 4.0,
}

m_prev_right : Frame.Mapper
m_prev_right = {
	is_chain: False,
	d: 0,
	prev_len: 300.0,
	prev_angle: 0.8726646259971648,
	prev_right: True,
	prev_w: 4.0,
}

map_int_got : List(I64)
map_int_got = [m_chain.d, m_prev_left.d]

map_int_want : List(I64)
map_int_want = [3, 0]

map_real_got : List(F64)
map_real_got = [
	m_chain.prev_len,
	m_chain.prev_angle,
	m_chain.prev_w,
	m_prev_left.prev_len,
	m_prev_left.prev_w,
]

map_real_want : List(F64)
map_real_want = [0.0, 0.0, 0.0, 300.0, 4.0]

map_bool_got : List(Bool)
map_bool_got = [
	m_chain.is_chain,
	m_chain.prev_right,
	m_prev_left.is_chain,
	m_prev_left.prev_right,
	m_prev_right.prev_right,
]

map_bool_want : List(Bool)
map_bool_want = [True, False, False, False, True]

at_d0 : Geom.RiderPt
at_d0 = Frame.at(
	{
		world: [],
		chain: [],
		pose,
	},
	{
		segments_ahead: 0,
		along: 50.0,
		across: 3.0,
	},
)

at_d1 : List(World.Segment) -> Geom.RiderPt
at_d1 = |w| Frame.at(
	{
		world: w,
		chain: Frame.build_chain(w, 0),
		pose,
	},
	{
		segments_ahead: 1,
		along: 50.0,
		across: 3.0,
	},
)

at_got : List(F64)
at_got = (
	{
		p = at_d1(World.segments)
		[
			at_d0.right,
			at_d0.forward,
			p.right,
			p.forward,
		]
	}
)

at_want : List(F64)
at_want = [
	9.933466539753061,
	(-49.00332889206208),
	(-48.11621135085446),
	431.95658232777186,
]

behind_got : List(F64)
behind_got = (
	{
		l = Frame.map_pt(
			{
				world: [],
				chain: [],
				pose,
			},
			{
				mapper: m_prev_left,
				along: 50.0,
				across: 3.0,
			},
		)
		r = Frame.map_pt(
			{
				world: [],
				chain: [],
				pose,
			},
			{
				mapper: m_prev_right,
				along: 50.0,
				across: 3.0,
			},
		)
		[
			l.right,
			l.forward,
			r.right,
			r.forward,
		]
	}
)

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
