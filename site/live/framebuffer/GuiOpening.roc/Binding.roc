# Binding -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText

Binding :: [].{
	Observable := { obs_id : CceText, obs_value : I64, obs_prev : I64, obs_dirty : Bool }.{
		is_eq : Binding.Observable, Binding.Observable -> Bool
		is_eq = |a, b| eq_Observable(a, b)
	}
	ObsText := { ot_id : CceText, ot_value : CceText, ot_prev : CceText, ot_dirty : Bool }.{
		is_eq : Binding.ObsText, Binding.ObsText -> Bool
		is_eq = |a, b| eq_ObsText(a, b)
	}
	BindingKind : [BindLabel(CceText), BindGauge(CceText), BindVisible(CceText), BindState(CceText), BindCustom(CceText, CceText)]
	Binding := { bd_source : CceText, bd_target : Binding.BindingKind, bd_transform : I64 }.{
		is_eq : Binding.Binding, Binding.Binding -> Bool
		is_eq = |a, b| eq_Binding(a, b)
	}
	BindingTable := { bt_observables : List(Binding.Observable), bt_obs_count : I64, bt_text_obs : List(Binding.ObsText), bt_text_count : I64, bt_bindings : List(Binding.Binding), bt_bind_count : I64 }.{
		is_eq : Binding.BindingTable, Binding.BindingTable -> Bool
		is_eq = |a, b| eq_BindingTable(a, b)
	}
	PendingUpdate := { pu_target_kind : Binding.BindingKind, pu_int_value : I64, pu_text_value : CceText }.{
		is_eq : Binding.PendingUpdate, Binding.PendingUpdate -> Bool
		is_eq = |a, b| eq_PendingUpdate(a, b)
	}

	binding_table_new : Binding.BindingTable
	binding_table_new = Binding.BindingTable.{ bt_observables: [], bt_obs_count: 0, bt_text_obs: [], bt_text_count: 0, bt_bindings: [], bt_bind_count: 0 }

	bt_clean : Binding.BindingTable -> Binding.BindingTable
	bt_clean = |bt| ({
		cleaned = bt_clean_obs(bt.bt_observables, 0, bt.bt_obs_count, [])
		cleaned_t = bt_clean_text(bt.bt_text_obs, 0, bt.bt_text_count, [])
		Binding.BindingTable.{ bt_observables: cleaned, bt_obs_count: bt.bt_obs_count, bt_text_obs: cleaned_t, bt_text_count: bt.bt_text_count, bt_bindings: bt.bt_bindings, bt_bind_count: bt.bt_bind_count }
	})

	bt_clean_obs : List(Binding.Observable), I64, I64, List(Binding.Observable) -> List(Binding.Observable)
	bt_clean_obs = |obs, i, n, acc| (if (i >= n) { acc } else { ({
		o = (List.get(obs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		cleaned = Binding.Observable.{ obs_id: o.obs_id, obs_value: o.obs_value, obs_prev: o.obs_value, obs_dirty: False }
		bt_clean_obs(obs, (i + 1), n, List.append(acc, cleaned))
	}) })

	bt_clean_text : List(Binding.ObsText), I64, I64, List(Binding.ObsText) -> List(Binding.ObsText)
	bt_clean_text = |obs, i, n, acc| (if (i >= n) { acc } else { ({
		o = (List.get(obs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		cleaned = Binding.ObsText.{ ot_id: o.ot_id, ot_value: o.ot_value, ot_prev: o.ot_value, ot_dirty: False }
		bt_clean_text(obs, (i + 1), n, List.append(acc, cleaned))
	}) })

	eq_Observable : Binding.Observable, Binding.Observable -> Bool
	eq_Observable = |ex, ey| ((((ex.obs_id == ey.obs_id) and (ex.obs_value == ey.obs_value)) and (ex.obs_prev == ey.obs_prev)) and (ex.obs_dirty == ey.obs_dirty))

	eq_ObsText : Binding.ObsText, Binding.ObsText -> Bool
	eq_ObsText = |ex, ey| ((((ex.ot_id == ey.ot_id) and (ex.ot_value == ey.ot_value)) and (ex.ot_prev == ey.ot_prev)) and (ex.ot_dirty == ey.ot_dirty))

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

	eq_Binding : Binding.Binding, Binding.Binding -> Bool
	eq_Binding = |ex, ey| (((ex.bd_source == ey.bd_source) and eq_BindingKind(ex.bd_target, ey.bd_target)) and (ex.bd_transform == ey.bd_transform))

	eq_BindingTable : Binding.BindingTable, Binding.BindingTable -> Bool
	eq_BindingTable = |ex, ey| ((((((ex.bt_observables == ey.bt_observables) and (ex.bt_obs_count == ey.bt_obs_count)) and (ex.bt_text_obs == ey.bt_text_obs)) and (ex.bt_text_count == ey.bt_text_count)) and (ex.bt_bindings == ey.bt_bindings)) and (ex.bt_bind_count == ey.bt_bind_count))

	eq_PendingUpdate : Binding.PendingUpdate, Binding.PendingUpdate -> Bool
	eq_PendingUpdate = |ex, ey| ((eq_BindingKind(ex.pu_target_kind, ey.pu_target_kind) and (ex.pu_int_value == ey.pu_int_value)) and (ex.pu_text_value == ey.pu_text_value))
}
