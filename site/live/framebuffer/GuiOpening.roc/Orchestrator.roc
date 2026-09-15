# Orchestrator -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Animation
import Binding
import BoxModel
import Event
import Overlay
import Sound
import Surface
import Theme
import Widget

Orchestrator :: [].{
	InputSource : [IsKeyboard, IsMouse, IsNetwork(Str), IsTimer(Str, I64), IsCustom(Str)]
	InputEntry : { ie_source : Orchestrator.InputSource, ie_enabled : Bool }
	UiTimer : { ut_name : Str, ut_interval : I64, ut_elapsed : I64, ut_repeating : Bool, ut_fired : Bool }
	AppState : { app_root : Widget.WidgetNode, app_theme : Theme.Theme, app_compositor : Surface.Compositor, app_overlays : Overlay.OverlayStack, app_bindings : Binding.BindingTable, app_animations : Animation.AnimSet, app_sounds : Sound.SoundQueue, app_handlers : Event.HandlerTable, app_timers : List(Orchestrator.UiTimer), app_timer_count : I64, app_focused : Str, app_hovered : Str, app_dirty : Bool, app_frame : I64, app_time : I64 }
	TimerTickResult : { ttr_timers : List(Orchestrator.UiTimer), ttr_fired : List(Str) }

	app_new : Widget.WidgetNode, Theme.Theme, I64, I64 -> Orchestrator.AppState
	app_new = |root, theme, w, h| { app_root: root, app_theme: theme, app_compositor: Surface.compositor_new(w, h, theme.th_palette.pal_bg), app_overlays: Overlay.overlay_stack_new, app_bindings: Binding.binding_table_new, app_animations: Animation.anim_set_new, app_sounds: Sound.sound_queue_new(16), app_handlers: Event.handler_table_new, app_timers: [], app_timer_count: 0, app_focused: "", app_hovered: "", app_dirty: True, app_frame: 0, app_time: 0 }

	app_add_timer : Orchestrator.AppState, Str, I64, Bool -> Orchestrator.AppState
	app_add_timer = |app_, name, interval, repeating| ({
		timer = { ut_name: name, ut_interval: interval, ut_elapsed: 0, ut_repeating: repeating, ut_fired: False }
		{ app_root: app_.app_root, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: app_.app_overlays, app_bindings: app_.app_bindings, app_animations: app_.app_animations, app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: List.append(app_.app_timers, timer), app_timer_count: (app_.app_timer_count + 1), app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: app_.app_dirty, app_frame: app_.app_frame, app_time: app_.app_time }
	})

	app_remove_timer : Orchestrator.AppState, Str -> Orchestrator.AppState
	app_remove_timer = |app_, name| ({
		filtered = orch_filter_timers(app_.app_timers, name, 0, app_.app_timer_count, [])
		{ app_root: app_.app_root, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: app_.app_overlays, app_bindings: app_.app_bindings, app_animations: app_.app_animations, app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: filtered, app_timer_count: U64.to_i64_wrap(List.len(filtered)), app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: app_.app_dirty, app_frame: app_.app_frame, app_time: app_.app_time }
	})

	orch_filter_timers : List(Orchestrator.UiTimer), Str, I64, I64, List(Orchestrator.UiTimer) -> List(Orchestrator.UiTimer)
	orch_filter_timers = |timers, name, i, n, acc| (if (i >= n) { acc } else { ({
		t = (List.get(timers, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (t.ut_name == name) { orch_filter_timers(timers, name, (i + 1), n, acc) } else { orch_filter_timers(timers, name, (i + 1), n, List.append(acc, t)) })
	}) })

	app_on : Orchestrator.AppState, Str, Str, I64 -> Orchestrator.AppState
	app_on = |app_, widget_id, event_name, action| { app_root: app_.app_root, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: app_.app_overlays, app_bindings: app_.app_bindings, app_animations: app_.app_animations, app_sounds: app_.app_sounds, app_handlers: Event.handler_table_add(app_.app_handlers, widget_id, event_name, action), app_timers: app_.app_timers, app_timer_count: app_.app_timer_count, app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: app_.app_dirty, app_frame: app_.app_frame, app_time: app_.app_time }

	app_bind : Orchestrator.AppState, Str, I64, Binding.Binding -> Orchestrator.AppState
	app_bind = |app_, obs_id, initial, binding| ({
		bt2 = Binding.bt_add_obs(app_.app_bindings, Binding.observable(obs_id, initial))
		bt3 = Binding.bt_add_binding(bt2, binding)
		{ app_root: app_.app_root, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: app_.app_overlays, app_bindings: bt3, app_animations: app_.app_animations, app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: app_.app_timers, app_timer_count: app_.app_timer_count, app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: True, app_frame: app_.app_frame, app_time: app_.app_time }
	})

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
		{ app_root: app_.app_root, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: app_.app_overlays, app_bindings: app_.app_bindings, app_animations: app_.app_animations, app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: result.ttr_timers, app_timer_count: U64.to_i64_wrap(List.len(result.ttr_timers)), app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: (if (U64.to_i64_wrap(List.len(result.ttr_fired)) > 0) { True } else { app_.app_dirty }), app_frame: app_.app_frame, app_time: app_.app_time }
	})

	orch_tick_timer_list : List(Orchestrator.UiTimer), I64, I64, I64, List(Orchestrator.UiTimer), List(Str) -> Orchestrator.TimerTickResult
	orch_tick_timer_list = |timers, dt, i, n, acc_timers, acc_fired| (if (i >= n) { { ttr_timers: acc_timers, ttr_fired: acc_fired } } else { ({
		t = (List.get(timers, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		new_elapsed = (t.ut_elapsed + dt)
		(if (new_elapsed >= t.ut_interval) { (if t.ut_repeating { ({
			reset = { ut_name: t.ut_name, ut_interval: t.ut_interval, ut_elapsed: (new_elapsed - t.ut_interval), ut_repeating: True, ut_fired: True }
			orch_tick_timer_list(timers, dt, (i + 1), n, List.append(acc_timers, reset), List.append(acc_fired, t.ut_name))
		}) } else { orch_tick_timer_list(timers, dt, (i + 1), n, acc_timers, List.append(acc_fired, t.ut_name)) }) } else { ({
			updated = { ut_name: t.ut_name, ut_interval: t.ut_interval, ut_elapsed: new_elapsed, ut_repeating: t.ut_repeating, ut_fired: False }
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
		{ app_root: app_.app_root, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: app_.app_overlays, app_bindings: app_.app_bindings, app_animations: app_.app_animations, app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: app_.app_timers, app_timer_count: app_.app_timer_count, app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: True, app_frame: app_.app_frame, app_time: app_.app_time }
	})

	orch_tick_animations : Orchestrator.AppState, I64 -> Orchestrator.AppState
	orch_tick_animations = |app_, dt| { app_root: app_.app_root, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: app_.app_overlays, app_bindings: app_.app_bindings, app_animations: Animation.anim_set_tick(app_.app_animations, dt), app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: app_.app_timers, app_timer_count: app_.app_timer_count, app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: app_.app_dirty, app_frame: app_.app_frame, app_time: app_.app_time }

	orch_tick_overlays : Orchestrator.AppState, I64 -> Orchestrator.AppState
	orch_tick_overlays = |app_, dt| { app_root: app_.app_root, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: Overlay.overlay_stack_tick(app_.app_overlays, dt), app_bindings: app_.app_bindings, app_animations: app_.app_animations, app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: app_.app_timers, app_timer_count: app_.app_timer_count, app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: app_.app_dirty, app_frame: app_.app_frame, app_time: app_.app_time }

	orch_apply_bindings : Orchestrator.AppState -> Orchestrator.AppState
	orch_apply_bindings = |app_| ({
		cleaned = Binding.bt_clean(app_.app_bindings)
		{ app_root: app_.app_root, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: app_.app_overlays, app_bindings: cleaned, app_animations: app_.app_animations, app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: app_.app_timers, app_timer_count: app_.app_timer_count, app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: app_.app_dirty, app_frame: app_.app_frame, app_time: app_.app_time }
	})

	orch_relayout : Orchestrator.AppState -> Orchestrator.AppState
	orch_relayout = |app_| (if app_.app_dirty { ({
		container = BoxModel.layout_rect(0, 0, app_.app_compositor.comp_width, app_.app_compositor.comp_height)
		laid_out = Widget.widget_layout(app_.app_root, app_.app_theme, container)
		{ app_root: laid_out, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: app_.app_overlays, app_bindings: app_.app_bindings, app_animations: app_.app_animations, app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: app_.app_timers, app_timer_count: app_.app_timer_count, app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: False, app_frame: app_.app_frame, app_time: app_.app_time }
	}) } else { app_ })

	orch_advance_frame : Orchestrator.AppState, I64 -> Orchestrator.AppState
	orch_advance_frame = |app_, dt| { app_root: app_.app_root, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: app_.app_overlays, app_bindings: app_.app_bindings, app_animations: app_.app_animations, app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: app_.app_timers, app_timer_count: app_.app_timer_count, app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: app_.app_dirty, app_frame: (app_.app_frame + 1), app_time: (app_.app_time + dt) }

	app_set_theme : Orchestrator.AppState, Theme.Theme -> Orchestrator.AppState
	app_set_theme = |app_, theme| { app_root: app_.app_root, app_theme: theme, app_compositor: app_.app_compositor, app_overlays: app_.app_overlays, app_bindings: app_.app_bindings, app_animations: app_.app_animations, app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: app_.app_timers, app_timer_count: app_.app_timer_count, app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: True, app_frame: app_.app_frame, app_time: app_.app_time }

	app_set_focus : Orchestrator.AppState, Str -> Orchestrator.AppState
	app_set_focus = |app_, id| { app_root: app_.app_root, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: app_.app_overlays, app_bindings: app_.app_bindings, app_animations: app_.app_animations, app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: app_.app_timers, app_timer_count: app_.app_timer_count, app_focused: id, app_hovered: app_.app_hovered, app_dirty: True, app_frame: app_.app_frame, app_time: app_.app_time }

	app_push_overlay : Orchestrator.AppState, Overlay.Overlay -> Orchestrator.AppState
	app_push_overlay = |app_, ov| { app_root: app_.app_root, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: Overlay.overlay_push(app_.app_overlays, ov), app_bindings: app_.app_bindings, app_animations: app_.app_animations, app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: app_.app_timers, app_timer_count: app_.app_timer_count, app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: True, app_frame: app_.app_frame, app_time: app_.app_time }

	app_play_sound : Orchestrator.AppState, Sound.SoundEffect -> Orchestrator.AppState
	app_play_sound = |app_, snd| { app_root: app_.app_root, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: app_.app_overlays, app_bindings: app_.app_bindings, app_animations: app_.app_animations, app_sounds: Sound.sq_enqueue(app_.app_sounds, snd), app_handlers: app_.app_handlers, app_timers: app_.app_timers, app_timer_count: app_.app_timer_count, app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: app_.app_dirty, app_frame: app_.app_frame, app_time: app_.app_time }

	app_update_binding : Orchestrator.AppState, Str, I64 -> Orchestrator.AppState
	app_update_binding = |app_, obs_id, value| { app_root: app_.app_root, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: app_.app_overlays, app_bindings: Binding.bt_set(app_.app_bindings, obs_id, value), app_animations: app_.app_animations, app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: app_.app_timers, app_timer_count: app_.app_timer_count, app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: True, app_frame: app_.app_frame, app_time: app_.app_time }

	app_start_animation : Orchestrator.AppState, Str, Animation.Transition -> Orchestrator.AppState
	app_start_animation = |app_, id, tr| { app_root: app_.app_root, app_theme: app_.app_theme, app_compositor: app_.app_compositor, app_overlays: app_.app_overlays, app_bindings: app_.app_bindings, app_animations: Animation.anim_set_add(app_.app_animations, id, tr), app_sounds: app_.app_sounds, app_handlers: app_.app_handlers, app_timers: app_.app_timers, app_timer_count: app_.app_timer_count, app_focused: app_.app_focused, app_hovered: app_.app_hovered, app_dirty: True, app_frame: app_.app_frame, app_time: app_.app_time }

	app_frame_count : Orchestrator.AppState -> I64
	app_frame_count = |app_| app_.app_frame

	app_elapsed : Orchestrator.AppState -> I64
	app_elapsed = |app_| app_.app_time

	app_is_dirty : Orchestrator.AppState -> Bool
	app_is_dirty = |app_| app_.app_dirty

	app_has_modal : Orchestrator.AppState -> Bool
	app_has_modal = |app_| Overlay.overlay_has_modal(app_.app_overlays)

	format_app_state : Orchestrator.AppState -> Str
	format_app_state = |app_| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat("frame=", I64.to_str(app_.app_frame)), " t="), I64.to_str(app_.app_time)), " dirty="), Theme.theme_fmt_bool(app_.app_dirty)), " focus="), app_.app_focused), " timers="), I64.to_str(app_.app_timer_count)), " overlays="), I64.to_str(app_.app_overlays.os_count))

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
}
