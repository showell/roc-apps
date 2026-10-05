# Overlay -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText
import Widget

Overlay :: [].{
	OverlayKind : [OvTooltip, OvPopup, OvContextMenu, OvNotification, OvModal]
	Overlay := { ov_id : CceText, ov_kind : Overlay.OverlayKind, ov_x : I64, ov_y : I64, ov_width : I64, ov_height : I64, ov_widget : Widget.WidgetNode, ov_modal : Bool, ov_dismiss_ms : I64, ov_elapsed : I64, ov_visible : Bool, ov_z : I64 }.{
		is_eq : Overlay.Overlay, Overlay.Overlay -> Bool
		is_eq = |a, b| eq_Overlay(a, b)
	}
	OverlayStack := { os_overlays : List(Overlay.Overlay), os_count : I64 }.{
		is_eq : Overlay.OverlayStack, Overlay.OverlayStack -> Bool
		is_eq = |a, b| eq_OverlayStack(a, b)
	}

	overlay_stack_new : Overlay.OverlayStack
	overlay_stack_new = Overlay.OverlayStack.{ os_overlays: [], os_count: 0 }

	overlay_stack_tick : Overlay.OverlayStack, I64 -> Overlay.OverlayStack
	overlay_stack_tick = |os, dt| ({
		ticked = ov_tick_all(os.os_overlays, dt, 0, os.os_count, [])
		alive = ov_remove_expired(ticked, 0, U64.to_i64_wrap(List.len(ticked)), [])
		Overlay.OverlayStack.{ os_overlays: alive, os_count: U64.to_i64_wrap(List.len(alive)) }
	})

	ov_tick_all : List(Overlay.Overlay), I64, I64, I64, List(Overlay.Overlay) -> List(Overlay.Overlay)
	ov_tick_all = |overlays, dt, i, n, acc| (if (i >= n) { acc } else { ({
		ov = (List.get(overlays, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		ticked = Overlay.Overlay.{ ov_id: ov.ov_id, ov_kind: ov.ov_kind, ov_x: ov.ov_x, ov_y: ov.ov_y, ov_width: ov.ov_width, ov_height: ov.ov_height, ov_widget: ov.ov_widget, ov_modal: ov.ov_modal, ov_dismiss_ms: ov.ov_dismiss_ms, ov_elapsed: (ov.ov_elapsed + dt), ov_visible: ov.ov_visible, ov_z: ov.ov_z }
		ov_tick_all(overlays, dt, (i + 1), n, List.append(acc, ticked))
	}) })

	ov_remove_expired : List(Overlay.Overlay), I64, I64, List(Overlay.Overlay) -> List(Overlay.Overlay)
	ov_remove_expired = |overlays, i, n, acc| (if (i >= n) { acc } else { ({
		ov = (List.get(overlays, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		expired : Bool
		expired = (if (ov.ov_dismiss_ms > 0) { (ov.ov_elapsed >= ov.ov_dismiss_ms) } else { False })
		(if expired { ov_remove_expired(overlays, (i + 1), n, acc) } else { ov_remove_expired(overlays, (i + 1), n, List.append(acc, ov)) })
	}) })

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

	eq_Overlay : Overlay.Overlay, Overlay.Overlay -> Bool
	eq_Overlay = |ex, ey| ((((((((((((ex.ov_id == ey.ov_id) and eq_OverlayKind(ex.ov_kind, ey.ov_kind)) and (ex.ov_x == ey.ov_x)) and (ex.ov_y == ey.ov_y)) and (ex.ov_width == ey.ov_width)) and (ex.ov_height == ey.ov_height)) and Widget.eq_WidgetNode(ex.ov_widget, ey.ov_widget)) and (ex.ov_modal == ey.ov_modal)) and (ex.ov_dismiss_ms == ey.ov_dismiss_ms)) and (ex.ov_elapsed == ey.ov_elapsed)) and (ex.ov_visible == ey.ov_visible)) and (ex.ov_z == ey.ov_z))

	eq_OverlayStack : Overlay.OverlayStack, Overlay.OverlayStack -> Bool
	eq_OverlayStack = |ex, ey| ((ex.os_overlays == ey.os_overlays) and (ex.os_count == ey.os_count))
}
