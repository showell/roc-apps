# queue-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/queue-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     True
#     3

app [main!] { cdx: "./codex/main.roc" }

import cdx.Maybe
import cdx.Queue
import cdx.Text

# QueueTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

show_dequeue : Maybe.Maybe(Queue.DequeueResult(I64)) -> List(U8)
show_dequeue = |r| (match r {
	Just(dr) => Text.show_int(dr.value)
	None => [13, 26, 31, 14, 30]
})

test_queue : List(U8)
test_queue = ({
	q0 = Queue.queue_empty
	q1 = Queue.queue_enqueue(Queue.queue_enqueue(Queue.queue_enqueue(q0, 10), 20), 30)
	List.concat(List.concat((if Queue.queue_is_empty(q0) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }), [1]), Text.show_int(Queue.queue_size(q1)))
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(test_queue))
	Ok({})
}
