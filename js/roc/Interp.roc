## This module runs a parsed JavaScript program by walking its tree.
##
## **THE WHOLE MACHINE IS ONE VALUE, `St`, THREADED THROUGH THE WALK.** Every
## evaluation takes the machine and answers it back beside its value (`Got`),
## and every statement answers it back beside how control leaves the
## statement (`Done`). JavaScript shares arrays, objects and closures by
## reference, so they live in the heap (`Heap`), a list of cells named by
## index; scopes live in a second list, because a closure holds on to the
## scope it was made in and sees later writes to it.
##
## **NOTHING HOLDS THE MACHINE BUT THE WALK.** Roc writes a list in place only
## while nothing else refers to it, so a single stray reference to the heap
## makes every property write copy the whole heap. The rules that keep it
## unique:
## - No closure in this module captures the machine or a part of it; loops
##   over the machine are `var $st` loops, never a `walk` with a lambda.
## - A write passes the list straight from the record it updates,
##   `{ ..machine, cells: Heap.with_prop(st.cells, ...) }`, so the old machine is
##   never read after the write that consumes it.
## - Every `Got` and `Done` is taken apart where it is answered,
##   `{ st: after, val } = Interp.eval(st, e)`, never kept whole while its
##   machine goes on to be written: a record kept for its `val` keeps its
##   `st` too, a second reference to the heap and the scopes, and each
##   write made while it lives copies them. Kept whole, a store into an
##   array copied the array and a closure's `++c` copied every scope.
## - A writer asks `Interp.kind_of` what a cell is, never matches the cell
##   out of the heap: the matched cell refers to its props or items for as
##   long as the arm runs.
##
## **A VARIABLE IS READ BY ITS PLACE, NEVER BY ITS NAME.** `Resolve` gives
## every name its slot before the run: how many scopes out its variable is,
## and where among that scope's variables. Each scope is made with every
## variable its layout names, unready until its declaration runs, so a slot
## always names a variable the scope has.
##
## **A SCOPE THAT NOTHING CAN CAPTURE IS DROPPED WHEN ITS BLOCK ENDS.** The
## parser marks each block and function whose text holds no function literal
## (`CapturesNothing`), and such a scope, the last in the list when its block
## ends, is dropped, so a loop or a recursion without closures leaves the
## scope list as it found it. Scopes that may be captured, and every cell,
## live until the run ends.
##
## A fault (a TypeError, a feature outside the subset, the step budget) stops
## the run: `fault` is set, every statement after it is skipped, and the
## message is the run's last line.
import Ast
import Heap
import Inspect
import NumberText

Interp :: [].{
	VariableState : [Mutable, Fixed, Unready]

	Variable : { value : Heap.Value, state : Interp.VariableState }

	Parent : [Outermost, Within(U64)]

	Scope : { variables : List(Interp.Variable), parent : Interp.Parent }

	Status : [Running, Faulted(Str)]

	Machine : {
		cells : List(Heap.Cell),
		scopes : List(Interp.Scope),
		# How many of `scopes` are alive: the ones past it are dead slots, which
		# the next scope entered reuses.
		live_scopes : U64,
		scope : U64,
		out : Str,
		steps : U64,
		step_limit : U64,
		depth : U64,
		status : Interp.Status,
	}

	Got : { machine : Interp.Machine, value : Heap.Value }

	Flow : [Normal, Broke, Continued, Returned(Heap.Value)]

	Done : { machine : Interp.Machine, flow : Interp.Flow }

	# The deepest JavaScript call the interpreter makes before it reports a
	# stack overflow, as node does, rather than overflow Roc's own stack.
	max_depth : U64
	max_depth = 400

	# ---- the run ---------------------------------------------------------------

	Outcome : {
		out : Str,
		steps : U64,
		cells : U64,
		scopes : U64,
		status : Interp.Status,
	}

	run : Ast.Program, U64 -> Interp.Outcome
	run = |program, step_limit| {
		fresh = Interp.with_globals({
			cells: [],
			scopes: [],
			live_scopes: 0,
			scope: 0,
			out: "",
			steps: 0,
			step_limit: step_limit,
			depth: 0,
			status: Running,
		})
		done = Interp.execute_block(fresh, program)
		machine = done.machine
		{
			out: machine.out,
			steps: machine.steps,
			cells: machine.cells.len(),
			scopes: machine.live_scopes,
			status: machine.status,
		}
	}

	# The machine with the outermost scope holding the builtins.
	with_globals : Interp.Machine -> Interp.Machine
	with_globals = |machine| {
		var $s = {
			..machine,
			scopes: machine.scopes.append({ variables: [], parent: Outermost }),
			live_scopes: 1,
			scope: 0,
		}
		log = Interp.alloc($s, Builtin(Log, []))
		$s = log.machine
		console = Interp.alloc($s, Namespace("console", [{ key: "log", value: log.value }]))
		$s = console.machine
		var $math_properties = [
			{ key: "PI", value: Number(3.141592653589793) },
			{ key: "E", value: Number(2.718281828459045) },
		]
		for n in [Floor, Ceil, Round, Trunc, Abs, Sign, Sqrt, Pow, Min, Max, Sin, Cos, Tan, Atan] {
			f = Interp.alloc($s, Builtin(n, []))
			$s = f.machine
			$math_properties = $math_properties.append({ key: Heap.native_name(n), value: f.value })
		}
		math_object = Interp.alloc($s, Namespace("Math", $math_properties))
		$s = math_object.machine
		var $object_properties = []
		for n in [Keys, Values, Entries] {
			f = Interp.alloc($s, Builtin(n, []))
			$s = f.machine
			$object_properties = $object_properties.append({ key: Heap.native_name(n), value: f.value })
		}
		object = Interp.alloc($s, Namespace("Object", $object_properties))
		$s = object.machine
		from_char_code = Interp.alloc($s, Builtin(FromCharCode, []))
		$s = from_char_code.machine
		string = Interp.alloc(
			$s,
			Builtin(StringOf, [{ key: "fromCharCode", value: from_char_code.value }]),
		)
		$s = string.machine
		is_array = Interp.alloc($s, Builtin(IsArray, []))
		$s = is_array.machine
		array = Interp.alloc($s, Namespace("Array", [{ key: "isArray", value: is_array.value }]))
		$s = array.machine
		is_integer = Interp.alloc($s, Builtin(IsInteger, []))
		$s = is_integer.machine
		number = Interp.alloc(
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
		made = [
			{ name: "console", value: console.value },
			{ name: "Math", value: math_object.value },
			{ name: "Object", value: object.value },
			{ name: "String", value: string.value },
			{ name: "Array", value: array.value },
			{ name: "Number", value: number.value },
			{ name: "NaN", value: Number(0.0 / 0.0) },
			{ name: "Infinity", value: Number(1.0 / 0.0) },
		]
		# The builtins in the order `Resolve` places them.
		globals = Ast.global_names.map(
			|name| {
				value: (made.find_first(|g| g.name == name) ?? crash "Interp.with_globals: a builtin Ast.global_names names").value,
				state: Fixed,
			},
		)
		{ ..$s, scopes: [{ variables: globals, parent: Outermost }] }
	}

	alloc : Interp.Machine, Heap.Cell -> Interp.Got
	alloc = |machine, cell| {
		id = machine.cells.len()
		{ machine: { ..machine, cells: machine.cells.append(cell) }, value: Reference(id) }
	}

	is_running : Interp.Machine -> Bool
	is_running = |machine| machine.status == Running

	# The machine stopped with `why`, unless it had already stopped.
	faulted : Interp.Machine, Str -> Interp.Machine
	faulted = |machine, why|
		match machine.status {
			Running => { ..machine, status: Faulted(why) }
			Faulted(_) => machine
		}

	fault_got : Interp.Machine, Str -> Interp.Got
	fault_got = |machine, why| { machine: Interp.faulted(machine, why), value: Undefined }

	at_line : Ast.Where -> Str
	at_line = |w| " (line ${w.line.to_str()})"

	# ---- scopes ----------------------------------------------------------------

	# Where a slot's variable is: its scope and its place there.
	Place : [At({ scope : U64, index : U64 }), Nowhere]

	place_of : Interp.Machine, Ast.Slot -> Interp.Place
	place_of = |machine, slot|
		match slot {
			Local({ hops, index }) => At({
				scope: Interp.scope_out(machine.scopes, machine.scope, hops),
				index: index,
			})
			Global(index) => At({ scope: 0, index: index })
			Undeclared => Nowhere
			Unresolved => crash "Interp.place_of: Parser.program_of resolves every name"
		}

	# The scope `hops` parents out from `start`.
	scope_out : List(Interp.Scope), U64, U64 -> U64
	scope_out = |scopes, start, hops| {
		var $scope_id = start
		var $left = hops
		while $left > 0 {
			$scope_id = Interp.parent_of(scopes, $scope_id)
			$left = $left - 1
		}
		$scope_id
	}

	parent_of : List(Interp.Scope), U64 -> U64
	parent_of = |scopes, scope_id|
		match scopes.get(scope_id) {
			Ok({ parent: Within(p), variables: _ }) => p
			_ => crash "Interp.parent_of: Resolve counts no more scopes out than there are"
		}

	variable_at : List(Interp.Scope), U64, U64 -> Interp.Variable
	variable_at = |scopes, scope_id, index| {
		scope = scopes.get(scope_id) ?? crash "Interp.var_at: a scope the machine has"
		scope.variables.get(index) ?? crash "Interp.var_at: a variable its scope's layout names"
	}

	# A declaration's place in the scope it runs in.
	own_index : Ast.Slot -> U64
	own_index = |slot|
		match slot {
			Local({ hops: 0, index }) => index
			_ => crash "Interp.own_index: Resolve places a declaration in its own scope"
		}

	unready : Interp.Variable
	unready = { value: Undefined, state: Unready }

	# The scopes with one variable written in place: the scope is taken out,
	# written while nothing else refers to its vars, and put back.
	with_variable : List(Interp.Scope), U64, U64, Interp.Variable -> List(Interp.Scope)
	with_variable = |scopes, scope_id, index, binding| {
		taken = scopes.replace(
			scope_id,
			{ variables: [], parent: Outermost },
		) ?? crash "Interp.with_var: a scope the machine has"
		taken.list.set(
			scope_id,
			Interp.scope_with_variable(taken.prev, index, binding),
		) ?? crash "Interp.with_var: the scope was just taken"
	}

	# **THE WRITE IS A FUNCTION OF ITS OWN**, handed the scope taken out. Made
	# inline, beside the scope's other uses, the write copied the scope list:
	# a closure's `++c`, with N closures alive, cost N.
	scope_with_variable : Interp.Scope, U64, Interp.Variable -> Interp.Scope
	scope_with_variable = |scope, index, binding| {
		{ variables, parent } = scope
		{
			variables: variables.set(
				index,
				binding,
			) ?? crash "Interp.scope_with_var: a variable the scope has",
			parent: parent,
		}
	}

	# The machine with a variable of its current scope declared.
	declare : Interp.Machine, Ast.Slot, Heap.Value, Interp.VariableState -> Interp.Machine
	declare = |machine, slot, value, state| {
		..machine,
		scopes: Interp.with_variable(
			machine.scopes,
			machine.scope,
			Interp.own_index(slot),
			{ value: value, state: state },
		),
	}

	# The machine inside a new scope whose parent is `parent`, holding `size`
	# variables, none of them ready.
	entered : Interp.Machine, Interp.Parent, U64 -> Interp.Machine
	entered = |machine, parent, size| Interp.with_scope_added(
		machine,
		{ variables: List.repeat(Interp.unready, size), parent: parent },
	)

	# The machine inside `scope`, a new one, in the first dead slot or past the
	# end.
	#
	# **A DROPPED SCOPE'S SLOT IS REUSED, AND THE LIST NEVER SHRINKS.**
	# `List.drop_last` is a `sublist`, and the list it answers refers to the
	# old one's memory: the next append copied the whole scope list, so each
	# call of a closure, beside N scopes kept alive by other closures, cost N.
	with_scope_added : Interp.Machine, Interp.Scope -> Interp.Machine
	with_scope_added = |machine, scope| {
		id = machine.live_scopes
		{
			..machine,
			scopes: Interp.scopes_with(machine.scopes, id, scope),
			live_scopes: id + 1,
			scope: id,
		}
	}

	scopes_with : List(Interp.Scope), U64, Interp.Scope -> List(Interp.Scope)
	scopes_with = |scopes, id, scope|
		if id < scopes.len() {
			scopes.set(id, scope) ?? crash "Interp.scopes_with: a slot the list has"
		} else {
			scopes.append(scope)
		}

	# The machine back in scope `outer`, the scope `inner` dropped when nothing
	# can have captured it and it is the last one alive.
	left : Interp.Machine, U64, U64, Ast.Capture -> Interp.Machine
	left = |machine, inner, outer, capture| {
		drops = capture == CapturesNothing and inner + 1 == machine.live_scopes
		if drops {
			{ ..machine, live_scopes: inner, scope: outer }
		} else {
			{ ..machine, scope: outer }
		}
	}

	# The functions a block declares, made before its first statement. Its
	# `let` and `const` names stay unready until their statement runs.
	hoisted : Interp.Machine, List(Ast.Statement) -> Interp.Machine
	hoisted = |machine, statements| {
		var $s = machine
		for stmt in statements {
			match stmt {
				FunctionDeclaration(definition, slot) => {
					{ machine: made, value: f } = Interp.alloc($s, Fun({ fun: definition, scope: $s.scope }))
					$s = Interp.declare(made, slot, f, Mutable)
				}
				_ => {}
			}
		}
		$s
	}

	# ---- statements ------------------------------------------------------------

	normal : Interp.Machine -> Interp.Done
	normal = |machine| { machine: machine, flow: Normal }

	execute_block : Interp.Machine, Ast.Block -> Interp.Done
	execute_block = |machine, block|
		match block.scoping {
			Unscoped => Interp.execute_list(machine, block.statements)
			Scoped(names) => {
				outer = machine.scope
				inner = Interp.hoisted(Interp.entered(machine, Within(outer), names.len()), block.statements)
				id = inner.scope
				{ machine: after, flow } = Interp.execute_list(inner, block.statements)
				{ machine: Interp.left(after, id, outer, block.capture), flow: flow }
			}
		}

	execute_list : Interp.Machine, List(Ast.Statement) -> Interp.Done
	execute_list = |machine, statements| {
		var $s = machine
		var $flow = Normal
		for stmt in statements {
			if $flow == Normal and Interp.is_running($s) {
				{ machine: after, flow } = Interp.execute(Interp.ticked($s), stmt)
				$s = after
				$flow = flow
			}
		}
		{ machine: $s, flow: $flow }
	}

	# The machine one step on, stopped when it passes its step budget.
	ticked : Interp.Machine -> Interp.Machine
	ticked = |machine|
		if machine.steps >= machine.step_limit {
			Interp.faulted(machine, "the program ran past its budget of ${machine.step_limit.to_str()} steps")
		} else {
			{ ..machine, steps: machine.steps + 1 }
		}

	execute : Interp.Machine, Ast.Statement -> Interp.Done
	execute = |machine, stmt|
		match stmt {
			Expression(e) => {
				{ machine: after, value: _ } = Interp.evaluate(machine, e)
				Interp.normal(after)
			}
			Declare(binding, declarations) => {
				var $s = machine
				for d in declarations {
					if Interp.is_running($s) {
						{ machine: made, value } = match d.init {
							Initialized(e) => Interp.evaluate($s, e)
							Uninitialized => { machine: $s, value: Undefined }
						}
						state = match binding {
							Let => Mutable
							Const => Fixed
						}
						$s = Interp.declare(made, d.slot, value, state)
					}
				}
				Interp.normal($s)
			}
			FunctionDeclaration(_, _) => Interp.normal(machine)
			If(test, yes, no) => {
				{ machine: tested, value } = Interp.evaluate(machine, test)
				if !Interp.is_running(tested) {
					Interp.normal(tested)
				} else if Interp.is_truthy(value) {
					Interp.execute(tested, yes)
				} else {
					Interp.execute(tested, no)
				}
			}
			While(test, body) => Interp.execute_while(machine, test, body)
			For(loop) => Interp.execute_for(machine, loop)
			ForOf(loop) => Interp.execute_for_of(machine, loop)
			BlockStatement(block) => Interp.execute_block(machine, block)
			Return(e) => {
				{ machine: after, value } = Interp.evaluate(machine, e)
				{ machine: after, flow: Returned(value) }
			}
			Break => { machine: machine, flow: Broke }
			Continue => { machine: machine, flow: Continued }
			Empty => Interp.normal(machine)
		}

	# How a loop goes on after its body: on, or out with the flow the loop
	# itself answers.
	after_body : Interp.Flow -> [GoOn, Leave(Interp.Flow)]
	after_body = |flow| match flow {
		Normal => GoOn
		Continued => GoOn
		Broke => Leave(Normal)
		Returned(v) => Leave(Returned(v))
	}

	execute_while : Interp.Machine, Ast.Expression, Ast.Statement -> Interp.Done
	execute_while = |machine, test, body| {
		var $s = machine
		var $flow = Normal
		var $going = True
		while $going {
			{ machine: tested, value } = Interp.evaluate(Interp.ticked($s), test)
			if !Interp.is_running(tested) or !Interp.is_truthy(value) {
				$s = tested
				$going = False
			} else {
				{ machine: after, flow } = Interp.execute(tested, body)
				$s = after
				match Interp.after_body(flow) {
					GoOn => {
						$going = Interp.is_running($s)
					}
					Leave(f) => {
						$flow = f
						$going = False
					}
				}
			}
		}
		{ machine: $s, flow: $flow }
	}

	execute_for : Interp.Machine, Ast.ForLoop -> Interp.Done
	execute_for = |machine, loop| {
		outer = machine.scope
		start = Interp.entered(machine, Within(outer), loop.names.len())
		{ machine: begun, flow: _ } = Interp.execute(start, loop.init)
		var $s = begun
		var $flow = Normal
		var $going = Interp.is_running($s)
		while $going {
			{ machine: tested, value } = match loop.test {
				Tested(e) => Interp.evaluate(Interp.ticked($s), e)
				Always => { machine: Interp.ticked($s), value: Boolean(True) }
			}
			if !Interp.is_running(tested) or !Interp.is_truthy(value) {
				$s = tested
				$going = False
			} else {
				{ machine: after, flow } = Interp.execute(tested, loop.body)
				match Interp.after_body(flow) {
					GoOn => {
						# **EACH PASS HAS ITS OWN `let`**, as JavaScript gives a
						# closure made in the body the pass's own variable. The
						# copy is made only where the body holds a closure.
						next_pass = match loop.capture {
							Captures => Interp.copied_scope(after)
							CapturesNothing => after
						}
						$s = match loop.update {
							Updated(e) => Interp.machine_after(next_pass, e)
							NoUpdate => next_pass
						}
						$going = Interp.is_running($s)
					}
					Leave(f) => {
						$s = after
						$flow = f
						$going = False
					}
				}
			}
		}
		{ machine: Interp.left($s, $s.scope, outer, loop.capture), flow: $flow }
	}

	# The machine in a copy of its current scope, beside the old one.
	copied_scope : Interp.Machine -> Interp.Machine
	copied_scope = |machine| {
		scope = machine.scopes.get(machine.scope) ?? crash "Interp.copied_scope: the current scope is one the machine has"
		Interp.with_scope_added(machine, scope)
	}

	execute_for_of : Interp.Machine, Ast.ForOfLoop -> Interp.Done
	execute_for_of = |machine, loop| {
		{ machine: got, value: iterable } = Interp.evaluate(machine, loop.iterable)
		state = match loop.binding {
			Let => Mutable
			Const => Fixed
		}
		match iterable {
			Reference(id) => match Interp.kind_of(got.cells, id) {
				ArrayKind(_) => Interp.execute_for_of_array(got, loop, id, state)
				_ => Interp.normal(
					Interp.faulted(
						got,
						"unsupported: `for ... of` over anything but an array or a string${Interp.at_line(loop.at)}",
					),
				)
			}
			Text(s) => Interp.execute_for_of_text(got, loop, s, state)
			_ => Interp.normal(
				Interp.faulted(
					got,
					"TypeError: the value is not iterable${Interp.at_line(loop.at)}",
				),
			)
		}
	}

	execute_for_of_array : Interp.Machine, Ast.ForOfLoop, U64, Interp.VariableState -> Interp.Done
	execute_for_of_array = |machine, loop, id, state| {
		var $s = machine
		var $flow = Normal
		var $i = 0
		var $going = Interp.is_running(machine)
		while $going {
			if $i >= Interp.item_count($s, id) {
				$going = False
			} else {
				v = Interp.item_at($s, id, $i)
				{ machine: after, flow } = Interp.execute_for_of_pass(Interp.ticked($s), loop, v, state)
				$s = after
				$i = $i + 1
				match Interp.after_body(flow) {
					GoOn => {
						$going = Interp.is_running($s)
					}
					Leave(f) => {
						$flow = f
						$going = False
					}
				}
			}
		}
		{ machine: $s, flow: $flow }
	}

	execute_for_of_text : Interp.Machine, Ast.ForOfLoop, Str, Interp.VariableState -> Interp.Done
	execute_for_of_text = |machine, loop, text, state| {
		var $s = machine
		var $flow = Normal
		var $going = Interp.is_running(machine)
		for c in Interp.characters(text) {
			if $going {
				{ machine: after, flow } = Interp.execute_for_of_pass(
					Interp.ticked($s),
					loop,
					Text(c),
					state,
				)
				$s = after
				match Interp.after_body(flow) {
					GoOn => {
						$going = Interp.is_running($s)
					}
					Leave(f) => {
						$flow = f
						$going = False
					}
				}
			}
		}
		{ machine: $s, flow: $flow }
	}

	# A string's characters, each its UTF-8 bytes, as `for ... of` takes them.
	characters : Str -> List(Str)
	characters = |text| {
		b = text.to_utf8()
		var $out = []
		var $i = 0
		while $i < b.len() {
			c = b.get($i) ?? crash "Interp.characters: inside the text"
			n = if c >= 0xF0 {
				4
			} else if c >= 0xE0 {
				3
			} else if c >= 0xC0 {
				2
			} else {
				1
			}
			$out = $out.append(
				Str.from_utf8(
					b.sublist({ start: $i, len: n }),
				) ?? crash "Interp.characters: a whole character",
			)
			$i = $i + n
		}
		$out
	}

	execute_for_of_pass : Interp.Machine, Ast.ForOfLoop, Heap.Value, Interp.VariableState -> Interp.Done
	execute_for_of_pass = |machine, loop, v, state| {
		outer = machine.scope
		inner = Interp.with_scope_added(
			machine,
			{ variables: [{ value: v, state: state }], parent: Within(outer) },
		)
		id = inner.scope
		{ machine: after, flow } = Interp.execute(inner, loop.body)
		{ machine: Interp.left(after, id, outer, loop.capture), flow: flow }
	}

	# ---- values ----------------------------------------------------------------

	is_truthy : Heap.Value -> Bool
	is_truthy = |v| match v {
		Number(n) => !(n == 0.0 or n.is_nan())
		Text(s) => !s.is_empty()
		Boolean(b) => b
		Null => False
		Undefined => False
		Reference(_) => True
	}

	type_of : List(Heap.Cell), Heap.Value -> Str
	type_of = |cells, v| match v {
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
	is_strictly_equal = |a, b| match (a, b) {
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
	is_same_value_zero = |a, b| match (a, b) {
		(Number(x), Number(y)) => x == y or (x.is_nan() and y.is_nan())
		_ => Interp.is_strictly_equal(a, b)
	}

	# What `String(v)` gives, for the values whose text the subset has.
	text_of : List(Heap.Cell), Heap.Value -> Try(Str, [Unsupported(Str)])
	text_of = |cells, v| Interp.text_of_seen(cells, v, [])

	text_of_seen : List(Heap.Cell), Heap.Value, List(U64) -> Try(Str, [Unsupported(Str)])
	text_of_seen = |cells, v, seen| match v {
		Number(n) => Ok(NumberText.of(n))
		Text(s) => Ok(s)
		Boolean(b) => Ok(
			if b {
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
							_ => Interp.text_of_seen(cells, item, seen.append(id))?
						}
						$parts = $parts.append(part)
					}
					Ok(Str.join_with($parts, ","))
				}
			}
			Object(_) => Ok("[object Object]")
			_ => Err(Unsupported("unsupported: turning a function or a builtin object into text"))
		}
	}

	# The property key a value names, as `o[k]` reads it.
	key_of : Heap.Value -> Try(Str, [Unsupported(Str)])
	key_of = |v| match v {
		Number(n) => Ok(NumberText.of(n))
		Text(s) => Ok(s)
		Boolean(b) => Ok(
			if b {
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
	index_of = |v| match v {
		Number(n) => {
			if n >= 0.0 and n < 4294967295.0 and n.div_trunc_by(1.0) == n {
				n.to_u64_try().map_err(|_| NotIndex)
			} else {
				Err(NotIndex)
			}
		}
		Text(s) => Inspect.index_of_key(s)
		_ => Err(NotIndex)
	}

	ordering_of_text : Str, Str -> [Before, Same, After]
	ordering_of_text = |a, b| {
		x = a.to_utf8()
		y = b.to_utf8()
		var $i = 0
		var $answer = Same
		var $deciding = True
		while $deciding {
			match (x.get($i), y.get($i)) {
				(Ok(c), Ok(d)) => {
					if c < d {
						$answer = Before
						$deciding = False
					} else if c > d {
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
	shown_value = |cells, v| match v {
		Text(s) => Inspect.escaped(s)
		_ => Inspect.inspect(cells, v) ?? Interp.type_of(cells, v)
	}

	# ---- expressions -----------------------------------------------------------

	evaluate : Interp.Machine, Ast.Expression -> Interp.Got
	evaluate = |machine, expr|
		match expr {
			Number(n) => { machine: machine, value: Number(n) }
			Text(s) => { machine: machine, value: Text(s) }
			Boolean(b) => { machine: machine, value: Boolean(b) }
			Null => { machine: machine, value: Null }
			Undefined => { machine: machine, value: Undefined }
			Template(texts, parts) => Interp.evaluate_template(machine, texts, parts)
			Name(name, slot, w) => Interp.evaluate_name(machine, name, slot, w)
			ArrayLit(items) => {
				{ machine: after, values } = Interp.evaluate_all(machine, items)
				Interp.alloc(after, Array(values))
			}
			ObjectLit(properties) => {
				var $s = machine
				var $made = []
				for p in properties {
					{ machine: after, value } = Interp.evaluate($s, p.value)
					$s = after
					$made = Heap.properties_with($made, p.key, value)
				}
				Interp.alloc($s, Object($made))
			}
			Unary(operator, e, w) => {
				{ machine: after, value } = Interp.evaluate(machine, e)
				Interp.unary(after, operator, value, w)
			}
			Binary(operator, a, b, w) => {
				{ machine: first, value: left_val } = Interp.evaluate(machine, a)
				{ machine: second, value: right_val } = Interp.evaluate(first, b)
				Interp.binary(second, operator, left_val, right_val, w)
			}
			Logical(operator, a, b) => {
				{ machine: first, value: left_val } = Interp.evaluate(machine, a)
				decided = match operator {
					And => !Interp.is_truthy(left_val)
					Or => Interp.is_truthy(left_val)
					Nullish => left_val != Null and left_val != Undefined
				}
				if decided {
					{ machine: first, value: left_val }
				} else {
					Interp.evaluate(first, b)
				}
			}
			Conditional(test, yes, no) => {
				{ machine: tested, value } = Interp.evaluate(machine, test)
				if Interp.is_truthy(value) {
					Interp.evaluate(tested, yes)
				} else {
					Interp.evaluate(tested, no)
				}
			}
			Assign(target, operator, e, w) => Interp.evaluate_assign(machine, target, operator, e, w)
			Update(target, step, fixity, w) => Interp.evaluate_update(machine, target, step, fixity, w)
			Member(object, key, w) => {
				{ machine: after, value: o } = Interp.evaluate(machine, object)
				Interp.property(after, o, key, w)
			}
			Index(object, key, w) => {
				{ machine: first, value: o } = Interp.evaluate(machine, object)
				{ machine: second, value: k } = Interp.evaluate(first, key)
				Interp.indexed(second, o, k, w)
			}
			Call(callee, arguments, w) => Interp.evaluate_call(machine, callee, arguments, w)
			Function(definition) => Interp.alloc(machine, Fun({ fun: definition, scope: machine.scope }))
		}

	# The machine after an expression whose value is not wanted.
	machine_after : Interp.Machine, Ast.Expression -> Interp.Machine
	machine_after = |machine, e| {
		{ machine: after, value: _ } = Interp.evaluate(machine, e)
		after
	}

	Evaluations : { machine : Interp.Machine, values : List(Heap.Value) }

	evaluate_all : Interp.Machine, List(Ast.Expression) -> Interp.Evaluations
	evaluate_all = |machine, expressions| {
		var $s = machine
		var $vals = []
		for e in expressions {
			{ machine: after, value } = Interp.evaluate($s, e)
			$s = after
			$vals = $vals.append(value)
		}
		{ machine: $s, values: $vals }
	}

	evaluate_template : Interp.Machine, List(Str), List(Ast.Expression) -> Interp.Got
	evaluate_template = |machine, texts, parts| {
		var $s = machine
		var $text = texts.first() ?? crash "Interp.eval_template: a template has a text piece before its first substitution"
		var $i = 1
		for part in parts {
			{ machine: after, value } = Interp.evaluate($s, part)
			$s = match Interp.text_of(after.cells, value) {
				Ok(t) => {
					$text = Str.concat(
						Str.concat($text, t),
						texts.get($i) ?? crash "Interp.eval_template: a template has a text piece after each substitution",
					)
					after
				}
				Err(Unsupported(why)) => Interp.faulted(after, why)
			}
			$i = $i + 1
		}
		{ machine: $s, value: Text($text) }
	}

	evaluate_name : Interp.Machine, Str, Ast.Slot, Ast.Where -> Interp.Got
	evaluate_name = |machine, name, slot, w|
		match Interp.place_of(machine, slot) {
			At({ scope, index }) => {
				binding = Interp.variable_at(machine.scopes, scope, index)
				match binding.state {
					Unready => Interp.fault_got(
						machine,
						"ReferenceError: Cannot access '${name}' before initialization${Interp.at_line(w)}",
					)
					_ => { machine: machine, value: binding.value }
				}
			}
			Nowhere => Interp.fault_got(machine, Interp.missing_name_message(name, w))
		}

	missing_name_message : Str, Ast.Where -> Str
	missing_name_message = |name, w|
		if [
			"globalThis",
			"window",
			"require",
			"process",
			"JSON",
			"Map",
			"Set",
			"Symbol",
			"Promise",
			"Date",
			"RegExp",
			"parseInt",
			"parseFloat",
			"setTimeout",
			"Error",
			"BigInt",
			"Reflect",
			"Proxy",
		].contains(name) {
			"unsupported: the builtin `${name}`${Interp.at_line(w)}"
		} else {
			"ReferenceError: ${name} is not defined${Interp.at_line(w)}"
		}

	unary : Interp.Machine, Ast.UnaryOperator, Heap.Value, Ast.Where -> Interp.Got
	unary = |machine, operator, v, w|
		match operator {
			Not => { machine: machine, value: Boolean(!Interp.is_truthy(v)) }
			TypeOf => { machine: machine, value: Text(Interp.type_of(machine.cells, v)) }
			Negate => match v {
				Number(n) => { machine: machine, value: Number(-n) }
				_ => Interp.fault_got(
					machine,
					"unsupported: `-` on a ${Interp.type_of(machine.cells, v)} (a coercion)${Interp.at_line(w)}",
				)
			}
			Plus => match v {
				Number(n) => { machine: machine, value: Number(n) }
				_ => Interp.fault_got(
					machine,
					"unsupported: `+` on a ${Interp.type_of(machine.cells, v)} (a coercion)${Interp.at_line(w)}",
				)
			}
		}

	binary : Interp.Machine, Ast.BinaryOperator, Heap.Value, Heap.Value, Ast.Where -> Interp.Got
	binary = |machine, operator, a, b, w|
		match operator {
			StrictEqual => { machine: machine, value: Boolean(Interp.is_strictly_equal(a, b)) }
			StrictNotEqual => { machine: machine, value: Boolean(!Interp.is_strictly_equal(a, b)) }
			Add => Interp.add(machine, a, b, w)
			_ => match (a, b) {
				(Number(x), Number(y)) => { machine: machine, value: Interp.arithmetic(operator, x, y) }
				(Text(x), Text(y)) => match operator {
					Less => { machine: machine, value: Boolean(Interp.ordering_of_text(x, y) == Before) }
					LessOrEqual => { machine: machine, value: Boolean(Interp.ordering_of_text(x, y) != After) }
					Greater => { machine: machine, value: Boolean(Interp.ordering_of_text(x, y) == After) }
					GreaterOrEqual => {
						machine: machine,
						value: Boolean(Interp.ordering_of_text(x, y) != Before),
					}
					_ => Interp.fault_got(
						machine,
						"unsupported: arithmetic on strings (a coercion)${Interp.at_line(w)}",
					)
				}
				_ => Interp.fault_got(
					machine,
					"unsupported: an operator on a ${Interp.type_of(machine.cells, a)} and a ${Interp.type_of(machine.cells, b)} (a coercion)${Interp.at_line(w)}",
				)
			}
		}

	arithmetic : Ast.BinaryOperator, F64, F64 -> Heap.Value
	arithmetic = |operator, x, y| match operator {
		Subtract => Number(x - y)
		Multiply => Number(x * y)
		Divide => Number(x / y)
		Remainder => Number(Interp.remainder(x, y))
		Power => Number(Interp.power(x, y))
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
	add : Interp.Machine, Heap.Value, Heap.Value, Ast.Where -> Interp.Got
	add = |machine, a, b, w|
		match (a, b) {
			(Number(x), Number(y)) => { machine: machine, value: Number(x + y) }
			_ => {
				is_texty = |v| match v {
					Text(_) => True
					Reference(_) => True
					_ => False
				}
				if is_texty(a) or is_texty(b) {
					match (Interp.text_of(machine.cells, a), Interp.text_of(machine.cells, b)) {
						(Ok(x), Ok(y)) => { machine: machine, value: Text(Str.concat(x, y)) }
						(Err(Unsupported(why)), _) => Interp.fault_got(
							machine,
							"${why}${Interp.at_line(w)}",
						)
						(_, Err(Unsupported(why))) => Interp.fault_got(
							machine,
							"${why}${Interp.at_line(w)}",
						)
					}
				} else {
					Interp.fault_got(
						machine,
						"unsupported: `+` on a ${Interp.type_of(machine.cells, a)} and a ${Interp.type_of(machine.cells, b)} (a coercion)${Interp.at_line(w)}",
					)
				}
			}
		}

	combined : Interp.Machine, Ast.AssignmentOperator, Heap.Value, Heap.Value, Ast.Where -> Interp.Got
	combined = |machine, operator, old, new, w|
		match operator {
			Set => { machine: machine, value: new }
			Combine(b) => Interp.binary(machine, b, old, new, w)
		}

	evaluate_assign : Interp.Machine, Ast.Target, Ast.AssignmentOperator, Ast.Expression, Ast.Where -> Interp.Got
	evaluate_assign = |machine, target, operator, e, w|
		match target {
			ToName(name, slot, at) => {
				match Interp.place_of(machine, slot) {
					Nowhere => Interp.fault_got(
						machine,
						"unsupported: assigning to `${name}`, which is not declared${Interp.at_line(at)}",
					)
					At({ scope, index }) => {
						facts = Interp.variable_facts(machine.scopes, scope, index)
						appends = operator == Combine(Add) and facts.state == Mutable and facts.holds_text and Interp.is_pure(e)
						if appends {
							Interp.appended_name(machine, scope, index, e, w)
						} else {
							old = Interp.variable_value(machine.scopes, scope, index)
							{ machine: after, value } = Interp.evaluate(machine, e)
							{ machine: made, value: result } = Interp.combined(after, operator, old, value, w)
							Interp.assigned_name(made, result, name, slot, at)
						}
					}
				}
			}
			ToMember(object, key) => {
				{ machine: first, value: o } = Interp.evaluate(machine, object)
				{ machine: second, value: old } = match operator {
					Set => { machine: first, value: Undefined }
					Combine(_) => Interp.property(first, o, key, w)
				}
				{ machine: third, value } = Interp.evaluate(second, e)
				{ machine: made, value: result } = Interp.combined(third, operator, old, value, w)
				Interp.stored(
					made,
					o,
					Text(key),
					result,
					w,
				)
			}
			ToIndex(object, key) => {
				{ machine: first, value: o } = Interp.evaluate(machine, object)
				{ machine: second, value: k } = Interp.evaluate(first, key)
				{ machine: third, value: old } = match operator {
					Set => { machine: second, value: Undefined }
					Combine(_) => Interp.indexed(second, o, k, w)
				}
				{ machine: fourth, value } = Interp.evaluate(third, e)
				{ machine: made, value: result } = Interp.combined(fourth, operator, old, value, w)
				Interp.stored(made, o, k, result, w)
			}
		}

	# A variable written, its place found again after the value was made:
	# making it may have run code that added scopes.
	assigned_name : Interp.Machine, Heap.Value, Str, Ast.Slot, Ast.Where -> Interp.Got
	assigned_name = |machine, value, name, slot, w|
		if !Interp.is_running(machine) {
			{ machine: machine, value: value }
		} else {
			match Interp.place_of(machine, slot) {
				At({ scope, index }) => match Interp.variable_facts(machine.scopes, scope, index).state {
					Mutable => Interp.variable_written(
						machine,
						scope,
						index,
						{ value: value, state: Mutable },
					)
					Fixed => Interp.fault_got(
						machine,
						"TypeError: Assignment to constant variable.${Interp.at_line(w)}",
					)
					Unready => Interp.fault_got(
						machine,
						"ReferenceError: Cannot access '${name}' before initialization${Interp.at_line(w)}",
					)
				}
				Nowhere => Interp.fault_got(
					machine,
					"ReferenceError: ${name} is not defined${Interp.at_line(w)}",
				)
			}
		}

	# What a variable is, with nothing of its value kept: a kept copy of a
	# string is a second reference to it.
	variable_facts : List(Interp.Scope), U64, U64 -> { state : Interp.VariableState, holds_text : Bool }
	variable_facts = |scopes, scope_id, index| {
		binding = Interp.variable_at(scopes, scope_id, index)
		{ state: binding.state, holds_text: Interp.is_text(binding.value) }
	}

	is_text : Heap.Value -> Bool
	is_text = |v| match v {
		Text(_) => True
		_ => False
	}

	# Whether evaluating an expression can't change a variable: it calls
	# nothing, assigns nothing and makes no function.
	is_pure : Ast.Expression -> Bool
	is_pure = |e| match e {
		Number(_) => True
		Text(_) => True
		Boolean(_) => True
		Null => True
		Undefined => True
		Name(_, _, _) => True
		Template(_, parts) => parts.all(Interp.is_pure)
		ArrayLit(items) => items.all(Interp.is_pure)
		ObjectLit(properties) => properties.all(|p| Interp.is_pure(p.value))
		Unary(_, a, _) => Interp.is_pure(a)
		Binary(_, a, b, _) => Interp.is_pure(a) and Interp.is_pure(b)
		Logical(_, a, b) => Interp.is_pure(a) and Interp.is_pure(b)
		Conditional(a, b, c) => Interp.is_pure(a) and Interp.is_pure(b) and Interp.is_pure(c)
		Member(a, _, _) => Interp.is_pure(a)
		Index(a, b, _) => Interp.is_pure(a) and Interp.is_pure(b)
		Assign(_, _, _, _) => False
		Update(_, _, _, _) => False
		Call(_, _, _) => False
		Function(_) => False
	}

	# `s += e` where `s` holds a string and `e` can't change it: `e` first,
	# then its text appended to the string where the variable holds it.
	#
	# **THE STRING IS TAKEN OUT OF ITS VARIABLE BEFORE IT GROWS.** Read the
	# usual way, the string is held twice, by the variable and by the value
	# read, so each append copied the string: building a string of N
	# characters one at a time cost N squared. `e` can't change the variable,
	# so it may run first, and the string then grows while only the variable
	# holds it.
	appended_name : Interp.Machine, U64, U64, Ast.Expression, Ast.Where -> Interp.Got
	appended_name = |machine, scope_id, index, e, w| {
		{ machine: after, value: piece } = Interp.evaluate(machine, e)
		if !Interp.is_running(after) {
			{ machine: after, value: Undefined }
		} else {
			match Interp.text_of(after.cells, piece) {
				Err(Unsupported(why)) => Interp.fault_got(after, "${why}${Interp.at_line(w)}")
				Ok(tail) => Interp.text_appended(after, scope_id, index, tail)
			}
		}
	}

	text_appended : Interp.Machine, U64, U64, Str -> Interp.Got
	text_appended = |machine, scope_id, index, tail| {
		grown = { ..machine, scopes: Interp.scopes_with_appended(machine.scopes, scope_id, index, tail) }
		{ machine: grown, value: Interp.variable_value(grown.scopes, scope_id, index) }
	}

	variable_value : List(Interp.Scope), U64, U64 -> Heap.Value
	variable_value = |scopes, scope_id, index| Interp.variable_at(scopes, scope_id, index).value

	scopes_with_appended : List(Interp.Scope), U64, U64, Str -> List(Interp.Scope)
	scopes_with_appended = |scopes, scope_id, index, tail| {
		taken = scopes.replace(
			scope_id,
			{ variables: [], parent: Outermost },
		) ?? crash "Interp.scopes_with_appended: a scope the machine has"
		taken.list.set(
			scope_id,
			Interp.scope_with_appended(taken.prev, index, tail),
		) ?? crash "Interp.scopes_with_appended: the scope was just taken"
	}

	scope_with_appended : Interp.Scope, U64, Str -> Interp.Scope
	scope_with_appended = |scope, index, tail| {
		{ variables, parent } = scope
		taken = variables.replace(
			index,
			Interp.unready,
		) ?? crash "Interp.scope_with_appended: a variable the scope has"
		{
			variables: taken.list.set(
				index,
				Interp.variable_with_appended(taken.prev, tail),
			) ?? crash "Interp.scope_with_appended: the variable was just taken",
			parent: parent,
		}
	}

	variable_with_appended : Interp.Variable, Str -> Interp.Variable
	variable_with_appended = |binding, tail| {
		{ value, state } = binding
		{ value: Interp.val_with_appended(value, tail), state: state }
	}

	val_with_appended : Heap.Value, Str -> Heap.Value
	val_with_appended = |value, tail| match value {
		Text(old) => Text(Str.concat(old, tail))
		_ => crash "Interp.val_with_appended: the interpreter appends only to a variable that holds a string"
	}

	variable_written : Interp.Machine, U64, U64, Interp.Variable -> Interp.Got
	variable_written = |machine, scope_id, index, binding| {
		machine: { ..machine, scopes: Interp.with_variable(machine.scopes, scope_id, index, binding) },
		value: binding.value,
	}

	evaluate_update : Interp.Machine, Ast.Target, Ast.Step, Ast.Fixity, Ast.Where -> Interp.Got
	evaluate_update = |machine, target, step, fixity, w| {
		delta = match step {
			Increment => 1.0
			Decrement => -1.0
		}
		answer = |old, new| match fixity {
			Prefix => Number(new)
			Postfix => Number(old)
		}
		match target {
			ToName(name, slot, at) => {
				{ machine: read_st, value: current } = Interp.evaluate_name(machine, name, slot, at)
				match current {
					Number(n) => {
						{ machine: written, value: _ } = Interp.assigned_name(
							read_st,
							Number(n + delta),
							name,
							slot,
							at,
						)
						{ machine: written, value: answer(n, n + delta) }
					}
					_ => Interp.fault_got(
						read_st,
						"unsupported: `++` or `--` on a ${Interp.type_of(read_st.cells, current)}${Interp.at_line(w)}",
					)
				}
			}
			ToMember(object, key) => {
				{ machine: first, value: o } = Interp.evaluate(machine, object)
				{ machine: read_st, value: current } = Interp.property(first, o, key, w)
				match current {
					Number(n) => {
						{ machine: written, value: _ } = Interp.stored(
							read_st,
							o,
							Text(key),
							Number(n + delta),
							w,
						)
						{ machine: written, value: answer(n, n + delta) }
					}
					_ => Interp.fault_got(
						read_st,
						"unsupported: `++` or `--` on a ${Interp.type_of(read_st.cells, current)}${Interp.at_line(w)}",
					)
				}
			}
			ToIndex(object, key) => {
				{ machine: first, value: o } = Interp.evaluate(machine, object)
				{ machine: second, value: k } = Interp.evaluate(first, key)
				{ machine: read_st, value: current } = Interp.indexed(second, o, k, w)
				match current {
					Number(n) => {
						{ machine: written, value: _ } = Interp.stored(
							read_st,
							o,
							k,
							Number(n + delta),
							w,
						)
						{ machine: written, value: answer(n, n + delta) }
					}
					_ => Interp.fault_got(
						read_st,
						"unsupported: `++` or `--` on a ${Interp.type_of(read_st.cells, current)}${Interp.at_line(w)}",
					)
				}
			}
		}
	}

	# ---- properties ------------------------------------------------------------

	property : Interp.Machine, Heap.Value, Str, Ast.Where -> Interp.Got
	property = |machine, object, key, w|
		match object {
			Reference(id) => match Heap.cell_at(machine.cells, id) {
				Object(properties) => {
					if Heap.has_property(properties, key) {
						{ machine: machine, value: Heap.property_value(properties, key) }
					} else if Interp.is_prototype_name(key) {
						Interp.fault_got(
							machine,
							"unsupported: Object.prototype's `${key}`${Interp.at_line(w)}",
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
							Ok(i) => { machine: machine, value: items.get(i) ?? Undefined }
							Err(NotIndex) => Interp.fault_got(
								machine,
								"unsupported: the array property `${key}` outside a call${Interp.at_line(w)}",
							)
						}
					}
				}
				Namespace(name, properties) => {
					if Heap.has_property(properties, key) {
						{ machine: machine, value: Heap.property_value(properties, key) }
					} else {
						Interp.fault_got(machine, "unsupported: `${name}.${key}`${Interp.at_line(w)}")
					}
				}
				Builtin(n, properties) => {
					if Heap.has_property(properties, key) {
						{ machine: machine, value: Heap.property_value(properties, key) }
					} else {
						Interp.fault_got(
							machine,
							"unsupported: `${Heap.native_name(n)}.${key}`${Interp.at_line(w)}",
						)
					}
				}
				Fun(_) => Interp.fault_got(
					machine,
					"unsupported: a function's properties (`${key}`)${Interp.at_line(w)}",
				)
				Taken => crash "Interp.property: no cell is out being written while a property is read"
			}
			Text(s) => {
				if key == "length" {
					if Interp.is_ascii(s) {
						{ machine: machine, value: Number(s.count_utf8_bytes().to_f64()) }
					} else {
						Interp.fault_got(
							machine,
							"unsupported: the length of a string with non-ASCII text${Interp.at_line(w)}",
						)
					}
				} else {
					match Inspect.index_of_key(key) {
						Ok(i) => Interp.char_at(machine, s, i, w)
						Err(NotIndex) => Interp.fault_got(
							machine,
							"unsupported: the string property `${key}` outside a call${Interp.at_line(w)}",
						)
					}
				}
			}
			Null => Interp.fault_got(
				machine,
				"TypeError: Cannot read properties of null (reading '${key}')${Interp.at_line(w)}",
			)
			Undefined => Interp.fault_got(
				machine,
				"TypeError: Cannot read properties of undefined (reading '${key}')${Interp.at_line(w)}",
			)
			_ => Interp.fault_got(
				machine,
				"unsupported: the property `${key}` of a ${Interp.type_of(machine.cells, object)}${Interp.at_line(w)}",
			)
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
	is_ascii = |s| s.to_utf8().all(|c| c < 128)

	char_at : Interp.Machine, Str, U64, Ast.Where -> Interp.Got
	char_at = |machine, s, i, w|
		if !Interp.is_ascii(s) {
			Interp.fault_got(
				machine,
				"unsupported: indexing a string with non-ASCII text${Interp.at_line(w)}",
			)
		} else {
			match s.to_utf8().get(i) {
				Ok(c) => {
					machine: machine,
					value: Text(Str.from_utf8([c]) ?? crash "Interp.char_at: an ASCII byte"),
				}
				Err(OutOfBounds) => { machine: machine, value: Undefined }
			}
		}

	indexed : Interp.Machine, Heap.Value, Heap.Value, Ast.Where -> Interp.Got
	indexed = |machine, object, key, w|
		match (object, Interp.index_of(key)) {
			(Reference(id), Ok(i)) => match Heap.cell_at(machine.cells, id) {
				Array(items) => { machine: machine, value: items.get(i) ?? Undefined }
				_ => Interp.property_by_value(machine, object, key, w)
			}
			(Text(s), Ok(i)) => Interp.char_at(machine, s, i, w)
			_ => Interp.property_by_value(machine, object, key, w)
		}

	property_by_value : Interp.Machine, Heap.Value, Heap.Value, Ast.Where -> Interp.Got
	property_by_value = |machine, object, key, w|
		match Interp.key_of(key) {
			Ok(k) => Interp.property(machine, object, k, w)
			Err(Unsupported(why)) => Interp.fault_got(machine, "${why}${Interp.at_line(w)}")
		}

	# What a cell is, and an array's length, with nothing of the cell kept.
	#
	# **A WRITER ASKS THIS, NEVER `Heap.cell_at`.** A cell matched out of the
	# heap is a second reference to its props or items for as long as the
	# match's arm runs, so a write made inside that arm copies them: every
	# store into an array of N items copied the N items. These answers hold
	# nothing of the heap.
	Kind : [ObjectKind, ArrayKind(U64), FunctionKind, BuiltinKind]

	kind_of : List(Heap.Cell), U64 -> Interp.Kind
	kind_of = |cells, id|
		match Heap.cell_at(cells, id) {
			Object(_) => ObjectKind
			Array(items) => ArrayKind(items.len())
			Fun(_) => FunctionKind
			Builtin(_, _) => BuiltinKind
			Namespace(_, _) => BuiltinKind
			Taken => crash "Interp.kind_of: no cell is out being written while another is asked about"
		}

	# A property or an item written: an object's property, an array's item
	# inside it or at its end.
	stored : Interp.Machine, Heap.Value, Heap.Value, Heap.Value, Ast.Where -> Interp.Got
	stored = |machine, object, key, value, w|
		if !Interp.is_running(machine) {
			{ machine: machine, value: value }
		} else {
			match object {
				Reference(id) => match Interp.kind_of(machine.cells, id) {
					ObjectKind => match Interp.key_of(key) {
						Ok(k) => {
							machine: { ..machine, cells: Heap.with_property(machine.cells, id, k, value) },
							value: value,
						}
						Err(Unsupported(why)) => Interp.fault_got(machine, "${why}${Interp.at_line(w)}")
					}
					ArrayKind(n) => {
						match Interp.index_of(key) {
							Ok(i) if i <= n => {
								machine: { ..machine, cells: Heap.with_item(machine.cells, id, i, value) },
								value: value,
							}
							Ok(_) => Interp.fault_got(
								machine,
								"unsupported: an array with holes (a write past its end)${Interp.at_line(w)}",
							)
							Err(NotIndex) => Interp.fault_got(
								machine,
								"unsupported: writing an array's `length` or a named property${Interp.at_line(w)}",
							)
						}
					}
					_ => Interp.fault_got(
						machine,
						"unsupported: writing a property of a function or a builtin${Interp.at_line(w)}",
					)
				}
				Null => Interp.fault_got(
					machine,
					"TypeError: Cannot set properties of null${Interp.at_line(w)}",
				)
				Undefined => Interp.fault_got(
					machine,
					"TypeError: Cannot set properties of undefined${Interp.at_line(w)}",
				)
				_ => Interp.fault_got(
					machine,
					"unsupported: writing a property of a ${Interp.type_of(machine.cells, object)}${Interp.at_line(w)}",
				)
			}
		}

	# ---- calls -----------------------------------------------------------------

	evaluate_call : Interp.Machine, Ast.Expression, List(Ast.Expression), Ast.Where -> Interp.Got
	evaluate_call = |machine, callee, arguments, w|
		match callee {
			Member(object, name, _) => {
				{ machine: first, value: o } = Interp.evaluate(machine, object)
				method = match o {
					Reference(id) => match Interp.kind_of(first.cells, id) {
						ArrayKind(_) => ArrayMethod(id)
						_ => Plain
					}
					Text(s) => TextMethod(s)
					_ => Plain
				}
				match method {
					ArrayMethod(id) => {
						{ machine: second, values } = Interp.evaluate_all(first, arguments)
						Interp.array_method(second, id, name, values, w)
					}
					TextMethod(s) => {
						{ machine: second, values } = Interp.evaluate_all(first, arguments)
						Interp.text_method(second, s, name, values, w)
					}
					Plain => {
						{ machine: second, value: f } = Interp.property(first, o, name, w)
						{ machine: third, values } = Interp.evaluate_all(second, arguments)
						Interp.call(third, f, values, w)
					}
				}
			}
			_ => {
				{ machine: first, value: f } = Interp.evaluate(machine, callee)
				{ machine: second, values } = Interp.evaluate_all(first, arguments)
				Interp.call(second, f, values, w)
			}
		}

	call : Interp.Machine, Heap.Value, List(Heap.Value), Ast.Where -> Interp.Got
	call = |machine, callee, arguments, w|
		if !Interp.is_running(machine) {
			{ machine: machine, value: Undefined }
		} else {
			match callee {
				Reference(id) => match Heap.cell_at(machine.cells, id) {
					Fun(c) => Interp.call_closure(machine, c, arguments, w)
					Builtin(n, _) => Interp.call_native(machine, n, arguments, w)
					_ => Interp.fault_got(
						machine,
						"TypeError: ${Interp.shown_value(machine.cells, callee)} is not a function${Interp.at_line(w)}",
					)
				}
				_ => Interp.fault_got(
					machine,
					"TypeError: ${Interp.shown_value(machine.cells, callee)} is not a function${Interp.at_line(w)}",
				)
			}
		}

	call_closure : Interp.Machine, Heap.Closure, List(Heap.Value), Ast.Where -> Interp.Got
	call_closure = |machine, c, arguments, w|
		if machine.depth >= Interp.max_depth {
			Interp.fault_got(machine, "RangeError: Maximum call stack size exceeded${Interp.at_line(w)}")
		} else {
			outer = machine.scope
			definition = c.fun.unbox()
			inside = Interp.with_scope_added(
				{ ..machine, depth: machine.depth + 1 },
				{ variables: Interp.call_vars(definition, arguments), parent: Within(c.scope) },
			)
			id = inside.scope
			{ machine: after, flow } = Interp.execute_list(Interp.hoisted(inside, definition.body), definition.body)
			value = match flow {
				Returned(v) => v
				_ => Undefined
			}
			back = Interp.left(after, id, outer, definition.capture)
			{ machine: { ..back, depth: back.depth - 1 }, value: value }
		}

	# A call's variables: each parameter holding its argument, then the rest
	# of the function's layout, unready.
	call_vars : Ast.FunctionDefinition, List(Heap.Value) -> List(Interp.Variable)
	call_vars = |definition, arguments| {
		parameters = definition.parameters.len()
		var $vars = List.with_capacity(definition.names.len())
		var $i = 0
		while $i < definition.names.len() {
			$vars = $vars.append(
				if $i < parameters {
					{ value: arguments.get($i) ?? Undefined, state: Mutable }
				} else {
					Interp.unready
				},
			)
			$i = $i + 1
		}
		$vars
	}

	number_argument : List(Heap.Value), U64 -> Try(F64, [NotNumber])
	number_argument = |arguments, i|
		match arguments.get(i) {
			Ok(Number(n)) => Ok(n)
			_ => Err(NotNumber)
		}

	math : Interp.Machine, Str, List(Heap.Value), (F64 -> F64), Ast.Where -> Interp.Got
	math = |machine, name, arguments, f, w|
		match Interp.number_argument(arguments, 0) {
			Ok(n) => { machine: machine, value: Number(f(n)) }
			Err(NotNumber) => Interp.fault_got(
				machine,
				"unsupported: Math.${name} of anything but a number${Interp.at_line(w)}",
			)
		}

	floor : F64 -> F64
	floor = |n|
		if n.is_nan() or n.is_infinite() or n == 0.0 {
			n
		} else {
			n.div_floor_by(1.0)
		}

	call_native : Interp.Machine, Heap.Native, List(Heap.Value), Ast.Where -> Interp.Got
	call_native = |machine, n, arguments, w|
		match n {
			Log => match Inspect.line_of(machine.cells, arguments) {
				Ok(line) => {
					machine: { ..machine, out: Str.concat(Str.concat(machine.out, line), "\n") },
					value: Undefined,
				}
				Err(Unsupported(why)) => Interp.fault_got(machine, "${why}${Interp.at_line(w)}")
			}
			Floor => Interp.math(machine, "floor", arguments, Interp.floor, w)
			Ceil => Interp.math(
				machine,
				"ceil",
				arguments,
				|x| -Interp.floor(-x),
				w,
			)
			Round => Interp.math(
				machine,
				"round",
				arguments,
				|x| {
					f = Interp.floor(x)
					if x - f >= 0.5 {
						# Rounding up from (-0.5, 0) gives -0, as JavaScript's does.
						if x < 0.0 and f == -1.0 {
							-0.0
						} else {
							f + 1.0
						}
					} else {
						f
					}
				},
				w,
			)
			Trunc => Interp.math(
				machine,
				"trunc",
				arguments,
				|x|
					if x.is_nan() or x.is_infinite() {
						x
					} else {
						x.div_trunc_by(1.0)
					},
				w,
			)
			Abs => Interp.math(
				machine,
				"abs",
				arguments,
				|x| x.abs(),
				w,
			)
			Sign => Interp.math(
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
				w,
			)
			Sqrt => Interp.math(
				machine,
				"sqrt",
				arguments,
				|x| x.sqrt(),
				w,
			)
			Sin => Interp.math(
				machine,
				"sin",
				arguments,
				|x| x.sin(),
				w,
			)
			Cos => Interp.math(
				machine,
				"cos",
				arguments,
				|x| x.cos(),
				w,
			)
			Tan => Interp.math(
				machine,
				"tan",
				arguments,
				|x| x.tan(),
				w,
			)
			Atan => Interp.math(
				machine,
				"atan",
				arguments,
				|x| x.atan(),
				w,
			)
			Pow => match (Interp.number_argument(arguments, 0), Interp.number_argument(arguments, 1)) {
				(Ok(x), Ok(y)) => { machine: machine, value: Number(Interp.power(x, y)) }
				_ => Interp.fault_got(
					machine,
					"unsupported: Math.pow of anything but two numbers${Interp.at_line(w)}",
				)
			}
			Min => Interp.min_max(machine, arguments, Min, w)
			Max => Interp.min_max(machine, arguments, Max, w)
			Keys => Interp.object_listing(machine, arguments, Keys, w)
			Values => Interp.object_listing(machine, arguments, Values, w)
			Entries => Interp.object_listing(machine, arguments, Entries, w)
			StringOf => match arguments.first() {
				Ok(v) => match Interp.text_of(machine.cells, v) {
					Ok(t) => { machine: machine, value: Text(t) }
					Err(Unsupported(why)) => Interp.fault_got(machine, "${why}${Interp.at_line(w)}")
				}
				Err(ListWasEmpty) => { machine: machine, value: Text("") }
			}
			FromCharCode => {
				var $bytes = []
				var $ok = True
				for a in arguments {
					match a {
						Number(c) if c >= 0.0 and c < 128.0 and c.div_trunc_by(1.0) == c => {
							$bytes = $bytes.append(c.to_u8_try() ?? 0)
						}
						_ => {
							$ok = False
						}
					}
				}
				if $ok {
					{
						machine: machine,
						value: Text(Str.from_utf8($bytes) ?? crash "Interp.call_native: ASCII bytes"),
					}
				} else {
					Interp.fault_got(
						machine,
						"unsupported: String.fromCharCode of anything but ASCII codes${Interp.at_line(w)}",
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
		}

	min_max : Interp.Machine, List(Heap.Value), [Min, Max], Ast.Where -> Interp.Got
	min_max = |machine, arguments, which, w| {
		var $best = match which {
			Min => 1.0 / 0.0
			Max => -1.0 / 0.0
		}
		var $ok = True
		for a in arguments {
			match a {
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
			Interp.fault_got(
				machine,
				"unsupported: Math.min or Math.max of anything but numbers${Interp.at_line(w)}",
			)
		}
	}

	# Object.keys, Object.values or Object.entries, of an object or an array.
	object_listing : Interp.Machine, List(Heap.Value), [Keys, Values, Entries], Ast.Where -> Interp.Got
	object_listing = |machine, arguments, which, w| {
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
				var $vals = []
				for p in listed {
					v = match which {
						Keys => Text(p.key)
						Values => p.value
						Entries => {
							{ machine: made, value: pair } = Interp.alloc($s, Array([Text(p.key), p.value]))
							$s = made
							pair
						}
					}
					$vals = $vals.append(v)
				}
				Interp.alloc($s, Array($vals))
			}
			Err(NotListed) => Interp.fault_got(
				machine,
				"unsupported: Object.keys, values or entries of anything but an object or an array${Interp.at_line(w)}",
			)
		}
	}

	# ---- array methods ---------------------------------------------------------

	items_of : Interp.Machine, U64 -> List(Heap.Value)
	items_of = |machine, id|
		match Heap.cell_at(machine.cells, id) {
			Array(items) => items
			_ => crash "Interp.items_of: the interpreter asks only an array for its items"
		}

	item_count : Interp.Machine, U64 -> U64
	item_count = |machine, id|
		match Heap.cell_at(machine.cells, id) {
			Array(items) => items.len()
			_ => crash "Interp.item_count: the interpreter asks only an array for its length"
		}

	item_at : Interp.Machine, U64, U64 -> Heap.Value
	item_at = |machine, id, i|
		match Heap.cell_at(machine.cells, id) {
			Array(items) => items.get(i) ?? Undefined
			_ => crash "Interp.item_at: the interpreter asks only an array for an item"
		}

	# A relative index (`slice`'s, negative from the end) as an index in 0..n.
	relative_index : Heap.Value, U64, U64 -> U64
	relative_index = |v, n, otherwise|
		match v {
			Number(x) => {
				t = if x.is_nan() {
					0.0
				} else {
					x.div_trunc_by(1.0)
				}
				if t < 0.0 {
					f = n.to_f64() + t
					if f < 0.0 {
						0
					} else {
						f.to_u64_try() ?? 0
					}
				} else if t >= n.to_f64() {
					n
				} else {
					t.to_u64_try() ?? 0
				}
			}
			_ => otherwise
		}

	array_method : Interp.Machine, U64, Str, List(Heap.Value), Ast.Where -> Interp.Got
	array_method = |machine, id, name, arguments, w|
		match name {
			"push" => {
				pushed = { ..machine, cells: Heap.with_items_pushed(machine.cells, id, arguments) }
				{ machine: pushed, value: Number(Interp.item_count(pushed, id).to_f64()) }
			}
			"pop" => {
				n = Interp.item_count(machine, id)
				if n == 0 {
					{ machine: machine, value: Undefined }
				} else {
					last = Interp.item_at(machine, id, n - 1)
					{ machine: { ..machine, cells: Heap.with_last_dropped(machine.cells, id) }, value: last }
				}
			}
			"join" => {
				separator = match arguments.first() {
					Ok(Text(s)) => Ok(s)
					Ok(Undefined) => Ok(",")
					Err(ListWasEmpty) => Ok(",")
					_ => Err(NotText)
				}
				match separator {
					Ok(s) => {
						var $parts = []
						var $why = ""
						for item in Interp.items_of(machine, id) {
							part = match item {
								Null => Ok("")
								Undefined => Ok("")
								_ => Interp.text_of(machine.cells, item)
							}
							match part {
								Ok(t) => {
									$parts = $parts.append(t)
								}
								Err(Unsupported(why)) => {
									$why = why
								}
							}
						}
						if $why == "" {
							{ machine: machine, value: Text(Str.join_with($parts, s)) }
						} else {
							Interp.fault_got(machine, "${$why}${Interp.at_line(w)}")
						}
					}
					Err(NotText) => Interp.fault_got(
						machine,
						"unsupported: `join` with a separator that is not a string${Interp.at_line(w)}",
					)
				}
			}
			"indexOf" => {
				target = arguments.first() ?? Undefined
				var $found = -1.0
				var $i = 0.0
				for item in Interp.items_of(machine, id) {
					if $found < 0.0 and Interp.is_strictly_equal(item, target) {
						$found = $i
					}
					$i = $i + 1.0
				}
				{ machine: machine, value: Number($found) }
			}
			"includes" => {
				target = arguments.first() ?? Undefined
				found = Interp.items_of(machine, id).any(|item| Interp.is_same_value_zero(item, target))
				{ machine: machine, value: Boolean(found) }
			}
			"slice" => {
				items = Interp.items_of(machine, id)
				n = items.len()
				from = Interp.relative_index(arguments.get(0) ?? Undefined, n, 0)
				to = Interp.relative_index(arguments.get(1) ?? Undefined, n, n)
				cut = if to > from {
					items.sublist({ start: from, len: to - from })
				} else {
					[]
				}
				Interp.alloc(machine, Array(cut))
			}
			"concat" => {
				var $out = Interp.items_of(machine, id)
				for a in arguments {
					$out = match a {
						Reference(other) => match Heap.cell_at(machine.cells, other) {
							Array(more) => List.concat($out, more)
							_ => $out.append(a)
						}
						_ => $out.append(a)
					}
				}
				Interp.alloc(machine, Array($out))
			}
			"reverse" => {
				items = Interp.items_of(machine, id)
				var $reversed = []
				var $k = items.len()
				while $k > 0 {
					$reversed = $reversed.append(items.get($k - 1) ?? crash "Interp.array_method: inside the items")
					$k = $k - 1
				}
				reversed = $reversed
				{ machine: { ..machine, cells: Heap.with_items(machine.cells, id, reversed) }, value: Reference(id) }
			}
			"forEach" => Interp.array_walk(machine, id, arguments, ForEach, w)
			"map" => Interp.array_walk(machine, id, arguments, Map, w)
			"filter" => Interp.array_walk(machine, id, arguments, Filter, w)
			"some" => Interp.array_walk(machine, id, arguments, Some, w)
			"every" => Interp.array_walk(machine, id, arguments, Every, w)
			"find" => Interp.array_walk(machine, id, arguments, Find, w)
			"findIndex" => Interp.array_walk(machine, id, arguments, FindIndex, w)
			"reduce" => Interp.array_reduce(machine, id, arguments, w)
			"sort" => Interp.array_sort(machine, id, arguments, w)
			_ => Interp.fault_got(machine, "unsupported: the array method `${name}`${Interp.at_line(w)}")
		}

	Walk : [ForEach, Map, Filter, Some, Every, Find, FindIndex]

	# An array method that calls a function on each item in turn, the items
	# read from the heap as it goes, since the function may change the array.
	array_walk : Interp.Machine, U64, List(Heap.Value), Interp.Walk, Ast.Where -> Interp.Got
	array_walk = |machine, id, arguments, walk, w| {
		f = arguments.first() ?? Undefined
		n = Interp.item_count(machine, id)
		var $s = machine
		var $out = []
		var $answer = match walk {
			Some => Boolean(False)
			Every => Boolean(True)
			Find => Undefined
			FindIndex => Number(-1.0)
			_ => Undefined
		}
		var $i = 0
		var $going = True
		while $going and $i < n and $i < Interp.item_count($s, id) {
			item = Interp.item_at($s, id, $i)
			{ machine: after, value } = Interp.call(
				$s,
				f,
				[item, Number($i.to_f64()), Reference(id)],
				w,
			)
			$s = after
			match walk {
				ForEach => {}
				Map => {
					$out = $out.append(value)
				}
				Filter => {
					if Interp.is_truthy(value) {
						$out = $out.append(item)
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
			}
			$going = $going and Interp.is_running($s)
			$i = $i + 1
		}
		match walk {
			Map => Interp.alloc($s, Array($out))
			Filter => Interp.alloc($s, Array($out))
			_ => { machine: $s, value: $answer }
		}
	}

	array_reduce : Interp.Machine, U64, List(Heap.Value), Ast.Where -> Interp.Got
	array_reduce = |machine, id, arguments, w| {
		f = arguments.first() ?? Undefined
		n = Interp.item_count(machine, id)
		start = match arguments.get(1) {
			Ok(v) => Ok({ accumulated: v, from: 0 })
			Err(OutOfBounds) => {
				if n == 0 {
					Err(Empty)
				} else {
					Ok({ accumulated: Interp.item_at(machine, id, 0), from: 1 })
				}
			}
		}
		match start {
			Err(Empty) => Interp.fault_got(
				machine,
				"TypeError: Reduce of empty array with no initial value${Interp.at_line(w)}",
			)
			Ok({ accumulated, from }) => {
				var $s = machine
				var $accumulated = accumulated
				var $i = from
				while $i < n and $i < Interp.item_count($s, id) and Interp.is_running($s) {
					item = Interp.item_at($s, id, $i)
					{ machine: after, value } = Interp.call(
						$s,
						f,
						[
							$accumulated,
							item,
							Number($i.to_f64()),
							Reference(id),
						],
						w,
					)
					$s = after
					$accumulated = value
					$i = $i + 1
				}
				{ machine: $s, value: $accumulated }
			}
		}
	}

	# `sort`, stable as JavaScript's is: a merge sort, the comparison a
	# function's answer or, with none, the items' text.
	array_sort : Interp.Machine, U64, List(Heap.Value), Ast.Where -> Interp.Got
	array_sort = |machine, id, arguments, w| {
		items = Interp.items_of(machine, id)
		compare = arguments.first() ?? Undefined
		{ machine: after, values } = Interp.merge_sorted(machine, items, compare, w)
		if Interp.is_running(after) {
			{ machine: { ..after, cells: Heap.with_items(after.cells, id, values) }, value: Reference(id) }
		} else {
			{ machine: after, value: Reference(id) }
		}
	}

	merge_sorted : Interp.Machine, List(Heap.Value), Heap.Value, Ast.Where -> Interp.Evaluations
	merge_sorted = |machine, items, compare, w| {
		n = items.len()
		if n <= 1 {
			{ machine: machine, values: items }
		} else {
			half = n // 2
			{ machine: first, values: lower } = Interp.merge_sorted(
				machine,
				items.sublist({ start: 0, len: half }),
				compare,
				w,
			)
			{ machine: second, values: upper } = Interp.merge_sorted(
				first,
				items.drop_first(half),
				compare,
				w,
			)
			var $s = second
			var $out = []
			var $i = 0
			var $j = 0
			while $i < lower.len() or $j < upper.len() {
				take_left = if $i >= lower.len() {
					False
				} else if $j >= upper.len() {
					True
				} else {
					a = lower.get($i) ?? crash "Interp.merge_sorted: inside the lower half"
					b = upper.get($j) ?? crash "Interp.merge_sorted: inside the upper half"
					{ machine: after, order } = Interp.compared(
						$s,
						{
							compare: compare,
							left: a,
							right: b,
							at: w,
						},
					)
					$s = after
					order != After
				}
				if take_left {
					$out = $out.append(lower.get($i) ?? crash "Interp.merge_sorted: inside the lower half")
					$i = $i + 1
				} else {
					$out = $out.append(upper.get($j) ?? crash "Interp.merge_sorted: inside the upper half")
					$j = $j + 1
				}
			}
			{ machine: $s, values: $out }
		}
	}

	# Two items of a sort, `left` and `right`, and the function that compares
	# them, or Undefined for none.
	Comparison : {
		compare : Heap.Value,
		left : Heap.Value,
		right : Heap.Value,
		at : Ast.Where,
	}

	Ordered : { machine : Interp.Machine, order : [Before, Same, After] }

	compared : Interp.Machine, Interp.Comparison -> Interp.Ordered
	compared = |machine, comparison| {
		{
			compare,
			left: a,
			right: b,
			at: w,
		} = comparison
		match compare {
			Undefined => {
				order = match (a, b) {
					(Undefined, Undefined) => Same
					(Undefined, _) => After
					(_, Undefined) => Before
					_ => match (Interp.text_of(machine.cells, a), Interp.text_of(machine.cells, b)) {
						(Ok(x), Ok(y)) => Interp.ordering_of_text(x, y)
						_ => Same
					}
				}
				{ machine: machine, order: order }
			}
			_ => {
				{ machine: after, value } = Interp.call(machine, compare, [a, b], w)
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
		"toUpperCase",
		"toLowerCase",
		"trim",
	]

	text_method : Interp.Machine, Str, Str, List(Heap.Value), Ast.Where -> Interp.Got
	text_method = |machine, s, name, arguments, w|
		if Interp.positional_methods.contains(name) and !Interp.is_ascii(s) {
			Interp.fault_got(
				machine,
				"unsupported: `${name}` on a string with non-ASCII text${Interp.at_line(w)}",
			)
		} else if name == "split" and arguments.first() == Ok(Text("")) and !Interp.is_ascii(s) {
			Interp.fault_got(
				machine,
				"unsupported: `split` into characters of a string with non-ASCII text${Interp.at_line(w)}",
			)
		} else {
			Interp.text_method_of(machine, s, name, arguments, w)
		}

	text_method_of : Interp.Machine, Str, Str, List(Heap.Value), Ast.Where -> Interp.Got
	text_method_of = |machine, s, name, arguments, w| {
		text_argument = |i| match arguments.get(i) {
			Ok(Text(t)) => Ok(t)
			_ => Err(NotText)
		}
		bytes = s.to_utf8()
		n = bytes.len()
		sliced = |from, to|
			if to > from {
				Text(
					Str.from_utf8(
						bytes.sublist({ start: from, len: to - from }),
					) ?? crash "Interp.text_method: an ASCII cut",
				)
			} else {
				Text("")
			}
		match name {
			"charAt" => (
				match Interp.index_of(arguments.first() ?? Number(0.0)) {
					Ok(i) => {
						got = Interp.char_at(machine, s, i, w)
						match got.value {
							Undefined => { machine: machine, value: Text("") }
							_ => got
						}
					}
					Err(NotIndex) => { machine: machine, value: Text("") }
				},
			)
			"charCodeAt" => (
				match Interp.index_of(arguments.first() ?? Number(0.0)) {
					Ok(i) => match bytes.get(i) {
						Ok(c) => { machine: machine, value: Number(c.to_f64()) }
						Err(OutOfBounds) => { machine: machine, value: Number(0.0 / 0.0) }
					}
					Err(NotIndex) => { machine: machine, value: Number(0.0 / 0.0) }
				},
			)
			"slice" => (
				{
					from = Interp.relative_index(arguments.get(0) ?? Undefined, n, 0)
					to = Interp.relative_index(arguments.get(1) ?? Undefined, n, n)
					{ machine: machine, value: sliced(from, to) }
				},
			)
			"substring" => (
				{
					clamp = |v, otherwise| match v {
						Number(x) => if x.is_nan() or x < 0.0 {
							0
						} else if x >= n.to_f64() {
							n
						} else {
							x.div_trunc_by(1.0).to_u64_try() ?? 0
						}
						_ => otherwise
					}
					a = clamp(arguments.get(0) ?? Undefined, 0)
					b = clamp(arguments.get(1) ?? Undefined, n)
					{ machine: machine, value: sliced(U64.min(a, b), U64.max(a, b)) }
				},
			)
			"indexOf" => match text_argument(0) {
				Ok(t) => { machine: machine, value: Number(Interp.text_index(s, t)) }
				Err(NotText) => Interp.fault_got(
					machine,
					"unsupported: `indexOf` of anything but a string${Interp.at_line(w)}",
				)
			}
			"includes" => match text_argument(0) {
				Ok(t) => { machine: machine, value: Boolean(s.contains(t)) }
				Err(NotText) => Interp.fault_got(
					machine,
					"unsupported: `includes` of anything but a string${Interp.at_line(w)}",
				)
			}
			"startsWith" => match text_argument(0) {
				Ok(t) => { machine: machine, value: Boolean(s.starts_with(t)) }
				Err(NotText) => Interp.fault_got(
					machine,
					"unsupported: `startsWith` of anything but a string${Interp.at_line(w)}",
				)
			}
			"endsWith" => match text_argument(0) {
				Ok(t) => { machine: machine, value: Boolean(s.ends_with(t)) }
				Err(NotText) => Interp.fault_got(
					machine,
					"unsupported: `endsWith` of anything but a string${Interp.at_line(w)}",
				)
			}
			"toUpperCase" => { machine: machine, value: Text(s.with_ascii_uppercased()) }
			"toLowerCase" => { machine: machine, value: Text(s.with_ascii_lowercased()) }
			"trim" => { machine: machine, value: Text(Interp.ascii_trimmed(s)) }
			"repeat" => match arguments.first() {
				Ok(Number(k)) if k >= 0.0 and k.div_trunc_by(1.0) == k and k < 100000000.0 => {
					{ machine: machine, value: Text(s.repeat(k.to_u64_try() ?? 0)) }
				}
				_ => Interp.fault_got(
					machine,
					"unsupported: `repeat` of anything but a whole number of times${Interp.at_line(w)}",
				)
			}
			"split" => match text_argument(0) {
				Ok("") => Interp.alloc(machine, Array(Interp.characters(s).map(|c| Text(c))))
				Ok(t) => Interp.alloc(machine, Array(s.split_on(t).map(|piece| Text(piece))))
				Err(NotText) => Interp.fault_got(
					machine,
					"unsupported: `split` by anything but a string${Interp.at_line(w)}",
				)
			}
			"padStart" => Interp.text_padded(machine, s, arguments, PadStart, w)
			"padEnd" => Interp.text_padded(machine, s, arguments, PadEnd, w)
			"concat" => {
				var $out = s
				var $why = ""
				for a in arguments {
					match Interp.text_of(machine.cells, a) {
						Ok(t) => {
							$out = Str.concat($out, t)
						}
						Err(Unsupported(why)) => {
							$why = why
						}
					}
				}
				if $why == "" {
					{ machine: machine, value: Text($out) }
				} else {
					Interp.fault_got(machine, "${$why}${Interp.at_line(w)}")
				}
			}
			_ => Interp.fault_got(
				machine,
				"unsupported: the string method `${name}`${Interp.at_line(w)}",
			)
		}
	}

	# Where `t` first starts in `s`, in bytes, or -1.
	text_index : Str, Str -> F64
	text_index = |s, t| {
		a = s.to_utf8()
		b = t.to_utf8()
		if b.len() > a.len() {
			-1.0
		} else {
			var $i = 0
			var $found = -1.0
			while $found < 0.0 and $i + b.len() <= a.len() {
				if a.sublist({ start: $i, len: b.len() }) == b {
					$found = $i.to_f64()
				}
				$i = $i + 1
			}
			$found
		}
	}

	ascii_trimmed : Str -> Str
	ascii_trimmed = |s| {
		b = s.to_utf8()
		is_space = |c| c == ' ' or c == '\t' or c == '\n' or c == '\r' or c == 11 or c == 12
		var $from = 0
		while $from < b.len() and is_space(b.get($from) ?? crash "Interp.ascii_trimmed: inside the text") {
			$from = $from + 1
		}
		var $to = b.len()
		while $to > $from and is_space(b.get($to - 1) ?? crash "Interp.ascii_trimmed: inside the text") {
			$to = $to - 1
		}
		Str.from_utf8(
			b.sublist({ start: $from, len: $to - $from }),
		) ?? crash "Interp.ascii_trimmed: an ASCII cut"
	}

	text_padded : Interp.Machine, Str, List(Heap.Value), [PadStart, PadEnd], Ast.Where -> Interp.Got
	text_padded = |machine, s, arguments, side, w| {
		fill = match arguments.get(1) {
			Ok(Text(f)) => Ok(f)
			Err(OutOfBounds) => Ok(" ")
			_ => Err(NotText)
		}
		match (arguments.first(), fill) {
			(Ok(Number(k)), Ok(f)) if Interp.is_ascii(s) and Interp.is_ascii(f) and k.div_trunc_by(1.0) == k and k < 100000000.0 => {
				n = s.count_utf8_bytes()
				target = if k < 0.0 {
					0
				} else {
					k.to_u64_try() ?? 0
				}
				if target <= n or f.is_empty() {
					{ machine: machine, value: Text(s) }
				} else {
					need = target - n
					fill_bytes = f.to_utf8()
					copies = need // fill_bytes.len() + 1
					pad = Str.from_utf8(
						f.repeat(copies).to_utf8().sublist({ start: 0, len: need }),
					) ?? crash "Interp.text_padded: an ASCII cut"
					match side {
						PadStart => { machine: machine, value: Text(Str.concat(pad, s)) }
						PadEnd => { machine: machine, value: Text(Str.concat(s, pad)) }
					}
				}
			}
			_ => Interp.fault_got(
				machine,
				"unsupported: `padStart` or `padEnd` other than to a whole length with ASCII text${Interp.at_line(w)}",
			)
		}
	}
}
