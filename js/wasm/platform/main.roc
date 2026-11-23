# The JavaScript subset's platform for the browser: a program that runs once,
# then a frame at a time, its effects handed to the page as it makes them.
#
# The host never builds a Roc list itself. It asks the Roc for a buffer of
# the source's length (`buffer_for_host`), writes the source into it, and
# hands it to `start_for_host!`, which consumes it. What that call answers is
# the run, boxed: the host keeps it and hands it to `frame_for_host!` for each
# frame and to `click_for_host!` for each click, each of which consumes it
# and answers the next, and to `drop_model_for_host`
# when the page starts another run. Each list the Roc hands the host through
# `Host.emit!` goes back to `drop_bytes_for_host`. So the host needs no
# knowledge of how Roc lays out a list or a box, only a list's three words
# and a box's one.
platform ""
	requires {
		[Model : model] for program : {
			source_buffer : U32 -> List(U8),
			start! : List(U8) => Box(model),
			frame! : Box(model), F64 => Box(model),
			click! : Box(model), F64, F64 => Box(model),
			drop_model : Box(model) -> {},
			drop_bytes : List(U8) -> {},
		}
	}
	exposes [Host]
	packages {}
	provides {
		"roc_buffer": buffer_for_host,
		"roc_click": click_for_host!,
		"roc_drop_bytes": drop_bytes_for_host,
		"roc_drop_model": drop_model_for_host,
		"roc_frame": frame_for_host!,
		"roc_start": start_for_host!,
	}
	hosted {
		"host_emit": Host.emit!,
		"host_key": Host.key!,
		"host_pointer": Host.pointer!,
	}
	targets: {
		wasm32: {
			inputs: [app],
			output: Archive,
		},
	}

import Host

buffer_for_host = program.source_buffer

start_for_host! = program.start!

frame_for_host! = program.frame!

click_for_host! = program.click!

drop_model_for_host = program.drop_model

drop_bytes_for_host = program.drop_bytes
