# Animation -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import ListUtils
import Quaternion
import Spline

Animation :: [].{
	ThrobberKind : [ThrobSpin, ThrobPulse, ThrobBounce, ThrobBar]
	Throbber : { thr_kind : Animation.ThrobberKind, thr_period : I64, thr_elapsed : I64, thr_phase : I64, thr_size : I64, thr_color : I64, thr_active : Bool }
	Transition : { tr_prop : Str, tr_from : I64, tr_to : I64, tr_duration : I64, tr_elapsed : I64, tr_easing : I64, tr_done : Bool }
	Keyframe : { kf_time : I64, kf_value : I64 }
	KeyframeSeq : { ks_frames : List(Animation.Keyframe), ks_count : I64, ks_elapsed : I64, ks_duration : I64, ks_looping : Bool, ks_done : Bool }
	AnimEntry : { ae_id : Str, ae_transition : Animation.Transition }
	AnimSet : { as_entries : List(Animation.AnimEntry), as_count : I64, as_throbbers : List(Animation.Throbber), as_throb_count : I64 }

	throbber_spin : I64, I64, I64 -> Animation.Throbber
	throbber_spin = |period, size, color| { thr_kind: ThrobSpin, thr_period: period, thr_elapsed: 0, thr_phase: 0, thr_size: size, thr_color: color, thr_active: True }

	throbber_pulse : I64, I64, I64 -> Animation.Throbber
	throbber_pulse = |period, size, color| { thr_kind: ThrobPulse, thr_period: period, thr_elapsed: 0, thr_phase: 0, thr_size: size, thr_color: color, thr_active: True }

	throbber_bounce : I64, I64, I64 -> Animation.Throbber
	throbber_bounce = |period, size, color| { thr_kind: ThrobBounce, thr_period: period, thr_elapsed: 0, thr_phase: 0, thr_size: size, thr_color: color, thr_active: True }

	throbber_bar : I64, I64, I64 -> Animation.Throbber
	throbber_bar = |period, size, color| { thr_kind: ThrobBar, thr_period: period, thr_elapsed: 0, thr_phase: 0, thr_size: size, thr_color: color, thr_active: True }

	throbber_tick : Animation.Throbber, I64 -> Animation.Throbber
	throbber_tick = |thr, dt| (if thr.thr_active { ({
		new_elapsed = (thr.thr_elapsed + dt)
		wrapped = (if (new_elapsed >= thr.thr_period) { (new_elapsed - thr.thr_period) } else { new_elapsed })
		phase = (if (thr.thr_period > 0) { I64.div_trunc_by((wrapped * 1000), thr.thr_period) } else { 0 })
		{ thr_kind: thr.thr_kind, thr_period: thr.thr_period, thr_elapsed: wrapped, thr_phase: phase, thr_size: thr.thr_size, thr_color: thr.thr_color, thr_active: True }
	}) } else { thr })

	throbber_start : Animation.Throbber -> Animation.Throbber
	throbber_start = |thr| { thr_kind: thr.thr_kind, thr_period: thr.thr_period, thr_elapsed: 0, thr_phase: 0, thr_size: thr.thr_size, thr_color: thr.thr_color, thr_active: True }

	throbber_stop : Animation.Throbber -> Animation.Throbber
	throbber_stop = |thr| { thr_kind: thr.thr_kind, thr_period: thr.thr_period, thr_elapsed: thr.thr_elapsed, thr_phase: thr.thr_phase, thr_size: thr.thr_size, thr_color: thr.thr_color, thr_active: False }

	throbber_spin_angle : Animation.Throbber -> I64
	throbber_spin_angle = |thr| I64.div_trunc_by((thr.thr_phase * 360), 1000)

	throbber_pulse_scale : Animation.Throbber -> I64
	throbber_pulse_scale = |thr| ({
		half = (if (thr.thr_phase < 500) { (thr.thr_phase * 2) } else { ((1000 - thr.thr_phase) * 2) })
		(500 + I64.div_trunc_by(half, 2))
	})

	throbber_bounce_offset : Animation.Throbber -> I64
	throbber_bounce_offset = |thr| ({
		up = (if (thr.thr_phase < 500) { (thr.thr_phase * 2) } else { ((1000 - thr.thr_phase) * 2) })
		I64.div_trunc_by((thr.thr_size * up), 1000)
	})

	throbber_bar_position : Animation.Throbber, I64 -> I64
	throbber_bar_position = |thr, width| I64.div_trunc_by((thr.thr_phase * width), 1000)

	transition_new : Str, I64, I64, I64, I64 -> Animation.Transition
	transition_new = |prop, from, to, duration, easing| { tr_prop: prop, tr_from: from, tr_to: to, tr_duration: duration, tr_elapsed: 0, tr_easing: easing, tr_done: False }

	transition_tick : Animation.Transition, I64 -> Animation.Transition
	transition_tick = |tr, dt| (if tr.tr_done { tr } else { ({
		new_elapsed = (tr.tr_elapsed + dt)
		(if (new_elapsed >= tr.tr_duration) { { tr_prop: tr.tr_prop, tr_from: tr.tr_from, tr_to: tr.tr_to, tr_duration: tr.tr_duration, tr_elapsed: tr.tr_duration, tr_easing: tr.tr_easing, tr_done: True } } else { { tr_prop: tr.tr_prop, tr_from: tr.tr_from, tr_to: tr.tr_to, tr_duration: tr.tr_duration, tr_elapsed: new_elapsed, tr_easing: tr.tr_easing, tr_done: False } })
	}) })

	transition_value : Animation.Transition -> I64
	transition_value = |tr| (if tr.tr_done { tr.tr_to } else { ({
		t = (if (tr.tr_duration > 0) { I64.div_trunc_by((tr.tr_elapsed * 1000), tr.tr_duration) } else { 1000 })
		(tr.tr_from + I64.div_trunc_by(((tr.tr_to - tr.tr_from) * t), 1000))
	}) })

	transition_reset : Animation.Transition, I64, I64 -> Animation.Transition
	transition_reset = |tr, from, to| { tr_prop: tr.tr_prop, tr_from: from, tr_to: to, tr_duration: tr.tr_duration, tr_elapsed: 0, tr_easing: tr.tr_easing, tr_done: False }

	keyframe : I64, I64 -> Animation.Keyframe
	keyframe = |time, value| { kf_time: time, kf_value: value }

	keyframe_seq : List(Animation.Keyframe), Bool -> Animation.KeyframeSeq
	keyframe_seq = |frames, looping| ({
		count = U64.to_i64_wrap(List.len(frames))
		dur = (if (count > 0) { (List.get(frames, I64.to_u64_wrap((count - 1))) ?? crash("list-at out of range")).kf_time } else { 0 })
		{ ks_frames: frames, ks_count: count, ks_elapsed: 0, ks_duration: dur, ks_looping: looping, ks_done: False }
	})

	keyframe_tick : Animation.KeyframeSeq, I64 -> Animation.KeyframeSeq
	keyframe_tick = |ks, dt| (if ks.ks_done { ks } else { ({
		new_elapsed = (ks.ks_elapsed + dt)
		(if (new_elapsed >= ks.ks_duration) { (if ks.ks_looping { { ks_frames: ks.ks_frames, ks_count: ks.ks_count, ks_elapsed: (new_elapsed - ks.ks_duration), ks_duration: ks.ks_duration, ks_looping: True, ks_done: False } } else { { ks_frames: ks.ks_frames, ks_count: ks.ks_count, ks_elapsed: ks.ks_duration, ks_duration: ks.ks_duration, ks_looping: False, ks_done: True } }) } else { { ks_frames: ks.ks_frames, ks_count: ks.ks_count, ks_elapsed: new_elapsed, ks_duration: ks.ks_duration, ks_looping: ks.ks_looping, ks_done: False } })
	}) })

	keyframe_value : Animation.KeyframeSeq -> I64
	keyframe_value = |ks| (if (ks.ks_count == 0) { 0 } else { kf_interp(ks.ks_frames, ks.ks_elapsed, 0, ks.ks_count) })

	kf_interp : List(Animation.Keyframe), I64, I64, I64 -> I64
	kf_interp = |frames, t, i, n| (if ((i + 1) >= n) { (List.get(frames, I64.to_u64_wrap((n - 1))) ?? crash("list-at out of range")).kf_value } else { ({
		cur = (List.get(frames, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		next = (List.get(frames, I64.to_u64_wrap((i + 1))) ?? crash("list-at out of range"))
		(if (t < next.kf_time) { ({
			seg_dur = (next.kf_time - cur.kf_time)
			(if (seg_dur <= 0) { cur.kf_value } else { ({
				local_t = I64.div_trunc_by(((t - cur.kf_time) * 1000), seg_dur)
				(cur.kf_value + I64.div_trunc_by(((next.kf_value - cur.kf_value) * local_t), 1000))
			}) })
		}) } else { kf_interp(frames, t, (i + 1), n) })
	}) })

	anim_set_new : Animation.AnimSet
	anim_set_new = { as_entries: [], as_count: 0, as_throbbers: [], as_throb_count: 0 }

	anim_set_add : Animation.AnimSet, Str, Animation.Transition -> Animation.AnimSet
	anim_set_add = |as_, id, tr| ({
		entry = { ae_id: id, ae_transition: tr }
		{ as_entries: List.append(as_.as_entries, entry), as_count: (as_.as_count + 1), as_throbbers: as_.as_throbbers, as_throb_count: as_.as_throb_count }
	})

	anim_set_add_throbber : Animation.AnimSet, Animation.Throbber -> Animation.AnimSet
	anim_set_add_throbber = |as_, thr| { as_entries: as_.as_entries, as_count: as_.as_count, as_throbbers: List.append(as_.as_throbbers, thr), as_throb_count: (as_.as_throb_count + 1) }

	anim_set_tick : Animation.AnimSet, I64 -> Animation.AnimSet
	anim_set_tick = |as_, dt| ({
		entries = ListUtils.map_list(({
			machine__1 = dt
			|machine__2| lam_0(machine__1, machine__2)
		}), as_.as_entries)
		throbbers = ListUtils.map_list(({
			machine__3 = dt
			|machine__4| lam_1(machine__3, machine__4)
		}), as_.as_throbbers)
		{ as_entries: entries, as_count: as_.as_count, as_throbbers: throbbers, as_throb_count: as_.as_throb_count }
	})

	anim_set_all_done : Animation.AnimSet -> Bool
	anim_set_all_done = |as_| anim_all_done_loop(as_.as_entries, 0, as_.as_count)

	anim_all_done_loop : List(Animation.AnimEntry), I64, I64 -> Bool
	anim_all_done_loop = |entries, i, n| (if (i >= n) { True } else { ({
		e = (List.get(entries, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if e.ae_transition.tr_done { anim_all_done_loop(entries, (i + 1), n) } else { False })
	}) })

	ease_linear_id : I64
	ease_linear_id = 0

	ease_quad_in_id : I64
	ease_quad_in_id = 1

	ease_quad_out_id : I64
	ease_quad_out_id = 2

	ease_bounce_id : I64
	ease_bounce_id = 3

	ease_spline : List(Quaternion.Vec3), I64 -> I64
	ease_spline = |control_points, t| ({
		result = Spline.spline_eval(control_points, I64.to_f64(t))
		F64.to_i64_wrap(result.vy)
	})

	ease_catmull_rom : Quaternion.Vec3, Quaternion.Vec3, Quaternion.Vec3, Quaternion.Vec3, I64 -> I64
	ease_catmull_rom = |p0, p1, p2, p3, t| ({
		result = Spline.catmull_rom(p0, p1, p2, p3, I64.to_f64(t))
		F64.to_i64_wrap(result.vy)
	})

	eq_ThrobberKind : Animation.ThrobberKind, Animation.ThrobberKind -> Bool
	eq_ThrobberKind = |ex, ey| (match ex {
		ThrobSpin => (match ey {
			ThrobSpin => True
			_ => False
		})
		ThrobPulse => (match ey {
			ThrobPulse => True
			_ => False
		})
		ThrobBounce => (match ey {
			ThrobBounce => True
			_ => False
		})
		ThrobBar => (match ey {
			ThrobBar => True
			_ => False
		})
	})

	lam_0 : I64, Animation.AnimEntry -> Animation.AnimEntry
	lam_0 = |dt, e| { ae_id: e.ae_id, ae_transition: transition_tick(e.ae_transition, dt) }

	lam_1 : I64, Animation.Throbber -> Animation.Throbber
	lam_1 = |dt, thr| throbber_tick(thr, dt)
}
