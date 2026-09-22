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

import cdx.EventBus
import cdx.Text

# EventBusTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

test_log : List(U8)
test_log = ({
	log = EventBus.event_log_new(10)
	log1 = EventBus.event_log_add(log, EventBus.event_new([32, 16, 16, 14], [19, 14, 15, 21, 14, 13, 22], 100))
	log2 = EventBus.event_log_add(log1, EventBus.event_new([18, 13, 14], [24, 16, 18, 18, 13, 24, 14, 13, 22], 200))
	log3 = EventBus.event_log_add(log2, EventBus.event_new([32, 16, 16, 14], [21, 13, 15, 22, 30], 300))
	EventBus.evt_format_event_log(log3)
})

test_filter : List(U8)
test_filter = ({
	log = EventBus.event_log_add(EventBus.event_log_add(EventBus.event_log_add(EventBus.event_log_new(10), EventBus.event_new([32, 16, 16, 14], [19, 14, 15, 21, 14, 13, 22], 100)), EventBus.event_new([18, 13, 14], [25, 31], 200)), EventBus.event_new([32, 16, 16, 14], [21, 13, 15, 22, 30], 300))
	boots = EventBus.event_log_filter(log, [32, 16, 16, 14])
	List.concat([32, 16, 16, 14, 73, 13, 33, 13, 18, 14, 19, 77], Text.show_int(U64.to_i64_wrap(List.len(boots))))
})

test_last : List(U8)
test_last = ({
	log = EventBus.event_log_add(EventBus.event_log_add(EventBus.event_log_new(10), EventBus.event_new([15], [4], 10)), EventBus.event_new([32], [5], 20))
	last = EventBus.event_log_last(log)
	(match last {
		Just(e) => List.concat([23, 15, 19, 14, 77], EventBus.evt_format_event(e))
		None => [23, 15, 19, 14, 77, 18, 16, 18, 13]
	})
})

test_since : List(U8)
test_since = ({
	log = EventBus.event_log_add(EventBus.event_log_add(EventBus.event_log_add(EventBus.event_log_new(10), EventBus.event_new([15], [4], 100)), EventBus.event_new([32], [5], 200)), EventBus.event_new([24], [6], 300))
	recent = EventBus.event_log_since(log, 200)
	List.concat([19, 17, 18, 24, 13, 73, 5, 3, 3, 77], Text.show_int(U64.to_i64_wrap(List.len(recent))))
})

test_overflow : List(U8)
test_overflow = ({
	log = EventBus.event_log_add(EventBus.event_log_add(EventBus.event_log_add(EventBus.event_log_add(EventBus.event_log_new(3), EventBus.event_new([15], [4], 1)), EventBus.event_new([32], [5], 2)), EventBus.event_new([24], [6], 3)), EventBus.event_new([22], [7], 4))
	List.concat([16, 33, 13, 21, 28, 23, 16, 27, 77], EventBus.evt_format_event_log(log))
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(test_log))
	line!(Text.printed(test_filter))
	line!(Text.printed(test_last))
	line!(Text.printed(test_since))
	line!(Text.printed(test_overflow))
	Ok({})
}
