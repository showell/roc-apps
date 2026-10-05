# Event -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import BoxModel
import CceText
import Maybe
import Widget

Event :: [].{
	EventKind : [EvKeyDown(I64, I64), EvKeyUp(I64, I64), EvMouseMove(I64, I64), EvMouseDown(I64, I64, I64), EvMouseUp(I64, I64, I64), EvScroll(I64, I64, I64), EvFocus(CceText), EvBlur(CceText), EvResize(I64, I64), EvTimer(CceText), EvNetwork(CceText, I64), EvCustom(CceText, I64)]
	Event := { ev_kind : Event.EventKind, ev_target : CceText, ev_timestamp : I64, ev_stopped : Bool, ev_handled : Bool }.{
		is_eq : Event.Event, Event.Event -> Bool
		is_eq = |a, b| eq_Event(a, b)
	}
	HandlerResult : [HrPass(Event.Event), HrHandled(Event.Event), HrStop(Event.Event)]
	EventHandler := { eh_widget_id : CceText, eh_event_name : CceText, eh_action : I64 }.{
		is_eq : Event.EventHandler, Event.EventHandler -> Bool
		is_eq = |a, b| eq_EventHandler(a, b)
	}
	HandlerTable := { ht_handlers : List(Event.EventHandler), ht_count : I64 }.{
		is_eq : Event.HandlerTable, Event.HandlerTable -> Bool
		is_eq = |a, b| eq_HandlerTable(a, b)
	}
	EventPath := { ep_ids : List(CceText), ep_count : I64 }.{
		is_eq : Event.EventPath, Event.EventPath -> Bool
		is_eq = |a, b| eq_EventPath(a, b)
	}

	event_key_down : I64, I64, I64 -> Event.Event
	event_key_down = |key, mods, ts| Event.Event.{ ev_kind: EvKeyDown(key, mods), ev_target: "", ev_timestamp: ts, ev_stopped: False, ev_handled: False }

	event_key_up : I64, I64, I64 -> Event.Event
	event_key_up = |key, mods, ts| Event.Event.{ ev_kind: EvKeyUp(key, mods), ev_target: "", ev_timestamp: ts, ev_stopped: False, ev_handled: False }

	event_mouse_move : I64, I64, I64 -> Event.Event
	event_mouse_move = |x, y, ts| Event.Event.{ ev_kind: EvMouseMove(x, y), ev_target: "", ev_timestamp: ts, ev_stopped: False, ev_handled: False }

	event_mouse_down : I64, I64, I64, I64 -> Event.Event
	event_mouse_down = |x, y, btn, ts| Event.Event.{ ev_kind: EvMouseDown(x, y, btn), ev_target: "", ev_timestamp: ts, ev_stopped: False, ev_handled: False }

	event_mouse_up : I64, I64, I64, I64 -> Event.Event
	event_mouse_up = |x, y, btn, ts| Event.Event.{ ev_kind: EvMouseUp(x, y, btn), ev_target: "", ev_timestamp: ts, ev_stopped: False, ev_handled: False }

	event_retarget : Event.Event, CceText -> Event.Event
	event_retarget = |ev, target| Event.Event.{ ev_kind: ev.ev_kind, ev_target: target, ev_timestamp: ev.ev_timestamp, ev_stopped: ev.ev_stopped, ev_handled: ev.ev_handled }

	handler_table_new : Event.HandlerTable
	handler_table_new = Event.HandlerTable.{ ht_handlers: [], ht_count: 0 }

	event_target_from_mouse : Widget.WidgetNode, I64, I64 -> CceText
	event_target_from_mouse = |root, mx, my| ({
		found = ev_hit_widget(root, mx, my)
		(match found {
			Just(w) => w.wn_id
			None => root.wn_id
		})
	})

	ev_hit_widget : Widget.WidgetNode, I64, I64 -> Maybe.Maybe(Widget.WidgetNode)
	ev_hit_widget = |w, mx, my| (if BoxModel.rect_contains(w.wn_bounds, mx, my) { ({
		child_hit = ev_hit_children(w.wn_children, mx, my, 0, w.wn_child_count)
		(match child_hit {
			Just(c) => Just(c)
			None => Just(w)
		})
	}) } else { None })

	ev_hit_children : List(Widget.WidgetNode), I64, I64, I64, I64 -> Maybe.Maybe(Widget.WidgetNode)
	ev_hit_children = |children, mx, my, i, n| (if (i >= n) { None } else { ({
		hit = ev_hit_widget((List.get(children, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), mx, my)
		(match hit {
			Just(w) => Just(w)
			None => ev_hit_children(children, mx, my, (i + 1), n)
		})
	}) })

	btn_left : I64
	btn_left = 0

	btn_right : I64
	btn_right = 1

	btn_middle : I64
	btn_middle = 2

	eq_EventKind : Event.EventKind, Event.EventKind -> Bool
	eq_EventKind = |ex, ey| (match ex {
		EvKeyDown(exf0, exf1) => (match ey {
			EvKeyDown(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
			_ => False
		})
		EvKeyUp(exf0, exf1) => (match ey {
			EvKeyUp(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
			_ => False
		})
		EvMouseMove(exf0, exf1) => (match ey {
			EvMouseMove(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
			_ => False
		})
		EvMouseDown(exf0, exf1, exf2) => (match ey {
			EvMouseDown(eyf0, eyf1, eyf2) => (((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2))
			_ => False
		})
		EvMouseUp(exf0, exf1, exf2) => (match ey {
			EvMouseUp(eyf0, eyf1, eyf2) => (((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2))
			_ => False
		})
		EvScroll(exf0, exf1, exf2) => (match ey {
			EvScroll(eyf0, eyf1, eyf2) => (((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2))
			_ => False
		})
		EvFocus(exf0) => (match ey {
			EvFocus(eyf0) => (exf0 == eyf0)
			_ => False
		})
		EvBlur(exf0) => (match ey {
			EvBlur(eyf0) => (exf0 == eyf0)
			_ => False
		})
		EvResize(exf0, exf1) => (match ey {
			EvResize(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
			_ => False
		})
		EvTimer(exf0) => (match ey {
			EvTimer(eyf0) => (exf0 == eyf0)
			_ => False
		})
		EvNetwork(exf0, exf1) => (match ey {
			EvNetwork(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
			_ => False
		})
		EvCustom(exf0, exf1) => (match ey {
			EvCustom(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
			_ => False
		})
	})

	eq_Event : Event.Event, Event.Event -> Bool
	eq_Event = |ex, ey| ((((eq_EventKind(ex.ev_kind, ey.ev_kind) and (ex.ev_target == ey.ev_target)) and (ex.ev_timestamp == ey.ev_timestamp)) and (ex.ev_stopped == ey.ev_stopped)) and (ex.ev_handled == ey.ev_handled))

	eq_HandlerResult : Event.HandlerResult, Event.HandlerResult -> Bool
	eq_HandlerResult = |ex, ey| (match ex {
		HrPass(exf0) => (match ey {
			HrPass(eyf0) => eq_Event(exf0, eyf0)
			_ => False
		})
		HrHandled(exf0) => (match ey {
			HrHandled(eyf0) => eq_Event(exf0, eyf0)
			_ => False
		})
		HrStop(exf0) => (match ey {
			HrStop(eyf0) => eq_Event(exf0, eyf0)
			_ => False
		})
	})

	eq_EventHandler : Event.EventHandler, Event.EventHandler -> Bool
	eq_EventHandler = |ex, ey| (((ex.eh_widget_id == ey.eh_widget_id) and (ex.eh_event_name == ey.eh_event_name)) and (ex.eh_action == ey.eh_action))

	eq_HandlerTable : Event.HandlerTable, Event.HandlerTable -> Bool
	eq_HandlerTable = |ex, ey| ((ex.ht_handlers == ey.ht_handlers) and (ex.ht_count == ey.ht_count))

	eq_EventPath : Event.EventPath, Event.EventPath -> Bool
	eq_EventPath = |ex, ey| ((ex.ep_ids == ey.ep_ids) and (ex.ep_count == ey.ep_count))
}
