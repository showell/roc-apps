# AppRunner -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Cce
import GpuRender
import InputSource
import Machine
import Orchestrator
import Overlay
import Theme
import Widget

AppRunner :: [].{
	BareApp : { ba_state : Orchestrator.AppState, ba_input : InputSource.RawInput, ba_quit : Bool, ba_width : I64, ba_height : I64, ba_max_tris : I64 }
	ActionResult : { ar_state : Orchestrator.AppState, ar_quit : Bool }

	bare_app_new : Widget.WidgetNode, Theme.Theme, I64, I64, I64 -> AppRunner.BareApp
	bare_app_new = |root, theme, w, h, max_tris| { ba_state: Orchestrator.app_new(root, theme, w, h), ba_input: InputSource.raw_input_new(w, h), ba_quit: False, ba_width: w, ba_height: h, ba_max_tris: max_tris }

	bare_app_tick! : Machine.Machine, AppRunner.BareApp => (Machine.Machine, AppRunner.BareApp)
	bare_app_tick! = |machine, ba| ({
		(machine1, ri) = InputSource.raw_input_poll!(machine, ba.ba_input)
		(machine1, bare_app_tick_step(ba, ri))
	})

	bare_app_tick_step : AppRunner.BareApp, InputSource.RawInput -> AppRunner.BareApp
	bare_app_tick_step = |ba, ri| ({
		events = InputSource.ri_collect_events(ri, ba.ba_state.app_frame)
		st2 = Orchestrator.app_tick(ba.ba_state, 16, events)
		{ ba_state: st2, ba_input: ri, ba_quit: ba.ba_quit, ba_width: ba.ba_width, ba_height: ba.ba_height, ba_max_tris: ba.ba_max_tris }
	})

	bare_app_render! : Machine.Machine, AppRunner.BareApp => (Machine.Machine, I64)
	bare_app_render! = |machine, ba| ({
		(machine1, _) = GpuRender.gr_clear!(machine, ba.ba_state.app_theme.th_palette.pal_bg)
		(machine2, _) = GpuRender.gr_clear_depth!(machine1)
		bare_app_flush_tris!(machine2, ba)
	})

	bare_app_flush_tris! : Machine.Machine, AppRunner.BareApp => (Machine.Machine, I64)
	bare_app_flush_tris! = |machine, ba| ({
		gf = GpuRender.gf_new(ba.ba_max_tris)
		({
			(machine1, machine__49) = GpuRender.gr_render_tree!(machine, gf, ba.ba_state.app_root, ba.ba_state.app_theme, GpuRender.gr_depth_scene)
			(machine2, machine__50) = GpuRender.gr_render_overlays!(machine1, machine__49, ba.ba_state.app_overlays, ba.ba_state.app_theme, 0, ba.ba_state.app_overlays.os_count)
			GpuRender.gr_flush!(machine2, machine__50.gf_idx)
		})
	})

	bare_app_open_menu : AppRunner.BareApp, Str, I64, I64, List(Str) -> AppRunner.BareApp
	bare_app_open_menu = |ba, id, x, y, items| ({
		menu_w = bare_menu_width(items, 0, U64.to_i64_wrap(List.len(items)), 0)
		menu_h = ((U64.to_i64_wrap(List.len(items)) * 20) + 4)
		menu_widget = Widget.widget_menu(id, items)
		ov = Overlay.overlay_context_menu(id, x, y, menu_w, menu_h, menu_widget)
		{ ba_state: Orchestrator.app_push_overlay(ba.ba_state, ov), ba_input: ba.ba_input, ba_quit: ba.ba_quit, ba_width: ba.ba_width, ba_height: ba.ba_height, ba_max_tris: ba.ba_max_tris }
	})

	bare_app_close_menu : AppRunner.BareApp, Str -> AppRunner.BareApp
	bare_app_close_menu = |ba, id| ({
		st = ba.ba_state
		ovs = Overlay.overlay_dismiss(st.app_overlays, id)
		{ ba_state: { app_root: st.app_root, app_theme: st.app_theme, app_compositor: st.app_compositor, app_overlays: ovs, app_bindings: st.app_bindings, app_animations: st.app_animations, app_sounds: st.app_sounds, app_handlers: st.app_handlers, app_timers: st.app_timers, app_timer_count: st.app_timer_count, app_focused: st.app_focused, app_hovered: st.app_hovered, app_dirty: True, app_frame: st.app_frame, app_time: st.app_time }, ba_input: ba.ba_input, ba_quit: ba.ba_quit, ba_width: ba.ba_width, ba_height: ba.ba_height, ba_max_tris: ba.ba_max_tris }
	})

	bare_app_close_all_menus : AppRunner.BareApp -> AppRunner.BareApp
	bare_app_close_all_menus = |ba| ({
		st = ba.ba_state
		{ ba_state: { app_root: st.app_root, app_theme: st.app_theme, app_compositor: st.app_compositor, app_overlays: Overlay.overlay_stack_new, app_bindings: st.app_bindings, app_animations: st.app_animations, app_sounds: st.app_sounds, app_handlers: st.app_handlers, app_timers: st.app_timers, app_timer_count: st.app_timer_count, app_focused: st.app_focused, app_hovered: st.app_hovered, app_dirty: True, app_frame: st.app_frame, app_time: st.app_time }, ba_input: ba.ba_input, ba_quit: ba.ba_quit, ba_width: ba.ba_width, ba_height: ba.ba_height, ba_max_tris: ba.ba_max_tris }
	})

	bare_menu_width : List(Str), I64, I64, I64 -> I64
	bare_menu_width = |items, i, n, max_w| (if (i >= n) { ((max_w * 6) + 16) } else { ({
		w = Cce.length((List.get(items, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))
		bare_menu_width(items, (i + 1), n, (if (w > max_w) { w } else { max_w }))
	}) })

	bare_app_frame : AppRunner.BareApp -> I64
	bare_app_frame = |ba| ba.ba_state.app_frame

	bare_app_input : AppRunner.BareApp -> InputSource.RawInput
	bare_app_input = |ba| ba.ba_input

	bare_app_set_quit : AppRunner.BareApp -> AppRunner.BareApp
	bare_app_set_quit = |ba| { ba_state: ba.ba_state, ba_input: ba.ba_input, ba_quit: True, ba_width: ba.ba_width, ba_height: ba.ba_height, ba_max_tris: ba.ba_max_tris }

	bare_app_set_root : AppRunner.BareApp, Widget.WidgetNode -> AppRunner.BareApp
	bare_app_set_root = |ba, root| ({
		st = ba.ba_state
		{ ba_state: Orchestrator.orch_relayout({ app_root: root, app_theme: st.app_theme, app_compositor: st.app_compositor, app_overlays: st.app_overlays, app_bindings: st.app_bindings, app_animations: st.app_animations, app_sounds: st.app_sounds, app_handlers: st.app_handlers, app_timers: st.app_timers, app_timer_count: st.app_timer_count, app_focused: st.app_focused, app_hovered: st.app_hovered, app_dirty: True, app_frame: st.app_frame, app_time: st.app_time }), ba_input: ba.ba_input, ba_quit: ba.ba_quit, ba_width: ba.ba_width, ba_height: ba.ba_height, ba_max_tris: ba.ba_max_tris }
	})

	bare_app_has_menu : AppRunner.BareApp, Str -> Bool
	bare_app_has_menu = |ba, id| ({
		found = Overlay.overlay_find(ba.ba_state.app_overlays, id)
		(match found {
			Just(_ov) => True
			None => False
		})
	})

	bare_app_has_any_menu : AppRunner.BareApp -> Bool
	bare_app_has_any_menu = |ba| (ba.ba_state.app_overlays.os_count > 0)
}
