# The JavaScript subset as the page's wasm module, on the platform in
# ../wasm/platform: a program's text in, then a frame at a time, each effect
# handed to the page as the program makes it (Canvas.roc).
#
# A program runs on the canvas library, held to the page's rails
# (`Canvas.run_limits`, then `Canvas.frame_limits` for each frame). Each frame
# is a tick of the program's clock (`Interp.tick!`): the clicks the page
# queued since the last (`click!`), the timers due, and the program's
# `frame(t)`. Every call but `click!` ends with one line through `Host.emit!`
# that says how it ended:
#
# - `end frame`: the call ran to its end, and the program waits for the page
#   to call the next frame (`Interp.waits`: an event queued, or a click
#   handler);
# - `end done`: the program ran to its end and waits for nothing;
# - `end faulted <why>`: the program stopped with a fault;
# - `end refused <why>`: the parser refused the program.
#
# The `<why>` is what js-run's last line says after its `js: `.
app [Model, program] { pf: platform "../wasm/platform/main.roc" }

import pf.Host
import Canvas
import Interp
import Parser

Model : [Live(Interp.Session), Refused]

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
		Ok(program) => {
			session = Interp.start!(page_host, program, Canvas, Canvas.run_limits)
			said!(session)
			Box.box(Live(session))
		}
		Err(fault) => {
			Host.emit!("end refused ${fault.why} (line ${fault.line.to_str()}, column ${fault.column.to_str()})".to_utf8())
			Box.box(Refused)
		}
	}
}

frame! : Box(Model), F64 => Box(Model)
frame! = |boxed, t|
	match boxed.unbox() {
		Live(session) => {
			next = Interp.tick!(page_host, session, t, Canvas.frame_limits)
			said!(next)
			Box.box(Live(next))
		}
		Refused => crash "JsApp.frame!: the page calls frame! only after `end frame`"
	}

# A click at x and y on the canvas, queued for the next frame.
click! : Box(Model), F64, F64 => Box(Model)
click! = |boxed, x, y|
	match boxed.unbox() {
		Live(session) => Box.box(Live(Interp.clicked(session, x, y)))
		Refused => Box.box(Refused)
	}

# The line that ends a call: how the session stands after it.
said! : Interp.Session => {}
said! = |session| {
	line = match Interp.outcome_of(session.machine).status {
		Faulted(why) => "end faulted ${why}"
		Running => if Interp.waits(session) {
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
	frame!,
	click!,
	drop_model,
	drop_bytes,
}
