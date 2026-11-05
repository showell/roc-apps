# BikeSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Acceleration
import Angle
import Bike
import Grade
import World
import Pose
import Speed

limit_got : List(F64)
limit_got = [Bike.yaw_per_tilt, Bike.max_lean.to_radians()]

limit_want : List(F64)
limit_want = [0.1, 0.3490658503988659]

s0 : Pose.RiderState
s0 = {
	segment: World.SegmentIndex.number(3),
	along: 120.5,
	across: 2.25,
	yaw: Angle.Turn.radians(0.375),
	speed: Speed.metres_a_step(0.8),
	tilt: Angle.Lean.radians(0.125),
	heading: Angle.Bearing.radians(4.5),
	gaze_yaw: Angle.Turn.radians(0.625),
	focus: 0.25,
}

s1 : Pose.RiderState
s1 = Bike.simulate_rider_step(
	s0,
	{ lean_step: Angle.Lean.radians(0.05), accel: Acceleration.metres_a_step_each_step(0.01) },
)

s2 : Pose.RiderState
s2 = Bike.simulate_rider_step(
	s1,
	{
		lean_step: Angle.Lean.radians(0.0 - 0.02),
		accel: Acceleration.metres_a_step_each_step(0.005),
	},
)

s3 : Pose.RiderState
s3 = Bike.simulate_rider_step(s2, { lean_step: Angle.upright, accel: Acceleration.steady })

exact_got : List(F64)
exact_got = [
	s1,
	s2,
	s3,
].join_map(
	|s| [
		s.yaw.to_radians(),
		s.speed.to_metres_a_step(),
		s.tilt.to_radians(),
		s.heading.to_radians(),
	],
)

exact_want : List(F64)
exact_want = [
	0.3925,
	0.81,
	0.175,
	4.5175,
	0.40800000000000003,
	0.8150000000000001,
	0.155,
	4.533,
	0.42350000000000004,
	0.8150000000000001,
	0.155,
	4.548500000000001,
]

carried_real_got : List(F64)
carried_real_got = [
	s1.gaze_yaw.to_radians(),
	s1.focus,
	s3.gaze_yaw.to_radians(),
	s3.focus,
]

carried_real_want : List(F64)
carried_real_want = [0.625, 0.25, 0.625, 0.25]

carried_int_got : List(I64)
carried_int_got = [
	s1.segment.to_i64(),
	s2.segment.to_i64(),
	s3.segment.to_i64(),
]

carried_int_want : List(I64)
carried_int_want = [3, 3, 3]

pos_got : List(F64)
pos_got = [
	s1.along,
	s1.across,
	s2.along,
	s2.across,
	s3.along,
	s3.across,
]

pos_want : List(F64)
pos_want = [
	121.25108639750266,
	2.5532642799382796,
	122.00167174017032,
	2.8708278851774045,
	122.7472448817898,
	3.1999869508214647,
]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "bk-limit",
			got: limit_got,
			want: limit_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "bk-exact",
			got: exact_got,
			want: exact_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "bk-carry",
			got: carried_real_got,
			want: carried_real_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "bk-seg  ",
			got: carried_int_got,
			want: carried_int_want,
		}),
		Grade.rel({
			name: "bk-pos  ",
			got: pos_got,
			want: pos_want,
			tol: F64.from_bits(4472406533629990549),
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
