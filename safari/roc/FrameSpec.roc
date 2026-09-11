# FrameSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Frame
import Geom
import Grade
import Maybe
import Scenery
import Tuple
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bound_got : List(I64)
bound_got = [Frame.look_ahead, Frame.max_chain]

bound_want : List(I64)
bound_want = [7, 8]

route_facts : List(World.Segment) -> List(I64)
route_facts = |w| [U64.to_i64_wrap(List.len(w)), U64.to_i64_wrap(List.len(Frame.build_chain(w, 0))), U64.to_i64_wrap(List.len(Frame.build_chain(w, 15))), U64.to_i64_wrap(List.len(Frame.build_chain(w, 18)))]

route_got : List(I64)
route_got = route_facts(World.build_world)

route_want : List(I64)
route_want = [19, 7, 4, 1]

pose : Frame.Pose
pose = { along: 100.0, across: 1.0, yaw: 0.2, hw: 2.0 }

m_chain : Frame.Mapper
m_chain = Frame.chain_map(3)

m_prev_left : Frame.Mapper
m_prev_left = { is_chain: False, d: 0, prev_len: 300.0, prev_angle: 1.2217304763960306, prev_right: False, prev_w: 4.0 }

m_prev_right : Frame.Mapper
m_prev_right = { is_chain: False, d: 0, prev_len: 300.0, prev_angle: 0.8726646259971648, prev_right: True, prev_w: 4.0 }

map_int_got : List(I64)
map_int_got = [m_chain.d, m_prev_left.d]

map_int_want : List(I64)
map_int_want = [3, 0]

map_real_got : List(F64)
map_real_got = [m_chain.prev_len, m_chain.prev_angle, m_chain.prev_w, m_prev_left.prev_len, m_prev_left.prev_w]

map_real_want : List(F64)
map_real_want = [0.0, 0.0, 0.0, 300.0, 4.0]

map_bool_got : List(Bool)
map_bool_got = [m_chain.is_chain, m_chain.prev_right, m_prev_left.is_chain, m_prev_left.prev_right, m_prev_right.prev_right]

map_bool_want : List(Bool)
map_bool_want = [True, False, False, False, True]

at_d0 : Geom.RiderPt
at_d0 = Frame.at([], [], pose, 0, 50.0, 3.0)

at_d1 : List(World.Segment) -> Geom.RiderPt
at_d1 = |w| Frame.at(w, Frame.build_chain(w, 0), pose, 1, 50.0, 3.0)

at_got : List(F64)
at_got = ({
	p = at_d1(World.build_world)
	[at_d0.right, at_d0.forward, p.right, p.forward]
})

at_want : List(F64)
at_want = [9.933466539753061, (-49.00332889206208), (-48.11621135085446), 431.95658232777186]

behind_got : List(F64)
behind_got = ({
	l = Frame.map_pt([], [], pose, m_prev_left, 50.0, 3.0)
	r = Frame.map_pt([], [], pose, m_prev_right, 50.0, 3.0)
	[l.right, l.forward, r.right, r.forward]
})

behind_want : List(F64)
behind_want = [(-194.76069932822074), (-231.63435691739767), 239.9883995667414, (-218.13274420105967)]

eq_tup2 : Tuple.Tup2(a, b), Tuple.Tup2(a, b) -> Bool
eq_tup2 = |ex, ey| (match ex {
	MkTup2(exf0, exf1) => (match ey {
		MkTup2(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
})

eq_tup3 : Tuple.Tup3(a, b, c), Tuple.Tup3(a, b, c) -> Bool
eq_tup3 = |ex, ey| (match ex {
	MkTup3(exf0, exf1, exf2) => (match ey {
		MkTup3(eyf0, eyf1, eyf2) => (((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2))
		_ => False
	})
})

eq_tup4 : Tuple.Tup4(a, b, c, d), Tuple.Tup4(a, b, c, d) -> Bool
eq_tup4 = |ex, ey| (match ex {
	MkTup4(exf0, exf1, exf2, exf3) => (match ey {
		MkTup4(eyf0, eyf1, eyf2, eyf3) => ((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3))
		_ => False
	})
})

eq_tup5 : Tuple.Tup5(a, b, c, d, e), Tuple.Tup5(a, b, c, d, e) -> Bool
eq_tup5 = |ex, ey| (match ex {
	MkTup5(exf0, exf1, exf2, exf3, exf4) => (match ey {
		MkTup5(eyf0, eyf1, eyf2, eyf3, eyf4) => (((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3)) and (exf4 == eyf4))
		_ => False
	})
})

eq_maybe : Maybe.Maybe(a), Maybe.Maybe(a) -> Bool
eq_maybe = |ex, ey| (match ex {
	Just(exf0) => (match ey {
		Just(eyf0) => (exf0 == eyf0)
		_ => False
	})
	None => (match ey {
		None => True
		_ => False
	})
})

eq_scheme : Scenery.Scheme, Scenery.Scheme -> Bool
eq_scheme = |ex, ey| (match ex {
	AllGreen => (match ey {
		AllGreen => True
		_ => False
	})
	YellowGreen => (match ey {
		YellowGreen => True
		_ => False
	})
	RedGreen => (match ey {
		RedGreen => True
		_ => False
	})
})

eq_creature : Scenery.Creature, Scenery.Creature -> Bool
eq_creature = |ex, ey| (match ex {
	NoCreature => (match ey {
		NoCreature => True
		_ => False
	})
	Elephant => (match ey {
		Elephant => True
		_ => False
	})
	Giraffe => (match ey {
		Giraffe => True
		_ => False
	})
	Zebra => (match ey {
		Zebra => True
		_ => False
	})
	Rhino => (match ey {
		Rhino => True
		_ => False
	})
	DuckPond => (match ey {
		DuckPond => True
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_ints("fr-bound", bound_got, bound_want))
	line!(Grade.grade_ints("fr-route", route_got, route_want))
	line!(Grade.grade_ints("fr-mapi ", map_int_got, map_int_want))
	line!(Grade.grade_reals("fr-mapr ", map_real_got, map_real_want, 0.0))
	line!(Grade.grade_bools("fr-mapb ", map_bool_got, map_bool_want))
	line!(Grade.grade_rel("fr-at   ", at_got, at_want, F64.from_bits(4497644614860975944)))
	line!(Grade.grade_rel("fr-behind", behind_got, behind_want, F64.from_bits(4502148214488346440)))
	Ok({})
}
