# ArcSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Arc
import Bike
import Grade
import Pose
import World

fixed_got : List(F64)
fixed_got = [Arc.no_frames, Arc.straighten_margin, Arc.min_forward_progress]

fixed_want : List(F64)
fixed_want = [1000000000.0, 0.05, 25.0]

steps_got : List(I64)
steps_got = [Arc.turn_danger_steps]

steps_want : List(I64)
steps_want = [2000]

seg : World.Segment
seg = World.segment_at(0)

rider : F64, F64, F64 -> Pose.RiderState
rider = |across, tilt, v| { segment: 0, along: 0.0, across: across, yaw: 0.0, v: v, tilt: tilt, heading: 0.0, gaze_yaw: 0.0, focus: 0.0 }

side : Arc.ArcOutcome -> I64
side = |o| (match o.shoulder {
	ShoulderLeft => (-1)
	ShoulderNone => 0
	ShoulderRight => 1
})

straight : Arc.ArcOutcome
straight = Arc.project_arc(rider(0.0, 0.0, Pose.v_base), seg)

straight_got : List(F64)
straight_got = [straight.forward, straight.end_across, straight.frames]

straight_want : List(F64)
straight_want = [25.0, 0.0, 1000000000.0]

wide : Arc.ArcOutcome
wide = Arc.project_arc(rider(3.0, 0.0, Pose.v_base), seg)

wide_got : List(F64)
wide_got = [wide.forward, wide.end_across, wide.frames]

wide_want : List(F64)
wide_want = [25.0, 3.0, 1000000000.0]

stopped : Arc.ArcOutcome
stopped = Arc.project_arc(rider(0.0, 0.0, 0.0), seg)

stopped_got : List(F64)
stopped_got = [stopped.forward, stopped.end_across, stopped.frames]

stopped_want : List(F64)
stopped_want = [0.0, 0.0, 1000000000.0]

none_got : List(I64)
none_got = [side(straight), side(wide), side(stopped)]

none_want : List(I64)
none_want = [0, 0, 0]

crossed_got : List(Bool)
crossed_got = [straight.crossed, wide.crossed, stopped.crossed]

crossed_want : List(Bool)
crossed_want = [False, False, False]

leaning : Arc.ArcOutcome
leaning = Arc.project_arc(rider(0.0, 0.2, Pose.v_base), seg)

other_way : Arc.ArcOutcome
other_way = Arc.project_arc(rider(0.0, (0.0 - 0.2), Pose.v_base), seg)

leaving_got : List(I64)
leaving_got = [side(leaning), side(other_way)]

leaving_want : List(I64)
leaving_want = [1, (-1)]

left_got : List(Bool)
left_got = [(leaning.frames < Arc.no_frames), (leaning.frames < I64.to_f64(Arc.turn_danger_steps)), (leaning.frames > 0.0), (leaning.forward <= Arc.min_forward_progress), (leaning.end_across > 0.0), (other_way.end_across < 0.0), (other_way.frames < Arc.no_frames)]

left_want : List(Bool)
left_want = [True, True, True, True, True, True, True]

mirror_got : List(F64)
mirror_got = [(leaning.frames - other_way.frames), (leaning.end_across + other_way.end_across)]

mirror_want : List(F64)
mirror_want = [0.0, 0.0]

mirror_fwd_got : List(F64)
mirror_fwd_got = [(leaning.forward - other_way.forward)]

mirror_fwd_want : List(F64)
mirror_fwd_want = [0.0]

step_got : List(F64)
step_got = (
	{
		a = Bike.simulate_rider_step(rider(0.0, 0.0, Pose.v_base), 0.0, 0.0)
		b = Bike.simulate_rider_step(rider(0.0, 0.0, Pose.v_base), 0.5, 0.25)
		[a.across, a.yaw, a.heading, a.tilt, a.v, b.tilt, b.v, b.yaw, b.heading, Bike.yaw_per_tilt]
	}
)

step_want : List(F64)
step_want = [0.0, 0.0, 0.0, 0.0, 0.3, 0.5, 0.55, 0.05, 0.05, 0.1]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "ar-fixed ",
			got: fixed_got,
			want: fixed_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "ar-steps ",
			got: steps_got,
			want: steps_want,
		}),
		Grade.reals({
			name: "ar-straig",
			got: straight_got,
			want: straight_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "ar-wide  ",
			got: wide_got,
			want: wide_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "ar-stop  ",
			got: stopped_got,
			want: stopped_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "ar-none  ",
			got: none_got,
			want: none_want,
		}),
		Grade.bools({
			name: "ar-cross ",
			got: crossed_got,
			want: crossed_want,
		}),
		Grade.ints({
			name: "ar-side  ",
			got: leaving_got,
			want: leaving_want,
		}),
		Grade.bools({
			name: "ar-left  ",
			got: left_got,
			want: left_want,
		}),
		Grade.reals({
			name: "ar-mirror",
			got: mirror_got,
			want: mirror_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "ar-mfwd  ",
			got: mirror_fwd_got,
			want: mirror_fwd_want,
			tol: F64.from_bits(4517329193108106637),
		}),
		Grade.reals({
			name: "ar-step  ",
			got: step_got,
			want: step_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
