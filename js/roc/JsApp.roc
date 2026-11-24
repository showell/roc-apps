# The JavaScript subset as the page's wasm module, on the platform in
# ../wasm/platform: a program's text in, then a frame at a time, each effect
# handed to the page as the program makes it (Canvas.roc).
#
# A program is compiled on the canvas library and runs on the bytecode VM
# (Vm.roc), held to the page's rails (`Canvas.run_limits`, then
# `Canvas.frame_limits` for each frame). Each frame is a tick of the
# program's clock (`Vm.tick!`): the clicks the page
# queued since the last (`add_click!`), the timers due, and the program's
# `frame(t)`. Every call but `add_click!` ends with one line through `Host.emit!`
# that says how it ended:
#
# - `end frame`: the call ran to its end, and the program waits for the page
#   to call the next frame (`Vm.waits`: an event queued, or a click
#   handler);
# - `end done`: the program ran to its end and waits for nothing;
# - `end faulted <why>`: the program stopped with a fault;
# - `end thrown <line>`: the program stopped with a throw nothing caught,
#   `<line>` what js-run prints for it (`Uncaught TypeError: ...`);
# - `end refused <why>`: the parser or the compiler refused the program,
#   before any of it ran.
#
# The `<why>` is what js-run's last line says after its `js: `.
app [Model, program] { pf: platform "../wasm/platform/main.roc" }

import pf.Host
import Canvas
import Compile
import Parser
import Vm

Model : [Live(Vm.Session), Refused]

page_host : Canvas.Host
page_host = {
	emit!: |effect| Host.emit!(Canvas.line_of(effect).to_utf8()),
	pointer!: |axis| Host.pointer!(axis),
	key!: |key| Host.key!(key.to_utf8()),
}

source_buffer : U32 -> List(U8)
source_buffer = |length| List.repeat(0, length.to_u64())

start! : List(U8) => Box(Model)
start! = |bytes| {
	src = Str.from_utf8_lossy(bytes)
	match Parser.program_of(src, Canvas) {
		Ok(tree) => match Compile.program(tree) {
			Ok(program) => {
				settings = {
					library: Canvas,
					steps: Canvas.run_limits.steps,
					effects: Canvas.run_limits.effects,
					collecting: Doubling,
				}
				session = Vm.start!(page_host, program, settings)
				report_ending!(session)
				Box.box(Live(session))
			}
			Err(Unsupported(why)) => {
				Host.emit!("end refused ${why}".to_utf8())
				Box.box(Refused)
			}
		}
		Err(fault) => {
			Host.emit!("end refused ${fault.why} (line ${fault.line.to_str()}, column ${fault.column.to_str()})".to_utf8())
			Box.box(Refused)
		}
	}
}

run_frame! : Box(Model), F64 => Box(Model)
run_frame! = |boxed, seconds|
	match boxed.unbox() {
		Live(session) => {
			next = Vm.tick!(page_host, session, seconds, Canvas.frame_limits)
			report_ending!(next)
			Box.box(Live(next))
		}
		Refused => crash "JsApp.run_frame!: the page calls run_frame! only after `end frame`"
	}

# A click at x and y on the canvas, queued for the next frame.
add_click! : Box(Model), F64, F64 => Box(Model)
add_click! = |boxed, x, y|
	match boxed.unbox() {
		Live(session) => Box.box(Live(Vm.with_click(session, x, y)))
		Refused => Box.box(Refused)
	}

# The line that ends a call: how the session stands after it.
report_ending! : Vm.Session => {}
report_ending! = |session| {
	line = match Vm.standing(session) {
		Faulted(why) => "end faulted ${why}"
		Uncaught(said) => "end thrown ${said}"
		Running => if Vm.waits(session) {
			"end frame"
		} else {
			"end done"
		}
	}
	Host.emit!(line.to_utf8())
}

drop_model : Box(Model) -> {}
drop_model = |_model| {}

drop_bytes : List(U8) -> {}
drop_bytes = |_bytes| {}

program = {
	source_buffer,
	start!,
	run_frame!,
	add_click!,
	drop_model,
	drop_bytes,
}
