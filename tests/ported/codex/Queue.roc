# Queue -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Maybe

Queue :: [].{
	Queue(a) : { front : List(a), back : List(a) }
	DequeueResult(a) : { value : a, rest : Queue.Queue(a) }

	queue_empty : Queue.Queue(a)
	queue_empty = { front: [], back: [] }

	queue_is_empty : Queue.Queue(a) -> Bool
	queue_is_empty = |q| ((U64.to_i64_wrap(List.len(q.front)) == 0) and (U64.to_i64_wrap(List.len(q.back)) == 0))

	queue_size : Queue.Queue(a) -> I64
	queue_size = |q| (U64.to_i64_wrap(List.len(q.front)) + U64.to_i64_wrap(List.len(q.back)))

	queue_enqueue : Queue.Queue(a), a -> Queue.Queue(a)
	queue_enqueue = |q, x| { front: q.front, back: List.concat([x], q.back) }

	queue_dequeue : Queue.Queue(a) -> Maybe.Maybe(Queue.DequeueResult(a))
	queue_dequeue = |q| (if (U64.to_i64_wrap(List.len(q.front)) > 0) { Just({ value: (List.get(q.front, I64.to_u64_wrap(0)) ?? crash("list-at out of range")), rest: { front: queue_tail(q.front), back: q.back } }) } else { (if (U64.to_i64_wrap(List.len(q.back)) > 0) { ({
		reversed = reverse_list(q.back, 0, U64.to_i64_wrap(List.len(q.back)), [])
		Just({ value: (List.get(reversed, I64.to_u64_wrap(0)) ?? crash("list-at out of range")), rest: { front: queue_tail(reversed), back: [] } })
	}) } else { None }) })

	queue_peek : Queue.Queue(a) -> Maybe.Maybe(a)
	queue_peek = |q| (if (U64.to_i64_wrap(List.len(q.front)) > 0) { Just((List.get(q.front, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))) } else { (if (U64.to_i64_wrap(List.len(q.back)) > 0) { Just((List.get(q.back, I64.to_u64_wrap((U64.to_i64_wrap(List.len(q.back)) - 1))) ?? crash("list-at out of range"))) } else { None }) })

	queue_from_list : List(a) -> Queue.Queue(a)
	queue_from_list = |xs| { front: xs, back: [] }

	queue_to_list : Queue.Queue(a) -> List(a)
	queue_to_list = |q| List.concat(q.front, reverse_list(q.back, 0, U64.to_i64_wrap(List.len(q.back)), []))

	reverse_list : List(a), I64, I64, List(a) -> List(a)
	reverse_list = |xs, i, len, acc| (if (i == len) { acc } else { reverse_list(xs, (i + 1), len, List.concat([(List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))], acc)) })

	queue_tail : List(a) -> List(a)
	queue_tail = |xs| queue_tail_loop(xs, 1, U64.to_i64_wrap(List.len(xs)), [])

	queue_tail_loop : List(a), I64, I64, List(a) -> List(a)
	queue_tail_loop = |xs, i, len, acc| (if (i == len) { acc } else { queue_tail_loop(xs, (i + 1), len, List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })
}
