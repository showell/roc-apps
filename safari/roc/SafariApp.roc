# The screensaver as a Roc app on the safari wasm platform (../wasm/platform).
#
# Hand-written: the wasm edge of SafariRide, which holds the ride and says what
# a frame shows. The host (../wasm/platform/host.zig) keeps the model as one
# boxed pointer and exposes the readouts web/blitter.js binds; the draw buffer
# is packed here, word for word what poc/drive_shim.zig in safari-codex wrote:
# tag, colour, count, then f32 bit patterns.
app [Model, program] { pf: platform "../wasm/platform/main.roc" }

import World
import Safari
import SafariRide
import SafariMovie
import ShapeWire
import Blit
import RideFocal

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
clock = |b| F64.to_u32_wrap(Box.unbox(b).ride.clock)

rider_seg : Box(Model) -> U32
rider_seg = |b| u(Box.unbox(b).ride.rider.segment)

rider_tilt : Box(Model) -> F32
rider_tilt = |b| {
	frame = movie.frame
	F64.to_f32_wrap(frame(Box.unbox(b)).roll)
}

cam_focal : Box(Model) -> F32
cam_focal = |b| {
	m = Box.unbox(b)
	F64.to_f32_wrap(RideFocal.ride_focal(m.world, m.ride.rider))
}

gaze_yaw : Box(Model) -> F32
gaze_yaw = |b| F64.to_f32_wrap(Box.unbox(b).ride.rider.gaze_yaw)

rider_v : Box(Model) -> F32
rider_v = |b| F64.to_f32_wrap(Box.unbox(b).ride.rider.v)

truck_lead : Box(Model) -> F32
truck_lead = |b| {
	m = Box.unbox(b)
	r = m.ride.rider
	F64.to_f32_wrap(m.ride.truck.pos - World.route_distance(m.world, r.segment, r.along))
}

truck_v : Box(Model) -> F32
truck_v = |b| F64.to_f32_wrap(Box.unbox(b).ride.truck.v)

# What the platform requires, as one record.
program = { init, advance, back, render, probe_frame, probe_expand, clock, rider_seg, rider_tilt, cam_focal, gaze_yaw, rider_v, truck_lead, truck_v }
