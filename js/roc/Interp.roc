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

	## A variable's value, and whether it may be written or read yet.
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

	## An expression's value, and the machine after it.
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
			made = Interp.alloc($s, Builtin(native, []))
			$s = made.machine
			$math_properties = $math_properties.append({
				key: Heap.native_name(native),
				value: made.value,
			})
		}
		math_object = Interp.alloc($s, Namespace("Math", $math_properties))
		$s = math_object.machine
		var $object_properties = []
		for native in [Keys, Values, Entries] {
			made = Interp.alloc($s, Builtin(native, []))
			$s = made.machine
			$object_properties = $object_properties.append({
				key: Heap.native_name(native),
				value: made.value,
			})
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
	with_fault : Interp.Machine, Str -> Interp.Machine
	with_fault = |machine, why|
		match machine.status {
			Running => { ..machine, status: Faulted(why) }
			Faulted(_) => machine
		}

	fault_got : Interp.Machine, Str -> Interp.Got
	fault_got = |machine, why| { machine: Interp.with_fault(machine, why), value: Undefined }

	line_note : Ast.Where -> Str
	line_note = |site| " (line ${site.line.to_str()})"

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
			Ok({ parent: Within(parent), variables: _ }) => parent
			_ => crash "Interp.parent_of: Resolve counts no more scopes out than there are"
		}

	variable_at : List(Interp.Scope), U64, U64 -> Interp.Variable
	variable_at = |scopes, scope_id, index| {
		scope = scopes.get(scope_id) ?? crash "Interp.variable_at: a scope the machine has"
		scope.variables.get(index) ?? crash "Interp.variable_at: a variable its scope's layout names"
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
		) ?? crash "Interp.with_variable: a scope the machine has"
		taken.list.set(
			scope_id,
			Interp.scope_with_variable(taken.prev, index, binding),
		) ?? crash "Interp.with_variable: the scope was just taken"
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
			) ?? crash "Interp.scope_with_variable: a variable the scope has",
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
	with_scope_entered : Interp.Machine, Interp.Parent, U64 -> Interp.Machine
	with_scope_entered = |machine, parent, size| Interp.with_scope_added(
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
	out_of_scope : Interp.Machine, U64, U64, Ast.Capture -> Interp.Machine
	out_of_scope = |machine, inner, outer, capture| {
		drops = capture == CapturesNothing and inner + 1 == machine.live_scopes
		if drops {
			{ ..machine, live_scopes: inner, scope: outer }
		} else {
			{ ..machine, scope: outer }
		}
	}

	# The functions a block declares, made before its first statement. Its
	# `let` and `const` names stay unready until their statement runs.
	with_functions_hoisted : Interp.Machine, List(Ast.Statement) -> Interp.Machine
	with_functions_hoisted = |machine, statements| {
		var $s = machine
		for statement in statements {
			match statement {
				FunctionDeclaration(definition, slot) => {
					{ machine: made, value: function } = Interp.alloc(
						$s,
						Fun({ fun: definition, scope: $s.scope }),
					)
					$s = Interp.declare(made, slot, function, Mutable)
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
				inner = Interp.with_functions_hoisted(
					Interp.with_scope_entered(machine, Within(outer), names.len()),
					block.statements,
				)
				id = inner.scope
				{ machine: after, flow } = Interp.execute_list(inner, block.statements)
				{ machine: Interp.out_of_scope(after, id, outer, block.capture), flow: flow }
			}
		}

	execute_list : Interp.Machine, List(Ast.Statement) -> Interp.Done
	execute_list = |machine, statements| {
		var $s = machine
		var $flow = Normal
		for statement in statements {
			if $flow == Normal and Interp.is_running($s) {
				{ machine: after, flow } = Interp.execute(Interp.one_step_on($s), statement)
				$s = after
				$flow = flow
			}
		}
		{ machine: $s, flow: $flow }
	}

	# The machine one step on, stopped when it passes its step budget.
	one_step_on : Interp.Machine -> Interp.Machine
	one_step_on = |machine|
		if machine.steps >= machine.step_limit {
			Interp.with_fault(
				machine,
				"the program ran past its budget of ${machine.step_limit.to_str()} steps",
			)
		} else {
			{ ..machine, steps: machine.steps + 1 }
		}

	execute : Interp.Machine, Ast.Statement -> Interp.Done
	execute = |machine, statement|
		match statement {
			Expression(expression) => {
				{ machine: after, value: _ } = Interp.evaluate(machine, expression)
				Interp.normal(after)
			}
			Declare(binding, declarations) => {
				var $s = machine
				for right_byte in declarations {
					if Interp.is_running($s) {
						{ machine: made, value } = match right_byte.init {
							Initialized(expression) => Interp.evaluate($s, expression)
							Uninitialized => { machine: $s, value: Undefined }
						}
						state = match binding {
							Let => Mutable
							Const => Fixed
						}
						$s = Interp.declare(made, right_byte.slot, value, state)
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
			ForOf(loop) => Interp.execute_iteration(machine, loop)
			BlockStatement(block) => Interp.execute_block(machine, block)
			Return(expression) => {
				{ machine: after, value } = Interp.evaluate(machine, expression)
				{ machine: after, flow: Returned(value) }
			}
			Break => { machine: machine, flow: Broke }
			Continue => { machine: machine, flow: Continued }
			Empty => Interp.normal(machine)
		}

	# How a loop goes on after its body: on, or out with the flow the loop
	# itself answers.
	body_outcome : Interp.Flow -> [GoOn, Leave(Interp.Flow)]
	body_outcome = |flow| match flow {
		Normal => GoOn
		Continued => GoOn
		Broke => Leave(Normal)
		Returned(subject) => Leave(Returned(subject))
	}

	execute_while : Interp.Machine, Ast.Expression, Ast.Statement -> Interp.Done
	execute_while = |machine, test, body| {
		var $s = machine
		var $flow = Normal
		var $going = True
		while $going {
			{ machine: tested, value } = Interp.evaluate(Interp.one_step_on($s), test)
			if !Interp.is_running(tested) or !Interp.is_truthy(value) {
				$s = tested
				$going = False
			} else {
				{ machine: after, flow } = Interp.execute(tested, body)
				$s = after
				match Interp.body_outcome(flow) {
					GoOn => {
						$going = Interp.is_running($s)
					}
					Leave(leaving) => {
						$flow = leaving
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
		start = Interp.with_scope_entered(machine, Within(outer), loop.names.len())
		{ machine: begun, flow: _ } = Interp.execute(start, loop.init)
		var $s = begun
		var $flow = Normal
		var $going = Interp.is_running($s)
		while $going {
			{ machine: tested, value } = match loop.test {
				Tested(expression) => Interp.evaluate(Interp.one_step_on($s), expression)
				Always => { machine: Interp.one_step_on($s), value: Boolean(True) }
			}
			if !Interp.is_running(tested) or !Interp.is_truthy(value) {
				$s = tested
				$going = False
			} else {
				{ machine: after, flow } = Interp.execute(tested, loop.body)
				match Interp.body_outcome(flow) {
					GoOn => {
						# **EACH PASS HAS ITS OWN `let`**, as JavaScript gives a
						# closure made in the body the pass's own variable. The
						# copy is made only where the body holds a closure.
						next_pass = match loop.capture {
							Captures => Interp.copied_scope(after)
							CapturesNothing => after
						}
						$s = match loop.update {
							Updated(expression) => Interp.machine_after(next_pass, expression)
							NoUpdate => next_pass
						}
						$going = Interp.is_running($s)
					}
					Leave(leaving) => {
						$s = after
						$flow = leaving
						$going = False
					}
				}
			}
		}
		{ machine: Interp.out_of_scope($s, $s.scope, outer, loop.capture), flow: $flow }
	}

	# The machine in a copy of its current scope, beside the old one.
	copied_scope : Interp.Machine -> Interp.Machine
	copied_scope = |machine| {
		scope = machine.scopes.get(machine.scope) ?? crash "Interp.copied_scope: the current scope is one the machine has"
		Interp.with_scope_added(machine, scope)
	}

	execute_iteration : Interp.Machine, Ast.ForOfLoop -> Interp.Done
	execute_iteration = |machine, loop| {
		{ machine: got, value: iterable } = Interp.evaluate(machine, loop.iterable)
		state = match loop.binding {
			Let => Mutable
			Const => Fixed
		}
		match iterable {
			Reference(id) => match Interp.kind_of(got.cells, id) {
				ArrayKind(_) => Interp.execute_for_of_array(got, loop, id, state)
				_ => Interp.normal(
					Interp.with_fault(
						got,
						"unsupported: `for ... of` over anything but an array or a string${Interp.line_note(loop.at)}",
					),
				)
			}
			Text(text) => Interp.execute_for_of_text(got, loop, text, state)
			_ => Interp.normal(
				Interp.with_fault(
					got,
					"TypeError: the value is not iterable${Interp.line_note(loop.at)}",
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
				subject = Interp.item_at($s, id, $i)
				{ machine: after, flow } = Interp.execute_for_of_pass(
					Interp.one_step_on($s),
					loop,
					{ value: subject, state: state },
				)
				$s = after
				$i = $i + 1
				match Interp.body_outcome(flow) {
					GoOn => {
						$going = Interp.is_running($s)
					}
					Leave(leaving) => {
						$flow = leaving
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
		for character in Interp.characters(text) {
			if $going {
				{ machine: after, flow } = Interp.execute_for_of_pass(
					Interp.one_step_on($s),
					loop,
					{ value: Text(character), state: state },
				)
				$s = after
				match Interp.body_outcome(flow) {
					GoOn => {
						$going = Interp.is_running($s)
					}
					Leave(leaving) => {
						$flow = leaving
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
		bytes = text.to_utf8()
		var $out = []
		var $i = 0
		while $i < bytes.len() {
			lead = bytes.get($i) ?? crash "Interp.characters: inside the text"
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
				) ?? crash "Interp.characters: a whole character",
			)
			$i = $i + width
		}
		$out
	}

	# One pass of a `for ... of`, its variable `binding`.
	execute_for_of_pass : Interp.Machine, Ast.ForOfLoop, Interp.Variable -> Interp.Done
	execute_for_of_pass = |machine, loop, binding| {
		outer = machine.scope
		inner = Interp.with_scope_added(machine, { variables: [binding], parent: Within(outer) })
		id = inner.scope
		{ machine: after, flow } = Interp.execute(inner, loop.body)
		{ machine: Interp.out_of_scope(after, id, outer, loop.capture), flow: flow }
	}

	# ---- values ----------------------------------------------------------------

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
		_ => Interp.is_strictly_equal(left, right)
	}

	# What `String(v)` gives, for the values whose text the subset has.
	text_of : List(Heap.Cell), Heap.Value -> Try(Str, [Unsupported(Str)])
	text_of = |cells, subject| Interp.text_of_seen(cells, subject, [])

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
		_ => Inspect.inspect(cells, subject) ?? Interp.type_of(cells, subject)
	}

	# ---- expressions -----------------------------------------------------------

	evaluate : Interp.Machine, Ast.Expression -> Interp.Got
	evaluate = |machine, tree|
		match tree {
			Number(number) => { machine: machine, value: Number(number) }
			Text(text) => { machine: machine, value: Text(text) }
			Boolean(truth) => { machine: machine, value: Boolean(truth) }
			Null => { machine: machine, value: Null }
			Undefined => { machine: machine, value: Undefined }
			Template(texts, parts) => Interp.evaluate_template(machine, texts, parts)
			Name(name, slot, site) => Interp.evaluate_name(machine, name, slot, site)
			ArrayLit(items) => {
				{ machine: after, values } = Interp.evaluate_all(machine, items)
				Interp.alloc(after, Array(values))
			}
			ObjectLit(properties) => {
				var $s = machine
				var $made = []
				for parent in properties {
					{ machine: after, value } = Interp.evaluate($s, parent.value)
					$s = after
					$made = Heap.properties_with($made, parent.key, value)
				}
				Interp.alloc($s, Object($made))
			}
			Unary(operator, expression, site) => {
				{ machine: after, value } = Interp.evaluate(machine, expression)
				Interp.unary(after, operator, value, site)
			}
			Binary(operator, left, right, site) => {
				{ machine: first, value: left_value } = Interp.evaluate(machine, left)
				{ machine: second, value: right_value } = Interp.evaluate(first, right)
				Interp.binary(second, operator, left_value, right_value, site)
			}
			Logical(operator, left, right) => {
				{ machine: first, value: left_value } = Interp.evaluate(machine, left)
				decided = match operator {
					And => !Interp.is_truthy(left_value)
					Or => Interp.is_truthy(left_value)
					Nullish => left_value != Null and left_value != Undefined
				}
				if decided {
					{ machine: first, value: left_value }
				} else {
					Interp.evaluate(first, right)
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
			Assign(target, operator, expression, site) => Interp.evaluate_assign(
				machine,
				{
					target: target,
					operator: operator,
					value: expression,
					at: site,
				},
			)
			Update(target, step, fixity, site) => Interp.evaluate_update(
				machine,
				target,
				step,
				fixity,
				site,
			)
			Member(object, key, site) => {
				{ machine: after, value: holder } = Interp.evaluate(machine, object)
				Interp.property(after, holder, key, site)
			}
			Index(object, key, site) => {
				{ machine: first, value: holder } = Interp.evaluate(machine, object)
				{ machine: second, value: key_value } = Interp.evaluate(first, key)
				Interp.indexed_value(second, holder, key_value, site)
			}
			Call(callee, arguments, site) => Interp.evaluate_call(machine, callee, arguments, site)
			Function(definition) => Interp.alloc(
				machine,
				Fun({ fun: definition, scope: machine.scope }),
			)
		}

	# The machine after an expression whose value is not wanted.
	machine_after : Interp.Machine, Ast.Expression -> Interp.Machine
	machine_after = |machine, expression| {
		{ machine: after, value: _ } = Interp.evaluate(machine, expression)
		after
	}

	Evaluations : { machine : Interp.Machine, values : List(Heap.Value) }

	evaluate_all : Interp.Machine, List(Ast.Expression) -> Interp.Evaluations
	evaluate_all = |machine, expressions| {
		var $s = machine
		var $values = []
		for expression in expressions {
			{ machine: after, value } = Interp.evaluate($s, expression)
			$s = after
			$values = $values.append(value)
		}
		{ machine: $s, values: $values }
	}

	evaluate_template : Interp.Machine, List(Str), List(Ast.Expression) -> Interp.Got
	evaluate_template = |machine, texts, parts| {
		var $s = machine
		var $text = texts.first() ?? crash "Interp.evaluate_template: a template has a text piece before its first substitution"
		var $i = 1
		for part in parts {
			{ machine: after, value } = Interp.evaluate($s, part)
			$s = match Interp.text_of(after.cells, value) {
				Ok(phrase) => {
					$text = Str.concat(
						Str.concat($text, phrase),
						texts.get($i) ?? crash "Interp.evaluate_template: a template has a text piece after each substitution",
					)
					after
				}
				Err(Unsupported(why)) => Interp.with_fault(after, why)
			}
			$i = $i + 1
		}
		{ machine: $s, value: Text($text) }
	}

	evaluate_name : Interp.Machine, Str, Ast.Slot, Ast.Where -> Interp.Got
	evaluate_name = |machine, name, slot, site|
		match Interp.place_of(machine, slot) {
			At({ scope, index }) => {
				binding = Interp.variable_at(machine.scopes, scope, index)
				match binding.state {
					Unready => Interp.fault_got(
						machine,
						"ReferenceError: Cannot access '${name}' before initialization${Interp.line_note(site)}",
					)
					_ => { machine: machine, value: binding.value }
				}
			}
			Nowhere => Interp.fault_got(machine, Interp.missing_name_message(name, site))
		}

	missing_name_message : Str, Ast.Where -> Str
	missing_name_message = |name, site|
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
			"unsupported: the builtin `${name}`${Interp.line_note(site)}"
		} else {
			"ReferenceError: ${name} is not defined${Interp.line_note(site)}"
		}

	unary : Interp.Machine, Ast.UnaryOperator, Heap.Value, Ast.Where -> Interp.Got
	unary = |machine, operator, subject, site|
		match operator {
			Not => { machine: machine, value: Boolean(!Interp.is_truthy(subject)) }
			TypeOf => { machine: machine, value: Text(Interp.type_of(machine.cells, subject)) }
			Negate => match subject {
				Number(number) => { machine: machine, value: Number(-number) }
				_ => Interp.fault_got(
					machine,
					"unsupported: `-` on a ${Interp.type_of(machine.cells, subject)} (a coercion)${Interp.line_note(site)}",
				)
			}
			Plus => match subject {
				Number(number) => { machine: machine, value: Number(number) }
				_ => Interp.fault_got(
					machine,
					"unsupported: `+` on a ${Interp.type_of(machine.cells, subject)} (a coercion)${Interp.line_note(site)}",
				)
			}
		}

	binary : Interp.Machine, Ast.BinaryOperator, Heap.Value, Heap.Value, Ast.Where -> Interp.Got
	binary = |machine, operator, left, right, site|
		match operator {
			StrictEqual => {
				machine: machine,
				value: Boolean(Interp.is_strictly_equal(left, right)),
			}
			StrictNotEqual => {
				machine: machine,
				value: Boolean(!Interp.is_strictly_equal(left, right)),
			}
			Add => Interp.add(machine, left, right, site)
			_ => match (left, right) {
				(Number(x), Number(y)) => {
					machine: machine,
					value: Interp.arithmetic(operator, x, y),
				}
				(Text(x), Text(y)) => match operator {
					Less => {
						machine: machine,
						value: Boolean(Interp.ordering_of_text(x, y) == Before),
					}
					LessOrEqual => {
						machine: machine,
						value: Boolean(Interp.ordering_of_text(x, y) != After),
					}
					Greater => {
						machine: machine,
						value: Boolean(Interp.ordering_of_text(x, y) == After),
					}
					GreaterOrEqual => {
						machine: machine,
						value: Boolean(Interp.ordering_of_text(x, y) != Before),
					}
					_ => Interp.fault_got(
						machine,
						"unsupported: arithmetic on strings (a coercion)${Interp.line_note(site)}",
					)
				}
				_ => Interp.fault_got(
					machine,
					"unsupported: an operator on a ${Interp.type_of(machine.cells, left)} and a ${Interp.type_of(machine.cells, right)} (a coercion)${Interp.line_note(site)}",
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
						Interp.text_of(machine.cells, left),
						Interp.text_of(machine.cells, right),
					) {
						(Ok(x), Ok(y)) => { machine: machine, value: Text(Str.concat(x, y)) }
						(Err(Unsupported(why)), _) => Interp.fault_got(
							machine,
							"${why}${Interp.line_note(site)}",
						)
						(_, Err(Unsupported(why))) => Interp.fault_got(
							machine,
							"${why}${Interp.line_note(site)}",
						)
					}
				} else {
					Interp.fault_got(
						machine,
						"unsupported: `+` on a ${Interp.type_of(machine.cells, left)} and a ${Interp.type_of(machine.cells, right)} (a coercion)${Interp.line_note(site)}",
					)
				}
			}
		}

	# What a variable or a property held, and the value an assignment gives it.
	Change : { old : Heap.Value, new : Heap.Value }

	combination : Interp.Machine, Ast.AssignmentOperator, Interp.Change, Ast.Where -> Interp.Got
	combination = |machine, operator, change, site| {
		{ old, new } = change
		match operator {
			Set => { machine: machine, value: new }
			Combine(binary_operator) => Interp.binary(machine, binary_operator, old, new, site)
		}
	}

	## An assignment's parts, as `Ast.Assign` holds them: the target, the
	## operator and the expression of the assignment's value.
	Assignment : {
		target : Ast.Target,
		operator : Ast.AssignmentOperator,
		value : Ast.Expression,
		at : Ast.Where,
	}

	evaluate_assign : Interp.Machine, Interp.Assignment -> Interp.Got
	evaluate_assign = |machine, assignment| {
		{
			target,
			operator,
			value: expression,
			at: site,
		} = assignment
		match target {
			ToName(name, slot, at) => {
				match Interp.place_of(machine, slot) {
					Nowhere => Interp.fault_got(
						machine,
						"unsupported: assigning to `${name}`, which is not declared${Interp.line_note(at)}",
					)
					At({ scope, index }) => {
						facts = Interp.variable_facts(machine.scopes, scope, index)
						appends = operator == Combine(Add) and facts.state == Mutable and facts.holds_text and Interp.is_pure(expression)
						if appends {
							Interp.appended_name(machine, scope, index, expression, site)
						} else {
							old = Interp.variable_value(machine.scopes, scope, index)
							{ machine: after, value } = Interp.evaluate(machine, expression)
							{ machine: made, value: result } = Interp.combination(
								after,
								operator,
								{ old: old, new: value },
								site,
							)
							Interp.assigned_name(made, result, name, slot, at)
						}
					}
				}
			}
			ToMember(object, key) => {
				{ machine: first, value: holder } = Interp.evaluate(machine, object)
				{ machine: second, value: old } = match operator {
					Set => { machine: first, value: Undefined }
					Combine(_) => Interp.property(first, holder, key, site)
				}
				{ machine: third, value } = Interp.evaluate(second, expression)
				{ machine: made, value: result } = Interp.combination(
					third,
					operator,
					{ old: old, new: value },
					site,
				)
				Interp.with_stored(
					made,
					holder,
					Text(key),
					result,
					site,
				)
			}
			ToIndex(object, key) => {
				{ machine: first, value: holder } = Interp.evaluate(machine, object)
				{ machine: second, value: key_value } = Interp.evaluate(first, key)
				{ machine: third, value: old } = match operator {
					Set => { machine: second, value: Undefined }
					Combine(_) => Interp.indexed_value(second, holder, key_value, site)
				}
				{ machine: fourth, value } = Interp.evaluate(third, expression)
				{ machine: made, value: result } = Interp.combination(
					fourth,
					operator,
					{ old: old, new: value },
					site,
				)
				Interp.with_stored(made, holder, key_value, result, site)
			}
		}
	}

	# A variable written, its place found again after the value was made:
	# making it may have run code that added scopes.
	assigned_name : Interp.Machine, Heap.Value, Str, Ast.Slot, Ast.Where -> Interp.Got
	assigned_name = |machine, value, name, slot, site|
		if !Interp.is_running(machine) {
			{ machine: machine, value: value }
		} else {
			match Interp.place_of(machine, slot) {
				At({ scope, index }) => match Interp.variable_facts(
					machine.scopes,
					scope,
					index,
				).state {
					Mutable => Interp.variable_written(
						machine,
						scope,
						index,
						{ value: value, state: Mutable },
					)
					Fixed => Interp.fault_got(
						machine,
						"TypeError: Assignment to constant variable.${Interp.line_note(site)}",
					)
					Unready => Interp.fault_got(
						machine,
						"ReferenceError: Cannot access '${name}' before initialization${Interp.line_note(site)}",
					)
				}
				Nowhere => Interp.fault_got(
					machine,
					"ReferenceError: ${name} is not defined${Interp.line_note(site)}",
				)
			}
		}

	# What a variable is, with nothing of its value kept: a kept copy of a
	# string is a second reference to it.
	Facts : { state : Interp.VariableState, holds_text : Bool }

	variable_facts : List(Interp.Scope), U64, U64 -> Interp.Facts
	variable_facts = |scopes, scope_id, index| {
		binding = Interp.variable_at(scopes, scope_id, index)
		{ state: binding.state, holds_text: Interp.is_text(binding.value) }
	}

	is_text : Heap.Value -> Bool
	is_text = |subject| match subject {
		Text(_) => True
		_ => False
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
		Template(_, parts) => parts.all(Interp.is_pure)
		ArrayLit(items) => items.all(Interp.is_pure)
		ObjectLit(properties) => properties.all(|parent| Interp.is_pure(parent.value))
		Unary(_, left, _) => Interp.is_pure(left)
		Binary(_, left, right, _) => Interp.is_pure(left) and Interp.is_pure(right)
		Logical(_, left, right) => Interp.is_pure(left) and Interp.is_pure(right)
		Conditional(
			test,
			yes,
			no,
		) => Interp.is_pure(test) and Interp.is_pure(yes) and Interp.is_pure(no)
		Member(left, _, _) => Interp.is_pure(left)
		Index(left, right, _) => Interp.is_pure(left) and Interp.is_pure(right)
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
	appended_name = |machine, scope_id, index, expression, site| {
		{ machine: after, value: piece } = Interp.evaluate(machine, expression)
		if !Interp.is_running(after) {
			{ machine: after, value: Undefined }
		} else {
			match Interp.text_of(after.cells, piece) {
				Err(Unsupported(why)) => Interp.fault_got(after, "${why}${Interp.line_note(site)}")
				Ok(tail) => Interp.text_appended(after, scope_id, index, tail)
			}
		}
	}

	text_appended : Interp.Machine, U64, U64, Str -> Interp.Got
	text_appended = |machine, scope_id, index, tail| {
		grown = {
			..machine,
			scopes: Interp.scopes_with_appended(machine.scopes, scope_id, index, tail),
		}
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
		{ value: Interp.value_with_appended(value, tail), state: state }
	}

	value_with_appended : Heap.Value, Str -> Heap.Value
	value_with_appended = |value, tail| match value {
		Text(old) => Text(Str.concat(old, tail))
		_ => crash "Interp.value_with_appended: the interpreter appends only to a variable that holds a string"
	}

	variable_written : Interp.Machine, U64, U64, Interp.Variable -> Interp.Got
	variable_written = |machine, scope_id, index, binding| {
		machine: {
			..machine,
			scopes: Interp.with_variable(machine.scopes, scope_id, index, binding),
		},
		value: binding.value,
	}

	evaluate_update : Interp.Machine, Ast.Target, Ast.Step, Ast.Fixity, Ast.Where -> Interp.Got
	evaluate_update = |machine, target, step, fixity, site| {
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
				{
					machine: read_machine,
					value: current,
				} = Interp.evaluate_name(machine, name, slot, at)
				match current {
					Number(number) => {
						{ machine: written, value: _ } = Interp.assigned_name(
							read_machine,
							Number(number + delta),
							name,
							slot,
							at,
						)
						{ machine: written, value: answer(number, number + delta) }
					}
					_ => Interp.fault_got(
						read_machine,
						"unsupported: `++` or `--` on a ${Interp.type_of(read_machine.cells, current)}${Interp.line_note(site)}",
					)
				}
			}
			ToMember(object, key) => {
				{ machine: first, value: holder } = Interp.evaluate(machine, object)
				{
					machine: read_machine,
					value: current,
				} = Interp.property(first, holder, key, site)
				match current {
					Number(number) => {
						{ machine: written, value: _ } = Interp.with_stored(
							read_machine,
							holder,
							Text(key),
							Number(number + delta),
							site,
						)
						{ machine: written, value: answer(number, number + delta) }
					}
					_ => Interp.fault_got(
						read_machine,
						"unsupported: `++` or `--` on a ${Interp.type_of(read_machine.cells, current)}${Interp.line_note(site)}",
					)
				}
			}
			ToIndex(object, key) => {
				{ machine: first, value: holder } = Interp.evaluate(machine, object)
				{ machine: second, value: key_value } = Interp.evaluate(first, key)
				{
					machine: read_machine,
					value: current,
				} = Interp.indexed_value(second, holder, key_value, site)
				match current {
					Number(number) => {
						{ machine: written, value: _ } = Interp.with_stored(
							read_machine,
							holder,
							key_value,
							Number(number + delta),
							site,
						)
						{ machine: written, value: answer(number, number + delta) }
					}
					_ => Interp.fault_got(
						read_machine,
						"unsupported: `++` or `--` on a ${Interp.type_of(read_machine.cells, current)}${Interp.line_note(site)}",
					)
				}
			}
		}
	}

	# ---- properties ------------------------------------------------------------

	property : Interp.Machine, Heap.Value, Str, Ast.Where -> Interp.Got
	property = |machine, object, key, site|
		match object {
			Reference(id) => match Heap.cell_at(machine.cells, id) {
				Object(properties) => {
					if Heap.has_property(properties, key) {
						{ machine: machine, value: Heap.property_value(properties, key) }
					} else if Interp.is_prototype_name(key) {
						Interp.fault_got(
							machine,
							"unsupported: Object.prototype's `${key}`${Interp.line_note(site)}",
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
							Err(NotIndex) => Interp.fault_got(
								machine,
								"unsupported: the array property `${key}` outside a call${Interp.line_note(site)}",
							)
						}
					}
				}
				Namespace(name, properties) => {
					if Heap.has_property(properties, key) {
						{ machine: machine, value: Heap.property_value(properties, key) }
					} else {
						Interp.fault_got(
							machine,
							"unsupported: `${name}.${key}`${Interp.line_note(site)}",
						)
					}
				}
				Builtin(number, properties) => {
					if Heap.has_property(properties, key) {
						{ machine: machine, value: Heap.property_value(properties, key) }
					} else {
						Interp.fault_got(
							machine,
							"unsupported: `${Heap.native_name(number)}.${key}`${Interp.line_note(site)}",
						)
					}
				}
				Fun(_) => Interp.fault_got(
					machine,
					"unsupported: a function's properties (`${key}`)${Interp.line_note(site)}",
				)
				Taken => crash "Interp.property: no cell is out being written while a property is read"
			}
			Text(text) => {
				if key == "length" {
					if Interp.is_ascii(text) {
						{ machine: machine, value: Number(text.count_utf8_bytes().to_f64()) }
					} else {
						Interp.fault_got(
							machine,
							"unsupported: the length of a string with non-ASCII text${Interp.line_note(site)}",
						)
					}
				} else {
					match Inspect.index_of_key(key) {
						Ok(position) => Interp.char_at(machine, text, position, site)
						Err(NotIndex) => Interp.fault_got(
							machine,
							"unsupported: the string property `${key}` outside a call${Interp.line_note(site)}",
						)
					}
				}
			}
			Null => Interp.fault_got(
				machine,
				"TypeError: Cannot read properties of null (reading '${key}')${Interp.line_note(site)}",
			)
			Undefined => Interp.fault_got(
				machine,
				"TypeError: Cannot read properties of undefined (reading '${key}')${Interp.line_note(site)}",
			)
			_ => Interp.fault_got(
				machine,
				"unsupported: the property `${key}` of a ${Interp.type_of(machine.cells, object)}${Interp.line_note(site)}",
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
	is_ascii = |text| text.to_utf8().all(|byte| byte < 128)

	char_at : Interp.Machine, Str, U64, Ast.Where -> Interp.Got
	char_at = |machine, text, position, site|
		if !Interp.is_ascii(text) {
			Interp.fault_got(
				machine,
				"unsupported: indexing a string with non-ASCII text${Interp.line_note(site)}",
			)
		} else {
			match text.to_utf8().get(position) {
				Ok(byte) => {
					machine: machine,
					value: Text(Str.from_utf8([byte]) ?? crash "Interp.char_at: an ASCII byte"),
				}
				Err(OutOfBounds) => { machine: machine, value: Undefined }
			}
		}

	indexed_value : Interp.Machine, Heap.Value, Heap.Value, Ast.Where -> Interp.Got
	indexed_value = |machine, object, key, site|
		match (object, Interp.index_of(key)) {
			(Reference(id), Ok(position)) => match Heap.cell_at(machine.cells, id) {
				Array(items) => { machine: machine, value: items.get(position) ?? Undefined }
				_ => Interp.property_by_value(machine, object, key, site)
			}
			(Text(text), Ok(position)) => Interp.char_at(machine, text, position, site)
			_ => Interp.property_by_value(machine, object, key, site)
		}

	property_by_value : Interp.Machine, Heap.Value, Heap.Value, Ast.Where -> Interp.Got
	property_by_value = |machine, object, key, site|
		match Interp.key_of(key) {
			Ok(key_value) => Interp.property(machine, object, key_value, site)
			Err(Unsupported(why)) => Interp.fault_got(machine, "${why}${Interp.line_note(site)}")
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
	with_stored : Interp.Machine, Heap.Value, Heap.Value, Heap.Value, Ast.Where -> Interp.Got
	with_stored = |machine, object, key, value, site|
		if !Interp.is_running(machine) {
			{ machine: machine, value: value }
		} else {
			match object {
				Reference(id) => match Interp.kind_of(machine.cells, id) {
					ObjectKind => match Interp.key_of(key) {
						Ok(key_value) => {
							machine: {
								..machine,
								cells: Heap.with_property(machine.cells, id, key_value, value),
							},
							value: value,
						}
						Err(Unsupported(why)) => Interp.fault_got(
							machine,
							"${why}${Interp.line_note(site)}",
						)
					}
					ArrayKind(length) => {
						match Interp.index_of(key) {
							Ok(position) if position <= length => {
								machine: {
									..machine,
									cells: Heap.with_item(machine.cells, id, position, value),
								},
								value: value,
							}
							Ok(_) => Interp.fault_got(
								machine,
								"unsupported: an array with holes (a write past its end)${Interp.line_note(site)}",
							)
							Err(NotIndex) => Interp.fault_got(
								machine,
								"unsupported: writing an array's `length` or a named property${Interp.line_note(site)}",
							)
						}
					}
					_ => Interp.fault_got(
						machine,
						"unsupported: writing a property of a function or a builtin${Interp.line_note(site)}",
					)
				}
				Null => Interp.fault_got(
					machine,
					"TypeError: Cannot set properties of null${Interp.line_note(site)}",
				)
				Undefined => Interp.fault_got(
					machine,
					"TypeError: Cannot set properties of undefined${Interp.line_note(site)}",
				)
				_ => Interp.fault_got(
					machine,
					"unsupported: writing a property of a ${Interp.type_of(machine.cells, object)}${Interp.line_note(site)}",
				)
			}
		}

	# ---- calls -----------------------------------------------------------------

	evaluate_call : Interp.Machine, Ast.Expression, List(Ast.Expression), Ast.Where -> Interp.Got
	evaluate_call = |machine, callee, arguments, site|
		match callee {
			Member(object, name, _) => {
				{ machine: first, value: holder } = Interp.evaluate(machine, object)
				method = match holder {
					Reference(id) => match Interp.kind_of(first.cells, id) {
						ArrayKind(_) => ArrayMethod(id)
						_ => Plain
					}
					Text(text) => TextMethod(text)
					_ => Plain
				}
				match method {
					ArrayMethod(id) => {
						{ machine: second, values } = Interp.evaluate_all(first, arguments)
						Interp.array_method(second, id, name, values, site)
					}
					TextMethod(text) => {
						{ machine: second, values } = Interp.evaluate_all(first, arguments)
						Interp.text_method(second, text, name, values, site)
					}
					Plain => {
						{
							machine: second,
							value: function,
						} = Interp.property(first, holder, name, site)
						{ machine: third, values } = Interp.evaluate_all(second, arguments)
						Interp.call(third, function, values, site)
					}
				}
			}
			_ => {
				{ machine: first, value: function } = Interp.evaluate(machine, callee)
				{ machine: second, values } = Interp.evaluate_all(first, arguments)
				Interp.call(second, function, values, site)
			}
		}

	call : Interp.Machine, Heap.Value, List(Heap.Value), Ast.Where -> Interp.Got
	call = |machine, callee, arguments, site|
		if !Interp.is_running(machine) {
			{ machine: machine, value: Undefined }
		} else {
			match callee {
				Reference(id) => match Heap.cell_at(machine.cells, id) {
					Fun(closure) => Interp.call_closure(machine, closure, arguments, site)
					Builtin(native, _) => Interp.call_native(machine, native, arguments, site)
					_ => Interp.fault_got(
						machine,
						"TypeError: ${Interp.shown_value(machine.cells, callee)} is not a function${Interp.line_note(site)}",
					)
				}
				_ => Interp.fault_got(
					machine,
					"TypeError: ${Interp.shown_value(machine.cells, callee)} is not a function${Interp.line_note(site)}",
				)
			}
		}

	call_closure : Interp.Machine, Heap.Closure, List(Heap.Value), Ast.Where -> Interp.Got
	call_closure = |machine, closure, arguments, site|
		if machine.depth >= Interp.max_depth {
			Interp.fault_got(
				machine,
				"RangeError: Maximum call stack size exceeded${Interp.line_note(site)}",
			)
		} else {
			outer = machine.scope
			definition = closure.fun.unbox()
			inside = Interp.with_scope_added(
				{ ..machine, depth: machine.depth + 1 },
				{
					variables: Interp.call_variables(definition, arguments),
					parent: Within(closure.scope),
				},
			)
			id = inside.scope
			{ machine: after, flow } = Interp.execute_list(
				Interp.with_functions_hoisted(inside, definition.statements),
				definition.statements,
			)
			value = match flow {
				Returned(subject) => subject
				_ => Undefined
			}
			back = Interp.out_of_scope(after, id, outer, definition.capture)
			{ machine: { ..back, depth: back.depth - 1 }, value: value }
		}

	# A call's variables: each parameter holding its argument, then the rest
	# of the function's layout, unready.
	call_variables : Ast.FunctionDefinition, List(Heap.Value) -> List(Interp.Variable)
	call_variables = |definition, arguments| {
		parameters = definition.parameters.len()
		var $variables = List.with_capacity(definition.names.len())
		var $i = 0
		while $i < definition.names.len() {
			$variables = $variables.append(
				if $i < parameters {
					{ value: arguments.get($i) ?? Undefined, state: Mutable }
				} else {
					Interp.unready
				},
			)
			$i = $i + 1
		}
		$variables
	}

	number_argument : List(Heap.Value), U64 -> Try(F64, [NotNumber])
	number_argument = |arguments, position|
		match arguments.get(position) {
			Ok(Number(number)) => Ok(number)
			_ => Err(NotNumber)
		}

	math : Interp.Machine, Str, List(Heap.Value), (F64 -> F64), Ast.Where -> Interp.Got
	math = |machine, name, arguments, function, site|
		match Interp.number_argument(arguments, 0) {
			Ok(number) => { machine: machine, value: Number(function(number)) }
			Err(NotNumber) => Interp.fault_got(
				machine,
				"unsupported: Math.${name} of anything but a number${Interp.line_note(site)}",
			)
		}

	floor : F64 -> F64
	floor = |number|
		if number.is_nan() or number.is_infinite() or number == 0.0 {
			number
		} else {
			number.div_floor_by(1.0)
		}

	call_native : Interp.Machine, Heap.Native, List(Heap.Value), Ast.Where -> Interp.Got
	call_native = |machine, native, arguments, site|
		match native {
			Log => match Inspect.line_of(machine.cells, arguments) {
				Ok(line) => {
					machine: { ..machine, out: Str.concat(Str.concat(machine.out, line), "\n") },
					value: Undefined,
				}
				Err(Unsupported(why)) => Interp.fault_got(
					machine,
					"${why}${Interp.line_note(site)}",
				)
			}
			Floor => Interp.math(machine, "floor", arguments, Interp.floor, site)
			Ceil => Interp.math(
				machine,
				"ceil",
				arguments,
				|x| -Interp.floor(-x),
				site,
			)
			Round => Interp.math(
				machine,
				"round",
				arguments,
				|x| {
					floored = Interp.floor(x)
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
				site,
			)
			Abs => Interp.math(
				machine,
				"abs",
				arguments,
				|x| x.abs(),
				site,
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
				site,
			)
			Sqrt => Interp.math(
				machine,
				"sqrt",
				arguments,
				|x| x.sqrt(),
				site,
			)
			Sin => Interp.math(
				machine,
				"sin",
				arguments,
				|x| x.sin(),
				site,
			)
			Cos => Interp.math(
				machine,
				"cos",
				arguments,
				|x| x.cos(),
				site,
			)
			Tan => Interp.math(
				machine,
				"tan",
				arguments,
				|x| x.tan(),
				site,
			)
			Atan => Interp.math(
				machine,
				"atan",
				arguments,
				|x| x.atan(),
				site,
			)
			Pow => match (
				Interp.number_argument(arguments, 0),
				Interp.number_argument(arguments, 1),
			) {
				(Ok(x), Ok(y)) => { machine: machine, value: Number(Interp.power(x, y)) }
				_ => Interp.fault_got(
					machine,
					"unsupported: Math.pow of anything but two numbers${Interp.line_note(site)}",
				)
			}
			Min => Interp.min_max(machine, arguments, Min, site)
			Max => Interp.min_max(machine, arguments, Max, site)
			Keys => Interp.object_listing(machine, arguments, Keys, site)
			Values => Interp.object_listing(machine, arguments, Values, site)
			Entries => Interp.object_listing(machine, arguments, Entries, site)
			StringOf => match arguments.first() {
				Ok(subject) => match Interp.text_of(machine.cells, subject) {
					Ok(phrase) => { machine: machine, value: Text(phrase) }
					Err(Unsupported(why)) => Interp.fault_got(
						machine,
						"${why}${Interp.line_note(site)}",
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
						value: Text(Str.from_utf8($bytes) ?? crash "Interp.call_native: ASCII bytes"),
					}
				} else {
					Interp.fault_got(
						machine,
						"unsupported: String.fromCharCode of anything but ASCII codes${Interp.line_note(site)}",
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
			Interp.fault_got(
				machine,
				"unsupported: Math.min or Math.max of anything but numbers${Interp.line_note(site)}",
			)
		}
	}

	# Object.keys, Object.values or Object.entries, of an object or an array.
	Listing : [Keys, Values, Entries]

	object_listing : Interp.Machine, List(Heap.Value), Interp.Listing, Ast.Where -> Interp.Got
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
							{ machine: made, value: pair } = Interp.alloc(
								$s,
								Array([Text(parent.key), parent.value]),
							)
							$s = made
							pair
						}
					}
					$values = $values.append(subject)
				}
				Interp.alloc($s, Array($values))
			}
			Err(NotListed) => Interp.fault_got(
				machine,
				"unsupported: Object.keys, values or entries of anything but an object or an array${Interp.line_note(site)}",
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
	item_at = |machine, id, position|
		match Heap.cell_at(machine.cells, id) {
			Array(items) => items.get(position) ?? Undefined
			_ => crash "Interp.item_at: the interpreter asks only an array for an item"
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

	array_method : Interp.Machine, U64, Str, List(Heap.Value), Ast.Where -> Interp.Got
	array_method = |machine, id, name, arguments, site|
		match name {
			"push" => {
				pushed = { ..machine, cells: Heap.with_items_pushed(machine.cells, id, arguments) }
				{ machine: pushed, value: Number(Interp.item_count(pushed, id).to_f64()) }
			}
			"pop" => {
				count = Interp.item_count(machine, id)
				if count == 0 {
					{ machine: machine, value: Undefined }
				} else {
					last = Interp.item_at(machine, id, count - 1)
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
						for item in Interp.items_of(machine, id) {
							part = match item {
								Null => Ok("")
								Undefined => Ok("")
								_ => Interp.text_of(machine.cells, item)
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
							Interp.fault_got(machine, "${$why}${Interp.line_note(site)}")
						}
					}
					Err(NotText) => Interp.fault_got(
						machine,
						"unsupported: `join` with a separator that is not a string${Interp.line_note(site)}",
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
				found = Interp.items_of(machine, id).any(
					|item| Interp.is_same_value_zero(item, target),
				)
				{ machine: machine, value: Boolean(found) }
			}
			"slice" => {
				items = Interp.items_of(machine, id)
				count = items.len()
				from = Interp.relative_index(arguments.get(0) ?? Undefined, count, 0)
				to = Interp.relative_index(arguments.get(1) ?? Undefined, count, count)
				cut = if to > from {
					items.sublist({ start: from, len: to - from })
				} else {
					[]
				}
				Interp.alloc(machine, Array(cut))
			}
			"concat" => {
				var $out = Interp.items_of(machine, id)
				for argument in arguments {
					$out = match argument {
						Reference(other) => match Heap.cell_at(machine.cells, other) {
							Array(more) => List.concat($out, more)
							_ => $out.append(argument)
						}
						_ => $out.append(argument)
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
				{
					machine: { ..machine, cells: Heap.with_items(machine.cells, id, reversed) },
					value: Reference(id),
				}
			}
			"forEach" => Interp.array_walk(machine, id, arguments, ForEach, site)
			"map" => Interp.array_walk(machine, id, arguments, Map, site)
			"filter" => Interp.array_walk(machine, id, arguments, Filter, site)
			"some" => Interp.array_walk(machine, id, arguments, Some, site)
			"every" => Interp.array_walk(machine, id, arguments, Every, site)
			"find" => Interp.array_walk(machine, id, arguments, Find, site)
			"findIndex" => Interp.array_walk(machine, id, arguments, FindIndex, site)
			"reduce" => Interp.array_reduce(machine, id, arguments, site)
			"sort" => Interp.array_sort(machine, id, arguments, site)
			_ => Interp.fault_got(
				machine,
				"unsupported: the array method `${name}`${Interp.line_note(site)}",
			)
		}

	Walk : [ForEach, Map, Filter, Some, Every, Find, FindIndex]

	# An array method that calls a function on each item in turn, the items
	# read from the heap as it goes, since the function may change the array.
	array_walk : Interp.Machine, U64, List(Heap.Value), Interp.Walk, Ast.Where -> Interp.Got
	array_walk = |machine, id, arguments, walk, site| {
		callback = arguments.first() ?? Undefined
		count = Interp.item_count(machine, id)
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
		while $going and $i < count and $i < Interp.item_count($s, id) {
			item = Interp.item_at($s, id, $i)
			{ machine: after, value } = Interp.call(
				$s,
				callback,
				[item, Number($i.to_f64()), Reference(id)],
				site,
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
	array_reduce = |machine, id, arguments, site| {
		callback = arguments.first() ?? Undefined
		count = Interp.item_count(machine, id)
		start = match arguments.get(1) {
			Ok(subject) => Ok({ accumulated: subject, from: 0 })
			Err(OutOfBounds) => {
				if count == 0 {
					Err(Empty)
				} else {
					Ok({ accumulated: Interp.item_at(machine, id, 0), from: 1 })
				}
			}
		}
		match start {
			Err(Empty) => Interp.fault_got(
				machine,
				"TypeError: Reduce of empty array with no initial value${Interp.line_note(site)}",
			)
			Ok({ accumulated, from }) => {
				var $s = machine
				var $accumulated = accumulated
				var $i = from
				while $i < count and $i < Interp.item_count($s, id) and Interp.is_running($s) {
					item = Interp.item_at($s, id, $i)
					{ machine: after, value } = Interp.call(
						$s,
						callback,
						[
							$accumulated,
							item,
							Number($i.to_f64()),
							Reference(id),
						],
						site,
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
	array_sort = |machine, id, arguments, site| {
		items = Interp.items_of(machine, id)
		compare = arguments.first() ?? Undefined
		{ machine: after, values } = Interp.merge_sorted(machine, items, compare, site)
		if Interp.is_running(after) {
			{
				machine: { ..after, cells: Heap.with_items(after.cells, id, values) },
				value: Reference(id),
			}
		} else {
			{ machine: after, value: Reference(id) }
		}
	}

	merge_sorted : Interp.Machine, List(Heap.Value), Heap.Value, Ast.Where -> Interp.Evaluations
	merge_sorted = |machine, items, compare, site| {
		count = items.len()
		if count <= 1 {
			{ machine: machine, values: items }
		} else {
			half = count // 2
			{ machine: first, values: lower } = Interp.merge_sorted(
				machine,
				items.sublist({ start: 0, len: half }),
				compare,
				site,
			)
			{ machine: second, values: upper } = Interp.merge_sorted(
				first,
				items.drop_first(half),
				compare,
				site,
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
					left = lower.get($i) ?? crash "Interp.merge_sorted: inside the lower half"
					right = upper.get($j) ?? crash "Interp.merge_sorted: inside the upper half"
					{ machine: after, order } = Interp.ordering_of(
						$s,
						{
							compare: compare,
							left: left,
							right: right,
							at: site,
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

	ordering_of : Interp.Machine, Interp.Comparison -> Interp.Ordered
	ordering_of = |machine, comparison| {
		{
			compare,
			left: left,
			right: right,
			at: site,
		} = comparison
		match compare {
			Undefined => {
				order = match (left, right) {
					(Undefined, Undefined) => Same
					(Undefined, _) => After
					(_, Undefined) => Before
					_ => match (
						Interp.text_of(machine.cells, left),
						Interp.text_of(machine.cells, right),
					) {
						(Ok(x), Ok(y)) => Interp.ordering_of_text(x, y)
						_ => Same
					}
				}
				{ machine: machine, order: order }
			}
			_ => {
				{ machine: after, value } = Interp.call(machine, compare, [left, right], site)
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
	text_method = |machine, text, name, arguments, site|
		if Interp.positional_methods.contains(name) and !Interp.is_ascii(text) {
			Interp.fault_got(
				machine,
				"unsupported: `${name}` on a string with non-ASCII text${Interp.line_note(site)}",
			)
		} else if name == "split" and arguments.first() == Ok(Text("")) and !Interp.is_ascii(text) {
			Interp.fault_got(
				machine,
				"unsupported: `split` into characters of a string with non-ASCII text${Interp.line_note(site)}",
			)
		} else {
			Interp.text_method_of(machine, text, name, arguments, site)
		}

	text_method_of : Interp.Machine, Str, Str, List(Heap.Value), Ast.Where -> Interp.Got
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
					) ?? crash "Interp.text_method: an ASCII cut",
				)
			} else {
				Text("")
			}
		match name {
			"charAt" => match Interp.index_of(arguments.first() ?? Number(0.0)) {
				Ok(position) => {
					got = Interp.char_at(machine, text, position, site)
					match got.value {
						Undefined => { machine: machine, value: Text("") }
						_ => got
					}
				}
				Err(NotIndex) => { machine: machine, value: Text("") }
			}
			"charCodeAt" => match Interp.index_of(arguments.first() ?? Number(0.0)) {
				Ok(position) => match bytes.get(position) {
					Ok(byte) => { machine: machine, value: Number(byte.to_f64()) }
					Err(OutOfBounds) => { machine: machine, value: Number(0.0 / 0.0) }
				}
				Err(NotIndex) => { machine: machine, value: Number(0.0 / 0.0) }
			}
			"slice" => {
				from = Interp.relative_index(arguments.get(0) ?? Undefined, count, 0)
				to = Interp.relative_index(arguments.get(1) ?? Undefined, count, count)
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
				Ok(phrase) => { machine: machine, value: Number(Interp.text_index(text, phrase)) }
				Err(NotText) => Interp.fault_got(
					machine,
					"unsupported: `indexOf` of anything but a string${Interp.line_note(site)}",
				)
			}
			"includes" => match text_argument(0) {
				Ok(phrase) => { machine: machine, value: Boolean(text.contains(phrase)) }
				Err(NotText) => Interp.fault_got(
					machine,
					"unsupported: `includes` of anything but a string${Interp.line_note(site)}",
				)
			}
			"startsWith" => match text_argument(0) {
				Ok(phrase) => { machine: machine, value: Boolean(text.starts_with(phrase)) }
				Err(NotText) => Interp.fault_got(
					machine,
					"unsupported: `startsWith` of anything but a string${Interp.line_note(site)}",
				)
			}
			"endsWith" => match text_argument(0) {
				Ok(phrase) => { machine: machine, value: Boolean(text.ends_with(phrase)) }
				Err(NotText) => Interp.fault_got(
					machine,
					"unsupported: `endsWith` of anything but a string${Interp.line_note(site)}",
				)
			}
			"toUpperCase" => { machine: machine, value: Text(text.with_ascii_uppercased()) }
			"toLowerCase" => { machine: machine, value: Text(text.with_ascii_lowercased()) }
			"trim" => { machine: machine, value: Text(Interp.ascii_trimmed(text)) }
			"repeat" => match arguments.first() {
				Ok(Number(times)) if times >= 0.0 and times.div_trunc_by(1.0) == times and times < 100000000.0 => {
					{ machine: machine, value: Text(text.repeat(times.to_u64_try() ?? 0)) }
				}
				_ => Interp.fault_got(
					machine,
					"unsupported: `repeat` of anything but a whole number of times${Interp.line_note(site)}",
				)
			}
			"split" => match text_argument(0) {
				Ok("") => Interp.alloc(
					machine,
					Array(Interp.characters(text).map(|character| Text(character))),
				)
				Ok(phrase) => Interp.alloc(
					machine,
					Array(text.split_on(phrase).map(|piece| Text(piece))),
				)
				Err(NotText) => Interp.fault_got(
					machine,
					"unsupported: `split` by anything but a string${Interp.line_note(site)}",
				)
			}
			"padStart" => Interp.text_padded(machine, text, arguments, PadStart, site)
			"padEnd" => Interp.text_padded(machine, text, arguments, PadEnd, site)
			"concat" => {
				var $out = text
				var $why = ""
				for argument in arguments {
					match Interp.text_of(machine.cells, argument) {
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
					Interp.fault_got(machine, "${$why}${Interp.line_note(site)}")
				}
			}
			_ => Interp.fault_got(
				machine,
				"unsupported: the string method `${name}`${Interp.line_note(site)}",
			)
		}
	}

	# Where `t` first starts in `s`, in bytes, or -1.
	text_index : Str, Str -> F64
	text_index = |text, phrase| {
		text_bytes = text.to_utf8()
		phrase_bytes = phrase.to_utf8()
		if phrase_bytes.len() > text_bytes.len() {
			-1.0
		} else {
			var $i = 0
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

	ascii_trimmed : Str -> Str
	ascii_trimmed = |text| {
		bytes = text.to_utf8()
		is_space = |byte| byte == ' ' or byte == '\t' or byte == '\n' or byte == '\r' or byte == 11 or byte == 12
		var $from = 0
		while $from < bytes.len() and is_space(bytes.get($from) ?? crash "Interp.ascii_trimmed: inside the text") {
			$from = $from + 1
		}
		var $to = bytes.len()
		while $to > $from and is_space(bytes.get($to - 1) ?? crash "Interp.ascii_trimmed: inside the text") {
			$to = $to - 1
		}
		Str.from_utf8(
			bytes.sublist({ start: $from, len: $to - $from }),
		) ?? crash "Interp.ascii_trimmed: an ASCII cut"
	}

	Side : [PadStart, PadEnd]

	text_padded : Interp.Machine, Str, List(Heap.Value), Interp.Side, Ast.Where -> Interp.Got
	text_padded = |machine, text, arguments, side, site| {
		fill_given = match arguments.get(1) {
			Ok(Text(given)) => Ok(given)
			Err(OutOfBounds) => Ok(" ")
			_ => Err(NotText)
		}
		match (arguments.first(), fill_given) {
			(Ok(Number(wanted)), Ok(pad_text)) if Interp.is_ascii(text) and Interp.is_ascii(pad_text) and wanted.div_trunc_by(1.0) == wanted and wanted < 100000000.0 => {
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
					) ?? crash "Interp.text_padded: an ASCII cut"
					match side {
						PadStart => { machine: machine, value: Text(Str.concat(pad, text)) }
						PadEnd => { machine: machine, value: Text(Str.concat(text, pad)) }
					}
				}
			}
			_ => Interp.fault_got(
				machine,
				"unsupported: `padStart` or `padEnd` other than to a whole length with ASCII text${Interp.line_note(site)}",
			)
		}
	}
}
