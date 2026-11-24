## This module runs a compiled JavaScript program (`Bytecode`) on a stack
## machine: one loop reads an instruction and hands the machine to that
## instruction's handler, which gives it back.
##
## **EVERY VALUE THE PROGRAM HOLDS IS IN THE MACHINE.** A call's frame is a
## run of slots on the operand stack (`stack`, its live part the first
## `top` places), the values being worked on sit above it, and the callers'
## frames wait in `frames`. A captured variable's box and a closure's
## environment are heap cells. So what a collector would start from is data:
## the live stack, the frames and the heap's cells.
##
## **THE LOOP ONLY DISPATCHES.** `run!` fetches the next instruction and
## calls `dispatch!`, whose match calls one top-level handler an arm, so no
## single function grows with the language. A handler answers the machine
## and nothing else; a value it makes goes on the stack.
##
## **A PLACE THE STACK GIVES UP IS CLEARED.** The stack never shrinks: a pop
## lowers `top` and writes `Null` where the value was, and a push past the
## end appends. A value left above `top` would be a second reference to a
## string or a list, and the next write to it in place would copy it.
##
## **A CALL OF A BUILTIN THAT CALLS BACK RUNS THE LOOP AGAIN.** `forEach`,
## `map`, `sort` and their kin call a function for each item: the call
## pushes the function and its arguments, enters its frame and runs the loop
## until that frame returns (`call_function!`), then reads its answer off the
## stack. While it runs, the method's receiver and arguments wait on the
## stack beneath it, and the array `map` or `filter` builds is a cell the
## stack refers to.
##
## **THE VM BORROWS THE WALKER'S PURE RULES.** What JavaScript gives for a
## property read, an operator on mixed values, a string method, a builtin
## that calls nothing back, and every message those make, lives once, in
## `Interp`. Where the VM's own fast path doesn't settle an instruction (two
## numbers added, an object's own property read), it hands the cells to that
## rule inside a walker machine that holds nothing else (`shell`), and takes
## the cells, the value and any fault or throw back (`with_got`). None of
## those rules walks the tree or calls a function: the VM never falls back
## on the walker to run the program.
##
## **THE HANDLERS TAKE SEVERAL ARGUMENTS, A NAMED EXCEPTION.** As the
## walker's evaluator does, a handler takes the host, then the program, then
## the machine, then the rest, where the style guide would take one record:
## a record holding the machine is a second reference to the heap.
##
## What the VM doesn't run yet (exceptions caught, timers, the canvas, Map
## and Set methods, `for ... of` over anything but an array or a string)
## stops the run with `unsupported (vm): ...`. A throw nothing can catch yet
## ends the run as an uncaught one, as node ends it.
import Ast
import Bytecode
import Canvas
import Heap
import Inspect
import Interp

Vm :: [].{
	Machine : {
		cells : List(Heap.Cell),
		stack : List(Heap.Value),
		top : U64,
		frames : List(Vm.Frame),
		# How many of `frames` are callers waiting: the ones past it are spent.
		depth : U64,
		code : U64,
		pc : U64,
		base : U64,
		builtins : List(Heap.Value),
		status : Vm.Status,
		steps : U64,
		step_limit : U64,
		effects : U64,
		effect_limit : U64,
	}

	## A caller's place, kept while its callee runs: its code, the
	## instruction after the call, its frame's base, and where on the stack
	## the callee's answer goes, the place of the function called (or of its
	## receiver, for a method).
	Frame : { code : U64, pc : U64, base : U64, result_at : U64 }

	Status : [Running, Finished, Faulted(Str), Thrown(Box(Interp.Throw))]

	## How a run ended: at its end, stopped by a fault, or by a throw nothing
	## caught, written as the line node prints first.
	Ending : [Finished, Faulted(Str), Uncaught(Str)]

	## A program run to its end, its effects handed to `host` as it runs.
	run! : Canvas.Host, Bytecode.Program, Interp.Limits => Vm.Ending
	run! = |host, program, limits| {
		walker = Interp.fresh(Core, limits)
		globals = walker.scopes.first() ?? crash "Vm.run!: Interp.fresh makes the builtins' scope"
		begun = {
			cells: walker.cells,
			stack: [],
			top: 0,
			frames: [],
			depth: 0,
			code: program.main,
			pc: 0,
			base: 0,
			builtins: globals.variables.map(|variable| variable.value),
			status: Running,
			steps: 0,
			step_limit: limits.steps,
			effects: 0,
			effect_limit: limits.effects,
		}
		main = code_of(program, program.main)
		entered = frame_filled(begun, { code: main, given: 0, boxes: [] })
		ended = loop!(host, program, entered, 0)
		match ended.status {
			Running | Finished => Finished
			Faulted(why) => Faulted(why)
			Thrown(boxed) => {
				{ value, site } = Box.unbox(boxed)
				match Interp.uncaught_ending(ended.cells, value, site) {
					Uncaught(line) => Uncaught(line)
					Faulted(why) => Faulted(why)
					Running => crash "Vm.run!: Interp.uncaught_ending answers how a throw ends the run"
				}
			}
		}
	}
}

# ---- the loop --------------------------------------------------------------

# The machine run on until it stops, or until fewer than `floor` callers
# wait: a callback's run ends when the frame it entered returns.
loop! : Canvas.Host, Bytecode.Program, Vm.Machine, U64 => Vm.Machine
loop! = |host, program, machine, floor| {
	var $machine = machine
	var $code = machine.code
	var $ops = code_of(program, $code).ops
	while is_running($machine) and $machine.depth >= floor {
		if $machine.code != $code {
			$code = $machine.code
			$ops = code_of(program, $code).ops
		}
		op = $ops.get($machine.pc) ?? crash "Vm.loop!: every code ends in a return or a finish"
		$machine = dispatch!(host, program, { ..$machine, pc: $machine.pc + 1 }, op)
	}
	$machine
}

dispatch! : Canvas.Host, Bytecode.Program, Vm.Machine, Bytecode.Op => Vm.Machine
dispatch! = |host, program, machine, op|
	match op {
		PushNumber(number) => pushed(machine, Number(number))
		PushText(text) => pushed(machine, Text(text))
		PushBoolean(truth) => pushed(machine, Boolean(truth))
		PushNull => pushed(machine, Null)
		PushUndefined => pushed(machine, Undefined)
		Pop => dropped(machine, 1)
		Duplicate => pushed(machine, value_at(machine, 1))
		DuplicatePair => duplicated_pair(machine)
		Nip => nipped(machine)
		LoadLocal(slot) => pushed(machine, slot_value(machine, slot))
		StoreLocal(slot) => with_slot(machine, slot, value_at(machine, 1))
		SetLocal(slot) => local_set(machine, slot)
		LoadBoxed(named) => boxed_loaded(machine, named)
		PeekBoxed(slot) => boxed_peeked(machine, slot)
		StoreBoxed(assigned) => boxed_stored(machine, assigned)
		SetBoxed(slot) => boxed_set(machine, slot)
		NewBox(slot) => box_made(machine, slot)
		CopyBox(slot) => box_copied(machine, slot)
		LoadBuiltin(index) => pushed(machine, machine.builtins.get(index) ?? crash "Vm.dispatch!: Resolve places a builtin the library has")
		MissingName({ name, at }) => missing_name(machine, name, at)
		ThrowUnready({ name, at }) => with_error(machine, ReferenceError, Interp.unready_message(name), at)
		ThrowConstant(at) => with_error(machine, TypeError, "Assignment to constant variable.", at)
		Refuse(why) => with_fault(machine, why)
		AppendLocal({ slot, at }) => local_appended(machine, slot, at)
		UpdateLocal({ slot, step }) => local_updated(machine, slot, step)
		UpdateBoxed(boxed) => boxed_updated(machine, boxed)
		UpdateFixed(at) => fixed_updated(machine, at)
		UpdateProperty({ key, step }) => property_updated(machine, key, step)
		UpdateIndex(step) => index_updated(machine, step)
		Unary(operator, at) => unary(machine, operator, at)
		Binary(operator, at) => binary(machine, operator, at)
		TemplatePart(piece) => template_joined(machine, piece)
		Jump(count) => { ..machine, pc: machine.pc + count }
		Loop(count) => stepped({ ..machine, pc: machine.pc - count })
		JumpIfFalse(count) => jumped_if_false(machine, count)
		SkipIfFalsy(count) => skipped_if(machine, count, Falsy)
		SkipIfTruthy(count) => skipped_if(machine, count, Truthy)
		SkipIfDefined(count) => skipped_if(machine, count, Defined)
		MakeArray(count) => array_made(machine, count)
		NewArray => allocated(machine, Array([]))
		AppendItem => item_appended(machine)
		AppendSpread({ source, at }) => spread_appended(machine, source, at)
		NewObject => allocated(machine, Object([]))
		SetField(key) => field_set(machine, key)
		SpreadFields(at) => fields_spread(machine, at)
		GetProperty(key, at) => property_read(machine, key, at)
		GetIndex(at) => index_read(machine, at)
		SetProperty(key, at) => property_written(machine, key, at)
		SetIndex(at) => index_written(machine, at)
		MakeClosure(made) => closure_made(machine, made)
		Call(site) => plain_called!(host, program, machine, site)
		CallSpread({ written, at }) => spread_called!(host, program, machine, { written: written, at: at })
		MethodLookup(name, at) => method_looked_up(machine, name, at)
		CallMethod({ name, site }) => method_called!(host, program, machine, { name: name, site: site })
		CallMethodSpread({ name, written, at }) => spread_method_called!(host, program, machine, { name: name, written: written, at: at })
		Construct({ count, callee, at }) => constructed(machine, { count: count, callee: callee, at: at })
		IterStart({ source, at }) => iteration_started(machine, source, at)
		IterNext({ slot, exit }) => iterated(machine, slot, exit)
		Return => returned(machine)
		Throw(at) => thrown(machine, at)
		Finish => { ..machine, status: Finished }
	}

code_of : Bytecode.Program, U64 -> Bytecode.Code
code_of = |program, code| program.codes.get(code) ?? crash "Vm.code_of: a closure names code the program has"

is_running : Vm.Machine -> Bool
is_running = |machine| match machine.status {
	Running => True
	_ => False
}

with_fault : Vm.Machine, Str -> Vm.Machine
with_fault = |machine, why| match machine.status {
	Running => { ..machine, status: Faulted(why) }
	_ => machine
}

unsupported : Vm.Machine, Str, Ast.Where -> Vm.Machine
unsupported = |machine, what, at| with_fault(machine, "unsupported (vm): ${what}${Interp.line_note(at)}")

# The machine unwinding with one of JavaScript's own errors, which nothing
# catches yet.
with_error : Vm.Machine, Heap.ErrorName, Str, Ast.Where -> Vm.Machine
with_error = |machine, name, message, at| {
	id = machine.cells.len()
	{
		..machine,
		cells: machine.cells.append(Failure(name, message)),
		status: Thrown(Box.box({ value: Reference(id), site: at })),
	}
}

# One more step counted, a call or a loop's pass, stopped past the budget.
stepped : Vm.Machine -> Vm.Machine
stepped = |machine|
	if machine.steps >= machine.step_limit {
		with_fault(machine, "the program ran past its budget of ${machine.step_limit.to_str()} steps")
	} else {
		{ ..machine, steps: machine.steps + 1 }
	}

# ---- the stack -------------------------------------------------------------

pushed : Vm.Machine, Heap.Value -> Vm.Machine
pushed = |machine, value|
	if machine.top < machine.stack.len() {
		{
			..machine,
			stack: machine.stack.set(machine.top, value) ?? crash "Vm.pushed: below the stack's end",
			top: machine.top + 1,
		}
	} else {
		{ ..machine, stack: machine.stack.append(value), top: machine.top + 1 }
	}

# The value `depth` places down from the top: 1 is the top.
value_at : Vm.Machine, U64 -> Heap.Value
value_at = |machine, depth| machine.stack.get(machine.top - depth) ?? crash "Vm.value_at: the compiler pushes what an instruction takes"

# The machine with its top `count` values given up, their places cleared.
dropped : Vm.Machine, U64 -> Vm.Machine
dropped = |machine, count| {
	var $stack = machine.stack
	var $at = machine.top - count
	while $at < machine.top {
		$stack = $stack.set($at, Null) ?? crash "Vm.dropped: below the stack's end"
		$at = $at + 1
	}
	{ ..machine, stack: $stack, top: machine.top - count }
}

# The machine with everything from `place` up given up, and `value` there:
# a call's answer in the place of the function called, a handler's in the
# place of what it took.
with_result : Vm.Machine, U64, Heap.Value -> Vm.Machine
with_result = |machine, place, value| {
	cleared = dropped(machine, machine.top - place)
	pushed(cleared, value)
}

# The top `count` values replaced by `value`.
replaced : Vm.Machine, U64, Heap.Value -> Vm.Machine
replaced = |machine, count, value| with_result(machine, machine.top - count, value)

duplicated_pair : Vm.Machine -> Vm.Machine
duplicated_pair = |machine| {
	under = value_at(machine, 2)
	over = value_at(machine, 1)
	pushed(pushed(machine, under), over)
}

nipped : Vm.Machine -> Vm.Machine
nipped = |machine| replaced(machine, 2, value_at(machine, 1))

slot_value : Vm.Machine, U64 -> Heap.Value
slot_value = |machine, slot| machine.stack.get(machine.base + slot) ?? crash "Vm.slot_value: a slot of the frame"

with_slot : Vm.Machine, U64, Heap.Value -> Vm.Machine
with_slot = |machine, slot, value| {
	..machine,
	stack: machine.stack.set(machine.base + slot, value) ?? crash "Vm.with_slot: a slot of the frame",
}

local_set : Vm.Machine, U64 -> Vm.Machine
local_set = |machine, slot| dropped(with_slot(machine, slot, value_at(machine, 1)), 1)

# The arguments of a call, the top `count` values, as a list of their own:
# a sublist would share the stack's memory, and the stack's next write in
# place would copy it.
arguments_of : Vm.Machine, U64 -> List(Heap.Value)
arguments_of = |machine, count| {
	var $values = List.with_capacity(count)
	var $at = machine.top - count
	while $at < machine.top {
		$values = $values.append(machine.stack.get($at) ?? crash "Vm.arguments_of: below the stack's end")
		$at = $at + 1
	}
	$values
}

allocated : Vm.Machine, Heap.Cell -> Vm.Machine
allocated = |machine, cell| {
	id = machine.cells.len()
	pushed({ ..machine, cells: machine.cells.append(cell) }, Reference(id))
}

# ---- boxes -----------------------------------------------------------------

box_of : Vm.Machine, U64 -> U64
box_of = |machine, slot| match slot_value(machine, slot) {
	Reference(id) => id
	_ => crash "Vm.box_of: the compiler names a boxed variable's slot, which holds its box"
}

# The value in a box, or the box unready.
box_content : Vm.Machine, U64 -> [Holding(Heap.Value), Unready]
box_content = |machine, box| match Heap.cell_at(machine.cells, box) {
	Variable(value) => Holding(value)
	UnreadyVariable => Unready
	_ => crash "Vm.box_content: a boxed slot holds a box"
}

with_box : Vm.Machine, U64, Heap.Value -> Vm.Machine
with_box = |machine, box, value| {
	..machine,
	cells: machine.cells.set(box, Variable(value)) ?? crash "Vm.with_box: a box the heap has",
}

boxed_loaded : Vm.Machine, Bytecode.Named -> Vm.Machine
boxed_loaded = |machine, { slot, name, at }|
	match box_content(machine, box_of(machine, slot)) {
		Holding(value) => pushed(machine, value)
		Unready => with_error(machine, ReferenceError, Interp.unready_message(name), at)
	}

boxed_peeked : Vm.Machine, U64 -> Vm.Machine
boxed_peeked = |machine, slot|
	match box_content(machine, box_of(machine, slot)) {
		Holding(value) => pushed(machine, value)
		Unready => pushed(machine, Undefined)
	}

boxed_stored : Vm.Machine, Bytecode.Assigned -> Vm.Machine
boxed_stored = |machine, { slot, name, kind, at }| {
	box = box_of(machine, slot)
	match (box_content(machine, box), kind) {
		(Unready, _) => with_error(machine, ReferenceError, Interp.unready_message(name), at)
		(Holding(_), Fixed) => with_error(machine, TypeError, "Assignment to constant variable.", at)
		(Holding(_), Mutable) => with_box(machine, box, value_at(machine, 1))
	}
}

boxed_set : Vm.Machine, U64 -> Vm.Machine
boxed_set = |machine, slot| dropped(with_box(machine, box_of(machine, slot), value_at(machine, 1)), 1)

box_made : Vm.Machine, U64 -> Vm.Machine
box_made = |machine, slot| {
	id = machine.cells.len()
	with_slot({ ..machine, cells: machine.cells.append(UnreadyVariable) }, slot, Reference(id))
}

box_copied : Vm.Machine, U64 -> Vm.Machine
box_copied = |machine, slot| {
	cell = match box_content(machine, box_of(machine, slot)) {
		Holding(value) => Variable(value)
		Unready => UnreadyVariable
	}
	id = machine.cells.len()
	with_slot({ ..machine, cells: machine.cells.append(cell) }, slot, Reference(id))
}

# ---- the walker's rules, borrowed ------------------------------------------

# A walker machine holding `cells` and nothing else, for one of `Interp`'s
# rules that reads or writes the heap and may fault or throw.
shell : List(Heap.Cell) -> Interp.Machine
shell = |cells| {
	cells: cells,
	scopes: [],
	live_scopes: 0,
	scope: 0,
	steps: 0,
	step_limit: 0,
	effects: 0,
	effect_limit: 0,
	budgeted: "",
	turtle: Canvas.turtle_start,
	depth: 0,
	status: Running,
	events: {
		clock: 0.0,
		pending_events: [],
		made: 0,
		firing: Idle,
		on_click: NoHandler,
	},
}

# The machine without its cells, which a borrowed rule takes: kept apart,
# the cells have one owner while the rule writes them.
Lent : { cells : List(Heap.Cell), machine : Vm.Machine }

lent : Vm.Machine -> Lent
lent = |machine| {
	cells = machine.cells
	{ cells: cells, machine: { ..machine, cells: [] } }
}

# The machine after a borrowed rule: its cells back, and its value in
# `place` on the stack, or its fault or throw taken on.
with_got : Vm.Machine, Interp.Got, U64 -> Vm.Machine
with_got = |machine, got, place| {
	{ machine: walker, value } = got
	match walker.status {
		Running => with_result({ ..machine, cells: walker.cells }, place, value)
		Faulted(why) => { ..machine, cells: walker.cells, status: Faulted(why) }
		Thrown(boxed) => { ..machine, cells: walker.cells, status: Thrown(boxed) }
	}
}

missing_name : Vm.Machine, Str, Ast.Where -> Vm.Machine
missing_name = |machine, name, at| {
	{ cells, machine: rest } = lent(machine)
	with_got(rest, Interp.missing_name_got(shell(cells), name, at), rest.top)
}

# ---- operators -------------------------------------------------------------

unary : Vm.Machine, Ast.UnaryOperator, Ast.Where -> Vm.Machine
unary = |machine, operator, at| {
	operand = value_at(machine, 1)
	match (operator, operand) {
		(Not, _) => replaced(machine, 1, Boolean(!Interp.is_truthy(operand)))
		(TypeOf, _) => replaced(machine, 1, Text(Interp.type_of(machine.cells, operand)))
		(Negate, Number(number)) => replaced(machine, 1, Number(-number))
		(Plus, Number(number)) => replaced(machine, 1, Number(number))
		_ => {
			{ cells, machine: rest } = lent(machine)
			with_got(rest, Interp.unary(shell(cells), operator, operand, at), rest.top - 1)
		}
	}
}

binary : Vm.Machine, Ast.BinaryOperator, Ast.Where -> Vm.Machine
binary = |machine, operator, at| {
	right = value_at(machine, 1)
	left = value_at(machine, 2)
	match (left, right) {
		(Number(x), Number(y)) => replaced(machine, 2, Interp.arithmetic(operator, x, y))
		_ => combined(machine, { operator: operator, left: left, right: right, at: at })
	}
}

# Two values that aren't both numbers, combined as the walker combines them,
# in place of the top two.
combined : Vm.Machine, { operator : Ast.BinaryOperator, left : Heap.Value, right : Heap.Value, at : Ast.Where } -> Vm.Machine
combined = |machine, { operator, left, right, at }|
	match operator {
		StrictEqual => replaced(machine, 2, Boolean(Interp.is_strictly_equal(left, right)))
		StrictNotEqual => replaced(machine, 2, Boolean(!Interp.is_strictly_equal(left, right)))
		_ => {
			{ cells, machine: rest } = lent(machine)
			with_got(rest, Interp.binary(shell(cells), operator, left, right, at), rest.top - 2)
		}
	}

template_joined : Vm.Machine, Str -> Vm.Machine
template_joined = |machine, piece| {
	part = value_at(machine, 1)
	match Interp.text_of(machine.cells, part) {
		Ok(phrase) => {
			taken = machine.stack.replace(machine.top - 2, Null) ?? crash "Vm.template_joined: a template's text so far is on the stack"
			so_far = match taken.prev {
				Text(text) => text
				_ => crash "Vm.template_joined: a template's text so far is text"
			}
			grown = { ..machine, stack: taken.list }
			replaced(grown, 2, Text(Str.concat(Str.concat(so_far, phrase), piece)))
		}
		# The walker's message, which names no line here.
		Err(Unsupported(why)) => with_fault(machine, why)
	}
}

jumped_if_false : Vm.Machine, U64 -> Vm.Machine
jumped_if_false = |machine, count| {
	test = value_at(machine, 1)
	popped = dropped(machine, 1)
	if Interp.is_truthy(test) {
		popped
	} else {
		{ ..popped, pc: popped.pc + count }
	}
}

skipped_if : Vm.Machine, U64, [Falsy, Truthy, Defined] -> Vm.Machine
skipped_if = |machine, count, settles| {
	subject = value_at(machine, 1)
	settled = match settles {
		Falsy => !Interp.is_truthy(subject)
		Truthy => Interp.is_truthy(subject)
		Defined => !Interp.is_nullish(subject)
	}
	if settled {
		{ ..machine, pc: machine.pc + count }
	} else {
		dropped(machine, 1)
	}
}

# ---- assignments and updates -----------------------------------------------

# `s += e`: the string grown where the slot holds it, while nothing else
# refers to it, so building a string a piece at a time copies no piece.
local_appended : Vm.Machine, U64, Ast.Where -> Vm.Machine
local_appended = |machine, slot, at| {
	piece = value_at(machine, 1)
	match slot_value(machine, slot) {
		Text(_) => match Interp.text_of(machine.cells, piece) {
			Ok(tail) => {
				taken = machine.stack.replace(machine.base + slot, Null) ?? crash "Vm.local_appended: a slot of the frame"
				grown = match taken.prev {
					Text(text) => Str.concat(text, tail)
					_ => crash "Vm.local_appended: the slot held text a moment ago"
				}
				written = { ..machine, stack: taken.list.set(machine.base + slot, Text(grown)) ?? crash "Vm.local_appended: a slot of the frame" }
				replaced(written, 1, slot_value(written, slot))
			}
			Err(Unsupported(why)) => with_fault(machine, "${why}${Interp.line_note(at)}")
		}
		old => {
			added = binary(pushed(replaced(machine, 1, old), piece), Add, at)
			if is_running(added) {
				with_slot(added, slot, value_at(added, 1))
			} else {
				added
			}
		}
	}
}

# What `++` or `--` answers: the new value before, the old after.
update_answer : Bytecode.Update, F64 -> Heap.Value
update_answer = |{ delta, fixity, at: _ }, old| match fixity {
	Prefix => Number(old + delta)
	Postfix => Number(old)
}

not_a_number_update : Vm.Machine, Heap.Value, Ast.Where -> Vm.Machine
not_a_number_update = |machine, current, at| with_fault(machine, "unsupported: `++` or `--` on a ${Interp.type_of(machine.cells, current)}${Interp.line_note(at)}")

local_updated : Vm.Machine, U64, Bytecode.Update -> Vm.Machine
local_updated = |machine, slot, step|
	match slot_value(machine, slot) {
		Number(old) => pushed(with_slot(machine, slot, Number(old + step.delta)), update_answer(step, old))
		current => not_a_number_update(machine, current, step.at)
	}

boxed_updated : Vm.Machine, { slot : U64, name : Str, kind : Bytecode.Kind, step : Bytecode.Update } -> Vm.Machine
boxed_updated = |machine, { slot, name, kind, step }| {
	box = box_of(machine, slot)
	match box_content(machine, box) {
		Unready => with_error(machine, ReferenceError, Interp.unready_message(name), step.at)
		Holding(Number(old)) => match kind {
			Fixed => with_error(machine, TypeError, "Assignment to constant variable.", step.at)
			Mutable => pushed(with_box(machine, box, Number(old + step.delta)), update_answer(step, old))
		}
		Holding(current) => not_a_number_update(machine, current, step.at)
	}
}

fixed_updated : Vm.Machine, Ast.Where -> Vm.Machine
fixed_updated = |machine, at|
	match value_at(machine, 1) {
		Number(_) => with_error(machine, TypeError, "Assignment to constant variable.", at)
		current => not_a_number_update(machine, current, at)
	}

property_updated : Vm.Machine, Str, Bytecode.Update -> Vm.Machine
property_updated = |machine, key, step| {
	holder = value_at(machine, 1)
	read = property_read(machine, key, step.at)
	if !is_running(read) {
		read
	} else {
		match value_at(read, 1) {
			Number(old) => {
				back = pushed(dropped(read, 1), holder)
				written = stored(pushed(back, Number(old + step.delta)), { key: Text(key), at: step.at })
				if is_running(written) {
					replaced(written, 1, update_answer(step, old))
				} else {
					written
				}
			}
			current => not_a_number_update(read, current, step.at)
		}
	}
}

index_updated : Vm.Machine, Bytecode.Update -> Vm.Machine
index_updated = |machine, step| {
	holder = value_at(machine, 2)
	key = value_at(machine, 1)
	read = index_read(pushed(pushed(machine, holder), key), step.at)
	if !is_running(read) {
		read
	} else {
		match value_at(read, 1) {
			Number(old) => {
				written = index_written(replaced(read, 1, Number(old + step.delta)), step.at)
				if is_running(written) {
					replaced(written, 1, update_answer(step, old))
				} else {
					written
				}
			}
			current => not_a_number_update(read, current, step.at)
		}
	}
}

# ---- arrays and objects ----------------------------------------------------

array_made : Vm.Machine, U64 -> Vm.Machine
array_made = |machine, count| {
	items = arguments_of(machine, count)
	id = machine.cells.len()
	replaced({ ..machine, cells: machine.cells.append(Array(items)) }, count, Reference(id))
}

reference_id : Heap.Value -> U64
reference_id = |value| match value {
	Reference(id) => id
	_ => crash "Vm.reference_id: the compiler puts the array or object being built beneath its parts"
}

item_appended : Vm.Machine -> Vm.Machine
item_appended = |machine| {
	id = reference_id(value_at(machine, 2))
	item = value_at(machine, 1)
	dropped({ ..machine, cells: Heap.with_items_pushed(machine.cells, id, [item]) }, 1)
}

spread_appended : Vm.Machine, Ast.Expression, Ast.Where -> Vm.Machine
spread_appended = |machine, source, at| {
	id = reference_id(value_at(machine, 2))
	given = value_at(machine, 1)
	{ cells, machine: rest } = lent(machine)
	{ machine: walker, values } = Interp.iterated(shell(cells), given)
	match values {
		Ok(items) => dropped({ ..rest, cells: Heap.with_items_pushed(walker.cells, id, items) }, 1)
		Err(NotIterable) => {
			failed = Interp.with_not_iterable(walker, given, Written(source), at)
			with_got(rest, { machine: failed, value: Undefined }, rest.top - 1)
		}
	}
}

field_set : Vm.Machine, Str -> Vm.Machine
field_set = |machine, key| {
	id = reference_id(value_at(machine, 2))
	value = value_at(machine, 1)
	dropped({ ..machine, cells: Heap.with_property(machine.cells, id, key, value) }, 1)
}

fields_spread : Vm.Machine, Ast.Where -> Vm.Machine
fields_spread = |machine, at| {
	id = reference_id(value_at(machine, 2))
	given = value_at(machine, 1)
	match Interp.spread_properties(machine.cells, given) {
		Ok(properties) => {
			var $cells = machine.cells
			for property in properties {
				$cells = Heap.with_property($cells, id, property.key, property.value)
			}
			dropped({ ..machine, cells: $cells }, 1)
		}
		Err(Unsupported(why)) => with_fault(machine, "${why}${Interp.line_note(at)}")
	}
}

# An object's own property, a builtin object's, or an array's length, read
# here; everything else as the walker reads it.
property_read : Vm.Machine, Str, Ast.Where -> Vm.Machine
property_read = |machine, key, at| {
	holder = value_at(machine, 1)
	found = match holder {
		Reference(id) => match Heap.cell_at(machine.cells, id) {
			Object(properties) | Namespace(_, properties) => match properties.find_first(|property| property.key == key) {
				Ok(property) => Found(property.value)
				Err(NotFound) => Elsewhere
			}
			Array(items) if key == "length" => Found(Number(items.len().to_f64()))
			_ => Elsewhere
		}
		_ => Elsewhere
	}
	match found {
		Found(value) => replaced(machine, 1, value)
		Elsewhere => {
			{ cells, machine: rest } = lent(machine)
			with_got(rest, Interp.property(shell(cells), holder, key, at), rest.top - 1)
		}
	}
}

index_read : Vm.Machine, Ast.Where -> Vm.Machine
index_read = |machine, at| {
	holder = value_at(machine, 2)
	key = value_at(machine, 1)
	found = match (holder, Interp.index_of(key)) {
		(Reference(id), Ok(position)) => match Heap.cell_at(machine.cells, id) {
			Array(items) => Found(items.get(position) ?? Undefined)
			_ => Elsewhere
		}
		_ => Elsewhere
	}
	match found {
		Found(value) => replaced(machine, 2, value)
		Elsewhere => {
			{ cells, machine: rest } = lent(machine)
			with_got(rest, Interp.indexed_value(shell(cells), holder, key, at), rest.top - 2)
		}
	}
}

# The value on top stored at `key` of the holder beneath it, both replaced
# by the value: an object's property or an array's item written here,
# everything else as the walker writes it.
stored : Vm.Machine, { key : Heap.Value, at : Ast.Where } -> Vm.Machine
stored = |machine, { key, at }| {
	holder = value_at(machine, 2)
	value = value_at(machine, 1)
	place = match holder {
		Reference(id) => match Interp.kind_of(machine.cells, id) {
			ObjectKind => match key {
				Text(text) => Property(id, text)
				_ => Elsewhere
			}
			ArrayKind(length) => match Interp.index_of(key) {
				Ok(position) if position <= length => Item(id, position)
				_ => Elsewhere
			}
			_ => Elsewhere
		}
		_ => Elsewhere
	}
	match place {
		Property(id, text) => replaced({ ..machine, cells: Heap.with_property(machine.cells, id, text, value) }, 2, value)
		Item(id, position) => replaced({ ..machine, cells: Heap.with_item(machine.cells, id, position, value) }, 2, value)
		Elsewhere => {
			{ cells, machine: rest } = lent(machine)
			with_got(rest, Interp.with_stored(shell(cells), holder, key, value, at), rest.top - 2)
		}
	}
}

property_written : Vm.Machine, Str, Ast.Where -> Vm.Machine
property_written = |machine, key, at| stored(machine, { key: Text(key), at: at })

index_written : Vm.Machine, Ast.Where -> Vm.Machine
index_written = |machine, at| {
	key = value_at(machine, 2)
	value = value_at(machine, 1)
	# holder, key, value -> holder, value: the store takes the key apart.
	stored(pushed(dropped(machine, 2), value), { key: key, at: at })
}

# ---- closures and calls ----------------------------------------------------

closure_made : Vm.Machine, { code : U64, captures : List(U64), definition : Box(Ast.FunctionDefinition) } -> Vm.Machine
closure_made = |machine, { code, captures, definition }| {
	boxes = captures.map(|slot| box_of(machine, slot))
	environment = machine.cells.len()
	cells = machine.cells.append(Environment({ code: code, boxes: boxes })).append(Fun({ fun: definition, scope: environment }))
	pushed({ ..machine, cells: cells }, Reference(environment + 1))
}

# How a call that finds no function names what it called: as the program
# wrote it (`o.f is not a function`), or, for a builtin's callback, by its
# value.
Naming : [Written(Str), Shown]

Calling : { count : U64, result_at : U64, naming : Naming, at : Ast.Where }

# The deepest call the VM makes before it throws a RangeError, the walker's.
max_depth : U64
max_depth = Interp.max_depth

# A call of the value beneath the top `count`: a closure's frame entered, a
# builtin's answer made, or a TypeError.
called! : Canvas.Host, Bytecode.Program, Vm.Machine, Calling => Vm.Machine
called! = |host, program, machine, calling| {
	callee = value_at(machine, calling.count + 1)
	target = match callee {
		Reference(id) => match Heap.cell_at(machine.cells, id) {
			Fun(closure) => Closure(closure.scope)
			Builtin(native, _) => Native(native)
			_ => NoFunction
		}
		_ => NoFunction
	}
	match target {
		Closure(environment) => closure_entered(program, machine, { environment: environment, calling: calling })
		Native(native) => native_called!(host, program, machine, { native: native, calling: calling })
		NoFunction => {
			shown = match calling.naming {
				Written(written) => written
				Shown => Interp.shown_value(machine.cells, callee)
			}
			with_error(machine, TypeError, "${shown} is not a function", calling.at)
		}
	}
}

plain_called! : Canvas.Host, Bytecode.Program, Vm.Machine, Bytecode.CallSite => Vm.Machine
plain_called! = |host, program, machine, site| {
	result_at = machine.top - site.count - 1
	called!(host, program, machine, { count: site.count, result_at: result_at, naming: Written(site.written), at: site.at })
}

closure_entered : Bytecode.Program, Vm.Machine, { environment : U64, calling : Calling } -> Vm.Machine
closure_entered = |program, machine, { environment, calling }| {
	{ code, boxes } = match Heap.cell_at(machine.cells, environment) {
		Environment(held) => held
		_ => crash "Vm.closure_entered: a VM closure's scope names its environment"
	}
	if machine.depth >= max_depth {
		with_error(machine, RangeError, "Maximum call stack size exceeded", calling.at)
	} else {
		counted = stepped(machine)
		caller = { code: counted.code, pc: counted.pc, base: counted.base, result_at: calling.result_at }
		depth = counted.depth
		base = counted.top - calling.count
		inside = {
			..counted,
			frames: frames_with(counted.frames, depth, caller),
			depth: depth + 1,
			code: code,
			pc: 0,
			base: base,
		}
		frame_filled(inside, { code: code_of(program, code), given: calling.count, boxes: boxes })
	}
}

frames_with : List(Vm.Frame), U64, Vm.Frame -> List(Vm.Frame)
frames_with = |frames, depth, caller|
	if depth < frames.len() {
		frames.set(depth, caller) ?? crash "Vm.frames_with: below the frames' end"
	} else {
		frames.append(caller)
	}

# The frame starting at `base`, `given` arguments on it, made ready to run:
# as many arguments as parameters, the rest of the slots undefined, then
# the boxes the code's entry makes.
frame_filled : Vm.Machine, { code : Bytecode.Code, given : U64, boxes : List(U64) } -> Vm.Machine
frame_filled = |machine, { code, given, boxes }| {
	var $machine = if given > code.parameters {
		dropped(machine, given - code.parameters)
	} else {
		machine
	}
	var $count = code.parameters.min(given)
	while $count < code.frame_size {
		$machine = pushed($machine, Undefined)
		$count = $count + 1
	}
	for entry in code.entry {
		$machine = match entry {
			FreshBox(slot) => box_made($machine, slot)
			FilledBox(slot) => {
				id = $machine.cells.len()
				value = slot_value($machine, slot)
				with_slot({ ..$machine, cells: $machine.cells.append(Variable(value)) }, slot, Reference(id))
			}
			CapturedBox({ slot, capture }) => with_slot(
				$machine,
				slot,
				Reference(boxes.get(capture) ?? crash "Vm.frame_filled: an environment holds every box its code captures"),
			)
		}
	}
	$machine
}

returned : Vm.Machine -> Vm.Machine
returned = |machine|
	if machine.depth == 0 {
		# A `return` outside every function ends the program, as node's
		# module wrapper ends it.
		{ ..machine, status: Finished }
	} else {
		value = value_at(machine, 1)
		caller = machine.frames.get(machine.depth - 1) ?? crash "Vm.returned: a caller waits"
		back = with_result(machine, caller.result_at, value)
		{ ..back, depth: back.depth - 1, code: caller.code, pc: caller.pc, base: caller.base }
	}

thrown : Vm.Machine, Ast.Where -> Vm.Machine
thrown = |machine, at| {
	value = value_at(machine, 1)
	{ ..machine, status: Thrown(Box.box({ value: value, site: at })) }
}

# The arguments built as one array, with their spreads, put on the stack
# in its place.
spread_unpacked : Vm.Machine -> { machine : Vm.Machine, count : U64 }
spread_unpacked = |machine| {
	items = match value_at(machine, 1) {
		Reference(id) => match Heap.cell_at(machine.cells, id) {
			Array(values) => values
			_ => crash "Vm.spread_unpacked: the compiler builds a call's spread arguments as an array"
		}
		_ => crash "Vm.spread_unpacked: the compiler builds a call's spread arguments as an array"
	}
	var $machine = dropped(machine, 1)
	for item in items {
		$machine = pushed($machine, item)
	}
	{ machine: $machine, count: items.len() }
}

spread_called! : Canvas.Host, Bytecode.Program, Vm.Machine, { written : Str, at : Ast.Where } => Vm.Machine
spread_called! = |host, program, machine, { written, at }| {
	{ machine: unpacked, count } = spread_unpacked(machine)
	called!(host, program, unpacked, { count: count, result_at: unpacked.top - count - 1, naming: Written(written), at: at })
}

spread_method_called! : Canvas.Host, Bytecode.Program, Vm.Machine, { name : Str, written : Str, at : Ast.Where } => Vm.Machine
spread_method_called! = |host, program, machine, { name, written, at }| {
	{ machine: unpacked, count } = spread_unpacked(machine)
	method_called!(host, program, unpacked, { name: name, site: { count: count, written: written, at: at } })
}

# What a method call calls, on the stack above its receiver.
method_looked_up : Vm.Machine, Str, Ast.Where -> Vm.Machine
method_looked_up = |machine, name, at| {
	receiver = value_at(machine, 1)
	by_name = match receiver {
		Reference(id) => match Interp.kind_of(machine.cells, id) {
			ArrayKind(_) | MapKind | SetKind => True
			_ => False
		}
		Text(_) => True
		_ => False
	}
	if by_name {
		pushed(machine, receiver)
	} else {
		property_read(pushed(machine, receiver), name, at)
	}
}

method_called! : Canvas.Host, Bytecode.Program, Vm.Machine, { name : Str, site : Bytecode.CallSite } => Vm.Machine
method_called! = |host, program, machine, { name, site }| {
	count = site.count
	result_at = machine.top - count - 2
	receiver = value_at(machine, count + 2)
	method = match receiver {
		Reference(id) => match Interp.kind_of(machine.cells, id) {
			ArrayKind(_) => ArrayMethod(id)
			MapKind | SetKind => CollectionMethod
			_ => Held
		}
		Text(text) => TextMethod(text)
		_ => Held
	}
	match method {
		ArrayMethod(id) => array_method!(host, program, machine, { id: id, name: name, count: count, result_at: result_at, at: site.at })
		TextMethod(text) => {
			arguments = arguments_of(machine, count)
			{ cells, machine: rest } = lent(machine)
			with_got(rest, Interp.text_method(shell(cells), text, name, arguments, site.at), result_at)
		}
		CollectionMethod => unsupported(machine, "Map and Set methods", site.at)
		Held => called!(host, program, machine, { count: count, result_at: result_at, naming: Written(site.written), at: site.at })
	}
}

constructed : Vm.Machine, { count : U64, callee : Ast.Expression, at : Ast.Where } -> Vm.Machine
constructed = |machine, { count, callee, at }| {
	maker = value_at(machine, count + 1)
	arguments = arguments_of(machine, count)
	{ cells, machine: rest } = lent(machine)
	with_got(rest, Interp.constructed(shell(cells), maker, callee, arguments, at), rest.top - count - 1)
}

# ---- builtins --------------------------------------------------------------

native_called! : Canvas.Host, Bytecode.Program, Vm.Machine, { native : Heap.Native, calling : Calling } => Vm.Machine
native_called! = |host, program, machine, { native, calling }| {
	arguments = arguments_of(machine, calling.count)
	at = calling.at
	match native {
		Log => match Inspect.line_of(machine.cells, arguments) {
			Ok(line) => {
				if machine.effects >= machine.effect_limit {
					with_fault(machine, "the program ran past its budget of ${machine.effect_limit.to_str()} effects")
				} else {
					emit! = host.emit!
					emit!(Log(line))
					with_result({ ..machine, effects: machine.effects + 1 }, calling.result_at, Undefined)
				}
			}
			Err(Unsupported(why)) => with_fault(machine, "${why}${Interp.line_note(at)}")
		}
		ArrayFrom if is_mapped(arguments) => array_from!(host, program, machine, { arguments: arguments, calling: calling })
		Timing(_) => unsupported(machine, "timers", at)
		OnClick | Paint(_) | Move(_) | Sense(_) => unsupported(machine, "the canvas", at)
		_ => {
			{ cells, machine: rest } = lent(machine)
			with_got(rest, Interp.call_native!(host, shell(cells), native, arguments, at), calling.result_at)
		}
	}
}

# Whether `Array.from` is given a mapper, which the VM calls back.
is_mapped : List(Heap.Value) -> Bool
is_mapped = |arguments| match arguments.get(1) {
	Ok(Undefined) | Err(OutOfBounds) => False
	Ok(_) => True
}

# A function called with `arguments`, by a builtin, its answer left on the
# stack: a closure's frame is entered and run until it returns.
call_function! : Canvas.Host, Bytecode.Program, Vm.Machine, { callee : Heap.Value, arguments : List(Heap.Value), at : Ast.Where } => Vm.Machine
call_function! = |host, program, machine, { callee, arguments, at }| {
	result_at = machine.top
	var $machine = pushed(machine, callee)
	for argument in arguments {
		$machine = pushed($machine, argument)
	}
	floor = $machine.depth + 1
	entered = called!(host, program, $machine, { count: arguments.len(), result_at: result_at, naming: Shown, at: at })
	if entered.depth >= floor {
		loop!(host, program, entered, floor)
	} else {
		entered
	}
}

# The answer `call_function!` left, taken off the stack.
Answered : { machine : Vm.Machine, value : Heap.Value }

answered : Vm.Machine -> Answered
answered = |machine| {
	value = value_at(machine, 1)
	{ machine: dropped(machine, 1), value: value }
}

array_from! : Canvas.Host, Bytecode.Program, Vm.Machine, { arguments : List(Heap.Value), calling : Calling } => Vm.Machine
array_from! = |host, program, machine, { arguments, calling }| {
	source = arguments.first() ?? Undefined
	mapper = arguments.get(1) ?? Undefined
	{ cells, machine: rest } = lent(machine)
	{ machine: walker, values: found } = Interp.iterated(shell(cells), source)
	back = { ..rest, cells: walker.cells }
	listed = match found {
		Ok(values) => Ok(values)
		Err(NotIterable) => Interp.array_like(back.cells, source)
	}
	match listed {
		Err(Unsupported(why)) => with_fault(back, "${why}${Interp.line_note(calling.at)}")
		Ok(values) => {
			out = back.cells.len()
			var $machine = pushed({ ..back, cells: back.cells.append(Array([])) }, Reference(out))
			var $i = 0
			for value in values {
				if is_running($machine) {
					{ machine: after, value: mapped } = answered(call_function!(host, program, $machine, { callee: mapper, arguments: [value, Number($i.to_f64())], at: calling.at }))
					$machine = if is_running(after) {
						{ ..after, cells: Heap.with_items_pushed(after.cells, out, [mapped]) }
					} else {
						after
					}
				}
				$i = $i + 1
			}
			if is_running($machine) {
				with_result($machine, calling.result_at, Reference(out))
			} else {
				$machine
			}
		}
	}
}

# ---- array methods ---------------------------------------------------------

ArrayCall : { id : U64, name : Str, count : U64, result_at : U64, at : Ast.Where }

item_count : Vm.Machine, U64 -> U64
item_count = |machine, id| match Interp.kind_of(machine.cells, id) {
	ArrayKind(length) => length
	_ => crash "Vm.item_count: asked only of an array"
}

item_at : Vm.Machine, U64, U64 -> Heap.Value
item_at = |machine, id, position| match Heap.cell_at(machine.cells, id) {
	Array(items) => items.get(position) ?? Undefined
	_ => crash "Vm.item_at: asked only of an array"
}

# An array's method: those that call a function back run here, the rest as
# the walker runs them.
array_method! : Canvas.Host, Bytecode.Program, Vm.Machine, ArrayCall => Vm.Machine
array_method! = |host, program, machine, call|
	match call.name {
		"forEach" => array_walk!(host, program, machine, call, ForEach)
		"map" => array_walk!(host, program, machine, call, Map)
		"filter" => array_walk!(host, program, machine, call, Filter)
		"some" => array_walk!(host, program, machine, call, Some)
		"every" => array_walk!(host, program, machine, call, Every)
		"find" => array_walk!(host, program, machine, call, Find)
		"findIndex" => array_walk!(host, program, machine, call, FindIndex)
		"flatMap" => array_walk!(host, program, machine, call, FlatMap)
		"findLast" => array_walk_back!(host, program, machine, call, FindLast)
		"findLastIndex" => array_walk_back!(host, program, machine, call, FindLastIndex)
		"reduce" => array_reduce!(host, program, machine, call, Forward)
		"reduceRight" => array_reduce!(host, program, machine, call, Backward)
		"sort" => array_sort!(host, program, machine, call)
		_ => {
			arguments = arguments_of(machine, call.count)
			{ cells, machine: rest } = lent(machine)
			with_got(rest, Interp.array_method!(host, shell(cells), call.id, call.name, arguments, call.at), call.result_at)
		}
	}

# A method's first argument, its callback.
callback_of : Vm.Machine, ArrayCall -> Heap.Value
callback_of = |machine, call|
	if call.count == 0 {
		Undefined
	} else {
		value_at(machine, call.count)
	}

Walk : [ForEach, Map, Filter, Some, Every, Find, FindIndex, FlatMap]

# An array method that calls a function on each item in turn, the items
# read from the heap as it goes, since the function may change the array.
array_walk! : Canvas.Host, Bytecode.Program, Vm.Machine, ArrayCall, Walk => Vm.Machine
array_walk! = |host, program, machine, call, walk| {
	callback = callback_of(machine, call)
	count = item_count(machine, call.id)
	builds = walk == Map or walk == Filter or walk == FlatMap
	out = machine.cells.len()
	var $machine = if builds {
		pushed({ ..machine, cells: machine.cells.append(Array([])) }, Reference(out))
	} else {
		machine
	}
	var $answer = match walk {
		Some => Boolean(False)
		Every => Boolean(True)
		FindIndex => Number(-1.0)
		_ => Undefined
	}
	var $i = 0
	var $going = True
	while $going and $i < count and $i < item_count($machine, call.id) {
		item = item_at($machine, call.id, $i)
		{ machine: after, value } = answered(call_function!(host, program, $machine, { callee: callback, arguments: [item, Number($i.to_f64()), Reference(call.id)], at: call.at }))
		$machine = after
		if !is_running($machine) {
			$going = False
		} else {
			match walk {
				ForEach => {}
				Map => {
					$machine = { ..$machine, cells: Heap.with_items_pushed($machine.cells, out, [value]) }
				}
				Filter => {
					if Interp.is_truthy(value) {
						$machine = { ..$machine, cells: Heap.with_items_pushed($machine.cells, out, [item]) }
					}
				}
				Some => {
					if Interp.is_truthy(value) {
						$answer = Boolean(True)
						$going = False
					}
				}
				Every => {
					if !Interp.is_truthy(value) {
						$answer = Boolean(False)
						$going = False
					}
				}
				Find => {
					if Interp.is_truthy(value) {
						$answer = item
						$going = False
					}
				}
				FindIndex => {
					if Interp.is_truthy(value) {
						$answer = Number($i.to_f64())
						$going = False
					}
				}
				FlatMap => {
					more = match value {
						Reference(made) => match Heap.cell_at($machine.cells, made) {
							Array(items) => items
							_ => [value]
						}
						_ => [value]
					}
					$machine = { ..$machine, cells: Heap.with_items_pushed($machine.cells, out, more) }
				}
			}
		}
		$i = $i + 1
	}
	answer = if builds {
		Reference(out)
	} else {
		$answer
	}
	if is_running($machine) {
		with_result($machine, call.result_at, answer)
	} else {
		$machine
	}
}

# `findLast` and `findLastIndex`: the callback on each item from the last
# back, until one passes.
array_walk_back! : Canvas.Host, Bytecode.Program, Vm.Machine, ArrayCall, [FindLast, FindLastIndex] => Vm.Machine
array_walk_back! = |host, program, machine, call, walk| {
	callback = callback_of(machine, call)
	var $machine = machine
	var $k = item_count(machine, call.id)
	var $answer = match walk {
		FindLast => Undefined
		FindLastIndex => Number(-1.0)
	}
	var $going = True
	while $going and $k > 0 {
		$k = $k - 1
		item = item_at($machine, call.id, $k)
		{ machine: after, value } = answered(call_function!(host, program, $machine, { callee: callback, arguments: [item, Number($k.to_f64()), Reference(call.id)], at: call.at }))
		$machine = after
		if is_running($machine) and Interp.is_truthy(value) {
			$answer = match walk {
				FindLast => item
				FindLastIndex => Number($k.to_f64())
			}
			$going = False
		}
		$going = $going and is_running($machine)
	}
	if is_running($machine) {
		with_result($machine, call.result_at, $answer)
	} else {
		$machine
	}
}

# `reduce`, from the first item on, and `reduceRight`, from the last back.
array_reduce! : Canvas.Host, Bytecode.Program, Vm.Machine, ArrayCall, [Forward, Backward] => Vm.Machine
array_reduce! = |host, program, machine, call, direction| {
	callback = callback_of(machine, call)
	count = item_count(machine, call.id)
	start = if call.count > 1 {
		Ok({ accumulated: value_at(machine, call.count - 1), taken: 0 })
	} else if count == 0 {
		Err(Empty)
	} else {
		first = match direction {
			Forward => 0
			Backward => count - 1
		}
		Ok({ accumulated: item_at(machine, call.id, first), taken: 1 })
	}
	match start {
		Err(Empty) => with_error(machine, TypeError, "Reduce of empty array with no initial value", call.at)
		Ok({ accumulated, taken }) => {
			var $machine = machine
			var $accumulated = accumulated
			var $done = taken
			while $done < count and is_running($machine) and (direction == Backward or $done < item_count($machine, call.id)) {
				position = match direction {
					Forward => $done
					Backward => count - 1 - $done
				}
				item = item_at($machine, call.id, position)
				{ machine: after, value } = answered(call_function!(host, program, $machine, { callee: callback, arguments: [$accumulated, item, Number(position.to_f64()), Reference(call.id)], at: call.at }))
				$machine = after
				$accumulated = value
				$done = $done + 1
			}
			if is_running($machine) {
				with_result($machine, call.result_at, $accumulated)
			} else {
				$machine
			}
		}
	}
}

# `sort`, stable as JavaScript's is: a merge sort, the comparison a
# function's answer or, with none, the items' text. The items being sorted
# are all the array's, which the stack refers to, so the lists the sort
# holds keep nothing alive the machine doesn't.
array_sort! : Canvas.Host, Bytecode.Program, Vm.Machine, ArrayCall => Vm.Machine
array_sort! = |host, program, machine, call| {
	items = match Heap.cell_at(machine.cells, call.id) {
		Array(values) => values
		_ => crash "Vm.array_sort!: asked only of an array"
	}
	compare = callback_of(machine, call)
	{ machine: after, values } = merge_sorted!(host, program, machine, { items: items, compare: compare, at: call.at })
	if is_running(after) {
		with_result({ ..after, cells: Heap.with_items(after.cells, call.id, values) }, call.result_at, Reference(call.id))
	} else {
		after
	}
}

merge_sorted! : Canvas.Host, Bytecode.Program, Vm.Machine, { items : List(Heap.Value), compare : Heap.Value, at : Ast.Where } => { machine : Vm.Machine, values : List(Heap.Value) }
merge_sorted! = |host, program, machine, { items, compare, at }| {
	count = items.len()
	if count <= 1 {
		{ machine: machine, values: items }
	} else {
		half = count // 2
		{ machine: first, values: lower } = merge_sorted!(host, program, machine, { items: items.sublist({ start: 0, len: half }), compare: compare, at: at })
		{ machine: second, values: upper } = merge_sorted!(host, program, first, { items: items.drop_first(half), compare: compare, at: at })
		var $machine = second
		var $out = []
		var $i = 0
		var $j = 0
		while $i < lower.len() or $j < upper.len() {
			take_left = if $i >= lower.len() {
				False
			} else if $j >= upper.len() {
				True
			} else {
				left = lower.get($i) ?? crash "Vm.merge_sorted!: inside the lower half"
				right = upper.get($j) ?? crash "Vm.merge_sorted!: inside the upper half"
				{ machine: after, order } = ordering_of!(host, program, $machine, { compare: compare, left: left, right: right, at: at })
				$machine = after
				order != After
			}
			if take_left {
				$out = $out.append(lower.get($i) ?? crash "Vm.merge_sorted!: inside the lower half")
				$i = $i + 1
			} else {
				$out = $out.append(upper.get($j) ?? crash "Vm.merge_sorted!: inside the upper half")
				$j = $j + 1
			}
		}
		{ machine: $machine, values: $out }
	}
}

ordering_of! : Canvas.Host, Bytecode.Program, Vm.Machine, { compare : Heap.Value, left : Heap.Value, right : Heap.Value, at : Ast.Where } => { machine : Vm.Machine, order : [Before, Same, After] }
ordering_of! = |host, program, machine, { compare, left, right, at }|
	match compare {
		Undefined => {
			order = match (left, right) {
				(Undefined, Undefined) => Same
				(Undefined, _) => After
				(_, Undefined) => Before
				_ => match (Interp.text_of(machine.cells, left), Interp.text_of(machine.cells, right)) {
					(Ok(x), Ok(y)) => Interp.ordering_of_text(x, y)
					_ => Same
				}
			}
			{ machine: machine, order: order }
		}
		_ => {
			if !is_running(machine) {
				{ machine: machine, order: Same }
			} else {
				{ machine: after, value } = answered(call_function!(host, program, machine, { callee: compare, arguments: [left, right], at: at }))
				order = match value {
					Number(x) => if x > 0.0 {
						After
					} else if x < 0.0 {
						Before
					} else {
						Same
					}
					_ => Same
				}
				{ machine: after, order: order }
			}
		}
	}

# ---- for ... of ------------------------------------------------------------

iteration_started : Vm.Machine, Ast.Expression, Ast.Where -> Vm.Machine
iteration_started = |machine, source, at| {
	given = value_at(machine, 1)
	match given {
		Reference(id) => match Interp.kind_of(machine.cells, id) {
			ArrayKind(_) => machine
			MapKind | SetKind | IteratorKind => unsupported(machine, "`for ... of` over a Map, a Set or an iterator", at)
			_ => not_iterable(machine, source, at)
		}
		Text(text) => {
			id = machine.cells.len()
			characters = Interp.characters(text).map(|character| Text(character))
			replaced({ ..machine, cells: machine.cells.append(Array(characters)) }, 1, Reference(id))
		}
		_ => not_iterable(machine, source, at)
	}
}

not_iterable : Vm.Machine, Ast.Expression, Ast.Where -> Vm.Machine
not_iterable = |machine, source, at| with_error(machine, TypeError, "${Interp.source_text(source)} is not iterable", at)

iterated : Vm.Machine, U64, U64 -> Vm.Machine
iterated = |machine, slot, exit| {
	id = reference_id(slot_value(machine, slot))
	position = match slot_value(machine, slot + 1) {
		Number(at) => at.to_u64_try() ?? crash "Vm.iterated: a `for ... of`'s place is a whole number"
		_ => crash "Vm.iterated: a `for ... of`'s place is a number"
	}
	if position < item_count(machine, id) {
		pushed(with_slot(machine, slot + 1, Number((position + 1).to_f64())), item_at(machine, id, position))
	} else {
		{ ..machine, pc: machine.pc + exit }
	}
}
