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
##   over the machine are `var $s` loops, never a `walk` with a lambda.
## - A write passes the list straight from the record it updates,
##   `{ ..machine, cells: Heap.with_property(machine.cells, ...) }`, so the
##   old machine is never read after the write that consumes it.
## - Every `Got` and `Done` is taken apart where it is answered,
##   `{ machine: after, value } = Interp.evaluate!(host, machine, expression)`, never
##   kept whole while its machine goes on to be written: a record kept for
##   its `value` keeps its `machine` too, a second reference to the heap and
##   the scopes, and each
##   write made while it lives copies them. Kept whole, a store into an
##   array copied the array and a closure's `++c` copied every scope.
## - A writer asks `ValueRules.kind_of` what a cell is, never matches the cell
##   out of the heap: the matched cell refers to its props or items for as
##   long as the arm runs.
##
## **THE VALUE RULES ARE `ValueRules`', LENT THE CELLS.** What a property
## read gives, what an operator makes of mixed values, the methods of
## strings, arrays, Maps and Sets that call nothing back, the builtins that
## make no effect, and their messages live in `ValueRules`, which the
## bytecode VM shares. The walker lends a rule its cells and status
## (`Interp.lent`) and takes back what the rule gives (`Interp.got_back`),
## through a function of its own for each rule (`Interp.property` and its
## kin), so the lending takes no room in the frames of the walk's recursive
## functions.
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
## **THE HOST RIDES BESIDE THE MACHINE, NEVER IN IT.** Every function on the
## way from a statement to a builtin takes the host's effects (`Canvas.Host`)
## as its first argument and is effectful, so `console.log` and a canvas
## builtin reach the host at the moment the program calls them, in program
## order. The host is a record of functions and refers to no part of the
## machine, so carrying it costs the walk nothing.
##
## **EVERY CALLBACK GOES THROUGH ONE QUEUE, ON A VIRTUAL CLOCK.** A timer
## (`setTimeout`, `setInterval`), a click for the `onClick` handler and the
## program's next `frame(t)` are each an `Event` in `machine.events`, due at
## a time in milliseconds; the queue and its rules are `Events`', which the
## VM shares. The clock reads 0 while the program runs and moves
## only when the host moves it: the page and the recording host tick it a
## frame at a time (`tick!`), and the command line runs the queue out
## (`drain!`). Each event runs at its time, earliest first, two at one time
## in the order they were queued, so the order is the program's alone, and
## the one node gives it.
##
## **THE WALK'S FUNCTIONS TAKE SEVERAL ARGUMENTS, A NAMED EXCEPTION.** As
## BASIC's workhorse does, the evaluator stays one big module and its
## functions take the host, then the machine, then the rest, where the style
## guide would take one record: a record holding the machine is a second
## reference to the heap. The queue's `tick!`, `drain!` and `run_event!`
## follow the same exception, and so do `timer_set` and `call!` they reach,
## the patterns' binders (`with_pattern_bound!` and its kin), an optional
## chain's links (`link!`, `call_link!`), and the methods of arrays and of
## Maps and Sets (`array_method!`, `collection_method!`).
##
## **A THROW UNWINDS THE WALK AS A FAULT STOPS IT.** A fault (a feature
## outside the subset, a budget) stops the run for good: `status` is set,
## every statement after it is skipped, and the message is the run's last
## line. A throw (`throw`, or one of JavaScript's own errors, `with_error`)
## sets `status` to the value thrown, and every statement after it is skipped
## the same way, back to the nearest `try`, which runs the machine on
## (`execute_try!`). One nothing catches ends the run as node ends it, and
## its host prints it (`Interp.Ending`).
import Ast
import Canvas
import Heap
import Events
import Inspect
import ValueRules

Interp :: [].{
	VariableState : [Mutable, Fixed, Unready]

	## A variable's value, and whether it may be written or read yet.
	Variable : { value : Heap.Value, state : Interp.VariableState }

	Parent : [Outermost, Within(U64)]

	Scope : { variables : List(Interp.Variable), parent : Interp.Parent }

	## How a run stands, as its host is told: running, stopped by a fault, or
	## stopped by a throw nothing caught, written as the line that says so.
	Ending : [Running, Faulted(Str), Uncaught(Str)]

	Machine : {
		cells : List(Heap.Cell),
		scopes : List(Interp.Scope),
		# How many of `scopes` are alive: the ones past it are dead slots, which
		# the next scope entered reuses.
		live_scopes : U64,
		scope : U64,
		steps : U64,
		step_limit : U64,
		effects : U64,
		effect_limit : U64,
		# What the budgets are counted for, for the message that says one ran
		# out: "the program", or "frame(t)".
		budgeted : Str,
		turtle : Canvas.Turtle,
		depth : U64,
		status : ValueRules.Status,
		events : Events.Queue,
	}

	## An expression's value, and the machine after it.
	Got : { machine : Interp.Machine, value : Heap.Value }

	Flow : [Normal, Broke(Ast.Label), Continued(Ast.Label), Returned(Heap.Value)]

	Done : { machine : Interp.Machine, flow : Interp.Flow }

	# ---- the run ---------------------------------------------------------------

	## How far a run (or one frame of it) may go: the statements it runs and
	## the effects it makes.
	Limits : { steps : U64, effects : U64 }

	Outcome : {
		steps : U64,
		cells : U64,
		scopes : U64,
		status : Interp.Ending,
	}

	## A program run to its end, then every timer it left, in the order of
	## their times (`drain!`), its effects handed to `host` as it runs.
	run! : Canvas.Host, Ast.Program, Ast.Library, Interp.Limits => Interp.Outcome
	run! = |host, program, library, limits| {
		session = Interp.start!(host, program, library, limits)
		Interp.outcome_of(Interp.drain!(host, session, Events.callback_limit).machine)
	}

	outcome_of : Interp.Machine -> Interp.Outcome
	outcome_of = |machine| {
		steps: machine.steps,
		cells: machine.cells.len(),
		scopes: machine.live_scopes,
		status: match machine.status {
			Running => Running
			Faulted(why) => Faulted(why)
			Thrown(boxed) => {
				{ value, site } = Box.unbox(boxed)
				ValueRules.uncaught_ending(machine.cells, value, site)
			}
		},
	}

	fresh : Ast.Library, Interp.Limits -> Interp.Machine
	fresh = |library, limits| Interp.with_globals(
		{
			cells: [],
			scopes: [],
			live_scopes: 0,
			scope: 0,
			steps: 0,
			step_limit: limits.steps,
			effects: 0,
			effect_limit: limits.effects,
			budgeted: "the program",
			turtle: Canvas.turtle_start,
			depth: 0,
			status: Running,
			events: Events.at_start,
		},
		library,
	)

	## A program that may go on after its end, its queue of events waiting.
	Session : { machine : Interp.Machine }

	## A program run to its end, with its own scope kept alive after, as a
	## page keeps a script's: a later callback sees the variables the program
	## declared, and the writes the last callback made. On the canvas
	## library, a program that declares `frame` has its first frame queued,
	## at time 0, and each frame queues the next.
	start! : Canvas.Host, Ast.Program, Ast.Library, Interp.Limits => Interp.Session
	start! = |host, program, library, limits| {
		names = match program.scoping {
			Scoped(scope_names) => scope_names
			Unscoped => crash "Interp.start!: Parser.program_of gives a program its own scope"
		}
		entered = Interp.with_scope_entered(
			Interp.fresh(library, limits),
			Within(0),
			names.len(),
		)
		id = entered.scope
		{ machine, flow: _ } = Interp.execute_list!(
			host,
			Interp.with_functions_hoisted(entered, program.statements),
			program.statements,
		)
		frame = match library {
			Core => NoFrame
			Canvas => match names.find_first_index(|name| name == "frame") {
				Ok(index) if Interp.is_running(machine) => match Interp.variable_at(
					machine.scopes,
					id,
					index,
				).value {
					Reference(cell) => match Heap.cell_at(machine.cells, cell) {
						Fun(closure) => Frame(closure)
						_ => NoFrame
					}
					_ => NoFrame
				}
				_ => NoFrame
			}
		}
		match frame {
			Frame(closure) => {
				machine: {
					..machine,
					events: Events.with_event(
						machine.events,
						{
							due: Events.frame_due(0),
							site: closure.fun.unbox().at,
							happening: Framed(closure, 0),
						},
					),
				},
			}
			NoFrame => { machine: machine }
		}
	}

	## The session with its clock moved to `seconds`, every event due by
	## then run in its order: the clicks the page queued, the timers, and the
	## frame of that time. They share one budget, `limits`, afresh. A session
	## that has stopped is answered as it is.
	##
	## The page and the recording host call it with `seconds` the frame's number over
	## `Canvas.frames_per_second`, computed as `Events.frame_time` computes it,
	## so a frame's event is due exactly at its tick.
	tick! : Canvas.Host, Interp.Session, F64, Interp.Limits => Interp.Session
	tick! = |host, session, seconds, limits| {
		{ machine: before } = session
		if !Interp.is_running(before) {
			{ machine: before }
		} else {
			until = seconds * 1000.0
			var $machine = {
				..before,
				steps: 0,
				step_limit: limits.steps,
				effects: 0,
				effect_limit: limits.effects,
			}
			var $going = True
			while $going {
				match Events.earliest($machine.events.pending_events, until) {
					At(index) if Interp.is_running($machine) => {
						{ machine: off, event } = Interp.event_taken($machine, index)
						$machine = Interp.run_event!(host, off, event)
					}
					_ => {
						$going = False
					}
				}
			}
			{ machine: { ..$machine, events: Events.with_clock_at($machine.events, until) } }
		}
	}

	## The session after every event left in its queue, earliest first, the
	## clock moved to each in turn, until none is left, the program stops, or
	## `most` callbacks have run with more to come (a fault that says so). The
	## command line's run, after the program.
	drain! : Canvas.Host, Interp.Session, U64 => Interp.Session
	drain! = |host, session, most| {
		var $machine = session.machine
		var $ran = 0
		var $going = True
		while $going {
			match Events.earliest($machine.events.pending_events, 1.0 / 0.0) {
				At(index) if Interp.is_running($machine) => {
					if $ran >= most {
						$machine = Interp.with_fault(
							$machine,
							"the program ran past its budget of ${most.to_str()} timer callbacks",
						)
						$going = False
					} else {
						{ machine: off, event } = Interp.event_taken($machine, index)
						$machine = Interp.run_event!(host, off, event)
						$ran = $ran + 1
					}
				}
				_ => {
					$going = False
				}
			}
		}
		{ machine: $machine }
	}

	## The session with a click queued for its `onClick` handler, due now, so
	## the next `tick!` runs it. A session with no handler, or stopped, is
	## answered as it is.
	with_click : Interp.Session, F64, F64 -> Interp.Session
	with_click = |session, x, y| {
		{ machine } = session
		match machine.events.on_click {
			Handler({ handler: _, site }) if Interp.is_running(machine) => {
				due = machine.events.clock
				{
					machine: {
						..machine,
						events: Events.with_event(
							machine.events,
							{
								due: due,
								site: site,
								happening: Clicked(x, y),
							},
						),
					},
				}
			}
			_ => { machine: machine }
		}
	}

	## Whether the session has more to do: an event queued, or a click handler
	## that a click would call. A host ticks a session while it waits.
	waits : Interp.Session -> Bool
	waits = |session|
		Interp.is_running(session.machine)
			and (!session.machine.events.pending_events.is_empty()
				or session.machine.events.on_click != NoHandler)

	# ---- the queue -------------------------------------------------------------

	# The event at `index` taken off the queue, the clock moved to its time.
	event_taken : Interp.Machine, U64 -> { machine : Interp.Machine, event : Events.Event }
	event_taken = |machine, index| {
		event = machine.events.pending_events.get(index) ?? crash "Interp.event_taken: Events.earliest names an event the queue has"
		{
			machine: { ..machine, events: Events.with_event_taken(machine.events, index, event.due) },
			event: event,
		}
	}

	# The machine after one event's callback: a timer's, again later when it
	# is an interval that wasn't cleared; a frame's, the next frame queued; a
	# click's, handed to the handler.
	run_event! : Canvas.Host, Interp.Machine, Events.Event => Interp.Machine
	run_event! = |host, machine, event|
		match event.happening {
			Timed({ timer, callback, every }) => {
				firing = {
					..machine,
					budgeted: "a timer's callback",
					events: Events.with_firing(machine.events, Firing(timer)),
				}
				{ machine: after, value: _ } = Interp.call!(host, firing, callback, [], event.site)
				again = after.events.firing == Firing(timer)
				idle = { ..after, events: Events.with_firing(after.events, Idle) }
				match every {
					Every(period) if again => {
						..idle,
						events: Events.with_event(
							idle.events,
							{
								due: event.due + period,
								site: event.site,
								happening: Timed({
									timer: timer,
									callback: callback,
									every: every,
								}),
							},
						),
					}
					_ => idle
				}
			}
			Framed(closure, number) => {
				framing = { ..machine, budgeted: "frame(t)" }
				{ machine: after, value: _ } = Interp.call_closure!(
					host,
					framing,
					closure,
					[Number(Events.frame_time(number))],
					event.site,
				)
				{
					..after,
					events: Events.with_event(
						after.events,
						{
							due: Events.frame_due(number + 1),
							site: event.site,
							happening: Framed(closure, number + 1),
						},
					),
				}
			}
			Clicked(x, y) => match machine.events.on_click {
				Handler({ handler, site }) => {
					clicking = { ..machine, budgeted: "the click handler" }
					{ machine: after, value: _ } = Interp.call!(
						host,
						clicking,
						handler,
						[Number(x), Number(y)],
						site,
					)
					after
				}
				NoHandler => machine
			}
		}

	# The machine after one effect handed to the host, or stopped when the
	# effect would pass its budget.
	emit! : Canvas.Host, Interp.Machine, Canvas.Effect => Interp.Got
	emit! = |host, machine, effect|
		if machine.effects >= machine.effect_limit {
			Interp.fault_got(
				machine,
				"${machine.budgeted} ran past its budget of ${machine.effect_limit.to_str()} effects",
			)
		} else {
			emit_now! = host.emit!
			emit_now!(effect)
			{ machine: { ..machine, effects: machine.effects + 1 }, value: Undefined }
		}

	# The machine with the outermost scope holding the builtins.
	with_globals : Interp.Machine, Ast.Library -> Interp.Machine
	with_globals = |machine, library| {
		{ cells, values } = ValueRules.globals(machine.cells, library)
		globals = values.map(|value| { value: value, state: Fixed })
		{ ..machine, cells: cells, scopes: [{ variables: globals, parent: Outermost }], live_scopes: 1, scope: 0 }
	}

	alloc : Interp.Machine, Heap.Cell -> Interp.Got
	alloc = |machine, cell| {
		id = machine.cells.len()
		{ machine: { ..machine, cells: machine.cells.append(cell) }, value: Reference(id) }
	}

	is_running : Interp.Machine -> Bool
	is_running = |machine|
		match machine.status {
			Running => True
			_ => False
		}

	# The machine stopped with `why`, unless it had already stopped.
	with_fault : Interp.Machine, Str -> Interp.Machine
	with_fault = |machine, why|
		match machine.status {
			Running => { ..machine, status: Faulted(why) }
			_ => machine
		}

	# The machine unwinding with `value` thrown at `site`, unless it had
	# already stopped.
	with_thrown : Interp.Machine, Heap.Value, Ast.Where -> Interp.Machine
	with_thrown = |machine, value, site|
		match machine.status {
			Running => { ..machine, status: Thrown(Box.box({ value, site })) }
			_ => machine
		}

	fault_got : Interp.Machine, Str -> Interp.Got
	fault_got = |machine, why| { machine: Interp.with_fault(machine, why), value: Undefined }

	# The machine unwinding with one of JavaScript's own errors, `name`,
	# saying `message` as node words it, thrown at `site`: a program may
	# catch it as it catches its own.
	with_error : Interp.Machine, Heap.ErrorName, Str, Ast.Where -> Interp.Machine
	with_error = |machine, name, message, site|
		if !Interp.is_running(machine) {
			machine
		} else {
			{ machine: made, value: error } = Interp.alloc(machine, Failure(name, message))
			Interp.with_thrown(made, error, site)
		}

	error_got : Interp.Machine, Heap.ErrorName, Str, Ast.Where -> Interp.Got
	error_got = |machine, name, message, site| {
		machine: Interp.with_error(machine, name, message, site),
		value: Undefined,
	}

	# ---- the value rules, lent the cells ------------------------------------

	## The machine with its cells lent to one of `ValueRules`' rules: the rule's
	## machine holds them and the status, and the rest of the walker's waits
	## without them, so the cells have one owner while the rule writes them.
	Lent : { rules : ValueRules.Machine, rest : Interp.Machine }

	lent : Interp.Machine -> Interp.Lent
	lent = |machine| {
		cells = machine.cells
		{ rules: { cells: cells, status: machine.status }, rest: { ..machine, cells: [] } }
	}

	# The walker's machine after a rule: the rule's cells and status put back.
	with_rules : Interp.Machine, ValueRules.Machine -> Interp.Machine
	with_rules = |rest, { cells, status }| { ..rest, cells: cells, status: status }

	got_back : Interp.Machine, ValueRules.Got -> Interp.Got
	got_back = |rest, { machine: rules, value }| { machine: Interp.with_rules(rest, rules), value: value }

	property : Interp.Machine, Heap.Value, Str, Ast.Where -> Interp.Got
	property = |machine, holder, key, site| {
		{ rules, rest } = Interp.lent(machine)
		Interp.got_back(rest, ValueRules.property(rules, holder, key, site))
	}

	indexed_value : Interp.Machine, Heap.Value, Heap.Value, Ast.Where -> Interp.Got
	indexed_value = |machine, holder, key, site| {
		{ rules, rest } = Interp.lent(machine)
		Interp.got_back(rest, ValueRules.indexed_value(rules, holder, key, site))
	}

	with_stored : Interp.Machine, Heap.Value, Heap.Value, Heap.Value, Ast.Where -> Interp.Got
	with_stored = |machine, holder, key, value, site| {
		{ rules, rest } = Interp.lent(machine)
		Interp.got_back(rest, ValueRules.with_stored(rules, holder, key, value, site))
	}

	binary : Interp.Machine, Ast.BinaryOperator, Heap.Value, Heap.Value, Ast.Where -> Interp.Got
	binary = |machine, operator, left, right, site| {
		{ rules, rest } = Interp.lent(machine)
		Interp.got_back(rest, ValueRules.binary(rules, operator, left, right, site))
	}

	with_not_iterable : Interp.Machine, Heap.Value, ValueRules.Origin, Ast.Where -> Interp.Machine
	with_not_iterable = |machine, subject, origin, site| {
		{ rules, rest } = Interp.lent(machine)
		Interp.with_rules(rest, ValueRules.with_not_iterable(rules, subject, origin, site))
	}

	unary : Interp.Machine, Ast.UnaryOperator, Heap.Value, Ast.Where -> Interp.Got
	unary = |machine, operator, subject, site| {
		{ rules, rest } = Interp.lent(machine)
		Interp.got_back(rest, ValueRules.unary(rules, operator, subject, site))
	}

	constructed : Interp.Machine, Heap.Value, Ast.Expression, List(Heap.Value), Ast.Where -> Interp.Got
	constructed = |machine, maker, callee, arguments, site| {
		{ rules, rest } = Interp.lent(machine)
		Interp.got_back(rest, ValueRules.constructed(rules, maker, callee, arguments, site))
	}

	missing_name_got : Interp.Machine, Str, Ast.Where -> Interp.Got
	missing_name_got = |machine, name, site| {
		{ rules, rest } = Interp.lent(machine)
		Interp.got_back(rest, ValueRules.missing_name_got(rules, name, site))
	}

	text_method : Interp.Machine, Str, Str, List(Heap.Value), Ast.Where -> Interp.Got
	text_method = |machine, text, name, arguments, site| {
		{ rules, rest } = Interp.lent(machine)
		Interp.got_back(rest, ValueRules.text_method(rules, text, name, arguments, site))
	}

	# The value rules' builtins, for those that make no effect and call
	# nothing back (`call_native!`'s other arms).
	native_called : Interp.Machine, Heap.Native, List(Heap.Value), Ast.Where -> Interp.Got
	native_called = |machine, native, arguments, site| {
		{ rules, rest } = Interp.lent(machine)
		Interp.got_back(rest, ValueRules.native_called(rules, native, arguments, site))
	}

	# The value rules' array methods, for those that call nothing back
	# (`array_method!`'s other arms).
	array_method : Interp.Machine, U64, Str, List(Heap.Value), Ast.Where -> Interp.Got
	array_method = |machine, id, name, arguments, site| {
		{ rules, rest } = Interp.lent(machine)
		Interp.got_back(rest, ValueRules.array_method(rules, id, name, arguments, site))
	}

	# The value rules' Map and Set methods, for all but `forEach`
	# (`collection_method!`'s other arm).
	collection_method : Interp.Machine, { id : U64, collection : ValueRules.Collection }, Str, List(Heap.Value), Ast.Where -> Interp.Got
	collection_method = |machine, place, name, arguments, site| {
		{ rules, rest } = Interp.lent(machine)
		Interp.got_back(rest, ValueRules.collection_method(rules, place, name, arguments, site))
	}

	Iterated : { machine : Interp.Machine, values : Try(List(Heap.Value), [NotIterable]) }

	iterated : Interp.Machine, Heap.Value -> Interp.Iterated
	iterated = |machine, subject| {
		{ rules, rest } = Interp.lent(machine)
		{ machine: after, values } = ValueRules.iterated(rules, subject)
		{ machine: Interp.with_rules(rest, after), values: values }
	}

	array_from_values : Interp.Machine, Heap.Value -> { machine : Interp.Machine, listed : Try(List(Heap.Value), [Unsupported(Str)]) }
	array_from_values = |machine, source| {
		{ rules, rest } = Interp.lent(machine)
		{ machine: after, listed } = ValueRules.array_from_values(rules, source)
		{ machine: Interp.with_rules(rest, after), listed: listed }
	}

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

	execute_block! : Canvas.Host, Interp.Machine, Ast.Block => Interp.Done
	execute_block! = |host, machine, block|
		match block.scoping {
			Unscoped => Interp.execute_list!(host, machine, block.statements)
			Scoped(names) => {
				outer = machine.scope
				inner = Interp.with_functions_hoisted(
					Interp.with_scope_entered(machine, Within(outer), names.len()),
					block.statements,
				)
				id = inner.scope
				{ machine: after, flow } = Interp.execute_list!(host, inner, block.statements)
				{ machine: Interp.out_of_scope(after, id, outer, block.capture), flow: flow }
			}
		}

	execute_list! : Canvas.Host, Interp.Machine, List(Ast.Statement) => Interp.Done
	execute_list! = |host, machine, statements| {
		var $s = machine
		var $flow = Normal
		for statement in statements {
			if $flow == Normal and Interp.is_running($s) {
				{ machine: after, flow } = Interp.execute!(host, Interp.one_step_on($s), statement)
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
				"${machine.budgeted} ran past its budget of ${machine.step_limit.to_str()} steps",
			)
		} else {
			{ ..machine, steps: machine.steps + 1 }
		}

	execute! : Canvas.Host, Interp.Machine, Ast.Statement => Interp.Done
	execute! = |host, machine, statement|
		match statement {
			Expression(expression) => {
				{ machine: after, value: _ } = Interp.evaluate!(host, machine, expression)
				Interp.normal(after)
			}
			Declare(binding, declarations) => {
				state = Interp.state_of(binding)
				var $s = machine
				for declarator in declarations {
					if Interp.is_running($s) {
						{ machine: made, value } = match declarator.init {
							Initialized(expression) => Interp.evaluate!(host, $s, expression)
							Uninitialized => { machine: $s, value: Undefined }
						}
						$s = match (declarator.pattern, declarator.init) {
							(Leaf(ToName(_, slot, _)), _) => Interp.declare(made, slot, value, state)
							(pattern, Initialized(expression)) => Interp.with_pattern_bound!(
								host,
								made,
								pattern,
								{
									value: value,
									how: Declaring(state),
									origin: Written(expression),
									at: declarator.at,
								},
							)
							(_, Uninitialized) => crash "Interp.execute!: Parser.declarators gives every pattern a value"
						}
					}
				}
				Interp.normal($s)
			}
			FunctionDeclaration(_, _) => Interp.normal(machine)
			If(test, yes, no) => {
				{ machine: tested, value } = Interp.evaluate!(host, machine, test)
				if !Interp.is_running(tested) {
					Interp.normal(tested)
				} else if ValueRules.is_truthy(value) {
					Interp.execute!(host, tested, yes)
				} else {
					Interp.execute!(host, tested, no)
				}
			}
			While(loop) => Interp.execute_while!(host, machine, loop)
			For(loop) => Interp.execute_for!(host, machine, loop)
			ForOf(loop) => Interp.execute_iteration!(host, machine, loop)
			BlockStatement(block) => Interp.execute_block!(host, machine, block)
			Return(expression) => {
				{ machine: after, value } = Interp.evaluate!(host, machine, expression)
				{ machine: after, flow: Returned(value) }
			}
			Throw(expression, site) => {
				{ machine: after, value } = Interp.evaluate!(host, machine, expression)
				Interp.normal(Interp.with_thrown(after, value, site))
			}
			Try(tried) => Interp.execute_try!(host, machine, tried)
			Switch(switch) => Interp.execute_switch!(host, machine, switch)
			Break(label) => { machine: machine, flow: Broke(label) }
			Continue(label) => { machine: machine, flow: Continued(label) }
			Labelled(label, body) => {
				{ machine: after, flow } = Interp.execute!(host, machine, body)
				left = if flow == Broke(Named(label)) {
					Normal
				} else {
					flow
				}
				{ machine: after, flow: left }
			}
			Empty => Interp.normal(machine)
		}

	# A `try`: its block; then, when the block threw, the `catch` with the
	# value thrown, the machine running on; then the `finally`, whatever came
	# before. A `finally` that ends normally leaves the try's own ending, a
	# throw still unwinding or a `return` still returning; one that throws,
	# returns or breaks puts its own in its place. A fault is never caught.
	execute_try! : Canvas.Host, Interp.Machine, Ast.TryStatement => Interp.Done
	execute_try! = |host, machine, { block, handler, finalizer }| {
		{ machine: tried, flow } = Interp.execute_block!(host, machine, block)
		{ machine: handled, flow: handled_flow } = match (tried.status, handler) {
			(Thrown(boxed), Caught(clause)) => Interp.execute_catch!(
				host,
				{ ..tried, status: Running },
				clause,
				Box.unbox(boxed).value,
			)
			_ => { machine: tried, flow: flow }
		}
		match (finalizer, handled.status) {
			(NoFinally, _) => { machine: handled, flow: handled_flow }
			(Finally(_), Faulted(_)) => { machine: handled, flow: handled_flow }
			(Finally(final_block), pending) => {
				{ machine: after, flow: final_flow } = Interp.execute_block!(
					host,
					{ ..handled, status: Running },
					final_block,
				)
				if !Interp.is_running(after) or final_flow != Normal {
					{ machine: after, flow: final_flow }
				} else {
					{ machine: { ..after, status: pending }, flow: handled_flow }
				}
			}
		}
	}

	# A `switch`: the value compared, by `===`, with each case's in order in
	# the switch's own scope, and the statements run from the first case that
	# matches (or the `default`, where none does) to the end, falling through
	# the cases after it, until a `break` leaves.
	execute_switch! : Canvas.Host, Interp.Machine, Ast.SwitchStatement => Interp.Done
	execute_switch! = |host, machine, switch| {
		{ machine: compared, value: subject } = Interp.evaluate!(host, machine, switch.discriminant)
		outer = compared.scope
		entered = match switch.scoping {
			Scoped(names) => Interp.with_functions_hoisted(
				Interp.with_scope_entered(compared, Within(outer), names.len()),
				switch.cases.join_map(|each| each.statements),
			)
			Unscoped => compared
		}
		id = entered.scope
		var $s = entered
		var $start = NoCase
		var $default = NoCase
		var $i = 0
		for each in switch.cases {
			if $start == NoCase and Interp.is_running($s) {
				match each.test {
					Matches(expression) => {
						{ machine: tested, value } = Interp.evaluate!(host, $s, expression)
						$s = tested
						if ValueRules.is_strictly_equal(subject, value) {
							$start = At($i)
						}
					}
					Otherwise => {
						$default = At($i)
					}
				}
			}
			$i = $i + 1
		}
		first = match $start {
			At(index) => At(index)
			NoCase => $default
		}
		var $flow = Normal
		match first {
			At(from) => {
				var $k = 0
				for each in switch.cases {
					if $k >= from and $flow == Normal and Interp.is_running($s) {
						{ machine: after, flow } = Interp.execute_list!(host, $s, each.statements)
						$s = after
						$flow = flow
					}
					$k = $k + 1
				}
			}
			NoCase => {}
		}
		left = match $flow {
			Broke(Unlabelled) => Normal
			other => other
		}
		done = match switch.scoping {
			Scoped(_) => Interp.out_of_scope($s, id, outer, switch.capture)
			Unscoped => $s
		}
		{ machine: done, flow: left }
	}

	execute_catch! : Canvas.Host, Interp.Machine, Ast.CatchClause, Heap.Value => Interp.Done
	execute_catch! = |host, machine, clause, thrown|
		match clause.parameter {
			Unbound => Interp.execute_block!(host, machine, clause.body)
			Bound(pattern) => {
				outer = machine.scope
				entered = Interp.with_scope_entered(machine, Within(outer), clause.names.len())
				id = entered.scope
				bound = Interp.with_pattern_bound!(
					host,
					entered,
					pattern,
					{
						value: thrown,
						how: Declaring(Mutable),
						origin: Nested,
						at: clause.at,
					},
				)
				{ machine: after, flow } = if Interp.is_running(bound) {
					Interp.execute_block!(host, bound, clause.body)
				} else {
					Interp.normal(bound)
				}
				{ machine: Interp.out_of_scope(after, id, outer, clause.capture), flow: flow }
			}
		}

	# How a loop goes on after its body: on, or out with the flow the loop
	# itself answers. A labelled `break` or `continue` is the loop's own when
	# it names one of the loop's labels, and passes out of it otherwise.
	body_outcome : Interp.Flow, List(U64) -> [GoOn, Leave(Interp.Flow)]
	body_outcome = |flow, labels| match flow {
		Normal => GoOn
		Continued(Unlabelled) => GoOn
		Broke(Unlabelled) => Leave(Normal)
		Continued(Named(label)) if labels.contains(label) => GoOn
		Broke(Named(label)) if labels.contains(label) => Leave(Normal)
		other => Leave(other)
	}

	# A `while`, or a `do ... while`, whose first pass runs before its test.
	execute_while! : Canvas.Host, Interp.Machine, Ast.WhileLoop => Interp.Done
	execute_while! = |host, machine, { test, body, order, labels }| {
		var $s = machine
		var $flow = Normal
		var $going = True
		var $untested = order == TestAfter
		while $going {
			{ machine: tested, value } = if $untested {
				{ machine: Interp.one_step_on($s), value: Boolean(True) }
			} else {
				Interp.evaluate!(host, Interp.one_step_on($s), test)
			}
			$untested = False
			if !Interp.is_running(tested) or !ValueRules.is_truthy(value) {
				$s = tested
				$going = False
			} else {
				{ machine: after, flow } = Interp.execute!(host, tested, body)
				$s = after
				match Interp.body_outcome(flow, labels) {
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

	execute_for! : Canvas.Host, Interp.Machine, Ast.ForLoop => Interp.Done
	execute_for! = |host, machine, loop| {
		outer = machine.scope
		start = Interp.with_scope_entered(machine, Within(outer), loop.names.len())
		{ machine: begun, flow: _ } = Interp.execute!(host, start, loop.init)
		var $s = begun
		var $flow = Normal
		var $going = Interp.is_running($s)
		while $going {
			{ machine: tested, value } = match loop.test {
				Tested(expression) => Interp.evaluate!(host, Interp.one_step_on($s), expression)
				Always => { machine: Interp.one_step_on($s), value: Boolean(True) }
			}
			if !Interp.is_running(tested) or !ValueRules.is_truthy(value) {
				$s = tested
				$going = False
			} else {
				{ machine: after, flow } = Interp.execute!(host, tested, loop.body)
				match Interp.body_outcome(flow, loop.labels) {
					GoOn => {
						# **EACH PASS HAS ITS OWN `let`**, as JavaScript gives a
						# closure made in the body the pass's own variable. The
						# copy is made only where the body holds a closure.
						next_pass = match loop.capture {
							Captures => Interp.copied_scope(after)
							CapturesNothing => after
						}
						$s = match loop.update {
							Updated(expression) => Interp.machine_after!(
								host,
								next_pass,
								expression,
							)
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

	execute_iteration! : Canvas.Host, Interp.Machine, Ast.ForOfLoop => Interp.Done
	execute_iteration! = |host, machine, loop| {
		{ machine: got, value: iterable } = Interp.evaluate!(host, machine, loop.iterable)
		state = Interp.state_of(loop.binding)
		match iterable {
			Reference(id) => match ValueRules.kind_of(got.cells, id) {
				ArrayKind(_) => Interp.execute_for_of_array!(host, got, loop, id, state)
				MapKind => {
					{ machine: after, flow, next: _ } = Interp.execute_for_of_steps!(
						host,
						got,
						loop,
						{ source: id, view: Entries, next: 0 },
						state,
					)
					{ machine: after, flow: flow }
				}
				SetKind => {
					{ machine: after, flow, next: _ } = Interp.execute_for_of_steps!(
						host,
						got,
						loop,
						{ source: id, view: Values, next: 0 },
						state,
					)
					{ machine: after, flow: flow }
				}
				IteratorKind => {
					walk = ValueRules.iteration_of(got.cells, id)
					{ machine: after, flow, next } = Interp.execute_for_of_steps!(host, got, loop, walk, state)
					{ machine: { ..after, cells: Heap.with_iterator_at(after.cells, id, next) }, flow: flow }
				}
				_ => Interp.normal(Interp.with_not_iterable(got, iterable, Written(loop.iterable), loop.at))
			}
			Text(text) => Interp.execute_for_of_text!(host, got, loop, text, state)
			_ => Interp.normal(Interp.with_not_iterable(got, iterable, Written(loop.iterable), loop.at))
		}
	}

	## A walk's machine and flow, and the place of the entry after the last it
	## gave, for an iterator to go on from.
	Walking : { machine : Interp.Machine, flow : Interp.Flow, next : U64 }

	# A `for ... of` over a Map's, a Set's or an iterator's entries, each read
	# from the heap as the loop comes to it, so an entry the body deletes is
	# skipped and one it adds is met.
	execute_for_of_steps! : Canvas.Host, Interp.Machine, Ast.ForOfLoop, ValueRules.EntryWalk, Interp.VariableState => Interp.Walking
	execute_for_of_steps! = |host, machine, loop, { source, view, next }, state| {
		var $s = machine
		var $flow = Normal
		var $i = next
		var $going = Interp.is_running(machine)
		while $going {
			step = ValueRules.step_at($s.cells, source, view, $i)
			$i = $i + 1
			passing = match step {
				Yield(value) => Passing(value)
				YieldPair(key, value) => {
					{ machine: made, value: pair } = Interp.alloc($s, Array([key, value]))
					$s = made
					Passing(pair)
				}
				Skip => Passless
				Ended => {
					$going = False
					Passless
				}
			}
			match passing {
				Passing(subject) => {
					{ machine: after, flow } = Interp.execute_for_of_pass!(
						host,
						Interp.one_step_on($s),
						loop,
						{ value: subject, state: state },
					)
					$s = after
					match Interp.body_outcome(flow, loop.labels) {
						GoOn => {
							$going = Interp.is_running($s)
						}
						Leave(leaving) => {
							$flow = leaving
							$going = False
						}
					}
				}
				Passless => {}
			}
		}
		{ machine: $s, flow: $flow, next: $i }
	}

	state_of : Ast.Binding -> Interp.VariableState
	state_of = |binding| match binding {
		Let => Mutable
		Const => Fixed
	}

	execute_for_of_array! : Canvas.Host, Interp.Machine, Ast.ForOfLoop, U64, Interp.VariableState => Interp.Done
	execute_for_of_array! = |host, machine, loop, id, state| {
		var $s = machine
		var $flow = Normal
		var $i = 0
		var $going = Interp.is_running(machine)
		while $going {
			if $i >= ValueRules.item_count($s.cells, id) {
				$going = False
			} else {
				subject = ValueRules.item_at($s.cells, id, $i)
				{ machine: after, flow } = Interp.execute_for_of_pass!(
					host,
					Interp.one_step_on($s),
					loop,
					{ value: subject, state: state },
				)
				$s = after
				$i = $i + 1
				match Interp.body_outcome(flow, loop.labels) {
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

	execute_for_of_text! : Canvas.Host, Interp.Machine, Ast.ForOfLoop, Str, Interp.VariableState => Interp.Done
	execute_for_of_text! = |host, machine, loop, text, state| {
		var $s = machine
		var $flow = Normal
		var $going = Interp.is_running(machine)
		for character in ValueRules.characters(text) {
			if $going {
				{ machine: after, flow } = Interp.execute_for_of_pass!(
					host,
					Interp.one_step_on($s),
					loop,
					{ value: Text(character), state: state },
				)
				$s = after
				match Interp.body_outcome(flow, loop.labels) {
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

	# One pass of a `for ... of`, its variable `binding`.
	execute_for_of_pass! : Canvas.Host, Interp.Machine, Ast.ForOfLoop, Interp.Variable => Interp.Done
	execute_for_of_pass! = |host, machine, loop, binding| {
		outer = machine.scope
		inner = match loop.pattern {
			Leaf(_) => Interp.with_scope_added(machine, { variables: [binding], parent: Within(outer) })
			pattern => Interp.with_pattern_bound!(
				host,
				Interp.with_scope_entered(machine, Within(outer), loop.names.len()),
				pattern,
				{
					value: binding.value,
					how: Declaring(binding.state),
					origin: Nested,
					at: loop.at,
				},
			)
		}
		id = inner.scope
		{ machine: after, flow } = if Interp.is_running(inner) {
			Interp.execute!(host, inner, loop.body)
		} else {
			Interp.normal(inner)
		}
		{ machine: Interp.out_of_scope(after, id, outer, loop.capture), flow: flow }
	}

	# ---- values ----------------------------------------------------------------

	# ---- expressions -----------------------------------------------------------

	evaluate! : Canvas.Host, Interp.Machine, Ast.Expression => Interp.Got
	evaluate! = |host, machine, tree|
		match tree {
			Number(number) => { machine: machine, value: Number(number) }
			Text(text) => { machine: machine, value: Text(text) }
			Boolean(truth) => { machine: machine, value: Boolean(truth) }
			Null => { machine: machine, value: Null }
			Undefined => { machine: machine, value: Undefined }
			Template(texts, parts) => Interp.evaluate_template!(host, machine, texts, parts)
			Name(name, slot, site) => Interp.evaluate_name(machine, name, slot, site)
			ArrayLit(items) => {
				{ machine: after, values } = Interp.evaluate_elements!(host, machine, items)
				Interp.alloc(after, Array(values))
			}
			ObjectLit(parts) => {
				var $s = machine
				var $made = []
				for part in parts {
					match part {
						Field(written) => {
							{ machine: after, value } = Interp.evaluate!(host, $s, written.value)
							$s = after
							$made = Heap.properties_with($made, written.key, value)
						}
						Spread(expression, site) => {
							{ machine: after, value } = Interp.evaluate!(host, $s, expression)
							match ValueRules.spread_properties(after.cells, value) {
								Ok(spread) => {
									$s = after
									for p in spread {
										$made = Heap.properties_with($made, p.key, p.value)
									}
								}
								Err(Unsupported(why)) => {
									$s = Interp.with_fault(after, "${why}${ValueRules.line_note(site)}")
								}
							}
						}
					}
				}
				Interp.alloc($s, Object($made))
			}
			Unary(operator, expression, site) => {
				{ machine: after, value } = Interp.evaluate!(host, machine, expression)
				Interp.unary(after, operator, value, site)
			}
			Binary(operator, left, right, site) => {
				{ machine: first, value: left_value } = Interp.evaluate!(host, machine, left)
				{ machine: second, value: right_value } = Interp.evaluate!(host, first, right)
				Interp.binary(second, operator, left_value, right_value, site)
			}
			Logical(operator, left, right) => {
				{ machine: first, value: left_value } = Interp.evaluate!(host, machine, left)
				if Interp.is_decided(operator, left_value) {
					{ machine: first, value: left_value }
				} else {
					Interp.evaluate!(host, first, right)
				}
			}
			Conditional(test, yes, no) => {
				{ machine: tested, value } = Interp.evaluate!(host, machine, test)
				if ValueRules.is_truthy(value) {
					Interp.evaluate!(host, tested, yes)
				} else {
					Interp.evaluate!(host, tested, no)
				}
			}
			Assign(target, operator, expression, site) => Interp.evaluate_assign!(
				host,
				machine,
				{
					target: target,
					operator: operator,
					value: expression,
					at: site,
				},
			)
			Update(target, step, fixity, site) => Interp.evaluate_update!(
				host,
				machine,
				target,
				step,
				fixity,
				site,
			)
			Member(object, key, site) => {
				{ machine: after, value: holder } = Interp.evaluate!(host, machine, object)
				Interp.property(after, holder, key, site)
			}
			Index(object, key, site) => {
				{ machine: first, value: holder } = Interp.evaluate!(host, machine, object)
				{ machine: second, value: key_value } = Interp.evaluate!(host, first, key)
				Interp.indexed_value(second, holder, key_value, site)
			}
			Call(callee, arguments, site) => Interp.evaluate_call!(
				host,
				machine,
				callee,
				arguments,
				site,
			)
			Function(definition) => Interp.alloc(
				machine,
				Fun({ fun: definition, scope: machine.scope }),
			)
			Chain(chain) => {
				{ machine: after, link } = Interp.link!(host, machine, chain)
				match link {
					Reached(value) => { machine: after, value: value }
					Short => { machine: after, value: Undefined }
				}
			}
			OptionalMember(_, _, _) | OptionalIndex(_, _, _) | OptionalCall(_, _, _) => crash "Interp.evaluate!: Parser.call_or_member puts an optional link inside a Chain"
			New(callee, arguments, site) => {
				{ machine: first, value: maker } = Interp.evaluate!(host, machine, callee)
				{ machine: second, values } = Interp.evaluate_elements!(host, first, arguments)
				Interp.constructed(second, maker, callee, values, site)
			}
			Destructure(pattern, expression, site) => {
				{ machine: after, value } = Interp.evaluate!(host, machine, expression)
				bound = Interp.with_pattern_bound!(
					host,
					after,
					pattern,
					{
						value: value,
						how: Assigning,
						origin: Written(expression),
						at: site,
					},
				)
				{ machine: bound, value: value }
			}
		}

	# Whether a logical operator settles on its left side, so the right side
	# isn't evaluated.
	is_decided : Ast.LogicalOperator, Heap.Value -> Bool
	is_decided = |operator, left|
		match operator {
			And => !ValueRules.is_truthy(left)
			Or => ValueRules.is_truthy(left)
			Nullish => left != Null and left != Undefined
		}

	# ---- optional chains -------------------------------------------------------

	## A link of a chain reached and its value, or a link that found `null` or
	## `undefined` where an optional link reads or calls, which ends the chain.
	Linked : { machine : Interp.Machine, link : [Reached(Heap.Value), Short] }

	reached : Interp.Got -> Interp.Linked
	reached = |{ machine, value }| { machine: machine, link: Reached(value) }

	# One link of a chain: its object's link first, then what it reads or
	# calls, the chain ending where an optional link finds nothing.
	link! : Canvas.Host, Interp.Machine, Ast.Expression => Interp.Linked
	link! = |host, machine, tree|
		match tree {
			Member(object, key, site) | OptionalMember(object, key, site) => {
				{ machine: after, link } = Interp.link!(host, machine, object)
				match link {
					Reached(holder) if Interp.is_optional_link(tree) and ValueRules.is_nullish(holder) => {
						machine: after,
						link: Short,
					}
					Reached(holder) => Interp.reached(Interp.property(after, holder, key, site))
					Short => { machine: after, link: Short }
				}
			}
			Index(object, key, site) | OptionalIndex(object, key, site) => {
				{ machine: after, link } = Interp.link!(host, machine, object)
				match link {
					Reached(holder) if Interp.is_optional_link(tree) and ValueRules.is_nullish(holder) => {
						machine: after,
						link: Short,
					}
					Reached(holder) => {
						{ machine: keyed, value: key_value } = Interp.evaluate!(host, after, key)
						Interp.reached(Interp.indexed_value(keyed, holder, key_value, site))
					}
					Short => { machine: after, link: Short }
				}
			}
			Call(callee, arguments, site) | OptionalCall(callee, arguments, site) => Interp.call_link!(
				host,
				machine,
				{
					callee: callee,
					arguments: arguments,
					optional: Interp.is_optional_link(tree),
					at: site,
				},
			)
			_ => Interp.reached(Interp.evaluate!(host, machine, tree))
		}

	is_optional_link : Ast.Expression -> Bool
	is_optional_link = |tree|
		match tree {
			OptionalMember(_, _, _) | OptionalIndex(_, _, _) | OptionalCall(_, _, _) => True
			_ => False
		}

	## A call in a chain: what it calls, its arguments, whether it is an
	## optional call (`f?.()`), and where.
	ChainCall : {
		callee : Ast.Expression,
		arguments : List(Ast.Element),
		optional : Bool,
		at : Ast.Where,
	}

	# A call in a chain. A method's object is the link before it, so `o?.f()`
	# ends where `o` is nothing; an optional call ends where the function is.
	call_link! : Canvas.Host, Interp.Machine, Interp.ChainCall => Interp.Linked
	call_link! = |host, machine, { callee, arguments, optional, at: site }|
		match callee {
			Member(object, name, _) | OptionalMember(object, name, _) => {
				{ machine: after, link } = Interp.link!(host, machine, object)
				match link {
					Reached(holder) if Interp.is_optional_link(callee) and ValueRules.is_nullish(holder) => {
						machine: after,
						link: Short,
					}
					Reached(holder) if optional => {
						{ machine: read, value: function } = Interp.property(after, holder, name, site)
						if ValueRules.is_nullish(function) {
							{ machine: read, link: Short }
						} else {
							{ machine: called, values } = Interp.evaluate_elements!(host, read, arguments)
							Interp.reached(Interp.call_written!(host, called, function, values, callee, site))
						}
					}
					Reached(holder) => Interp.reached(
						Interp.method_call!(
							host,
							after,
							holder,
							{
								name: name,
								arguments: arguments,
								callee: callee,
								at: site,
							},
						),
					)
					Short => { machine: after, link: Short }
				}
			}
			_ => {
				{ machine: after, link } = Interp.link!(host, machine, callee)
				match link {
					Reached(function) if optional and ValueRules.is_nullish(function) => { machine: after, link: Short }
					Reached(function) => {
						{ machine: called, values } = Interp.evaluate_elements!(host, after, arguments)
						Interp.reached(Interp.call_written!(host, called, function, values, callee, site))
					}
					Short => { machine: after, link: Short }
				}
			}
		}

	# The machine after an expression whose value is not wanted.
	machine_after! : Canvas.Host, Interp.Machine, Ast.Expression => Interp.Machine
	machine_after! = |host, machine, expression| {
		{ machine: after, value: _ } = Interp.evaluate!(host, machine, expression)
		after
	}

	Evaluations : { machine : Interp.Machine, values : List(Heap.Value) }

	# The values of an array literal's items or a call's arguments, each
	# spread one put in as its items.
	evaluate_elements! : Canvas.Host, Interp.Machine, List(Ast.Element) => Interp.Evaluations
	evaluate_elements! = |host, machine, elements| {
		var $s = machine
		var $values = []
		for element in elements {
			match element {
				Single(expression) => {
					{ machine: after, value } = Interp.evaluate!(host, $s, expression)
					$s = after
					$values = $values.append(value)
				}
				Spread(expression, site) => {
					{ machine: after, value } = Interp.evaluate!(host, $s, expression)
					{ machine: walked, values: items } = Interp.iterated(after, value)
					match items {
						Ok(spread) => {
							$s = walked
							$values = List.concat($values, spread)
						}
						Err(NotIterable) => {
							$s = Interp.with_not_iterable(walked, value, Written(expression), site)
						}
					}
				}
			}
		}
		{ machine: $s, values: $values }
	}

	# ---- iteration over arrays, Maps and Sets ---------------------------------

	# A Map's or a Set's method: `forEach`, which calls back, here, and the
	# rest by the value rules.
	collection_method! : Canvas.Host, Interp.Machine, { id : U64, collection : ValueRules.Collection }, Str, List(Heap.Value), Ast.Where => Interp.Got
	collection_method! = |host, machine, { id, collection }, name, arguments, site|
		match name {
			"forEach" => Interp.collection_walk!(host, machine, id, arguments.first() ?? Undefined, site)
			_ => Interp.collection_method(machine, { id: id, collection: collection }, name, arguments, site)
		}

	# `forEach` on a Map or a Set: the callback given each entry's value, its
	# key (a Set's value again) and the collection, each entry read from the
	# heap as the walk comes to it.
	collection_walk! : Canvas.Host, Interp.Machine, U64, Heap.Value, Ast.Where => Interp.Got
	collection_walk! = |host, machine, id, callback, site| {
		var $s = machine
		var $i = 0
		var $going = True
		while $going and Interp.is_running($s) {
			match ValueRules.step_at($s.cells, id, Entries, $i) {
				YieldPair(key, value) => {
					{ machine: after, value: _ } = Interp.call!(host, $s, callback, [value, key, Reference(id)], site)
					$s = after
				}
				Skip => {}
				_ => {
					$going = False
				}
			}
			$i = $i + 1
		}
		{ machine: $s, value: Undefined }
	}

	evaluate_template! : Canvas.Host, Interp.Machine, List(Str), List(Ast.Expression) => Interp.Got
	evaluate_template! = |host, machine, texts, parts| {
		var $s = machine
		var $text = texts.first() ?? crash "Interp.evaluate_template: a template has a text piece before its first substitution"
		var $i = 1
		for part in parts {
			{ machine: after, value } = Interp.evaluate!(host, $s, part)
			$s = match ValueRules.text_of(after.cells, value) {
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
					Unready => Interp.error_got(
						machine,
						ReferenceError,
						ValueRules.unready_message(name),
						site,
					)
					_ => { machine: machine, value: binding.value }
				}
			}
			Nowhere => Interp.missing_name_got(machine, name, site)
		}

	# What a variable or a property held, and the value an assignment gives it.
	Change : { old : Heap.Value, new : Heap.Value }

	combination : Interp.Machine, Ast.AssignmentOperator, Interp.Change, Ast.Where -> Interp.Got
	combination = |machine, operator, change, site| {
		{ old, new } = change
		match operator {
			Set => { machine: machine, value: new }
			Combine(binary_operator) => Interp.binary(machine, binary_operator, old, new, site)
			Logically(_) => { machine: machine, value: new }
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

	evaluate_assign! : Canvas.Host, Interp.Machine, Interp.Assignment => Interp.Got
	evaluate_assign! = |host, machine, assignment|
		match assignment.operator {
			Logically(logical) => Interp.evaluate_logical_assign!(host, machine, assignment, logical)
			_ => Interp.evaluate_written_assign!(host, machine, assignment)
		}

	# `a ??= b`, `a ||= b` and `a &&= b`: the target read, then written with
	# `b`'s value only when the operator doesn't settle on what it read; `b`
	# isn't evaluated otherwise.
	evaluate_logical_assign! : Canvas.Host, Interp.Machine, Interp.Assignment, Ast.LogicalOperator => Interp.Got
	evaluate_logical_assign! = |host, machine, assignment, logical| {
		{
			target,
			operator: _,
			value: expression,
			at: site,
		} = assignment
		match target {
			ToName(name, slot, at) => {
				{ machine: read, value: old } = Interp.evaluate_name(machine, name, slot, at)
				if !Interp.is_running(read) or Interp.is_decided(logical, old) {
					{ machine: read, value: old }
				} else {
					{ machine: after, value } = Interp.evaluate!(host, read, expression)
					Interp.assigned_name(after, value, name, slot, at)
				}
			}
			ToMember(object, key) => {
				{ machine: first, value: holder } = Interp.evaluate!(host, machine, object)
				{ machine: read, value: old } = Interp.property(first, holder, key, site)
				if !Interp.is_running(read) or Interp.is_decided(logical, old) {
					{ machine: read, value: old }
				} else {
					{ machine: after, value } = Interp.evaluate!(host, read, expression)
					Interp.with_stored(after, holder, Text(key), value, site)
				}
			}
			ToIndex(object, key) => {
				{ machine: first, value: holder } = Interp.evaluate!(host, machine, object)
				{ machine: second, value: key_value } = Interp.evaluate!(host, first, key)
				{ machine: read, value: old } = Interp.indexed_value(second, holder, key_value, site)
				if !Interp.is_running(read) or Interp.is_decided(logical, old) {
					{ machine: read, value: old }
				} else {
					{ machine: after, value } = Interp.evaluate!(host, read, expression)
					Interp.with_stored(after, holder, key_value, value, site)
				}
			}
		}
	}

	# `=` and the compound assignments.
	evaluate_written_assign! : Canvas.Host, Interp.Machine, Interp.Assignment => Interp.Got
	evaluate_written_assign! = |host, machine, assignment| {
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
						"unsupported: assigning to `${name}`, which is not declared${ValueRules.line_note(at)}",
					)
					At({ scope, index }) => {
						facts = Interp.variable_facts(machine.scopes, scope, index)
						appends = operator == Combine(Add) and facts.state == Mutable and facts.holds_text and ValueRules.is_pure(expression)
						if appends {
							Interp.appended_name!(
								host,
								machine,
								scope,
								index,
								expression,
								site,
							)
						} else {
							old = Interp.variable_value(machine.scopes, scope, index)
							{ machine: after, value } = Interp.evaluate!(host, machine, expression)
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
				{ machine: first, value: holder } = Interp.evaluate!(host, machine, object)
				{ machine: second, value: old } = match operator {
					Set => { machine: first, value: Undefined }
					_ => Interp.property(first, holder, key, site)
				}
				{ machine: third, value } = Interp.evaluate!(host, second, expression)
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
				{ machine: first, value: holder } = Interp.evaluate!(host, machine, object)
				{ machine: second, value: key_value } = Interp.evaluate!(host, first, key)
				{ machine: third, value: old } = match operator {
					Set => { machine: second, value: Undefined }
					_ => Interp.indexed_value(second, holder, key_value, site)
				}
				{ machine: fourth, value } = Interp.evaluate!(host, third, expression)
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
					Fixed => Interp.error_got(
						machine,
						TypeError,
						"Assignment to constant variable.",
						site,
					)
					Unready => Interp.error_got(
						machine,
						ReferenceError,
						ValueRules.unready_message(name),
						site,
					)
				}
				Nowhere => Interp.error_got(machine, ReferenceError, "${name} is not defined", site)
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

	# `s += e` where `s` holds a string and `e` can't change it: `e` first,
	# then its text appended to the string where the variable holds it.
	#
	# **THE STRING IS TAKEN OUT OF ITS VARIABLE BEFORE IT GROWS.** Read the
	# usual way, the string is held twice, by the variable and by the value
	# read, so each append copied the string: building a string of N
	# characters one at a time cost N squared. `e` can't change the variable,
	# so it may run first, and the string then grows while only the variable
	# holds it.
	appended_name! : Canvas.Host, Interp.Machine, U64, U64, Ast.Expression, Ast.Where => Interp.Got
	appended_name! = |
		host,
		machine,
		scope_id,
		index,
		expression,
		site,
	| {
		{ machine: after, value: piece } = Interp.evaluate!(host, machine, expression)
		if !Interp.is_running(after) {
			{ machine: after, value: Undefined }
		} else {
			match ValueRules.text_of(after.cells, piece) {
				Err(Unsupported(why)) => Interp.fault_got(after, "${why}${ValueRules.line_note(site)}")
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

	evaluate_update! : Canvas.Host, Interp.Machine, Ast.Target, Ast.Step, Ast.Fixity, Ast.Where => Interp.Got
	evaluate_update! = |
		host,
		machine,
		target,
		step,
		fixity,
		site,
	| {
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
						"unsupported: `++` or `--` on a ${ValueRules.type_of(read_machine.cells, current)}${ValueRules.line_note(site)}",
					)
				}
			}
			ToMember(object, key) => {
				{ machine: first, value: holder } = Interp.evaluate!(host, machine, object)
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
						"unsupported: `++` or `--` on a ${ValueRules.type_of(read_machine.cells, current)}${ValueRules.line_note(site)}",
					)
				}
			}
			ToIndex(object, key) => {
				{ machine: first, value: holder } = Interp.evaluate!(host, machine, object)
				{ machine: second, value: key_value } = Interp.evaluate!(host, first, key)
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
						"unsupported: `++` or `--` on a ${ValueRules.type_of(read_machine.cells, current)}${ValueRules.line_note(site)}",
					)
				}
			}
		}
	}

	# ---- patterns --------------------------------------------------------------

	## How a pattern's leaves take their values: declared in the scope being
	## made, in the state given, or assigned as `=` assigns.
	How : [Declaring(Interp.VariableState), Assigning]

	## A value for a pattern to take apart, and how its leaves take theirs.
	Binding : {
		value : Heap.Value,
		how : Interp.How,
		origin : ValueRules.Origin,
		at : Ast.Where,
	}

	ItemPatterns : { items : List(Ast.ArrayItem), rest : Ast.Rest }

	PropertyPatterns : { properties : List(Ast.PropertyPattern), rest : Ast.Rest }

	ParameterPatterns : { items : List(Ast.Parameter), rest : Ast.Rest }

	with_pattern_bound! : Canvas.Host, Interp.Machine, Ast.Pattern, Interp.Binding => Interp.Machine
	with_pattern_bound! = |host, machine, pattern, binding|
		if !Interp.is_running(machine) {
			machine
		} else {
			match pattern {
				Leaf(target) => Interp.with_leaf_bound!(host, machine, target, binding)
				ArrayPattern(items, rest) => Interp.with_items_bound!(
					host,
					machine,
					{ items: items, rest: rest },
					binding,
				)
				ObjectPattern(properties, rest) => Interp.with_properties_bound!(
					host,
					machine,
					{ properties: properties, rest: rest },
					binding,
				)
			}
		}

	with_leaf_bound! : Canvas.Host, Interp.Machine, Ast.Target, Interp.Binding => Interp.Machine
	with_leaf_bound! = |host, machine, target, binding| {
		{ value, how, origin: _, at } = binding
		match (how, target) {
			(Declaring(state), ToName(_, slot, _)) => Interp.declare(machine, slot, value, state)
			(Declaring(_), _) => crash "Interp.with_leaf_bound!: Parser.pattern declares names alone"
			(Assigning, ToName(name, slot, site)) => {
				{ machine: after, value: _ } = Interp.assigned_name(machine, value, name, slot, site)
				after
			}
			(Assigning, ToMember(object, key)) => {
				{ machine: first, value: holder } = Interp.evaluate!(host, machine, object)
				{ machine: after, value: _ } = Interp.with_stored(first, holder, Text(key), value, at)
				after
			}
			(Assigning, ToIndex(object, key)) => {
				{ machine: first, value: holder } = Interp.evaluate!(host, machine, object)
				{ machine: second, value: key_value } = Interp.evaluate!(host, first, key)
				{ machine: after, value: _ } = Interp.with_stored(second, holder, key_value, value, at)
				after
			}
		}
	}

	# What a pattern walks: an array's items, read from the heap as the walk
	# goes, since what it binds may change the array, or values made once.
	Walked : [ItemsOf(U64), Values(List(Heap.Value))]

	# The machine comes back whether or not the value is iterable, as from
	# `iterated`.
	walked_of : Interp.Machine, Heap.Value -> { machine : Interp.Machine, walked : Try(Interp.Walked, [NotIterable]) }
	walked_of = |machine, subject|
		match subject {
			Reference(id) if ValueRules.is_array_cell(machine.cells, id) => { machine: machine, walked: Ok(ItemsOf(id)) }
			_ => {
				{ machine: after, values } = Interp.iterated(machine, subject)
				{ machine: after, walked: values.map_ok(|listed| Values(listed)) }
			}
		}

	walked_at : Interp.Machine, Interp.Walked, U64 -> Heap.Value
	walked_at = |machine, walked, position|
		match walked {
			ItemsOf(id) => ValueRules.item_at(machine.cells, id, position)
			Values(values) => values.get(position) ?? Undefined
		}

	walked_from : Interp.Machine, Interp.Walked, U64 -> List(Heap.Value)
	walked_from = |machine, walked, position|
		match walked {
			ItemsOf(id) => ValueRules.items_of(machine.cells, id).drop_first(position)
			Values(values) => values.drop_first(position)
		}

	with_items_bound! : Canvas.Host, Interp.Machine, Interp.ItemPatterns, Interp.Binding => Interp.Machine
	with_items_bound! = |host, machine, { items, rest }, binding| {
		{ value, how, origin, at } = binding
		{ machine: walking, walked: found } = Interp.walked_of(machine, value)
		match found {
			Err(NotIterable) => Interp.with_not_iterable(walking, value, origin, at)
			Ok(walked) => {
				var $s = walking
				var $i = 0
				for item in items {
					match item {
						Hole => {}
						Item(inner, default) => {
							given = Interp.walked_at($s, walked, $i)
							{ machine: after, value: chosen } = Interp.defaulted!(host, $s, given, default)
							$s = Interp.with_pattern_bound!(
								host,
								after,
								inner,
								{
									value: chosen,
									how: how,
									origin: Nested,
									at: at,
								},
							)
						}
					}
					$i = $i + 1
				}
				match rest {
					NoRest => $s
					RestOf(inner) => {
						left = Interp.walked_from($s, walked, $i)
						{ machine: made, value: array } = Interp.alloc($s, Array(left))
						Interp.with_pattern_bound!(
							host,
							made,
							inner,
							{
								value: array,
								how: how,
								origin: Nested,
								at: at,
							},
						)
					}
				}
			}
		}
	}

	with_properties_bound! : Canvas.Host, Interp.Machine, Interp.PropertyPatterns, Interp.Binding => Interp.Machine
	with_properties_bound! = |host, machine, { properties, rest }, binding| {
		{ value, how, origin, at } = binding
		match value {
			Null | Undefined => Interp.with_error(
				machine,
				TypeError,
				ValueRules.destructure_message(value, properties, origin),
				at,
			)
			_ => {
				var $s = machine
				for part in properties {
					{ machine: read, value: given } = Interp.property($s, value, part.key, at)
					{ machine: after, value: chosen } = Interp.defaulted!(host, read, given, part.default)
					$s = Interp.with_pattern_bound!(
						host,
						after,
						part.pattern,
						{
							value: chosen,
							how: how,
							origin: Nested,
							at: at,
						},
					)
				}
				match rest {
					NoRest => $s
					RestOf(inner) => match ValueRules.properties_left($s.cells, value, properties.map(|p| p.key)) {
						Ok(left) => {
							{ machine: made, value: object } = Interp.alloc($s, Object(left))
							Interp.with_pattern_bound!(
								host,
								made,
								inner,
								{
									value: object,
									how: how,
									origin: Nested,
									at: at,
								},
							)
						}
						Err(Unsupported(why)) => Interp.with_fault($s, "${why}${ValueRules.line_note(at)}")
					}
				}
			}
		}
	}

	# The call's parameters bound from its arguments: each pattern given its
	# argument, or its default where the argument is `undefined`, then the rest
	# parameter the items the others left.
	with_parameters_bound! : Canvas.Host, Interp.Machine, Interp.ParameterPatterns, List(Heap.Value), Ast.Where => Interp.Machine
	with_parameters_bound! = |host, machine, { items, rest }, arguments, site| {
		var $s = machine
		var $i = 0
		for item in items {
			given = arguments.get($i) ?? Undefined
			{ machine: after, value: chosen } = Interp.defaulted!(host, $s, given, item.default)
			$s = Interp.with_pattern_bound!(
				host,
				after,
				item.pattern,
				{
					value: chosen,
					how: Declaring(Mutable),
					origin: Argument,
					at: site,
				},
			)
			$i = $i + 1
		}
		match rest {
			NoRest => $s
			RestOf(inner) => {
				{ machine: made, value: array } = Interp.alloc($s, Array(arguments.drop_first(items.len())))
				Interp.with_pattern_bound!(
					host,
					made,
					inner,
					{
						value: array,
						how: Declaring(Mutable),
						origin: Nested,
						at: site,
					},
				)
			}
		}
	}

	# `given`, or the default's value where `given` is `undefined`.
	defaulted! : Canvas.Host, Interp.Machine, Heap.Value, Ast.Default => Interp.Got
	defaulted! = |host, machine, given, default|
		match (given, default) {
			(Undefined, Defaulted(expression)) => Interp.evaluate!(host, machine, expression)
			_ => { machine: machine, value: given }
		}

	# ---- properties ------------------------------------------------------------

	# ---- calls -----------------------------------------------------------------

	evaluate_call! : Canvas.Host, Interp.Machine, Ast.Expression, List(Ast.Element), Ast.Where => Interp.Got
	evaluate_call! = |host, machine, callee, arguments, site|
		match callee {
			Member(object, name, _) => {
				{ machine: first, value: holder } = Interp.evaluate!(host, machine, object)
				Interp.method_call!(
					host,
					first,
					holder,
					{
						name: name,
						arguments: arguments,
						callee: callee,
						at: site,
					},
				)
			}
			_ => {
				{ machine: first, value: function } = Interp.evaluate!(host, machine, callee)
				{ machine: second, values } = Interp.evaluate_elements!(host, first, arguments)
				Interp.call_written!(host, second, function, values, callee, site)
			}
		}

	## A method call as the program wrote it: the method's name, its
	## arguments, the callee written (`o.f`) and where it is.
	MethodCall : {
		name : Str,
		arguments : List(Ast.Element),
		callee : Ast.Expression,
		at : Ast.Where,
	}

	# A method of `holder` called, its arguments evaluated first: an array's
	# and a string's by name, anything else's the function its property holds.
	method_call! : Canvas.Host, Interp.Machine, Heap.Value, Interp.MethodCall => Interp.Got
	method_call! = |host, machine, holder, { name, arguments, callee, at: site }| {
		method = match holder {
			Reference(id) => match ValueRules.kind_of(machine.cells, id) {
				ArrayKind(_) => ArrayMethod(id)
				MapKind => CollectionMethod({ id: id, collection: IsMap })
				SetKind => CollectionMethod({ id: id, collection: IsSet })
				_ => Plain
			}
			Text(text) => TextMethod(text)
			_ => Plain
		}
		match method {
			CollectionMethod(held) => {
				{ machine: second, values } = Interp.evaluate_elements!(host, machine, arguments)
				Interp.collection_method!(host, second, held, name, values, site)
			}
			ArrayMethod(id) => {
				{ machine: second, values } = Interp.evaluate_elements!(host, machine, arguments)
				Interp.array_method!(
					host,
					second,
					id,
					name,
					values,
					site,
				)
			}
			TextMethod(text) => {
				{ machine: second, values } = Interp.evaluate_elements!(host, machine, arguments)
				Interp.text_method(second, text, name, values, site)
			}
			Plain => {
				{ machine: second, value: function } = Interp.property(machine, holder, name, site)
				{ machine: third, values } = Interp.evaluate_elements!(host, second, arguments)
				Interp.call_written!(host, third, function, values, callee, site)
			}
		}
	}

	# A call the program wrote: `call!`, but a callee that isn't a function
	# is named as the program wrote it, as node names it (`o.f is not a
	# function`).
	call_written! : Canvas.Host, Interp.Machine, Heap.Value, List(Heap.Value), Ast.Expression, Ast.Where => Interp.Got
	call_written! = |host, machine, function, arguments, written, site|
		if Interp.is_running(machine) and !ValueRules.is_callable(machine.cells, function) {
			Interp.not_written_function_got(machine, written, site)
		} else {
			Interp.call!(host, machine, function, arguments, site)
		}

	# **A CALL'S FRAMES STAY SMALL.** `call_written!` and `call!` stand on the
	# Roc stack under every call the program makes, so what only a failed call
	# needs, its message, is made in a function of its own, and so is a call
	# of a builtin: the dev build gives a frame room for all its arms.
	not_written_function_got : Interp.Machine, Ast.Expression, Ast.Where -> Interp.Got
	not_written_function_got = |machine, written, site|
		Interp.error_got(machine, TypeError, "${ValueRules.source_text(written)} is not a function", site)

	call! : Canvas.Host, Interp.Machine, Heap.Value, List(Heap.Value), Ast.Where => Interp.Got
	call! = |host, machine, callee, arguments, site|
		if !Interp.is_running(machine) {
			{ machine: machine, value: Undefined }
		} else {
			match Interp.closure_of(machine.cells, callee) {
				Ok(closure) => Interp.call_closure!(host, machine, closure, arguments, site)
				Err(NotClosure) => Interp.call_builtin!(host, machine, callee, arguments, site)
			}
		}

	closure_of : List(Heap.Cell), Heap.Value -> Try(Heap.Closure, [NotClosure])
	closure_of = |cells, callee|
		match callee {
			Reference(id) => match Heap.cell_at(cells, id) {
				Fun(closure) => Ok(closure)
				_ => Err(NotClosure)
			}
			_ => Err(NotClosure)
		}

	# A call of a builtin, or the TypeError of a call of what is no function.
	call_builtin! : Canvas.Host, Interp.Machine, Heap.Value, List(Heap.Value), Ast.Where => Interp.Got
	call_builtin! = |host, machine, callee, arguments, site|
		match callee {
			Reference(id) => match Heap.cell_at(machine.cells, id) {
				Builtin(native, _) => Interp.call_native!(host, machine, native, arguments, site)
				_ => Interp.error_got(machine, TypeError, "${ValueRules.shown_value(machine.cells, callee)} is not a function", site)
			}
			_ => Interp.error_got(machine, TypeError, "${ValueRules.shown_value(machine.cells, callee)} is not a function", site)
		}

	call_closure! : Canvas.Host, Interp.Machine, Heap.Closure, List(Heap.Value), Ast.Where => Interp.Got
	call_closure! = |host, machine, closure, arguments, site|
		if machine.depth >= ValueRules.max_depth {
			Interp.error_got(machine, RangeError, "Maximum call stack size exceeded", site)
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
			bound = match definition.binding {
				Plain => inside
				Patterned(parameters) => Interp.with_parameters_bound!(
					host,
					inside,
					parameters,
					arguments,
					definition.at,
				)
			}
			{ machine: after, flow } = Interp.execute_list!(
				host,
				Interp.with_functions_hoisted(bound, definition.statements),
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
	# of the function's layout, unready. Parameters bound through patterns
	# start unready too, and `with_parameters_bound!` makes them.
	call_variables : Ast.FunctionDefinition, List(Heap.Value) -> List(Interp.Variable)
	call_variables = |definition, arguments| {
		parameters = match definition.binding {
			Plain => definition.parameters.len()
			Patterned(_) => 0
		}
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

	# A builtin called: those that make an effect or call back here, the rest
	# by the value rules.
	call_native! : Canvas.Host, Interp.Machine, Heap.Native, List(Heap.Value), Ast.Where => Interp.Got
	call_native! = |host, machine, native, arguments, site|
		match native {
			Log => match Inspect.line_of(machine.cells, arguments) {
				Ok(line) => Interp.emit!(host, machine, Log(line))
				Err(Unsupported(why)) => Interp.fault_got(
					machine,
					"${why}${ValueRules.line_note(site)}",
				)
			}
			Paint(paint) => match Canvas.effect_of(
				paint,
				{ arguments: arguments, cells: machine.cells },
			) {
				Ok(effect) => Interp.emit!(host, machine, effect)
				Err(Unsupported(why)) => Interp.fault_got(
					machine,
					"${why}${ValueRules.line_note(site)}",
				)
			}
			Move(move) => match Canvas.moved(machine.turtle, { move: move, arguments: arguments }) {
				Ok({ turtle, drawn }) => match drawn {
					Drew(effect) => Interp.emit!(host, { ..machine, turtle: turtle }, effect)
					Nothing => { machine: { ..machine, turtle: turtle }, value: Undefined }
				}
				Err(Unsupported(why)) => Interp.fault_got(
					machine,
					"${why}${ValueRules.line_note(site)}",
				)
			}
			Sense(MouseX) => {
				pointer! = host.pointer!
				{ machine: machine, value: Number(pointer!(X)) }
			}
			Sense(MouseY) => {
				pointer! = host.pointer!
				{ machine: machine, value: Number(pointer!(Y)) }
			}
			Sense(KeyIsDown) => match arguments.first() {
				Ok(Text(key)) => {
					key! = host.key!
					down = match key!(key) {
						Down => True
						Up => False
					}
					{ machine: machine, value: Boolean(down) }
				}
				_ => Interp.fault_got(
					machine,
					"unsupported: keyIsDown of anything but a key's name${ValueRules.line_note(site)}",
				)
			}
			Timing(SetTimeout) => Interp.timer_set(machine, Once, arguments, site)
			Timing(SetInterval) => Interp.timer_set(machine, Repeating, arguments, site)
			Timing(ClearTimeout) | Timing(ClearInterval) => Interp.timer_cleared(machine, arguments)
			ArrayFrom if ValueRules.is_mapped(arguments) => Interp.array_from!(host, machine, arguments, site)
			OnClick => match arguments.first() {
				Ok(handler) if ValueRules.is_callable(machine.cells, handler) => {
					machine: {
						..machine,
						events: Events.with_click_handler(
							machine.events,
							{ handler: handler, site: site },
						),
					},
					value: Undefined,
				}
				_ => Interp.fault_got(
					machine,
					"unsupported: onClick of anything but a function${ValueRules.line_note(site)}",
				)
			}
			Floor | Ceil | Round | Trunc | Abs | Sign | Sqrt | Sin | Cos | Tan | Atan | Pow | Min | Max | Keys | Values | Entries | StringOf | FromCharCode | IsArray | IsInteger | MakeError(_) | ArrayFrom | ArrayOf | MakeMap | MakeSet => Interp.native_called(machine, native, arguments, site)
		}

	# `Array.from(source, mapper)`: `ValueRules.array_from_values`' values,
	# each given to `mapper` with its index.
	array_from! : Canvas.Host, Interp.Machine, List(Heap.Value), Ast.Where => Interp.Got
	array_from! = |host, machine, arguments, site| {
		mapper = arguments.get(1) ?? Undefined
		{ machine: walked, listed } = Interp.array_from_values(machine, arguments.first() ?? Undefined)
		match listed {
			Err(Unsupported(why)) => Interp.fault_got(walked, "${why}${ValueRules.line_note(site)}")
			Ok(values) => {
				var $s = walked
				var $out = []
				var $i = 0
				for value in values {
					if Interp.is_running($s) {
						{ machine: after, value: mapped } = Interp.call!(host, $s, mapper, [value, Number($i.to_f64())], site)
						$s = after
						$out = $out.append(mapped)
					}
					$i = $i + 1
				}
				Interp.alloc($s, Array($out))
			}
		}
	}

	# `setTimeout(callback, ms)` or `setInterval(callback, ms)`: the timer's
	# handle, its callback queued by `Events.timer_requested`'s rules.
	timer_set : Interp.Machine, [Once, Repeating], List(Heap.Value), Ast.Where -> Interp.Got
	timer_set = |machine, repeats, arguments, site| {
		{ rules, rest } = Interp.lent(machine)
		asked = { repeats: repeats, arguments: arguments, at: site, timer: rest.events.made, clock: rest.events.clock }
		{ machine: after, value, queued } = Events.timer_requested(rules, asked)
		back = Interp.with_rules(rest, after)
		match queued {
			Queued(event) => { machine: { ..back, events: Events.with_event(back.events, event) }, value: value }
			Refused => { machine: back, value: value }
		}
	}

	# `clearTimeout(handle)` or `clearInterval(handle)`: the timer queued no
	# more.
	timer_cleared : Interp.Machine, List(Heap.Value) -> Interp.Got
	timer_cleared = |machine, arguments|
		match Events.timer_named(machine.cells, arguments) {
			Timer(number) => {
				machine: { ..machine, events: Events.without_timer(machine.events, number) },
				value: Undefined,
			}
			NoTimer => { machine: machine, value: Undefined }
		}

	# ---- array methods ---------------------------------------------------------

	# An array's method: those that call a function back here, the rest by
	# the value rules.
	array_method! : Canvas.Host, Interp.Machine, U64, Str, List(Heap.Value), Ast.Where => Interp.Got
	array_method! = |
		host,
		machine,
		id,
		name,
		arguments,
		site,
	|
		match name {
			"flatMap" => Interp.array_walk!(
				host,
				machine,
				id,
				arguments,
				FlatMap,
				site,
			)
			"findLast" => Interp.array_walk_back!(host, machine, id, arguments, FindLast, site)
			"findLastIndex" => Interp.array_walk_back!(host, machine, id, arguments, FindLastIndex, site)
			"reduceRight" => Interp.array_reduce_right!(host, machine, id, arguments, site)
			"forEach" => Interp.array_walk!(
				host,
				machine,
				id,
				arguments,
				ForEach,
				site,
			)
			"map" => Interp.array_walk!(
				host,
				machine,
				id,
				arguments,
				Map,
				site,
			)
			"filter" => Interp.array_walk!(
				host,
				machine,
				id,
				arguments,
				Filter,
				site,
			)
			"some" => Interp.array_walk!(
				host,
				machine,
				id,
				arguments,
				Some,
				site,
			)
			"every" => Interp.array_walk!(
				host,
				machine,
				id,
				arguments,
				Every,
				site,
			)
			"find" => Interp.array_walk!(
				host,
				machine,
				id,
				arguments,
				Find,
				site,
			)
			"findIndex" => Interp.array_walk!(
				host,
				machine,
				id,
				arguments,
				FindIndex,
				site,
			)
			"reduce" => Interp.array_reduce!(host, machine, id, arguments, site)
			"sort" => Interp.array_sort!(host, machine, id, arguments, site)
			_ => Interp.array_method(machine, id, name, arguments, site)
		}

	Walk : [ForEach, Map, Filter, Some, Every, Find, FindIndex, FlatMap]

	# `findLast` and `findLastIndex`: the callback on each item from the last
	# back, until one passes.
	array_walk_back! : Canvas.Host, Interp.Machine, U64, List(Heap.Value), [FindLast, FindLastIndex], Ast.Where => Interp.Got
	array_walk_back! = |host, machine, id, arguments, walk, site| {
		callback = arguments.first() ?? Undefined
		var $s = machine
		var $k = ValueRules.item_count(machine.cells, id)
		var $answer = match walk {
			FindLast => Undefined
			FindLastIndex => Number(-1.0)
		}
		var $going = True
		while $going and $k > 0 {
			$k = $k - 1
			item = ValueRules.item_at($s.cells, id, $k)
			{ machine: after, value } = Interp.call!(host, $s, callback, [item, Number($k.to_f64()), Reference(id)], site)
			$s = after
			if ValueRules.is_truthy(value) {
				$answer = match walk {
					FindLast => item
					FindLastIndex => Number($k.to_f64())
				}
				$going = False
			}
			$going = $going and Interp.is_running($s)
		}
		{ machine: $s, value: $answer }
	}

	# `reduceRight`: `reduce` from the last item back.
	array_reduce_right! : Canvas.Host, Interp.Machine, U64, List(Heap.Value), Ast.Where => Interp.Got
	array_reduce_right! = |host, machine, id, arguments, site| {
		callback = arguments.first() ?? Undefined
		count = ValueRules.item_count(machine.cells, id)
		start = match arguments.get(1) {
			Ok(subject) => Ok({ accumulated: subject, before: count })
			Err(OutOfBounds) => {
				if count == 0 {
					Err(Empty)
				} else {
					Ok({ accumulated: ValueRules.item_at(machine.cells, id, count - 1), before: count - 1 })
				}
			}
		}
		match start {
			Err(Empty) => Interp.error_got(
				machine,
				TypeError,
				"Reduce of empty array with no initial value",
				site,
			)
			Ok({ accumulated, before }) => {
				var $s = machine
				var $accumulated = accumulated
				var $k = before
				while $k > 0 and Interp.is_running($s) {
					$k = $k - 1
					item = ValueRules.item_at($s.cells, id, $k)
					{ machine: after, value } = Interp.call!(
						host,
						$s,
						callback,
						[
							$accumulated,
							item,
							Number($k.to_f64()),
							Reference(id),
						],
						site,
					)
					$s = after
					$accumulated = value
				}
				{ machine: $s, value: $accumulated }
			}
		}
	}

	# An array method that calls a function on each item in turn, the items
	# read from the heap as it goes, since the function may change the array.
	array_walk! : Canvas.Host, Interp.Machine, U64, List(Heap.Value), Interp.Walk, Ast.Where => Interp.Got
	array_walk! = |
		host,
		machine,
		id,
		arguments,
		walk,
		site,
	| {
		callback = arguments.first() ?? Undefined
		count = ValueRules.item_count(machine.cells, id)
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
		while $going and $i < count and $i < ValueRules.item_count($s.cells, id) {
			item = ValueRules.item_at($s.cells, id, $i)
			{ machine: after, value } = Interp.call!(
				host,
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
					if ValueRules.is_truthy(value) {
						$out = $out.append(item)
					}
				}
				Some => {
					if ValueRules.is_truthy(value) {
						$answer = Boolean(True)
						$going = False
					}
				}
				Every => {
					if !ValueRules.is_truthy(value) {
						$answer = Boolean(False)
						$going = False
					}
				}
				Find => {
					if ValueRules.is_truthy(value) {
						$answer = item
						$going = False
					}
				}
				FindIndex => {
					if ValueRules.is_truthy(value) {
						$answer = Number($i.to_f64())
						$going = False
					}
				}
				FlatMap => {
					$out = match value {
						Reference(made) if ValueRules.is_array_cell($s.cells, made) => List.concat($out, ValueRules.items_of($s.cells, made))
						_ => $out.append(value)
					}
				}
			}
			$going = $going and Interp.is_running($s)
			$i = $i + 1
		}
		match walk {
			Map => Interp.alloc($s, Array($out))
			Filter => Interp.alloc($s, Array($out))
			FlatMap => Interp.alloc($s, Array($out))
			_ => { machine: $s, value: $answer }
		}
	}

	array_reduce! : Canvas.Host, Interp.Machine, U64, List(Heap.Value), Ast.Where => Interp.Got
	array_reduce! = |host, machine, id, arguments, site| {
		callback = arguments.first() ?? Undefined
		count = ValueRules.item_count(machine.cells, id)
		start = match arguments.get(1) {
			Ok(subject) => Ok({ accumulated: subject, from: 0 })
			Err(OutOfBounds) => {
				if count == 0 {
					Err(Empty)
				} else {
					Ok({ accumulated: ValueRules.item_at(machine.cells, id, 0), from: 1 })
				}
			}
		}
		match start {
			Err(Empty) => Interp.error_got(
				machine,
				TypeError,
				"Reduce of empty array with no initial value",
				site,
			)
			Ok({ accumulated, from }) => {
				var $s = machine
				var $accumulated = accumulated
				var $i = from
				while $i < count and $i < ValueRules.item_count($s.cells, id) and Interp.is_running($s) {
					item = ValueRules.item_at($s.cells, id, $i)
					{ machine: after, value } = Interp.call!(
						host,
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
	array_sort! : Canvas.Host, Interp.Machine, U64, List(Heap.Value), Ast.Where => Interp.Got
	array_sort! = |host, machine, id, arguments, site| {
		items = ValueRules.items_of(machine.cells, id)
		compare = arguments.first() ?? Undefined
		{ machine: after, values } = Interp.merge_sorted!(host, machine, items, compare, site)
		if Interp.is_running(after) {
			{
				machine: { ..after, cells: Heap.with_items(after.cells, id, values) },
				value: Reference(id),
			}
		} else {
			{ machine: after, value: Reference(id) }
		}
	}

	merge_sorted! : Canvas.Host, Interp.Machine, List(Heap.Value), Heap.Value, Ast.Where => Interp.Evaluations
	merge_sorted! = |host, machine, items, compare, site| {
		count = items.len()
		if count <= 1 {
			{ machine: machine, values: items }
		} else {
			half = count // 2
			{ machine: first, values: lower } = Interp.merge_sorted!(
				host,
				machine,
				items.sublist({ start: 0, len: half }),
				compare,
				site,
			)
			{ machine: second, values: upper } = Interp.merge_sorted!(
				host,
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
					{ machine: after, order } = Interp.ordering_of!(
						host,
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

	ordering_of! : Canvas.Host, Interp.Machine, Interp.Comparison => Interp.Ordered
	ordering_of! = |host, machine, comparison| {
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
						ValueRules.text_of(machine.cells, left),
						ValueRules.text_of(machine.cells, right),
					) {
						(Ok(x), Ok(y)) => ValueRules.ordering_of_text(x, y)
						_ => Same
					}
				}
				{ machine: machine, order: order }
			}
			_ => {
				{ machine: after, value } = Interp.call!(
					host,
					machine,
					compare,
					[left, right],
					site,
				)
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

}
