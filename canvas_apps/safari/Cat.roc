# Cat -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import lib.DeviceMath
import Num_
import lib.Trig

Cat :: [].{
	Cat : { along : F64, start_across : F64, mid_across : F64, end_across : F64, height : F64 }
	CatState : { pose_idx : I64, across : F64, lift : F64 }

	cat_height : F64
	cat_height = 1.7

	cat_along : F64
	cat_along = 105.0

	cat_road_gap : F64
	cat_road_gap = 1.5

	cat_beyond_tree : F64
	cat_beyond_tree = 2.0

	cat_head_x : F64
	cat_head_x = (0.0 - 0.48)

	land_hind_reach : F64
	land_hind_reach = (0.7 * cat_height)

	grass_toehold : F64
	grass_toehold = 0.3

	cat_make : F64, F64, F64 -> Cat.Cat
	cat_make = |lane_half, tree_offset, tree_along| ({
		tree_x = (lane_half + tree_offset)
		{ along: (tree_along + cat_beyond_tree), start_across: (tree_x + cat_road_gap), mid_across: ((0.0 - cat_head_x) * cat_height), end_across: ((0.0 - (lane_half + grass_toehold)) - land_hind_reach), height: cat_height }
	})

	enters_road_steps : F64
	enters_road_steps = 10.0

	frozen_steps : F64
	frozen_steps = 24.0

	escapes_steps : F64
	escapes_steps = 4.0

	cross_frames : F64
	cross_frames = ((enters_road_steps + frozen_steps) + escapes_steps)

	road_buffer : F64
	road_buffer = 3.0

	cat_in_danger : F64, F64 -> Bool
	cat_in_danger = |gap_along, v| ({
		e = (gap_along - road_buffer)
		(if (e > 0.0) { (e <= (cross_frames * v)) } else { False })
	})

	clamp01 : F64 -> F64
	clamp01 = |x| (if (x < 0.0) { 0.0 } else { (if (x > 1.0) { 1.0 } else { x }) })

	lerp : F64, F64, F64 -> F64
	lerp = |a, b, t| (a + ((b - a) * t))

	cross_t : F64, F64 -> F64
	cross_t = |gap, v| ({
		e = (gap - road_buffer)
		(if (e <= 0.0) { 1.0 } else { (if (v <= F64.from_bits(4517329193108106637)) { 0.0 } else { clamp01((1.0 - (e / (cross_frames * v)))) }) })
	})

	focus_peak : F64
	focus_peak = 1.8

	focus_ramp_down : F64
	focus_ramp_down = 83.0

	cat_smoothstep : F64 -> F64
	cat_smoothstep = |t| ((t * t) * (3.0 - (2.0 * t)))

	cat_focus : F64, F64 -> F64
	cat_focus = |gap_along, v| (if (v <= F64.from_bits(4517329193108106637)) { 0.0 } else { (if ((gap_along - road_buffer) > 0.0) { (cat_smoothstep(cross_t(gap_along, v)) * focus_peak) } else { cat_focus_past((gap_along - road_buffer), v) }) })

	cat_focus_past : F64, F64 -> F64
	cat_focus_past = |e, v| ((1.0 - cat_smoothstep(DeviceMath.real_min((((0.0 - e) / v) / focus_ramp_down), 1.0))) * focus_peak)

	stride_steps : F64
	stride_steps = 5.0

	gait : F64, F64 -> F64
	gait = |p, phase_len| ({
		c = Num_.round_real((phase_len / stride_steps))
		((p * (if (c < 1.0) { 1.0 } else { c })) * Trig.two_pi)
	})

	pose_rest : I64
	pose_rest = 0

	pose_stride : I64
	pose_stride = 1

	pose_frozen : I64
	pose_frozen = 2

	pose_coil : I64
	pose_coil = 3

	pose_flight : I64
	pose_flight = 4

	pose_land : I64
	pose_land = 5

	pose_collapse : I64
	pose_collapse = 6

	leap_pose_for : F64 -> I64
	leap_pose_for = |t| (if (t < 0.2) { pose_coil } else { (if (t < 0.7) { pose_flight } else { (if (t < 0.95) { pose_land } else { pose_collapse }) }) })

	leap_height : F64
	leap_height = 0.18

	pow075 : F64 -> F64
	pow075 = |b| DeviceMath.real_sqrt((b * DeviceMath.real_sqrt(b)))

	cat_state : Cat.Cat, F64, F64 -> Cat.CatState
	cat_state = |c, gap_along, v| ({
		step = (cross_t(gap_along, v) * cross_frames)
		escape_at = (enters_road_steps + frozen_steps)
		(if (step <= enters_road_steps) { cat_entering(c, step) } else { (if (step <= escape_at) { { pose_idx: pose_frozen, across: c.mid_across, lift: 0.0 } } else { cat_escaping(c, (step - escape_at)) }) })
	})

	cat_entering : Cat.Cat, F64 -> Cat.CatState
	cat_entering = |c, step| ({
		p = (step / enters_road_steps)
		{ pose_idx: (if (Trig.r_sin(gait(p, enters_road_steps)) > 0.0) { pose_stride } else { pose_rest }), across: lerp(c.start_across, c.mid_across, p), lift: 0.0 }
	})

	cat_escaping : Cat.Cat, F64 -> Cat.CatState
	cat_escaping = |c, raw_k| ({
		k = (if (raw_k > escapes_steps) { escapes_steps } else { raw_k })
		pose = leap_pose_for((k / escapes_steps))
		(if (k < 1.0) { { pose_idx: pose, across: c.mid_across, lift: 0.0 } } else { (if (k < 3.0) { cat_airborne(c, pose, ((k - 1.0) / 2.0)) } else { { pose_idx: pose, across: c.end_across, lift: 0.0 } }) })
	})

	cat_airborne : Cat.Cat, I64, F64 -> Cat.CatState
	cat_airborne = |c, pose, b| { pose_idx: pose, across: lerp(c.mid_across, c.end_across, pow075(b)), lift: (((leap_height * 4.0) * b) * (1.0 - b)) }
}
