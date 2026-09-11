# ViewYawSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Grade
import Maybe
import Pose
import Scenery
import Tuple
import ViewYaw

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

s0 : Pose.RiderState
s0 = { segment: 0, along: 0.0, across: 0.0, yaw: 0.0, v: 0.3, tilt: 0.0, heading: 0.0, gaze_yaw: 0.0, focus: 0.0 }

s1 : Pose.RiderState
s1 = { segment: 0, along: 0.0, across: 0.0, yaw: 0.0, v: 0.3, tilt: 0.125, heading: 4.5, gaze_yaw: 0.375, focus: 0.0 }

s2 : Pose.RiderState
s2 = { segment: 0, along: 0.0, across: 0.0, yaw: 0.0, v: 0.3, tilt: 0.5, heading: 1.0, gaze_yaw: (-0.25), focus: 0.0 }

s3 : Pose.RiderState
s3 = { segment: 0, along: 0.0, across: 0.0, yaw: 0.0, v: 0.3, tilt: (-0.75), heading: (-2.0), gaze_yaw: 0.125, focus: 0.0 }

s4 : Pose.RiderState
s4 = { segment: 0, along: 0.0, across: 0.0, yaw: 0.0, v: 0.3, tilt: 1.25, heading: 0.5, gaze_yaw: 0.0, focus: 0.0 }

frac_got : List(F64)
frac_got = [ViewYaw.head_yaw_frac]

frac_want : List(F64)
frac_want = [0.15]

yaw_got : List(F64)
yaw_got = [ViewYaw.view_yaw_for(s0), ViewYaw.view_yaw_for(s1), ViewYaw.view_yaw_for(s2), ViewYaw.view_yaw_for(s3), ViewYaw.view_yaw_for(s4)]

yaw_want : List(F64)
yaw_want = [0.0, 0.39375, (-0.175), 0.012500000000000011, 0.1875]

head_got : List(F64)
head_got = [ViewYaw.heading_for(s0), ViewYaw.heading_for(s1), ViewYaw.heading_for(s2), ViewYaw.heading_for(s3), ViewYaw.heading_for(s4)]

head_want : List(F64)
head_want = [0.0, 4.89375, 0.825, (-1.9875), 0.6875]

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
	line!(Grade.grade_reals("vy-frac", frac_got, frac_want, 0.0))
	line!(Grade.grade_reals("vy-yaw ", yaw_got, yaw_want, 0.0))
	line!(Grade.grade_reals("vy-head", head_got, head_want, 0.0))
	Ok({})
}
