# Orchestrator -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Animation
import Binding
import BoxModel
import CceText
import Event
import Overlay
import Sound
import Surface
import Theme
import Widget

Orchestrator :: [].{
	InputSource : [IsKeyboard, IsMouse, IsNetwork(CceText), IsTimer(CceText, I64), IsCustom(CceText)]
	InputEntry := { ie_source : Orchestrator.InputSource, ie_enabled : Bool }.{
		is_eq : Orchestrator.InputEntry, Orchestrator.InputEntry -> Bool
		is_eq = |a, b| eq_InputEntry(a, b)
	}
	UiTimer := { ut_name : CceText, ut_interval : I64, ut_elapsed : I64, ut_repeating : Bool, ut_fired : Bool }.{
		is_eq : Orchestrator.UiTimer, Orchestrator.UiTimer -> Bool
		is_eq = |a, b| eq_UiTimer(a, b)
	}
	AppState := { app_root : Widget.WidgetNode, app_theme : Theme.Theme, app_compositor : Surface.Compositor, app_overlays : Overlay.OverlayStack, app_bindings : Binding.BindingTable, app_animations : Animation.AnimSet, app_sounds : Sound.SoundQueue, app_handlers : Event.HandlerTable, app_timers : List(Orchestrator.UiTimer), app_timer_count : I64, app_focused : CceText, app_hovered : CceText, app_dirty : Bool, app_frame : I64, app_time : I64 }.{
		is_eq : Orchestrator.AppState, Orchestrator.AppState -> Bool
		is_eq = |a, b| eq_AppState(a, b)
	}
	TimerTickResult := { ttr_timers : List(Orchestrator.UiTimer), ttr_fired : List(CceText) }.{
		is_eq : Orchestrator.TimerTickResult, Orchestrator.TimerTickResult -> Bool
		is_eq = |a, b| eq_TimerTickResult(a, b)
	}

	app_new : Widget.WidgetNode, Theme.Theme, I64, I64 -> Orchestrator.AppState
	app_new = |root, theme, w, h| Orchestrator.AppState.{ app_root: root, app_theme: theme, app_compositor: Surface.compositor_new(w, h, theme.th_palette.pal_bg), app_overlays: Overlay.overlay_stack_new, app_bindings: Binding.binding_table_new, app_animations: Animation.anim_set_new, app_sounds: Sound.sound_queue_new(16), app_handlers: Event.handler_table_new, app_timers: [], app_timer_count: 0, app_focused: "", app_hovered: "", app_dirty: True, app_frame: 0, app_time: 0 }

	app_tick : Orchestrator.AppState, I64, List(Event.Event) -> Orchestrator.AppState
	app_tick = |app_, dt, events| ({
		app2 = orch_tick_timers(app_, dt)
		app3 = orch_dispatch_events(app2, events, 0, U64.to_i64_wrap(List.len(events)))
		app4 = orch_tick_animations(app3, dt)
		app5 = orch_tick_overlays(app4, dt)
		app6 = orch_apply_bindings(app5)
		app7 = orch_relayout(app6)
		orch_advance_frame(app7, dt)
	})

	orch_tick_timers : Orchestrator.AppState, I64 -> Orchestrator.AppState
	orch_tick_timers = |app_, dt| ({
		result = orch_tick_timer_list(app_.app_timers, dt, 0, app_.app_timer_count, [], [])
		Orchestrator.AppState.{ app_root: app_.app_root, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: app_.app_overlays, app_bindings: app_.app_bindings, app_animations: app_.app_animations, app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: result.ttr_timers, app_timer_count: U64.to_i64_wrap(List.len(result.ttr_timers)), app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: (if (U64.to_i64_wrap(List.len(result.ttr_fired)) > 0) { True } else { app_.app_dirty }), app_frame: app_.app_frame, app_time: app_.app_time }
	})

	orch_tick_timer_list : List(Orchestrator.UiTimer), I64, I64, I64, List(Orchestrator.UiTimer), List(CceText) -> Orchestrator.TimerTickResult
	orch_tick_timer_list = |timers, dt, i, n, acc_timers, acc_fired| (if (i >= n) { Orchestrator.TimerTickResult.{ ttr_timers: acc_timers, ttr_fired: acc_fired } } else { ({
		t = (List.get(timers, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		new_elapsed : I64
		new_elapsed = (t.ut_elapsed + dt)
		(if (new_elapsed >= t.ut_interval) { (if t.ut_repeating { ({
			reset = Orchestrator.UiTimer.{ ut_name: t.ut_name, ut_interval: t.ut_interval, ut_elapsed: (new_elapsed - t.ut_interval), ut_repeating: True, ut_fired: True }
			orch_tick_timer_list(timers, dt, (i + 1), n, List.append(acc_timers, reset), List.append(acc_fired, t.ut_name))
		}) } else { orch_tick_timer_list(timers, dt, (i + 1), n, acc_timers, List.append(acc_fired, t.ut_name)) }) } else { ({
			updated = Orchestrator.UiTimer.{ ut_name: t.ut_name, ut_interval: t.ut_interval, ut_elapsed: new_elapsed, ut_repeating: t.ut_repeating, ut_fired: False }
			orch_tick_timer_list(timers, dt, (i + 1), n, List.append(acc_timers, updated), acc_fired)
		}) })
	}) })

	orch_dispatch_events : Orchestrator.AppState, List(Event.Event), I64, I64 -> Orchestrator.AppState
	orch_dispatch_events = |app_, events, i, n| (if (i >= n) { app_ } else { ({
		ev = (List.get(events, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		app2 = orch_dispatch_one(app_, ev)
		orch_dispatch_events(app2, events, (i + 1), n)
	}) })

	orch_dispatch_one : Orchestrator.AppState, Event.Event -> Orchestrator.AppState
	orch_dispatch_one = |app_, ev| ({
		_targeted = (if (ev.ev_target == "") { (match ev.ev_kind {
			EvMouseDown(x, y, _btn) => Event.event_retarget(ev, Event.event_target_from_mouse(app_.app_root, x, y))
			EvMouseUp(x, y, _btn) => Event.event_retarget(ev, Event.event_target_from_mouse(app_.app_root, x, y))
			EvMouseMove(x, y) => Event.event_retarget(ev, Event.event_target_from_mouse(app_.app_root, x, y))
			EvKeyDown(_k, _m) => Event.event_retarget(ev, app_.app_focused)
			EvKeyUp(_k, _m) => Event.event_retarget(ev, app_.app_focused)
			EvScroll(x, y, _d) => Event.event_retarget(ev, Event.event_target_from_mouse(app_.app_root, x, y))
			EvFocus(_id) => ev
			EvBlur(_id) => ev
			EvResize(_w, _h) => ev
			EvTimer(_name) => ev
			EvNetwork(_ch, _len) => ev
			EvCustom(_name, _d) => ev
		}) } else { ev })
		Orchestrator.AppState.{ app_root: app_.app_root, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: app_.app_overlays, app_bindings: app_.app_bindings, app_animations: app_.app_animations, app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: app_.app_timers, app_timer_count: app_.app_timer_count, app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: True, app_frame: app_.app_frame, app_time: app_.app_time }
	})

	orch_tick_animations : Orchestrator.AppState, I64 -> Orchestrator.AppState
	orch_tick_animations = |app_, dt| Orchestrator.AppState.{ app_root: app_.app_root, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: app_.app_overlays, app_bindings: app_.app_bindings, app_animations: Animation.anim_set_tick(app_.app_animations, dt), app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: app_.app_timers, app_timer_count: app_.app_timer_count, app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: app_.app_dirty, app_frame: app_.app_frame, app_time: app_.app_time }

	orch_tick_overlays : Orchestrator.AppState, I64 -> Orchestrator.AppState
	orch_tick_overlays = |app_, dt| Orchestrator.AppState.{ app_root: app_.app_root, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: Overlay.overlay_stack_tick(app_.app_overlays, dt), app_bindings: app_.app_bindings, app_animations: app_.app_animations, app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: app_.app_timers, app_timer_count: app_.app_timer_count, app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: app_.app_dirty, app_frame: app_.app_frame, app_time: app_.app_time }

	orch_apply_bindings : Orchestrator.AppState -> Orchestrator.AppState
	orch_apply_bindings = |app_| ({
		cleaned = Binding.bt_clean(app_.app_bindings)
		Orchestrator.AppState.{ app_root: app_.app_root, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: app_.app_overlays, app_bindings: cleaned, app_animations: app_.app_animations, app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: app_.app_timers, app_timer_count: app_.app_timer_count, app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: app_.app_dirty, app_frame: app_.app_frame, app_time: app_.app_time }
	})

	orch_relayout : Orchestrator.AppState -> Orchestrator.AppState
	orch_relayout = |app_| (if app_.app_dirty { ({
		container = BoxModel.layout_rect(0, 0, app_.app_compositor.comp_width, app_.app_compositor.comp_height)
		laid_out = Widget.widget_layout(app_.app_root, app_.app_theme, container)
		Orchestrator.AppState.{ app_root: laid_out, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: app_.app_overlays, app_bindings: app_.app_bindings, app_animations: app_.app_animations, app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: app_.app_timers, app_timer_count: app_.app_timer_count, app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: False, app_frame: app_.app_frame, app_time: app_.app_time }
	}) } else { app_ })

	orch_advance_frame : Orchestrator.AppState, I64 -> Orchestrator.AppState
	orch_advance_frame = |app_, dt| Orchestrator.AppState.{ app_root: app_.app_root, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: app_.app_overlays, app_bindings: app_.app_bindings, app_animations: app_.app_animations, app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: app_.app_timers, app_timer_count: app_.app_timer_count, app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: app_.app_dirty, app_frame: (app_.app_frame + 1), app_time: (app_.app_time + dt) }

	eq_InputSource : Orchestrator.InputSource, Orchestrator.InputSource -> Bool
	eq_InputSource = |ex, ey| (match ex {
		IsKeyboard => (match ey {
			IsKeyboard => True
			_ => False
		})
		IsMouse => (match ey {
			IsMouse => True
			_ => False
		})
		IsNetwork(exf0) => (match ey {
			IsNetwork(eyf0) => (exf0 == eyf0)
			_ => False
		})
		IsTimer(exf0, exf1) => (match ey {
			IsTimer(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
			_ => False
		})
		IsCustom(exf0) => (match ey {
			IsCustom(eyf0) => (exf0 == eyf0)
			_ => False
		})
	})

	eq_InputEntry : Orchestrator.InputEntry, Orchestrator.InputEntry -> Bool
	eq_InputEntry = |ex, ey| (eq_InputSource(ex.ie_source, ey.ie_source) and (ex.ie_enabled == ey.ie_enabled))

	eq_UiTimer : Orchestrator.UiTimer, Orchestrator.UiTimer -> Bool
	eq_UiTimer = |ex, ey| (((((ex.ut_name == ey.ut_name) and (ex.ut_interval == ey.ut_interval)) and (ex.ut_elapsed == ey.ut_elapsed)) and (ex.ut_repeating == ey.ut_repeating)) and (ex.ut_fired == ey.ut_fired))

	eq_AppState : Orchestrator.AppState, Orchestrator.AppState -> Bool
	eq_AppState = |ex, ey| ((((((((((((((Widget.eq_WidgetNode(ex.app_root, ey.app_root) and Theme.eq_Theme(ex.app_theme, ey.app_theme)) and Surface.eq_Compositor(ex.app_compositor, ey.app_compositor)) and Overlay.eq_OverlayStack(ex.app_overlays, ey.app_overlays)) and Binding.eq_BindingTable(ex.app_bindings, ey.app_bindings)) and Animation.eq_AnimSet(ex.app_animations, ey.app_animations)) and Sound.eq_SoundQueue(ex.app_sounds, ey.app_sounds)) and Event.eq_HandlerTable(ex.app_handlers, ey.app_handlers)) and (ex.app_timers == ey.app_timers)) and (ex.app_timer_count == ey.app_timer_count)) and (ex.app_focused == ey.app_focused)) and (ex.app_hovered == ey.app_hovered)) and (ex.app_dirty == ey.app_dirty)) and (ex.app_frame == ey.app_frame)) and (ex.app_time == ey.app_time))

	eq_TimerTickResult : Orchestrator.TimerTickResult, Orchestrator.TimerTickResult -> Bool
	eq_TimerTickResult = |ex, ey| ((ex.ttr_timers == ey.ttr_timers) and (ex.ttr_fired == ey.ttr_fired))
}
