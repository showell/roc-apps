## This module holds the JavaScript heap as one Roc value: a list of cells,
## each an object, an array, a function or a builtin, named by its index.
## A JavaScript value that is shared by reference (an array, an object, a
## function) is a `Ref` to its cell, so two variables that hold one array hold
## one index, and a write through either is seen by both.
##
## **EVERY WRITE IS A `List.update` OF ONE CELL.** Roc writes a list in place
## only while nothing else refers to it, and `List.update` hands its function
## the cell with nothing else referring to it, so the props or items inside
## are written in place: a property write costs the property, never the
## object or the heap. Each writer takes the cell list itself and gives it
## back, and its callers pass it straight from the record they update
## (`{ ..machine, cells: Heap.with_property(machine.cells, ...) }`), so the
## list is never referred to twice.
##
## The dev build boxes an update's function when it captures a value that
## holds a reference count (a key, a `Value`, a list), one small allocation a
## write that the release build doesn't make; it is never a copy
## (js/controls/expected-dev.txt names it per control). The writers took the
## cell out and put it back by hand before, which the dev build didn't box,
## and read worse.
##
## **A FREED CELL STAYS IN ITS PLACE.** The bytecode VM's collector
## (`Collector`) turns each cell no root reaches into a `Freed` cell, linked
## to the next free one, and an allocation (`allocated`) takes the first
## free cell before it grows the list. Nothing moves, so a reference stays
## the index it was.
import Ast
import NumberText

Heap :: [].{

	## A JavaScript program's value: a number, a string, a boolean, `null`,
	## `undefined`, or a reference to a cell of the heap.
	Value : [
		Number(F64),
		Text(Str),
		Boolean(Bool),
		Null,
		Undefined,
		Reference(U64),
	]

	## An object's property: the property's key and the property's value.
	Property : { key : Str, value : Heap.Value }

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
		ArrayFrom,
		ArrayOf,
		IsInteger,
		Paint(Heap.Paint),
		Move(Heap.Move),
		Sense(Heap.Sense),
		Timing(Heap.Timing),
		OnClick,
		OnCollect,
		# `Error`, `TypeError` and their kin, which `new` calls.
		MakeError(Heap.ErrorName),
		MakeMap,
		MakeSet,
	]

	## The canvas builtins that draw a shape or set how shapes are drawn.
	Paint : [
		Background,
		Fill,
		NoFill,
		Stroke,
		NoStroke,
		Line,
		Rect,
		Circle,
		Ellipse,
		Polygon,
		Words,
	]

	## The turtle's builtins.
	Move : [Forward, Back, Turn, PenUp, PenDown, Goto]

	## The builtins that read the host's input.
	Sense : [MouseX, MouseY, KeyIsDown]

	## The timers, JavaScript's own, in both libraries.
	Timing : [SetTimeout, SetInterval, ClearTimeout, ClearInterval]

	## The errors JavaScript's own operations throw, by their names.
	ErrorName : [Error, TypeError, RangeError, ReferenceError, SyntaxError]

	error_name_text : Heap.ErrorName -> Str
	error_name_text = |name| match name {
		Error => "Error"
		TypeError => "TypeError"
		RangeError => "RangeError"
		ReferenceError => "ReferenceError"
		SyntaxError => "SyntaxError"
	}

	Closure : { fun : Box(Ast.FunctionDefinition), scope : U64 }

	Cell : [
		Object(List(Heap.Property)),
		# A class's instance: an object marked with the names of its class and
		# of each class that class extends, nearest first, which `instanceof`
		# reads. Its properties are its fields and its methods' closures
		# (`Parser`'s "classes"), so it is never printed or listed.
		Instance(List(Str), List(Heap.Property)),
		Array(List(Heap.Value)),
		Fun(Heap.Closure),
		# A builtin function, and the properties it carries (`String.fromCharCode`).
		Builtin(Heap.Native, List(Heap.Property)),
		# A builtin object such as `Math`, by its name.
		Namespace(Str, List(Heap.Property)),
		# What `setTimeout` and `setInterval` answer: the timer's number, which
		# `clearTimeout` and `clearInterval` take. Node's is an object it can
		# print; ours can't be printed or read, so no program shows it.
		TimerHandle(U64),
		# An error, thrown by JavaScript's own operations or made by `new
		# Error(message)`: its name and its message. Node prints an error with
		# its stack, so the subset never prints one.
		Failure(Heap.ErrorName, Str),
		# A Map and a Set, each its table in a list of one: the table is big,
		# and kept out of line every cell stays the size of an object's, while
		# `List.update` still writes it in place.
		MapOf(List(Heap.Table)),
		SetOf(List(Heap.Table)),
		# What `keys()`, `values()` and `entries()` answer: the array, Map or
		# Set it walks, what of each entry it gives, and the next entry's place.
		Iteration({ source : U64, view : Heap.View, next : U64 }),
		# The bytecode VM's box for a variable a closure may capture, which the
		# frame that declares it and every closure that captures it share:
		# unready until its declaration runs, then its value. No JavaScript
		# value refers to a box; only the VM's frames and environments do.
		UnreadyVariable,
		Variable(Heap.Value),
		# What one of the VM's closures carries: the number of its compiled
		# code, and the boxes of the variables it captures, in the order the
		# code reads them. The closure's `Fun` cell names it by its `scope`.
		Environment({ code : U64, boxes : List(U64) }),
		# A cell the collector freed, and the free cell after it, which the
		# next allocation after this cell's takes.
		Freed(Heap.Free),
	]

	## Where the free cells start, or go on from a free cell: a free cell's
	## place, or none left.
	Free : [FreeAt(U64), NoneFree]

	## A cell put in the heap: the cells after, the free cells left, and the
	## new cell's place.
	Allocated : { cells : List(Heap.Cell), free : Heap.Free, id : U64 }

	## The heap with `cell` in the first free cell's place, or at the end
	## when none is free.
	allocated : List(Heap.Cell), Heap.Free, Heap.Cell -> Heap.Allocated
	allocated = |cells, free, cell|
		match free {
			NoneFree => {
				id = cells.len()
				{ cells: cells.append(cell), free: NoneFree, id: id }
			}
			FreeAt(id) => {
				next = match Heap.cell_at(cells, id) {
					Freed(after) => after
					_ => crash "Heap.allocated: the free list names only freed cells"
				}
				{ cells: cells.set(id, cell) ?? crash "Heap.allocated: a free cell the heap has", free: next, id: id }
			}
		}

	## How many cells the heap holds in use: its length less the cells on
	## its free list. The list is linked through the freed cells, so this
	## walks it, a step a free cell: a host asks it at a sample, never an
	## instruction.
	in_use_count : List(Heap.Cell), Heap.Free -> U64
	in_use_count = |cells, free| {
		var $free_cells = 0
		var $at = free
		while $at != NoneFree {
			$at = match $at {
				FreeAt(id) => match Heap.cell_at(cells, id) {
					Freed(after) => after
					_ => crash "Heap.in_use_count: the free list names only freed cells"
				}
				NoneFree => NoneFree
			}
			$free_cells = $free_cells + 1
		}
		cells.len() - $free_cells
	}

	## A Map's or a Set's entries, in the order their keys were first set,
	## each standing or `Gone` once deleted; where each standing key's entry
	## is in `entries`, by the key's identity; how many stand; and the next
	## entry's ordinal. A Set's entry holds its value as its key and its value
	## both.
	##
	## **A WALK KEEPS ITS PLACE BY ORDINAL, NOT BY INDEX.** Each entry gets the
	## next ordinal when it is first set, so the ordinals rise along
	## `entries`, and a walk under way (an iterator, a `for ... of`, a
	## `forEach`) holds the ordinal after the entry it last met. So when the
	## gone entries outnumber the standing ones, a delete drops them all
	## (`compacted`), and every walk still meets the rest in order, and each
	## entry set after it began. A table holds at most twice its size in
	## entries, however many keys pass through it. `clear` keeps the next ordinal
	## too, so a walk under way meets what is set after it, as in JavaScript.
	Table : {
		entries : List(Heap.Entry),
		places : Dict(Str, U64),
		size : U64,
		next_ordinal : U64,
	}

	Entry : { ordinal : U64, held : Heap.Held }

	Held : [Standing({ key : Heap.Value, value : Heap.Value }), Gone]

	## What an iterator gives of each entry: its key (an array's index), its
	## value, or both as a pair.
	View : [Keys, Values, Entries]

	empty_table : Heap.Table
	empty_table = { entries: [], places: Dict.empty(), size: 0, next_ordinal: 0 }

	# A key's identity as a Map compares keys, SameValueZero: NaN is one key,
	# and so are 0 and -0; a reference is its cell.
	identity_of : Heap.Value -> Str
	identity_of = |key| match key {
		Number(number) => if number.is_nan() {
			"nNaN"
		} else if number == 0.0 {
			"n0"
		} else {
			"n${NumberText.text_for(number)}"
		}
		Text(text) => "s${text}"
		Boolean(truth) => if truth {
			"t"
		} else {
			"f"
		}
		Null => "l"
		Undefined => "u"
		Reference(id) => "r${id.to_str()}"
	}

	# The table of a Map's or a Set's cell.
	table_of : Heap.Cell -> Heap.Table
	table_of = |cell| match cell {
		MapOf(tables) => tables.first() ?? crash "Heap.table_of: a Map holds its table"
		SetOf(tables) => tables.first() ?? crash "Heap.table_of: a Set holds its table"
		_ => crash "Heap.table_of: the interpreter asks only a Map or a Set for its table"
	}

	# The entry standing for `key`, if one does.
	entry_value : Heap.Table, Heap.Value -> Try(Heap.Value, [Missing])
	entry_value = |table, key|
		match table.places.get(Heap.identity_of(key)) {
			Ok(place) => match table.entries.get(place) {
				Ok({ ordinal: _, held: Standing(entry) }) => Ok(entry.value)
				_ => crash "Heap.entry_value: a place names a standing entry"
			}
			Err(KeyNotFound) => Err(Missing)
		}

	# The table with `key`'s entry set to `value`: in its place, keeping the
	# key it was first set with, when it stands, else at the end, a key of -0
	# made 0, as JavaScript makes it.
	table_with : Heap.Table, Heap.Value, Heap.Value -> Heap.Table
	table_with = |{ entries, places, size, next_ordinal }, key, value| {
		identity = Heap.identity_of(key)
		match places.get(identity) {
			Ok(place) => {
				entries: entries.update(
					place,
					|entry| Heap.entry_with_value(entry, value),
				) ?? crash "Heap.table_with: a place names an entry",
				places: places,
				size: size,
				next_ordinal: next_ordinal,
			}
			Err(KeyNotFound) => {
				kept = match key {
					Number(number) if number == 0.0 => Number(0.0)
					_ => key
				}
				{
					entries: entries.append({ ordinal: next_ordinal, held: Standing({ key: kept, value: value }) }),
					places: places.insert(identity, entries.len()),
					size: size + 1,
					next_ordinal: next_ordinal + 1,
				}
			}
		}
	}

	entry_with_value : Heap.Entry, Heap.Value -> Heap.Entry
	entry_with_value = |{ ordinal, held }, value| match held {
		Standing({ key, value: _ }) => { ordinal: ordinal, held: Standing({ key: key, value: value }) }
		Gone => crash "Heap.entry_with_value: a place names a standing entry"
	}

	# The table with `key`'s entry gone, if it stood, and every gone entry
	# dropped once they outnumber the standing ones.
	table_without : Heap.Table, Heap.Value -> Heap.Table
	table_without = |{ entries, places, size, next_ordinal }, key| {
		identity = Heap.identity_of(key)
		match places.get(identity) {
			Ok(place) => {
				marked = entries.update(place, |{ ordinal, held: _ }| { ordinal: ordinal, held: Gone }) ?? crash "Heap.table_without: a place names an entry"
				left = size - 1
				remaining = places.remove(identity)
				if marked.len() - left > left {
					Heap.compacted({ entries: marked, places: remaining, size: left, next_ordinal: next_ordinal })
				} else {
					{ entries: marked, places: remaining, size: left, next_ordinal: next_ordinal }
				}
			}
			Err(KeyNotFound) => { entries: entries, places: places, size: size, next_ordinal: next_ordinal }
		}
	}

	# The table with its standing entries alone, in their order, each keeping
	# its ordinal, and each key's place moved to where its entry went.
	compacted : Heap.Table -> Heap.Table
	compacted = |{ entries, places, size, next_ordinal }| {
		var $kept = []
		var $moved = []
		for entry in entries {
			$moved = $moved.append($kept.len())
			match entry.held {
				Standing(_) => {
					$kept = $kept.append(entry)
				}
				Gone => {}
			}
		}
		moved = $moved
		{
			entries: $kept,
			places: places.map(|_, place| moved.get(place) ?? crash "Heap.compacted: a place names an entry"),
			size: size,
			next_ordinal: next_ordinal,
		}
	}

	# The first entry a walk meets at `ordinal` or after, with its index in
	# `entries`, or none. An entry's ordinal is never below its index, so
	# the search looks no further than `ordinal`'s index, and where nothing
	# was dropped the entry is there.
	entry_from : Heap.Table, U64 -> [Met(Heap.Entry), NoneLeft]
	entry_from = |table, ordinal| {
		entries = table.entries
		match entries.get(ordinal) {
			Ok(entry) if entry.ordinal == ordinal => Met(entry)
			_ => {
				var $low = 0
				var $high = U64.min(entries.len(), ordinal + 1)
				while $low < $high {
					middle = ($low + $high) // 2
					below = match entries.get(middle) {
						Ok(entry) => entry.ordinal < ordinal
						Err(OutOfBounds) => crash "Heap.entry_from: the search stays inside the entries"
					}
					if below {
						$low = middle + 1
					} else {
						$high = middle
					}
				}
				match entries.get($low) {
					Ok(entry) => Met(entry)
					Err(OutOfBounds) => NoneLeft
				}
			}
		}
	}

	# The heap with an entry of a Map's or a Set's table set, deleted, or
	# all of them gone, each written where the cell holds it.
	with_entry : List(Heap.Cell), U64, Heap.Value, Heap.Value -> List(Heap.Cell)
	with_entry = |cells, id, key, value|
		cells.update(
			id,
			|cell| Heap.cell_with_table(cell, |table| Heap.table_with(table, key, value)),
		) ?? crash "Heap.with_entry: a Ref names a cell the heap has"

	without_entry : List(Heap.Cell), U64, Heap.Value -> List(Heap.Cell)
	without_entry = |cells, id, key|
		cells.update(
			id,
			|cell| Heap.cell_with_table(cell, |table| Heap.table_without(table, key)),
		) ?? crash "Heap.without_entry: a Ref names a cell the heap has"

	cleared : List(Heap.Cell), U64 -> List(Heap.Cell)
	cleared = |cells, id|
		cells.update(
			id,
			|cell| Heap.cell_with_table(cell, |table| { ..Heap.empty_table, next_ordinal: table.next_ordinal }),
		) ?? crash "Heap.cleared: a Ref names a cell the heap has"

	# **THE WRITE IS A FUNCTION OF ITS OWN**, handed the cell taken out, as
	# `items_with` is: the table is written where its list of one holds it.
	cell_with_table : Heap.Cell, (Heap.Table -> Heap.Table) -> Heap.Cell
	cell_with_table = |cell, write| match cell {
		MapOf(tables) => MapOf(Heap.tables_with(tables, write))
		SetOf(tables) => SetOf(Heap.tables_with(tables, write))
		_ => crash "Heap.cell_with_table: the interpreter writes entries only to a Map or a Set"
	}

	tables_with : List(Heap.Table), (Heap.Table -> Heap.Table) -> List(Heap.Table)
	tables_with = |tables, write| tables.update(0, write) ?? crash "Heap.tables_with: a Map or a Set holds its table"

	# The heap with an iterator moved on to `next`.
	with_iterator_at : List(Heap.Cell), U64, U64 -> List(Heap.Cell)
	with_iterator_at = |cells, id, next|
		cells.update(
			id,
			|cell| match cell {
				Iteration(walk) => Iteration({ ..walk, next: next })
				_ => crash "Heap.with_iterator_at: the interpreter moves only an iterator on"
			},
		) ?? crash "Heap.with_iterator_at: a Ref names a cell the heap has"

	native_name : Heap.Native -> Str
	native_name = |native| match native {
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
		ArrayFrom => "from"
		ArrayOf => "of"
		IsInteger => "isInteger"
		Paint(paint) => match paint {
			Background => "background"
			Fill => "fill"
			NoFill => "noFill"
			Stroke => "stroke"
			NoStroke => "noStroke"
			Line => "line"
			Rect => "rect"
			Circle => "circle"
			Ellipse => "ellipse"
			Polygon => "polygon"
			Words => "text"
		}
		Move(move) => match move {
			Forward => "forward"
			Back => "back"
			Turn => "turn"
			PenUp => "penUp"
			PenDown => "penDown"
			Goto => "goto"
		}
		Sense(sense) => match sense {
			MouseX => "mouseX"
			MouseY => "mouseY"
			KeyIsDown => "keyIsDown"
		}
		Timing(timing) => match timing {
			SetTimeout => "setTimeout"
			SetInterval => "setInterval"
			ClearTimeout => "clearTimeout"
			ClearInterval => "clearInterval"
		}
		OnClick => "onClick"
		OnCollect => "onCollect"
		MakeError(name) => Heap.error_name_text(name)
		MakeMap => "Map"
		MakeSet => "Set"
	}

	cell_at : List(Heap.Cell), U64 -> Heap.Cell
	cell_at = |cells, id| cells.get(id) ?? crash "Heap.cell_at: a Ref names a cell the heap has"

	# The value of a property an object has, or Undefined.
	property_value : List(Heap.Property), Str -> Heap.Value
	property_value = |properties, key|
		match properties.find_first(|found| found.key == key) {
			Ok(found) => found.value
			Err(NotFound) => Undefined
		}

	has_property : List(Heap.Property), Str -> Bool
	has_property = |properties, key| properties.any(|found| found.key == key)

	# Props with `key` set: in its place when it is there, else at the end.
	properties_with : List(Heap.Property), Str, Heap.Value -> List(Heap.Property)
	properties_with = |properties, key, value|
		match properties.find_first_index(|found| found.key == key) {
			Ok(position) => properties.set(
				position,
				{ key: key, value: value },
			) ?? crash "Heap.properties_with: the index was just found"
			Err(NotFound) => properties.append({ key: key, value: value })
		}

	with_property : List(Heap.Cell), U64, Str, Heap.Value -> List(Heap.Cell)
	with_property = |cells, id, key, value|
		cells.update(
			id,
			|cell| match cell {
				Object(properties) => Object(Heap.properties_with(properties, key, value))
				Instance(classes, properties) => {
					written = Heap.properties_with(properties, key, value)
					Instance(classes, written)
				}
				_ => crash "Heap.with_property: the interpreter writes properties only to objects"
			},
		) ?? crash "Heap.with_property: a Ref names a cell the heap has"

	# The heap with an array's item `i` set, or appended when `i` is its length.
	with_item : List(Heap.Cell), U64, U64, Heap.Value -> List(Heap.Cell)
	with_item = |cells, id, position, value|
		cells.update(
			id,
			|cell| match cell {
				Array(items) => Array(Heap.items_with(items, position, value))
				_ => crash "Heap.with_item: the interpreter writes items only to arrays"
			},
		) ?? crash "Heap.with_item: a Ref names a cell the heap has"

	# **THE WRITE IS A FUNCTION OF ITS OWN.** Made inline in `with_item`'s match
	# arm, beside a binding of its own, it copied the items: every store into
	# an array of N items cost N.
	items_with : List(Heap.Value), U64, Heap.Value -> List(Heap.Value)
	items_with = |items, position, value|
		if position == items.len() {
			items.append(value)
		} else {
			items.set(
				position,
				value,
			) ?? crash "Heap.items_with: the interpreter writes inside an array or at its end"
		}

	with_items_pushed : List(Heap.Cell), U64, List(Heap.Value) -> List(Heap.Cell)
	with_items_pushed = |cells, id, values|
		cells.update(
			id,
			|cell| match cell {
				Array(items) => Array(List.concat(items, values))
				_ => crash "Heap.with_items_pushed: the interpreter pushes only onto arrays"
			},
		) ?? crash "Heap.with_items_pushed: a Ref names a cell the heap has"

	with_last_dropped : List(Heap.Cell), U64 -> List(Heap.Cell)
	with_last_dropped = |cells, id|
		cells.update(
			id,
			|cell| match cell {
				Array(items) => Array(items.drop_last(1))
				_ => crash "Heap.with_last_dropped: the interpreter pops only arrays"
			},
		) ?? crash "Heap.with_last_dropped: a Ref names a cell the heap has"

	# The heap with an array's items replaced whole.
	with_items : List(Heap.Cell), U64, List(Heap.Value) -> List(Heap.Cell)
	with_items = |cells, id, values|
		cells.set(id, Array(values)) ?? crash "Heap.with_items: a Ref names a cell the heap has"
}
