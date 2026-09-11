# CanvasRollSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CanvasRoll
import Grade
import Pose
import Tuple

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

band_got : List(F64)
band_got = [CanvasRoll.roll_deadband]

band_want : List(F64)
band_want = [0.001]

tilt_in : List(F64)
tilt_in = [0.0, F64.from_bits(4532020583610935537), 0.0005, (-0.0005), 0.0009999, 0.001, (-0.001), 0.002, (-0.002), 0.35, (-0.42)]

roll_want : List(F64)
roll_want = [0.0, 0.0, 0.0, 0.0, 0.0, 0.001, (-0.001), 0.002, (-0.002), 0.35, (-0.42)]

as_rider : F64 -> Pose.RiderState
as_rider = |t| { segment: 0, along: 0.0, across: 0.0, yaw: 0.0, v: 0.3, tilt: t, heading: 0.0, gaze_yaw: 0.0, focus: 0.0 }

# roll_walk builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
roll_walk : I64 -> List(F64)
roll_walk = |i| roll_walk_acc(i, [])

roll_walk_acc : I64, List(F64) -> List(F64)
roll_walk_acc = |i, acc| (if (i >= U64.to_i64_wrap(List.len(tilt_in))) { acc } else { roll_walk_acc((i + 1), List.append(acc, CanvasRoll.rider_roll(as_rider((List.get(tilt_in, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))) })

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
	line!(Grade.grade_reals("cr-band", band_got, band_want, 0.0))
	line!(Grade.grade_reals("cr-roll", roll_walk(0), roll_want, 0.0))
	Ok({})
}
