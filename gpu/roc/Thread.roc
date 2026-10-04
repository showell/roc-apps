# Thread -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Thread :: [].{
	ThreadIndex := { ti_value : I32 }.{
		is_eq : Thread.ThreadIndex, Thread.ThreadIndex -> Bool
		is_eq = |a, b| eq_ThreadIndex(a, b)
	}

	make_thread_index : I32 -> Thread.ThreadIndex
	make_thread_index = |val| Thread.ThreadIndex.{ ti_value: val }

	thread_index_get : Thread.ThreadIndex -> I32
	thread_index_get = |idx| idx.ti_value

	eq_ThreadIndex : Thread.ThreadIndex, Thread.ThreadIndex -> Bool
	eq_ThreadIndex = |ex, ey| (ex.ti_value == ey.ti_value)
}
