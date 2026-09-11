# BikeSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Bike
import Grade
import Pose

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

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_reals("bk-limit", limit_got, limit_want, 0.0))
	line!(Grade.grade_reals("bk-exact", exact_got, exact_want, 0.0))
	line!(Grade.grade_reals("bk-carry", carried_real_got, carried_real_want, 0.0))
	line!(Grade.grade_ints("bk-seg  ", carried_int_got, carried_int_want))
	line!(Grade.grade_rel("bk-pos  ", pos_got, pos_want, F64.from_bits(4472406533629990549)))
	Ok({})
}
