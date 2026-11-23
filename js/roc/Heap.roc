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
		Timing(Heap.Timing),
		OnClick,
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

	Closure : { fun : Box(Ast.FunctionDefinition), scope : U64 }

	Cell : [
		Object(List(Heap.Property)),
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
		Timing(timing) => match timing {
			SetTimeout => "setTimeout"
			SetInterval => "setInterval"
			ClearTimeout => "clearTimeout"
			ClearInterval => "clearInterval"
		}
		OnClick => "onClick"
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
