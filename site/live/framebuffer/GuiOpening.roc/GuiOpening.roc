app [main!] { pf: platform "../../../../../../showell_repos/roc-apps/framebuffer/platform/main.roc" }

import pf.Echo

echo! = |msg| Echo.line!(msg)

# GuiOpening -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import AppRunner
import CceText
import Event
import InputSource
import Machine
import Theme
import Widget

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
AppId : [AppDashboard, AppCircuits, AppSettings]
ShellState := { ss_app : AppRunner.BareApp, ss_active : I64, ss_frame : I64 }.{
	is_eq : ShellState, ShellState -> Bool
	is_eq = |a, b| eq_ShellState(a, b)
}
NavEntry := { ne_id : I64, ne_label : CceText, ne_icon : CceText }.{
	is_eq : NavEntry, NavEntry -> Bool
	is_eq = |a, b| eq_NavEntry(a, b)
}

gui_w : I64
gui_w = 1024

gui_h : I64
gui_h = 768

gui_max_tris : I64
gui_max_tris = 12000

gui_sidebar_w : I64
gui_sidebar_w = 160

shell_nav_entries : List(NavEntry)
shell_nav_entries = [NavEntry.{ ne_id: 0, ne_label: "Dashboard", ne_icon: "D" }, NavEntry.{ ne_id: 1, ne_label: "Circuits", ne_icon: "C" }, NavEntry.{ ne_id: 2, ne_label: "Settings", ne_icon: "G" }]

shell_build_root : I64 -> Widget.WidgetNode
shell_build_root = |active| ({
	sidebar = shell_build_sidebar(active)
	content = shell_build_content(active)
	Widget.widget_panel("root", DirRow, 0, [sidebar, content])
})

shell_build_sidebar : I64 -> Widget.WidgetNode
shell_build_sidebar = |active| ({
	logo = Widget.widget_set_min(Widget.widget_label("logo", "CODEX GUIOS"), gui_sidebar_w, 24)
	sep = Widget.widget_separator("nav-sep")
	items = shell_build_nav_items(active, 0, U64.to_i64_wrap(List.len(shell_nav_entries)), [])
	Widget.widget_set_min(Widget.widget_set_flex(Widget.widget_panel("sidebar", DirColumn, 2, List.concat([logo, sep], items)), 0), gui_sidebar_w, 0)
})

shell_build_nav_items : I64, I64, I64, List(Widget.WidgetNode) -> List(Widget.WidgetNode)
shell_build_nav_items = |active, i, n, acc| (if (i >= n) { acc } else { ({
	entry = (List.get(shell_nav_entries, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	btn = Widget.widget_button(CceText.concat("nav-", CceText.show_int(i)), CceText.concat(CceText.concat(entry.ne_icon, " "), entry.ne_label))
	styled = (if (i == active) { Widget.widget_add_flag(btn, Theme.flag_focused) } else { btn })
	shell_build_nav_items(active, (i + 1), n, List.append(acc, styled))
}) })

shell_build_content : I64 -> Widget.WidgetNode
shell_build_content = |active| ({
	header = shell_build_header(active)
	body = shell_build_body(active)
	Widget.widget_set_flex(Widget.widget_panel("content", DirColumn, 0, [header, body]), 1)
})

shell_build_header : I64 -> Widget.WidgetNode
shell_build_header = |active| ({
	title_text : CceText
	title_text = (if (active == 0) { "Dashboard" } else { (if (active == 1) { "Circuits EDA" } else { "Settings" }) })
	title = Widget.widget_label("title", title_text)
	Widget.widget_fixed(Widget.widget_panel("header", DirRow, 8, [title]), 0, 28)
})

shell_build_body : I64 -> Widget.WidgetNode
shell_build_body = |active| (if (active == 0) { shell_dashboard_body } else { (if (active == 1) { shell_circuits_body } else { shell_settings_body }) })

shell_dashboard_body : Widget.WidgetNode
shell_dashboard_body = ({
	welcome = Widget.widget_label("welcome", "Welcome to Codex GuiOS")
	info = Widget.widget_label("info", "Use the sidebar to navigate.")
	apps = Widget.widget_label("apps-label", "Available apps: Circuits EDA, Settings")
	Widget.widget_set_flex(Widget.widget_panel("dash-body", DirColumn, 8, [welcome, info, apps]), 1)
})

shell_circuits_body : Widget.WidgetNode
shell_circuits_body = ({
	info = Widget.widget_label("circ-info", "Launch Circuits EDA externally:")
	cmd = Widget.widget_label("circ-cmd", "codex-vm -kernel circuits-gpu.cdx -gop")
	hint = Widget.widget_label("circ-hint", "Full EDA with schematic, PCB, 3D, sim")
	Widget.widget_set_flex(Widget.widget_panel("circ-body", DirColumn, 8, [info, cmd, hint]), 1)
})

shell_settings_body : Widget.WidgetNode
shell_settings_body = ({
	theme_label = Widget.widget_label("set-theme", "Theme: Terminal")
	res_label = Widget.widget_label("set-res", "Resolution: 1024x768")
	Widget.widget_set_flex(Widget.widget_panel("set-body", DirColumn, 8, [theme_label, res_label]), 1)
})

shell_init : ShellState
shell_init = ({
	root = shell_build_root(0)
	ba = AppRunner.bare_app_new(root, Theme.theme_terminal, gui_w, gui_h, gui_max_tris)
	ShellState.{ ss_app: ba, ss_active: 0, ss_frame: 0 }
})

shell_loop! : Machine.Machine, ShellState => (Machine.Machine, I64)
shell_loop! = |machine, ss| ({
	(machine1, ba2) = AppRunner.bare_app_tick!(machine, ss.ss_app)
	shell_loop_tick!(machine1, ss, ba2)
})

shell_loop_tick! : Machine.Machine, ShellState, AppRunner.BareApp => (Machine.Machine, I64)
shell_loop_tick! = |machine, ss, ba2| ({
	ss2 = shell_process_input(ss, ba2)
	({
		(machine1, rendered) = AppRunner.bare_app_render!(machine, ss2.ss_app)
		shell_loop_after!(machine1, rendered, ss2)
	})
})

shell_loop_after! : Machine.Machine, I64, ShellState => (Machine.Machine, I64)
shell_loop_after! = |machine, _rendered, ss2| (if ss2.ss_app.ba_quit { (machine, ss2.ss_frame) } else { shell_loop!(machine, ShellState.{ ss_app: ss2.ss_app, ss_active: ss2.ss_active, ss_frame: (ss2.ss_frame + 1) }) })

shell_process_input : ShellState, AppRunner.BareApp -> ShellState
shell_process_input = |ss, ba| ({
	ri = AppRunner.bare_app_input(ba)
	key : I64
	key = InputSource.ri_key_pressed(ri)
	clicked : Bool
	clicked = InputSource.ri_left_down(ri)
	mx : I64
	mx = ri.ri_mx
	my : I64
	my = ri.ri_my
	ss2 = (if (key == 16) { ShellState.{ ss_app: AppRunner.bare_app_set_quit(ba), ss_active: ss.ss_active, ss_frame: ss.ss_frame } } else { ShellState.{ ss_app: ba, ss_active: ss.ss_active, ss_frame: ss.ss_frame } })
	(if clicked { shell_handle_click(ss2, mx, my) } else { ss2 })
})

shell_handle_click : ShellState, I64, I64 -> ShellState
shell_handle_click = |ss, mx, my| ({
	target : CceText
	target = Event.event_target_from_mouse(ss.ss_app.ba_state.app_root, mx, my)
	shell_nav_click(ss, shell_nav_index(target, 0, U64.to_i64_wrap(List.len(shell_nav_entries))))
})

shell_nav_index : CceText, I64, I64 -> I64
shell_nav_index = |target, i, n| (if (i >= n) { (0 - 1) } else { (if (target == CceText.concat("nav-", CceText.show_int(i))) { i } else { shell_nav_index(target, (i + 1), n) }) })

shell_nav_click : ShellState, I64 -> ShellState
shell_nav_click = |ss, idx| (if (idx < 0) { ss } else { ({
	new_root = shell_build_root(idx)
	ShellState.{ ss_app: AppRunner.bare_app_set_root(ss.ss_app, new_root), ss_active: idx, ss_frame: ss.ss_frame }
}) })

eq_AppId : AppId, AppId -> Bool
eq_AppId = |ex, ey| (match ex {
	AppDashboard => (match ey {
		AppDashboard => True
		_ => False
	})
	AppCircuits => (match ey {
		AppCircuits => True
		_ => False
	})
	AppSettings => (match ey {
		AppSettings => True
		_ => False
	})
})

eq_ShellState : ShellState, ShellState -> Bool
eq_ShellState = |ex, ey| ((AppRunner.eq_BareApp(ex.ss_app, ey.ss_app) and (ex.ss_active == ey.ss_active)) and (ex.ss_frame == ey.ss_frame))

eq_NavEntry : NavEntry, NavEntry -> Bool
eq_NavEntry = |ex, ey| (((ex.ne_id == ey.ne_id) and (ex.ne_label == ey.ne_label)) and (ex.ne_icon == ey.ne_icon))

# --- Entry ---

main! = |args| {
	machine = Machine.boot!(args, ["Console", "Gpu.Compute", "Gpu.Memory", "Device.Port"])
	(machine1, machine__1) = shell_loop!(machine, shell_init)
	frames = machine__1
	line!(CceText.printed(CceText.concat(CceText.concat("GuiOS | ", CceText.show_int(frames)), " frames")))
	Machine.halt!(machine1)
	Ok({})
}
