# Event -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import BoxModel
import Maybe
import Widget

Event :: [].{
	EventKind : [EvKeyDown(I64, I64), EvKeyUp(I64, I64), EvMouseMove(I64, I64), EvMouseDown(I64, I64, I64), EvMouseUp(I64, I64, I64), EvScroll(I64, I64, I64), EvFocus(Str), EvBlur(Str), EvResize(I64, I64), EvTimer(Str), EvNetwork(Str, I64), EvCustom(Str, I64)]
	Event : { ev_kind : Event.EventKind, ev_target : Str, ev_timestamp : I64, ev_stopped : Bool, ev_handled : Bool }
	HandlerResult : [HrPass(Event.Event), HrHandled(Event.Event), HrStop(Event.Event)]
	EventHandler : { eh_widget_id : Str, eh_event_name : Str, eh_action : I64 }
	HandlerTable : { ht_handlers : List(Event.EventHandler), ht_count : I64 }
	EventPath : { ep_ids : List(Str), ep_count : I64 }

	event_key_down : I64, I64, I64 -> Event.Event
	event_key_down = |key, mods, ts| { ev_kind: EvKeyDown(key, mods), ev_target: "", ev_timestamp: ts, ev_stopped: False, ev_handled: False }

	event_key_up : I64, I64, I64 -> Event.Event
	event_key_up = |key, mods, ts| { ev_kind: EvKeyUp(key, mods), ev_target: "", ev_timestamp: ts, ev_stopped: False, ev_handled: False }

	event_mouse_move : I64, I64, I64 -> Event.Event
	event_mouse_move = |x, y, ts| { ev_kind: EvMouseMove(x, y), ev_target: "", ev_timestamp: ts, ev_stopped: False, ev_handled: False }

	event_mouse_down : I64, I64, I64, I64 -> Event.Event
	event_mouse_down = |x, y, btn, ts| { ev_kind: EvMouseDown(x, y, btn), ev_target: "", ev_timestamp: ts, ev_stopped: False, ev_handled: False }

	event_mouse_up : I64, I64, I64, I64 -> Event.Event
	event_mouse_up = |x, y, btn, ts| { ev_kind: EvMouseUp(x, y, btn), ev_target: "", ev_timestamp: ts, ev_stopped: False, ev_handled: False }

	event_scroll : I64, I64, I64, I64 -> Event.Event
	event_scroll = |x, y, delta, ts| { ev_kind: EvScroll(x, y, delta), ev_target: "", ev_timestamp: ts, ev_stopped: False, ev_handled: False }

	event_focus : Str, I64 -> Event.Event
	event_focus = |id, ts| { ev_kind: EvFocus(id), ev_target: id, ev_timestamp: ts, ev_stopped: False, ev_handled: False }

	event_blur : Str, I64 -> Event.Event
	event_blur = |id, ts| { ev_kind: EvBlur(id), ev_target: id, ev_timestamp: ts, ev_stopped: False, ev_handled: False }

	event_resize : I64, I64, I64 -> Event.Event
	event_resize = |w, h, ts| { ev_kind: EvResize(w, h), ev_target: "", ev_timestamp: ts, ev_stopped: False, ev_handled: False }

	event_timer : Str, I64 -> Event.Event
	event_timer = |name, ts| { ev_kind: EvTimer(name), ev_target: "", ev_timestamp: ts, ev_stopped: False, ev_handled: False }

	event_network : Str, I64, I64 -> Event.Event
	event_network = |channel, len, ts| { ev_kind: EvNetwork(channel, len), ev_target: "", ev_timestamp: ts, ev_stopped: False, ev_handled: False }

	event_custom : Str, I64, I64 -> Event.Event
	event_custom = |name, data, ts| { ev_kind: EvCustom(name, data), ev_target: "", ev_timestamp: ts, ev_stopped: False, ev_handled: False }

	event_stop : Event.Event -> Event.Event
	event_stop = |ev| { ev_kind: ev.ev_kind, ev_target: ev.ev_target, ev_timestamp: ev.ev_timestamp, ev_stopped: True, ev_handled: ev.ev_handled }

	event_handle : Event.Event -> Event.Event
	event_handle = |ev| { ev_kind: ev.ev_kind, ev_target: ev.ev_target, ev_timestamp: ev.ev_timestamp, ev_stopped: ev.ev_stopped, ev_handled: True }

	event_retarget : Event.Event, Str -> Event.Event
	event_retarget = |ev, target| { ev_kind: ev.ev_kind, ev_target: target, ev_timestamp: ev.ev_timestamp, ev_stopped: ev.ev_stopped, ev_handled: ev.ev_handled }

	handler_table_new : Event.HandlerTable
	handler_table_new = { ht_handlers: [], ht_count: 0 }

	handler_table_add : Event.HandlerTable, Str, Str, I64 -> Event.HandlerTable
	handler_table_add = |ht, widget_id, event_name, action| ({
		h = { eh_widget_id: widget_id, eh_event_name: event_name, eh_action: action }
		{ ht_handlers: List.append(ht.ht_handlers, h), ht_count: (ht.ht_count + 1) }
	})

	handler_table_lookup : Event.HandlerTable, Str, Str -> Maybe.Maybe(Event.EventHandler)
	handler_table_lookup = |ht, widget_id, event_name| ht_lookup_loop(ht.ht_handlers, widget_id, event_name, 0, ht.ht_count)

	ht_lookup_loop : List(Event.EventHandler), Str, Str, I64, I64 -> Maybe.Maybe(Event.EventHandler)
	ht_lookup_loop = |handlers, wid, ename, i, n| (if (i >= n) { None } else { ({
		h = (List.get(handlers, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (h.eh_widget_id == wid) { (if (h.eh_event_name == ename) { Just(h) } else { ht_lookup_loop(handlers, wid, ename, (i + 1), n) }) } else { ht_lookup_loop(handlers, wid, ename, (i + 1), n) })
	}) })

	event_target_from_mouse : Widget.WidgetNode, I64, I64 -> Str
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

	event_path_to : Widget.WidgetNode, Str -> Event.EventPath
	event_path_to = |root, target| ({
		path = ev_build_path(root, target, [])
		{ ep_ids: path, ep_count: U64.to_i64_wrap(List.len(path)) }
	})

	ev_build_path : Widget.WidgetNode, Str, List(Str) -> List(Str)
	ev_build_path = |w, target, acc| ({
		acc2 = List.append(acc, w.wn_id)
		(if (w.wn_id == target) { acc2 } else { ev_build_path_children(w.wn_children, target, acc2, 0, w.wn_child_count) })
	})

	ev_build_path_children : List(Widget.WidgetNode), Str, List(Str), I64, I64 -> List(Str)
	ev_build_path_children = |children, target, acc, i, n| (if (i >= n) { [] } else { ({
		path = ev_build_path((List.get(children, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), target, acc)
		(if (U64.to_i64_wrap(List.len(path)) > 0) { path } else { ev_build_path_children(children, target, acc, (i + 1), n) })
	}) })

	event_kind_name : Event.EventKind -> Str
	event_kind_name = |k| (match k {
		EvKeyDown(_key, _mods) => "keydown"
		EvKeyUp(_key, _mods) => "keyup"
		EvMouseMove(_x, _y) => "mousemove"
		EvMouseDown(_x, _y, _btn) => "mousedown"
		EvMouseUp(_x, _y, _btn) => "mouseup"
		EvScroll(_x, _y, _d) => "scroll"
		EvFocus(_id) => "focus"
		EvBlur(_id) => "blur"
		EvResize(_w, _h) => "resize"
		EvTimer(_name) => "timer"
		EvNetwork(_ch, _len) => "network"
		EvCustom(_name, _d) => "custom"
	})

	event_is_mouse : Event.EventKind -> Bool
	event_is_mouse = |k| (match k {
		EvMouseMove(_x, _y) => True
		EvMouseDown(_x, _y, _b) => True
		EvMouseUp(_x, _y, _b) => True
		EvScroll(_x, _y, _d) => True
		EvKeyDown(_k2, _m) => False
		EvKeyUp(_k2, _m) => False
		EvFocus(_id) => False
		EvBlur(_id) => False
		EvResize(_w, _h) => False
		EvTimer(_n) => False
		EvNetwork(_c, _l) => False
		EvCustom(_n, _d) => False
	})

	event_is_keyboard : Event.EventKind -> Bool
	event_is_keyboard = |k| (match k {
		EvKeyDown(_k2, _m) => True
		EvKeyUp(_k2, _m) => True
		EvMouseMove(_x, _y) => False
		EvMouseDown(_x, _y, _b) => False
		EvMouseUp(_x, _y, _b) => False
		EvScroll(_x, _y, _d) => False
		EvFocus(_id) => False
		EvBlur(_id) => False
		EvResize(_w, _h) => False
		EvTimer(_n) => False
		EvNetwork(_c, _l) => False
		EvCustom(_n, _d) => False
	})

	mod_none : I64
	mod_none = 0

	mod_shift : I64
	mod_shift = 1

	mod_ctrl : I64
	mod_ctrl = 2

	mod_alt : I64
	mod_alt = 4

	btn_left : I64
	btn_left = 0

	btn_right : I64
	btn_right = 1

	btn_middle : I64
	btn_middle = 2

	format_event : Event.Event -> Str
	format_event = |ev| Str.concat(Str.concat(Str.concat(Str.concat(event_kind_name(ev.ev_kind), " target="), ev.ev_target), " t="), I64.to_str(ev.ev_timestamp))

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

	eq_HandlerResult : Event.HandlerResult, Event.HandlerResult -> Bool
	eq_HandlerResult = |ex, ey| (match ex {
		HrPass(exf0) => (match ey {
			HrPass(eyf0) => (exf0 == eyf0)
			_ => False
		})
		HrHandled(exf0) => (match ey {
			HrHandled(eyf0) => (exf0 == eyf0)
			_ => False
		})
		HrStop(exf0) => (match ey {
			HrStop(eyf0) => (exf0 == eyf0)
			_ => False
		})
	})
}
