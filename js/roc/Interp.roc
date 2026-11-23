# This module runs a parsed JavaScript program by walking its tree.
#
# **THE WHOLE MACHINE IS ONE VALUE, `St`, THREADED THROUGH THE WALK.** Every
# evaluation takes the machine and answers it back beside its value (`Got`),
# and every statement answers it back beside how control leaves the
# statement (`Done`). JavaScript shares arrays, objects and closures by
# reference, so they live in the heap (`Heap`), a list of cells named by
# index; scopes live in a second list, because a closure holds on to the
# scope it was made in and sees later writes to it.
#
# **NOTHING HOLDS THE MACHINE BUT THE WALK.** Roc writes a list in place only
# while nothing else refers to it, so a single stray reference to the heap
# makes every property write copy the whole heap. The rules that keep it
# unique:
# - No closure in this module captures the machine or a part of it; loops
#   over the machine are `var $st` loops, never a `walk` with a lambda.
# - A write passes the list straight from the record it updates,
#   `{ ..st, cells: Heap.with_prop(st.cells, ...) }`, so the old machine is
#   never read after the write that consumes it.
# - Every `Got` and `Done` is taken apart where it is answered,
#   `{ st: after, val } = Interp.eval(st, e)`, never kept whole while its
#   machine goes on to be written: a record kept for its `val` keeps its
#   `st` too, a second reference to the heap and the scopes, and each
#   write made while it lives copies them. Kept whole, a store into an
#   array copied the array and a closure's `++c` copied every scope.
# - A writer asks `Interp.kind_of` what a cell is, never matches the cell
#   out of the heap: the matched cell refers to its props or items for as
#   long as the arm runs.
#
# **A SCOPE THAT NOTHING CAN CAPTURE IS DROPPED WHEN ITS BLOCK ENDS.** The
# parser marks each block and function whose text holds no function literal
# (`CapturesNothing`), and such a scope, the last in the list when its block
# ends, is dropped, so a loop or a recursion without closures leaves the
# scope list as it found it. Scopes that may be captured, and every cell,
# live until the run ends.
#
# A fault (a TypeError, a feature outside the subset, the step budget) stops
# the run: `fault` is set, every statement after it is skipped, and the
# message is the run's last line.
import Ast
import Heap
import Inspect
import NumberText

Interp :: [].{
	VarState : [Mutable, Fixed, Unready]

	Var : { name : Str, val : Heap.Val, state : Interp.VarState }

	Parent : [Outermost, Within(U64)]

	Scope : { vars : List(Interp.Var), parent : Interp.Parent }

	Status : [Running, Faulted(Str)]

	St : {
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

	Got : { st : Interp.St, val : Heap.Val }

	Flow : [Normal, Broke, Continued, Returned(Heap.Val)]

	Done : { st : Interp.St, flow : Interp.Flow }

	# The deepest JavaScript call the interpreter makes before it reports a
	# stack overflow, as node does, rather than overflow Roc's own stack.
	max_depth : U64
	max_depth = 400

	# ---- the run ---------------------------------------------------------------

	Outcome : { out : Str, steps : U64, cells : U64, scopes : U64, status : Interp.Status }

	run : Ast.Program, U64 -> Interp.Outcome
	run = |program, step_limit| {
		st0 = Interp.with_globals({
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
		done = Interp.exec_block(st0, program)
		st = done.st
		{
			out: st.out,
			steps: st.steps,
			cells: st.cells.len(),
			scopes: st.live_scopes,
			status: st.status,
		}
	}

	# The machine with the outermost scope holding the builtins.
	with_globals : Interp.St -> Interp.St
	with_globals = |st| {
		var $s = { ..st, scopes: st.scopes.append({ vars: [], parent: Outermost }), live_scopes: 1, scope: 0 }
		log = Interp.alloc($s, Builtin(Log, []))
		$s = log.st
		console = Interp.alloc($s, Namespace("console", [{ key: "log", val: log.val }]))
		$s = console.st
		var $math_props = [
			{ key: "PI", val: Number(3.141592653589793) },
			{ key: "E", val: Number(2.718281828459045) },
		]
		for n in [Floor, Ceil, Round, Trunc, Abs, Sign, Sqrt, Pow, Min, Max, Sin, Cos, Tan, Atan] {
			f = Interp.alloc($s, Builtin(n, []))
			$s = f.st
			$math_props = $math_props.append({ key: Heap.native_name(n), val: f.val })
		}
		math_object = Interp.alloc($s, Namespace("Math", $math_props))
		$s = math_object.st
		var $object_props = []
		for n in [Keys, Values, Entries] {
			f = Interp.alloc($s, Builtin(n, []))
			$s = f.st
			$object_props = $object_props.append({ key: Heap.native_name(n), val: f.val })
		}
		object = Interp.alloc($s, Namespace("Object", $object_props))
		$s = object.st
		from_char_code = Interp.alloc($s, Builtin(FromCharCode, []))
		$s = from_char_code.st
		string = Interp.alloc($s, Builtin(StringOf, [{ key: "fromCharCode", val: from_char_code.val }]))
		$s = string.st
		is_array = Interp.alloc($s, Builtin(IsArray, []))
		$s = is_array.st
		array = Interp.alloc($s, Namespace("Array", [{ key: "isArray", val: is_array.val }]))
		$s = array.st
		is_integer = Interp.alloc($s, Builtin(IsInteger, []))
		$s = is_integer.st
		number = Interp.alloc(
			$s,
			Namespace(
				"Number",
				[
					{ key: "isInteger", val: is_integer.val },
					{ key: "MAX_SAFE_INTEGER", val: Number(9007199254740991.0) },
				],
			),
		)
		$s = number.st
		globals = [
			{ name: "console", val: console.val, state: Fixed },
			{ name: "Math", val: math_object.val, state: Fixed },
			{ name: "Object", val: object.val, state: Fixed },
			{ name: "String", val: string.val, state: Fixed },
			{ name: "Array", val: array.val, state: Fixed },
			{ name: "Number", val: number.val, state: Fixed },
			{ name: "NaN", val: Number(0.0 / 0.0), state: Fixed },
			{ name: "Infinity", val: Number(1.0 / 0.0), state: Fixed },
		]
		{ ..$s, scopes: [{ vars: globals, parent: Outermost }] }
	}

	alloc : Interp.St, Heap.Cell -> Interp.Got
	alloc = |st, cell| {
		id = st.cells.len()
		{ st: { ..st, cells: st.cells.append(cell) }, val: Ref(id) }
	}

	is_running : Interp.St -> Bool
	is_running = |st| st.status == Running

	# The machine stopped with `why`, unless it had already stopped.
	faulted : Interp.St, Str -> Interp.St
	faulted = |st, why|
		match st.status {
			Running => { ..st, status: Faulted(why) }
			Faulted(_) => st
		}

	fault_got : Interp.St, Str -> Interp.Got
	fault_got = |st, why| { st: Interp.faulted(st, why), val: Undefined }

	at_line : Ast.Where -> Str
	at_line = |w| " (line ${w.line.to_str()})"

	# ---- scopes ----------------------------------------------------------------

	Found : [Found({ scope : U64, index : U64, binding : Interp.Var }), Missing]

	lookup : List(Interp.Scope), U64, Str -> Interp.Found
	lookup = |scopes, start, name| {
		var $sid = start
		var $searching = True
		var $found = Missing
		while $searching {
			scope = scopes.get($sid) ?? crash "Interp.lookup: a scope's parent is a scope"
			var $i = 0
			for v in scope.vars {
				if $searching and v.name == name {
					$found = Found({ scope: $sid, index: $i, binding: v })
					$searching = False
				}
				$i = $i + 1
			}
			if $searching {
				match scope.parent {
					Within(p) => {
						$sid = p
					}
					Outermost => {
						$searching = False
					}
				}
			}
		}
		$found
	}

	# The scopes with one variable written in place: the scope is taken out,
	# written while nothing else refers to its vars, and put back.
	with_var : List(Interp.Scope), U64, U64, Interp.Var -> List(Interp.Scope)
	with_var = |scopes, sid, index, binding| {
		taken = scopes.replace(sid, { vars: [], parent: Outermost }) ?? crash "Interp.with_var: a scope the machine has"
		taken.list.set(sid, Interp.scope_with_var(taken.prev, index, binding)) ?? crash "Interp.with_var: the scope was just taken"
	}

	# **THE WRITE IS A FUNCTION OF ITS OWN**, handed the scope taken out. Made
	# inline, beside the scope's other uses, the write copied the scope list:
	# a closure's `++c`, with N closures alive, cost N.
	scope_with_var : Interp.Scope, U64, Interp.Var -> Interp.Scope
	scope_with_var = |scope, index, binding| {
		{ vars, parent } = scope
		{ vars: vars.set(index, binding) ?? crash "Interp.scope_with_var: a variable the scope has", parent: parent }
	}

	# The scopes with a variable declared in scope `sid`: set where the name
	# is already there (a hoisted declaration), else added.
	with_declared : List(Interp.Scope), U64, Interp.Var -> List(Interp.Scope)
	with_declared = |scopes, sid, binding| {
		taken = scopes.replace(sid, { vars: [], parent: Outermost }) ?? crash "Interp.with_declared: a scope the machine has"
		taken.list.set(sid, Interp.scope_with_declared(taken.prev, binding)) ?? crash "Interp.with_declared: the scope was just taken"
	}

	scope_with_declared : Interp.Scope, Interp.Var -> Interp.Scope
	scope_with_declared = |scope, binding| {
		{ vars, parent } = scope
		index = Interp.index_of_name(vars, binding.name)
		written = if index == vars.len() {
			vars.append(binding)
		} else {
			vars.set(index, binding) ?? crash "Interp.scope_with_declared: the index was just found"
		}
		{ vars: written, parent: parent }
	}

	# Where `name` is among `vars`, or their count when it is not.
	index_of_name : List(Interp.Var), Str -> U64
	index_of_name = |vars, name| {
		var $index = vars.len()
		var $i = 0
		for v in vars {
			if v.name == name and $index == vars.len() {
				$index = $i
			}
			$i = $i + 1
		}
		$index
	}

	declare : Interp.St, Str, Heap.Val, Interp.VarState -> Interp.St
	declare = |st, name, val, state| { ..st, scopes: Interp.with_declared(st.scopes, st.scope, { name: name, val: val, state: state }) }

	# The machine inside a new scope whose parent is `parent`.
	entered : Interp.St, Interp.Parent -> Interp.St
	entered = |st, parent| Interp.with_scope_added(st, { vars: [], parent: parent })

	# The machine inside `scope`, a new one, in the first dead slot or past the
	# end.
	#
	# **A DROPPED SCOPE'S SLOT IS REUSED, AND THE LIST NEVER SHRINKS.**
	# `List.drop_last` is a `sublist`, and the list it answers refers to the
	# old one's memory: the next append copied the whole scope list, so each
	# call of a closure, beside N scopes kept alive by other closures, cost N.
	with_scope_added : Interp.St, Interp.Scope -> Interp.St
	with_scope_added = |st, scope| {
		id = st.live_scopes
		{ ..st, scopes: Interp.scopes_with(st.scopes, id, scope), live_scopes: id + 1, scope: id }
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
	left : Interp.St, U64, U64, Ast.Capture -> Interp.St
	left = |st, inner, outer, capture| {
		drops = capture == CapturesNothing and inner + 1 == st.live_scopes
		if drops {
			{ ..st, live_scopes: inner, scope: outer }
		} else {
			{ ..st, scope: outer }
		}
	}

	# The functions a block declares, made before its first statement, and its
	# `let` and `const` names, which can't be read until their statement runs.
	hoisted : Interp.St, List(Ast.Stmt) -> Interp.St
	hoisted = |st, stmts| {
		var $s = st
		for stmt in stmts {
			match stmt {
				FunctionDecl(def) => {
					{ st: made, val: f } = Interp.alloc($s, Fun({ fun: def, scope: $s.scope }))
					$s = Interp.declare(made, def.name, f, Mutable)
				}
				Declare(_, decls) => {
					for d in decls {
						$s = Interp.declare($s, d.name, Undefined, Unready)
					}
				}
				_ => {}
			}
		}
		$s
	}

	# ---- statements ------------------------------------------------------------

	normal : Interp.St -> Interp.Done
	normal = |st| { st: st, flow: Normal }

	exec_block : Interp.St, Ast.Block -> Interp.Done
	exec_block = |st, block|
		match block.scoping {
			Unscoped => Interp.exec_list(st, block.stmts)
			Scoped => {
				outer = st.scope
				inner = Interp.hoisted(Interp.entered(st, Within(outer)), block.stmts)
				id = inner.scope
				{ st: after, flow } = Interp.exec_list(inner, block.stmts)
				{ st: Interp.left(after, id, outer, block.capture), flow: flow }
			}
		}

	exec_list : Interp.St, List(Ast.Stmt) -> Interp.Done
	exec_list = |st, stmts| {
		var $s = st
		var $flow = Normal
		for stmt in stmts {
			if $flow == Normal and Interp.is_running($s) {
				{ st: after, flow } = Interp.exec(Interp.ticked($s), stmt)
				$s = after
				$flow = flow
			}
		}
		{ st: $s, flow: $flow }
	}

	# The machine one step on, stopped when it passes its step budget.
	ticked : Interp.St -> Interp.St
	ticked = |st|
		if st.steps >= st.step_limit {
			Interp.faulted(st, "the program ran past its budget of ${st.step_limit.to_str()} steps")
		} else {
			{ ..st, steps: st.steps + 1 }
		}

	exec : Interp.St, Ast.Stmt -> Interp.Done
	exec = |st, stmt|
		match stmt {
			Expression(e) => {
				{ st: after, val: _ } = Interp.eval(st, e)
				Interp.normal(after)
			}
			Declare(binding, decls) => {
				var $s = st
				for d in decls {
					if Interp.is_running($s) {
						{ st: made, val } = match d.init {
							Initialized(e) => Interp.eval($s, e)
							Uninitialized => { st: $s, val: Undefined }
						}
						state = match binding {
							Let => Mutable
							Const => Fixed
						}
						$s = Interp.declare(made, d.name, val, state)
					}
				}
				Interp.normal($s)
			}
			FunctionDecl(_) => Interp.normal(st)
			If(test, yes, no) => {
				{ st: tested, val } = Interp.eval(st, test)
				if !Interp.is_running(tested) {
					Interp.normal(tested)
				} else if Interp.is_truthy(val) {
					Interp.exec(tested, yes)
				} else {
					Interp.exec(tested, no)
				}
			}
			While(test, body) => Interp.exec_while(st, test, body)
			For(loop) => Interp.exec_for(st, loop)
			ForOf(loop) => Interp.exec_for_of(st, loop)
			BlockStmt(block) => Interp.exec_block(st, block)
			Return(e) => {
				{ st: after, val } = Interp.eval(st, e)
				{ st: after, flow: Returned(val) }
			}
			Break => { st: st, flow: Broke }
			Continue => { st: st, flow: Continued }
			Empty => Interp.normal(st)
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

	exec_while : Interp.St, Ast.Expr, Ast.Stmt -> Interp.Done
	exec_while = |st, test, body| {
		var $s = st
		var $flow = Normal
		var $going = True
		while $going {
			{ st: tested, val } = Interp.eval(Interp.ticked($s), test)
			if !Interp.is_running(tested) or !Interp.is_truthy(val) {
				$s = tested
				$going = False
			} else {
				{ st: after, flow } = Interp.exec(tested, body)
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
		{ st: $s, flow: $flow }
	}

	exec_for : Interp.St, Ast.ForLoop -> Interp.Done
	exec_for = |st, loop| {
		outer = st.scope
		start = Interp.entered(st, Within(outer))
		{ st: begun, flow: _ } = Interp.exec(start, loop.init)
		var $s = begun
		var $flow = Normal
		var $going = Interp.is_running($s)
		while $going {
			{ st: tested, val } = match loop.test {
				Tested(e) => Interp.eval(Interp.ticked($s), e)
				Always => { st: Interp.ticked($s), val: Boolean(True) }
			}
			if !Interp.is_running(tested) or !Interp.is_truthy(val) {
				$s = tested
				$going = False
			} else {
				{ st: after, flow } = Interp.exec(tested, loop.body)
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
		{ st: Interp.left($s, $s.scope, outer, loop.capture), flow: $flow }
	}

	# The machine in a copy of its current scope, beside the old one.
	copied_scope : Interp.St -> Interp.St
	copied_scope = |st| {
		scope = st.scopes.get(st.scope) ?? crash "Interp.copied_scope: the current scope is one the machine has"
		Interp.with_scope_added(st, scope)
	}

	exec_for_of : Interp.St, Ast.ForOfLoop -> Interp.Done
	exec_for_of = |st, loop| {
		{ st: got, val: iterable } = Interp.eval(st, loop.iterable)
		state = match loop.binding {
			Let => Mutable
			Const => Fixed
		}
		match iterable {
			Ref(id) => match Interp.kind_of(got.cells, id) {
				ArrayKind(_) => Interp.exec_for_of_array(got, loop, id, state)
				_ => Interp.normal(Interp.faulted(got, "unsupported: `for ... of` over anything but an array or a string${Interp.at_line(loop.at)}"))
			}
			Text(s) => Interp.exec_for_of_text(got, loop, s, state)
			_ => Interp.normal(Interp.faulted(got, "TypeError: the value is not iterable${Interp.at_line(loop.at)}"))
		}
	}

	exec_for_of_array : Interp.St, Ast.ForOfLoop, U64, Interp.VarState -> Interp.Done
	exec_for_of_array = |st, loop, id, state| {
		var $s = st
		var $flow = Normal
		var $i = 0
		var $going = Interp.is_running(st)
		while $going {
			if $i >= Interp.item_count($s, id) {
				$going = False
			} else {
				v = Interp.item_at($s, id, $i)
				{ st: after, flow } = Interp.exec_for_of_pass(Interp.ticked($s), loop, v, state)
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
		{ st: $s, flow: $flow }
	}

	exec_for_of_text : Interp.St, Ast.ForOfLoop, Str, Interp.VarState -> Interp.Done
	exec_for_of_text = |st, loop, text, state| {
		var $s = st
		var $flow = Normal
		var $going = Interp.is_running(st)
		for c in Interp.characters(text) {
			if $going {
				{ st: after, flow } = Interp.exec_for_of_pass(Interp.ticked($s), loop, Text(c), state)
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
		{ st: $s, flow: $flow }
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
			$out = $out.append(Str.from_utf8(b.sublist({ start: $i, len: n })) ?? crash "Interp.characters: a whole character")
			$i = $i + n
		}
		$out
	}

	exec_for_of_pass : Interp.St, Ast.ForOfLoop, Heap.Val, Interp.VarState -> Interp.Done
	exec_for_of_pass = |st, loop, v, state| {
		outer = st.scope
		inner = Interp.declare(Interp.entered(st, Within(outer)), loop.name, v, state)
		id = inner.scope
		{ st: after, flow } = Interp.exec(inner, loop.body)
		{ st: Interp.left(after, id, outer, loop.capture), flow: flow }
	}

	# ---- values ----------------------------------------------------------------

	is_truthy : Heap.Val -> Bool
	is_truthy = |v| match v {
		Number(n) => !(n == 0.0 or n.is_nan())
		Text(s) => !s.is_empty()
		Boolean(b) => b
		Null => False
		Undefined => False
		Ref(_) => True
	}

	type_of : List(Heap.Cell), Heap.Val -> Str
	type_of = |cells, v| match v {
		Number(_) => "number"
		Text(_) => "string"
		Boolean(_) => "boolean"
		Null => "object"
		Undefined => "undefined"
		Ref(id) => match Heap.cell_at(cells, id) {
			Fun(_) => "function"
			Builtin(_, _) => "function"
			_ => "object"
		}
	}

	is_strictly_equal : Heap.Val, Heap.Val -> Bool
	is_strictly_equal = |a, b| match (a, b) {
		(Number(x), Number(y)) => x == y
		(Text(x), Text(y)) => x == y
		(Boolean(x), Boolean(y)) => x == y
		(Null, Null) => True
		(Undefined, Undefined) => True
		(Ref(x), Ref(y)) => x == y
		_ => False
	}

	# SameValueZero, as `includes` compares: NaN finds NaN.
	is_same_value_zero : Heap.Val, Heap.Val -> Bool
	is_same_value_zero = |a, b| match (a, b) {
		(Number(x), Number(y)) => x == y or (x.is_nan() and y.is_nan())
		_ => Interp.is_strictly_equal(a, b)
	}

	# What `String(v)` gives, for the values whose text the subset has.
	text_of : List(Heap.Cell), Heap.Val -> Try(Str, [Unsupported(Str)])
	text_of = |cells, v| Interp.text_of_seen(cells, v, [])

	text_of_seen : List(Heap.Cell), Heap.Val, List(U64) -> Try(Str, [Unsupported(Str)])
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
		Ref(id) => match Heap.cell_at(cells, id) {
			Arr(items) => {
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
			Obj(_) => Ok("[object Object]")
			_ => Err(Unsupported("unsupported: turning a function or a builtin object into text"))
		}
	}

	# The property key a value names, as `o[k]` reads it.
	key_of : Heap.Val -> Try(Str, [Unsupported(Str)])
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
		Ref(_) => Err(Unsupported("unsupported: an object or array as a property key"))
	}

	# The array index a value names, if it names one.
	index_of : Heap.Val -> Try(U64, [NotIndex])
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

	shown_value : List(Heap.Cell), Heap.Val -> Str
	shown_value = |cells, v| match v {
		Text(s) => Inspect.escaped(s)
		_ => Inspect.inspect(cells, v) ?? Interp.type_of(cells, v)
	}

	# ---- expressions -----------------------------------------------------------

	eval : Interp.St, Ast.Expr -> Interp.Got
	eval = |st, expr|
		match expr {
			Number(n) => { st: st, val: Number(n) }
			Text(s) => { st: st, val: Text(s) }
			Boolean(b) => { st: st, val: Boolean(b) }
			Null => { st: st, val: Null }
			Undefined => { st: st, val: Undefined }
			Template(texts, parts) => Interp.eval_template(st, texts, parts)
			Name(name, w) => Interp.eval_name(st, name, w)
			ArrayLit(items) => {
				{ st: after, vals } = Interp.eval_all(st, items)
				Interp.alloc(after, Arr(vals))
			}
			ObjectLit(props) => {
				var $s = st
				var $made = []
				for p in props {
					{ st: after, val } = Interp.eval($s, p.value)
					$s = after
					$made = Heap.props_with($made, p.key, val)
				}
				Interp.alloc($s, Obj($made))
			}
			Unary(op, e, w) => {
				{ st: after, val } = Interp.eval(st, e)
				Interp.unary(after, op, val, w)
			}
			Binary(op, a, b, w) => {
				{ st: first, val: left_val } = Interp.eval(st, a)
				{ st: second, val: right_val } = Interp.eval(first, b)
				Interp.binary(second, op, left_val, right_val, w)
			}
			Logical(op, a, b) => {
				{ st: first, val: left_val } = Interp.eval(st, a)
				decided = match op {
					And => !Interp.is_truthy(left_val)
					Or => Interp.is_truthy(left_val)
					Nullish => left_val != Null and left_val != Undefined
				}
				if decided {
					{ st: first, val: left_val }
				} else {
					Interp.eval(first, b)
				}
			}
			Conditional(test, yes, no) => {
				{ st: tested, val } = Interp.eval(st, test)
				if Interp.is_truthy(val) {
					Interp.eval(tested, yes)
				} else {
					Interp.eval(tested, no)
				}
			}
			Assign(target, op, e, w) => Interp.eval_assign(st, target, op, e, w)
			Update(target, step, fixity, w) => Interp.eval_update(st, target, step, fixity, w)
			Member(obj, key, w) => {
				{ st: after, val: o } = Interp.eval(st, obj)
				Interp.property(after, o, key, w)
			}
			Index(obj, key, w) => {
				{ st: first, val: o } = Interp.eval(st, obj)
				{ st: second, val: k } = Interp.eval(first, key)
				Interp.indexed(second, o, k, w)
			}
			Call(callee, args, w) => Interp.eval_call(st, callee, args, w)
			Function(def) => Interp.alloc(st, Fun({ fun: def, scope: st.scope }))
		}

	# The machine after an expression whose value is not wanted.
	machine_after : Interp.St, Ast.Expr -> Interp.St
	machine_after = |st, e| {
		{ st: after, val: _ } = Interp.eval(st, e)
		after
	}

	Vals : { st : Interp.St, vals : List(Heap.Val) }

	eval_all : Interp.St, List(Ast.Expr) -> Interp.Vals
	eval_all = |st, exprs| {
		var $s = st
		var $vals = []
		for e in exprs {
			{ st: after, val } = Interp.eval($s, e)
			$s = after
			$vals = $vals.append(val)
		}
		{ st: $s, vals: $vals }
	}

	eval_template : Interp.St, List(Str), List(Ast.Expr) -> Interp.Got
	eval_template = |st, texts, parts| {
		var $s = st
		var $text = texts.first() ?? ""
		var $i = 1
		for part in parts {
			{ st: after, val } = Interp.eval($s, part)
			$s = match Interp.text_of(after.cells, val) {
				Ok(t) => {
					$text = Str.concat(Str.concat($text, t), texts.get($i) ?? "")
					after
				}
				Err(Unsupported(why)) => Interp.faulted(after, why)
			}
			$i = $i + 1
		}
		{ st: $s, val: Text($text) }
	}

	eval_name : Interp.St, Str, Ast.Where -> Interp.Got
	eval_name = |st, name, w|
		match Interp.lookup(st.scopes, st.scope, name) {
			Found(f) => match f.binding.state {
				Unready => Interp.fault_got(st, "ReferenceError: Cannot access '${name}' before initialization${Interp.at_line(w)}")
				_ => { st: st, val: f.binding.val }
			}
			Missing => Interp.fault_got(st, Interp.missing_name_message(name, w))
		}

	missing_name_message : Str, Ast.Where -> Str
	missing_name_message = |name, w|
		if ["globalThis", "window", "require", "process", "JSON", "Map", "Set", "Symbol", "Promise", "Date", "RegExp", "parseInt", "parseFloat", "setTimeout", "Error", "BigInt", "Reflect", "Proxy"].contains(name) {
			"unsupported: the builtin `${name}`${Interp.at_line(w)}"
		} else {
			"ReferenceError: ${name} is not defined${Interp.at_line(w)}"
		}

	unary : Interp.St, Ast.UnaryOp, Heap.Val, Ast.Where -> Interp.Got
	unary = |st, op, v, w|
		match op {
			Not => { st: st, val: Boolean(!Interp.is_truthy(v)) }
			TypeOf => { st: st, val: Text(Interp.type_of(st.cells, v)) }
			Negate => match v {
				Number(n) => { st: st, val: Number(-n) }
				_ => Interp.fault_got(st, "unsupported: `-` on a ${Interp.type_of(st.cells, v)} (a coercion)${Interp.at_line(w)}")
			}
			Plus => match v {
				Number(n) => { st: st, val: Number(n) }
				_ => Interp.fault_got(st, "unsupported: `+` on a ${Interp.type_of(st.cells, v)} (a coercion)${Interp.at_line(w)}")
			}
		}

	binary : Interp.St, Ast.BinaryOp, Heap.Val, Heap.Val, Ast.Where -> Interp.Got
	binary = |st, op, a, b, w|
		match op {
			StrictEqual => { st: st, val: Boolean(Interp.is_strictly_equal(a, b)) }
			StrictNotEqual => { st: st, val: Boolean(!Interp.is_strictly_equal(a, b)) }
			Add => Interp.add(st, a, b, w)
			_ => match (a, b) {
				(Number(x), Number(y)) => { st: st, val: Interp.arithmetic(op, x, y) }
				(Text(x), Text(y)) => match op {
					Less => { st: st, val: Boolean(Interp.ordering_of_text(x, y) == Before) }
					LessOrEqual => { st: st, val: Boolean(Interp.ordering_of_text(x, y) != After) }
					Greater => { st: st, val: Boolean(Interp.ordering_of_text(x, y) == After) }
					GreaterOrEqual => { st: st, val: Boolean(Interp.ordering_of_text(x, y) != Before) }
					_ => Interp.fault_got(st, "unsupported: arithmetic on strings (a coercion)${Interp.at_line(w)}")
				}
				_ => Interp.fault_got(st, "unsupported: an operator on a ${Interp.type_of(st.cells, a)} and a ${Interp.type_of(st.cells, b)} (a coercion)${Interp.at_line(w)}")
			}
		}

	arithmetic : Ast.BinaryOp, F64, F64 -> Heap.Val
	arithmetic = |op, x, y| match op {
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
	add : Interp.St, Heap.Val, Heap.Val, Ast.Where -> Interp.Got
	add = |st, a, b, w|
		match (a, b) {
			(Number(x), Number(y)) => { st: st, val: Number(x + y) }
			_ => {
				is_texty = |v| match v {
					Text(_) => True
					Ref(_) => True
					_ => False
				}
				if is_texty(a) or is_texty(b) {
					match (Interp.text_of(st.cells, a), Interp.text_of(st.cells, b)) {
						(Ok(x), Ok(y)) => { st: st, val: Text(Str.concat(x, y)) }
						(Err(Unsupported(why)), _) => Interp.fault_got(st, "${why}${Interp.at_line(w)}")
						(_, Err(Unsupported(why))) => Interp.fault_got(st, "${why}${Interp.at_line(w)}")
					}
				} else {
					Interp.fault_got(st, "unsupported: `+` on a ${Interp.type_of(st.cells, a)} and a ${Interp.type_of(st.cells, b)} (a coercion)${Interp.at_line(w)}")
				}
			}
		}

	combined : Interp.St, Ast.AssignOp, Heap.Val, Heap.Val, Ast.Where -> Interp.Got
	combined = |st, op, old, new, w|
		match op {
			Set => { st: st, val: new }
			Combine(b) => Interp.binary(st, b, old, new, w)
		}

	eval_assign : Interp.St, Ast.Target, Ast.AssignOp, Ast.Expr, Ast.Where -> Interp.Got
	eval_assign = |st, target, op, e, w|
		match target {
			ToName(name, at) => {
				match Interp.place_of(st.scopes, st.scope, name) {
					Unplaced => Interp.fault_got(st, "unsupported: assigning to `${name}`, which is not declared${Interp.at_line(at)}")
					Placed(place) => {
						appends = op == Combine(Add) and place.state == Mutable and place.holds_text and Interp.is_pure(e)
						if appends {
							Interp.appended_name(st, place.scope, place.index, e, w)
						} else {
							old = Interp.var_value(st.scopes, place.scope, place.index)
							{ st: after, val } = Interp.eval(st, e)
							{ st: made, val: value } = Interp.combined(after, op, old, val, w)
							Interp.assigned_name(made, value, name, at)
						}
					}
				}
			}
			ToMember(obj, key) => {
				{ st: first, val: o } = Interp.eval(st, obj)
				{ st: second, val: old } = match op {
					Set => { st: first, val: Undefined }
					Combine(_) => Interp.property(first, o, key, w)
				}
				{ st: third, val } = Interp.eval(second, e)
				{ st: made, val: value } = Interp.combined(third, op, old, val, w)
				Interp.stored(made, o, Text(key), value, w)
			}
			ToIndex(obj, key) => {
				{ st: first, val: o } = Interp.eval(st, obj)
				{ st: second, val: k } = Interp.eval(first, key)
				{ st: third, val: old } = match op {
					Set => { st: second, val: Undefined }
					Combine(_) => Interp.indexed(second, o, k, w)
				}
				{ st: fourth, val } = Interp.eval(third, e)
				{ st: made, val: value } = Interp.combined(fourth, op, old, val, w)
				Interp.stored(made, o, k, value, w)
			}
		}

	# A variable written, found again after the value was made: making it may
	# have run code that added scopes.
	assigned_name : Interp.St, Heap.Val, Str, Ast.Where -> Interp.Got
	assigned_name = |st, val, name, w|
		if !Interp.is_running(st) {
			{ st: st, val: val }
		} else {
			match Interp.lookup(st.scopes, st.scope, name) {
				Found(f) => match f.binding.state {
					Mutable => Interp.var_written(st, f.scope, f.index, { ..f.binding, val: val })
					Fixed => Interp.fault_got(st, "TypeError: Assignment to constant variable.${Interp.at_line(w)}")
					Unready => Interp.fault_got(st, "ReferenceError: Cannot access '${name}' before initialization${Interp.at_line(w)}")
				}
				Missing => Interp.fault_got(st, "ReferenceError: ${name} is not defined${Interp.at_line(w)}")
			}
		}

	# Where a variable is, and what it holds, with nothing of its value kept:
	# a kept copy of a string is a second reference to it.
	Place : [Placed({ scope : U64, index : U64, state : Interp.VarState, holds_text : Bool }), Unplaced]

	place_of : List(Interp.Scope), U64, Str -> Interp.Place
	place_of = |scopes, start, name|
		match Interp.lookup(scopes, start, name) {
			Found(f) => Placed({ scope: f.scope, index: f.index, state: f.binding.state, holds_text: Interp.is_text(f.binding.val) })
			Missing => Unplaced
		}

	is_text : Heap.Val -> Bool
	is_text = |v| match v {
		Text(_) => True
		_ => False
	}

	# Whether evaluating an expression can't change a variable: it calls
	# nothing, assigns nothing and makes no function.
	is_pure : Ast.Expr -> Bool
	is_pure = |e| match e {
		Number(_) => True
		Text(_) => True
		Boolean(_) => True
		Null => True
		Undefined => True
		Name(_, _) => True
		Template(_, parts) => parts.all(Interp.is_pure)
		ArrayLit(items) => items.all(Interp.is_pure)
		ObjectLit(props) => props.all(|p| Interp.is_pure(p.value))
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
	appended_name : Interp.St, U64, U64, Ast.Expr, Ast.Where -> Interp.Got
	appended_name = |st, sid, index, e, w| {
		{ st: after, val: rhs } = Interp.eval(st, e)
		if !Interp.is_running(after) {
			{ st: after, val: Undefined }
		} else {
			match Interp.text_of(after.cells, rhs) {
				Err(Unsupported(why)) => Interp.fault_got(after, "${why}${Interp.at_line(w)}")
				Ok(tail) => Interp.text_appended(after, sid, index, tail)
			}
		}
	}

	text_appended : Interp.St, U64, U64, Str -> Interp.Got
	text_appended = |st, sid, index, tail| {
		grown = { ..st, scopes: Interp.scopes_with_appended(st.scopes, sid, index, tail) }
		{ st: grown, val: Interp.var_value(grown.scopes, sid, index) }
	}

	var_value : List(Interp.Scope), U64, U64 -> Heap.Val
	var_value = |scopes, sid, index| {
		scope = scopes.get(sid) ?? crash "Interp.var_value: a scope the machine has"
		binding = scope.vars.get(index) ?? crash "Interp.var_value: a variable the scope has"
		binding.val
	}

	scopes_with_appended : List(Interp.Scope), U64, U64, Str -> List(Interp.Scope)
	scopes_with_appended = |scopes, sid, index, tail| {
		taken = scopes.replace(sid, { vars: [], parent: Outermost }) ?? crash "Interp.scopes_with_appended: a scope the machine has"
		taken.list.set(sid, Interp.scope_with_appended(taken.prev, index, tail)) ?? crash "Interp.scopes_with_appended: the scope was just taken"
	}

	scope_with_appended : Interp.Scope, U64, Str -> Interp.Scope
	scope_with_appended = |scope, index, tail| {
		{ vars, parent } = scope
		taken = vars.replace(index, { name: "", val: Undefined, state: Unready }) ?? crash "Interp.scope_with_appended: a variable the scope has"
		{ vars: taken.list.set(index, Interp.var_with_appended(taken.prev, tail)) ?? crash "Interp.scope_with_appended: the variable was just taken", parent: parent }
	}

	var_with_appended : Interp.Var, Str -> Interp.Var
	var_with_appended = |binding, tail| {
		{ name, val, state } = binding
		{ name: name, val: Interp.val_with_appended(val, tail), state: state }
	}

	val_with_appended : Heap.Val, Str -> Heap.Val
	val_with_appended = |val, tail| match val {
		Text(old) => Text(Str.concat(old, tail))
		_ => crash "Interp.val_with_appended: the interpreter appends only to a variable that holds a string"
	}

	var_written : Interp.St, U64, U64, Interp.Var -> Interp.Got
	var_written = |st, sid, index, binding| { st: { ..st, scopes: Interp.with_var(st.scopes, sid, index, binding) }, val: binding.val }

	eval_update : Interp.St, Ast.Target, Ast.Step, Ast.Fixity, Ast.Where -> Interp.Got
	eval_update = |st, target, step, fixity, w| {
		delta = match step {
			Increment => 1.0
			Decrement => -1.0
		}
		answer = |old, new| match fixity {
			Prefix => Number(new)
			Postfix => Number(old)
		}
		match target {
			ToName(name, at) => {
				{ st: read_st, val: current } = Interp.eval_name(st, name, at)
				match current {
					Number(n) => {
						{ st: written, val: _ } = Interp.assigned_name(read_st, Number(n + delta), name, at)
						{ st: written, val: answer(n, n + delta) }
					}
					_ => Interp.fault_got(read_st, "unsupported: `++` or `--` on a ${Interp.type_of(read_st.cells, current)}${Interp.at_line(w)}")
				}
			}
			ToMember(obj, key) => {
				{ st: first, val: o } = Interp.eval(st, obj)
				{ st: read_st, val: current } = Interp.property(first, o, key, w)
				match current {
					Number(n) => {
						{ st: written, val: _ } = Interp.stored(read_st, o, Text(key), Number(n + delta), w)
						{ st: written, val: answer(n, n + delta) }
					}
					_ => Interp.fault_got(read_st, "unsupported: `++` or `--` on a ${Interp.type_of(read_st.cells, current)}${Interp.at_line(w)}")
				}
			}
			ToIndex(obj, key) => {
				{ st: first, val: o } = Interp.eval(st, obj)
				{ st: second, val: k } = Interp.eval(first, key)
				{ st: read_st, val: current } = Interp.indexed(second, o, k, w)
				match current {
					Number(n) => {
						{ st: written, val: _ } = Interp.stored(read_st, o, k, Number(n + delta), w)
						{ st: written, val: answer(n, n + delta) }
					}
					_ => Interp.fault_got(read_st, "unsupported: `++` or `--` on a ${Interp.type_of(read_st.cells, current)}${Interp.at_line(w)}")
				}
			}
		}
	}

	# ---- properties ------------------------------------------------------------

	property : Interp.St, Heap.Val, Str, Ast.Where -> Interp.Got
	property = |st, obj, key, w|
		match obj {
			Ref(id) => match Heap.cell_at(st.cells, id) {
				Obj(props) => {
					if Heap.has_prop(props, key) {
						{ st: st, val: Heap.prop_value(props, key) }
					} else if Interp.is_prototype_name(key) {
						Interp.fault_got(st, "unsupported: Object.prototype's `${key}`${Interp.at_line(w)}")
					} else {
						{ st: st, val: Undefined }
					}
				}
				Arr(items) => {
					if key == "length" {
						{ st: st, val: Number(items.len().to_f64()) }
					} else {
						match Inspect.index_of_key(key) {
							Ok(i) => { st: st, val: items.get(i) ?? Undefined }
							Err(NotIndex) => Interp.fault_got(st, "unsupported: the array property `${key}` outside a call${Interp.at_line(w)}")
						}
					}
				}
				Namespace(name, props) => {
					if Heap.has_prop(props, key) {
						{ st: st, val: Heap.prop_value(props, key) }
					} else {
						Interp.fault_got(st, "unsupported: `${name}.${key}`${Interp.at_line(w)}")
					}
				}
				Builtin(n, props) => {
					if Heap.has_prop(props, key) {
						{ st: st, val: Heap.prop_value(props, key) }
					} else {
						Interp.fault_got(st, "unsupported: `${Heap.native_name(n)}.${key}`${Interp.at_line(w)}")
					}
				}
				Fun(_) => Interp.fault_got(st, "unsupported: a function's properties (`${key}`)${Interp.at_line(w)}")
				Taken => crash "Interp.property: no cell is out being written while a property is read"
			}
			Text(s) => {
				if key == "length" {
					if Interp.is_ascii(s) {
						{ st: st, val: Number(s.count_utf8_bytes().to_f64()) }
					} else {
						Interp.fault_got(st, "unsupported: the length of a string with non-ASCII text${Interp.at_line(w)}")
					}
				} else {
					match Inspect.index_of_key(key) {
						Ok(i) => Interp.char_at(st, s, i, w)
						Err(NotIndex) => Interp.fault_got(st, "unsupported: the string property `${key}` outside a call${Interp.at_line(w)}")
					}
				}
			}
			Null => Interp.fault_got(st, "TypeError: Cannot read properties of null (reading '${key}')${Interp.at_line(w)}")
			Undefined => Interp.fault_got(st, "TypeError: Cannot read properties of undefined (reading '${key}')${Interp.at_line(w)}")
			_ => Interp.fault_got(st, "unsupported: the property `${key}` of a ${Interp.type_of(st.cells, obj)}${Interp.at_line(w)}")
		}

	is_prototype_name : Str -> Bool
	is_prototype_name = |key| ["toString", "hasOwnProperty", "valueOf", "constructor", "isPrototypeOf", "propertyIsEnumerable", "toLocaleString", "__proto__"].contains(key)

	is_ascii : Str -> Bool
	is_ascii = |s| s.to_utf8().all(|c| c < 128)

	char_at : Interp.St, Str, U64, Ast.Where -> Interp.Got
	char_at = |st, s, i, w|
		if !Interp.is_ascii(s) {
			Interp.fault_got(st, "unsupported: indexing a string with non-ASCII text${Interp.at_line(w)}")
		} else {
			match s.to_utf8().get(i) {
				Ok(c) => { st: st, val: Text(Str.from_utf8([c]) ?? crash "Interp.char_at: an ASCII byte") }
				Err(OutOfBounds) => { st: st, val: Undefined }
			}
		}

	indexed : Interp.St, Heap.Val, Heap.Val, Ast.Where -> Interp.Got
	indexed = |st, obj, key, w|
		match (obj, Interp.index_of(key)) {
			(Ref(id), Ok(i)) => match Heap.cell_at(st.cells, id) {
				Arr(items) => { st: st, val: items.get(i) ?? Undefined }
				_ => Interp.property_by_value(st, obj, key, w)
			}
			(Text(s), Ok(i)) => Interp.char_at(st, s, i, w)
			_ => Interp.property_by_value(st, obj, key, w)
		}

	property_by_value : Interp.St, Heap.Val, Heap.Val, Ast.Where -> Interp.Got
	property_by_value = |st, obj, key, w|
		match Interp.key_of(key) {
			Ok(k) => Interp.property(st, obj, k, w)
			Err(Unsupported(why)) => Interp.fault_got(st, "${why}${Interp.at_line(w)}")
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
			Obj(_) => ObjectKind
			Arr(items) => ArrayKind(items.len())
			Fun(_) => FunctionKind
			Builtin(_, _) => BuiltinKind
			Namespace(_, _) => BuiltinKind
			Taken => crash "Interp.kind_of: no cell is out being written while another is asked about"
		}

	# A property or an item written: an object's property, an array's item
	# inside it or at its end.
	stored : Interp.St, Heap.Val, Heap.Val, Heap.Val, Ast.Where -> Interp.Got
	stored = |st, obj, key, val, w|
		if !Interp.is_running(st) {
			{ st: st, val: val }
		} else {
			match obj {
				Ref(id) => match Interp.kind_of(st.cells, id) {
					ObjectKind => match Interp.key_of(key) {
						Ok(k) => { st: { ..st, cells: Heap.with_prop(st.cells, id, k, val) }, val: val }
						Err(Unsupported(why)) => Interp.fault_got(st, "${why}${Interp.at_line(w)}")
					}
					ArrayKind(n) => {
						match Interp.index_of(key) {
							Ok(i) if i <= n => { st: { ..st, cells: Heap.with_item(st.cells, id, i, val) }, val: val }
							Ok(_) => Interp.fault_got(st, "unsupported: an array with holes (a write past its end)${Interp.at_line(w)}")
							Err(NotIndex) => Interp.fault_got(st, "unsupported: writing an array's `length` or a named property${Interp.at_line(w)}")
						}
					}
					_ => Interp.fault_got(st, "unsupported: writing a property of a function or a builtin${Interp.at_line(w)}")
				}
				Null => Interp.fault_got(st, "TypeError: Cannot set properties of null${Interp.at_line(w)}")
				Undefined => Interp.fault_got(st, "TypeError: Cannot set properties of undefined${Interp.at_line(w)}")
				_ => Interp.fault_got(st, "unsupported: writing a property of a ${Interp.type_of(st.cells, obj)}${Interp.at_line(w)}")
			}
		}

	# ---- calls -----------------------------------------------------------------

	eval_call : Interp.St, Ast.Expr, List(Ast.Expr), Ast.Where -> Interp.Got
	eval_call = |st, callee, args, w|
		match callee {
			Member(obj, name, _) => {
				{ st: first, val: o } = Interp.eval(st, obj)
				method = match o {
					Ref(id) => match Interp.kind_of(first.cells, id) {
						ArrayKind(_) => ArrayMethod(id)
						_ => Plain
					}
					Text(s) => TextMethod(s)
					_ => Plain
				}
				match method {
					ArrayMethod(id) => {
						{ st: second, vals } = Interp.eval_all(first, args)
						Interp.array_method(second, id, name, vals, w)
					}
					TextMethod(s) => {
						{ st: second, vals } = Interp.eval_all(first, args)
						Interp.text_method(second, s, name, vals, w)
					}
					Plain => {
						{ st: second, val: f } = Interp.property(first, o, name, w)
						{ st: third, vals } = Interp.eval_all(second, args)
						Interp.call(third, f, vals, w)
					}
				}
			}
			_ => {
				{ st: first, val: f } = Interp.eval(st, callee)
				{ st: second, vals } = Interp.eval_all(first, args)
				Interp.call(second, f, vals, w)
			}
		}

	call : Interp.St, Heap.Val, List(Heap.Val), Ast.Where -> Interp.Got
	call = |st, callee, args, w|
		if !Interp.is_running(st) {
			{ st: st, val: Undefined }
		} else {
			match callee {
				Ref(id) => match Heap.cell_at(st.cells, id) {
					Fun(c) => Interp.call_closure(st, c, args, w)
					Builtin(n, _) => Interp.call_native(st, n, args, w)
					_ => Interp.fault_got(st, "TypeError: ${Interp.shown_value(st.cells, callee)} is not a function${Interp.at_line(w)}")
				}
				_ => Interp.fault_got(st, "TypeError: ${Interp.shown_value(st.cells, callee)} is not a function${Interp.at_line(w)}")
			}
		}

	call_closure : Interp.St, Heap.Closure, List(Heap.Val), Ast.Where -> Interp.Got
	call_closure = |st, c, args, w|
		if st.depth >= Interp.max_depth {
			Interp.fault_got(st, "RangeError: Maximum call stack size exceeded${Interp.at_line(w)}")
		} else {
			outer = st.scope
			var $s = Interp.entered({ ..st, depth: st.depth + 1 }, Within(c.scope))
			id = $s.scope
			var $i = 0
			for name in c.fun.params {
				$s = Interp.declare($s, name, args.get($i) ?? Undefined, Mutable)
				$i = $i + 1
			}
			{ st: after, flow } = Interp.exec_list(Interp.hoisted($s, c.fun.body), c.fun.body)
			val = match flow {
				Returned(v) => v
				_ => Undefined
			}
			back = Interp.left(after, id, outer, c.fun.capture)
			{ st: { ..back, depth: back.depth - 1 }, val: val }
		}

	number_arg : List(Heap.Val), U64 -> Try(F64, [NotNumber])
	number_arg = |args, i|
		match args.get(i) {
			Ok(Number(n)) => Ok(n)
			_ => Err(NotNumber)
		}

	math : Interp.St, Str, List(Heap.Val), (F64 -> F64), Ast.Where -> Interp.Got
	math = |st, name, args, f, w|
		match Interp.number_arg(args, 0) {
			Ok(n) => { st: st, val: Number(f(n)) }
			Err(NotNumber) => Interp.fault_got(st, "unsupported: Math.${name} of anything but a number${Interp.at_line(w)}")
		}

	floor : F64 -> F64
	floor = |n|
		if n.is_nan() or n.is_infinite() or n == 0.0 {
			n
		} else {
			n.div_floor_by(1.0)
		}

	call_native : Interp.St, Heap.Native, List(Heap.Val), Ast.Where -> Interp.Got
	call_native = |st, n, args, w|
		match n {
			Log => match Inspect.line_of(st.cells, args) {
				Ok(line) => { st: { ..st, out: Str.concat(Str.concat(st.out, line), "\n") }, val: Undefined }
				Err(Unsupported(why)) => Interp.fault_got(st, "${why}${Interp.at_line(w)}")
			}
			Floor => Interp.math(st, "floor", args, Interp.floor, w)
			Ceil => Interp.math(st, "ceil", args, |x| -Interp.floor(-x), w)
			Round => Interp.math(
				st,
				"round",
				args,
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
				st,
				"trunc",
				args,
				|x|
					if x.is_nan() or x.is_infinite() {
						x
					} else {
						x.div_trunc_by(1.0)
					},
				w,
			)
			Abs => Interp.math(st, "abs", args, |x| x.abs(), w)
			Sign => Interp.math(
				st,
				"sign",
				args,
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
			Sqrt => Interp.math(st, "sqrt", args, |x| x.sqrt(), w)
			Sin => Interp.math(st, "sin", args, |x| x.sin(), w)
			Cos => Interp.math(st, "cos", args, |x| x.cos(), w)
			Tan => Interp.math(st, "tan", args, |x| x.tan(), w)
			Atan => Interp.math(st, "atan", args, |x| x.atan(), w)
			Pow => match (Interp.number_arg(args, 0), Interp.number_arg(args, 1)) {
				(Ok(x), Ok(y)) => { st: st, val: Number(Interp.power(x, y)) }
				_ => Interp.fault_got(st, "unsupported: Math.pow of anything but two numbers${Interp.at_line(w)}")
			}
			Min => Interp.min_max(st, args, Min, w)
			Max => Interp.min_max(st, args, Max, w)
			Keys => Interp.object_listing(st, args, Keys, w)
			Values => Interp.object_listing(st, args, Values, w)
			Entries => Interp.object_listing(st, args, Entries, w)
			StringOf => match args.first() {
				Ok(v) => match Interp.text_of(st.cells, v) {
					Ok(t) => { st: st, val: Text(t) }
					Err(Unsupported(why)) => Interp.fault_got(st, "${why}${Interp.at_line(w)}")
				}
				Err(ListWasEmpty) => { st: st, val: Text("") }
			}
			FromCharCode => {
				var $bytes = []
				var $ok = True
				for a in args {
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
					{ st: st, val: Text(Str.from_utf8($bytes) ?? crash "Interp.call_native: ASCII bytes") }
				} else {
					Interp.fault_got(st, "unsupported: String.fromCharCode of anything but ASCII codes${Interp.at_line(w)}")
				}
			}
			IsArray => match args.first() {
				Ok(Ref(id)) => match Heap.cell_at(st.cells, id) {
					Arr(_) => { st: st, val: Boolean(True) }
					_ => { st: st, val: Boolean(False) }
				}
				_ => { st: st, val: Boolean(False) }
			}
			IsInteger => match args.first() {
				Ok(Number(x)) => { st: st, val: Boolean(!x.is_nan() and !x.is_infinite() and x.div_trunc_by(1.0) == x) }
				_ => { st: st, val: Boolean(False) }
			}
		}

	min_max : Interp.St, List(Heap.Val), [Min, Max], Ast.Where -> Interp.Got
	min_max = |st, args, which, w| {
		var $best = match which {
			Min => 1.0 / 0.0
			Max => -1.0 / 0.0
		}
		var $ok = True
		for a in args {
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
			{ st: st, val: Number($best) }
		} else {
			Interp.fault_got(st, "unsupported: Math.min or Math.max of anything but numbers${Interp.at_line(w)}")
		}
	}

	# Object.keys, Object.values or Object.entries, of an object or an array.
	object_listing : Interp.St, List(Heap.Val), [Keys, Values, Entries], Ast.Where -> Interp.Got
	object_listing = |st, args, which, w| {
		props = match args.first() {
			Ok(Ref(id)) => match Heap.cell_at(st.cells, id) {
				Obj(ps) => Ok(Inspect.props_in_key_order(ps))
				Arr(items) => {
					var $ps = []
					var $i = 0
					for item in items {
						$ps = $ps.append({ key: $i.to_str(), val: item })
						$i = $i + 1
					}
					Ok($ps)
				}
				_ => Err(NotListed)
			}
			_ => Err(NotListed)
		}
		match props {
			Ok(ps) => {
				var $s = st
				var $vals = []
				for p in ps {
					v = match which {
						Keys => Text(p.key)
						Values => p.val
						Entries => {
							{ st: made, val: pair } = Interp.alloc($s, Arr([Text(p.key), p.val]))
							$s = made
							pair
						}
					}
					$vals = $vals.append(v)
				}
				Interp.alloc($s, Arr($vals))
			}
			Err(NotListed) => Interp.fault_got(st, "unsupported: Object.keys, values or entries of anything but an object or an array${Interp.at_line(w)}")
		}
	}

	# ---- array methods ---------------------------------------------------------

	items_of : Interp.St, U64 -> List(Heap.Val)
	items_of = |st, id|
		match Heap.cell_at(st.cells, id) {
			Arr(items) => items
			_ => crash "Interp.items_of: the interpreter asks only an array for its items"
		}

	item_count : Interp.St, U64 -> U64
	item_count = |st, id|
		match Heap.cell_at(st.cells, id) {
			Arr(items) => items.len()
			_ => crash "Interp.item_count: the interpreter asks only an array for its length"
		}

	item_at : Interp.St, U64, U64 -> Heap.Val
	item_at = |st, id, i|
		match Heap.cell_at(st.cells, id) {
			Arr(items) => items.get(i) ?? Undefined
			_ => crash "Interp.item_at: the interpreter asks only an array for an item"
		}

	# A relative index (`slice`'s, negative from the end) as an index in 0..n.
	relative_index : Heap.Val, U64, U64 -> U64
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

	array_method : Interp.St, U64, Str, List(Heap.Val), Ast.Where -> Interp.Got
	array_method = |st, id, name, args, w|
		match name {
			"push" => {
				pushed = { ..st, cells: Heap.with_items_pushed(st.cells, id, args) }
				{ st: pushed, val: Number(Interp.item_count(pushed, id).to_f64()) }
			}
			"pop" => {
				n = Interp.item_count(st, id)
				if n == 0 {
					{ st: st, val: Undefined }
				} else {
					last = Interp.item_at(st, id, n - 1)
					{ st: { ..st, cells: Heap.with_last_dropped(st.cells, id) }, val: last }
				}
			}
			"join" => {
				sep = match args.first() {
					Ok(Text(s)) => Ok(s)
					Ok(Undefined) => Ok(",")
					Err(ListWasEmpty) => Ok(",")
					_ => Err(NotText)
				}
				match sep {
					Ok(s) => {
						var $parts = []
						var $why = ""
						for item in Interp.items_of(st, id) {
							part = match item {
								Null => Ok("")
								Undefined => Ok("")
								_ => Interp.text_of(st.cells, item)
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
							{ st: st, val: Text(Str.join_with($parts, s)) }
						} else {
							Interp.fault_got(st, "${$why}${Interp.at_line(w)}")
						}
					}
					Err(NotText) => Interp.fault_got(st, "unsupported: `join` with a separator that is not a string${Interp.at_line(w)}")
				}
			}
			"indexOf" => {
				target = args.first() ?? Undefined
				var $found = -1.0
				var $i = 0.0
				for item in Interp.items_of(st, id) {
					if $found < 0.0 and Interp.is_strictly_equal(item, target) {
						$found = $i
					}
					$i = $i + 1.0
				}
				{ st: st, val: Number($found) }
			}
			"includes" => {
				target = args.first() ?? Undefined
				found = Interp.items_of(st, id).any(|item| Interp.is_same_value_zero(item, target))
				{ st: st, val: Boolean(found) }
			}
			"slice" => {
				items = Interp.items_of(st, id)
				n = items.len()
				from = Interp.relative_index(args.get(0) ?? Undefined, n, 0)
				to = Interp.relative_index(args.get(1) ?? Undefined, n, n)
				cut = if to > from {
					items.sublist({ start: from, len: to - from })
				} else {
					[]
				}
				Interp.alloc(st, Arr(cut))
			}
			"concat" => {
				var $out = Interp.items_of(st, id)
				for a in args {
					$out = match a {
						Ref(other) => match Heap.cell_at(st.cells, other) {
							Arr(more) => $out.concat(more)
							_ => $out.append(a)
						}
						_ => $out.append(a)
					}
				}
				Interp.alloc(st, Arr($out))
			}
			"reverse" => {
				items = Interp.items_of(st, id)
				var $reversed = []
				var $k = items.len()
				while $k > 0 {
					$reversed = $reversed.append(items.get($k - 1) ?? crash "Interp.array_method: inside the items")
					$k = $k - 1
				}
				reversed = $reversed
				{ st: { ..st, cells: Heap.with_items(st.cells, id, reversed) }, val: Ref(id) }
			}
			"forEach" => Interp.array_walk(st, id, args, ForEach, w)
			"map" => Interp.array_walk(st, id, args, Map, w)
			"filter" => Interp.array_walk(st, id, args, Filter, w)
			"some" => Interp.array_walk(st, id, args, Some, w)
			"every" => Interp.array_walk(st, id, args, Every, w)
			"find" => Interp.array_walk(st, id, args, Find, w)
			"findIndex" => Interp.array_walk(st, id, args, FindIndex, w)
			"reduce" => Interp.array_reduce(st, id, args, w)
			"sort" => Interp.array_sort(st, id, args, w)
			_ => Interp.fault_got(st, "unsupported: the array method `${name}`${Interp.at_line(w)}")
		}

	Walk : [ForEach, Map, Filter, Some, Every, Find, FindIndex]

	# An array method that calls a function on each item in turn, the items
	# read from the heap as it goes, since the function may change the array.
	array_walk : Interp.St, U64, List(Heap.Val), Interp.Walk, Ast.Where -> Interp.Got
	array_walk = |st, id, args, walk, w| {
		f = args.first() ?? Undefined
		n = Interp.item_count(st, id)
		var $s = st
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
			{ st: after, val } = Interp.call($s, f, [item, Number($i.to_f64()), Ref(id)], w)
			$s = after
			match walk {
				ForEach => {}
				Map => {
					$out = $out.append(val)
				}
				Filter => {
					if Interp.is_truthy(val) {
						$out = $out.append(item)
					}
				}
				Some => {
					if Interp.is_truthy(val) {
						$answer = Boolean(True)
						$going = False
					}
				}
				Every => {
					if !Interp.is_truthy(val) {
						$answer = Boolean(False)
						$going = False
					}
				}
				Find => {
					if Interp.is_truthy(val) {
						$answer = item
						$going = False
					}
				}
				FindIndex => {
					if Interp.is_truthy(val) {
						$answer = Number($i.to_f64())
						$going = False
					}
				}
			}
			$going = $going and Interp.is_running($s)
			$i = $i + 1
		}
		match walk {
			Map => Interp.alloc($s, Arr($out))
			Filter => Interp.alloc($s, Arr($out))
			_ => { st: $s, val: $answer }
		}
	}

	array_reduce : Interp.St, U64, List(Heap.Val), Ast.Where -> Interp.Got
	array_reduce = |st, id, args, w| {
		f = args.first() ?? Undefined
		n = Interp.item_count(st, id)
		start = match args.get(1) {
			Ok(v) => Ok({ acc: v, from: 0 })
			Err(OutOfBounds) => {
				if n == 0 {
					Err(Empty)
				} else {
					Ok({ acc: Interp.item_at(st, id, 0), from: 1 })
				}
			}
		}
		match start {
			Err(Empty) => Interp.fault_got(st, "TypeError: Reduce of empty array with no initial value${Interp.at_line(w)}")
			Ok({ acc, from }) => {
				var $s = st
				var $acc = acc
				var $i = from
				while $i < n and $i < Interp.item_count($s, id) and Interp.is_running($s) {
					item = Interp.item_at($s, id, $i)
					{ st: after, val } = Interp.call($s, f, [$acc, item, Number($i.to_f64()), Ref(id)], w)
					$s = after
					$acc = val
					$i = $i + 1
				}
				{ st: $s, val: $acc }
			}
		}
	}

	# `sort`, stable as JavaScript's is: a merge sort, the comparison a
	# function's answer or, with none, the items' text.
	array_sort : Interp.St, U64, List(Heap.Val), Ast.Where -> Interp.Got
	array_sort = |st, id, args, w| {
		items = Interp.items_of(st, id)
		compare = args.first() ?? Undefined
		{ st: after, vals } = Interp.merge_sorted(st, items, compare, w)
		if Interp.is_running(after) {
			{ st: { ..after, cells: Heap.with_items(after.cells, id, vals) }, val: Ref(id) }
		} else {
			{ st: after, val: Ref(id) }
		}
	}

	merge_sorted : Interp.St, List(Heap.Val), Heap.Val, Ast.Where -> Interp.Vals
	merge_sorted = |st, items, compare, w| {
		n = items.len()
		if n <= 1 {
			{ st: st, vals: items }
		} else {
			half = n // 2
			{ st: first, vals: lower } = Interp.merge_sorted(st, items.sublist({ start: 0, len: half }), compare, w)
			{ st: second, vals: upper } = Interp.merge_sorted(first, items.drop_first(half), compare, w)
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
					{ st: after, order } = Interp.compared($s, compare, a, b, w)
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
			{ st: $s, vals: $out }
		}
	}

	compared : Interp.St, Heap.Val, Heap.Val, Heap.Val, Ast.Where -> { st : Interp.St, order : [Before, Same, After] }
	compared = |st, compare, a, b, w|
		match compare {
			Undefined => {
				order = match (a, b) {
					(Undefined, Undefined) => Same
					(Undefined, _) => After
					(_, Undefined) => Before
					_ => match (Interp.text_of(st.cells, a), Interp.text_of(st.cells, b)) {
						(Ok(x), Ok(y)) => Interp.ordering_of_text(x, y)
						_ => Same
					}
				}
				{ st: st, order: order }
			}
			_ => {
				{ st: after, val } = Interp.call(st, compare, [a, b], w)
				order = match val {
					Number(x) => if x > 0.0 {
						After
					} else if x < 0.0 {
						Before
					} else {
						Same
					}
					_ => Same
				}
				{ st: after, order: order }
			}
		}

	# ---- string methods --------------------------------------------------------

	# The string methods that count or cut by position, which the subset has
	# for ASCII text alone: JavaScript counts UTF-16 units, where the
	# interpreter's strings are UTF-8.
	positional_methods : List(Str)
	positional_methods = ["charAt", "charCodeAt", "slice", "substring", "indexOf", "toUpperCase", "toLowerCase", "trim"]

	text_method : Interp.St, Str, Str, List(Heap.Val), Ast.Where -> Interp.Got
	text_method = |st, s, name, args, w|
		if Interp.positional_methods.contains(name) and !Interp.is_ascii(s) {
			Interp.fault_got(st, "unsupported: `${name}` on a string with non-ASCII text${Interp.at_line(w)}")
		} else if name == "split" and args.first() == Ok(Text("")) and !Interp.is_ascii(s) {
			Interp.fault_got(st, "unsupported: `split` into characters of a string with non-ASCII text${Interp.at_line(w)}")
		} else {
			Interp.text_method_of(st, s, name, args, w)
		}

	text_method_of : Interp.St, Str, Str, List(Heap.Val), Ast.Where -> Interp.Got
	text_method_of = |st, s, name, args, w| {
		text_arg = |i| match args.get(i) {
			Ok(Text(t)) => Ok(t)
			_ => Err(NotText)
		}
		bytes = s.to_utf8()
		n = bytes.len()
		sliced = |from, to|
			if to > from {
				Text(Str.from_utf8(bytes.sublist({ start: from, len: to - from })) ?? crash "Interp.text_method: an ASCII cut")
			} else {
				Text("")
			}
		match name {
			"charAt" => (
				match Interp.index_of(args.first() ?? Number(0.0)) {
					Ok(i) => {
						got = Interp.char_at(st, s, i, w)
						match got.val {
							Undefined => { st: st, val: Text("") }
							_ => got
						}
					}
					Err(NotIndex) => { st: st, val: Text("") }
				},
			)
			"charCodeAt" => (
				match Interp.index_of(args.first() ?? Number(0.0)) {
					Ok(i) => match bytes.get(i) {
						Ok(c) => { st: st, val: Number(c.to_f64()) }
						Err(OutOfBounds) => { st: st, val: Number(0.0 / 0.0) }
					}
					Err(NotIndex) => { st: st, val: Number(0.0 / 0.0) }
				},
			)
			"slice" => (
				{
					from = Interp.relative_index(args.get(0) ?? Undefined, n, 0)
					to = Interp.relative_index(args.get(1) ?? Undefined, n, n)
					{ st: st, val: sliced(from, to) }
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
					a = clamp(args.get(0) ?? Undefined, 0)
					b = clamp(args.get(1) ?? Undefined, n)
					{ st: st, val: sliced(U64.min(a, b), U64.max(a, b)) }
				},
			)
			"indexOf" => match text_arg(0) {
				Ok(t) => { st: st, val: Number(Interp.text_index(s, t)) }
				Err(NotText) => Interp.fault_got(st, "unsupported: `indexOf` of anything but a string${Interp.at_line(w)}")
			}
			"includes" => match text_arg(0) {
				Ok(t) => { st: st, val: Boolean(s.contains(t)) }
				Err(NotText) => Interp.fault_got(st, "unsupported: `includes` of anything but a string${Interp.at_line(w)}")
			}
			"startsWith" => match text_arg(0) {
				Ok(t) => { st: st, val: Boolean(s.starts_with(t)) }
				Err(NotText) => Interp.fault_got(st, "unsupported: `startsWith` of anything but a string${Interp.at_line(w)}")
			}
			"endsWith" => match text_arg(0) {
				Ok(t) => { st: st, val: Boolean(s.ends_with(t)) }
				Err(NotText) => Interp.fault_got(st, "unsupported: `endsWith` of anything but a string${Interp.at_line(w)}")
			}
			"toUpperCase" => { st: st, val: Text(s.with_ascii_uppercased()) }
			"toLowerCase" => { st: st, val: Text(s.with_ascii_lowercased()) }
			"trim" => { st: st, val: Text(Interp.ascii_trimmed(s)) }
			"repeat" => match args.first() {
				Ok(Number(k)) if k >= 0.0 and k.div_trunc_by(1.0) == k and k < 100000000.0 => {
					{ st: st, val: Text(Str.repeat(s, k.to_u64_try() ?? 0)) }
				}
				_ => Interp.fault_got(st, "unsupported: `repeat` of anything but a whole number of times${Interp.at_line(w)}")
			}
			"split" => match text_arg(0) {
				Ok("") => Interp.alloc(st, Arr(Interp.characters(s).map(|c| Text(c))))
				Ok(t) => Interp.alloc(st, Arr(s.split_on(t).map(|piece| Text(piece))))
				Err(NotText) => Interp.fault_got(st, "unsupported: `split` by anything but a string${Interp.at_line(w)}")
			}
			"padStart" => Interp.text_padded(st, s, args, PadStart, w)
			"padEnd" => Interp.text_padded(st, s, args, PadEnd, w)
			"concat" => {
				var $out = s
				var $why = ""
				for a in args {
					match Interp.text_of(st.cells, a) {
						Ok(t) => {
							$out = Str.concat($out, t)
						}
						Err(Unsupported(why)) => {
							$why = why
						}
					}
				}
				if $why == "" {
					{ st: st, val: Text($out) }
				} else {
					Interp.fault_got(st, "${$why}${Interp.at_line(w)}")
				}
			}
			_ => Interp.fault_got(st, "unsupported: the string method `${name}`${Interp.at_line(w)}")
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
		while $from < b.len() and is_space(b.get($from) ?? 0) {
			$from = $from + 1
		}
		var $to = b.len()
		while $to > $from and is_space(b.get($to - 1) ?? 0) {
			$to = $to - 1
		}
		Str.from_utf8(b.sublist({ start: $from, len: $to - $from })) ?? crash "Interp.ascii_trimmed: an ASCII cut"
	}

	text_padded : Interp.St, Str, List(Heap.Val), [PadStart, PadEnd], Ast.Where -> Interp.Got
	text_padded = |st, s, args, side, w| {
		fill = match args.get(1) {
			Ok(Text(f)) => Ok(f)
			Err(OutOfBounds) => Ok(" ")
			_ => Err(NotText)
		}
		match (args.first(), fill) {
			(Ok(Number(k)), Ok(f)) if Interp.is_ascii(s) and Interp.is_ascii(f) and k.div_trunc_by(1.0) == k and k < 100000000.0 => {
				n = s.count_utf8_bytes()
				target = if k < 0.0 {
					0
				} else {
					k.to_u64_try() ?? 0
				}
				if target <= n or f.is_empty() {
					{ st: st, val: Text(s) }
				} else {
					need = target - n
					fb = f.to_utf8()
					copies = need // fb.len() + 1
					pad = Str.from_utf8(Str.repeat(f, copies).to_utf8().sublist({ start: 0, len: need })) ?? crash "Interp.text_padded: an ASCII cut"
					match side {
						PadStart => { st: st, val: Text(Str.concat(pad, s)) }
						PadEnd => { st: st, val: Text(Str.concat(s, pad)) }
					}
				}
			}
			_ => Interp.fault_got(st, "unsupported: `padStart` or `padEnd` other than to a whole length with ASCII text${Interp.at_line(w)}")
		}
	}
}
