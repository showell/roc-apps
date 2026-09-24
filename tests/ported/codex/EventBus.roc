# EventBus -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Maybe
import Text

EventBus :: [].{
	BusEvent : { evt_topic : Text, evt_payload : Text, evt_timestamp : I64 }
	EventLog : { log_events : List(EventBus.BusEvent), log_count : I64, log_max : I64 }

	event_new : Text, Text, I64 -> EventBus.BusEvent
	event_new = |topic, payload, ts| { evt_topic: topic, evt_payload: payload, evt_timestamp: ts }

	event_log_new : I64 -> EventBus.EventLog
	event_log_new = |max| { log_events: [], log_count: 0, log_max: max }

	event_log_add : EventBus.EventLog, EventBus.BusEvent -> EventBus.EventLog
	event_log_add = |log, evt| ({
		events = (if (log.log_count >= log.log_max) { List.append(evt_drop_first(log.log_events), evt) } else { List.append(log.log_events, evt) })
		count = (if (log.log_count >= log.log_max) { log.log_max } else { (log.log_count + 1) })
		{ log_events: events, log_count: count, log_max: log.log_max }
	})

	evt_drop_first : List(EventBus.BusEvent) -> List(EventBus.BusEvent)
	evt_drop_first = |xs| evt_drop_loop(xs, 1, U64.to_i64_wrap(List.len(xs)), [])

	evt_drop_loop : List(EventBus.BusEvent), I64, I64, List(EventBus.BusEvent) -> List(EventBus.BusEvent)
	evt_drop_loop = |xs, i, n, acc| (if (i >= n) { acc } else { evt_drop_loop(xs, (i + 1), n, List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	event_log_filter : EventBus.EventLog, Text -> List(EventBus.BusEvent)
	event_log_filter = |log, topic| evt_filter_loop(log.log_events, topic, 0, log.log_count, [])

	evt_filter_loop : List(EventBus.BusEvent), Text, I64, I64, List(EventBus.BusEvent) -> List(EventBus.BusEvent)
	evt_filter_loop = |events, topic, i, n, acc| (if (i >= n) { acc } else { ({
		e = (List.get(events, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
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

	evt_format_event : EventBus.BusEvent -> Text
	evt_format_event = |e| Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("[", Text.show_int(e.evt_timestamp)), "] "), e.evt_topic), ": "), e.evt_payload)

	evt_format_event_log : EventBus.EventLog -> Text
	evt_format_event_log = |log| Text.concat(Text.concat(Text.concat(Text.show_int(log.log_count), "/"), Text.show_int(log.log_max)), " events")
}
