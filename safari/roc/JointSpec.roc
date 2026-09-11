# JointSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Frame
import Grade
import Joint
import Maybe
import Scenery
import Tuple

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

outer_got : List(F64)
outer_got = [Joint.outer_cu(True, 4.0), Joint.outer_cu(False, 4.0), Joint.outer_cu(True, 7.5), Joint.outer_cu(False, 7.5)]

outer_want : List(F64)
outer_want = [0.0, 4.0, 0.0, 7.5]

pose : Frame.Pose
pose = { along: 100.0, across: 1.0, yaw: 0.2, hw: 2.0 }

behind_right : Frame.Mapper
behind_right = { is_chain: False, d: 0, prev_len: 300.0, prev_angle: 0.8726646259971648, prev_right: True, prev_w: 4.0 }

behind_left : Frame.Mapper
behind_left = { is_chain: False, d: 0, prev_len: 300.0, prev_angle: 1.2217304763960306, prev_right: False, prev_w: 4.0 }

here : Frame.Mapper
here = Frame.chain_map(0)

apex_got : List(F64)
apex_got = ({
	r = Joint.joint_apex([], [], pose, behind_right, here, 300.0, 4.0, 4.0, True)
	l = Joint.joint_apex([], [], pose, behind_left, here, 300.0, 4.0, 4.0, False)
	[r.right, r.forward, l.right, l.forward]
})

apex_want : List(F64)
apex_want = [17.297297467543466, (-100.43071597950589), 21.403438709482494, (-100.55298847633645)]

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
	line!(Grade.grade_reals("jt-outer", outer_got, outer_want, 0.0))
	line!(Grade.grade_rel("jt-apex ", apex_got, apex_want, F64.from_bits(4502148214488346440)))
	Ok({})
}
