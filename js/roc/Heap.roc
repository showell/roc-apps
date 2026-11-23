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
## it straight from the record they update (`{ ..machine, cells:
## Heap.with_property(machine.cells, ...) }`), so the list is never referred
## to twice.
##
## Cells are never freed: a run's heap holds every object it made
## (js/README.md, "Cells are never freed", says why).
import Ast

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
		IsInteger,
		Paint(Heap.Paint),
		Move(Heap.Move),
		Sense(Heap.Sense),
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

	Closure : { fun : Box(Ast.FunctionDefinition), scope : U64 }

	Cell : [
		Object(List(Heap.Property)),
		Array(List(Heap.Value)),
		Fun(Heap.Closure),
		# A builtin function, and the properties it carries (`String.fromCharCode`).
		Builtin(Heap.Native, List(Heap.Property)),
		# A builtin object such as `Math`, by its name.
		Namespace(Str, List(Heap.Property)),
		# What a cell's place holds while the cell is out being written.
		Taken,
	]

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

	with_property : List(Heap.Cell), U64, Str, Heap.Value -> List(Heap.Cell)
	with_property = |cells, id, key, value| {
		taken = Heap.taken_out(cells, id)
		match taken.prev {
			Object(properties) => Heap.put_back(
				taken.list,
				id,
				Object(Heap.properties_with(properties, key, value)),
			)
			_ => crash "Heap.with_property: the interpreter writes properties only to objects"
		}
	}

	# The heap with an array's item `i` set, or appended when `i` is its length.
	with_item : List(Heap.Cell), U64, U64, Heap.Value -> List(Heap.Cell)
	with_item = |cells, id, position, value| {
		taken = Heap.taken_out(cells, id)
		match taken.prev {
			Array(items) => Heap.put_back(
				taken.list,
				id,
				Array(Heap.items_with(items, position, value)),
			)
			_ => crash "Heap.with_item: the interpreter writes items only to arrays"
		}
	}

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
	with_items_pushed = |cells, id, values| {
		taken = Heap.taken_out(cells, id)
		match taken.prev {
			Array(items) => Heap.put_back(
				taken.list,
				id,
				Array(List.concat(items, values)),
			)
			_ => crash "Heap.with_items_pushed: the interpreter pushes only onto arrays"
		}
	}

	with_last_dropped : List(Heap.Cell), U64 -> List(Heap.Cell)
	with_last_dropped = |cells, id| {
		taken = Heap.taken_out(cells, id)
		match taken.prev {
			Array(items) => Heap.put_back(taken.list, id, Array(items.drop_last(1)))
			_ => crash "Heap.with_last_dropped: the interpreter pops only arrays"
		}
	}

	# The heap with an array's items replaced whole.
	with_items : List(Heap.Cell), U64, List(Heap.Value) -> List(Heap.Cell)
	with_items = |cells, id, values| Heap.put_back(cells, id, Array(values))
}
