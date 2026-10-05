# AppRunner -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import GpuRender
import InputSource
import Machine
import Orchestrator
import Theme
import Widget

AppRunner :: [].{
	BareApp := { ba_state : Orchestrator.AppState, ba_input : InputSource.RawInput, ba_quit : Bool, ba_width : I64, ba_height : I64, ba_max_tris : I64 }.{
		is_eq : AppRunner.BareApp, AppRunner.BareApp -> Bool
		is_eq = |a, b| eq_BareApp(a, b)
	}
	ActionResult := { ar_state : Orchestrator.AppState, ar_quit : Bool }.{
		is_eq : AppRunner.ActionResult, AppRunner.ActionResult -> Bool
		is_eq = |a, b| eq_ActionResult(a, b)
	}

	bare_app_new : Widget.WidgetNode, Theme.Theme, I64, I64, I64 -> AppRunner.BareApp
	bare_app_new = |root, theme, w, h, max_tris| AppRunner.BareApp.{ ba_state: Orchestrator.app_new(root, theme, w, h), ba_input: InputSource.raw_input_new(w, h), ba_quit: False, ba_width: w, ba_height: h, ba_max_tris: max_tris }

	bare_app_tick! : Machine.Machine, AppRunner.BareApp => (Machine.Machine, AppRunner.BareApp)
	bare_app_tick! = |machine, ba| ({
		(machine1, ri) = InputSource.raw_input_poll!(machine, ba.ba_input)
		bare_app_tick_step!(machine1, ba, ri)
	})

	bare_app_tick_step! : Machine.Machine, AppRunner.BareApp, InputSource.RawInput => (Machine.Machine, AppRunner.BareApp)
	bare_app_tick_step! = |machine, ba, ri| ({
		(machine2, machine__1) = ({
		(machine1, events) = InputSource.ri_collect_events!(machine, ri, ba.ba_state.app_frame)
		st2 = Orchestrator.app_tick(ba.ba_state, 16, events)
		(machine1, AppRunner.BareApp.{ ba_state: st2, ba_input: ri, ba_quit: ba.ba_quit, ba_width: ba.ba_width, ba_height: ba.ba_height, ba_max_tris: ba.ba_max_tris })
	})
		(machine2, machine__1)
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
			(machine1, machine__1) = GpuRender.gr_render_tree!(machine, gf, ba.ba_state.app_root, ba.ba_state.app_theme, GpuRender.gr_depth_scene)
			(machine2, machine__2) = GpuRender.gr_render_overlays!(machine1, machine__1, ba.ba_state.app_overlays, ba.ba_state.app_theme, 0, ba.ba_state.app_overlays.os_count)
			GpuRender.gr_flush!(machine2, machine__2.gf_idx)
		})
	})

	bare_app_input : AppRunner.BareApp -> InputSource.RawInput
	bare_app_input = |ba| ba.ba_input

	bare_app_set_quit : AppRunner.BareApp -> AppRunner.BareApp
	bare_app_set_quit = |ba| AppRunner.BareApp.{ ba_state: ba.ba_state, ba_input: ba.ba_input, ba_quit: True, ba_width: ba.ba_width, ba_height: ba.ba_height, ba_max_tris: ba.ba_max_tris }

	bare_app_set_root : AppRunner.BareApp, Widget.WidgetNode -> AppRunner.BareApp
	bare_app_set_root = |ba, root| ({
		st = ba.ba_state
		AppRunner.BareApp.{ ba_state: Orchestrator.orch_relayout(Orchestrator.AppState.{ app_root: root, app_theme: st.app_theme, app_compositor: st.app_compositor, app_overlays: st.app_overlays, app_bindings: st.app_bindings, app_animations: st.app_animations, app_sounds: st.app_sounds, app_handlers: st.app_handlers, app_timers: st.app_timers, app_timer_count: st.app_timer_count, app_focused: st.app_focused, app_hovered: st.app_hovered, app_dirty: True, app_frame: st.app_frame, app_time: st.app_time }), ba_input: ba.ba_input, ba_quit: ba.ba_quit, ba_width: ba.ba_width, ba_height: ba.ba_height, ba_max_tris: ba.ba_max_tris }
	})

	eq_BareApp : AppRunner.BareApp, AppRunner.BareApp -> Bool
	eq_BareApp = |ex, ey| (((((Orchestrator.eq_AppState(ex.ba_state, ey.ba_state) and InputSource.eq_RawInput(ex.ba_input, ey.ba_input)) and (ex.ba_quit == ey.ba_quit)) and (ex.ba_width == ey.ba_width)) and (ex.ba_height == ey.ba_height)) and (ex.ba_max_tris == ey.ba_max_tris))

	eq_ActionResult : AppRunner.ActionResult, AppRunner.ActionResult -> Bool
	eq_ActionResult = |ex, ey| (Orchestrator.eq_AppState(ex.ar_state, ey.ar_state) and (ex.ar_quit == ey.ar_quit))
}
