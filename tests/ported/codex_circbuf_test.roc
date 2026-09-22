# circbuf-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/circbuf-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     count=3 front=10 back=30
#     overflow front=2 count=3
#     after-pop=20 count=1
#     list=1,2,3
#     sum=600

app [main!] { cdx: "./codex/main.roc" }

import cdx.CircularBuffer
import cdx.Text

# CircBufTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

test_push_pop : List(U8)
test_push_pop = ({
	b = CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_new(5), 10), 20), 30)
	f = CircularBuffer.circbuf_front(b)
	bk = CircularBuffer.circbuf_back(b)
	(match f {
		Just(fv) => (match bk {
			Just(bv) => List.concat(List.concat(List.concat(List.concat(List.concat([24, 16, 25, 18, 14, 77], Text.show_int(CircularBuffer.circbuf_count(b))), [2, 28, 21, 16, 18, 14, 77]), Text.show_int(fv)), [2, 32, 15, 24, 34, 77]), Text.show_int(bv))
			None => [32, 34, 73, 18, 16, 18, 13]
			None => [28, 73, 18, 16, 18, 13]
		})
	})
})

test_overflow : List(U8)
test_overflow = ({
	b = CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_new(3), 1), 2), 3), 4)
	f = CircularBuffer.circbuf_front(b)
	(match f {
		Just(fv) => List.concat(List.concat(List.concat([16, 33, 13, 21, 28, 23, 16, 27, 2, 28, 21, 16, 18, 14, 77], Text.show_int(fv)), [2, 24, 16, 25, 18, 14, 77]), Text.show_int(CircularBuffer.circbuf_count(b)))
		None => [18, 16, 18, 13]
	})
})

test_pop : List(U8)
test_pop = ({
	b = CircularBuffer.circbuf_pop_front(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_new(5), 10), 20))
	f = CircularBuffer.circbuf_front(b)
	(match f {
		Just(fv) => List.concat(List.concat(List.concat([15, 28, 14, 13, 21, 73, 31, 16, 31, 77], Text.show_int(fv)), [2, 24, 16, 25, 18, 14, 77]), Text.show_int(CircularBuffer.circbuf_count(b)))
		None => [13, 26, 31, 14, 30]
	})
})

test_to_list : List(U8)
test_to_list = ({
	b = CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_new(5), 1), 2), 3)
	lst = CircularBuffer.circbuf_to_list(b)
	List.concat(List.concat(List.concat(List.concat(List.concat([23, 17, 19, 14, 77], Text.show_int((List.get(lst, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))), [66]), Text.show_int((List.get(lst, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))), [66]), Text.show_int((List.get(lst, I64.to_u64_wrap(2)) ?? crash("list-at out of range"))))
})

test_sum : List(U8)
test_sum = ({
	b = CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_new(10), 100), 200), 300)
	List.concat([19, 25, 26, 77], Text.show_int(CircularBuffer.circbuf_sum(b)))
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(test_push_pop))
	line!(Text.printed(test_overflow))
	line!(Text.printed(test_pop))
	line!(Text.printed(test_to_list))
	line!(Text.printed(test_sum))
	Ok({})
}
