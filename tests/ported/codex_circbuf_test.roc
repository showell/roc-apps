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

# CircBufTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

test_push_pop : Str
test_push_pop = ({
	b = CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_new(5), 10), 20), 30)
	f = CircularBuffer.circbuf_front(b)
	bk = CircularBuffer.circbuf_back(b)
	(match f {
		Just(fv) => (match bk {
			Just(bv) => Str.concat(Str.concat(Str.concat(Str.concat(Str.concat("count=", I64.to_str(CircularBuffer.circbuf_count(b))), " front="), I64.to_str(fv)), " back="), I64.to_str(bv))
			None => "bk-none"
			None => "f-none"
		})
	})
})

test_overflow : Str
test_overflow = ({
	b = CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_new(3), 1), 2), 3), 4)
	f = CircularBuffer.circbuf_front(b)
	(match f {
		Just(fv) => Str.concat(Str.concat(Str.concat("overflow front=", I64.to_str(fv)), " count="), I64.to_str(CircularBuffer.circbuf_count(b)))
		None => "none"
	})
})

test_pop : Str
test_pop = ({
	b = CircularBuffer.circbuf_pop_front(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_new(5), 10), 20))
	f = CircularBuffer.circbuf_front(b)
	(match f {
		Just(fv) => Str.concat(Str.concat(Str.concat("after-pop=", I64.to_str(fv)), " count="), I64.to_str(CircularBuffer.circbuf_count(b)))
		None => "empty"
	})
})

test_to_list : Str
test_to_list = ({
	b = CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_new(5), 1), 2), 3)
	lst = CircularBuffer.circbuf_to_list(b)
	Str.concat(Str.concat(Str.concat(Str.concat(Str.concat("list=", I64.to_str((List.get(lst, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))), ","), I64.to_str((List.get(lst, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))), ","), I64.to_str((List.get(lst, I64.to_u64_wrap(2)) ?? crash("list-at out of range"))))
})

test_sum : Str
test_sum = ({
	b = CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_push_back(CircularBuffer.circbuf_new(10), 100), 200), 300)
	Str.concat("sum=", I64.to_str(CircularBuffer.circbuf_sum(b)))
})

# --- Entry ---

main! = |_args| {
	line!(test_push_pop)
	line!(test_overflow)
	line!(test_pop)
	line!(test_to_list)
	line!(test_sum)
	Ok({})
}
