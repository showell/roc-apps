## This module holds the one queue every callback goes through, and its
## virtual clock: a timer's
## callback, the program's next `frame(t)` and a click are each an event,
## due at a time in milliseconds, and run earliest first, two at one time in
## the order they were queued. The VM runs the callbacks; this module
## keeps the order, the clock and the timers' rules (`timer_requested`,
## `timer_named`), each message in its words.
import Ast
import Canvas
import Heap
import ValueRules

Events :: [].{

	## What waits to happen after the program's end: a timer's callback, the
	## next frame, a click. Each runs when the clock reaches its time,
	## earliest first, and of two at one time the one queued first.
	Event : {
		due : F64,
		order : U64,
		site : Ast.Where,
		happening : Events.Happening,
	}

	Happening : [
		# A timer's callback; an interval's is queued again `every` ms on.
		Timed(
			{
				timer : U64,
				callback : Heap.Value,
				every : [Once, Every(F64)],
			},
		),
		# The program's `frame(t)`, for the frame of that number.
		Framed(Heap.Closure, U64),
		# A click at x and y, for the program's `onClick` handler.
		Clicked(F64, F64),
		# A collection that has swept, for the program's `onCollect` handler:
		# the heap's cells, those in use just before it and those it found live.
		Collected({ cells : U64, before : U64, live : U64 }),
	]

	## The one queue every callback goes through, and its clock.
	##
	## **THE CLOCK IS VIRTUAL.** It reads 0 while the program runs, and moves
	## only when the host moves it: to each event's time as the event runs,
	## then to the time the host asked for (`tick!`), or from event to event
	## until none is left (`drain!`). So callbacks run in an order the program
	## alone fixes, the order node gives them.
	Queue : {
		# Milliseconds since the program started, on the virtual clock.
		clock : F64,
		pending_events : List(Events.Event),
		# The events and timers numbered so far: the next event's `order`, and
		# the next timer's number.
		made : U64,
		# The interval whose callback runs, and whether it cleared itself.
		firing : [Firing(U64), Cleared, Idle],
		on_click : [Handler({ handler : Heap.Value, site : Ast.Where }), NoHandler],
		# The program's `onCollect` handler, a playground extra like `onClick`.
		on_collect : [Handler({ handler : Heap.Value, site : Ast.Where }), NoHandler],
	}

	## A queue with nothing waiting, its clock at 0: a program's at its start.
	at_start : Events.Queue
	at_start = {
		clock: 0.0,
		pending_events: [],
		made: 0,
		firing: Idle,
		on_click: NoHandler,
		on_collect: NoHandler,
	}

	## The most timer callbacks `run!` runs after the program: an interval
	## never cleared runs forever in node, and stops here with a message.
	callback_limit : U64
	callback_limit = 100000

	## The time of frame `number`, in seconds, as the page and the recording host
	## compute it.
	frame_time : U64 -> F64
	frame_time = |number| number.to_f64() / Canvas.frames_per_second.to_f64()

	# The clock's time, in ms, of frame `number`'s tick.
	frame_due : U64 -> F64
	frame_due = |number| Events.frame_time(number) * 1000.0

	# The events with one more queued, its `order` the next number.
	with_event : Events.Queue,
	{
		due : F64,
		site : Ast.Where,
		happening : Events.Happening,
	} -> Events.Queue
	with_event = |events, { due, site, happening }| {
		{ clock, pending_events, made, firing, on_click, on_collect } = events
		{
			clock: clock,
			pending_events: pending_events.append({
				due: due,
				order: made,
				site: site,
				happening: happening,
			}),
			made: made + 1,
			firing: firing,
			on_click: on_click,
			on_collect: on_collect,
		}
	}

	# The events with the clock at `time`, unless it is past it.
	with_clock_at : Events.Queue, F64 -> Events.Queue
	with_clock_at = |events, time| {
		{ clock, pending_events, made, firing, on_click, on_collect } = events
		{
			clock: if time > clock {
				time
			} else {
				clock
			},
			pending_events: pending_events,
			made: made,
			firing: firing,
			on_click: on_click,
			on_collect: on_collect,
		}
	}

	# The place in `pending_events` of the earliest event due by `until`: the least
	# time, and of two at one time the one queued first.
	earliest : List(Events.Event), F64 -> [At(U64), NoneDue]
	earliest = |pending_events, until| {
		var $best = NoneDue
		var $best_due = 0.0
		var $best_order = 0
		var $i = 0
		for event in pending_events {
			if event.due <= until {
				better = match $best {
					NoneDue => True
					At(_) => Events.is_sooner(event, { due: $best_due, order: $best_order })
				}
				if better {
					$best = At($i)
					$best_due = event.due
					$best_order = event.order
				}
			}
			$i = $i + 1
		}
		$best
	}

	# Whether `event` runs before one due at `due` and queued `order`th.
	is_sooner : Events.Event, { due : F64, order : U64 } -> Bool
	is_sooner = |event, { due, order }|
		event.due < due or (event.due == due and event.order < order)

	with_event_taken : Events.Queue, U64, F64 -> Events.Queue
	with_event_taken = |events, index, due| {
		{ clock, pending_events, made, firing, on_click, on_collect } = events
		{
			clock: if due > clock {
				due
			} else {
				clock
			},
			pending_events: pending_events.drop_at(index),
			made: made,
			firing: firing,
			on_click: on_click,
			on_collect: on_collect,
		}
	}

	# The events with `firing` set.
	with_firing : Events.Queue, [Firing(U64), Cleared, Idle] -> Events.Queue
	with_firing = |events, now_firing| {
		{
			clock,
			pending_events,
			made,
			firing: _,
			on_click,
			on_collect,
		} = events
		{
			clock: clock,
			pending_events: pending_events,
			made: made,
			firing: now_firing,
			on_click: on_click,
			on_collect: on_collect,
		}
	}

	# The events without timer `timer`: its callback queued no more, and an
	# interval clearing itself from its own callback not queued again.
	without_timer : Events.Queue, U64 -> Events.Queue
	without_timer = |events, timer| {
		{ clock, pending_events, made, firing, on_click, on_collect } = events
		{
			clock: clock,
			pending_events: pending_events.keep_if(
				|event| match event.happening {
					Timed(
						{
							timer: queued,
							callback: _,
							every: _,
						},
					) => queued != timer
					_ => True
				},
			),
			made: made,
			firing: if firing == Firing(timer) {
				Cleared
			} else {
				firing
			},
			on_click: on_click,
			on_collect: on_collect,
		}
	}

	with_click_handler : Events.Queue, { handler : Heap.Value, site : Ast.Where } -> Events.Queue
	with_click_handler = |events, handling| {
		{
			clock,
			pending_events,
			made,
			firing,
			on_click: _,
			on_collect,
		} = events
		{
			clock: clock,
			pending_events: pending_events,
			made: made,
			firing: firing,
			on_click: Handler(handling),
			on_collect: on_collect,
		}
	}

	## The events with `handling` called after each collection, an event
	## queued for it once the collection has swept (`onCollect`).
	with_collect_handler : Events.Queue, { handler : Heap.Value, site : Ast.Where } -> Events.Queue
	with_collect_handler = |events, handling| {
		{
			clock,
			pending_events,
			made,
			firing,
			on_click,
			on_collect: _,
		} = events
		{
			clock: clock,
			pending_events: pending_events,
			made: made,
			firing: firing,
			on_click: on_click,
			on_collect: Handler(handling),
		}
	}

	## `setTimeout(callback, ms)` or `setInterval(callback, ms)`: the timer's
	## handle, numbered `timer`, and its first event, `ms` on from `clock`, for
	## the VM to queue; or the fault that refuses it. A delay below 1 ms,
	## past 2^31 - 1 or left out is 1 ms, as node makes it.
	timer_requested : ValueRules.Machine,
	{
		repeats : [Once, Repeating],
		arguments : List(Heap.Value),
		at : Ast.Where,
		timer : U64,
		clock : F64,
	} -> { machine : ValueRules.Machine, value : Heap.Value, queued : [Queued({ due : F64, site : Ast.Where, happening : Events.Happening }), Refused] }
	timer_requested = |machine, { repeats, arguments, at, timer, clock }| {
		name = match repeats {
			Once => "setTimeout"
			Repeating => "setInterval"
		}
		callback = arguments.first() ?? Undefined
		delay = match arguments.get(1) {
			Ok(Number(ms)) => Ok(
				if ms >= 1.0 and ms <= 2147483647.0 {
					ms
				} else {
					1.0
				},
			)
			Ok(Undefined) | Err(OutOfBounds) => Ok(1.0)
			Ok(_) => Err(NotNumber)
		}
		if !ValueRules.is_callable(machine.cells, callback) {
			timer_refused(machine, "${name}(callback, ms) of a callback that is not a function", at)
		} else if arguments.len() > 2 {
			timer_refused(machine, "${name}'s arguments after the delay", at)
		} else {
			match delay {
				Ok(ms) => {
					every = match repeats {
						Once => Once
						Repeating => Every(ms)
					}
					{ machine: made, value: handle } = ValueRules.alloc(machine, TimerHandle(timer))
					event = {
						due: clock + ms,
						site: at,
						happening: Timed({ timer: timer, callback: callback, every: every }),
					}
					{ machine: made, value: handle, queued: Queued(event) }
				}
				Err(NotNumber) => timer_refused(machine, "${name}(callback, ms) of a delay that is not a number", at)
			}
		}
	}

	## The timer `clearTimeout(handle)` or `clearInterval(handle)` names, which
	## node treats as one: anything but a timer's handle names none, and is
	## let be, as node lets it be.
	timer_named : List(Heap.Cell), List(Heap.Value) -> [Timer(U64), NoTimer]
	timer_named = |cells, arguments|
		match arguments.first() {
			Ok(Reference(id)) => match Heap.cell_at(cells, id) {
				TimerHandle(number) => Timer(number)
				_ => NoTimer
			}
			_ => NoTimer
		}
}

timer_refused : ValueRules.Machine, Str, Ast.Where -> { machine : ValueRules.Machine, value : Heap.Value, queued : [Queued({ due : F64, site : Ast.Where, happening : Events.Happening }), Refused] }
timer_refused = |machine, why, at| {
	machine: ValueRules.with_fault(machine, "unsupported: ${why}${ValueRules.line_note(at)}"),
	value: Undefined,
	queued: Refused,
}
