## This module holds the JavaScript heap as one Roc value: a list of cells,
## each an object, an array, a function or a builtin, named by its index.
## A JavaScript value that is shared by reference (an array, an object, a
## function) is a `Ref` to its cell, so two variables that hold one array hold
## one index, and a write through either is seen by both.
##
## **EVERY WRITE TAKES THE CELL OUT, WRITES IT AND PUTS IT BACK.** Roc writes
## a list in place only while nothing else refers to it. `List.replace` hands
## the cell over and leaves `Taken` in its place, so the props or items inside
## it are written while the cell is the only thing that refers to them, and a
## property write costs the property, never the object or the heap. Each
## writer takes the cell list itself and gives it back, and its callers pass
## it straight from the record they update (`{ ..st, cells:
## Heap.with_prop(st.cells, ...) }`), so the list is never referred to twice.
##
## Cells are never freed: a run's heap holds every object it made.
import Ast

Heap :: [].{
	Val : [
		Number(F64),
		Text(Str),
		Boolean(Bool),
		Null,
		Undefined,
		Ref(U64),
	]

	Prop : { key : Str, val : Heap.Val }

	# The builtin functions, each called by name from the interpreter.
	Native : [
		Log,
		Floor,
		Ceil,
		Round,
		Trunc,
		Abs,
		Sign,
		Sqrt,
		Pow,
		Min,
		Max,
		Sin,
		Cos,
		Tan,
		Atan,
		Keys,
		Values,
		Entries,
		StringOf,
		FromCharCode,
		IsArray,
		IsInteger,
	]

	Closure : { fun : Box(Ast.FunDef), scope : U64 }

	Cell : [
		Obj(List(Heap.Prop)),
		Arr(List(Heap.Val)),
		Fun(Heap.Closure),
		# A builtin function, and the properties it carries (`String.fromCharCode`).
		Builtin(Heap.Native, List(Heap.Prop)),
		# A builtin object such as `Math`, by its name.
		Namespace(Str, List(Heap.Prop)),
		# What a cell's place holds while the cell is out being written.
		Taken,
	]

	native_name : Heap.Native -> Str
	native_name = |n| match n {
		Log => "log"
		Floor => "floor"
		Ceil => "ceil"
		Round => "round"
		Trunc => "trunc"
		Abs => "abs"
		Sign => "sign"
		Sqrt => "sqrt"
		Pow => "pow"
		Min => "min"
		Max => "max"
		Sin => "sin"
		Cos => "cos"
		Tan => "tan"
		Atan => "atan"
		Keys => "keys"
		Values => "values"
		Entries => "entries"
		StringOf => "String"
		FromCharCode => "fromCharCode"
		IsArray => "isArray"
		IsInteger => "isInteger"
	}

	cell_at : List(Heap.Cell), U64 -> Heap.Cell
	cell_at = |cells, id| cells.get(id) ?? crash "Heap.cell_at: a Ref names a cell the heap has"

	# The value of a property an object has, or Undefined.
	prop_value : List(Heap.Prop), Str -> Heap.Val
	prop_value = |props, key|
		match props.find_first(|p| p.key == key) {
			Ok(p) => p.val
			Err(NotFound) => Undefined
		}

	has_prop : List(Heap.Prop), Str -> Bool
	has_prop = |props, key| props.any(|p| p.key == key)

	# Props with `key` set: in its place when it is there, else at the end.
	props_with : List(Heap.Prop), Str, Heap.Val -> List(Heap.Prop)
	props_with = |props, key, val|
		match props.find_first_index(|p| p.key == key) {
			Ok(i) => props.set(
				i,
				{ key: key, val: val },
			) ?? crash "Heap.props_with: the index was just found"
			Err(NotFound) => props.append({ key: key, val: val })
		}

	# The cell at `id` handed over, `Taken` left in its place.
	taken_out : List(Heap.Cell), U64 -> { list : List(Heap.Cell), prev : Heap.Cell }
	taken_out = |
		cells,
		id,
	| cells.replace(id, Taken) ?? crash "Heap.taken_out: a Ref names a cell the heap has"

	put_back : List(Heap.Cell), U64, Heap.Cell -> List(Heap.Cell)
	put_back = |
		cells,
		id,
		cell,
	| cells.set(id, cell) ?? crash "Heap.put_back: the cell was just taken"

	with_prop : List(Heap.Cell), U64, Str, Heap.Val -> List(Heap.Cell)
	with_prop = |cells, id, key, val| {
		taken = Heap.taken_out(cells, id)
		match taken.prev {
			Obj(props) => Heap.put_back(
				taken.list,
				id,
				Obj(Heap.props_with(props, key, val)),
			)
			_ => crash "Heap.with_prop: the interpreter writes properties only to objects"
		}
	}

	# The heap with an array's item `i` set, or appended when `i` is its length.
	with_item : List(Heap.Cell), U64, U64, Heap.Val -> List(Heap.Cell)
	with_item = |cells, id, i, val| {
		taken = Heap.taken_out(cells, id)
		match taken.prev {
			Arr(items) => Heap.put_back(
				taken.list,
				id,
				Arr(Heap.items_with(items, i, val)),
			)
			_ => crash "Heap.with_item: the interpreter writes items only to arrays"
		}
	}

	# **THE WRITE IS A FUNCTION OF ITS OWN.** Made inline in `with_item`'s match
	# arm, beside a binding of its own, it copied the items: every store into
	# an array of N items cost N.
	items_with : List(Heap.Val), U64, Heap.Val -> List(Heap.Val)
	items_with = |items, i, val|
		if i == items.len() {
			items.append(val)
		} else {
			items.set(
				i,
				val,
			) ?? crash "Heap.items_with: the interpreter writes inside an array or at its end"
		}

	with_items_pushed : List(Heap.Cell), U64, List(Heap.Val) -> List(Heap.Cell)
	with_items_pushed = |cells, id, vals| {
		taken = Heap.taken_out(cells, id)
		match taken.prev {
			Arr(items) => Heap.put_back(
				taken.list,
				id,
				Arr(List.concat(items, vals)),
			)
			_ => crash "Heap.with_items_pushed: the interpreter pushes only onto arrays"
		}
	}

	with_last_dropped : List(Heap.Cell), U64 -> List(Heap.Cell)
	with_last_dropped = |cells, id| {
		taken = Heap.taken_out(cells, id)
		match taken.prev {
			Arr(items) => Heap.put_back(taken.list, id, Arr(items.drop_last(1)))
			_ => crash "Heap.with_last_dropped: the interpreter pops only arrays"
		}
	}

	# The heap with an array's items replaced whole.
	with_items : List(Heap.Cell), U64, List(Heap.Val) -> List(Heap.Cell)
	with_items = |cells, id, vals| Heap.put_back(cells, id, Arr(vals))
}
