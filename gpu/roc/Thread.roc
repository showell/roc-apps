# Thread -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Thread :: [].{
	ThreadIndex : { ti_value : I64 }

	make_thread_index : I64 -> Thread.ThreadIndex
	make_thread_index = |val| { ti_value: val }

	thread_index_get : Thread.ThreadIndex -> I64
	thread_index_get = |idx| idx.ti_value
}
