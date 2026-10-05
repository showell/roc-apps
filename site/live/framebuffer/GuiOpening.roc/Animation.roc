# Animation -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText
import ListUtils

Animation :: [].{
	ThrobberKind : [ThrobSpin, ThrobPulse, ThrobBounce, ThrobBar]
	Throbber := { thr_kind : Animation.ThrobberKind, thr_period : I64, thr_elapsed : I64, thr_phase : I64, thr_size : I64, thr_color : I64, thr_active : Bool }.{
		is_eq : Animation.Throbber, Animation.Throbber -> Bool
		is_eq = |a, b| eq_Throbber(a, b)
	}
	Transition := { tr_prop : CceText, tr_from : I64, tr_to : I64, tr_duration : I64, tr_elapsed : I64, tr_easing : I64, tr_done : Bool }.{
		is_eq : Animation.Transition, Animation.Transition -> Bool
		is_eq = |a, b| eq_Transition(a, b)
	}
	Keyframe := { kf_time : I64, kf_value : I64 }.{
		is_eq : Animation.Keyframe, Animation.Keyframe -> Bool
		is_eq = |a, b| eq_Keyframe(a, b)
	}
	KeyframeSeq := { ks_frames : List(Animation.Keyframe), ks_count : I64, ks_elapsed : I64, ks_duration : I64, ks_looping : Bool, ks_done : Bool }.{
		is_eq : Animation.KeyframeSeq, Animation.KeyframeSeq -> Bool
		is_eq = |a, b| eq_KeyframeSeq(a, b)
	}
	AnimEntry := { ae_id : CceText, ae_transition : Animation.Transition }.{
		is_eq : Animation.AnimEntry, Animation.AnimEntry -> Bool
		is_eq = |a, b| eq_AnimEntry(a, b)
	}
	AnimSet := { as_entries : List(Animation.AnimEntry), as_count : I64, as_throbbers : List(Animation.Throbber), as_throb_count : I64 }.{
		is_eq : Animation.AnimSet, Animation.AnimSet -> Bool
		is_eq = |a, b| eq_AnimSet(a, b)
	}

	throbber_tick : Animation.Throbber, I64 -> Animation.Throbber
	throbber_tick = |thr, dt| (if thr.thr_active { ({
		new_elapsed : I64
		new_elapsed = (thr.thr_elapsed + dt)
		wrapped : I64
		wrapped = (if (new_elapsed >= thr.thr_period) { (new_elapsed - thr.thr_period) } else { new_elapsed })
		phase : I64
		phase = (if (thr.thr_period > 0) { I64.div_trunc_by((wrapped * 1000), thr.thr_period) } else { 0 })
		Animation.Throbber.{ thr_kind: thr.thr_kind, thr_period: thr.thr_period, thr_elapsed: wrapped, thr_phase: phase, thr_size: thr.thr_size, thr_color: thr.thr_color, thr_active: True }
	}) } else { thr })

	transition_tick : Animation.Transition, I64 -> Animation.Transition
	transition_tick = |tr, dt| (if tr.tr_done { tr } else { ({
		new_elapsed : I64
		new_elapsed = (tr.tr_elapsed + dt)
		(if (new_elapsed >= tr.tr_duration) { Animation.Transition.{ tr_prop: tr.tr_prop, tr_from: tr.tr_from, tr_to: tr.tr_to, tr_duration: tr.tr_duration, tr_elapsed: tr.tr_duration, tr_easing: tr.tr_easing, tr_done: True } } else { Animation.Transition.{ tr_prop: tr.tr_prop, tr_from: tr.tr_from, tr_to: tr.tr_to, tr_duration: tr.tr_duration, tr_elapsed: new_elapsed, tr_easing: tr.tr_easing, tr_done: False } })
	}) })

	anim_set_new : Animation.AnimSet
	anim_set_new = Animation.AnimSet.{ as_entries: [], as_count: 0, as_throbbers: [], as_throb_count: 0 }

	anim_set_tick : Animation.AnimSet, I64 -> Animation.AnimSet
	anim_set_tick = |as_, dt| ({
		entries = ListUtils.map_list(({
			machine__1 = dt
			|machine__2| lam_4(machine__1, machine__2)
		}), as_.as_entries)
		throbbers = ListUtils.map_list(({
			machine__3 = dt
			|machine__4| lam_5(machine__3, machine__4)
		}), as_.as_throbbers)
		Animation.AnimSet.{ as_entries: entries, as_count: as_.as_count, as_throbbers: throbbers, as_throb_count: as_.as_throb_count }
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

	eq_Throbber : Animation.Throbber, Animation.Throbber -> Bool
	eq_Throbber = |ex, ey| ((((((eq_ThrobberKind(ex.thr_kind, ey.thr_kind) and (ex.thr_period == ey.thr_period)) and (ex.thr_elapsed == ey.thr_elapsed)) and (ex.thr_phase == ey.thr_phase)) and (ex.thr_size == ey.thr_size)) and (ex.thr_color == ey.thr_color)) and (ex.thr_active == ey.thr_active))

	eq_Transition : Animation.Transition, Animation.Transition -> Bool
	eq_Transition = |ex, ey| (((((((ex.tr_prop == ey.tr_prop) and (ex.tr_from == ey.tr_from)) and (ex.tr_to == ey.tr_to)) and (ex.tr_duration == ey.tr_duration)) and (ex.tr_elapsed == ey.tr_elapsed)) and (ex.tr_easing == ey.tr_easing)) and (ex.tr_done == ey.tr_done))

	eq_Keyframe : Animation.Keyframe, Animation.Keyframe -> Bool
	eq_Keyframe = |ex, ey| ((ex.kf_time == ey.kf_time) and (ex.kf_value == ey.kf_value))

	eq_KeyframeSeq : Animation.KeyframeSeq, Animation.KeyframeSeq -> Bool
	eq_KeyframeSeq = |ex, ey| ((((((ex.ks_frames == ey.ks_frames) and (ex.ks_count == ey.ks_count)) and (ex.ks_elapsed == ey.ks_elapsed)) and (ex.ks_duration == ey.ks_duration)) and (ex.ks_looping == ey.ks_looping)) and (ex.ks_done == ey.ks_done))

	eq_AnimEntry : Animation.AnimEntry, Animation.AnimEntry -> Bool
	eq_AnimEntry = |ex, ey| ((ex.ae_id == ey.ae_id) and eq_Transition(ex.ae_transition, ey.ae_transition))

	eq_AnimSet : Animation.AnimSet, Animation.AnimSet -> Bool
	eq_AnimSet = |ex, ey| ((((ex.as_entries == ey.as_entries) and (ex.as_count == ey.as_count)) and (ex.as_throbbers == ey.as_throbbers)) and (ex.as_throb_count == ey.as_throb_count))

	lam_4 : I64, Animation.AnimEntry -> Animation.AnimEntry
	lam_4 = |dt, e| Animation.AnimEntry.{ ae_id: e.ae_id, ae_transition: transition_tick(e.ae_transition, dt) }

	lam_5 : I64, Animation.Throbber -> Animation.Throbber
	lam_5 = |dt, thr| throbber_tick(thr, dt)
}
