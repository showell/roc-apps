# VehicleLimitsSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Grade
import ListUtils
import Trig
import Tuple
import VehicleLimits

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

to_rad : F64 -> F64
to_rad = |d| (d * Trig.deg)

table_deg : List(F64)
table_deg = [15.0, 20.0, 30.0, 50.0, 70.0, 80.0]

table_want : List(F64)
table_want = [1.297, 0.84, 0.461, 0.222, 0.139, 0.117]

edge_deg : List(F64)
edge_deg = [14.5, 14.4, 15.4, 15.5, 30.5, 0.0, (-15.0), (-50.0)]

edge_want : List(F64)
edge_want = [1.297, 0.222, 1.297, 0.222, 0.222, 0.222, 0.222, 0.222]

env_got : List(F64)
env_got = [VehicleLimits.a_accel, VehicleLimits.v_max, VehicleLimits.approach_intersection_dist]

env_want : List(F64)
env_want = [0.01, 2.5, 60.0]

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
	line!(Grade.grade_reals("v-table", ListUtils.list_map(VehicleLimits.turn_speed, ListUtils.list_map(to_rad, table_deg)), table_want, 0.0))
	line!(Grade.grade_reals("v-edge ", ListUtils.list_map(VehicleLimits.turn_speed, ListUtils.list_map(to_rad, edge_deg)), edge_want, 0.0))
	line!(Grade.grade_reals("v-env  ", env_got, env_want, 0.0))
	Ok({})
}
