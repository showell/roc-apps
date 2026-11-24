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
## **A BREAKABLE RESOLVES ITS OWN `break`S AND `continue`S.** The code a
## statement compiles to may hold `Exit` and `Next` in place of jumps, each
## naming the loop, `switch` or labelled statement it leaves by its place
## among the function's; that statement, once it knows where its end and its
## next pass are, turns them into jumps relative to where they sit. An
## optional chain does the same with its links' `Short`s.
##
## **EVERY WAY OUT OF A `try` BUT A THROW RUNS ITS `finally` ON THE WAY.** A
## `break`, a `continue` or a `return` inside a `try` takes off the handlers
## of the `try`s it leaves and runs their `finally` blocks, compiled where it
## stands, before its jump (`tries_left`); a throw reaches the `finally`
## through its handler.
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
			breakables: [],
			tries: [],
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
		frame = match names.find_first_index(|name| name == "frame") {
			Ok(index) => {
				scope = entered.state.scopes.last() ?? crash "Compile.program: the program's scope was just entered"
				Declared(scope.places.get(index) ?? crash "Compile.program: a scope has a place for each of its names")
			}
			Err(NotFound) => Undeclared
		}
		body = block_body(entered.state, tree.statements)?
		code = finished_code(body.state, { ops: body.ops.append(Do(Finish)), arguments: Each(0) })
		Ok({ codes: body.state.codes.append(code), main: body.state.codes.len(), frame: frame })
	}

	## What the compiler knows as it goes: the code of every function
	## finished so far, the functions being compiled (the innermost last), the
	## scopes around the code being compiled, innermost last, as `Resolve`
	## counted them, and, in the function being compiled, the statements a
	## `break` or a `continue` may leave and the `try`s around the code.
	State : {
		codes : List(Bytecode.Code),
		functions : List(Compile.Function),
		scopes : List(Compile.Scope),
		breakables : List(Compile.Breakable),
		tries : List(Compile.TryRegion),
	}

	## A statement a `break` may leave, or a loop a `continue` may go on: its
	## labels, and how many `try`s were around it, which a `break` out of it
	## leaves first.
	Breakable : { kind : [Loop, Switch, Labelled], labels : List(U64), tries : U64 }

	## A `try` around the code being compiled: whether its handler waits on the
	## VM's handler stack, its `finally`, which every way out of it runs, and
	## how many scopes were around it, the scopes its `finally` is compiled in.
	TryRegion : { handler : [Waiting, Gone], finally : [Finally(Ast.Block), NoFinally], scopes : U64 }

	## How a pattern's leaves take their values: declared, or assigned as `=`
	## assigns; what gave the value, for the message when it can't be taken
	## apart; and where.
	PatternBinding : { how : [Declaring, Assigning], origin : ValueRules.Origin, at : Ast.Where }

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

	## An instruction, or a jump its statement has yet to place: a `break`
	## out of the breakable at that place among the function's (`Exit`), a
	## `continue` of the loop at that place (`Next`), or an optional link's
	## end of its chain (`Short`).
	Emitted : [Do(Bytecode.Op), Exit(U64), Next(U64), Short]

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

# A run's code from its emitted list: every `break`, `continue` and optional
# link has been made a jump by its statement or its chain by the time its
# function is finished.
finished_ops : List(Compile.Emitted) -> List(Bytecode.Op)
finished_ops = |emitted|
	emitted.map(
		|each| match each {
			Do(op) => op
			Exit(_) | Next(_) => crash "Compile.finished_ops: a breakable resolves every break and continue inside it"
			Short => crash "Compile.finished_ops: a chain resolves every optional link inside it"
		},
	)

finished_code : Compile.State, { ops : List(Compile.Emitted), arguments : Bytecode.Arguments } -> Bytecode.Code
finished_code = |state, { ops, arguments }| {
	function = state.functions.last() ?? crash "Compile.finished_code: a function is being compiled"
	{
		ops: finished_ops(ops),
		frame_size: function.slots,
		arguments: arguments,
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

# A breakable's code with its own `break`s and `continue`s made jumps: `ops`
# starts at `offset` in the breakable's code, whose end is `exit` and, for a
# loop, whose next pass starts at `next`. The breakable is the one at
# `target` among the function's; those inside resolved their own before, and
# those around it resolve theirs after.
resolved : List(Compile.Emitted), { offset : U64, exit : U64, next : [Continues(U64), NoContinue], target : U64 } -> List(Compile.Emitted)
resolved = |ops, { offset, exit, next, target }|
	ops.map_with_index(
		|each, index| match each {
			Exit(place) if place == target => Do(jump_to(offset + index, exit))
			Next(place) if place == target => match next {
				Continues(start) => Do(jump_to(offset + index, start))
				NoContinue => crash "Compile.resolved: a continue names a loop"
			}
			done => done
		},
	)

# The state inside one more breakable, and its place among the function's.
breakable_entered : Compile.State, { kind : [Loop, Switch, Labelled], labels : List(U64) } -> { state : Compile.State, target : U64 }
breakable_entered = |state, { kind, labels }| {
	target = state.breakables.len()
	breakable = { kind: kind, labels: labels, tries: state.tries.len() }
	{ state: { ..state, breakables: state.breakables.append(breakable) }, target: target }
}

breakable_left : Compile.State -> Compile.State
breakable_left = |state| { ..state, breakables: state.breakables.drop_last(1) }

# The place among the function's breakables of the one a `break` or a
# `continue` leaves: the innermost loop (or `switch`, for a `break`), or the
# innermost with the label.
exit_target : Compile.State, { leaving : [Breaking, Continuing], label : Ast.Label } -> U64
exit_target = |state, { leaving, label }| {
	var $found = NotFound
	var $place = 0
	for breakable in state.breakables {
		fits = match (leaving, label) {
			(Breaking, Unlabelled) => breakable.kind != Labelled
			(Continuing, Unlabelled) => breakable.kind == Loop
			(Breaking, Named(name)) => breakable.labels.contains(name)
			(Continuing, Named(name)) => breakable.kind == Loop and breakable.labels.contains(name)
		}
		if fits {
			$found = Found($place)
		}
		$place = $place + 1
	}
	match $found {
		Found(place) => place
		NotFound => crash "Compile.exit_target: Parser.statement refuses a break or a continue with nothing to leave"
	}
}

# The code that leaves the `try`s around the code being compiled, from the
# innermost out, down to the `down_to`th: each handler still waiting taken
# off, and each `finally` run, compiled in the `try`s around it.
tries_left : Compile.State, U64 -> Try(Compile.Compiled, [Unsupported(Str)])
tries_left = |state, down_to| {
	tries = state.tries
	var $state = state
	var $ops = []
	var $at = tries.len()
	while $at > down_to {
		$at = $at - 1
		region = tries.get($at) ?? crash "Compile.tries_left: a try around the code"
		leave = match region.handler {
			Waiting => [Do(LeaveTry)]
			Gone => []
		}
		$ops = List.concat($ops, leave)
		match region.finally {
			Finally(final_block) => {
				scopes = $state.scopes
				done = block({ ..$state, tries: tries.take_first($at), scopes: scopes.take_first(region.scopes) }, final_block)?
				$state = { ..done.state, tries: tries, scopes: scopes }
				$ops = List.concat($ops, done.ops)
			}
			NoFinally => {}
		}
	}
	compiled($state, $ops)
}

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
			leaving = tries_left(done.state, 0)?
			compiled(leaving.state, List.concat(done.ops, leaving.ops).append(Do(Return)))
		}
		Throw(tree, site) => {
			done = expression_compiled(state, tree)?
			compiled(done.state, done.ops.append(Do(Throw(site))))
		}
		Try(tree) => try_compiled(state, tree)
		Switch(tree) => switch_compiled(state, tree)
		Break(label) => exit_compiled(state, { leaving: Breaking, label: label })
		Continue(label) => exit_compiled(state, { leaving: Continuing, label: label })
		Labelled(label, inner) => {
			{ state: inside, target } = breakable_entered(state, { kind: Labelled, labels: [label] })
			done = statement_compiled(inside, inner)?
			ops = resolved(done.ops, { offset: 0, exit: done.ops.len(), next: NoContinue, target: target })
			compiled(breakable_left(done.state), ops)
		}
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
		match (declarator.pattern, declarator.init) {
			(Leaf(ToName(_, slot, _)), init) => {
				value = match init {
					Initialized(tree) => expression_compiled($state, tree)?
					Uninitialized => { state: $state, ops: [Do(PushUndefined)] }
				}
				declared = declaration_ops(value.state, slot)
				$state = with_ready(declared.state, slot)
				$ops = List.concat(List.concat($ops, value.ops), declared.ops)
			}
			(pattern, Initialized(tree)) => {
				value = expression_compiled($state, tree)?
				bound = pattern_bound(value.state, pattern, { how: Declaring, origin: Written(tree), at: declarator.at })?
				$state = bound.state
				$ops = List.concat(List.concat($ops, value.ops), bound.ops)
			}
			(_, Uninitialized) => crash "Compile.declarations: Parser.declarators gives every pattern a value"
		}
	}
	compiled($state, $ops)
}

# A `break` or a `continue`: the `try`s between it and what it leaves left,
# then the jump its breakable places.
exit_compiled : Compile.State, { leaving : [Breaking, Continuing], label : Ast.Label } -> Try(Compile.Compiled, [Unsupported(Str)])
exit_compiled = |state, { leaving, label }| {
	target = exit_target(state, { leaving: leaving, label: label })
	breakable = state.breakables.get(target) ?? crash "Compile.exit_compiled: a breakable the compiler has"
	left = tries_left(state, breakable.tries)?
	jump = match leaving {
		Breaking => Exit(target)
		Continuing => Next(target)
	}
	compiled(left.state, left.ops.append(jump))
}

# A `while`, its test before each pass, or a `do ... while`, after.
while_loop : Compile.State, Ast.WhileLoop -> Try(Compile.Compiled, [Unsupported(Str)])
while_loop = |state, { test, body, order, labels }| {
	tested = expression_compiled(state, test)?
	{ state: inside, target } = breakable_entered(tested.state, { kind: Loop, labels: labels })
	passed = statement_compiled(inside, body)?
	t = tested.ops.len()
	b = passed.ops.len()
	ops = match order {
		TestFirst => {
			# test, JumpIfFalse, body, Loop
			total = t + 1 + b + 1
			List.concat(
				tested.ops.append(Do(JumpIfFalse(b + 1))),
				resolved(passed.ops, { offset: t + 1, exit: total, next: Continues(0), target: target }),
			).append(Do(Loop(total)))
		}
		TestAfter => {
			# body, test, JumpIfFalse, Loop
			total = b + t + 2
			List.concat(
				resolved(passed.ops, { offset: 0, exit: total, next: Continues(b), target: target }),
				tested.ops,
			).append(Do(JumpIfFalse(1))).append(Do(Loop(total)))
		}
	}
	compiled(breakable_left(passed.state), ops)
}

for_loop : Compile.State, Ast.ForLoop -> Try(Compile.Compiled, [Unsupported(Str)])
for_loop = |state, loop| {
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
	{ state: inside, target } = breakable_entered(tested_state, { kind: Loop, labels: loop.labels })
	body_done = statement_compiled(inside, loop.body)?
	passed = { ..body_done, state: breakable_left(body_done.state) }
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
		List.concat(check_ops, resolved(passed.ops, { offset: check, exit: total, next: Continues(check + b), target: target })),
		tail,
	).append(Do(Loop(total)))
	compiled(left_scope(updated.state), List.concat(head, ops))
}

for_of_loop : Compile.State, Ast.ForOfLoop -> Try(Compile.Compiled, [Unsupported(Str)])
for_of_loop = |state, loop| {
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
	declared = pattern_bound(entered.state, loop.pattern, { how: Declaring, origin: Nested, at: loop.at })?
	{ state: inside, target } = breakable_entered(declared.state, { kind: Loop, labels: loop.labels })
	passed = statement_compiled(inside, loop.body)?
	pass = List.concat(List.concat(entered.ops, declared.ops), passed.ops)
	# IterNext, the pass, Loop
	total = 1 + pass.len() + 1
	start = List.concat(
		[Do(IterNext({ slot: hidden, exit: pass.len() + 1 }))],
		resolved(pass, { offset: 1, exit: total, next: Continues(0), target: target }),
	)
	compiled(left_scope(breakable_left(passed.state)), List.concat(head, start.append(Do(Loop(total)))))
}

# A `try`. Its block runs under a handler; a throw lands at the `catch`,
# under a handler of its own when there is a `finally`, or at the
# `finally`'s code for a throw, which holds the throw in three slots, runs,
# and throws it again. Every way out of the block or the `catch` but a throw
# runs the `finally`'s code on the way: the end of the block, a `return`, a
# `break` or a `continue` (`tries_left`).
#
#     EnterTry(Catching), block, LeaveTry, Jump to the end's finally
#     catch:   EnterTry(Finishing), bind, body, LeaveTry, Jump to it
#     thrown:  the throw held, finally, the throw thrown again
#     end:     finally
try_compiled : Compile.State, Ast.TryStatement -> Try(Compile.Compiled, [Unsupported(Str)])
try_compiled = |state, { block: tried, handler, finalizer }| {
	outer = state.tries
	has_finally = match finalizer {
		Finally(_) => True
		NoFinally => False
	}
	level = state.scopes.len()
	tried_done = block({ ..state, tries: outer.append({ handler: Waiting, finally: finalizer, scopes: level }) }, tried)?
	after_tried = { ..tried_done.state, tries: outer }
	caught = match handler {
		Caught(clause) => {
			waiting = if has_finally {
				Waiting
			} else {
				Gone
			}
			done = catch_compiled({ ..after_tried, tries: outer.append({ handler: waiting, finally: finalizer, scopes: level }) }, clause)?
			Caught({ state: { ..done.state, tries: outer }, ops: done.ops })
		}
		Uncaught => Uncaught
	}
	after_caught = match caught {
		Caught(done) => done.state
		Uncaught => after_tried
	}
	match finalizer {
		NoFinally => match caught {
			Caught(done) => {
				a = tried_done.ops
				b = done.ops
				ops = List.concat(
					List.concat([Do(EnterTry({ handler: a.len() + 2, kind: Catching }))], a).append(Do(LeaveTry)).append(Do(Jump(b.len()))),
					b,
				)
				compiled(after_caught, ops)
			}
			Uncaught => crash "Compile.try_compiled: Parser.statement gives a try a catch or a finally"
		}
		Finally(final_block) => {
			{ state: placed, slot: held } = with_hidden_slots(after_caught, 3)
			on_throw = block(placed, final_block)?
			on_end = block(on_throw.state, final_block)?
			thrown = List.concat(
				ops_of([SetLocal(held + 2), SetLocal(held + 1), SetLocal(held)]),
				on_throw.ops,
			).append(Do(LoadLocal(held))).append(Do(LoadLocal(held + 1))).append(Do(LoadLocal(held + 2))).append(Do(Rethrow))
			a = tried_done.ops
			caught_ops = match caught {
				Caught(done) => {
					b = done.ops
					List.concat([Do(EnterTry({ handler: b.len() + 2, kind: Finishing }))], b).append(Do(LeaveTry)).append(Do(Jump(thrown.len())))
				}
				Uncaught => []
			}
			first_kind = match caught {
				Caught(_) => Catching
				Uncaught => Finishing
			}
			tried_ops = List.concat([Do(EnterTry({ handler: a.len() + 2, kind: first_kind }))], a)
				.append(Do(LeaveTry))
				.append(Do(Jump(caught_ops.len() + thrown.len())))
			ops = List.concat(List.concat(List.concat(tried_ops, caught_ops), thrown), on_end.ops)
			compiled(on_end.state, ops)
		}
	}
}

# A `catch`, the value thrown on the stack: bound to its parameter in a
# scope of its own, or dropped, then its body.
catch_compiled : Compile.State, Ast.CatchClause -> Try(Compile.Compiled, [Unsupported(Str)])
catch_compiled = |state, clause|
	match clause.parameter {
		Unbound => {
			body = block(state, clause.body)?
			compiled(body.state, List.concat([Do(Pop)], body.ops))
		}
		Bound(pattern) => {
			entered = entered_scope(
				state,
				{
					names: clause.names,
					kinds: clause.names.map(|_| Mutable),
					parameters: 0,
					capture: clause.capture,
					boxes: AtEntry,
				},
			)
			bound = pattern_bound(entered.state, pattern, { how: Declaring, origin: Nested, at: clause.at })?
			body = block(bound.state, clause.body)?
			compiled(left_scope(body.state), List.concat(List.concat(entered.ops, bound.ops), body.ops))
		}
	}

# A `switch`. The value compared is held in a slot; each case's test is
# compared with it in order, and the first that is the same jumps to its
# statements, or, where none is, the `default`'s, and the statements fall
# through to the end.
#
# **A SWITCH'S VARIABLES ARE BOXED AND CHECKED WHEN THEY RUN.** A case may be
# entered past the declarations of the cases before it, so a read after a
# declaration in the text may still come before it at run time: each
# variable of the switch's scope lives in a box, ready to read at the
# compiler's word, which checks at run time.
switch_compiled : Compile.State, Ast.SwitchStatement -> Try(Compile.Compiled, [Unsupported(Str)])
switch_compiled = |state, switch| {
	subject = expression_compiled(state, switch.discriminant)?
	{ state: placed, slot: held } = with_hidden_slots(subject.state, 1)
	statements = switch.cases.join_map(|each| each.statements)
	entered = match switch.scoping {
		Scoped(names) => entered_scope(
			placed,
			{
				names: names,
				kinds: kinds_of(names, statements),
				parameters: names.len(),
				capture: Captures,
				boxes: AtEntry,
			},
		)
		Unscoped => { state: placed, ops: [] }
	}
	hoisted = hoisted_functions(entered.state, statements)?
	{ state: inside, target } = breakable_entered(hoisted.state, { kind: Switch, labels: [] })
	var $state = inside
	var $tests = []
	for each in switch.cases {
		match each.test {
			Matches(tree) => {
				done = expression_compiled($state, tree)?
				$state = done.state
				$tests = $tests.append(Tested(done.ops))
			}
			Otherwise => {
				$tests = $tests.append(Default)
			}
		}
	}
	var $bodies = []
	for each in switch.cases {
		done = statement_list($state, each.statements)?
		$state = done.state
		$bodies = $bodies.append(done.ops)
	}
	bodies = $bodies
	tests = $tests
	# Each case's test: the held value, the test, a jump to its statements.
	test_lengths = tests.map(
		|test| match test {
			Tested(ops) => ops.len() + 2
			Default => 0
		},
	)
	tests_length = test_lengths.sum() + 1
	body_starts = bodies.map_with_index(
		|_, index| bodies.take_first(index).map(|ops| ops.len()).sum(),
	)
	bodies_length = bodies.map(|ops| ops.len()).sum()
	var $test_ops = []
	var $at = 0
	var $default = NoDefault
	var $index = 0
	for test in tests {
		match test {
			Tested(ops) => {
				$at = $at + ops.len() + 2
				start = tests_length + (body_starts.get($index) ?? crash "Compile.switch_compiled: a case's statements")
				$test_ops = List.concat(List.concat($test_ops, [Do(LoadLocal(held))]), ops).append(Do(JumpIfSame(start - $at)))
			}
			Default => {
				$default = DefaultAt(body_starts.get($index) ?? crash "Compile.switch_compiled: a case's statements")
			}
		}
		$index = $index + 1
	}
	# Past the tests: to the default's statements, or past them all.
	otherwise = match $default {
		DefaultAt(start) => start
		NoDefault => bodies_length
	}
	test_ops = $test_ops.append(Do(Jump(otherwise)))
	body_ops = resolved(bodies.join_map(|ops| ops), { offset: 0, exit: bodies_length, next: NoContinue, target: target })
	done_state = breakable_left($state)
	left = match switch.scoping {
		Scoped(_) => left_scope(done_state)
		Unscoped => done_state
	}
	head = List.concat(List.concat(subject.ops, [Do(SetLocal(held))]), List.concat(entered.ops, hoisted.ops))
	compiled(left, List.concat(List.concat(head, test_ops), body_ops))
}

# ---- patterns --------------------------------------------------------------

# The value on the stack taken apart by `pattern`, its leaves bound as
# `binding` says, and taken off the stack.
pattern_bound : Compile.State, Ast.Pattern, Compile.PatternBinding -> Try(Compile.Compiled, [Unsupported(Str)])
pattern_bound = |state, pattern, binding|
	match pattern {
		Leaf(target) => leaf_bound(state, target, binding)
		ArrayPattern(items, rest) => {
			{ state: placed, slot: walked } = with_hidden_slots(state, 1)
			var $state = placed
			var $ops = ops_of([DestructureItems({ origin: binding.origin, at: binding.at }), SetLocal(walked)])
			var $i = 0
			for item in items {
				match item {
					Hole => {}
					Item(inner, default) => {
						given = defaulted($state, default)?
						bound = pattern_bound(given.state, inner, { ..binding, origin: Nested })?
						$state = bound.state
						$ops = List.concat(List.concat($ops, ops_of([LoadLocal(walked), ItemOf($i)])), List.concat(given.ops, bound.ops))
					}
				}
				$i = $i + 1
			}
			match rest {
				NoRest => compiled($state, $ops)
				RestOf(inner) => {
					bound = pattern_bound($state, inner, { ..binding, origin: Nested })?
					compiled(bound.state, List.concat(List.concat($ops, ops_of([LoadLocal(walked), ItemsFrom($i)])), bound.ops))
				}
			}
		}
		ObjectPattern(properties, rest) => {
			{ state: placed, slot: held } = with_hidden_slots(state, 1)
			var $state = placed
			var $ops = ops_of([
				CheckDestructurable({ properties: properties, origin: binding.origin, at: binding.at }),
				SetLocal(held),
			])
			for part in properties {
				given = defaulted($state, part.default)?
				bound = pattern_bound(given.state, part.pattern, { ..binding, origin: Nested })?
				$state = bound.state
				$ops = List.concat(List.concat($ops, ops_of([LoadLocal(held), GetProperty(part.key, binding.at)])), List.concat(given.ops, bound.ops))
			}
			match rest {
				NoRest => compiled($state, $ops)
				RestOf(inner) => {
					bound = pattern_bound($state, inner, { ..binding, origin: Nested })?
					left = PropertiesLeft({ keys: properties.map(|part| part.key), at: binding.at })
					compiled(bound.state, List.concat(List.concat($ops, ops_of([LoadLocal(held), left])), bound.ops))
				}
			}
		}
	}

# A default's code, the value given on the stack: kept unless it is
# `undefined`, which `SkipIfNotUndefined` drops for the default's value to
# take its place.
defaulted : Compile.State, Ast.Default -> Try(Compile.Compiled, [Unsupported(Str)])
defaulted = |state, default|
	match default {
		NoDefault => compiled(state, [])
		Defaulted(tree) => {
			done = expression_compiled(state, tree)?
			compiled(done.state, List.concat([Do(SkipIfNotUndefined(done.ops.len()))], done.ops))
		}
	}

leaf_bound : Compile.State, Ast.Target, Compile.PatternBinding -> Try(Compile.Compiled, [Unsupported(Str)])
leaf_bound = |state, target, binding|
	match (binding.how, target) {
		(Declaring, ToName(_, slot, _)) => {
			declared = declaration_ops(state, slot)
			compiled(with_ready(declared.state, slot), declared.ops)
		}
		(Declaring, _) => crash "Compile.leaf_bound: Parser.pattern declares names alone"
		(Assigning, ToName(name, slot, at)) => {
			{ state: placed, reached } = reached_of(state, slot)
			if reached == Undeclared {
				compiled(placed, [Do(undeclared_refusal(name, at))])
			} else {
				compiled(placed, ops_of([name_write(reached, { name: name, at: at }), Pop]))
			}
		}
		(Assigning, ToMember(object, key)) => {
			holder = expression_compiled(state, object)?
			compiled(holder.state, List.concat(holder.ops, ops_of([Swap, SetProperty(key, binding.at), Pop])))
		}
		(Assigning, ToIndex(object, key)) => {
			holder = expression_compiled(state, object)?
			keyed = expression_compiled(holder.state, key)?
			compiled(keyed.state, List.concat(List.concat(holder.ops, keyed.ops), ops_of([Rotate, SetIndex(binding.at), Pop])))
		}
	}

# ---- functions -------------------------------------------------------------

# The closure-making instruction of a function literal, its code compiled
# and added to the program's.
function_made : Compile.State, Box(Ast.FunctionDefinition) -> Try({ state : Compile.State, op : Bytecode.Op }, [Unsupported(Str)])
function_made = |state, boxed| {
	definition = boxed.unbox()
	ready = match definition.binding {
		Plain => definition.parameters.len()
		Patterned(_) => 0
	}
	inner = { ..state, functions: state.functions.append(no_function_yet), breakables: [], tries: [] }
	entered = entered_scope(
		inner,
		{
			names: definition.names,
			kinds: kinds_of(definition.names, definition.statements),
			parameters: ready,
			capture: definition.capture,
			boxes: AtCall,
		},
	)
	taken = match definition.binding {
		Plain => { state: entered.state, ops: [], arguments: Each(ready) }
		Patterned(patterns) => {
			{ state: placed, slot: packed } = with_hidden_slots(entered.state, 1)
			bound = parameters_bound(placed, { patterns: patterns, packed: packed, at: definition.at })?
			{ state: bound.state, ops: bound.ops, arguments: Packed(packed) }
		}
	}
	body = block_body(taken.state, definition.statements)?
	done = body.state
	code = finished_code(
		done,
		{
			ops: List.concat(taken.ops, body.ops).append(Do(PushUndefined)).append(Do(Return)),
			arguments: taken.arguments,
		},
	)
	function = done.functions.last() ?? crash "Compile.function_made: the function is being compiled"
	Ok({
		state: {
			codes: done.codes.append(code),
			functions: done.functions.drop_last(1),
			scopes: done.scopes.drop_last(1),
			breakables: state.breakables,
			tries: state.tries,
		},
		op: MakeClosure({ code: done.codes.len(), captures: function.captures.map(|c| c.from), definition: boxed }),
	})
}

# The code that binds a function's patterned parameters from its arguments,
# which the call packed into an array in the slot `packed`: each pattern
# given its argument, or its default where that is `undefined`, then the
# rest parameter the arguments left. A failure names the function's own
# line, where node points.
parameters_bound : Compile.State, { patterns : { items : List(Ast.Parameter), rest : Ast.Rest }, packed : U64, at : Ast.Where } -> Try(Compile.Compiled, [Unsupported(Str)])
parameters_bound = |state, { patterns, packed, at }| {
	var $state = state
	var $ops = []
	var $i = 0
	for item in patterns.items {
		given = defaulted($state, item.default)?
		bound = pattern_bound(given.state, item.pattern, { how: Declaring, origin: Argument, at: at })?
		$state = bound.state
		$ops = List.concat(List.concat($ops, ops_of([LoadLocal(packed), ItemOf($i)])), List.concat(given.ops, bound.ops))
		$i = $i + 1
	}
	match patterns.rest {
		NoRest => compiled($state, $ops)
		RestOf(inner) => {
			bound = pattern_bound($state, inner, { how: Declaring, origin: Nested, at: at })?
			compiled(bound.state, List.concat(List.concat($ops, ops_of([LoadLocal(packed), ItemsFrom($i)])), bound.ops))
		}
	}
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
		Instance(classes) => compiled(state, [Do(NewInstance(classes))])
		InstanceOf(value, class, name, _) => {
			first = expression_compiled(state, value)?
			second = expression_compiled(first.state, class)?
			compiled(second.state, List.concat(first.ops, second.ops).append(Do(InstanceOf(name))))
		}
		Chain(chain) => {
			done = link_compiled(state, chain)?
			end = done.ops.len()
			ops = done.ops.map_with_index(
				|each, index| match each {
					Short => Do(ShortIfNullish(end - index - 1))
					other => other
				},
			)
			compiled(done.state, ops)
		}
		OptionalMember(_, _, _) | OptionalIndex(_, _, _) | OptionalCall(_, _, _) => crash "Compile.expression_compiled: Parser.call_or_member puts an optional link inside a Chain"
		Destructure(pattern, value, site) => {
			made = expression_compiled(state, value)?
			bound = pattern_bound(made.state, pattern, { how: Assigning, origin: Written(value), at: site })?
			compiled(bound.state, List.concat(made.ops.append(Do(Duplicate)), bound.ops))
		}
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

# The old value a compound assignment combines: an unready variable's is
# undefined, the error coming at the write.
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

# ---- optional chains -------------------------------------------------------

# One link of an optional chain, its object's links first: an optional link
# whose object is `null` or `undefined` ends the chain (`Short`), which the
# chain makes a jump to its end, where the chain's value is `undefined`.
link_compiled : Compile.State, Ast.Expression -> Try(Compile.Compiled, [Unsupported(Str)])
link_compiled = |state, tree|
	match tree {
		Member(object, key, site) | OptionalMember(object, key, site) => {
			holder = link_compiled(state, object)?
			compiled(holder.state, List.concat(holder.ops, short_if_optional(tree)).append(Do(GetProperty(key, site))))
		}
		Index(object, key, site) | OptionalIndex(object, key, site) => {
			holder = link_compiled(state, object)?
			keyed = expression_compiled(holder.state, key)?
			compiled(keyed.state, List.concat(List.concat(holder.ops, short_if_optional(tree)), keyed.ops).append(Do(GetIndex(site))))
		}
		Call(callee, arguments, site) | OptionalCall(callee, arguments, site) => chain_call(
			state,
			{ callee: callee, arguments: arguments, optional: is_optional_link(tree), at: site },
		)
		_ => expression_compiled(state, tree)
	}

is_optional_link : Ast.Expression -> Bool
is_optional_link = |tree|
	match tree {
		OptionalMember(_, _, _) | OptionalIndex(_, _, _) | OptionalCall(_, _, _) => True
		_ => False
	}

short_if_optional : Ast.Expression -> List(Compile.Emitted)
short_if_optional = |tree|
	if is_optional_link(tree) {
		[Short]
	} else {
		[]
	}

# A call in a chain. A method's object is the link before it, so `o?.f()`
# ends where `o` is nothing; an optional call (`f?.()`, `o.f?.()`) ends where
# the function is, and calls it as a plain call.
chain_call : Compile.State, { callee : Ast.Expression, arguments : List(Ast.Element), optional : Bool, at : Ast.Where } -> Try(Compile.Compiled, [Unsupported(Str)])
chain_call = |state, { callee, arguments, optional, at }| {
	written = ValueRules.source_text(callee)
	spreads = arguments.any(|argument| is_spread(argument))
	plain_call = if spreads {
		CallSpread({ written: written, at: at })
	} else {
		Call({ count: arguments.len(), written: written, at: at })
	}
	match callee {
		Member(object, name, _) | OptionalMember(object, name, _) => {
			holder = link_compiled(state, object)?
			reached = List.concat(holder.ops, short_if_optional(callee))
			given = if spreads {
				elements_array(holder.state, arguments)?
			} else {
				singles(holder.state, arguments)?
			}
			if optional {
				function = reached.append(Do(GetProperty(name, at))).append(Short)
				compiled(given.state, List.concat(function, given.ops).append(Do(plain_call)))
			} else {
				call = if spreads {
					CallMethodSpread({ name: name, written: written, at: at })
				} else {
					CallMethod({ name: name, site: { count: arguments.len(), written: written, at: at } })
				}
				compiled(given.state, List.concat(reached.append(Do(MethodLookup(name, at))), given.ops).append(Do(call)))
			}
		}
		_ => {
			function = link_compiled(state, callee)?
			given = if spreads {
				elements_array(function.state, arguments)?
			} else {
				singles(function.state, arguments)?
			}
			short = if optional {
				[Short]
			} else {
				[]
			}
			compiled(given.state, List.concat(List.concat(function.ops, short), given.ops).append(Do(plain_call)))
		}
	}
}
