# FrameSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Frame
import Geom
import Grade
import Text
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

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_ints([28, 21, 73, 32, 16, 25, 18, 22], bound_got, bound_want)))
	line!(Text.printed(Grade.grade_ints([28, 21, 73, 21, 16, 25, 14, 13], route_got, route_want)))
	line!(Text.printed(Grade.grade_ints([28, 21, 73, 26, 15, 31, 17, 2], map_int_got, map_int_want)))
	line!(Text.printed(Grade.grade_reals([28, 21, 73, 26, 15, 31, 21, 2], map_real_got, map_real_want, 0.0)))
	line!(Text.printed(Grade.grade_bools([28, 21, 73, 26, 15, 31, 32, 2], map_bool_got, map_bool_want)))
	line!(Text.printed(Grade.grade_rel([28, 21, 73, 15, 14, 2, 2, 2], at_got, at_want, F64.from_bits(4497644614860975944))))
	line!(Text.printed(Grade.grade_rel([28, 21, 73, 32, 13, 20, 17, 18, 22], behind_got, behind_want, F64.from_bits(4502148214488346440))))
	Ok({})
}
