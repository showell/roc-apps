## This module compiles a resolved JavaScript program (`Ast`) into the
## bytecode VM's code (`Bytecode`): each function, and the program itself, a
## flat list of instructions, its variables laid out as slots of its frame.
##
## **THE COMPILER'S SCOPES ARE `Resolve`'S, ONE FOR ONE.** It enters a scope
## wherever `Resolve` counted one (the program's, a `Scoped` block's, a
## function's, a C-form `for`'s, a `for ... of` pass's), so a name's
## `Ast.Slot`, hops out and an index there, finds its variable here too.
## Each scope's variables take slots of the frame of the function they are
## declared in, boxed when the scope holds a function literal
## (`Ast.Capture`). A name read from inside a function nested deeper than
## its scope is a capture: the nested function gets a slot of its own for
## the box, filled from its closure's environment at each call, and each
## function between passes the box on.
##
## **A READ BEFORE THE DECLARATION IS KNOWN HERE.** Within the function that
## declares it, a variable is read either after its declaration in the
## program's text, and then always after it has run, or before, and then
## always before: a block's scope starts afresh each time it is entered, and
## no jump lands inside a scope past a declaration. So such a read compiles
## to its ReferenceError (`ThrowUnready`), and only a read through a box,
## from a closure that may run at any time, checks at run time.
##
## **A LOOP RESOLVES ITS OWN `break` AND `continue`.** The code a statement
## compiles to may hold `Break` and `Continue` in place of jumps; the loop
## around them, once it knows where its end and its next pass are, turns
## them into jumps relative to where they sit.
##
## What the VM doesn't run yet is refused here when the parser's tree shows
## it (`unsupported (vm): ...`), and by the VM when only a run does.
import Ast
import Bytecode
import ValueRules

Compile :: [].{

	## A program's code, or the first construct in it the VM doesn't run yet.
	program : Ast.Program -> Try(Bytecode.Program, [Unsupported(Str)])
	program = |tree| {
		names = match tree.scoping {
			Scoped(scope_names) => scope_names
			Unscoped => crash "Compile.program: Parser.program_of gives a program its own scope"
		}
		begun = {
			codes: [],
			functions: [no_function_yet],
			scopes: [],
		}
		entered = entered_scope(
			begun,
			{
				names: names,
				kinds: kinds_of(names, tree.statements),
				parameters: 0,
				capture: tree.capture,
				boxes: AtCall,
			},
		)
		body = block_body(entered.state, tree.statements)?
		code = finished_code(body.state, { ops: body.ops.append(Do(Finish)), parameters: 0 })
		Ok({ codes: body.state.codes.append(code), main: body.state.codes.len() })
	}

	## What the compiler knows as it goes: the code of every function
	## finished so far, the functions being compiled (the innermost last), and
	## the scopes around the code being compiled, innermost last, as
	## `Resolve` counted them.
	State : {
		codes : List(Bytecode.Code),
		functions : List(Compile.Function),
		scopes : List(Compile.Scope),
	}

	## A function being compiled: how many slots its frame has so far, the
	## variables of enclosing functions it captures, and what its calls do
	## first.
	Function : {
		slots : U64,
		captures : List(Compile.Capture),
		entry : List(Bytecode.Entry),
	}

	## A captured variable, by its scope (a place in `State.scopes`) and its
	## index there: the slot its box takes in the capturing function's frame,
	## and the slot the box is in, in the frame of the function around it,
	## which a closure's environment takes it from.
	Capture : { scope : U64, index : U64, slot : U64, from : U64 }

	## A scope's variables, each its place, its kind, and whether the code
	## compiled so far has passed its declaration.
	Scope : {
		level : U64,
		places : List(Compile.Place),
		kinds : List(Bytecode.Kind),
		ready : List(Bool),
	}

	Place : [Slot(U64), Boxed(U64)]

	## An instruction, or a `break` or a `continue` its loop has yet to make
	## a jump.
	Emitted : [Do(Bytecode.Op), Break, Continue]

	Compiled : { state : Compile.State, ops : List(Compile.Emitted) }

	## Where a name's variable is, as the code being compiled reaches it: in
	## a slot or a box of its own frame, in a box it captures, a builtin, or
	## nowhere.
	Reached : [
		Own({ place : Compile.Place, kind : Bytecode.Kind, ready : Bool }),
		Captured({ slot : U64, kind : Bytecode.Kind }),
		Builtin(U64),
		Undeclared,
	]

	## A scope about to be entered: its names and their kinds, how many of
	## them are parameters (ready when the code starts), the parser's word on
	## whether a closure may capture them, and whether their boxes are made by
	## the call (a function's own scope) or by code where the scope starts.
	Layout : {
		names : List(Str),
		kinds : List(Bytecode.Kind),
		parameters : U64,
		capture : Ast.Capture,
		boxes : [AtCall, AtEntry],
	}
}

no_function_yet : Compile.Function
no_function_yet = { slots: 0, captures: [], entry: [] }

refusal : Str -> Try(a, [Unsupported(Str)])
refusal = |what| Err(Unsupported("unsupported (vm): ${what}"))

compiled : Compile.State, List(Compile.Emitted) -> Try(Compile.Compiled, [Unsupported(Str)])
compiled = |state, ops| Ok({ state: state, ops: ops })

ops_of : List(Bytecode.Op) -> List(Compile.Emitted)
ops_of = |ops| ops.map(|op| Do(op))

# A run's code from its emitted list: every `break` and `continue` has been
# made a jump by its loop by the time its function is finished.
finished_ops : List(Compile.Emitted) -> List(Bytecode.Op)
finished_ops = |emitted|
	emitted.map(
		|each| match each {
			Do(op) => op
			Break | Continue => crash "Compile.finished_ops: a loop resolves every break and continue inside it"
		},
	)

finished_code : Compile.State, { ops : List(Compile.Emitted), parameters : U64 } -> Bytecode.Code
finished_code = |state, { ops, parameters }| {
	function = state.functions.last() ?? crash "Compile.finished_code: a function is being compiled"
	{
		ops: finished_ops(ops),
		frame_size: function.slots,
		parameters: parameters,
		entry: function.entry,
	}
}

# The kind of each name a scope holds: `const` for the names a `const`
# among its statements declares.
kinds_of : List(Str), List(Ast.Statement) -> List(Bytecode.Kind)
kinds_of = |names, statements| {
	var $constants = []
	for statement in statements {
		match statement {
			Declare(Const, declarators) => {
				for declarator in declarators {
					$constants = List.concat($constants, Ast.pattern_names(declarator.pattern))
				}
			}
			_ => {}
		}
	}
	constants = $constants
	names.map(
		|name|
			if constants.contains(name) {
				Fixed
			} else {
				Mutable
			},
	)
}

kind_of_binding : Ast.Binding -> Bytecode.Kind
kind_of_binding = |binding| match binding {
	Let => Mutable
	Const => Fixed
}

with_function : Compile.State, (Compile.Function -> Compile.Function) -> Compile.State
with_function = |state, change| {
	level = state.functions.len() - 1
	{
		..state,
		functions: state.functions.update(level, change) ?? crash "Compile.with_function: a function is being compiled",
	}
}

# The state inside a new scope of the innermost function, and the code that
# makes its boxes where it starts (none when the call makes them).
entered_scope : Compile.State, Compile.Layout -> Compile.Compiled
entered_scope = |state, layout| {
	function = state.functions.last() ?? crash "Compile.entered_scope: a function is being compiled"
	first = function.slots
	count = layout.names.len()
	boxed = layout.capture == Captures
	slots = List.from_iter(U64.until(first, first + count))
	places = slots.map(
		|slot|
			if boxed {
				Boxed(slot)
			} else {
				Slot(slot)
			},
	)
	entries = if boxed and layout.boxes == AtCall {
		slots.map_with_index(
			|slot, index|
				if index < layout.parameters {
					FilledBox(slot)
				} else {
					FreshBox(slot)
				},
		)
	} else {
		[]
	}
	ops = if boxed and layout.boxes == AtEntry {
		slots.map(|slot| Do(NewBox(slot)))
	} else {
		[]
	}
	grown = with_function(
		state,
		|f| { ..f, slots: f.slots + count, entry: List.concat(f.entry, entries) },
	)
	scope = {
		level: grown.functions.len() - 1,
		places: places,
		kinds: layout.kinds,
		ready: List.from_iter(U64.until(0, count)).map(|index| index < layout.parameters),
	}
	{ state: { ..grown, scopes: grown.scopes.append(scope) }, ops: ops }
}

left_scope : Compile.State -> Compile.State
left_scope = |state| { ..state, scopes: state.scopes.drop_last(1) }

# A new slot of the innermost function's frame, for a `for ... of`'s place.
with_hidden_slots : Compile.State, U64 -> { state : Compile.State, slot : U64 }
with_hidden_slots = |state, count| {
	function = state.functions.last() ?? crash "Compile.with_hidden_slots: a function is being compiled"
	{ state: with_function(state, |f| { ..f, slots: f.slots + count }), slot: function.slots }
}

# The state with a declaration's variable passed, so later reads of it in
# its own function read it plainly.
with_ready : Compile.State, Ast.Slot -> Compile.State
with_ready = |state, slot| {
	index = own_index(slot)
	last = state.scopes.len() - 1
	{
		..state,
		scopes: state.scopes.update(
			last,
			|scope| { ..scope, ready: scope.ready.set(index, True) ?? crash "Compile.with_ready: a variable its scope's layout names" },
		) ?? crash "Compile.with_ready: a scope is open",
	}
}

own_index : Ast.Slot -> U64
own_index = |slot| match slot {
	Local({ hops: 0, index }) => index
	_ => crash "Compile.own_index: Resolve places a declaration in its own scope"
}

reached_of : Compile.State, Ast.Slot -> { state : Compile.State, reached : Compile.Reached }
reached_of = |state, slot|
	match slot {
		Local({ hops, index }) => {
			at = state.scopes.len() - 1 - hops
			scope = state.scopes.get(at) ?? crash "Compile.reached_of: Resolve counts no more scopes out than there are"
			place = scope.places.get(index) ?? crash "Compile.reached_of: a variable its scope's layout names"
			kind = scope.kinds.get(index) ?? crash "Compile.reached_of: a variable its scope's layout names"
			level = state.functions.len() - 1
			if scope.level == level {
				ready = scope.ready.get(index) ?? crash "Compile.reached_of: a variable its scope's layout names"
				{ state: state, reached: Own({ place: place, kind: kind, ready: ready }) }
			} else {
				{ state: after, slot: box } = capture_slot(state, { level: level, scope: at, index: index })
				{ state: after, reached: Captured({ slot: box, kind: kind }) }
			}
		}
		Global(index) => { state: state, reached: Builtin(index) }
		Undeclared => { state: state, reached: Undeclared }
		Unresolved => crash "Compile.reached_of: Parser.program_of resolves every name"
	}

# The slot, in the frame of the function at `level`, of the box of a
# variable an enclosing function declares: captured by `level`, and by every
# function between, the first time one of them reaches it.
capture_slot : Compile.State, { level : U64, scope : U64, index : U64 } -> { state : Compile.State, slot : U64 }
capture_slot = |state, { level, scope, index }| {
	declared = state.scopes.get(scope) ?? crash "Compile.capture_slot: a scope the compiler has"
	if declared.level == level {
		match declared.places.get(index) {
			Ok(Boxed(slot)) => { state: state, slot: slot }
			_ => crash "Compile.capture_slot: a scope with a function literal inside boxes its variables"
		}
	} else {
		function = state.functions.get(level) ?? crash "Compile.capture_slot: a function being compiled"
		match function.captures.find_first(|c| c.scope == scope and c.index == index) {
			Ok(found) => { state: state, slot: found.slot }
			Err(NotFound) => {
				{ state: outer, slot: from } = capture_slot(state, { level: level - 1, scope: scope, index: index })
				known = outer.functions.get(level) ?? crash "Compile.capture_slot: a function being compiled"
				slot = known.slots
				capture = { scope: scope, index: index, slot: slot, from: from }
				grown = {
					..known,
					slots: slot + 1,
					captures: known.captures.append(capture),
					entry: known.entry.append(CapturedBox({ slot: slot, capture: known.captures.len() })),
				}
				{
					state: { ..outer, functions: outer.functions.set(level, grown) ?? crash "Compile.capture_slot: a function being compiled" },
					slot: slot,
				}
			}
		}
	}
}

# The jump from the instruction at `from` to the one at `to`.
jump_to : U64, U64 -> Bytecode.Op
jump_to = |from, to|
	if to > from {
		Jump(to - from - 1)
	} else {
		Loop(from + 1 - to)
	}

# A loop's code with its own `break`s and `continue`s made jumps: `ops`
# starts at `offset` in the loop's code, whose end is `exit` and whose next
# pass starts at `next`. A loop inside resolved its own before.
resolved : List(Compile.Emitted), { offset : U64, exit : U64, next : U64 } -> List(Compile.Emitted)
resolved = |ops, { offset, exit, next }|
	ops.map_with_index(
		|each, index| match each {
			Break => Do(jump_to(offset + index, exit))
			Continue => Do(jump_to(offset + index, next))
			done => done
		},
	)

# ---- statements ------------------------------------------------------------

# A block's code, its functions made first.
block_body : Compile.State, List(Ast.Statement) -> Try(Compile.Compiled, [Unsupported(Str)])
block_body = |state, statements| {
	hoisted = hoisted_functions(state, statements)?
	body = statement_list(hoisted.state, statements)?
	compiled(body.state, List.concat(hoisted.ops, body.ops))
}

hoisted_functions : Compile.State, List(Ast.Statement) -> Try(Compile.Compiled, [Unsupported(Str)])
hoisted_functions = |state, statements| {
	var $state = state
	var $ops = []
	for statement in statements {
		match statement {
			FunctionDeclaration(definition, slot) => {
				made = function_made($state, definition)?
				declared = declaration_ops(made.state, slot)
				$state = with_ready(declared.state, slot)
				$ops = List.concat($ops.append(Do(made.op)), declared.ops)
			}
			_ => {}
		}
	}
	compiled($state, $ops)
}

# The code that takes the value on the stack into a declaration's variable.
declaration_ops : Compile.State, Ast.Slot -> Compile.Compiled
declaration_ops = |state, slot| {
	{ state: after, reached } = reached_of(state, slot)
	op = match reached {
		Own({ place: Slot(at), kind: _, ready: _ }) => SetLocal(at)
		Own({ place: Boxed(at), kind: _, ready: _ }) => SetBoxed(at)
		_ => crash "Compile.declaration_ops: Resolve places a declaration in its own scope"
	}
	{ state: after, ops: [Do(op)] }
}

statement_list : Compile.State, List(Ast.Statement) -> Try(Compile.Compiled, [Unsupported(Str)])
statement_list = |state, statements| {
	var $state = state
	var $ops = []
	for statement in statements {
		done = statement_compiled($state, statement)?
		$state = done.state
		$ops = List.concat($ops, done.ops)
	}
	compiled($state, $ops)
}

statement_compiled : Compile.State, Ast.Statement -> Try(Compile.Compiled, [Unsupported(Str)])
statement_compiled = |state, statement|
	match statement {
		Expression(tree) => {
			done = expression_compiled(state, tree)?
			compiled(done.state, done.ops.append(Do(Pop)))
		}
		Declare(_, declarators) => declarations(state, declarators)
		FunctionDeclaration(_, _) => compiled(state, [])
		If(test, yes, no) => {
			tested = expression_compiled(state, test)?
			then = statement_compiled(tested.state, yes)?
			otherwise = statement_compiled(then.state, no)?
			ops = if otherwise.ops.is_empty() {
				List.concat(tested.ops.append(Do(JumpIfFalse(then.ops.len()))), then.ops)
			} else {
				List.concat(
					List.concat(
						tested.ops.append(Do(JumpIfFalse(then.ops.len() + 1))),
						then.ops.append(Do(Jump(otherwise.ops.len()))),
					),
					otherwise.ops,
				)
			}
			compiled(otherwise.state, ops)
		}
		While(loop) => while_loop(state, loop)
		For(loop) => for_loop(state, loop)
		ForOf(loop) => for_of_loop(state, loop)
		BlockStatement(tree_block) => block(state, tree_block)
		Return(tree) => {
			done = expression_compiled(state, tree)?
			compiled(done.state, done.ops.append(Do(Return)))
		}
		Throw(tree, site) => {
			done = expression_compiled(state, tree)?
			compiled(done.state, done.ops.append(Do(Throw(site))))
		}
		Try(_) => refusal("`try` statements")
		Switch(_) => refusal("`switch` statements")
		Break(Unlabelled) => compiled(state, [Break])
		Continue(Unlabelled) => compiled(state, [Continue])
		Break(Named(_)) | Continue(Named(_)) | Labelled(_, _) => refusal("labels")
		Empty => compiled(state, [])
	}

block : Compile.State, Ast.Block -> Try(Compile.Compiled, [Unsupported(Str)])
block = |state, tree_block|
	match tree_block.scoping {
		Unscoped => statement_list(state, tree_block.statements)
		Scoped(names) => {
			entered = entered_scope(
				state,
				{
					names: names,
					kinds: kinds_of(names, tree_block.statements),
					parameters: 0,
					capture: tree_block.capture,
					boxes: AtEntry,
				},
			)
			body = block_body(entered.state, tree_block.statements)?
			compiled(left_scope(body.state), List.concat(entered.ops, body.ops))
		}
	}

declarations : Compile.State, List(Ast.Declarator) -> Try(Compile.Compiled, [Unsupported(Str)])
declarations = |state, declarators| {
	var $state = state
	var $ops = []
	for declarator in declarators {
		match declarator.pattern {
			Leaf(ToName(_, slot, _)) => {
				value = match declarator.init {
					Initialized(tree) => expression_compiled($state, tree)?
					Uninitialized => { state: $state, ops: [Do(PushUndefined)] }
				}
				declared = declaration_ops(value.state, slot)
				$state = with_ready(declared.state, slot)
				$ops = List.concat(List.concat($ops, value.ops), declared.ops)
			}
			_ => {
				return refusal("destructuring${ValueRules.line_note(declarator.at)}")
			}
		}
	}
	compiled($state, $ops)
}

refused_labels : List(U64) -> Try({}, [Unsupported(Str)])
refused_labels = |labels|
	if labels.is_empty() {
		Ok({})
	} else {
		refusal("labels")
	}

# A `while`, its test before each pass, or a `do ... while`, after.
while_loop : Compile.State, Ast.WhileLoop -> Try(Compile.Compiled, [Unsupported(Str)])
while_loop = |state, { test, body, order, labels }| {
	refused_labels(labels)?
	tested = expression_compiled(state, test)?
	passed = statement_compiled(tested.state, body)?
	t = tested.ops.len()
	b = passed.ops.len()
	ops = match order {
		TestFirst => {
			# test, JumpIfFalse, body, Loop
			total = t + 1 + b + 1
			List.concat(
				tested.ops.append(Do(JumpIfFalse(b + 1))),
				resolved(passed.ops, { offset: t + 1, exit: total, next: 0 }),
			).append(Do(Loop(total)))
		}
		TestAfter => {
			# body, test, JumpIfFalse, Loop
			total = b + t + 2
			List.concat(
				resolved(passed.ops, { offset: 0, exit: total, next: b }),
				tested.ops,
			).append(Do(JumpIfFalse(1))).append(Do(Loop(total)))
		}
	}
	compiled(passed.state, ops)
}

for_loop : Compile.State, Ast.ForLoop -> Try(Compile.Compiled, [Unsupported(Str)])
for_loop = |state, loop| {
	refused_labels(loop.labels)?
	entered = entered_scope(
		state,
		{
			names: loop.names,
			kinds: kinds_of(loop.names, [loop.init]),
			parameters: 0,
			capture: loop.capture,
			boxes: AtEntry,
		},
	)
	begun = statement_compiled(entered.state, loop.init)?
	tested = match loop.test {
		Tested(tree) => {
			done = expression_compiled(begun.state, tree)?
			Tested(done)
		}
		Always => Always
	}
	tested_state = match tested {
		Tested(done) => done.state
		Always => begun.state
	}
	passed = statement_compiled(tested_state, loop.body)?
	# **EACH PASS HAS ITS OWN `let`**, as JavaScript gives a closure made in
	# the body the pass's own variable: a boxed variable gets a fresh box
	# holding its value before the update.
	scope = passed.state.scopes.last() ?? crash "Compile.for_loop: the loop's scope is open"
	copies = scope.places.keep_oks(
		|place| match place {
			Boxed(slot) => Ok(Do(CopyBox(slot)))
			Slot(_) => Err(NotBoxed)
		},
	)
	updated = match loop.update {
		Updated(tree) => {
			done = expression_compiled(passed.state, tree)?
			{ state: done.state, ops: done.ops.append(Do(Pop)) }
		}
		NoUpdate => { state: passed.state, ops: [] }
	}
	head = List.concat(entered.ops, begun.ops)
	test_ops = match tested {
		Tested(done) => done.ops
		Always => []
	}
	b = passed.ops.len()
	tail = List.concat(copies, updated.ops)
	check = if test_ops.is_empty() {
		0
	} else {
		test_ops.len() + 1
	}
	# test, JumpIfFalse, body, copies, update, Loop
	total = check + b + tail.len() + 1
	check_ops = if test_ops.is_empty() {
		[]
	} else {
		test_ops.append(Do(JumpIfFalse(b + tail.len() + 1)))
	}
	ops = List.concat(
		List.concat(check_ops, resolved(passed.ops, { offset: check, exit: total, next: check + b })),
		tail,
	).append(Do(Loop(total)))
	compiled(left_scope(updated.state), List.concat(head, ops))
}

for_of_loop : Compile.State, Ast.ForOfLoop -> Try(Compile.Compiled, [Unsupported(Str)])
for_of_loop = |state, loop| {
	refused_labels(loop.labels)?
	slot = match loop.pattern {
		Leaf(ToName(_, leaf, _)) => leaf
		_ => return refusal("destructuring${ValueRules.line_note(loop.at)}")
	}
	walked = expression_compiled(state, loop.iterable)?
	{ state: placed, slot: hidden } = with_hidden_slots(walked.state, 2)
	head = List.concat(
		walked.ops,
		ops_of([
			IterStart({ source: loop.iterable, at: loop.at }),
			SetLocal(hidden),
			PushNumber(0.0),
			SetLocal(hidden + 1),
		]),
	)
	entered = entered_scope(
		placed,
		{
			names: loop.names,
			kinds: loop.names.map(|_| kind_of_binding(loop.binding)),
			parameters: 0,
			capture: loop.capture,
			boxes: AtEntry,
		},
	)
	declared = declaration_ops(entered.state, slot)
	passed = statement_compiled(with_ready(declared.state, slot), loop.body)?
	pass = List.concat(List.concat(entered.ops, declared.ops), passed.ops)
	# IterNext, the pass, Loop
	total = 1 + pass.len() + 1
	start = List.concat(
		[Do(IterNext({ slot: hidden, exit: pass.len() + 1 }))],
		resolved(pass, { offset: 1, exit: total, next: 0 }),
	)
	compiled(left_scope(passed.state), List.concat(head, start.append(Do(Loop(total)))))
}

# ---- functions -------------------------------------------------------------

# The closure-making instruction of a function literal, its code compiled
# and added to the program's.
function_made : Compile.State, Box(Ast.FunctionDefinition) -> Try({ state : Compile.State, op : Bytecode.Op }, [Unsupported(Str)])
function_made = |state, boxed| {
	definition = boxed.unbox()
	parameters = match definition.binding {
		Plain => definition.parameters.len()
		Patterned(_) => return refusal("parameter patterns, defaults and rest parameters${ValueRules.line_note(definition.at)}")
	}
	inner = { ..state, functions: state.functions.append(no_function_yet) }
	entered = entered_scope(
		inner,
		{
			names: definition.names,
			kinds: kinds_of(definition.names, definition.statements),
			parameters: parameters,
			capture: definition.capture,
			boxes: AtCall,
		},
	)
	body = block_body(entered.state, definition.statements)?
	done = body.state
	code = finished_code(done, { ops: body.ops.append(Do(PushUndefined)).append(Do(Return)), parameters: parameters })
	function = done.functions.last() ?? crash "Compile.function_made: the function is being compiled"
	Ok({
		state: {
			codes: done.codes.append(code),
			functions: done.functions.drop_last(1),
			scopes: done.scopes.drop_last(1),
		},
		op: MakeClosure({ code: done.codes.len(), captures: function.captures.map(|c| c.from), definition: boxed }),
	})
}

# ---- expressions -----------------------------------------------------------

expression_compiled : Compile.State, Ast.Expression -> Try(Compile.Compiled, [Unsupported(Str)])
expression_compiled = |state, tree|
	match tree {
		Number(number) => compiled(state, [Do(PushNumber(number))])
		Text(text) => compiled(state, [Do(PushText(text))])
		Boolean(truth) => compiled(state, [Do(PushBoolean(truth))])
		Null => compiled(state, [Do(PushNull)])
		Undefined => compiled(state, [Do(PushUndefined)])
		Template(texts, parts) => {
			first = texts.first() ?? crash "Compile.expression_compiled: a template has a text piece before its first substitution"
			var $state = state
			var $ops = [Do(PushText(first))]
			var $i = 1
			for part in parts {
				done = expression_compiled($state, part)?
				$state = done.state
				piece = texts.get($i) ?? crash "Compile.expression_compiled: a template has a text piece after each substitution"
				$ops = List.concat($ops, done.ops).append(Do(TemplatePart(piece)))
				$i = $i + 1
			}
			compiled($state, $ops)
		}
		Name(name, slot, site) => name_read(state, { name: name, slot: slot, at: site })
		ArrayLit(items) => {
			if items.any(|item| is_spread(item)) {
				elements_array(state, items)
			} else {
				done = singles(state, items)?
				compiled(done.state, done.ops.append(Do(MakeArray(items.len()))))
			}
		}
		ObjectLit(parts) => {
			var $state = state
			var $ops = [Do(NewObject)]
			for part in parts {
				match part {
					Field(written) => {
						done = expression_compiled($state, written.value)?
						$state = done.state
						$ops = List.concat($ops, done.ops).append(Do(SetField(written.key)))
					}
					Spread(spread, site) => {
						done = expression_compiled($state, spread)?
						$state = done.state
						$ops = List.concat($ops, done.ops).append(Do(SpreadFields(site)))
					}
				}
			}
			compiled($state, $ops)
		}
		Unary(operator, operand, site) => {
			done = expression_compiled(state, operand)?
			compiled(done.state, done.ops.append(Do(Unary(operator, site))))
		}
		Binary(operator, left, right, site) => {
			first = expression_compiled(state, left)?
			second = expression_compiled(first.state, right)?
			compiled(second.state, List.concat(first.ops, second.ops).append(Do(Binary(operator, site))))
		}
		Logical(operator, left, right) => {
			first = expression_compiled(state, left)?
			second = expression_compiled(first.state, right)?
			compiled(second.state, List.concat(first.ops.append(Do(skip_for(operator, second.ops.len()))), second.ops))
		}
		Conditional(test, yes, no) => {
			tested = expression_compiled(state, test)?
			then = expression_compiled(tested.state, yes)?
			otherwise = expression_compiled(then.state, no)?
			compiled(
				otherwise.state,
				List.concat(
					List.concat(
						tested.ops.append(Do(JumpIfFalse(then.ops.len() + 1))),
						then.ops.append(Do(Jump(otherwise.ops.len()))),
					),
					otherwise.ops,
				),
			)
		}
		Assign(target, operator, value, site) => assignment(state, { target: target, operator: operator, value: value, at: site })
		Update(target, step, fixity, site) => {
			update = {
				delta: match step {
					Increment => 1.0
					Decrement => -1.0
				},
				fixity: fixity,
				at: site,
			}
			update_compiled(state, { target: target, update: update })
		}
		Member(object, key, site) => {
			done = expression_compiled(state, object)?
			compiled(done.state, done.ops.append(Do(GetProperty(key, site))))
		}
		Index(object, key, site) => {
			first = expression_compiled(state, object)?
			second = expression_compiled(first.state, key)?
			compiled(second.state, List.concat(first.ops, second.ops).append(Do(GetIndex(site))))
		}
		Call(callee, arguments, site) => call_compiled(state, { callee: callee, arguments: arguments, at: site })
		Function(definition) => {
			made = function_made(state, definition)?
			compiled(made.state, [Do(made.op)])
		}
		New(callee, arguments, site) => {
			if arguments.any(|argument| is_spread(argument)) {
				refusal("spread in `new`'s arguments${ValueRules.line_note(site)}")
			} else {
				made = expression_compiled(state, callee)?
				given = singles(made.state, arguments)?
				compiled(
					given.state,
					List.concat(made.ops, given.ops).append(Do(Construct({ count: arguments.len(), callee: callee, at: site }))),
				)
			}
		}
		Chain(_) => refusal("optional chains (`?.`)")
		OptionalMember(_, _, _) | OptionalIndex(_, _, _) | OptionalCall(_, _, _) => crash "Compile.expression_compiled: Parser.call_or_member puts an optional link inside a Chain"
		Destructure(_, _, site) => refusal("destructuring${ValueRules.line_note(site)}")
	}

skip_for : Ast.LogicalOperator, U64 -> Bytecode.Op
skip_for = |operator, count| match operator {
	And => SkipIfFalsy(count)
	Or => SkipIfTruthy(count)
	Nullish => SkipIfDefined(count)
}

is_spread : Ast.Element -> Bool
is_spread = |element| match element {
	Spread(_, _) => True
	Single(_) => False
}

# The values of elements none of which is a spread, pushed in order.
singles : Compile.State, List(Ast.Element) -> Try(Compile.Compiled, [Unsupported(Str)])
singles = |state, elements| {
	var $state = state
	var $ops = []
	for element in elements {
		match element {
			Single(tree) => {
				done = expression_compiled($state, tree)?
				$state = done.state
				$ops = List.concat($ops, done.ops)
			}
			Spread(_, _) => crash "Compile.singles: its callers pass elements without a spread"
		}
	}
	compiled($state, $ops)
}

# An array of elements some of which are spreads, built one at a time.
elements_array : Compile.State, List(Ast.Element) -> Try(Compile.Compiled, [Unsupported(Str)])
elements_array = |state, elements| {
	var $state = state
	var $ops = [Do(NewArray)]
	for element in elements {
		match element {
			Single(tree) => {
				done = expression_compiled($state, tree)?
				$state = done.state
				$ops = List.concat($ops, done.ops).append(Do(AppendItem))
			}
			Spread(tree, site) => {
				done = expression_compiled($state, tree)?
				$state = done.state
				$ops = List.concat($ops, done.ops).append(Do(AppendSpread({ source: tree, at: site })))
			}
		}
	}
	compiled($state, $ops)
}

name_read : Compile.State, { name : Str, slot : Ast.Slot, at : Ast.Where } -> Try(Compile.Compiled, [Unsupported(Str)])
name_read = |state, { name, slot, at }| {
	{ state: after, reached } = reached_of(state, slot)
	op = match reached {
		Own({ place: _, kind: _, ready: False }) => ThrowUnready({ name: name, at: at })
		Own({ place: Slot(local), kind: _, ready: True }) => LoadLocal(local)
		Own({ place: Boxed(box), kind: _, ready: True }) => LoadBoxed({ slot: box, name: name, at: at })
		Captured({ slot: box, kind: _ }) => LoadBoxed({ slot: box, name: name, at: at })
		Builtin(index) => LoadBuiltin(index)
		Undeclared => MissingName({ name: name, at: at })
	}
	compiled(after, [Do(op)])
}

# The old value a compound assignment combines, read as the walker reads
# it: an unready variable's is undefined, the error coming at the write.
name_peek : Compile.Reached -> Bytecode.Op
name_peek = |reached| match reached {
	Own({ place: _, kind: _, ready: False }) => PushUndefined
	Own({ place: Slot(local), kind: _, ready: True }) => LoadLocal(local)
	Own({ place: Boxed(box), kind: _, ready: True }) => PeekBoxed(box)
	Captured({ slot: box, kind: _ }) => PeekBoxed(box)
	Builtin(index) => LoadBuiltin(index)
	Undeclared => crash "Compile.name_peek: an assignment to an undeclared name is refused before it reads"
}

# The write of the value on the stack to a name's variable, which leaves
# the value there.
name_write : Compile.Reached, { name : Str, at : Ast.Where } -> Bytecode.Op
name_write = |reached, { name, at }| match reached {
	Own({ place: _, kind: _, ready: False }) => ThrowUnready({ name: name, at: at })
	Own({ place: _, kind: Fixed, ready: True }) => ThrowConstant(at)
	Own({ place: Slot(local), kind: Mutable, ready: True }) => StoreLocal(local)
	Own({ place: Boxed(box), kind: Mutable, ready: True }) => StoreBoxed({ slot: box, name: name, kind: Mutable, at: at })
	Captured({ slot: box, kind }) => StoreBoxed({ slot: box, name: name, kind: kind, at: at })
	Builtin(_) => ThrowConstant(at)
	Undeclared => crash "Compile.name_write: an assignment to an undeclared name is refused before it writes"
}

undeclared_refusal : Str, Ast.Where -> Bytecode.Op
undeclared_refusal = |name, at| Refuse("unsupported: assigning to `${name}`, which is not declared${ValueRules.line_note(at)}")

Assignment : {
	target : Ast.Target,
	operator : Ast.AssignmentOperator,
	value : Ast.Expression,
	at : Ast.Where,
}

assignment : Compile.State, Assignment -> Try(Compile.Compiled, [Unsupported(Str)])
assignment = |state, { target, operator, value, at: site }|
	match target {
		ToName(name, slot, at) => {
			{ state: placed, reached } = reached_of(state, slot)
			if reached == Undeclared {
				compiled(placed, [Do(undeclared_refusal(name, at))])
			} else {
				made = expression_compiled(placed, value)?
				write = name_write(reached, { name: name, at: at })
				ops = match operator {
					Set => made.ops.append(Do(write))
					Combine(Add) if ValueRules.is_pure(value) and is_plain_local(reached) => made.ops.append(Do(AppendLocal({ slot: plain_slot(reached), at: site })))
					Combine(binary) => List.concat([Do(name_peek(reached))], made.ops).append(Do(Binary(binary, site))).append(Do(write))
					Logically(logical) => {
						read = name_read(placed, { name: name, slot: slot, at: at })?
						rest = made.ops.append(Do(write))
						List.concat(read.ops.append(Do(skip_for(logical, rest.len()))), rest)
					}
				}
				compiled(made.state, ops)
			}
		}
		ToMember(object, key) => {
			holder = expression_compiled(state, object)?
			made = expression_compiled(holder.state, value)?
			ops = match operator {
				Set => List.concat(holder.ops, made.ops).append(Do(SetProperty(key, site)))
				Combine(binary) => List.concat(
					holder.ops.append(Do(Duplicate)).append(Do(GetProperty(key, site))),
					made.ops,
				).append(Do(Binary(binary, site))).append(Do(SetProperty(key, site)))
				Logically(logical) => {
					rest = made.ops.append(Do(SetProperty(key, site))).append(Do(Jump(1)))
					List.concat(
						holder.ops.append(Do(Duplicate)).append(Do(GetProperty(key, site))).append(Do(skip_for(logical, rest.len()))),
						rest,
					).append(Do(Nip))
				}
			}
			compiled(made.state, ops)
		}
		ToIndex(object, key) => {
			holder = expression_compiled(state, object)?
			keyed = expression_compiled(holder.state, key)?
			made = expression_compiled(keyed.state, value)?
			both = List.concat(holder.ops, keyed.ops)
			ops = match operator {
				Set => List.concat(both, made.ops).append(Do(SetIndex(site)))
				Combine(binary) => List.concat(
					both.append(Do(DuplicatePair)).append(Do(GetIndex(site))),
					made.ops,
				).append(Do(Binary(binary, site))).append(Do(SetIndex(site)))
				Logically(logical) => {
					rest = made.ops.append(Do(SetIndex(site))).append(Do(Jump(2)))
					List.concat(
						both.append(Do(DuplicatePair)).append(Do(GetIndex(site))).append(Do(skip_for(logical, rest.len()))),
						rest,
					).append(Do(Nip)).append(Do(Nip))
				}
			}
			compiled(made.state, ops)
		}
	}

# A variable of the function's own frame, in a slot, ready and mutable: one
# a string may grow in.
is_plain_local : Compile.Reached -> Bool
is_plain_local = |reached| match reached {
	Own({ place: Slot(_), kind: Mutable, ready: True }) => True
	_ => False
}

plain_slot : Compile.Reached -> U64
plain_slot = |reached| match reached {
	Own({ place: Slot(local), kind: _, ready: _ }) => local
	_ => crash "Compile.plain_slot: asked only of a plain local"
}

update_compiled : Compile.State, { target : Ast.Target, update : Bytecode.Update } -> Try(Compile.Compiled, [Unsupported(Str)])
update_compiled = |state, { target, update }|
	match target {
		ToName(name, slot, at) => {
			{ state: placed, reached } = reached_of(state, slot)
			ops = match reached {
				Own({ place: _, kind: _, ready: False }) => [ThrowUnready({ name: name, at: at })]
				Own({ place: Slot(local), kind: Mutable, ready: True }) => [UpdateLocal({ slot: local, step: update })]
				Own({ place: Slot(local), kind: Fixed, ready: True }) => [LoadLocal(local), UpdateFixed(update.at)]
				Own({ place: Boxed(box), kind, ready: True }) => [UpdateBoxed({ slot: box, name: name, kind: kind, step: update })]
				Captured({ slot: box, kind }) => [UpdateBoxed({ slot: box, name: name, kind: kind, step: update })]
				Builtin(index) => [LoadBuiltin(index), UpdateFixed(update.at)]
				Undeclared => [MissingName({ name: name, at: at })]
			}
			compiled(placed, ops_of(ops))
		}
		ToMember(object, key) => {
			holder = expression_compiled(state, object)?
			compiled(holder.state, holder.ops.append(Do(UpdateProperty({ key: key, step: update }))))
		}
		ToIndex(object, key) => {
			holder = expression_compiled(state, object)?
			keyed = expression_compiled(holder.state, key)?
			compiled(keyed.state, List.concat(holder.ops, keyed.ops).append(Do(UpdateIndex(update))))
		}
	}

call_compiled : Compile.State, { callee : Ast.Expression, arguments : List(Ast.Element), at : Ast.Where } -> Try(Compile.Compiled, [Unsupported(Str)])
call_compiled = |state, { callee, arguments, at }| {
	written = ValueRules.source_text(callee)
	spreads = arguments.any(|argument| is_spread(argument))
	match callee {
		Member(object, name, _) => {
			holder = expression_compiled(state, object)?
			given = if spreads {
				elements_array(holder.state, arguments)?
			} else {
				singles(holder.state, arguments)?
			}
			call = if spreads {
				CallMethodSpread({ name: name, written: written, at: at })
			} else {
				CallMethod({ name: name, site: { count: arguments.len(), written: written, at: at } })
			}
			compiled(
				given.state,
				List.concat(holder.ops.append(Do(MethodLookup(name, at))), given.ops).append(Do(call)),
			)
		}
		_ => {
			function = expression_compiled(state, callee)?
			given = if spreads {
				elements_array(function.state, arguments)?
			} else {
				singles(function.state, arguments)?
			}
			call = if spreads {
				CallSpread({ written: written, at: at })
			} else {
				Call({ count: arguments.len(), written: written, at: at })
			}
			compiled(given.state, List.concat(function.ops, given.ops).append(Do(call)))
		}
	}
}
