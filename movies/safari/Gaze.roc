# Gaze -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import DeviceMath
import Pigs
import Pose
import Scenery
import Trig
import World

Gaze :: [].{
	PigLook : { looking : Bool, dist : F64 }
	GazeBrake : { engaged : Bool, accel : F64 }

	gaze_look_dist : F64
	gaze_look_dist = 150.0

	gaze_release_angle : F64
	gaze_release_angle = (35.0 * Trig.deg)

	gaze_swivel_rate : F64
	gaze_swivel_rate = (4.0 * Trig.deg)

	gaze_return_rate : F64
	gaze_return_rate = (0.2 * Trig.deg)

	gaze_return_ease : F64
	gaze_return_ease = 0.05

	gaze_return_snap : F64
	gaze_return_snap = (0.02 * Trig.deg)

	focus_decay : F64
	focus_decay = 0.0012

	pig_gaze_speed : F64
	pig_gaze_speed = 0.2

	pig_gaze_settle_dist : F64
	pig_gaze_settle_dist = 25.0

	eyes_on_road_yaw : F64
	eyes_on_road_yaw = (6.0 * Trig.deg)

	smoothstep : F64 -> F64
	smoothstep = |t| ((t * t) * (3.0 - (2.0 * t)))

	gaze_focus : F64 -> F64
	gaze_focus = |f| smoothstep(f)

	no_look : Gaze.PigLook
	no_look = { looking: False, dist: 0.0 }

	pig_ahead : Pose.RiderState, World.Segment -> Gaze.PigLook
	pig_ahead = |state, seg| (if (seg.pigs_distract == False) { no_look } else { (if (DeviceMath.real_abs(state.yaw) > eyes_on_road_yaw) { no_look } else { pig_ahead_near(state, seg) }) })

	pig_ahead_near : Pose.RiderState, World.Segment -> Gaze.PigLook
	pig_ahead_near = |state, seg| ({
		pig = Pigs.gaze_pig(seg.length, (seg.width / 2.0))
		dist = (pig.along - state.along)
		(if (dist > gaze_look_dist) { no_look } else { pig_ahead_bearing(state, pig, dist) })
	})

	pig_ahead_bearing : Pose.RiderState, Scenery.Critter, F64 -> Gaze.PigLook
	pig_ahead_bearing = |state, pig, dist| ({
		bearing = (Trig.r_atan2((pig.across - state.across), dist) - state.yaw)
		(if (DeviceMath.real_abs(bearing) >= gaze_release_angle) { no_look } else { { looking: True, dist: dist } })
	})

	desired_gaze : Pose.RiderState, World.Segment -> F64
	desired_gaze = |state, seg| (if (pig_ahead(state, seg).looking == False) { 0.0 } else { desired_gaze_at(state, Pigs.gaze_pig(seg.length, (seg.width / 2.0))) })

	desired_gaze_at : Pose.RiderState, Scenery.Critter -> F64
	desired_gaze_at = |state, pig| (Trig.r_atan2((pig.across - state.across), (pig.along - state.along)) - state.yaw)

	next_gaze_yaw : Pose.RiderState, F64 -> F64
	next_gaze_yaw = |state, want| (if ((F64.to_bits(want) == F64.to_bits(0.0)) == False) { (state.gaze_yaw + DeviceMath.real_max((0.0 - gaze_swivel_rate), DeviceMath.real_min(gaze_swivel_rate, (want - state.gaze_yaw)))) } else { (if (DeviceMath.real_abs(state.gaze_yaw) <= gaze_return_snap) { 0.0 } else { (state.gaze_yaw - (Trig.r_sign(state.gaze_yaw) * DeviceMath.real_min(gaze_return_rate, (DeviceMath.real_abs(state.gaze_yaw) * gaze_return_ease)))) }) })

	next_focus : Pose.RiderState, F64 -> F64
	next_focus = |state, gaze_yaw| (if (F64.to_bits(gaze_yaw) == F64.to_bits(0.0)) { DeviceMath.real_max(0.0, (state.focus - focus_decay)) } else { DeviceMath.real_max(state.focus, DeviceMath.real_min((DeviceMath.real_abs(gaze_yaw) / gaze_release_angle), 1.0)) })

	next_rider_gaze : Pose.RiderState, List(World.Segment) -> Pose.RiderState
	next_rider_gaze = |state, segs| ({
		want = desired_gaze(state, (List.get(segs, I64.to_u64_wrap(state.segment)) ?? crash("list-at out of range")))
		gy = next_gaze_yaw(state, want)
		{ segment: state.segment, along: state.along, across: state.across, yaw: state.yaw, v: state.v, tilt: state.tilt, heading: state.heading, gaze_yaw: gy, focus: next_focus(state, gy) }
	})

	gawk_engaged : Pose.RiderState, World.Segment -> Bool
	gawk_engaged = |state, seg| (if (seg.pigs_distract == False) { False } else { (state.along >= (Pigs.gaze_pig(seg.length, (seg.width / 2.0)).along - gaze_look_dist)) })

	pig_gaze_brake : Pose.RiderState, World.Segment -> Gaze.GazeBrake
	pig_gaze_brake = |state, seg| (if (gawk_engaged(state, seg) == False) { { engaged: False, accel: 0.0 } } else { (if (state.v <= pig_gaze_speed) { { engaged: True, accel: 0.0 } } else { pig_gaze_brake_easing(state, seg) }) })

	pig_gaze_brake_easing : Pose.RiderState, World.Segment -> Gaze.GazeBrake
	pig_gaze_brake_easing = |state, seg| ({
		d = ((Pigs.gaze_pig(seg.length, (seg.width / 2.0)).along - state.along) - pig_gaze_settle_dist)
		{ engaged: True, accel: (((pig_gaze_speed * pig_gaze_speed) - (state.v * state.v)) / (2.0 * DeviceMath.real_max(d, 1.0))) }
	})
}
