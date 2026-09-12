# Cells a program writes one at a time: POKE's address space, and each
# BASIC array.
#
# **A LIST ROC CAN STILL REACH IS A LIST ROC COPIES.** A machine is a
# record handed from statement to statement, and a flat list of cells
# nested inside it is written in place only while nothing else refers to
# it; one stray reference and every write copies all of it. So the cells
# live in fixed-size pages, and a write takes its page out of the table,
# writes it, and puts it back. At worst a write copies a page.
#
# A page nobody has written is an empty list and reads as the fill, so a
# large space costs nothing until it is used.

Pages :: [].{
	size : U64
	size = 4096

	# `n` cells, every one reading as the fill until it is written.
	new : U64 -> List(List(a))
	new = |n| List.repeat([], U64.div_trunc_by(n + Pages.size - 1, Pages.size))

	get : List(List(a)), U64, a -> a
	get = |ps, i, fill| List.get(List.get(ps, U64.div_trunc_by(i, Pages.size)) ?? [], U64.rem_by(i, Pages.size)) ?? fill

	# **THE PAGE COMES OUT OF THE TABLE BEFORE IT IS WRITTEN.** Written
	# where it stands, it is still reachable from the table, and the write
	# copies it.
	set : List(List(a)), U64, a, a -> List(List(a))
	set = |ps, i, v, fill| {
		p = U64.div_trunc_by(i, Pages.size)
		taken = List.replace(ps, p, []) ?? crash("Pages.set: a cell past the last page")
		page = if List.is_empty(taken.prev) { List.repeat(fill, Pages.size) } else { taken.prev }
		List.set(taken.list, p, List.set(page, U64.rem_by(i, Pages.size), v) ?? crash("Pages.set: a cell past its page")) ?? crash("Pages.set: a cell past the last page")
	}
}
