# The screensaver as a Roc app on the movie wasm platform (../../wasm/platform).
#
# Hand-written. **THE DEFAULT PLUS WHAT IS SAFARI'S OWN**: WasmApp.program is
# the whole wasm edge for any movie, and this names the two things Safari
# answers differently -- the command counts the Node smoke run times its stages
# by, before and after expansion. Every other movie's app is the five lines
# without this part.
app [Model, program] { pf: platform "../../wasm/platform/main.roc" }

import Safari
import SafariMovie
import WasmApp
import Blit

Model : SafariMovie.Model

# How many commands the frame has before and after expansion, so render's
# stages can be timed apart.
probe_frame : Box(Model) -> U32
probe_frame = |b| {
	m = Box.unbox(b)
	U64.to_u32_wrap(List.len(Safari.ride_frame(m.world, m.ride)))
}

probe_expand : Box(Model) -> U32
probe_expand = |b| {
	m = Box.unbox(b)
	U64.to_u32_wrap(List.len(Blit.blit_expand(Safari.ride_frame(m.world, m.ride), 0)))
}

program = { ..WasmApp.program(SafariMovie.movie), probe_frame, probe_expand }
