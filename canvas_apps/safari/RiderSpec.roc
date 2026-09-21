# RiderSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import lib.DeviceMath
import Grade
import LeanSearch
import Pose
import Rider
import Text
import Throttle
import VehicleLimits
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

segs : List(World.Segment)
segs = [World.segment_at(0), World.segment_at(1), World.segment_at(2)]

seg : World.Segment
seg = World.segment_at(0)

rider : F64, F64, F64, F64 -> Pose.RiderState
rider = |along, across, v, tilt| { segment: 0, along: along, across: across, yaw: 0.0, v: v, tilt: tilt, heading: 0.0, gaze_yaw: 0.0, focus: 0.0 }

step_got : List(Bool)
step_got = ({
	d = Rider.decide(rider(0.0, 0.0, Pose.v_base, 0.0), seg)
	held = Rider.decide(rider(0.0, 0.0, Pose.v_base, 0.5), seg)
	[(DeviceMath.real_abs(d.tilt_step) <= LeanSearch.max_tilt_correction), (DeviceMath.real_abs(held.tilt_step) <= LeanSearch.max_tilt_correction), (d.accel <= (VehicleLimits.a_accel + F64.from_bits(4517329193108106637)))]
})

step_want : List(Bool)
step_want = [True, True, True]

leaned_got : List(Bool)
leaned_got = ({
	d = Rider.decide(rider(0.0, 0.0, Pose.v_base, 0.0), seg)
	same = Throttle.get_forward_accel_decel(Pose.with_tilt(rider(0.0, 0.0, Pose.v_base, 0.0), (0.0 + d.tilt_step)), seg)
	[(F64.to_bits(d.accel) == F64.to_bits(same))]
})

leaned_want : List(Bool)
leaned_want = [True]

at_seam : Pose.RiderState
at_seam = { segment: 0, along: 499.0, across: 0.5, yaw: 0.1, v: 1.25, tilt: 0.05, heading: 0.7, gaze_yaw: 0.3, focus: 0.4 }

crossed : Pose.RiderState
crossed = Rider.rider_state_for_next_segment(at_seam, segs)

carry_got : List(F64)
carry_got = [crossed.v, crossed.tilt, crossed.focus, crossed.gaze_yaw]

carry_want : List(F64)
carry_want = [1.25, 0.05, 0.4, 0.0]

turn_got : List(F64)
turn_got = [(crossed.heading - 0.7), (crossed.yaw - (0.1 - seg.exit_angle))]

turn_want : List(F64)
turn_want = [0.0, 0.0]

index_got : List(I64)
index_got = [crossed.segment, seg.exit_to]

index_want : List(I64)
index_want = [1, 1]

early_got : List(Bool)
early_got = ({
	far = Rider.rider_state_for_next_segment(rider(100.0, 0.0, Pose.v_base, 0.0), segs)
	[(DeviceMath.real_abs(far.across) >= (World.segment_at(1).width / 2.0))]
})

early_want : List(Bool)
early_want = [True]

resolve_got : List(I64)
resolve_got = [Rider.resolve_cross(rider(100.0, 0.0, Pose.v_base, 0.0), seg, segs).segment, Rider.resolve_cross(rider(499.0, 0.0, Pose.v_base, 0.0), seg, segs).segment]

resolve_want : List(I64)
resolve_want = [0, 1]

last_seg : World.Segment
last_seg = World.segment_at(18)

ended : F64, F64 -> Pose.RiderState
ended = |along, v| Rider.finish_clamp({ segment: 0, along: along, across: 0.0, yaw: 0.0, v: v, tilt: 0.0, heading: 0.0, gaze_yaw: 0.0, focus: 0.0 }, last_seg)

finish_got : List(F64)
finish_got = [ended(300.0, 0.5).along, ended(300.0, 0.5).v, ended(310.0, 0.5).along, ended(310.0, 0.5).v, ended(290.0, 0.05).along, ended(290.0, 0.05).v, ended(290.0, 0.5).along, ended(290.0, 0.5).v, ended(100.0, 0.05).along, ended(100.0, 0.05).v]

finish_want : List(F64)
finish_want = [300.0, 0.0, 300.0, 0.0, 300.0, 0.0, 290.0, 0.5, 100.0, 0.05]

done_got : List(Bool)
done_got = ({
	at_end = { segment: 0, along: 300.0, across: 0.0, yaw: 0.0, v: 0.0, tilt: 0.0, heading: 0.0, gaze_yaw: 0.0, focus: 0.0 }
	short = { segment: 0, along: 299.0, across: 0.0, yaw: 0.0, v: 0.0, tilt: 0.0, heading: 0.0, gaze_yaw: 0.0, focus: 0.0 }
	[Rider.is_finished(at_end, [World.segment_at(18)]), Rider.is_finished(short, [World.segment_at(18)]), last_seg.terminates, Rider.is_finished(rider(499.0, 0.0, Pose.v_base, 0.0), segs)]
})

done_want : List(Bool)
done_want = [True, False, True, False]

next : Pose.RiderState
next = Rider.get_next_rider_state(rider(0.0, 0.0, Pose.v_base, 0.0), segs)

frame_got : List(Bool)
frame_got = [(next.along > 0.0), (next.v > 0.0), (next.segment == 0), (DeviceMath.real_abs(next.across) < (seg.width / 2.0)), (next.v <= VehicleLimits.v_max)]

frame_want : List(Bool)
frame_want = [True, True, True, True, True]

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_bools([21, 22, 73, 19, 14, 13, 31, 2, 2], step_got, step_want)))
	line!(Text.printed(Grade.grade_bools([21, 22, 73, 23, 13, 15, 18, 13, 22], leaned_got, leaned_want)))
	line!(Text.printed(Grade.grade_reals([21, 22, 73, 24, 15, 21, 21, 30, 2], carry_got, carry_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([21, 22, 73, 14, 25, 21, 18, 2, 2], turn_got, turn_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([21, 22, 73, 17, 18, 22, 13, 36, 2], index_got, index_want)))
	line!(Text.printed(Grade.grade_bools([21, 22, 73, 13, 15, 21, 23, 30, 2], early_got, early_want)))
	line!(Text.printed(Grade.grade_ints([21, 22, 73, 21, 13, 19, 16, 23, 33], resolve_got, resolve_want)))
	line!(Text.printed(Grade.grade_reals([21, 22, 73, 28, 17, 18, 17, 19, 20], finish_got, finish_want, 0.0)))
	line!(Text.printed(Grade.grade_bools([21, 22, 73, 22, 16, 18, 13, 2, 2], done_got, done_want)))
	line!(Text.printed(Grade.grade_bools([21, 22, 73, 28, 21, 15, 26, 13, 2], frame_got, frame_want)))
	Ok({})
}
