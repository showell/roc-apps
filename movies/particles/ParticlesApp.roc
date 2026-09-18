# particles on the movie wasm platform: the same movie the roc-ray app
# plays, on a page.
#
# Hand-written, and almost nothing: the platform asks for a model it can step
# and a frame it can draw, and `Particles.movie` is both. Compare
# safari/roc/SafariApp.roc, which is the same file for the other movie.
app [Model, program] { pf: platform "../../safari/wasm/platform/main.roc" }

import Particles
import ShapeWire

Model : Particles.Model

movie = Particles.movie

init : {} -> Box(Model)
init = |{}| Box.box(movie.init)

advance : Box(Model) -> Box(Model)
advance = |b| {
	step = movie.advance
	Box.box(step(Box.unbox(b)))
}

back : Box(Model) -> Box(Model)
back = |b| {
	step = movie.back
	Box.box(step(Box.unbox(b)))
}

render : Box(Model) -> List(U32)
render = |b| {
	frame = movie.frame
	ShapeWire.pack(frame(Box.unbox(b)).shapes)
}

clock : Box(Model) -> U32
clock = |b| {
	tick = movie.clock
	F64.to_u32_wrap(tick(Box.unbox(b)))
}

# It has no scenes, and no roll.
scene : Box(Model) -> U32
scene = |_b| 0

roll : Box(Model) -> F32
roll = |_b| 0.0

# The smoke run's stage timings: how many shapes a frame has.
probe_frame : Box(Model) -> U32
probe_frame = |b| {
	frame = movie.frame
	U64.to_u32_wrap(List.len(frame(Box.unbox(b)).shapes))
}

probe_expand : Box(Model) -> U32
probe_expand = |b| probe_frame(b)

# How big a frame is, in the movie's own coordinates.
width : Box(Model) -> U32
width = |_b| F64.to_u32_wrap(movie.size.width)

height : Box(Model) -> U32
height = |_b| F64.to_u32_wrap(movie.size.height)

program = { init, advance, back, render, probe_frame, probe_expand, clock, scene, roll, width, height }
