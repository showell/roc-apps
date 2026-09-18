# The screensaver as a Roc app on the safari wasm platform (../wasm/platform).
#
# Hand-written: the wasm edge of SafariRide, which holds the ride and says what
# a frame shows. The host (../wasm/platform/host.zig) keeps the model as one
# boxed pointer and exposes the readouts web/blitter.js binds; the draw buffer
# is packed here, word for word what poc/drive_shim.zig in safari-codex wrote:
# tag, colour, count, then f32 bit patterns.
app [Model, program] { pf: platform "../wasm/platform/main.roc" }

import Safari
import SafariRide
import SafariMovie
import ShapeWire
import Blit

Model : SafariMovie.Model

# The movie this page plays, named here and nowhere else. Roc reads
# `movie.advance(m)` as a method call, so its functions are bound first.
movie = SafariMovie.movie

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

# --- The draw buffer --------------------------------------------------------

u : I64 -> U32
u = |n| I64.to_u32_wrap(n)

# Timing probes for the smoke run: how many commands the frame has before and
# after expansion, so render's three stages can be timed apart.
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

# **THE WHOLE FRAME, BACKDROP AND ALL.** What went over this wire used to be
# draw commands, with the page painting the sky and the sun itself from six
# more exports; a page cannot do that for a movie it has never heard of, so the
# frame arrives as shapes and the page paints what it is given.
render : Box(Model) -> List(U32)
render = |b| {
	frame = movie.frame
	ShapeWire.pack(frame(Box.unbox(b)).shapes)
}

# --- The readouts -------------------------------------------------------------

clock : Box(Model) -> U32
clock = |b| {
	tick = movie.clock
	F64.to_u32_wrap(tick(Box.unbox(b)))
}

# Which scene it is in. Safari's are the route's segments, and the page shows
# the number; what a scene IS, is the movie's business.
scene : Box(Model) -> U32
scene = |b| u(Box.unbox(b).ride.rider.segment)

# How the camera is turned, which the page applies to the whole frame.
roll : Box(Model) -> F32
roll = |b| {
	frame = movie.frame
	F64.to_f32_wrap(frame(Box.unbox(b)).roll)
}

# What the platform requires, as one record.
program = { init, advance, back, render, probe_frame, probe_expand, clock, scene, roll }
