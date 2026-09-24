# eventbus-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/eventbus-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     3/10 events
#     boot-events=2
#     last=[20] b: 2
#     since-200=2
#     overflow=3/3 events

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.EventBus

# EventBusTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

test_log : CceText
test_log = ({
	log = EventBus.event_log_new(10)
	log1 = EventBus.event_log_add(log, EventBus.event_new("boot", "started", 100))
	log2 = EventBus.event_log_add(log1, EventBus.event_new("net", "connected", 200))
	log3 = EventBus.event_log_add(log2, EventBus.event_new("boot", "ready", 300))
	EventBus.evt_format_event_log(log3)
})

test_filter : CceText
test_filter = ({
	log = EventBus.event_log_add(EventBus.event_log_add(EventBus.event_log_add(EventBus.event_log_new(10), EventBus.event_new("boot", "started", 100)), EventBus.event_new("net", "up", 200)), EventBus.event_new("boot", "ready", 300))
	boots = EventBus.event_log_filter(log, "boot")
	CceText.concat("boot-events=", CceText.show_int(U64.to_i64_wrap(List.len(boots))))
})

test_last : CceText
test_last = ({
	log = EventBus.event_log_add(EventBus.event_log_add(EventBus.event_log_new(10), EventBus.event_new("a", "1", 10)), EventBus.event_new("b", "2", 20))
	last = EventBus.event_log_last(log)
	(match last {
		Just(e) => CceText.concat("last=", EventBus.evt_format_event(e))
		None => "last=none"
	})
})

test_since : CceText
test_since = ({
	log = EventBus.event_log_add(EventBus.event_log_add(EventBus.event_log_add(EventBus.event_log_new(10), EventBus.event_new("a", "1", 100)), EventBus.event_new("b", "2", 200)), EventBus.event_new("c", "3", 300))
	recent = EventBus.event_log_since(log, 200)
	CceText.concat("since-200=", CceText.show_int(U64.to_i64_wrap(List.len(recent))))
})

test_overflow : CceText
test_overflow = ({
	log = EventBus.event_log_add(EventBus.event_log_add(EventBus.event_log_add(EventBus.event_log_add(EventBus.event_log_new(3), EventBus.event_new("a", "1", 1)), EventBus.event_new("b", "2", 2)), EventBus.event_new("c", "3", 3)), EventBus.event_new("d", "4", 4))
	CceText.concat("overflow=", EventBus.evt_format_event_log(log))
})

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(test_log))
	line!(CceText.printed(test_filter))
	line!(CceText.printed(test_last))
	line!(CceText.printed(test_since))
	line!(CceText.printed(test_overflow))
	Ok({})
}
