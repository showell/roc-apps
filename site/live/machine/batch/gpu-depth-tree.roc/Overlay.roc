# Overlay -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Maybe
import Widget

Overlay :: [].{
	OverlayKind : [OvTooltip, OvPopup, OvContextMenu, OvNotification, OvModal]
	Overlay : { ov_id : Str, ov_kind : Overlay.OverlayKind, ov_x : I64, ov_y : I64, ov_width : I64, ov_height : I64, ov_widget : Widget.WidgetNode, ov_modal : Bool, ov_dismiss_ms : I64, ov_elapsed : I64, ov_visible : Bool, ov_z : I64 }
	OverlayStack : { os_overlays : List(Overlay.Overlay), os_count : I64 }

	overlay_tooltip : Str, I64, I64, I64, I64, Widget.WidgetNode -> Overlay.Overlay
	overlay_tooltip = |id, x, y, w, h, content| { ov_id: id, ov_kind: OvTooltip, ov_x: x, ov_y: y, ov_width: w, ov_height: h, ov_widget: content, ov_modal: False, ov_dismiss_ms: 3000, ov_elapsed: 0, ov_visible: True, ov_z: 1000 }

	overlay_popup : Str, I64, I64, I64, I64, Widget.WidgetNode -> Overlay.Overlay
	overlay_popup = |id, x, y, w, h, content| { ov_id: id, ov_kind: OvPopup, ov_x: x, ov_y: y, ov_width: w, ov_height: h, ov_widget: content, ov_modal: False, ov_dismiss_ms: 0, ov_elapsed: 0, ov_visible: True, ov_z: 900 }

	overlay_context_menu : Str, I64, I64, I64, I64, Widget.WidgetNode -> Overlay.Overlay
	overlay_context_menu = |id, x, y, w, h, content| { ov_id: id, ov_kind: OvContextMenu, ov_x: x, ov_y: y, ov_width: w, ov_height: h, ov_widget: content, ov_modal: False, ov_dismiss_ms: 0, ov_elapsed: 0, ov_visible: True, ov_z: 950 }

	overlay_notification : Str, I64, I64, I64, I64, Widget.WidgetNode, I64 -> Overlay.Overlay
	overlay_notification = |id, x, y, w, h, content, duration| { ov_id: id, ov_kind: OvNotification, ov_x: x, ov_y: y, ov_width: w, ov_height: h, ov_widget: content, ov_modal: False, ov_dismiss_ms: duration, ov_elapsed: 0, ov_visible: True, ov_z: 800 }

	overlay_modal : Str, I64, I64, I64, I64, Widget.WidgetNode -> Overlay.Overlay
	overlay_modal = |id, x, y, w, h, content| { ov_id: id, ov_kind: OvModal, ov_x: x, ov_y: y, ov_width: w, ov_height: h, ov_widget: content, ov_modal: True, ov_dismiss_ms: 0, ov_elapsed: 0, ov_visible: True, ov_z: 2000 }

	overlay_stack_new : Overlay.OverlayStack
	overlay_stack_new = { os_overlays: [], os_count: 0 }

	overlay_push : Overlay.OverlayStack, Overlay.Overlay -> Overlay.OverlayStack
	overlay_push = |os, ov| { os_overlays: List.append(os.os_overlays, ov), os_count: (os.os_count + 1) }

	overlay_pop : Overlay.OverlayStack -> Overlay.OverlayStack
	overlay_pop = |os| (if (os.os_count <= 0) { os } else { ({
		trimmed = ov_take(os.os_overlays, (os.os_count - 1), 0, [])
		{ os_overlays: trimmed, os_count: (os.os_count - 1) }
	}) })

	ov_take : List(Overlay.Overlay), I64, I64, List(Overlay.Overlay) -> List(Overlay.Overlay)
	ov_take = |overlays, n, i, acc| (if (i >= n) { acc } else { ov_take(overlays, n, (i + 1), List.append(acc, (List.get(overlays, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	overlay_dismiss : Overlay.OverlayStack, Str -> Overlay.OverlayStack
	overlay_dismiss = |os, id| ({
		filtered = ov_filter(os.os_overlays, id, 0, os.os_count, [])
		{ os_overlays: filtered, os_count: U64.to_i64_wrap(List.len(filtered)) }
	})

	ov_filter : List(Overlay.Overlay), Str, I64, I64, List(Overlay.Overlay) -> List(Overlay.Overlay)
	ov_filter = |overlays, id, i, n, acc| (if (i >= n) { acc } else { ({
		ov = (List.get(overlays, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (ov.ov_id == id) { ov_filter(overlays, id, (i + 1), n, acc) } else { ov_filter(overlays, id, (i + 1), n, List.append(acc, ov)) })
	}) })

	overlay_stack_tick : Overlay.OverlayStack, I64 -> Overlay.OverlayStack
	overlay_stack_tick = |os, dt| ({
		ticked = ov_tick_all(os.os_overlays, dt, 0, os.os_count, [])
		alive = ov_remove_expired(ticked, 0, U64.to_i64_wrap(List.len(ticked)), [])
		{ os_overlays: alive, os_count: U64.to_i64_wrap(List.len(alive)) }
	})

	ov_tick_all : List(Overlay.Overlay), I64, I64, I64, List(Overlay.Overlay) -> List(Overlay.Overlay)
	ov_tick_all = |overlays, dt, i, n, acc| (if (i >= n) { acc } else { ({
		ov = (List.get(overlays, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		ticked = { ov_id: ov.ov_id, ov_kind: ov.ov_kind, ov_x: ov.ov_x, ov_y: ov.ov_y, ov_width: ov.ov_width, ov_height: ov.ov_height, ov_widget: ov.ov_widget, ov_modal: ov.ov_modal, ov_dismiss_ms: ov.ov_dismiss_ms, ov_elapsed: (ov.ov_elapsed + dt), ov_visible: ov.ov_visible, ov_z: ov.ov_z }
		ov_tick_all(overlays, dt, (i + 1), n, List.append(acc, ticked))
	}) })

	ov_remove_expired : List(Overlay.Overlay), I64, I64, List(Overlay.Overlay) -> List(Overlay.Overlay)
	ov_remove_expired = |overlays, i, n, acc| (if (i >= n) { acc } else { ({
		ov = (List.get(overlays, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		expired = (if (ov.ov_dismiss_ms > 0) { (ov.ov_elapsed >= ov.ov_dismiss_ms) } else { False })
		(if expired { ov_remove_expired(overlays, (i + 1), n, acc) } else { ov_remove_expired(overlays, (i + 1), n, List.append(acc, ov)) })
	}) })

	overlay_has_modal : Overlay.OverlayStack -> Bool
	overlay_has_modal = |os| ov_any_modal(os.os_overlays, 0, os.os_count)

	ov_any_modal : List(Overlay.Overlay), I64, I64 -> Bool
	ov_any_modal = |overlays, i, n| (if (i >= n) { False } else { ({
		ov = (List.get(overlays, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if ov.ov_modal { True } else { ov_any_modal(overlays, (i + 1), n) })
	}) })

	overlay_top : Overlay.OverlayStack -> Maybe.Maybe(Overlay.Overlay)
	overlay_top = |os| (if (os.os_count <= 0) { None } else { Just((List.get(os.os_overlays, I64.to_u64_wrap((os.os_count - 1))) ?? crash("list-at out of range"))) })

	overlay_find : Overlay.OverlayStack, Str -> Maybe.Maybe(Overlay.Overlay)
	overlay_find = |os, id| ov_find_loop(os.os_overlays, id, 0, os.os_count)

	ov_find_loop : List(Overlay.Overlay), Str, I64, I64 -> Maybe.Maybe(Overlay.Overlay)
	ov_find_loop = |overlays, id, i, n| (if (i >= n) { None } else { ({
		ov = (List.get(overlays, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (ov.ov_id == id) { Just(ov) } else { ov_find_loop(overlays, id, (i + 1), n) })
	}) })

	overlay_kind_name : Overlay.OverlayKind -> Str
	overlay_kind_name = |k| (match k {
		OvTooltip => "tooltip"
		OvPopup => "popup"
		OvContextMenu => "context-menu"
		OvNotification => "notification"
		OvModal => "modal"
	})

	format_overlay : Overlay.Overlay -> Str
	format_overlay = |ov| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(overlay_kind_name(ov.ov_kind), "["), ov.ov_id), "] ("), I64.to_str(ov.ov_x)), ","), I64.to_str(ov.ov_y)), " "), I64.to_str(ov.ov_width)), "x"), I64.to_str(ov.ov_height)), ")")

	eq_OverlayKind : Overlay.OverlayKind, Overlay.OverlayKind -> Bool
	eq_OverlayKind = |ex, ey| (match ex {
		OvTooltip => (match ey {
			OvTooltip => True
			_ => False
		})
		OvPopup => (match ey {
			OvPopup => True
			_ => False
		})
		OvContextMenu => (match ey {
			OvContextMenu => True
			_ => False
		})
		OvNotification => (match ey {
			OvNotification => True
			_ => False
		})
		OvModal => (match ey {
			OvModal => True
			_ => False
		})
	})
}
