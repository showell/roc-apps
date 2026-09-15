# Binding -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Binding :: [].{
	Observable : { obs_id : Str, obs_value : I64, obs_prev : I64, obs_dirty : Bool }
	ObsText : { ot_id : Str, ot_value : Str, ot_prev : Str, ot_dirty : Bool }
	BindingKind : [BindLabel(Str), BindGauge(Str), BindVisible(Str), BindState(Str), BindCustom(Str, Str)]
	Binding : { bd_source : Str, bd_target : Binding.BindingKind, bd_transform : I64 }
	BindingTable : { bt_observables : List(Binding.Observable), bt_obs_count : I64, bt_text_obs : List(Binding.ObsText), bt_text_count : I64, bt_bindings : List(Binding.Binding), bt_bind_count : I64 }
	PendingUpdate : { pu_target_kind : Binding.BindingKind, pu_int_value : I64, pu_text_value : Str }

	observable : Str, I64 -> Binding.Observable
	observable = |id, val| { obs_id: id, obs_value: val, obs_prev: val, obs_dirty: False }

	obs_text : Str, Str -> Binding.ObsText
	obs_text = |id, val| { ot_id: id, ot_value: val, ot_prev: val, ot_dirty: False }

	binding_table_new : Binding.BindingTable
	binding_table_new = { bt_observables: [], bt_obs_count: 0, bt_text_obs: [], bt_text_count: 0, bt_bindings: [], bt_bind_count: 0 }

	bt_add_obs : Binding.BindingTable, Binding.Observable -> Binding.BindingTable
	bt_add_obs = |bt, obs| { bt_observables: List.append(bt.bt_observables, obs), bt_obs_count: (bt.bt_obs_count + 1), bt_text_obs: bt.bt_text_obs, bt_text_count: bt.bt_text_count, bt_bindings: bt.bt_bindings, bt_bind_count: bt.bt_bind_count }

	bt_add_text_obs : Binding.BindingTable, Binding.ObsText -> Binding.BindingTable
	bt_add_text_obs = |bt, ot| { bt_observables: bt.bt_observables, bt_obs_count: bt.bt_obs_count, bt_text_obs: List.append(bt.bt_text_obs, ot), bt_text_count: (bt.bt_text_count + 1), bt_bindings: bt.bt_bindings, bt_bind_count: bt.bt_bind_count }

	bt_add_binding : Binding.BindingTable, Binding.Binding -> Binding.BindingTable
	bt_add_binding = |bt, b| { bt_observables: bt.bt_observables, bt_obs_count: bt.bt_obs_count, bt_text_obs: bt.bt_text_obs, bt_text_count: bt.bt_text_count, bt_bindings: List.append(bt.bt_bindings, b), bt_bind_count: (bt.bt_bind_count + 1) }

	bt_set : Binding.BindingTable, Str, I64 -> Binding.BindingTable
	bt_set = |bt, id, val| ({
		updated = bt_set_obs(bt.bt_observables, id, val, 0, bt.bt_obs_count, [])
		{ bt_observables: updated, bt_obs_count: bt.bt_obs_count, bt_text_obs: bt.bt_text_obs, bt_text_count: bt.bt_text_count, bt_bindings: bt.bt_bindings, bt_bind_count: bt.bt_bind_count }
	})

	bt_set_obs : List(Binding.Observable), Str, I64, I64, I64, List(Binding.Observable) -> List(Binding.Observable)
	bt_set_obs = |obs, id, val, i, n, acc| (if (i >= n) { acc } else { ({
		o = (List.get(obs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (o.obs_id == id) { ({
			updated = { obs_id: o.obs_id, obs_value: val, obs_prev: o.obs_value, obs_dirty: True }
			bt_set_obs(obs, id, val, (i + 1), n, List.append(acc, updated))
		}) } else { bt_set_obs(obs, id, val, (i + 1), n, List.append(acc, o)) })
	}) })

	bt_set_text : Binding.BindingTable, Str, Str -> Binding.BindingTable
	bt_set_text = |bt, id, val| ({
		updated = bt_set_text_obs(bt.bt_text_obs, id, val, 0, bt.bt_text_count, [])
		{ bt_observables: bt.bt_observables, bt_obs_count: bt.bt_obs_count, bt_text_obs: updated, bt_text_count: bt.bt_text_count, bt_bindings: bt.bt_bindings, bt_bind_count: bt.bt_bind_count }
	})

	bt_set_text_obs : List(Binding.ObsText), Str, Str, I64, I64, List(Binding.ObsText) -> List(Binding.ObsText)
	bt_set_text_obs = |obs, id, val, i, n, acc| (if (i >= n) { acc } else { ({
		o = (List.get(obs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (o.ot_id == id) { ({
			updated = { ot_id: o.ot_id, ot_value: val, ot_prev: o.ot_value, ot_dirty: True }
			bt_set_text_obs(obs, id, val, (i + 1), n, List.append(acc, updated))
		}) } else { bt_set_text_obs(obs, id, val, (i + 1), n, List.append(acc, o)) })
	}) })

	bt_get : Binding.BindingTable, Str -> I64
	bt_get = |bt, id| bt_get_loop(bt.bt_observables, id, 0, bt.bt_obs_count)

	bt_get_loop : List(Binding.Observable), Str, I64, I64 -> I64
	bt_get_loop = |obs, id, i, n| (if (i >= n) { 0 } else { ({
		o = (List.get(obs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (o.obs_id == id) { o.obs_value } else { bt_get_loop(obs, id, (i + 1), n) })
	}) })

	bt_get_text : Binding.BindingTable, Str -> Str
	bt_get_text = |bt, id| bt_get_text_loop(bt.bt_text_obs, id, 0, bt.bt_text_count)

	bt_get_text_loop : List(Binding.ObsText), Str, I64, I64 -> Str
	bt_get_text_loop = |obs, id, i, n| (if (i >= n) { "" } else { ({
		o = (List.get(obs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (o.ot_id == id) { o.ot_value } else { bt_get_text_loop(obs, id, (i + 1), n) })
	}) })

	bt_is_dirty : Binding.BindingTable, Str -> Bool
	bt_is_dirty = |bt, id| bt_dirty_loop(bt.bt_observables, id, 0, bt.bt_obs_count)

	bt_dirty_loop : List(Binding.Observable), Str, I64, I64 -> Bool
	bt_dirty_loop = |obs, id, i, n| (if (i >= n) { False } else { ({
		o = (List.get(obs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (o.obs_id == id) { o.obs_dirty } else { bt_dirty_loop(obs, id, (i + 1), n) })
	}) })

	bt_collect_dirty : Binding.BindingTable -> List(Binding.PendingUpdate)
	bt_collect_dirty = |bt| bt_collect_loop(bt.bt_bindings, bt.bt_observables, bt.bt_obs_count, 0, bt.bt_bind_count, [])

	bt_collect_loop : List(Binding.Binding), List(Binding.Observable), I64, I64, I64, List(Binding.PendingUpdate) -> List(Binding.PendingUpdate)
	bt_collect_loop = |bindings, obs, obs_count, i, n, acc| (if (i >= n) { acc } else { ({
		b = (List.get(bindings, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		dirty = bt_source_dirty(obs, b.bd_source, 0, obs_count)
		(if dirty { ({
			val = bt_source_value(obs, b.bd_source, 0, obs_count)
			pu = { pu_target_kind: b.bd_target, pu_int_value: val, pu_text_value: "" }
			bt_collect_loop(bindings, obs, obs_count, (i + 1), n, List.append(acc, pu))
		}) } else { bt_collect_loop(bindings, obs, obs_count, (i + 1), n, acc) })
	}) })

	bt_source_dirty : List(Binding.Observable), Str, I64, I64 -> Bool
	bt_source_dirty = |obs, id, i, n| (if (i >= n) { False } else { ({
		o = (List.get(obs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (o.obs_id == id) { o.obs_dirty } else { bt_source_dirty(obs, id, (i + 1), n) })
	}) })

	bt_source_value : List(Binding.Observable), Str, I64, I64 -> I64
	bt_source_value = |obs, id, i, n| (if (i >= n) { 0 } else { ({
		o = (List.get(obs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (o.obs_id == id) { o.obs_value } else { bt_source_value(obs, id, (i + 1), n) })
	}) })

	bt_clean : Binding.BindingTable -> Binding.BindingTable
	bt_clean = |bt| ({
		cleaned = bt_clean_obs(bt.bt_observables, 0, bt.bt_obs_count, [])
		cleaned_t = bt_clean_text(bt.bt_text_obs, 0, bt.bt_text_count, [])
		{ bt_observables: cleaned, bt_obs_count: bt.bt_obs_count, bt_text_obs: cleaned_t, bt_text_count: bt.bt_text_count, bt_bindings: bt.bt_bindings, bt_bind_count: bt.bt_bind_count }
	})

	bt_clean_obs : List(Binding.Observable), I64, I64, List(Binding.Observable) -> List(Binding.Observable)
	bt_clean_obs = |obs, i, n, acc| (if (i >= n) { acc } else { ({
		o = (List.get(obs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		cleaned = { obs_id: o.obs_id, obs_value: o.obs_value, obs_prev: o.obs_value, obs_dirty: False }
		bt_clean_obs(obs, (i + 1), n, List.append(acc, cleaned))
	}) })

	bt_clean_text : List(Binding.ObsText), I64, I64, List(Binding.ObsText) -> List(Binding.ObsText)
	bt_clean_text = |obs, i, n, acc| (if (i >= n) { acc } else { ({
		o = (List.get(obs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		cleaned = { ot_id: o.ot_id, ot_value: o.ot_value, ot_prev: o.ot_value, ot_dirty: False }
		bt_clean_text(obs, (i + 1), n, List.append(acc, cleaned))
	}) })

	bind_to_label : Str, Str -> Binding.Binding
	bind_to_label = |source, widget_id| { bd_source: source, bd_target: BindLabel(widget_id), bd_transform: 0 }

	bind_to_gauge : Str, Str -> Binding.Binding
	bind_to_gauge = |source, widget_id| { bd_source: source, bd_target: BindGauge(widget_id), bd_transform: 0 }

	bind_to_visible : Str, Str -> Binding.Binding
	bind_to_visible = |source, widget_id| { bd_source: source, bd_target: BindVisible(widget_id), bd_transform: 0 }

	bind_to_state : Str, Str -> Binding.Binding
	bind_to_state = |source, widget_id| { bd_source: source, bd_target: BindState(widget_id), bd_transform: 0 }

	eq_BindingKind : Binding.BindingKind, Binding.BindingKind -> Bool
	eq_BindingKind = |ex, ey| (match ex {
		BindLabel(exf0) => (match ey {
			BindLabel(eyf0) => (exf0 == eyf0)
			_ => False
		})
		BindGauge(exf0) => (match ey {
			BindGauge(eyf0) => (exf0 == eyf0)
			_ => False
		})
		BindVisible(exf0) => (match ey {
			BindVisible(eyf0) => (exf0 == eyf0)
			_ => False
		})
		BindState(exf0) => (match ey {
			BindState(eyf0) => (exf0 == eyf0)
			_ => False
		})
		BindCustom(exf0, exf1) => (match ey {
			BindCustom(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
			_ => False
		})
	})
}
