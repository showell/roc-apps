# VehicleLimitsSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Grade
import ListUtils
import lib.Trig
import VehicleLimits

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

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "v-table",
			got: ListUtils.list_map(VehicleLimits.turn_speed, ListUtils.list_map(to_rad, table_deg)),
			want: table_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "v-edge ",
			got: ListUtils.list_map(VehicleLimits.turn_speed, ListUtils.list_map(to_rad, edge_deg)),
			want: edge_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "v-env  ",
			got: env_got,
			want: env_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
