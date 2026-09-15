# GazeSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Gaze
import Grade
import Pose
import Text
import Trig
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

fixed_got : List(F64)
fixed_got = [Gaze.gaze_look_dist, Gaze.focus_decay, Gaze.pig_gaze_speed, Gaze.pig_gaze_settle_dist, (Gaze.gaze_release_angle / Trig.deg), (Gaze.gaze_swivel_rate / Trig.deg), (Gaze.gaze_return_rate / Trig.deg), (Gaze.gaze_return_snap / Trig.deg), (Gaze.eyes_on_road_yaw / Trig.deg), Gaze.gaze_return_ease]

fixed_want : List(F64)
fixed_want = [150.0, 0.0012, 0.2, 25.0, 35.0, 4.0, 0.2, 0.02, 6.0, 0.05]

smooth_got : List(F64)
smooth_got = [Gaze.smoothstep(0.0), Gaze.smoothstep(0.5), Gaze.smoothstep(1.0), Gaze.gaze_focus(0.5)]

smooth_want : List(F64)
smooth_want = [0.0, 0.5, 1.0, 0.5]

plain : World.Segment
plain = World.segment_at(0)

distracting : World.Segment
distracting = World.segment_at(2)

rider : F64, F64 -> Pose.RiderState
rider = |along, yaw| { segment: 2, along: along, across: 0.0, yaw: yaw, v: Pose.v_base, tilt: 0.0, heading: 0.0, gaze_yaw: 0.0, focus: 0.0 }

legs_got : List(Bool)
legs_got = [plain.pigs_distract, distracting.pigs_distract]

legs_want : List(Bool)
legs_want = [False, True]

looking_got : List(Bool)
looking_got = [Gaze.pig_ahead(rider(200.0, 0.0), plain).looking, Gaze.pig_ahead(rider(200.0, (10.0 * Trig.deg)), distracting).looking, Gaze.pig_ahead(rider(100.0, 0.0), distracting).looking, Gaze.pig_ahead(rider(341.0, 0.0), distracting).looking, Gaze.pig_ahead(rider(200.0, 0.0), distracting).looking, Gaze.no_look.looking]

looking_want : List(Bool)
looking_want = [False, False, False, False, True, False]

dist_got : List(F64)
dist_got = [Gaze.pig_ahead(rider(200.0, 0.0), distracting).dist, Gaze.pig_ahead(rider(100.0, 0.0), distracting).dist, Gaze.no_look.dist]

dist_want : List(F64)
dist_want = [142.0, 0.0, 0.0]

want_got : List(Bool)
want_got = ({
	far = Gaze.desired_gaze(rider(200.0, 0.0), distracting)
	near = Gaze.desired_gaze(rider(320.0, 0.0), distracting)
	[(far > 0.0), (near > far), (F64.to_bits(Gaze.desired_gaze(rider(200.0, 0.0), plain)) == F64.to_bits(0.0))]
})

want_want : List(Bool)
want_want = [True, True, True]

head : F64, F64 -> Pose.RiderState
head = |gaze_yaw, along| { segment: 2, along: along, across: 0.0, yaw: 0.0, v: Pose.v_base, tilt: 0.0, heading: 0.0, gaze_yaw: gaze_yaw, focus: 0.0 }

swivel_got : List(F64)
swivel_got = [(Gaze.next_gaze_yaw(head(0.0, 200.0), 1.0) - Gaze.gaze_swivel_rate), (Gaze.next_gaze_yaw(head(0.0, 200.0), (0.0 - 1.0)) + Gaze.gaze_swivel_rate), (Gaze.next_gaze_yaw(head(0.0, 200.0), (Gaze.gaze_swivel_rate / 2.0)) - (Gaze.gaze_swivel_rate / 2.0))]

swivel_want : List(F64)
swivel_want = [0.0, 0.0, 0.0]

return_got : List(Bool)
return_got = ({
	big = Gaze.next_gaze_yaw(head((30.0 * Trig.deg), 200.0), 0.0)
	small = Gaze.next_gaze_yaw(head((2.0 * Trig.deg), 200.0), 0.0)
	[(big < (30.0 * Trig.deg)), (big > 0.0), (small < (2.0 * Trig.deg)), (small > 0.0), (((30.0 * Trig.deg) - big) > ((2.0 * Trig.deg) - small))]
})

return_want : List(Bool)
return_want = [True, True, True, True, True]

snap_got : List(F64)
snap_got = [Gaze.next_gaze_yaw(head(Gaze.gaze_return_snap, 200.0), 0.0), Gaze.next_gaze_yaw(head((0.0 - Gaze.gaze_return_snap), 200.0), 0.0), Gaze.next_gaze_yaw(head(0.0, 200.0), 0.0)]

snap_want : List(F64)
snap_want = [0.0, 0.0, 0.0]

focused : F64, F64 -> Pose.RiderState
focused = |focus, gaze_yaw| { segment: 2, along: 200.0, across: 0.0, yaw: 0.0, v: Pose.v_base, tilt: 0.0, heading: 0.0, gaze_yaw: gaze_yaw, focus: focus }

focus_got : List(Bool)
focus_got = ({
	rising = Gaze.next_focus(focused(0.0, (20.0 * Trig.deg)), (20.0 * Trig.deg))
	held = Gaze.next_focus(focused(0.9, (1.0 * Trig.deg)), (1.0 * Trig.deg))
	easing = Gaze.next_focus(focused(0.9, 0.0), 0.0)
	[(rising > 0.0), (held >= 0.9), (easing < 0.9), (easing > 0.0)]
})

focus_want : List(Bool)
focus_want = [True, True, True, True]

focus_ends_got : List(F64)
focus_ends_got = [Gaze.next_focus(focused(0.0, 0.0), 0.0), Gaze.next_focus(focused(0.0, (90.0 * Trig.deg)), (90.0 * Trig.deg))]

focus_ends_want : List(F64)
focus_ends_want = [0.0, 1.0]

gawk_got : List(Bool)
gawk_got = [Gaze.gawk_engaged(rider(200.0, 0.0), plain), Gaze.gawk_engaged(rider(100.0, 0.0), distracting), Gaze.gawk_engaged(rider(200.0, 0.0), distracting), Gaze.gawk_engaged(rider(341.0, 0.0), distracting)]

gawk_want : List(Bool)
gawk_want = [False, False, True, True]

outlast_got : List(Bool)
outlast_got = ({
	looks = Gaze.pig_ahead(rider(341.0, 0.0), distracting).looking
	[(looks == False), Gaze.gawk_engaged(rider(341.0, 0.0), distracting)]
})

outlast_want : List(Bool)
outlast_want = [True, True]

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_reals([29, 38, 73, 28, 17, 36, 13, 22, 2], fixed_got, fixed_want, F64.from_bits(4427486594234968593))))
	line!(Text.printed(Grade.grade_reals([29, 38, 73, 19, 26, 16, 16, 14, 20], smooth_got, smooth_want, 0.0)))
	line!(Text.printed(Grade.grade_bools([29, 38, 73, 23, 13, 29, 19, 2, 2], legs_got, legs_want)))
	line!(Text.printed(Grade.grade_bools([29, 38, 73, 23, 16, 16, 34, 2, 2], looking_got, looking_want)))
	line!(Text.printed(Grade.grade_reals([29, 38, 73, 22, 17, 19, 14, 2, 2], dist_got, dist_want, 0.0)))
	line!(Text.printed(Grade.grade_bools([29, 38, 73, 27, 15, 18, 14, 2, 2], want_got, want_want)))
	line!(Text.printed(Grade.grade_reals([29, 38, 73, 19, 27, 17, 33, 13, 23], swivel_got, swivel_want, 0.0)))
	line!(Text.printed(Grade.grade_bools([29, 38, 73, 21, 13, 14, 25, 21, 18], return_got, return_want)))
	line!(Text.printed(Grade.grade_reals([29, 38, 73, 19, 18, 15, 31, 2, 2], snap_got, snap_want, 0.0)))
	line!(Text.printed(Grade.grade_bools([29, 38, 73, 28, 16, 24, 25, 19, 2], focus_got, focus_want)))
	line!(Text.printed(Grade.grade_reals([29, 38, 73, 28, 13, 18, 22, 19, 2], focus_ends_got, focus_ends_want, 0.0)))
	line!(Text.printed(Grade.grade_bools([29, 38, 73, 29, 15, 27, 34, 2, 2], gawk_got, gawk_want)))
	line!(Text.printed(Grade.grade_bools([29, 38, 73, 16, 25, 14, 23, 19, 14], outlast_got, outlast_want)))
	Ok({})
}
