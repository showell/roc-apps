## This module holds the rules JavaScript's values follow, which the
## bytecode VM (`Vm`) calls where its own fast paths stop: what a property
## read gives and a property write does, what an
## operator makes of two values, the methods of strings, arrays, Maps and
## Sets, the builtins that make no effect and call nothing back, and the
## errors those throw and the faults they stop at, each message in its
## words. None of them runs a function of the program or reaches the host,
## so a message has one home.
##
## **THE VM LENDS A RULE ITS CELLS.** A rule reads and writes the heap
## (`cells`) and the run's `status` (a fault, or a value thrown), and
## nothing else, so it takes a machine of those two (`ValueRules.Machine`):
## the VM takes its cells out of its own machine, hands them over with
## its status, and puts back what the rule gives, so the cells have one
## owner while the rule writes them. A rule generic over the rest of the
## VM's machine, an open record, would be shorter to call, but the dev
## build copies the cells a rule writes through one.
##
## **NOTHING HOLDS THE MACHINE BUT THE RULE.** A rule passes the cells straight from the record it
## updates, takes every `Got` apart where it is answered, and asks
## `ValueRules.kind_of` what a cell is rather than matching it out of the
## heap, so the heap stays unique and each write is made in place
## (js/README.md, "Why the heap is one value").
##
## **THE RULES TAKE SEVERAL ARGUMENTS, A NAMED EXCEPTION.** As the VM's
## handlers do, a rule takes the machine first, then the rest, where the
## style guide would take one record: a record holding the machine is a
## second reference to the heap. `array_method` and `collection_method`,
## the methods by name, follow it too.
import Ast
import Heap
import Inspect
import NumberText

ValueRules :: [].{

	## The part of the VM's machine a rule reads and writes: the heap, its
	## free cells, which an allocation takes first, and whether the run goes
	## on.
	Machine : { cells : List(Heap.Cell), free : Heap.Free, status : ValueRules.Status }

	## A rule's value, and the machine after it.
	Got : { machine : ValueRules.Machine, value : Heap.Value }

	Evaluations : { machine : ValueRules.Machine, values : List(Heap.Value) }

	## Whether the machine runs on: a fault stops the run for good; a value
	## thrown, and not yet caught, unwinds it to the nearest `try`, which runs
	## it on. The value thrown and where it was thrown wait in a box, so a
	## status is no bigger than a fault's message: the machine holding it is
	## handed back from every evaluation.
	Status : [Running, Faulted(Str), Thrown(Box(ValueRules.Throw))]

	Throw : { value : Heap.Value, site : Ast.Where }

	# The deepest JavaScript call the interpreter makes before it reports a
	# stack overflow, as node does, rather than overflow Roc's own stack.
	max_depth : U64
	max_depth = 400

	# What a throw nothing caught says: `Uncaught `, the first line node
	# prints for the value (an error's name and message, or the value as
	# console.log shows it), and the line of the throw.
	uncaught_ending : List(Heap.Cell), Heap.Value, Ast.Where -> [Uncaught(Str), Faulted(Str)]
	uncaught_ending = |cells, value, site| {
		shown = match value {
			Reference(id) => match Heap.cell_at(cells, id) {
				Failure(_, _) => ValueRules.text_of(cells, value)
				_ => Inspect.line_of(cells, [value])
			}
			_ => Inspect.line_of(cells, [value])
		}
		match shown {
			Ok(text) => {
				first = text.split_on("\n").first() ?? crash "ValueRules.uncaught_ending: a split has a first piece"
				Uncaught("Uncaught ${first}${ValueRules.line_note(site)}")
			}
			Err(Unsupported(why)) => Faulted("${why}, thrown and not caught${ValueRules.line_note(site)}")
		}
	}

	# ---- the machine's status --------------------------------------------------

	alloc : ValueRules.Machine, Heap.Cell -> ValueRules.Got
	alloc = |machine, cell| {
		{ cells, free, status } = machine
		made = Heap.allocated(cells, free, cell)
		{ machine: { cells: made.cells, free: made.free, status: status }, value: Reference(made.id) }
	}

	is_running : ValueRules.Machine -> Bool
	is_running = |machine|
		match machine.status {
			Running => True
			_ => False
		}

	# The machine stopped with `why`, unless it had already stopped.
	with_fault : ValueRules.Machine, Str -> ValueRules.Machine
	with_fault = |machine, why|
		match machine.status {
			Running => { ..machine, status: Faulted(why) }
			_ => machine
		}

	# The machine unwinding with `value` thrown at `site`, unless it had
	# already stopped.
	with_thrown : ValueRules.Machine, Heap.Value, Ast.Where -> ValueRules.Machine
	with_thrown = |machine, value, site|
		match machine.status {
			Running => { ..machine, status: Thrown(Box.box({ value, site })) }
			_ => machine
		}

	fault_got : ValueRules.Machine, Str -> ValueRules.Got
	fault_got = |machine, why| { machine: ValueRules.with_fault(machine, why), value: Undefined }

	line_note : Ast.Where -> Str
	line_note = |site| " (line ${site.line.to_str()})"

	# The machine unwinding with one of JavaScript's own errors, `name`,
	# saying `message` as node words it, thrown at `site`: a program may
	# catch it as it catches its own.
	with_error : ValueRules.Machine, Heap.ErrorName, Str, Ast.Where -> ValueRules.Machine
	with_error = |machine, name, message, site|
		if !ValueRules.is_running(machine) {
			machine
		} else {
			{ machine: made, value: error } = ValueRules.alloc(machine, Failure(name, message))
			ValueRules.with_thrown(made, error, site)
		}

	error_got : ValueRules.Machine, Heap.ErrorName, Str, Ast.Where -> ValueRules.Got
	error_got = |machine, name, message, site| {
		machine: ValueRules.with_error(machine, name, message, site),
		value: Undefined,
	}

	# An expression as V8 writes it in a message (`o.f is not a function`):
	# names, properties, indices, calls and literals, and `(intermediate
	# value)` for the rest.
	source_text : Ast.Expression -> Str
	source_text = |expression| match expression {
		Name(name, _, _) => name
		Member(object, key, _) => "${ValueRules.source_text(object)}.${key}"
		Index(object, key, _) => "${ValueRules.source_text(object)}[${ValueRules.source_text(key)}]"
		Call(callee, _, _) => "${ValueRules.source_text(callee)}(...)"
		OptionalMember(object, key, _) => "${ValueRules.source_text(object)}?.${key}"
		OptionalIndex(object, key, _) => "${ValueRules.source_text(object)}?.[${ValueRules.source_text(key)}]"
		OptionalCall(callee, _, _) => "${ValueRules.source_text(callee)}?.(...)"
		Chain(chain) => ValueRules.source_text(chain)
		Number(number) => NumberText.text_for(number)
		Text(text) => "\"${text}\""
		Boolean(truth) => if truth {
			"true"
		} else {
			"false"
		}
		Null => "null"
		Undefined => "undefined"
		ObjectLit([]) => "{}"
		ObjectLit(_) => "{(intermediate value)}"
		ArrayLit(items) => {
			shown = items.map(
				|item| match item {
					Single(single) => ValueRules.source_text(single)
					Spread(_, _) => "(intermediate value)"
				},
			)
			"[${Str.join_with(shown, ",")}]"
		}
		_ => "(intermediate value)"
	}

	# ---- values ----------------------------------------------------------------

	# A string's characters, each its UTF-8 bytes, as `for ... of` takes them.
	characters : Str -> List(Str)
	characters = |text| {
		bytes = text.to_utf8()
		var $out = []
		var $i = 0
		while $i < bytes.len() {
			lead = bytes.get($i) ?? crash "ValueRules.characters: inside the text"
			width = if lead >= 0xF0 {
				4
			} else if lead >= 0xE0 {
				3
			} else if lead >= 0xC0 {
				2
			} else {
				1
			}
			$out = $out.append(
				Str.from_utf8(
					bytes.sublist({ start: $i, len: width }),
				) ?? crash "ValueRules.characters: a whole character",
			)
			$i = $i + width
		}
		$out
	}

	is_truthy : Heap.Value -> Bool
	is_truthy = |subject| match subject {
		Number(number) => !(number == 0.0 or number.is_nan())
		Text(text) => !text.is_empty()
		Boolean(truth) => truth
		Null => False
		Undefined => False
		Reference(_) => True
	}

	type_of : List(Heap.Cell), Heap.Value -> Str
	type_of = |cells, subject| match subject {
		Number(_) => "number"
		Text(_) => "string"
		Boolean(_) => "boolean"
		Null => "object"
		Undefined => "undefined"
		Reference(id) => match Heap.cell_at(cells, id) {
			Fun(_) => "function"
			Builtin(_, _) => "function"
			_ => "object"
		}
	}

	is_strictly_equal : Heap.Value, Heap.Value -> Bool
	is_strictly_equal = |left, right| match (left, right) {
		(Number(x), Number(y)) => x == y
		(Text(x), Text(y)) => x == y
		(Boolean(x), Boolean(y)) => x == y
		(Null, Null) => True
		(Undefined, Undefined) => True
		(Reference(x), Reference(y)) => x == y
		_ => False
	}

	# SameValueZero, as `includes` compares: NaN finds NaN.
	is_same_value_zero : Heap.Value, Heap.Value -> Bool
	is_same_value_zero = |left, right| match (left, right) {
		(Number(x), Number(y)) => x == y or (x.is_nan() and y.is_nan())
		_ => ValueRules.is_strictly_equal(left, right)
	}

	# What `String(v)` gives, for the values whose text the subset has.
	text_of : List(Heap.Cell), Heap.Value -> Try(Str, [Unsupported(Str)])
	text_of = |cells, subject| ValueRules.text_of_seen(cells, subject, [])

	text_of_seen : List(Heap.Cell), Heap.Value, List(U64) -> Try(Str, [Unsupported(Str)])
	text_of_seen = |cells, subject, seen| match subject {
		Number(number) => Ok(NumberText.text_for(number))
		Text(text) => Ok(text)
		Boolean(truth) => Ok(
			if truth {
				"true"
			} else {
				"false"
			},
		)
		Null => Ok("null")
		Undefined => Ok("undefined")
		Reference(id) => match Heap.cell_at(cells, id) {
			Array(items) => {
				if seen.contains(id) {
					Err(Unsupported("unsupported: turning a circular array into text"))
				} else {
					var $parts = []
					for item in items {
						part = match item {
							Null => ""
							Undefined => ""
							_ => ValueRules.text_of_seen(cells, item, seen.append(id))?
						}
						$parts = $parts.append(part)
					}
					Ok(Str.join_with($parts, ","))
				}
			}
			Object(_) => Ok("[object Object]")
			MapOf(_) => Ok("[object Map]")
			SetOf(_) => Ok("[object Set]")
			Failure(name, "") => Ok(Heap.error_name_text(name))
			Failure(name, message) => Ok("${Heap.error_name_text(name)}: ${message}")
			_ => Err(Unsupported("unsupported: turning a function or a builtin object into text"))
		}
	}

	# The property key a value names, as `o[k]` reads it.
	key_of : Heap.Value -> Try(Str, [Unsupported(Str)])
	key_of = |subject| match subject {
		Number(number) => Ok(NumberText.text_for(number))
		Text(text) => Ok(text)
		Boolean(truth) => Ok(
			if truth {
				"true"
			} else {
				"false"
			},
		)
		Null => Ok("null")
		Undefined => Ok("undefined")
		Reference(_) => Err(Unsupported("unsupported: an object or array as a property key"))
	}

	# The array index a value names, if it names one.
	index_of : Heap.Value -> Try(U64, [NotIndex])
	index_of = |subject| match subject {
		Number(number) => {
			if number >= 0.0 and number < 4294967295.0 and number.div_trunc_by(1.0) == number {
				number.to_u64_try().map_err(|_| NotIndex)
			} else {
				Err(NotIndex)
			}
		}
		Text(text) => Inspect.index_of_key(text)
		_ => Err(NotIndex)
	}

	ordering_of_text : Str, Str -> [Before, Same, After]
	ordering_of_text = |left, right| {
		x = left.to_utf8()
		y = right.to_utf8()
		var $i = 0
		var $answer = Same
		var $deciding = True
		while $deciding {
			match (x.get($i), y.get($i)) {
				(Ok(left_byte), Ok(right_byte)) => {
					if left_byte < right_byte {
						$answer = Before
						$deciding = False
					} else if left_byte > right_byte {
						$answer = After
						$deciding = False
					} else {
						$i = $i + 1
					}
				}
				(Err(_), Ok(_)) => {
					$answer = Before
					$deciding = False
				}
				(Ok(_), Err(_)) => {
					$answer = After
					$deciding = False
				}
				(Err(_), Err(_)) => {
					$deciding = False
				}
			}
		}
		$answer
	}

	shown_value : List(Heap.Cell), Heap.Value -> Str
	shown_value = |cells, subject| match subject {
		Text(text) => Inspect.escaped_text(text)
		_ => Inspect.inspect(cells, subject) ?? ValueRules.type_of(cells, subject)
	}

	is_nullish : Heap.Value -> Bool
	is_nullish = |subject| subject == Null or subject == Undefined

	# The own properties `{...value}` spreads: an object's, in key order, an
	# array's items by their indices, an ASCII string's characters; a value
	# with none (`null`, a number, a function) spreads nothing.
	spread_properties : List(Heap.Cell), Heap.Value -> Try(List(Heap.Property), [Unsupported(Str)])
	spread_properties = |cells, subject|
		match subject {
			Reference(id) => match Heap.cell_at(cells, id) {
				Object(properties) => Ok(Inspect.properties_in_key_order(properties))
				Array(items) => Ok(ValueRules.indexed_properties(items))
				_ => Ok([])
			}
			Text(text) => {
				if ValueRules.is_ascii(text) {
					Ok(ValueRules.indexed_properties(ValueRules.characters(text).map(|character| Text(character))))
				} else {
					Err(Unsupported("unsupported: spreading a string with non-ASCII text into an object"))
				}
			}
			_ => Ok([])
		}

	indexed_properties : List(Heap.Value) -> List(Heap.Property)
	indexed_properties = |items| items.map_with_index(|item, position| { key: position.to_str(), value: item })

	# ---- iteration over arrays, strings, Maps and Sets -------------------------

	# The values a spread, a pattern or a collection's constructor takes from
	# what it is given, as `for ... of` takes them: an array's items, a
	# string's characters, a Map's entries as pairs, a Set's values, or what
	# an iterator has left, which then has nothing more.
	#
	# The machine comes back whether or not the value is iterable, so no
	# caller keeps its own while this one writes.
	iterated : ValueRules.Machine, Heap.Value -> ValueRules.Iterated
	iterated = |machine, subject|
		match subject {
			Reference(id) => match ValueRules.kind_of(machine.cells, id) {
				ArrayKind(_) => {
					items = ValueRules.items_of(machine.cells, id)
					{ machine: machine, values: Ok(items) }
				}
				MapKind => ValueRules.iterated_ok(ValueRules.stepped(machine, { source: id, view: Entries, next: 0 }))
				SetKind => ValueRules.iterated_ok(ValueRules.stepped(machine, { source: id, view: Values, next: 0 }))
				IteratorKind => {
					walk = ValueRules.iteration_of(machine.cells, id)
					{ machine: after, values } = ValueRules.stepped(machine, walk)
					end = ValueRules.walk_length(after.cells, walk.source)
					{
						machine: { ..after, cells: Heap.with_iterator_at(after.cells, id, end) },
						values: Ok(values),
					}
				}
				_ => { machine: machine, values: Err(NotIterable) }
			}
			Text(text) => {
				machine: machine,
				values: Ok(ValueRules.characters(text).map(|character| Text(character))),
			}
			_ => { machine: machine, values: Err(NotIterable) }
		}

	Iterated : { machine : ValueRules.Machine, values : Try(List(Heap.Value), [NotIterable]) }

	iterated_ok : ValueRules.Evaluations -> ValueRules.Iterated
	iterated_ok = |{ machine, values }| { machine: machine, values: Ok(values) }

	## Where a walk of entries is: the array, Map or Set walked, what it gives
	## of each entry, and the next entry's place.
	EntryWalk : { source : U64, view : Heap.View, next : U64 }

	## One entry of a walk: a value given, a pair given (an entry's key and
	## value, made into an array where it is used), a deleted entry passed
	## over, or the end.
	Step : [Yield(Heap.Value), YieldPair(Heap.Value, Heap.Value), Skip, Ended]

	step_at : List(Heap.Cell), U64, Heap.View, U64 -> ValueRules.Step
	step_at = |cells, source, view, position| {
		cell = Heap.cell_at(cells, source)
		match cell {
			Array(items) => match items.get(position) {
				Ok(item) => match view {
					Keys => Yield(Number(position.to_f64()))
					Values => Yield(item)
					Entries => YieldPair(Number(position.to_f64()), item)
				}
				Err(OutOfBounds) => Ended
			}
			MapOf(_) => match Heap.table_of(cell).entries.get(position) {
				Ok(Standing({ key, value })) => match view {
					Keys => Yield(key)
					Values => Yield(value)
					Entries => YieldPair(key, value)
				}
				Ok(Gone) => Skip
				Err(OutOfBounds) => Ended
			}
			# A Set's value is its key, as it was first added.
			SetOf(_) => match Heap.table_of(cell).entries.get(position) {
				Ok(Standing({ key, value: _ })) => match view {
					Entries => YieldPair(key, key)
					_ => Yield(key)
				}
				Ok(Gone) => Skip
				Err(OutOfBounds) => Ended
			}
			_ => crash "ValueRules.step_at: a walk's source is an array, a Map or a Set"
		}
	}

	# How many places a walk's source has: an array's items, a table's
	# entries, deleted ones included.
	walk_length : List(Heap.Cell), U64 -> U64
	walk_length = |cells, source| {
		cell = Heap.cell_at(cells, source)
		match cell {
			Array(items) => items.len()
			_ => Heap.table_of(cell).entries.len()
		}
	}

	iteration_of : List(Heap.Cell), U64 -> ValueRules.EntryWalk
	iteration_of = |cells, id|
		match Heap.cell_at(cells, id) {
			Iteration(walk) => walk
			_ => crash "ValueRules.iteration_of: the interpreter asks only an iterator where it walks"
		}

	# The values a walk gives from its place to its source's end, each pair
	# made into an array.
	stepped : ValueRules.Machine, ValueRules.EntryWalk -> ValueRules.Evaluations
	stepped = |machine, { source, view, next }| {
		var $s = machine
		var $values = []
		var $i = next
		var $going = True
		while $going {
			match ValueRules.step_at($s.cells, source, view, $i) {
				Yield(value) => {
					$values = $values.append(value)
				}
				YieldPair(key, value) => {
					{ machine: made, value: pair } = ValueRules.alloc($s, Array([key, value]))
					$s = made
					$values = $values.append(pair)
				}
				Skip => {}
				Ended => {
					$going = False
				}
			}
			$i = $i + 1
		}
		{ machine: $s, values: $values }
	}

	## A Map or a Set, for what their methods share.
	Collection : [IsMap, IsSet]

	collection_name : ValueRules.Collection -> Str
	collection_name = |collection| match collection {
		IsMap => "Map"
		IsSet => "Set"
	}

	# `new Map(entries)` or `new Set(values)`: the collection, filled from
	# what is given in its order, or empty for nothing, `null` or `undefined`.
	collection_made : ValueRules.Machine, ValueRules.Collection, List(Heap.Value), Ast.Where -> ValueRules.Got
	collection_made = |machine, collection, arguments, site| {
		{ machine: made, value: collection_value } = ValueRules.alloc(
			machine,
			match collection {
				IsMap => MapOf([Heap.empty_table])
				IsSet => SetOf([Heap.empty_table])
			},
		)
		id = match collection_value {
			Reference(placed) => placed
			_ => crash "ValueRules.collection_made: an allocation answers a reference"
		}
		given = arguments.first() ?? Undefined
		if ValueRules.is_nullish(given) {
			{ machine: made, value: collection_value }
		} else {
			{ machine: walked, values: given_values } = ValueRules.iterated(made, given)
			match given_values {
				Err(NotIterable) => {
					machine: ValueRules.with_not_iterable(walked, given, Argument, site),
					value: Undefined,
				}
				Ok(values) => {
					var $s = walked
					for each in values {
						if ValueRules.is_running($s) {
							$s = match collection {
								IsSet => { ..$s, cells: Heap.with_entry($s.cells, id, each, each) }
								IsMap => match ValueRules.entry_of($s.cells, each) {
									Ok({ key, value }) => { ..$s, cells: Heap.with_entry($s.cells, id, key, value) }
									Err(NotEntry) => {
										shown = ValueRules.text_of($s.cells, each) ?? ValueRules.type_of($s.cells, each)
										ValueRules.with_error(
											$s,
											TypeError,
											"Iterator value ${shown} is not an entry object",
											site,
										)
									}
								}
							}
						}
					}
					{ machine: $s, value: Reference(id) }
				}
			}
		}
	}

	# A Map's entry as `new Map` reads one: an array's first two items, or an
	# object's properties "0" and "1".
	entry_of : List(Heap.Cell), Heap.Value -> Try({ key : Heap.Value, value : Heap.Value }, [NotEntry])
	entry_of = |cells, subject|
		match subject {
			Reference(id) => match Heap.cell_at(cells, id) {
				Array(items) => Ok({ key: items.get(0) ?? Undefined, value: items.get(1) ?? Undefined })
				Object(properties) => Ok({
					key: Heap.property_value(properties, "0"),
					value: Heap.property_value(properties, "1"),
				})
				_ => Ok({ key: Undefined, value: Undefined })
			}
			_ => Err(NotEntry)
		}

	# A Map's or a Set's method: a Map's `get` and `set`, a Set's `add`, and
	# what both have, `has`, `delete`, `clear`, `forEach`, `keys`, `values`
	# and `entries`; the VM runs `forEach` itself.
	collection_method : ValueRules.Machine, { id : U64, collection : ValueRules.Collection }, Str, List(Heap.Value), Ast.Where -> ValueRules.Got
	collection_method = |machine, { id, collection }, name, arguments, site| {
		key = arguments.first() ?? Undefined
		match (collection, name) {
			(IsMap, "get") => {
				table = Heap.table_of(Heap.cell_at(machine.cells, id))
				found = match Heap.entry_value(table, key) {
					Ok(value) => value
					Err(Missing) => Undefined
				}
				{ machine: machine, value: found }
			}
			(IsMap, "set") => {
				value = arguments.get(1) ?? Undefined
				{
					machine: { ..machine, cells: Heap.with_entry(machine.cells, id, key, value) },
					value: Reference(id),
				}
			}
			(IsSet, "add") => {
				machine: { ..machine, cells: Heap.with_entry(machine.cells, id, key, key) },
				value: Reference(id),
			}
			(_, "has") => {
				table = Heap.table_of(Heap.cell_at(machine.cells, id))
				{ machine: machine, value: Boolean(Heap.entry_value(table, key).is_ok()) }
			}
			(_, "delete") => {
				table = Heap.table_of(Heap.cell_at(machine.cells, id))
				stood = Heap.entry_value(table, key).is_ok()
				if stood {
					{
						machine: { ..machine, cells: Heap.without_entry(machine.cells, id, key) },
						value: Boolean(True),
					}
				} else {
					{ machine: machine, value: Boolean(False) }
				}
			}
			(_, "clear") => { machine: { ..machine, cells: Heap.cleared(machine.cells, id) }, value: Undefined }
			(_, "forEach") => crash "ValueRules.collection_method: the VM runs `forEach` itself"
			(_, "keys") => ValueRules.alloc(machine, Iteration({ source: id, view: Keys, next: 0 }))
			(_, "values") => ValueRules.alloc(machine, Iteration({ source: id, view: Values, next: 0 }))
			(_, "entries") => ValueRules.alloc(machine, Iteration({ source: id, view: Entries, next: 0 }))
			_ => ValueRules.fault_got(
				machine,
				"unsupported: the ${ValueRules.collection_name(collection)} method `${name}`${ValueRules.line_note(site)}",
			)
		}
	}

	# ---- names and operators ---------------------------------------------------

	unready_message : Str -> Str
	unready_message = |name| "Cannot access '${name}' before initialization"

	# A name declared nowhere: a builtin JavaScript has and the subset
	# doesn't, refused, or else node's ReferenceError.
	missing_name_got : ValueRules.Machine, Str, Ast.Where -> ValueRules.Got
	missing_name_got = |machine, name, site|
		if [
			"globalThis",
			"window",
			"require",
			"process",
			"JSON",
			"Symbol",
			"Promise",
			"Date",
			"RegExp",
			"parseInt",
			"parseFloat",
			"BigInt",
			"Reflect",
			"Proxy",
		].contains(name) {
			ValueRules.fault_got(machine, "unsupported: the builtin `${name}`${ValueRules.line_note(site)}")
		} else {
			ValueRules.error_got(machine, ReferenceError, "${name} is not defined", site)
		}

	unary : ValueRules.Machine, Ast.UnaryOperator, Heap.Value, Ast.Where -> ValueRules.Got
	unary = |machine, operator, subject, site|
		match operator {
			Not => { machine: machine, value: Boolean(!ValueRules.is_truthy(subject)) }
			TypeOf => { machine: machine, value: Text(ValueRules.type_of(machine.cells, subject)) }
			Negate => match subject {
				Number(number) => { machine: machine, value: Number(-number) }
				_ => ValueRules.fault_got(
					machine,
					"unsupported: `-` on a ${ValueRules.type_of(machine.cells, subject)} (a coercion)${ValueRules.line_note(site)}",
				)
			}
			Plus => match subject {
				Number(number) => { machine: machine, value: Number(number) }
				_ => ValueRules.fault_got(
					machine,
					"unsupported: `+` on a ${ValueRules.type_of(machine.cells, subject)} (a coercion)${ValueRules.line_note(site)}",
				)
			}
		}

	binary : ValueRules.Machine, Ast.BinaryOperator, Heap.Value, Heap.Value, Ast.Where -> ValueRules.Got
	binary = |machine, operator, left, right, site|
		match operator {
			StrictEqual => {
				machine: machine,
				value: Boolean(ValueRules.is_strictly_equal(left, right)),
			}
			StrictNotEqual => {
				machine: machine,
				value: Boolean(!ValueRules.is_strictly_equal(left, right)),
			}
			Add => ValueRules.add(machine, left, right, site)
			_ => match (left, right) {
				(Number(x), Number(y)) => {
					machine: machine,
					value: ValueRules.arithmetic(operator, x, y),
				}
				(Text(x), Text(y)) => match operator {
					Less => {
						machine: machine,
						value: Boolean(ValueRules.ordering_of_text(x, y) == Before),
					}
					LessOrEqual => {
						machine: machine,
						value: Boolean(ValueRules.ordering_of_text(x, y) != After),
					}
					Greater => {
						machine: machine,
						value: Boolean(ValueRules.ordering_of_text(x, y) == After),
					}
					GreaterOrEqual => {
						machine: machine,
						value: Boolean(ValueRules.ordering_of_text(x, y) != Before),
					}
					_ => ValueRules.fault_got(
						machine,
						"unsupported: arithmetic on strings (a coercion)${ValueRules.line_note(site)}",
					)
				}
				_ => ValueRules.fault_got(
					machine,
					"unsupported: an operator on a ${ValueRules.type_of(machine.cells, left)} and a ${ValueRules.type_of(machine.cells, right)} (a coercion)${ValueRules.line_note(site)}",
				)
			}
		}

	arithmetic : Ast.BinaryOperator, F64, F64 -> Heap.Value
	arithmetic = |operator, x, y| match operator {
		Subtract => Number(x - y)
		Multiply => Number(x * y)
		Divide => Number(x / y)
		Remainder => Number(ValueRules.remainder(x, y))
		Power => Number(ValueRules.power(x, y))
		Less => Boolean(x < y)
		LessOrEqual => Boolean(x <= y)
		Greater => Boolean(x > y)
		GreaterOrEqual => Boolean(x >= y)
		Add => Number(x + y)
		StrictEqual => Boolean(x == y)
		StrictNotEqual => Boolean(x != y)
	}

	# JavaScript's `%`: the sign of the dividend, NaN for a zero divisor or an
	# infinite dividend, the dividend itself for an infinite divisor.
	remainder : F64, F64 -> F64
	remainder = |x, y|
		if y == 0.0 or x.is_nan() or y.is_nan() or x.is_infinite() {
			0.0 / 0.0
		} else if y.is_infinite() {
			x
		} else {
			x.rem_by(y)
		}

	power : F64, F64 -> F64
	power = |x, y|
		if y.is_nan() or ((x == 1.0 or x == -1.0) and y.is_infinite()) {
			0.0 / 0.0
		} else {
			x.pow(y)
		}

	# `+`: numbers add; a string, an array or an object on either side makes
	# both sides text, which join.
	add : ValueRules.Machine, Heap.Value, Heap.Value, Ast.Where -> ValueRules.Got
	add = |machine, left, right, site|
		match (left, right) {
			(Number(x), Number(y)) => { machine: machine, value: Number(x + y) }
			_ => {
				is_texty = |subject| match subject {
					Text(_) => True
					Reference(_) => True
					_ => False
				}
				if is_texty(left) or is_texty(right) {
					match (
						ValueRules.text_of(machine.cells, left),
						ValueRules.text_of(machine.cells, right),
					) {
						(Ok(x), Ok(y)) => { machine: machine, value: Text(Str.concat(x, y)) }
						(Err(Unsupported(why)), _) => ValueRules.fault_got(
							machine,
							"${why}${ValueRules.line_note(site)}",
						)
						(_, Err(Unsupported(why))) => ValueRules.fault_got(
							machine,
							"${why}${ValueRules.line_note(site)}",
						)
					}
				} else {
					ValueRules.fault_got(
						machine,
						"unsupported: `+` on a ${ValueRules.type_of(machine.cells, left)} and a ${ValueRules.type_of(machine.cells, right)} (a coercion)${ValueRules.line_note(site)}",
					)
				}
			}
		}

	# Whether evaluating an expression can't change a variable: it calls
	# nothing, assigns nothing and makes no function.
	is_pure : Ast.Expression -> Bool
	is_pure = |expression| match expression {
		Number(_) => True
		Text(_) => True
		Boolean(_) => True
		Null => True
		Undefined => True
		Name(_, _, _) => True
		Template(_, parts) => parts.all(ValueRules.is_pure)
		ArrayLit(items) => items.all(ValueRules.is_pure_element)
		ObjectLit(parts) => parts.all(
			|part| match part {
				Field(p) => ValueRules.is_pure(p.value)
				Spread(spread, _) => ValueRules.is_pure(spread)
			},
		)
		Unary(_, left, _) => ValueRules.is_pure(left)
		Binary(_, left, right, _) => ValueRules.is_pure(left) and ValueRules.is_pure(right)
		Logical(_, left, right) => ValueRules.is_pure(left) and ValueRules.is_pure(right)
		Conditional(
			test,
			yes,
			no,
		) => ValueRules.is_pure(test) and ValueRules.is_pure(yes) and ValueRules.is_pure(no)
		Member(left, _, _) => ValueRules.is_pure(left)
		Index(left, right, _) => ValueRules.is_pure(left) and ValueRules.is_pure(right)
		Assign(_, _, _, _) => False
		Update(_, _, _, _) => False
		Call(_, _, _) => False
		Function(_) => False
		Destructure(_, _, _) => False
		New(_, _, _) => False
		OptionalMember(left, _, _) => ValueRules.is_pure(left)
		OptionalIndex(left, right, _) => ValueRules.is_pure(left) and ValueRules.is_pure(right)
		OptionalCall(_, _, _) => False
		Chain(chain) => ValueRules.is_pure(chain)
	}

	is_pure_element : Ast.Element -> Bool
	is_pure_element = |element|
		match element {
			Single(expression) => ValueRules.is_pure(expression)
			Spread(expression, _) => ValueRules.is_pure(expression)
		}

	# ---- patterns --------------------------------------------------------------

	## Where a value being taken apart came from, which node's messages name
	## when it can't be: the expression written beside the pattern, a call's
	## argument, or a part of a bigger value.
	Origin : [Written(Ast.Expression), Argument, Nested]

	is_array_cell : List(Heap.Cell), U64 -> Bool
	is_array_cell = |cells, id|
		match ValueRules.kind_of(cells, id) {
			ArrayKind(_) => True
			_ => False
		}

	# An object's own properties but those `taken`, in key order, as `...rest`
	# takes them.
	properties_left : List(Heap.Cell), Heap.Value, List(Str) -> Try(List(Heap.Property), [Unsupported(Str)])
	properties_left = |cells, subject, taken| {
		refused = Err(Unsupported("unsupported: `...rest` of anything but a plain object"))
		match subject {
			Reference(id) => match Heap.cell_at(cells, id) {
				Object(properties) => Ok(
					Inspect.properties_in_key_order(properties).keep_if(|p| !taken.contains(p.key)),
				)
				_ => refused
			}
			_ => refused
		}
	}

	# node's words for a pattern of properties given `null` or `undefined`.
	destructure_message : Heap.Value, List(Ast.PropertyPattern), ValueRules.Origin -> Str
	destructure_message = |subject, properties, origin| {
		nothing = match subject {
			Null => "null"
			_ => "undefined"
		}
		source = match origin {
			Written(expression) => ValueRules.source_text(expression)
			Argument => match subject {
				Null => "object null"
				_ => "undefined"
			}
			Nested => nothing
		}
		match (origin, properties.first()) {
			(Nested, Ok(first)) => "Cannot read properties of ${nothing} (reading '${first.key}')"
			(_, Ok(first)) => "Cannot destructure property '${first.key}' of '${source}' as it is ${nothing}."
			(_, Err(ListWasEmpty)) => "Cannot destructure '${source}' as it is ${nothing}."
		}
	}

	# The machine stopped by the TypeError node gives for taking apart, or
	# walking, what isn't iterable: the expression written, where there is one,
	# else the value's type and value.
	with_not_iterable : ValueRules.Machine, Heap.Value, ValueRules.Origin, Ast.Where -> ValueRules.Machine
	with_not_iterable = |machine, subject, origin, site| {
		message = match origin {
			Written(expression) => "${ValueRules.source_text(expression)} is not iterable"
			_ => {
				shown = match subject {
					Number(number) => "number ${NumberText.text_for(number)}"
					Boolean(truth) => if truth {
						"boolean true"
					} else {
						"boolean false"
					}
					Null => "object null"
					_ => ValueRules.type_of(machine.cells, subject)
				}
				"${shown} is not iterable (cannot read property Symbol(Symbol.iterator))"
			}
		}
		ValueRules.with_error(machine, TypeError, message, site)
	}

	# ---- properties ------------------------------------------------------------

	property : ValueRules.Machine, Heap.Value, Str, Ast.Where -> ValueRules.Got
	property = |machine, object, key, site|
		match object {
			Reference(id) => match Heap.cell_at(machine.cells, id) {
				Object(properties) => {
					if Heap.has_property(properties, key) {
						{ machine: machine, value: Heap.property_value(properties, key) }
					} else if ValueRules.is_prototype_name(key) {
						ValueRules.fault_got(
							machine,
							"unsupported: Object.prototype's `${key}`${ValueRules.line_note(site)}",
						)
					} else {
						{ machine: machine, value: Undefined }
					}
				}
				Array(items) => {
					if key == "length" {
						{ machine: machine, value: Number(items.len().to_f64()) }
					} else {
						match Inspect.index_of_key(key) {
							Ok(position) => {
								machine: machine,
								value: items.get(position) ?? Undefined,
							}
							Err(NotIndex) => ValueRules.fault_got(
								machine,
								"unsupported: the array property `${key}` outside a call${ValueRules.line_note(site)}",
							)
						}
					}
				}
				Namespace(name, properties) => {
					if Heap.has_property(properties, key) {
						{ machine: machine, value: Heap.property_value(properties, key) }
					} else {
						ValueRules.fault_got(
							machine,
							"unsupported: `${name}.${key}`${ValueRules.line_note(site)}",
						)
					}
				}
				Builtin(number, properties) => {
					if Heap.has_property(properties, key) {
						{ machine: machine, value: Heap.property_value(properties, key) }
					} else {
						ValueRules.fault_got(
							machine,
							"unsupported: `${Heap.native_name(number)}.${key}`${ValueRules.line_note(site)}",
						)
					}
				}
				Fun(_) => ValueRules.fault_got(
					machine,
					"unsupported: a function's properties (`${key}`)${ValueRules.line_note(site)}",
				)
				TimerHandle(_) => ValueRules.fault_got(
					machine,
					"unsupported: a timer's properties (`${key}`)${ValueRules.line_note(site)}",
				)
				MapOf(_) => ValueRules.collection_property(machine, IsMap, Heap.table_of(Heap.cell_at(machine.cells, id)), key, site)
				SetOf(_) => ValueRules.collection_property(machine, IsSet, Heap.table_of(Heap.cell_at(machine.cells, id)), key, site)
				Iteration(_) => ValueRules.fault_got(
					machine,
					"unsupported: an iterator's properties and methods (`${key}`)${ValueRules.line_note(site)}",
				)
				UnreadyVariable | Variable(_) | Environment(_) | Freed(_) => crash "ValueRules.property: no JavaScript value refers to a VM box, an environment or a freed cell"
				Failure(name, message) => match key {
					"name" => { machine: machine, value: Text(Heap.error_name_text(name)) }
					"message" => { machine: machine, value: Text(message) }
					_ => {
						if key == "stack" or ValueRules.is_prototype_name(key) {
							ValueRules.fault_got(
								machine,
								"unsupported: an error's `${key}`${ValueRules.line_note(site)}",
							)
						} else {
							{ machine: machine, value: Undefined }
						}
					}
				}
			}
			Text(text) => {
				if key == "length" {
					if ValueRules.is_ascii(text) {
						{ machine: machine, value: Number(text.count_utf8_bytes().to_f64()) }
					} else {
						ValueRules.fault_got(
							machine,
							"unsupported: the length of a string with non-ASCII text${ValueRules.line_note(site)}",
						)
					}
				} else {
					match Inspect.index_of_key(key) {
						Ok(position) => ValueRules.char_at(machine, text, position, site)
						Err(NotIndex) => ValueRules.fault_got(
							machine,
							"unsupported: the string property `${key}` outside a call${ValueRules.line_note(site)}",
						)
					}
				}
			}
			Null => ValueRules.error_got(
				machine,
				TypeError,
				"Cannot read properties of null (reading '${key}')",
				site,
			)
			Undefined => ValueRules.error_got(
				machine,
				TypeError,
				"Cannot read properties of undefined (reading '${key}')",
				site,
			)
			_ => ValueRules.fault_got(
				machine,
				"unsupported: the property `${key}` of a ${ValueRules.type_of(machine.cells, object)}${ValueRules.line_note(site)}",
			)
		}

	# A Map's or a Set's property: its `size`; a method's name outside a call
	# is refused, since the subset calls a collection's methods by name.
	collection_property : ValueRules.Machine, ValueRules.Collection, Heap.Table, Str, Ast.Where -> ValueRules.Got
	collection_property = |machine, collection, table, key, site|
		if key == "size" {
			{ machine: machine, value: Number(table.size.to_f64()) }
		} else if ValueRules.is_prototype_name(key) or ["get", "set", "add", "has", "delete", "clear", "forEach", "keys", "values", "entries"].contains(key) {
			ValueRules.fault_got(
				machine,
				"unsupported: the ${ValueRules.collection_name(collection)} method `${key}` outside a call${ValueRules.line_note(site)}",
			)
		} else {
			{ machine: machine, value: Undefined }
		}

	is_prototype_name : Str -> Bool
	is_prototype_name = |key| [
		"toString",
		"hasOwnProperty",
		"valueOf",
		"constructor",
		"isPrototypeOf",
		"propertyIsEnumerable",
		"toLocaleString",
		"__proto__",
	].contains(key)

	is_ascii : Str -> Bool
	is_ascii = |text| text.to_utf8().all(|byte| byte < 128)

	char_at : ValueRules.Machine, Str, U64, Ast.Where -> ValueRules.Got
	char_at = |machine, text, position, site|
		if !ValueRules.is_ascii(text) {
			ValueRules.fault_got(
				machine,
				"unsupported: indexing a string with non-ASCII text${ValueRules.line_note(site)}",
			)
		} else {
			match text.to_utf8().get(position) {
				Ok(byte) => {
					machine: machine,
					value: Text(Str.from_utf8([byte]) ?? crash "ValueRules.char_at: an ASCII byte"),
				}
				Err(OutOfBounds) => { machine: machine, value: Undefined }
			}
		}

	indexed_value : ValueRules.Machine, Heap.Value, Heap.Value, Ast.Where -> ValueRules.Got
	indexed_value = |machine, object, key, site|
		match (object, ValueRules.index_of(key)) {
			(Reference(id), Ok(position)) => match Heap.cell_at(machine.cells, id) {
				Array(items) => { machine: machine, value: items.get(position) ?? Undefined }
				_ => ValueRules.property_by_value(machine, object, key, site)
			}
			(Text(text), Ok(position)) => ValueRules.char_at(machine, text, position, site)
			_ => ValueRules.property_by_value(machine, object, key, site)
		}

	property_by_value : ValueRules.Machine, Heap.Value, Heap.Value, Ast.Where -> ValueRules.Got
	property_by_value = |machine, object, key, site|
		match ValueRules.key_of(key) {
			Ok(key_value) => ValueRules.property(machine, object, key_value, site)
			Err(Unsupported(why)) => ValueRules.fault_got(machine, "${why}${ValueRules.line_note(site)}")
		}

	# What a cell is, and an array's length, with nothing of the cell kept.
	#
	# **A WRITER ASKS THIS, NEVER `Heap.cell_at`.** A cell matched out of the
	# heap is a second reference to its props or items for as long as the
	# match's arm runs, so a write made inside that arm copies them: every
	# store into an array of N items copied the N items. These answers hold
	# nothing of the heap.
	Kind : [ObjectKind, ArrayKind(U64), FunctionKind, BuiltinKind, ErrorKind, MapKind, SetKind, IteratorKind]

	kind_of : List(Heap.Cell), U64 -> ValueRules.Kind
	kind_of = |cells, id|
		match Heap.cell_at(cells, id) {
			Object(_) => ObjectKind
			Array(items) => ArrayKind(items.len())
			Fun(_) => FunctionKind
			Builtin(_, _) => BuiltinKind
			Namespace(_, _) => BuiltinKind
			TimerHandle(_) => BuiltinKind
			Failure(_, _) => ErrorKind
			MapOf(_) => MapKind
			SetOf(_) => SetKind
			Iteration(_) => IteratorKind
			UnreadyVariable | Variable(_) | Environment(_) | Freed(_) => crash "ValueRules.kind_of: no JavaScript value refers to a VM box, an environment or a freed cell"
		}

	# A property or an item written: an object's property, an array's item
	# inside it or at its end.
	with_stored : ValueRules.Machine, Heap.Value, Heap.Value, Heap.Value, Ast.Where -> ValueRules.Got
	with_stored = |machine, object, key, value, site|
		if !ValueRules.is_running(machine) {
			{ machine: machine, value: value }
		} else {
			match object {
				Reference(id) => match ValueRules.kind_of(machine.cells, id) {
					ObjectKind => match ValueRules.key_of(key) {
						Ok(key_value) => {
							machine: {
								..machine,
								cells: Heap.with_property(machine.cells, id, key_value, value),
							},
							value: value,
						}
						Err(Unsupported(why)) => ValueRules.fault_got(
							machine,
							"${why}${ValueRules.line_note(site)}",
						)
					}
					ArrayKind(length) => {
						match ValueRules.index_of(key) {
							Ok(position) if position <= length => {
								machine: {
									..machine,
									cells: Heap.with_item(machine.cells, id, position, value),
								},
								value: value,
							}
							Ok(_) => ValueRules.fault_got(
								machine,
								"unsupported: an array with holes (a write past its end)${ValueRules.line_note(site)}",
							)
							Err(NotIndex) => ValueRules.fault_got(
								machine,
								"unsupported: writing an array's `length` or a named property${ValueRules.line_note(site)}",
							)
						}
					}
					ErrorKind => ValueRules.fault_got(
						machine,
						"unsupported: writing a property of an error${ValueRules.line_note(site)}",
					)
					MapKind | SetKind => ValueRules.fault_got(
						machine,
						"unsupported: writing a property of a Map or a Set (use its methods)${ValueRules.line_note(site)}",
					)
					_ => ValueRules.fault_got(
						machine,
						"unsupported: writing a property of a function or a builtin${ValueRules.line_note(site)}",
					)
				}
				Null | Undefined => {
					nothing = if object == Null {
						"null"
					} else {
						"undefined"
					}
					setting = match ValueRules.key_of(key) {
						Ok(text) => " (setting '${text}')"
						Err(_) => ""
					}
					ValueRules.error_got(
						machine,
						TypeError,
						"Cannot set properties of ${nothing}${setting}",
						site,
					)
				}
				_ => ValueRules.fault_got(
					machine,
					"unsupported: writing a property of a ${ValueRules.type_of(machine.cells, object)}${ValueRules.line_note(site)}",
				)
			}
		}

	# ---- builtins --------------------------------------------------------------

	# What `new` makes: an error, from `Error` and its kin, or a Map or a
	# Set, the subset's constructors. `new` on a function of the program would need its
	# prototype, which the subset leaves out.
	constructed : ValueRules.Machine, Heap.Value, Ast.Expression, List(Heap.Value), Ast.Where -> ValueRules.Got
	constructed = |machine, maker, callee, arguments, site|
		if !ValueRules.is_running(machine) {
			{ machine: machine, value: Undefined }
		} else {
			made = match maker {
				Reference(id) => match Heap.cell_at(machine.cells, id) {
					Builtin(MakeError(name), _) => Errors(name)
					Builtin(MakeMap, _) => Collected(IsMap)
					Builtin(MakeSet, _) => Collected(IsSet)
					Fun(_) => Program
					_ => Nothing
				}
				_ => Nothing
			}
			match made {
				Errors(name) => ValueRules.error_made(machine, name, arguments, site)
				Collected(collection) => ValueRules.collection_made(machine, collection, arguments, site)
				Program => ValueRules.fault_got(
					machine,
					"unsupported: `new` on a function of the program (constructors and prototypes)${ValueRules.line_note(site)}",
				)
				Nothing => ValueRules.error_got(
					machine,
					TypeError,
					"${ValueRules.source_text(callee)} is not a constructor",
					site,
				)
			}
		}

	# `new Error(message)` and its kin: the message the text of what is given,
	# or none.
	error_made : ValueRules.Machine, Heap.ErrorName, List(Heap.Value), Ast.Where -> ValueRules.Got
	error_made = |machine, name, arguments, site| {
		message = match arguments.first() {
			Ok(Undefined) | Err(ListWasEmpty) => Ok("")
			Ok(given) => ValueRules.text_of(machine.cells, given)
		}
		match message {
			Ok(text) => ValueRules.alloc(machine, Failure(name, text))
			Err(Unsupported(why)) => ValueRules.fault_got(machine, "${why}${ValueRules.line_note(site)}")
		}
	}

	number_argument : List(Heap.Value), U64 -> Try(F64, [NotNumber])
	number_argument = |arguments, position|
		match arguments.get(position) {
			Ok(Number(number)) => Ok(number)
			_ => Err(NotNumber)
		}

	math : ValueRules.Machine, Str, List(Heap.Value), (F64 -> F64), Ast.Where -> ValueRules.Got
	math = |machine, name, arguments, function, site|
		match ValueRules.number_argument(arguments, 0) {
			Ok(number) => { machine: machine, value: Number(function(number)) }
			Err(NotNumber) => ValueRules.fault_got(
				machine,
				"unsupported: Math.${name} of anything but a number${ValueRules.line_note(site)}",
			)
		}

	floor : F64 -> F64
	floor = |number|
		if number.is_nan() or number.is_infinite() or number == 0.0 {
			number
		} else {
			number.div_floor_by(1.0)
		}

	# The values of an object with a whole `length`, as `Array.from` reads
	# them; a number or a boolean has none.
	array_like : List(Heap.Cell), Heap.Value -> Try(List(Heap.Value), [Unsupported(Str)])
	array_like = |cells, source|
		match source {
			Reference(id) => match Heap.cell_at(cells, id) {
				Object(properties) => match Heap.property_value(properties, "length") {
					Number(length) if length >= 0.0 and length.div_trunc_by(1.0) == length and length <= 10000000.0 => {
						count = length.to_u64_try() ?? 0
						var $values = List.with_capacity(count)
						var $i = 0
						while $i < count {
							$values = $values.append(Heap.property_value(properties, $i.to_str()))
							$i = $i + 1
						}
						Ok($values)
					}
					Undefined => Ok([])
					_ => Err(Unsupported("unsupported: `Array.from` of an object whose `length` is not a whole number up to 10,000,000"))
				}
				_ => Ok([])
			}
			Number(_) | Boolean(_) => Ok([])
			_ => Err(Unsupported("unsupported: `Array.from` of null or undefined"))
		}

	is_callable : List(Heap.Cell), Heap.Value -> Bool
	is_callable = |cells, value|
		match value {
			Reference(id) => match Heap.cell_at(cells, id) {
				Fun(_) => True
				Builtin(_, _) => True
				_ => False
			}
			_ => False
		}

	min_max : ValueRules.Machine, List(Heap.Value), [Min, Max], Ast.Where -> ValueRules.Got
	min_max = |machine, arguments, which, site| {
		var $best = match which {
			Min => 1.0 / 0.0
			Max => -1.0 / 0.0
		}
		var $ok = True
		for argument in arguments {
			match argument {
				Number(x) => {
					$best = if x.is_nan() or $best.is_nan() {
						0.0 / 0.0
					} else {
						match which {
							Min => if x < $best or (x == 0.0 and 1.0 / x < 0.0) {
								x
							} else {
								$best
							}
							Max => if x > $best or (x == 0.0 and 1.0 / x > 0.0 and $best == 0.0) {
								x
							} else {
								$best
							}
						}
					}
				}
				_ => {
					$ok = False
				}
			}
		}
		if $ok {
			{ machine: machine, value: Number($best) }
		} else {
			ValueRules.fault_got(
				machine,
				"unsupported: Math.min or Math.max of anything but numbers${ValueRules.line_note(site)}",
			)
		}
	}

	# Object.keys, Object.values or Object.entries, of an object or an array.
	Listing : [Keys, Values, Entries]

	object_listing : ValueRules.Machine, List(Heap.Value), ValueRules.Listing, Ast.Where -> ValueRules.Got
	object_listing = |machine, arguments, which, site| {
		properties = match arguments.first() {
			Ok(Reference(id)) => match Heap.cell_at(machine.cells, id) {
				Object(listed) => Ok(Inspect.properties_in_key_order(listed))
				Array(items) => {
					var $listed = []
					var $i = 0
					for item in items {
						$listed = $listed.append({ key: $i.to_str(), value: item })
						$i = $i + 1
					}
					Ok($listed)
				}
				_ => Err(NotListed)
			}
			_ => Err(NotListed)
		}
		match properties {
			Ok(listed) => {
				var $s = machine
				var $values = []
				for parent in listed {
					subject = match which {
						Keys => Text(parent.key)
						Values => parent.value
						Entries => {
							{ machine: made, value: pair } = ValueRules.alloc(
								$s,
								Array([Text(parent.key), parent.value]),
							)
							$s = made
							pair
						}
					}
					$values = $values.append(subject)
				}
				ValueRules.alloc($s, Array($values))
			}
			Err(NotListed) => ValueRules.fault_got(
				machine,
				"unsupported: Object.keys, values or entries of anything but an object or an array${ValueRules.line_note(site)}",
			)
		}
	}

	## A builtin's answer, for the builtins that make no effect and call
	## nothing back. The VM runs the others itself: `console.log`, the
	## canvas's, the timers, `onClick`, and `Array.from` with a mapper.
	native_called : ValueRules.Machine, Heap.Native, List(Heap.Value), Ast.Where -> ValueRules.Got
	native_called = |machine, native, arguments, site|
		match native {
			Floor => ValueRules.math(machine, "floor", arguments, ValueRules.floor, site)
			Ceil => ValueRules.math(
				machine,
				"ceil",
				arguments,
				|x| -ValueRules.floor(-x),
				site,
			)
			Round => ValueRules.math(
				machine,
				"round",
				arguments,
				|x| {
					floored = ValueRules.floor(x)
					if x - floored >= 0.5 {
						# Rounding up from (-0.5, 0) gives -0, as JavaScript's does.
						if x < 0.0 and floored == -1.0 {
							-0.0
						} else {
							floored + 1.0
						}
					} else {
						floored
					}
				},
				site,
			)
			Trunc => ValueRules.math(
				machine,
				"trunc",
				arguments,
				|x|
					if x.is_nan() or x.is_infinite() {
						x
					} else {
						x.div_trunc_by(1.0)
					},
				site,
			)
			Abs => ValueRules.math(
				machine,
				"abs",
				arguments,
				|x| x.abs(),
				site,
			)
			Sign => ValueRules.math(
				machine,
				"sign",
				arguments,
				|x|
					if x > 0.0 {
						1.0
					} else if x < 0.0 {
						-1.0
					} else {
						x
					},
				site,
			)
			Sqrt => ValueRules.math(
				machine,
				"sqrt",
				arguments,
				|x| x.sqrt(),
				site,
			)
			Sin => ValueRules.math(
				machine,
				"sin",
				arguments,
				|x| x.sin(),
				site,
			)
			Cos => ValueRules.math(
				machine,
				"cos",
				arguments,
				|x| x.cos(),
				site,
			)
			Tan => ValueRules.math(
				machine,
				"tan",
				arguments,
				|x| x.tan(),
				site,
			)
			Atan => ValueRules.math(
				machine,
				"atan",
				arguments,
				|x| x.atan(),
				site,
			)
			Pow => match (
				ValueRules.number_argument(arguments, 0),
				ValueRules.number_argument(arguments, 1),
			) {
				(Ok(x), Ok(y)) => { machine: machine, value: Number(ValueRules.power(x, y)) }
				_ => ValueRules.fault_got(
					machine,
					"unsupported: Math.pow of anything but two numbers${ValueRules.line_note(site)}",
				)
			}
			Min => ValueRules.min_max(machine, arguments, Min, site)
			Max => ValueRules.min_max(machine, arguments, Max, site)
			Keys => ValueRules.object_listing(machine, arguments, Keys, site)
			Values => ValueRules.object_listing(machine, arguments, Values, site)
			Entries => ValueRules.object_listing(machine, arguments, Entries, site)
			StringOf => match arguments.first() {
				Ok(subject) => match ValueRules.text_of(machine.cells, subject) {
					Ok(phrase) => { machine: machine, value: Text(phrase) }
					Err(Unsupported(why)) => ValueRules.fault_got(
						machine,
						"${why}${ValueRules.line_note(site)}",
					)
				}
				Err(ListWasEmpty) => { machine: machine, value: Text("") }
			}
			FromCharCode => {
				var $bytes = []
				var $ok = True
				for argument in arguments {
					match argument {
						Number(code) if code >= 0.0 and code < 128.0 and code.div_trunc_by(1.0) == code => {
							$bytes = $bytes.append(code.to_u8_try() ?? 0)
						}
						_ => {
							$ok = False
						}
					}
				}
				if $ok {
					{
						machine: machine,
						value: Text(Str.from_utf8($bytes) ?? crash "ValueRules.native_called: ASCII bytes"),
					}
				} else {
					ValueRules.fault_got(
						machine,
						"unsupported: String.fromCharCode of anything but ASCII codes${ValueRules.line_note(site)}",
					)
				}
			}
			IsArray => match arguments.first() {
				Ok(Reference(id)) => match Heap.cell_at(machine.cells, id) {
					Array(_) => { machine: machine, value: Boolean(True) }
					_ => { machine: machine, value: Boolean(False) }
				}
				_ => { machine: machine, value: Boolean(False) }
			}
			IsInteger => match arguments.first() {
				Ok(Number(x)) => {
					machine: machine,
					value: Boolean(!x.is_nan() and !x.is_infinite() and x.div_trunc_by(1.0) == x),
				}
				_ => { machine: machine, value: Boolean(False) }
			}
			MakeError(name) => ValueRules.fault_got(
				machine,
				"unsupported: calling `${Heap.error_name_text(name)}` without `new`${ValueRules.line_note(site)}",
			)
			ArrayFrom if !ValueRules.is_mapped(arguments) => {
				{ machine: walked, listed } = ValueRules.array_from_values(machine, arguments.first() ?? Undefined)
				match listed {
					Ok(values) => ValueRules.alloc(walked, Array(values))
					Err(Unsupported(why)) => ValueRules.fault_got(walked, "${why}${ValueRules.line_note(site)}")
				}
			}
			ArrayOf => ValueRules.alloc(machine, Array(arguments))
			MakeMap | MakeSet => ValueRules.error_got(
				machine,
				TypeError,
				"Constructor ${Heap.native_name(native)} requires 'new'",
				site,
			)
			ArrayFrom | Log | Paint(_) | Move(_) | Sense(_) | Timing(_) | OnClick => crash "ValueRules.native_called: the VM runs a builtin that makes an effect or calls back itself"
		}

	# Whether `Array.from` is given a mapper, which the VM calls back.
	is_mapped : List(Heap.Value) -> Bool
	is_mapped = |arguments| match arguments.get(1) {
		Ok(Undefined) | Err(OutOfBounds) => False
		Ok(_) => True
	}

	# `Array.from(source)`'s values: an iterable's, or those of an object with
	# a `length` (`{ length: 3 }`, its properties "0" to "2").
	array_from_values : ValueRules.Machine, Heap.Value -> { machine : ValueRules.Machine, listed : Try(List(Heap.Value), [Unsupported(Str)]) }
	array_from_values = |machine, source| {
		{ machine: walked, values: found } = ValueRules.iterated(machine, source)
		listed = match found {
			Ok(values) => Ok(values)
			Err(NotIterable) => ValueRules.array_like(walked.cells, source)
		}
		{ machine: walked, listed: listed }
	}

	# ---- array methods ---------------------------------------------------------

	items_of : List(Heap.Cell), U64 -> List(Heap.Value)
	items_of = |cells, id|
		match Heap.cell_at(cells, id) {
			Array(items) => items
			_ => crash "ValueRules.items_of: the interpreter asks only an array for its items"
		}

	item_count : List(Heap.Cell), U64 -> U64
	item_count = |cells, id|
		match Heap.cell_at(cells, id) {
			Array(items) => items.len()
			_ => crash "ValueRules.item_count: the interpreter asks only an array for its length"
		}

	item_at : List(Heap.Cell), U64, U64 -> Heap.Value
	item_at = |cells, id, position|
		match Heap.cell_at(cells, id) {
			Array(items) => items.get(position) ?? Undefined
			_ => crash "ValueRules.item_at: the interpreter asks only an array for an item"
		}

	# A relative index (`slice`'s, negative from the end) as an index in 0..n.
	relative_index : Heap.Value, U64, U64 -> U64
	relative_index = |subject, length, otherwise|
		match subject {
			Number(x) => {
				truncated = if x.is_nan() {
					0.0
				} else {
					x.div_trunc_by(1.0)
				}
				if truncated < 0.0 {
					from_end = length.to_f64() + truncated
					if from_end < 0.0 {
						0
					} else {
						from_end.to_u64_try() ?? 0
					}
				} else if truncated >= length.to_f64() {
					length
				} else {
					truncated.to_u64_try() ?? 0
				}
			}
			_ => otherwise
		}

	# Where in `items` from `from` on an item first passes `test`, or none.
	first_place : List(Heap.Value), U64, (Heap.Value -> Bool) -> [Place(U64), NoPlace]
	first_place = |items, from, test| {
		var $found = NoPlace
		var $i = 0
		for item in items {
			if $found == NoPlace and $i >= from and test(item) {
				$found = Place($i)
			}
			$i = $i + 1
		}
		$found
	}

	place_number : [Place(U64), NoPlace] -> F64
	place_number = |found| match found {
		Place(position) => position.to_f64()
		NoPlace => -1.0
	}

	# `at`'s index: from the end when negative, or none past either end.
	at_index : Heap.Value, U64 -> Try(U64, [OutOfRange])
	at_index = |subject, length| {
		wanted = match subject {
			Number(number) if !number.is_nan() => number.div_trunc_by(1.0)
			_ => 0.0
		}
		place = if wanted < 0.0 {
			length.to_f64() + wanted
		} else {
			wanted
		}
		if place >= 0.0 and place < length.to_f64() {
			place.to_u64_try().map_err(|_| OutOfRange)
		} else {
			Err(OutOfRange)
		}
	}

	# An array's items with the arrays among them put in their place, to
	# `depth` levels, as `flat` puts them.
	flattened : List(Heap.Cell), List(Heap.Value), U64 -> List(Heap.Value)
	flattened = |cells, items, depth| {
		var $out = []
		for item in items {
			inner = match item {
				Reference(id) if depth > 0 => match Heap.cell_at(cells, id) {
					Array(nested) => Nested(nested)
					_ => Lone
				}
				_ => Lone
			}
			$out = match inner {
				Nested(nested) => List.concat($out, ValueRules.flattened(cells, nested, depth - 1))
				Lone => $out.append(item)
			}
		}
		$out
	}

	## An array's method, for the methods that call nothing back; the VM runs
	## the others itself.
	array_method : ValueRules.Machine, U64, Str, List(Heap.Value), Ast.Where -> ValueRules.Got
	array_method = |
		machine,
		id,
		name,
		arguments,
		site,
	|
		match name {
			"push" => {
				pushed = { ..machine, cells: Heap.with_items_pushed(machine.cells, id, arguments) }
				{ machine: pushed, value: Number(ValueRules.item_count(pushed.cells, id).to_f64()) }
			}
			"pop" => {
				count = ValueRules.item_count(machine.cells, id)
				if count == 0 {
					{ machine: machine, value: Undefined }
				} else {
					last = ValueRules.item_at(machine.cells, id, count - 1)
					{
						machine: { ..machine, cells: Heap.with_last_dropped(machine.cells, id) },
						value: last,
					}
				}
			}
			"join" => {
				separator = match arguments.first() {
					Ok(Text(text)) => Ok(text)
					Ok(Undefined) => Ok(",")
					Err(ListWasEmpty) => Ok(",")
					_ => Err(NotText)
				}
				match separator {
					Ok(text) => {
						var $parts = []
						var $why = ""
						for item in ValueRules.items_of(machine.cells, id) {
							part = match item {
								Null => Ok("")
								Undefined => Ok("")
								_ => ValueRules.text_of(machine.cells, item)
							}
							match part {
								Ok(phrase) => {
									$parts = $parts.append(phrase)
								}
								Err(Unsupported(why)) => {
									$why = why
								}
							}
						}
						if $why == "" {
							{ machine: machine, value: Text(Str.join_with($parts, text)) }
						} else {
							ValueRules.fault_got(machine, "${$why}${ValueRules.line_note(site)}")
						}
					}
					Err(NotText) => ValueRules.fault_got(
						machine,
						"unsupported: `join` with a separator that is not a string${ValueRules.line_note(site)}",
					)
				}
			}
			"indexOf" => {
				target = arguments.first() ?? Undefined
				items = ValueRules.items_of(machine.cells, id)
				from = ValueRules.relative_index(arguments.get(1) ?? Undefined, items.len(), 0)
				found = ValueRules.first_place(items, from, |item| ValueRules.is_strictly_equal(item, target))
				{ machine: machine, value: Number(ValueRules.place_number(found)) }
			}
			"includes" => {
				target = arguments.first() ?? Undefined
				items = ValueRules.items_of(machine.cells, id)
				from = ValueRules.relative_index(arguments.get(1) ?? Undefined, items.len(), 0)
				found = ValueRules.first_place(items, from, |item| ValueRules.is_same_value_zero(item, target))
				{ machine: machine, value: Boolean(found != NoPlace) }
			}
			"lastIndexOf" => {
				if arguments.len() > 1 {
					ValueRules.fault_got(
						machine,
						"unsupported: `lastIndexOf` from a position${ValueRules.line_note(site)}",
					)
				} else {
					target = arguments.first() ?? Undefined
					items = ValueRules.items_of(machine.cells, id)
					var $found = -1.0
					var $i = 0
					for item in items {
						if ValueRules.is_strictly_equal(item, target) {
							$found = $i.to_f64()
						}
						$i = $i + 1
					}
					{ machine: machine, value: Number($found) }
				}
			}
			"at" => {
				items = ValueRules.items_of(machine.cells, id)
				found = match ValueRules.at_index(arguments.first() ?? Undefined, items.len()) {
					Ok(position) => items.get(position) ?? Undefined
					Err(OutOfRange) => Undefined
				}
				{ machine: machine, value: found }
			}
			"shift" => {
				items = ValueRules.items_of(machine.cells, id)
				match items.first() {
					Ok(head) => {
						machine: { ..machine, cells: Heap.with_items(machine.cells, id, items.drop_first(1)) },
						value: head,
					}
					Err(ListWasEmpty) => { machine: machine, value: Undefined }
				}
			}
			"unshift" => {
				grown = List.concat(arguments, ValueRules.items_of(machine.cells, id))
				count = grown.len()
				{
					machine: { ..machine, cells: Heap.with_items(machine.cells, id, grown) },
					value: Number(count.to_f64()),
				}
			}
			"splice" => {
				items = ValueRules.items_of(machine.cells, id)
				count = items.len()
				start = ValueRules.relative_index(arguments.get(0) ?? Undefined, count, 0)
				removing = match arguments.get(1) {
					Err(OutOfBounds) => if arguments.is_empty() {
						0
					} else {
						count - start
					}
					Ok(Number(wanted)) => {
						if wanted.is_nan() or wanted <= 0.0 {
							0
						} else if wanted >= (count - start).to_f64() {
							count - start
						} else {
							wanted.div_trunc_by(1.0).to_u64_try() ?? 0
						}
					}
					Ok(_) => 0
				}
				removed = items.sublist({ start: start, len: removing })
				kept = List.concat(
					List.concat(items.sublist({ start: 0, len: start }), arguments.drop_first(2)),
					items.drop_first(start + removing),
				)
				ValueRules.alloc({ ..machine, cells: Heap.with_items(machine.cells, id, kept) }, Array(removed))
			}
			"fill" => {
				items = ValueRules.items_of(machine.cells, id)
				count = items.len()
				value = arguments.first() ?? Undefined
				from = ValueRules.relative_index(arguments.get(1) ?? Undefined, count, 0)
				to = ValueRules.relative_index(arguments.get(2) ?? Undefined, count, count)
				filled = items.map_with_index(
					|item, position|
						if position >= from and position < to {
							value
						} else {
							item
						},
				)
				{
					machine: { ..machine, cells: Heap.with_items(machine.cells, id, filled) },
					value: Reference(id),
				}
			}
			"flat" => {
				depth = match arguments.first() {
					Ok(Number(levels)) if levels >= 1.0 => if levels.is_infinite() or levels > 1000.0 {
						1000
					} else {
						levels.div_trunc_by(1.0).to_u64_try() ?? 0
					}
					Ok(Number(_)) => 0
					_ => 1
				}
				ValueRules.alloc(machine, Array(ValueRules.flattened(machine.cells, ValueRules.items_of(machine.cells, id), depth)))
			}
			"slice" => {
				items = ValueRules.items_of(machine.cells, id)
				count = items.len()
				from = ValueRules.relative_index(arguments.get(0) ?? Undefined, count, 0)
				to = ValueRules.relative_index(arguments.get(1) ?? Undefined, count, count)
				cut = if to > from {
					items.sublist({ start: from, len: to - from })
				} else {
					[]
				}
				ValueRules.alloc(machine, Array(cut))
			}
			"concat" => {
				var $out = ValueRules.items_of(machine.cells, id)
				for argument in arguments {
					$out = match argument {
						Reference(other) => match Heap.cell_at(machine.cells, other) {
							Array(more) => List.concat($out, more)
							_ => $out.append(argument)
						}
						_ => $out.append(argument)
					}
				}
				ValueRules.alloc(machine, Array($out))
			}
			"reverse" => {
				items = ValueRules.items_of(machine.cells, id)
				var $reversed = []
				var $k = items.len()
				while $k > 0 {
					$reversed = $reversed.append(items.get($k - 1) ?? crash "ValueRules.array_method: inside the items")
					$k = $k - 1
				}
				reversed = $reversed
				{
					machine: { ..machine, cells: Heap.with_items(machine.cells, id, reversed) },
					value: Reference(id),
				}
			}
			"keys" => ValueRules.alloc(machine, Iteration({ source: id, view: Keys, next: 0 }))
			"values" => ValueRules.alloc(machine, Iteration({ source: id, view: Values, next: 0 }))
			"entries" => ValueRules.alloc(machine, Iteration({ source: id, view: Entries, next: 0 }))
			"forEach" | "map" | "filter" | "some" | "every" | "find" | "findIndex" | "flatMap" | "findLast" | "findLastIndex" | "reduce" | "reduceRight" | "sort" => crash "ValueRules.array_method: the VM runs the methods that call back itself"
			_ => ValueRules.fault_got(
				machine,
				"unsupported: the array method `${name}`${ValueRules.line_note(site)}",
			)
		}

	# ---- string methods --------------------------------------------------------

	# The string methods that count or cut by position, which the subset has
	# for ASCII text alone: JavaScript counts UTF-16 units, where the
	# interpreter's strings are UTF-8.
	positional_methods : List(Str)
	positional_methods = [
		"charAt",
		"charCodeAt",
		"slice",
		"substring",
		"indexOf",
		"lastIndexOf",
		"at",
		"toUpperCase",
		"toLowerCase",
		"trim",
		"trimStart",
		"trimEnd",
	]

	text_method : ValueRules.Machine, Str, Str, List(Heap.Value), Ast.Where -> ValueRules.Got
	text_method = |machine, text, name, arguments, site|
		if ValueRules.positional_methods.contains(name) and !ValueRules.is_ascii(text) {
			ValueRules.fault_got(
				machine,
				"unsupported: `${name}` on a string with non-ASCII text${ValueRules.line_note(site)}",
			)
		} else if name == "split" and arguments.first() == Ok(Text("")) and !ValueRules.is_ascii(text) {
			ValueRules.fault_got(
				machine,
				"unsupported: `split` into characters of a string with non-ASCII text${ValueRules.line_note(site)}",
			)
		} else {
			ValueRules.text_method_of(machine, text, name, arguments, site)
		}

	text_method_of : ValueRules.Machine, Str, Str, List(Heap.Value), Ast.Where -> ValueRules.Got
	text_method_of = |machine, text, name, arguments, site| {
		text_argument = |position| match arguments.get(position) {
			Ok(Text(phrase)) => Ok(phrase)
			_ => Err(NotText)
		}
		bytes = text.to_utf8()
		count = bytes.len()
		sliced = |from, to|
			if to > from {
				Text(
					Str.from_utf8(
						bytes.sublist({ start: from, len: to - from }),
					) ?? crash "ValueRules.text_method: an ASCII cut",
				)
			} else {
				Text("")
			}
		match name {
			"charAt" => match ValueRules.index_of(arguments.first() ?? Number(0.0)) {
				Ok(position) => {
					got = ValueRules.char_at(machine, text, position, site)
					match got.value {
						Undefined => { machine: machine, value: Text("") }
						_ => got
					}
				}
				Err(NotIndex) => { machine: machine, value: Text("") }
			}
			"charCodeAt" => match ValueRules.index_of(arguments.first() ?? Number(0.0)) {
				Ok(position) => match bytes.get(position) {
					Ok(byte) => { machine: machine, value: Number(byte.to_f64()) }
					Err(OutOfBounds) => { machine: machine, value: Number(0.0 / 0.0) }
				}
				Err(NotIndex) => { machine: machine, value: Number(0.0 / 0.0) }
			}
			"slice" => {
				from = ValueRules.relative_index(arguments.get(0) ?? Undefined, count, 0)
				to = ValueRules.relative_index(arguments.get(1) ?? Undefined, count, count)
				{ machine: machine, value: sliced(from, to) }
			}
			"substring" => {
				clamp = |subject, otherwise| match subject {
					Number(x) => if x.is_nan() or x < 0.0 {
						0
					} else if x >= count.to_f64() {
						count
					} else {
						x.div_trunc_by(1.0).to_u64_try() ?? 0
					}
					_ => otherwise
				}
				one_end = clamp(arguments.get(0) ?? Undefined, 0)
				other_end = clamp(arguments.get(1) ?? Undefined, count)
				{
					machine: machine,
					value: sliced(U64.min(one_end, other_end), U64.max(one_end, other_end)),
				}
			}
			"indexOf" => match text_argument(0) {
				Ok(phrase) => {
					from = ValueRules.clamped_index(arguments.get(1) ?? Undefined, count)
					{ machine: machine, value: Number(ValueRules.text_index_from(text, phrase, from)) }
				}
				Err(NotText) => ValueRules.fault_got(
					machine,
					"unsupported: `indexOf` of anything but a string${ValueRules.line_note(site)}",
				)
			}
			"lastIndexOf" => match (text_argument(0), arguments.len()) {
				(Ok(phrase), 1) => { machine: machine, value: Number(ValueRules.text_last_index(text, phrase)) }
				_ => ValueRules.fault_got(
					machine,
					"unsupported: `lastIndexOf` of anything but a string, or from a position${ValueRules.line_note(site)}",
				)
			}
			"includes" => match text_argument(0) {
				Ok(phrase) => {
					from = ValueRules.clamped_index(arguments.get(1) ?? Undefined, count)
					{ machine: machine, value: Boolean(ValueRules.text_index_from(text, phrase, from) >= 0.0) }
				}
				Err(NotText) => ValueRules.fault_got(
					machine,
					"unsupported: `includes` of anything but a string${ValueRules.line_note(site)}",
				)
			}
			"startsWith" => match (text_argument(0), arguments.len()) {
				(Ok(phrase), 1) => { machine: machine, value: Boolean(text.starts_with(phrase)) }
				_ => ValueRules.fault_got(
					machine,
					"unsupported: `startsWith` of anything but a string, or from a position${ValueRules.line_note(site)}",
				)
			}
			"endsWith" => match (text_argument(0), arguments.len()) {
				(Ok(phrase), 1) => { machine: machine, value: Boolean(text.ends_with(phrase)) }
				_ => ValueRules.fault_got(
					machine,
					"unsupported: `endsWith` of anything but a string, or to a position${ValueRules.line_note(site)}",
				)
			}
			"at" => match ValueRules.at_index(arguments.first() ?? Undefined, count) {
				Ok(position) => { machine: machine, value: sliced(position, position + 1) }
				Err(OutOfRange) => { machine: machine, value: Undefined }
			}
			"trimStart" => { machine: machine, value: Text(ValueRules.ascii_trimmed_at(text, Start)) }
			"trimEnd" => { machine: machine, value: Text(ValueRules.ascii_trimmed_at(text, End)) }
			"replace" | "replaceAll" => match (text_argument(0), text_argument(1)) {
				(Ok(phrase), Ok(replacement)) if !replacement.contains("$") and (name == "replace" or !phrase.is_empty()) => {
					replaced = if name == "replaceAll" {
						Str.join_with(text.split_on(phrase), replacement)
					} else {
						ValueRules.text_replaced_once(text, phrase, replacement)
					}
					{ machine: machine, value: Text(replaced) }
				}
				_ => ValueRules.fault_got(
					machine,
					"unsupported: `${name}` but of a string by a string without `$`, or `replaceAll` of the empty string${ValueRules.line_note(site)}",
				)
			}
			"toUpperCase" => { machine: machine, value: Text(text.with_ascii_uppercased()) }
			"toLowerCase" => { machine: machine, value: Text(text.with_ascii_lowercased()) }
			"trim" => { machine: machine, value: Text(ValueRules.ascii_trimmed(text)) }
			"repeat" => match arguments.first() {
				Ok(Number(times)) if times >= 0.0 and times.div_trunc_by(1.0) == times and times < 100000000.0 => {
					{ machine: machine, value: Text(text.repeat(times.to_u64_try() ?? 0)) }
				}
				_ => ValueRules.fault_got(
					machine,
					"unsupported: `repeat` of anything but a whole number of times${ValueRules.line_note(site)}",
				)
			}
			"split" => {
				limit = match arguments.get(1) {
					Ok(Number(most)) if most >= 0.0 and most.div_trunc_by(1.0) == most => Ok(Limited(most.to_u64_try() ?? 0))
					Ok(Undefined) | Err(OutOfBounds) => Ok(Unlimited)
					_ => Err(NotLimit)
				}
				pieces = match text_argument(0) {
					Ok("") => Ok(ValueRules.characters(text))
					Ok(phrase) => Ok(text.split_on(phrase))
					Err(NotText) => Err(NotText)
				}
				match (pieces, limit) {
					(Ok(all), Ok(Unlimited)) => ValueRules.alloc(machine, Array(all.map(|piece| Text(piece))))
					(Ok(all), Ok(Limited(most))) => ValueRules.alloc(
						machine,
						Array(all.take_first(most).map(|piece| Text(piece))),
					)
					_ => ValueRules.fault_got(
						machine,
						"unsupported: `split` by anything but a string, or to a limit that is not a whole number${ValueRules.line_note(site)}",
					)
				}
			}
			"padStart" => ValueRules.text_padded(machine, text, arguments, PadStart, site)
			"padEnd" => ValueRules.text_padded(machine, text, arguments, PadEnd, site)
			"concat" => {
				var $out = text
				var $why = ""
				for argument in arguments {
					match ValueRules.text_of(machine.cells, argument) {
						Ok(phrase) => {
							$out = Str.concat($out, phrase)
						}
						Err(Unsupported(why)) => {
							$why = why
						}
					}
				}
				if $why == "" {
					{ machine: machine, value: Text($out) }
				} else {
					ValueRules.fault_got(machine, "${$why}${ValueRules.line_note(site)}")
				}
			}
			_ => ValueRules.fault_got(
				machine,
				"unsupported: the string method `${name}`${ValueRules.line_note(site)}",
			)
		}
	}

	# Where `phrase` first starts in `text` at `from` or after, in bytes, or
	# -1.
	text_index_from : Str, Str, U64 -> F64
	text_index_from = |text, phrase, from| {
		text_bytes = text.to_utf8()
		phrase_bytes = phrase.to_utf8()
		if phrase_bytes.len() > text_bytes.len() {
			-1.0
		} else {
			var $i = from
			var $found = -1.0
			while $found < 0.0 and $i + phrase_bytes.len() <= text_bytes.len() {
				if text_bytes.sublist({ start: $i, len: phrase_bytes.len() }) == phrase_bytes {
					$found = $i.to_f64()
				}
				$i = $i + 1
			}
			$found
		}
	}

	# Where `phrase` last starts in `text`, in bytes, or -1.
	text_last_index : Str, Str -> F64
	text_last_index = |text, phrase| {
		text_bytes = text.to_utf8()
		phrase_bytes = phrase.to_utf8()
		if phrase_bytes.len() > text_bytes.len() {
			-1.0
		} else {
			var $i = text_bytes.len() - phrase_bytes.len() + 1
			var $found = -1.0
			while $found < 0.0 and $i > 0 {
				$i = $i - 1
				if text_bytes.sublist({ start: $i, len: phrase_bytes.len() }) == phrase_bytes {
					$found = $i.to_f64()
				}
			}
			$found
		}
	}

	# A position argument as a string method clamps it, within 0 and `count`.
	clamped_index : Heap.Value, U64 -> U64
	clamped_index = |subject, count|
		match subject {
			Number(x) => if x.is_nan() or x <= 0.0 {
				0
			} else if x >= count.to_f64() {
				count
			} else {
				x.div_trunc_by(1.0).to_u64_try() ?? 0
			}
			_ => 0
		}

	# `text` with the first `phrase` in it replaced, as `replace` does.
	text_replaced_once : Str, Str, Str -> Str
	text_replaced_once = |text, phrase, replacement| {
		found = ValueRules.text_index_from(text, phrase, 0)
		if found < 0.0 {
			text
		} else {
			bytes = text.to_utf8()
			at = found.to_u64_try() ?? 0
			before = bytes.sublist({ start: 0, len: at })
			after = bytes.drop_first(at + phrase.count_utf8_bytes())
			Str.from_utf8(
				List.concat(List.concat(before, replacement.to_utf8()), after),
			) ?? crash "ValueRules.text_replaced_once: whole characters around a whole phrase"
		}
	}

	ascii_trimmed : Str -> Str
	ascii_trimmed = |text| ValueRules.ascii_trimmed_at(text, Both)

	ascii_trimmed_at : Str, [Start, End, Both] -> Str
	ascii_trimmed_at = |text, ends| {
		bytes = text.to_utf8()
		is_space = |byte| byte == ' ' or byte == '\t' or byte == '\n' or byte == '\r' or byte == 11 or byte == 12
		var $from = 0
		while ends != End and $from < bytes.len() and is_space(bytes.get($from) ?? crash "ValueRules.ascii_trimmed: inside the text") {
			$from = $from + 1
		}
		var $to = bytes.len()
		while ends != Start and $to > $from and is_space(bytes.get($to - 1) ?? crash "ValueRules.ascii_trimmed: inside the text") {
			$to = $to - 1
		}
		Str.from_utf8(
			bytes.sublist({ start: $from, len: $to - $from }),
		) ?? crash "ValueRules.ascii_trimmed: an ASCII cut"
	}

	Side : [PadStart, PadEnd]

	text_padded : ValueRules.Machine, Str, List(Heap.Value), ValueRules.Side, Ast.Where -> ValueRules.Got
	text_padded = |machine, text, arguments, side, site| {
		fill_given = match arguments.get(1) {
			Ok(Text(given)) => Ok(given)
			Err(OutOfBounds) => Ok(" ")
			_ => Err(NotText)
		}
		match (arguments.first(), fill_given) {
			(Ok(Number(wanted)), Ok(pad_text)) if ValueRules.is_ascii(text) and ValueRules.is_ascii(pad_text) and wanted.div_trunc_by(1.0) == wanted and wanted < 100000000.0 => {
				count = text.count_utf8_bytes()
				target = if wanted < 0.0 {
					0
				} else {
					wanted.to_u64_try() ?? 0
				}
				if target <= count or pad_text.is_empty() {
					{ machine: machine, value: Text(text) }
				} else {
					need = target - count
					fill_bytes = pad_text.to_utf8()
					copies = need // fill_bytes.len() + 1
					pad = Str.from_utf8(
						pad_text.repeat(copies).to_utf8().sublist({ start: 0, len: need }),
					) ?? crash "ValueRules.text_padded: an ASCII cut"
					match side {
						PadStart => { machine: machine, value: Text(Str.concat(pad, text)) }
						PadEnd => { machine: machine, value: Text(Str.concat(text, pad)) }
					}
				}
			}
			_ => ValueRules.fault_got(
				machine,
				"unsupported: `padStart` or `padEnd` other than to a whole length with ASCII text${ValueRules.line_note(site)}",
			)
		}
	}

	# ---- the builtins --------------------------------------------------------

	## The builtins of `library`, made in `cells`: the cells after, and each
	## builtin's value in the order `Resolve` places them
	## (`Ast.global_names_of`), which the VM's outermost frame holds.
	globals : List(Heap.Cell), Ast.Library -> { cells : List(Heap.Cell), values : List(Heap.Value) }
	globals = |cells, library| {
		var $s = { cells: cells, free: NoneFree, status: Running }
		log = ValueRules.alloc($s, Builtin(Log, []))
		$s = log.machine
		console = ValueRules.alloc($s, Namespace("console", [{ key: "log", value: log.value }]))
		$s = console.machine
		var $math_properties = [
			{ key: "PI", value: Number(3.141592653589793) },
			{ key: "E", value: Number(2.718281828459045) },
		]
		for native in [
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
		] {
			made = ValueRules.alloc($s, Builtin(native, []))
			$s = made.machine
			$math_properties = $math_properties.append({
				key: Heap.native_name(native),
				value: made.value,
			})
		}
		math_object = ValueRules.alloc($s, Namespace("Math", $math_properties))
		$s = math_object.machine
		var $object_properties = []
		for native in [Keys, Values, Entries] {
			made = ValueRules.alloc($s, Builtin(native, []))
			$s = made.machine
			$object_properties = $object_properties.append({
				key: Heap.native_name(native),
				value: made.value,
			})
		}
		object = ValueRules.alloc($s, Namespace("Object", $object_properties))
		$s = object.machine
		from_char_code = ValueRules.alloc($s, Builtin(FromCharCode, []))
		$s = from_char_code.machine
		string = ValueRules.alloc(
			$s,
			Builtin(StringOf, [{ key: "fromCharCode", value: from_char_code.value }]),
		)
		$s = string.machine
		var $array_properties = []
		for native in [IsArray, ArrayFrom, ArrayOf] {
			made = ValueRules.alloc($s, Builtin(native, []))
			$s = made.machine
			$array_properties = $array_properties.append({
				key: Heap.native_name(native),
				value: made.value,
			})
		}
		array = ValueRules.alloc($s, Namespace("Array", $array_properties))
		$s = array.machine
		is_integer = ValueRules.alloc($s, Builtin(IsInteger, []))
		$s = is_integer.machine
		number = ValueRules.alloc(
			$s,
			Namespace(
				"Number",
				[
					{ key: "isInteger", value: is_integer.value },
					{ key: "MAX_SAFE_INTEGER", value: Number(9007199254740991.0) },
				],
			),
		)
		$s = number.machine
		var $made = [
			{ name: "console", value: console.value },
			{ name: "Math", value: math_object.value },
			{ name: "Object", value: object.value },
			{ name: "String", value: string.value },
			{ name: "Array", value: array.value },
			{ name: "Number", value: number.value },
			{ name: "NaN", value: Number(0.0 / 0.0) },
			{ name: "Infinity", value: Number(1.0 / 0.0) },
		]
		for native in [
			Timing(SetTimeout),
			Timing(SetInterval),
			Timing(ClearTimeout),
			Timing(ClearInterval),
		] {
			timer_builtin = ValueRules.alloc($s, Builtin(native, []))
			$s = timer_builtin.machine
			$made = $made.append({ name: Heap.native_name(native), value: timer_builtin.value })
		}
		for name in [Error, TypeError, RangeError, ReferenceError, SyntaxError] {
			maker = ValueRules.alloc($s, Builtin(MakeError(name), []))
			$s = maker.machine
			$made = $made.append({ name: Heap.error_name_text(name), value: maker.value })
		}
		for native in [MakeMap, MakeSet] {
			maker = ValueRules.alloc($s, Builtin(native, []))
			$s = maker.machine
			$made = $made.append({ name: Heap.native_name(native), value: maker.value })
		}
		match library {
			Core => {}
			Canvas => {
				for native in ValueRules.canvas_natives {
					canvas_builtin = ValueRules.alloc($s, Builtin(native, []))
					$s = canvas_builtin.machine
					$made = $made.append({
						name: Heap.native_name(native),
						value: canvas_builtin.value,
					})
				}
			}
		}
		made = $made
		values = Ast.global_names_of(library).map(
			|name| (made.find_first(|g| g.name == name) ?? crash "ValueRules.globals: a builtin Ast.global_names_of names").value,
		)
		{ cells: $s.cells, values: values }
	}

	# The canvas library's builtins.
	canvas_natives : List(Heap.Native)
	canvas_natives = [
		Paint(Background),
		Paint(Fill),
		Paint(NoFill),
		Paint(Stroke),
		Paint(NoStroke),
		Paint(Line),
		Paint(Rect),
		Paint(Circle),
		Paint(Ellipse),
		Paint(Polygon),
		Paint(Words),
		Move(Forward),
		Move(Back),
		Move(Turn),
		Move(PenUp),
		Move(PenDown),
		Move(Goto),
		Sense(MouseX),
		Sense(MouseY),
		Sense(KeyIsDown),
		OnClick,
	]
}
