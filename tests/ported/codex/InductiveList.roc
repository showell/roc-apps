# InductiveList -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

InductiveList :: [].{
	IList(a) := [INil, ICons(a, InductiveList.IList(a))].{
		is_eq : InductiveList.IList(a), InductiveList.IList(a) -> Bool where [a.is_eq : a, a -> Bool]
		is_eq = |a, b| eq_IList(a, b)
	}

	ilist_append : InductiveList.IList(a), InductiveList.IList(a) -> InductiveList.IList(a)
	ilist_append = |xs, ys| (match xs {
		INil => ys
		ICons(h, t) => ICons(h, ilist_append(t, ys))
	})

	ilist_reverse : InductiveList.IList(a) -> InductiveList.IList(a)
	ilist_reverse = |xs| (match xs {
		INil => INil
		ICons(h, t) => ilist_append(ilist_reverse(t), ICons(h, INil))
	})

	ilist_length : InductiveList.IList(a) -> I64
	ilist_length = |xs| (match xs {
		INil => 0
		ICons(_h, t) => (1 + ilist_length(t))
	})

	ilist_from_list : List(a) -> InductiveList.IList(a)
	ilist_from_list = |xs| ilist_from_list_loop(xs, (U64.to_i64_wrap(List.len(xs)) - 1), INil)

	ilist_from_list_loop : List(a), I64, InductiveList.IList(a) -> InductiveList.IList(a)
	ilist_from_list_loop = |xs, i, acc| (if (i < 0) { acc } else { ilist_from_list_loop(xs, (i - 1), ICons((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), acc)) })

	ilist_to_list : InductiveList.IList(a) -> List(a)
	ilist_to_list = |xs| ilist_to_list_loop(xs, [])

	ilist_to_list_loop : InductiveList.IList(a), List(a) -> List(a)
	ilist_to_list_loop = |xs, acc| (match xs {
		INil => acc
		ICons(h, t) => ilist_to_list_loop(t, List.append(acc, h))
	})

	eq_IList : InductiveList.IList(a), InductiveList.IList(a) -> Bool where [a.is_eq : a, a -> Bool]
	eq_IList = |ex, ey| (match ex {
		INil => (match ey {
			INil => True
			_ => False
		})
		ICons(exf0, exf1) => (match ey {
			ICons(eyf0, eyf1) => ((exf0 == eyf0) and eq_IList(exf1, eyf1))
			_ => False
		})
	})
}
