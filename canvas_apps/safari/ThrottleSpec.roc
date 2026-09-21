# ThrottleSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Arc
import Grade
import Pose
import Text
import Throttle
import lib.Trig
import VehicleLimits
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

fixed_got : List(F64)
fixed_got = [Throttle.tilt_hold, Throttle.brake_decay, (Throttle.tilt_hold / Trig.deg)]

fixed_want : List(F64)
fixed_want = [0.03490658503988659, 20.0, 2.0]

seg : World.Segment
seg = World.segment_at(0)

rider_at : F64, F64, F64, F64 -> Pose.RiderState
rider_at = |across, along, v, tilt| { segment: 0, along: along, across: across, yaw: 0.0, v: v, tilt: tilt, heading: 0.0, gaze_yaw: 0.0, focus: 0.0 }

rider : F64, F64, F64 -> Pose.RiderState
rider = |along, v, tilt| rider_at(0.0, along, v, tilt)

corner_got : List(F64)
corner_got = [Throttle.corner_brake(rider(498.4, 0.3, 0.0), seg, 0.222, 0.01), Throttle.corner_brake(rider(600.0, 0.3, 0.0), seg, 0.222, 0.01), Throttle.corner_brake(rider(0.0, 0.3, 0.0), seg, 0.222, (0.0 - 5.0))]

corner_want : List(F64)
corner_want = [0.0, 0.0, (-5.0)]

corner_min_got : List(Bool)
corner_min_got = [(Throttle.corner_brake(rider(0.0, 0.3, 0.0), seg, 0.222, 0.01) <= 0.01), (Throttle.corner_brake(rider(0.0, 0.3, 0.0), seg, 0.222, (0.0 - 5.0)) <= (0.0 - 5.0)), (Throttle.corner_brake(rider(0.0, 2.0, 0.0), seg, 0.222, 0.01) < Throttle.corner_brake(rider(0.0, 0.3, 0.0), seg, 0.222, 0.01))]

corner_min_want : List(Bool)
corner_min_want = [True, True, True]

cat_seg : World.Segment
cat_seg = World.segment_at(1)

cat_got : List(F64)
cat_got = [Throttle.cat_gate(rider(0.0, 0.3, 0.0), seg, 0.01), Throttle.cat_gate(rider(0.0, 0.3, 0.0), seg, (0.0 - 5.0)), Throttle.cat_gate(rider(120.0, 0.3, 0.0), cat_seg, 0.01), Throttle.cat_gate(rider(120.0, 0.3, 0.0), cat_seg, (0.0 - 5.0)), Throttle.cat_gate(rider(0.0, 0.3, 0.0), cat_seg, 0.01)]

cat_want : List(F64)
cat_want = [0.01, (-5.0), 0.0, (-5.0), 0.01]

outcome : Arc.Shoulder -> Arc.ArcOutcome
outcome = |sh| { shoulder: sh, forward: 10.0, crossed: False, end_across: 0.0, frames: 40.0 }

road_got : List(Bool)
road_got = [Throttle.stayed_on_road(outcome(ShoulderNone)), Throttle.stayed_on_road(outcome(ShoulderLeft)), Throttle.stayed_on_road(outcome(ShoulderRight))]

road_want : List(Bool)
road_want = [True, False, False]

soon : Arc.ArcOutcome
soon = { shoulder: ShoulderLeft, forward: 10.0, crossed: False, end_across: 0.0, frames: 2.0 }

brake_got : List(Bool)
brake_got = ({
	far = Throttle.shoulder_brake_at(rider(0.0, 1.0, 0.0), outcome(ShoulderLeft), 0.01)
	near_off = Throttle.shoulder_brake_at(rider(0.0, 1.0, 0.0), soon, 0.01)
	already = Throttle.shoulder_brake_at(rider(0.0, 1.0, 0.0), outcome(ShoulderLeft), (0.0 - 9.0))
	[(far < 0.0), (far > near_off), (already < (0.0 - 8.999))]
})

brake_want : List(Bool)
brake_want = [True, True, True]

instant : Arc.ArcOutcome
instant = { shoulder: ShoulderLeft, forward: 0.0, crossed: False, end_across: 0.0, frames: 0.0 }

zero_frames_got : List(Bool)
zero_frames_got = [(Throttle.shoulder_brake_at(rider(0.0, 1.0, 0.0), instant, 0.01) < 0.0)]

zero_frames_want : List(Bool)
zero_frames_want = [True]

clamp_got : List(F64)
clamp_got = [Throttle.clamp_v(rider(0.0, 0.3, 0.0), seg, 0.222, 1.0, False), Throttle.clamp_v(rider(0.0, 0.3, 0.0), seg, 0.222, 3.0, False), Throttle.clamp_v(rider(0.0, 0.3, 0.0), seg, 0.222, (0.0 - 1.0), False), Throttle.clamp_v(rider(0.0, 0.3, 0.0), seg, 0.222, 0.1, True), Throttle.clamp_v(rider(0.0, 0.3, 0.0), seg, 0.222, 0.5, True), Throttle.clamp_v(rider(0.0, 0.3, 0.0), seg, 0.222, 0.1, False)]

clamp_want : List(F64)
clamp_want = [1.0, 2.5, 0.0, 0.222, 0.5, 0.1]

decide : F64, F64, F64 -> F64
decide = |along, v, tilt| Throttle.get_forward_accel_decel(rider(along, v, tilt), seg)

whole_got : List(F64)
whole_got = [decide(0.0, 0.3, 0.0), decide(0.0, VehicleLimits.v_max, 0.0), decide(0.0, 0.0, 0.0)]

whole_want : List(F64)
whole_want = [0.01, 0.0, 0.01]

wide : F64 -> F64
wide = |tilt| Throttle.get_forward_accel_decel(rider_at(100.0, 0.0, 0.3, tilt), seg)

tilt_got : List(F64)
tilt_got = [wide((0.0 - 0.001)), wide((0.0 - Throttle.tilt_hold)), wide(((0.0 - Throttle.tilt_hold) - 0.5))]

tilt_want : List(F64)
tilt_want = [0.01, 0.0, 0.0]

compose_got : List(Bool)
compose_got = [(decide(0.0, 0.3, (Throttle.tilt_hold - 0.001)) < 0.0), (decide(0.0, 0.3, 0.001) > 0.0), (decide(0.0, 0.3, (0.0 - (Throttle.tilt_hold - 0.001))) < 0.0)]

compose_want : List(Bool)
compose_want = [True, True, True]

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_reals([14, 20, 73, 28, 17, 36, 13, 22, 2], fixed_got, fixed_want, F64.from_bits(4427486594234968593))))
	line!(Text.printed(Grade.grade_reals([14, 20, 73, 24, 16, 21, 18, 13, 21], corner_got, corner_want, 0.0)))
	line!(Text.printed(Grade.grade_bools([14, 20, 73, 24, 26, 17, 18, 2, 2], corner_min_got, corner_min_want)))
	line!(Text.printed(Grade.grade_reals([14, 20, 73, 24, 15, 14, 2, 2, 2], cat_got, cat_want, 0.0)))
	line!(Text.printed(Grade.grade_bools([14, 20, 73, 21, 16, 15, 22, 2, 2], road_got, road_want)))
	line!(Text.printed(Grade.grade_bools([14, 20, 73, 32, 21, 15, 34, 13, 2], brake_got, brake_want)))
	line!(Text.printed(Grade.grade_bools([14, 20, 73, 38, 13, 21, 16, 2, 2], zero_frames_got, zero_frames_want)))
	line!(Text.printed(Grade.grade_reals([14, 20, 73, 24, 23, 15, 26, 31, 2], clamp_got, clamp_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([14, 20, 73, 27, 20, 16, 23, 13, 2], whole_got, whole_want, F64.from_bits(4427486594234968593))))
	line!(Text.printed(Grade.grade_reals([14, 20, 73, 14, 17, 23, 14, 2, 2], tilt_got, tilt_want, F64.from_bits(4427486594234968593))))
	line!(Text.printed(Grade.grade_bools([14, 20, 73, 24, 16, 26, 31, 2, 2], compose_got, compose_want)))
	Ok({})
}
