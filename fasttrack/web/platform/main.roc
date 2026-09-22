# The fasttrack platform: a game driven by clicks, over one boxed model the
# host keeps (host.zig).
#
# `init` takes the time as Elm's did, to seed the deck, a setup number, and
# who sits in each seat (FastTrack.seats_of).
# `update` takes the code of what was clicked. `view` answers the whole page
# as data (Wire.View); `release` hands a view back so Roc frees it, since
# freeing its lists of strings needs a layout only Roc has.
platform ""
	requires {
		[Model : model] for program : {
			init : U64, U32, U32 -> Box(model),
			update : Box(model), U32 -> Box(model),
			view : Box(model) -> Box(Wire.View),
			release : Box(Wire.View) -> {},
		}
	}
	exposes [Wire]
	packages {}
	provides {
		"roc_init": init_for_host,
		"roc_update": update_for_host,
		"roc_view": view_for_host,
		"roc_release": release_for_host,
	}
	targets: {
		inputs_dir: "targets/",
		wasm32: {
			inputs: ["host.wasm", app],
			exports: ["start", "update", "computeView"],
		},
	}

import Wire

init_for_host = program.init
update_for_host = program.update
view_for_host = program.view
release_for_host = program.release
