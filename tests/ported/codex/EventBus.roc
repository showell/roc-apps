# EventBus -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText
import Maybe

EventBus :: [].{
	BusEvent := { evt_topic : CceText, evt_payload : CceText, evt_timestamp : I64 }.{
		is_eq : EventBus.BusEvent, EventBus.BusEvent -> Bool
		is_eq = |a, b| eq_BusEvent(a, b)
	}
	EventLog := { log_events : List(EventBus.BusEvent), log_count : I64, log_max : I64 }.{
		is_eq : EventBus.EventLog, EventBus.EventLog -> Bool
		is_eq = |a, b| eq_EventLog(a, b)
	}

	event_new : CceText, CceText, I64 -> EventBus.BusEvent
	event_new = |topic, payload, ts| EventBus.BusEvent.{ evt_topic: topic, evt_payload: payload, evt_timestamp: ts }

	event_log_new : I64 -> EventBus.EventLog
	event_log_new = |max| EventBus.EventLog.{ log_events: [], log_count: 0, log_max: max }

	event_log_add : EventBus.EventLog, EventBus.BusEvent -> EventBus.EventLog
	event_log_add = |log, evt| ({
		events = (if (log.log_count >= log.log_max) { List.append(evt_drop_first(log.log_events), evt) } else { List.append(log.log_events, evt) })
		count : I64
		count = (if (log.log_count >= log.log_max) { log.log_max } else { (log.log_count + 1) })
		EventBus.EventLog.{ log_events: events, log_count: count, log_max: log.log_max }
	})

	evt_drop_first : List(EventBus.BusEvent) -> List(EventBus.BusEvent)
	evt_drop_first = |xs| evt_drop_loop(xs, 1, U64.to_i64_wrap(List.len(xs)), [])

	evt_drop_loop : List(EventBus.BusEvent), I64, I64, List(EventBus.BusEvent) -> List(EventBus.BusEvent)
	evt_drop_loop = |xs, i, n, acc| (if (i >= n) { acc } else { evt_drop_loop(xs, (i + 1), n, List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	event_log_filter : EventBus.EventLog, CceText -> List(EventBus.BusEvent)
	event_log_filter = |log, topic| evt_filter_loop(log.log_events, topic, 0, log.log_count, [])

	evt_filter_loop : List(EventBus.BusEvent), CceText, I64, I64, List(EventBus.BusEvent) -> List(EventBus.BusEvent)
	evt_filter_loop = |events, topic, i, n, acc| (if (i >= n) { acc } else { ({
		e = (List.get(events, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		matches : Bool
		matches = (e.evt_topic == topic)
		(if matches { evt_filter_loop(events, topic, (i + 1), n, List.append(acc, e)) } else { evt_filter_loop(events, topic, (i + 1), n, acc) })
	}) })

	event_log_last : EventBus.EventLog -> Maybe.Maybe(EventBus.BusEvent)
	event_log_last = |log| (if (log.log_count == 0) { None } else { Just((List.get(log.log_events, I64.to_u64_wrap((log.log_count - 1))) ?? crash("list-at out of range"))) })

	event_log_since : EventBus.EventLog, I64 -> List(EventBus.BusEvent)
	event_log_since = |log, ts| evt_since_loop(log.log_events, ts, 0, log.log_count, [])

	evt_since_loop : List(EventBus.BusEvent), I64, I64, I64, List(EventBus.BusEvent) -> List(EventBus.BusEvent)
	evt_since_loop = |events, ts, i, n, acc| (if (i >= n) { acc } else { ({
		e = (List.get(events, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (e.evt_timestamp >= ts) { evt_since_loop(events, ts, (i + 1), n, List.append(acc, e)) } else { evt_since_loop(events, ts, (i + 1), n, acc) })
	}) })

	evt_format_event : EventBus.BusEvent -> CceText
	evt_format_event = |e| CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("[", CceText.show_int(e.evt_timestamp)), "] "), e.evt_topic), ": "), e.evt_payload)

	evt_format_event_log : EventBus.EventLog -> CceText
	evt_format_event_log = |log| CceText.concat(CceText.concat(CceText.concat(CceText.show_int(log.log_count), "/"), CceText.show_int(log.log_max)), " events")

	eq_BusEvent : EventBus.BusEvent, EventBus.BusEvent -> Bool
	eq_BusEvent = |ex, ey| (((ex.evt_topic == ey.evt_topic) and (ex.evt_payload == ey.evt_payload)) and (ex.evt_timestamp == ey.evt_timestamp))

	eq_EventLog : EventBus.EventLog, EventBus.EventLog -> Bool
	eq_EventLog = |ex, ey| (((ex.log_events == ey.log_events) and (ex.log_count == ey.log_count)) and (ex.log_max == ey.log_max))
}
