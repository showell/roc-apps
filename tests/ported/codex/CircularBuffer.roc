# CircularBuffer -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import ListUtils
import MathLib
import Maybe

CircularBuffer :: [].{
	CircBuf := { cb_data : List(I64), cb_head : I64, cb_tail : I64, cb_count : I64, cb_capacity : I64 }.{
		is_eq : CircularBuffer.CircBuf, CircularBuffer.CircBuf -> Bool
		is_eq = |a, b| a.cb_data == b.cb_data and a.cb_head == b.cb_head and a.cb_tail == b.cb_tail and a.cb_count == b.cb_count and a.cb_capacity == b.cb_capacity
	}

	circbuf_new : I64 -> CircularBuffer.CircBuf
	circbuf_new = |cap| CircularBuffer.CircBuf.{ cb_data: ListUtils.list_zeros(cap), cb_head: 0, cb_tail: 0, cb_count: 0, cb_capacity: cap }

	circbuf_push_back : CircularBuffer.CircBuf, I64 -> CircularBuffer.CircBuf
	circbuf_push_back = |buf, val| (if (buf.cb_count >= buf.cb_capacity) { ({
		new_data = (List.set(buf.cb_data, I64.to_u64_wrap(buf.cb_tail), val) ?? crash("list-set-at past the end"))
		CircularBuffer.CircBuf.{ cb_data: new_data, cb_head: MathLib.math_mod((buf.cb_head + 1), buf.cb_capacity), cb_tail: MathLib.math_mod((buf.cb_tail + 1), buf.cb_capacity), cb_count: buf.cb_count, cb_capacity: buf.cb_capacity }
	}) } else { ({
		new_data = (List.set(buf.cb_data, I64.to_u64_wrap(buf.cb_tail), val) ?? crash("list-set-at past the end"))
		CircularBuffer.CircBuf.{ cb_data: new_data, cb_head: buf.cb_head, cb_tail: MathLib.math_mod((buf.cb_tail + 1), buf.cb_capacity), cb_count: (buf.cb_count + 1), cb_capacity: buf.cb_capacity }
	}) })

	circbuf_push_front : CircularBuffer.CircBuf, I64 -> CircularBuffer.CircBuf
	circbuf_push_front = |buf, val| ({
		new_head = MathLib.math_mod(((buf.cb_head - 1) + buf.cb_capacity), buf.cb_capacity)
		(if (buf.cb_count >= buf.cb_capacity) { ({
			new_tail = MathLib.math_mod(((buf.cb_tail - 1) + buf.cb_capacity), buf.cb_capacity)
			CircularBuffer.CircBuf.{ cb_data: (List.set(buf.cb_data, I64.to_u64_wrap(new_head), val) ?? crash("list-set-at past the end")), cb_head: new_head, cb_tail: new_tail, cb_count: buf.cb_count, cb_capacity: buf.cb_capacity }
		}) } else { CircularBuffer.CircBuf.{ cb_data: (List.set(buf.cb_data, I64.to_u64_wrap(new_head), val) ?? crash("list-set-at past the end")), cb_head: new_head, cb_tail: buf.cb_tail, cb_count: (buf.cb_count + 1), cb_capacity: buf.cb_capacity } })
	})

	circbuf_pop_front : CircularBuffer.CircBuf -> CircularBuffer.CircBuf
	circbuf_pop_front = |buf| (if (buf.cb_count == 0) { buf } else { CircularBuffer.CircBuf.{ cb_data: buf.cb_data, cb_head: MathLib.math_mod((buf.cb_head + 1), buf.cb_capacity), cb_tail: buf.cb_tail, cb_count: (buf.cb_count - 1), cb_capacity: buf.cb_capacity } })

	circbuf_pop_back : CircularBuffer.CircBuf -> CircularBuffer.CircBuf
	circbuf_pop_back = |buf| (if (buf.cb_count == 0) { buf } else { CircularBuffer.CircBuf.{ cb_data: buf.cb_data, cb_head: buf.cb_head, cb_tail: MathLib.math_mod(((buf.cb_tail - 1) + buf.cb_capacity), buf.cb_capacity), cb_count: (buf.cb_count - 1), cb_capacity: buf.cb_capacity } })

	circbuf_front : CircularBuffer.CircBuf -> Maybe.Maybe(I64)
	circbuf_front = |buf| (if (buf.cb_count == 0) { None } else { Just((List.get(buf.cb_data, I64.to_u64_wrap(buf.cb_head)) ?? crash("list-at out of range"))) })

	circbuf_back : CircularBuffer.CircBuf -> Maybe.Maybe(I64)
	circbuf_back = |buf| (if (buf.cb_count == 0) { None } else { Just((List.get(buf.cb_data, I64.to_u64_wrap(MathLib.math_mod(((buf.cb_tail - 1) + buf.cb_capacity), buf.cb_capacity))) ?? crash("list-at out of range"))) })

	circbuf_at : CircularBuffer.CircBuf, I64 -> Maybe.Maybe(I64)
	circbuf_at = |buf, i| (if (i < 0) { None } else { (if (i >= buf.cb_count) { None } else { Just((List.get(buf.cb_data, I64.to_u64_wrap(MathLib.math_mod((buf.cb_head + i), buf.cb_capacity))) ?? crash("list-at out of range"))) }) })

	circbuf_count : CircularBuffer.CircBuf -> I64
	circbuf_count = |buf| buf.cb_count

	circbuf_capacity : CircularBuffer.CircBuf -> I64
	circbuf_capacity = |buf| buf.cb_capacity

	circbuf_is_empty : CircularBuffer.CircBuf -> Bool
	circbuf_is_empty = |buf| (buf.cb_count == 0)

	circbuf_is_full : CircularBuffer.CircBuf -> Bool
	circbuf_is_full = |buf| (buf.cb_count >= buf.cb_capacity)

	circbuf_to_list : CircularBuffer.CircBuf -> List(I64)
	circbuf_to_list = |buf| circbuf_to_list_loop(buf, 0, buf.cb_count, [])

	circbuf_to_list_loop : CircularBuffer.CircBuf, I64, I64, List(I64) -> List(I64)
	circbuf_to_list_loop = |buf, i, n, acc| (if (i >= n) { acc } else { ({
		val = (List.get(buf.cb_data, I64.to_u64_wrap(MathLib.math_mod((buf.cb_head + i), buf.cb_capacity))) ?? crash("list-at out of range"))
		circbuf_to_list_loop(buf, (i + 1), n, List.append(acc, val))
	}) })

	circbuf_sum : CircularBuffer.CircBuf -> I64
	circbuf_sum = |buf| circbuf_sum_loop(buf, 0, buf.cb_count, 0)

	circbuf_sum_loop : CircularBuffer.CircBuf, I64, I64, I64 -> I64
	circbuf_sum_loop = |buf, i, n, acc| (if (i >= n) { acc } else { ({
		val = (List.get(buf.cb_data, I64.to_u64_wrap(MathLib.math_mod((buf.cb_head + i), buf.cb_capacity))) ?? crash("list-at out of range"))
		circbuf_sum_loop(buf, (i + 1), n, (acc + val))
	}) })
}
