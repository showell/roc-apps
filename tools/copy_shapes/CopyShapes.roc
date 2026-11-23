app [main!] {}

# The copy shapes: one small loop for each way of writing into a list, a
# record or a dict, run by tools/copy_shapes/copy_shapes.shale on the
# allocation ladder (tools/alloc_ladder.shale).
#
#   copy-shapes <shape> <size> <steps>
#
# Each shape makes a list (or a dict) of `size` entries, then writes into it
# `steps` times. **A WRITE IN PLACE ALLOCATES NOTHING; A COPY ALLOCATES THE
# WHOLE LIST AGAIN**, so the ladder's count for one more step says which a
# shape is: 0 is in place, 1 or more a copy of `size` entries each step.
# The expected files beside this one hold each shape's count in the release
# and the dev build, and docs/roc-notes.md, "Speed and copying", says what
# each one shows.
#
# **EVERY SHAPE IS WRITTEN AS IT IS MEASURED**, so some of them break the
# style guide on purpose (`?? xs`, a closure read after the write): the
# shape is the point. Pairs that differ in one line sit next to each other,
# the one that writes in place first.

main! = |args| {
	shape = args.get(0) ?? crash "usage: copy-shapes <shape> <size> <steps>"
	size = count_at(args, 1)
	steps = count_at(args, 2)
	echo!(U64.to_str(run_shape(shape, args, { size, steps })))
	Ok({})
}

## How big the list is and how many writes go into it.
Sizes : { size : U64, steps : U64 }

## A count from the command line, which crashes on anything but a number:
## the script that runs this program is its only caller.
count_at : List(Str), U64 -> U64
count_at = |args, k| {
	text = args.get(k) ?? crash "usage: copy-shapes <shape> <size> <steps>"
	U64.from_str(text) ?? crash "copy-shapes: a size or a step count is a number"
}

## The shape by its name. `args` is the command line, which `host-args-list`
## writes into.
run_shape : Str, List(Str), Sizes -> U64
run_shape = |shape, args, { size, steps }| {
	match shape {
		"set-restored" => set_restored(0, steps, size, List.repeat(0, size), 0)
		"set-or-empty" => set_or_empty(0, steps, size, List.repeat(0, size), 0)
		"set-or-crash" => set_or_crash(0, steps, size, List.repeat(0, size), 0)
		"get-after-set" => get_after_set(0, steps, size, List.repeat(0, size), 0)
		"closure-called-before" => closure_called_before(0, steps, size, List.repeat(0, size), 0)
		"closure-called-after" => closure_called_after(0, steps, size, List.repeat(0, size), 0)
		"helper-returns-list" => helper_returns_list(0, steps, size, List.repeat(0, size), 0)
		"helper-len-before-set" => helper_len_before_set(0, steps, size, List.repeat(0, size), 0)
		"helper-len-after-set" => helper_len_after_set(0, steps, size, List.repeat(0, size), 0)
		"record-rebuilt" => record_rebuilt(0, steps, size, { items: List.repeat(0, size), total: 0 })
		"record-len-before-set" => record_len_before_set(0, steps, size, { items: List.repeat(0, size), total: 0 })
		"record-len-after-set" => record_len_after_set(0, steps, size, { items: List.repeat(0, size), total: 0 })
		"record-update" => record_update(0, steps, size, { items: List.repeat(0, size), total: 0 })
		"field-inside-update" => field_inside_update(0, steps, size, { items: List.repeat(0, size), total: 0 })
		"field-taken-out-first" => field_taken_out_first(0, steps, size, { items: List.repeat(0, size), total: 0 })
		"index-computed-first" => index_computed_first(0, steps, size, { scr: List.repeat(0, size), base: 0 })
		"index-bound-before" => index_bound_before(0, steps, size, { scr: List.repeat(0, size), base: 0 })
		"helper-reads-record" => helper_reads_record(0, steps, size, { scr: List.repeat(0, size), base: 0 })
		"append-after-drop" => append_after_drop(0, steps, size, List.repeat(0, size), 0)
		"append-len-after" => append_len_after(0, steps, size, List.repeat(0, size), 0)
		"nested-update" => nested_update(0, steps, size, [List.repeat(0, size), [1]], 0)
		"nested-get-then-set" => nested_get_then_set(0, steps, size, [List.repeat(0, size), [1]], 0)
		"dict-insert" => dict_insert(0, steps, size, filled(0, size, Dict.empty()), 0)
		"dict-len-after-insert" => dict_len_after_insert(0, steps, size, filled(0, size, Dict.empty()), 0)
		"dict-take-then-insert" => dict_take_then_insert(0, steps, size, Dict.empty().insert(0, List.repeat(0, size)), 0)
		"dict-get-then-insert" => dict_get_then_insert(0, steps, size, Dict.empty().insert(0, List.repeat(0, size)), 0)
		"str-list-restored" => str_list_restored(0, steps, size, List.repeat("a", size), 0)
		"str-list-or-crash" => str_list_or_crash(0, steps, size, List.repeat("a", size), 0)
		"host-args-list" => str_list_restored(0, steps, args.len(), args, 0)
		_ => crash "copy-shapes: no such shape"
	}
}

# ── A list written in one function ──

## Reads before the write, and `?? xs`: the fallback hands the list back on
## its error path, which RC1 sees through, so on a list of numbers it costs
## nothing in every build (a list of strings is `str-list-restored`).
set_restored : U64, U64, U64, List(U64), U64 -> U64
set_restored = |i, steps, size, xs, acc| {
	if i >= steps {
		acc + xs.len()
	} else {
		j = i % size
		v = xs.get(j) ?? 0
		ys = xs.set(j, v + 1) ?? xs
		set_restored(i + 1, steps, size, ys, acc + v)
	}
}

## `set-restored` with `?? []`.
set_or_empty : U64, U64, U64, List(U64), U64 -> U64
set_or_empty = |i, steps, size, xs, acc| {
	if i >= steps {
		acc + xs.len()
	} else {
		j = i % size
		v = xs.get(j) ?? 0
		ys = xs.set(j, v + 1) ?? []
		set_or_empty(i + 1, steps, size, ys, acc + v)
	}
}

## `set-restored` with `?? crash`, the style guide's form.
set_or_crash : U64, U64, U64, List(U64), U64 -> U64
set_or_crash = |i, steps, size, xs, acc| {
	if i >= steps {
		acc + xs.len()
	} else {
		j = i % size
		ys = xs.set(j, i) ?? crash "set_or_crash: in range"
		set_or_crash(i + 1, steps, size, ys, acc + j)
	}
}

## **COPIES:** the old list read after the write, so the write can't take it.
get_after_set : U64, U64, U64, List(U64), U64 -> U64
get_after_set = |i, steps, size, xs, acc| {
	if i >= steps {
		acc + xs.len()
	} else {
		j = i % size
		ys = xs.set(j, i) ?? xs
		v = xs.get(j) ?? 0
		get_after_set(i + 1, steps, size, ys, acc + v)
	}
}

## A closure over the list, called inside the write's own arguments.
closure_called_before : U64, U64, U64, List(U64), U64 -> U64
closure_called_before = |i, steps, size, xs, acc| {
	if i >= steps {
		acc + xs.len()
	} else {
		j = i % size
		at = |k| xs.get(k) ?? 0
		ys = xs.set(j, at(j) + 1) ?? xs
		closure_called_before(i + 1, steps, size, ys, acc + j)
	}
}

## **COPIES:** the same closure called after the write: it still holds the
## old list.
closure_called_after : U64, U64, U64, List(U64), U64 -> U64
closure_called_after = |i, steps, size, xs, acc| {
	if i >= steps {
		acc + xs.len()
	} else {
		j = i % size
		at = |k| xs.get(k) ?? 0
		ys = xs.set(j, i) ?? xs
		closure_called_after(i + 1, steps, size, ys, acc + at(j))
	}
}

# ── A list written through a helper ──

peek : List(U64) -> (List(U64), U64)
peek = |xs| (xs, xs.len())

## A helper that hands the list back with its length.
helper_returns_list : U64, U64, U64, List(U64), U64 -> U64
helper_returns_list = |i, steps, size, xs, acc| {
	if i >= steps {
		acc + xs.len()
	} else {
		j = i % size
		(xs2, len) = peek(xs)
		ys = xs2.set(j, len) ?? xs2
		helper_returns_list(i + 1, steps, size, ys, acc + len)
	}
}

bump_len_first : List(U64), U64, U64 -> (List(U64), U64)
bump_len_first = |xs, j, v| {
	len = xs.len()
	(xs.set(j, v) ?? xs, len)
}

## A helper that reads the length, then writes.
helper_len_before_set : U64, U64, U64, List(U64), U64 -> U64
helper_len_before_set = |i, steps, size, xs, acc| {
	if i >= steps {
		acc + xs.len()
	} else {
		j = i % size
		(ys, len) = bump_len_first(xs, j, i)
		helper_len_before_set(i + 1, steps, size, ys, acc + len)
	}
}

bump_len_after : List(U64), U64, U64 -> (List(U64), U64)
bump_len_after = |xs, j, v| (xs.set(j, v) ?? xs, xs.len())

## **COPIES IN THE DEV BUILD ONLY:** a helper that reads the length after
## its write. The release build specializes the helper and writes in place.
helper_len_after_set : U64, U64, U64, List(U64), U64 -> U64
helper_len_after_set = |i, steps, size, xs, acc| {
	if i >= steps {
		acc + xs.len()
	} else {
		j = i % size
		(ys, len) = bump_len_after(xs, j, i)
		helper_len_after_set(i + 1, steps, size, ys, acc + len)
	}
}

# ── A list in a record ──

## A record with a list in it.
Totals : { items : List(U64), total : U64 }

## The record built again, `?? st.items` as the fallback.
record_rebuilt : U64, U64, U64, Totals -> U64
record_rebuilt = |i, steps, size, st| {
	if i >= steps {
		st.total + st.items.len()
	} else {
		j = i % size
		record_rebuilt(i + 1, steps, size, { items: st.items.set(j, i) ?? st.items, total: st.total + 1 })
	}
}

## The list's length read in the field before the write.
record_len_before_set : U64, U64, U64, Totals -> U64
record_len_before_set = |i, steps, size, st| {
	if i >= steps {
		st.total + st.items.len()
	} else {
		j = i % size
		record_len_before_set(i + 1, steps, size, { total: st.total + st.items.len(), items: st.items.set(j, i) ?? st.items })
	}
}

## The list's length read in the field after the write: in one function
## body a length read after the write costs nothing.
record_len_after_set : U64, U64, U64, Totals -> U64
record_len_after_set = |i, steps, size, st| {
	if i >= steps {
		st.total + st.items.len()
	} else {
		j = i % size
		record_len_after_set(i + 1, steps, size, { items: st.items.set(j, i) ?? st.items, total: st.total + st.items.len() })
	}
}

## A record update.
record_update : U64, U64, U64, Totals -> U64
record_update = |i, steps, size, st| {
	if i >= steps {
		st.total + st.items.len()
	} else {
		j = i % size
		record_update(i + 1, steps, size, { ..st, items: st.items.set(j, i) ?? st.items })
	}
}

## A record update, `?? crash` as the fallback.
field_inside_update : U64, U64, U64, Totals -> U64
field_inside_update = |i, steps, size, st| {
	if i >= steps {
		st.total + st.items.len()
	} else {
		j = i % size
		field_inside_update(i + 1, steps, size, { ..st, items: st.items.set(j, i) ?? crash "field_inside_update: in range" })
	}
}

## The field taken out in a statement of its own, then written back: the
## old nightlies copied this, RC1 doesn't.
field_taken_out_first : U64, U64, U64, Totals -> U64
field_taken_out_first = |i, steps, size, st| {
	if i >= steps {
		st.total + st.items.len()
	} else {
		j = i % size
		items = st.items
		field_taken_out_first(i + 1, steps, size, { ..st, items: items.set(j, i) ?? crash "field_taken_out_first: in range" })
	}
}

## A screen and where it starts, as BASIC's devices hold one.
Screen : { scr : List(U64), base : U64 }

## Where a cell is kept, read from the whole record.
kept : Screen, U64 -> U64
kept = |d, a| (a + d.base) % d.scr.len()

## The index computed without the record.
index_computed_first : U64, U64, U64, Screen -> U64
index_computed_first = |i, steps, size, d| {
	if i >= steps {
		d.base + d.scr.len()
	} else {
		j = i % size
		index_computed_first(i + 1, steps, size, { ..d, scr: d.scr.set(j, i) ?? crash "index_computed_first: in range" })
	}
}

## The index from `kept`, bound on the line before the write.
index_bound_before : U64, U64, U64, Screen -> U64
index_bound_before = |i, steps, size, d| {
	if i >= steps {
		d.base + d.scr.len()
	} else {
		j = i % size
		k = kept(d, j)
		index_bound_before(i + 1, steps, size, { ..d, scr: d.scr.set(k, i) ?? crash "index_bound_before: in range" })
	}
}

## **COPIES IN THE DEV BUILD ONLY:** the index from `kept`, which reads the
## whole record, inside the write of its field (BASIC's Devices.poked).
helper_reads_record : U64, U64, U64, Screen -> U64
helper_reads_record = |i, steps, size, d| {
	if i >= steps {
		d.base + d.scr.len()
	} else {
		j = i % size
		helper_reads_record(i + 1, steps, size, { ..d, scr: d.scr.set(kept(d, j), i) ?? crash "helper_reads_record: in range" })
	}
}

# ── Appending ──

## The last entry dropped and one appended.
append_after_drop : U64, U64, U64, List(U64), U64 -> U64
append_after_drop = |i, steps, size, xs, acc| {
	if i >= steps {
		acc + xs.len()
	} else {
		j = i % size
		ys = xs.drop_last(1).append(i)
		append_after_drop(i + 1, steps, size, ys, acc + j)
	}
}

## The same, and the old list's length read after it.
append_len_after : U64, U64, U64, List(U64), U64 -> U64
append_len_after = |i, steps, size, xs, acc| {
	if i >= steps {
		acc + xs.len()
	} else {
		j = i % size
		ys = xs.drop_last(1).append(i)
		append_len_after(i + 1, steps, size, ys, acc + j + xs.len())
	}
}

# ── A list of lists ──

## `List.update` on the inner list: it hands the element over unshared.
nested_update : U64, U64, U64, List(List(U64)), U64 -> U64
nested_update = |i, steps, size, xss, acc| {
	if i >= steps {
		acc + xss.len()
	} else {
		j = i % size
		yss = xss.update(0, |inner| inner.set(j, i) ?? crash "nested_update: inner in range") ?? crash "nested_update: outer in range"
		nested_update(i + 1, steps, size, yss, acc + j)
	}
}

## **COPIES:** the inner list got, written, and set back: the outer list
## still holds it while it is written.
nested_get_then_set : U64, U64, U64, List(List(U64)), U64 -> U64
nested_get_then_set = |i, steps, size, xss, acc| {
	if i >= steps {
		acc + xss.len()
	} else {
		j = i % size
		inner = xss.get(0) ?? crash "nested_get_then_set: outer in range"
		yss = xss.set(0, inner.set(j, i) ?? crash "nested_get_then_set: inner in range") ?? crash "nested_get_then_set: outer in range"
		nested_get_then_set(i + 1, steps, size, yss, acc + j)
	}
}

# ── A dict ──

filled : U64, U64, Dict(U64, U64) -> Dict(U64, U64)
filled = |k, size, d| if (k >= size) d else filled(k + 1, size, d.insert(k, 0))

## An insert over a key already there.
dict_insert : U64, U64, U64, Dict(U64, U64), U64 -> U64
dict_insert = |i, steps, size, d, acc| {
	if i >= steps {
		acc + d.len()
	} else {
		j = i % size
		d2 = d.insert(j, i)
		dict_insert(i + 1, steps, size, d2, acc + j)
	}
}

## **COPIES:** the old dict's length read after the insert.
dict_len_after_insert : U64, U64, U64, Dict(U64, U64), U64 -> U64
dict_len_after_insert = |i, steps, size, d, acc| {
	if i >= steps {
		acc + d.len()
	} else {
		j = i % size
		d2 = d.insert(j, i)
		dict_len_after_insert(i + 1, steps, size, d2, acc + d.len())
	}
}

## A list kept in a dict, taken out (got, then removed), written and put
## back.
dict_take_then_insert : U64, U64, U64, Dict(U64, List(U64)), U64 -> U64
dict_take_then_insert = |i, steps, size, d, acc| {
	if i >= steps {
		acc + d.len()
	} else {
		j = i % size
		l = d.get(0) ?? crash "dict_take_then_insert: key 0 is there"
		d0 = d.remove(0)
		dict_take_then_insert(i + 1, steps, size, d0.insert(0, l.set(j, i) ?? l), acc + j)
	}
}

## **COPIES:** the list got from the dict and written while the dict still
## holds it.
dict_get_then_insert : U64, U64, U64, Dict(U64, List(U64)), U64 -> U64
dict_get_then_insert = |i, steps, size, d, acc| {
	if i >= steps {
		acc + d.len()
	} else {
		j = i % size
		l = d.get(0) ?? crash "dict_get_then_insert: key 0 is there"
		dict_get_then_insert(i + 1, steps, size, d.insert(0, l.set(j, i) ?? l), acc + j)
	}
}

# ── A list of strings ──

## **COPIES IN THE DEV AND BOXY BUILDS:** `set-restored` on a list of
## strings, `?? xs` and all. The fallback is free only where the entries hold
## no reference count. It writes past the first three entries, so
## `host-args-list` keeps its own shape, size and step count.
str_list_restored : U64, U64, U64, List(Str), U64 -> U64
str_list_restored = |i, steps, size, xs, acc| {
	if i >= steps {
		acc + xs.len()
	} else {
		j = 3 + i % (size - 3)
		ys = xs.set(j, "x") ?? xs
		str_list_restored(i + 1, steps, size, ys, acc + j)
	}
}

## `str-list-restored` with `?? crash`, which every build writes in place.
str_list_or_crash : U64, U64, U64, List(Str), U64 -> U64
str_list_or_crash = |i, steps, size, xs, acc| {
	if i >= steps {
		acc + xs.len()
	} else {
		j = 3 + i % (size - 3)
		ys = xs.set(j, "x") ?? crash "str_list_or_crash: in range"
		str_list_or_crash(i + 1, steps, size, ys, acc + j)
	}
}
