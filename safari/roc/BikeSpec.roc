# BikeSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Bike
import Grade
import Pose
import Tuple

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

limit_got : List(F64)
limit_got = [Bike.yaw_per_tilt, Bike.max_lean]

limit_want : List(F64)
limit_want = [0.1, 0.3490658503988659]

s0 : Pose.RiderState
s0 = { segment: 3, along: 120.5, across: 2.25, yaw: 0.375, v: 0.8, tilt: 0.125, heading: 4.5, gaze_yaw: 0.625, focus: 0.25 }

s1 : Pose.RiderState
s1 = Bike.simulate_rider_step(s0, 0.05, 0.01)

s2 : Pose.RiderState
s2 = Bike.simulate_rider_step(s1, (0.0 - 0.02), 0.005)

s3 : Pose.RiderState
s3 = Bike.simulate_rider_step(s2, 0.0, 0.0)

exact_got : List(F64)
exact_got = [s1.yaw, s1.v, s1.tilt, s1.heading, s2.yaw, s2.v, s2.tilt, s2.heading, s3.yaw, s3.v, s3.tilt, s3.heading]

exact_want : List(F64)
exact_want = [0.3925, 0.81, 0.175, 4.5175, 0.40800000000000003, 0.8150000000000001, 0.155, 4.533, 0.42350000000000004, 0.8150000000000001, 0.155, 4.548500000000001]

carried_real_got : List(F64)
carried_real_got = [s1.gaze_yaw, s1.focus, s3.gaze_yaw, s3.focus]

carried_real_want : List(F64)
carried_real_want = [0.625, 0.25, 0.625, 0.25]

carried_int_got : List(I64)
carried_int_got = [s1.segment, s2.segment, s3.segment]

carried_int_want : List(I64)
carried_int_want = [3, 3, 3]

pos_got : List(F64)
pos_got = [s1.along, s1.across, s2.along, s2.across, s3.along, s3.across]

pos_want : List(F64)
pos_want = [121.25108639750266, 2.5532642799382796, 122.00167174017032, 2.8708278851774045, 122.7472448817898, 3.1999869508214647]

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

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_reals("bk-limit", limit_got, limit_want, 0.0))
	line!(Grade.grade_reals("bk-exact", exact_got, exact_want, 0.0))
	line!(Grade.grade_reals("bk-carry", carried_real_got, carried_real_want, 0.0))
	line!(Grade.grade_ints("bk-seg  ", carried_int_got, carried_int_want))
	line!(Grade.grade_rel("bk-pos  ", pos_got, pos_want, F64.from_bits(4472406533629990549)))
	Ok({})
}
