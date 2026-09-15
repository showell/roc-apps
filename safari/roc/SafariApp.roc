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
import Blit
import Paint
import RideFocal

Model : SafariRide.Model

init : {} -> Box(Model)
init = |{}| Box.box(SafariRide.init)

advance : Box(Model) -> Box(Model)
advance = |b| Box.box(SafariRide.advance(Box.unbox(b)))

back : Box(Model) -> Box(Model)
back = |b| Box.box(SafariRide.back(Box.unbox(b)))

# --- The draw buffer --------------------------------------------------------

word : F64 -> U32
word = |v| F32.to_bits(F64.to_f32_wrap(v))

words : List(F64) -> List(U32)
words = |vs| List.map(vs, word)

u : I64 -> U32
u = |n| I64.to_u32_wrap(n)

# One command as the blitter reads it. Tag 3 is a disc: six words and no point
# count. Tags 2 to 6 carry two colours and their geometry ahead of the count.
pack_cmd : Paint.DrawCmd -> List(U32)
pack_cmd = |c| {
	n = u(U64.to_i64_wrap(List.len(c.pts)) // 2)
	if c.tag == 3 {
		List.concat([3, u(c.color)], words(List.concat(List.take_first(c.geom, 3), [c.strength])))
	} else if c.tag >= 2 and c.tag <= 6 {
		List.concat(List.concat(List.concat([u(c.tag), u(c.color), u(c.color2)], words(c.geom)), [n]), words(c.pts))
	} else {
		List.concat([u(c.tag), u(c.color), n], words(c.pts))
	}
}

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

render : Box(Model) -> List(U32)
render = |b| List.join_map(SafariRide.commands(Box.unbox(b)), pack_cmd)

# --- The readouts -------------------------------------------------------------

clock : Box(Model) -> U32
clock = |b| F64.to_u32_wrap(Box.unbox(b).ride.clock)

rider_seg : Box(Model) -> U32
rider_seg = |b| u(Box.unbox(b).ride.rider.segment)

rider_tilt : Box(Model) -> F32
rider_tilt = |b| F64.to_f32_wrap(SafariRide.roll(Box.unbox(b)))

cam_focal : Box(Model) -> F32
cam_focal = |b| {
	m = Box.unbox(b)
	F64.to_f32_wrap(RideFocal.ride_focal(m.world, m.ride.rider))
}

gaze_yaw : Box(Model) -> F32
gaze_yaw = |b| F64.to_f32_wrap(Box.unbox(b).ride.rider.gaze_yaw)

sky_top : Box(Model) -> U32
sky_top = |b| u(SafariRide.sky_top(Box.unbox(b)))

sky_horizon : Box(Model) -> U32
sky_horizon = |b| u(SafariRide.sky_horizon(Box.unbox(b)))

sun_visible : Box(Model) -> U32
sun_visible = |b| if SafariRide.sun(Box.unbox(b)).visible { 1 } else { 0 }

sun_x : Box(Model) -> F32
sun_x = |b| F64.to_f32_wrap(SafariRide.sun(Box.unbox(b)).x)

sun_y : Box(Model) -> F32
sun_y = |b| F64.to_f32_wrap(SafariRide.sun(Box.unbox(b)).y)

sun_scale : Box(Model) -> F32
sun_scale = |b| F64.to_f32_wrap(SafariRide.sun(Box.unbox(b)).scale)

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
program = { init, advance, back, render, probe_frame, probe_expand, clock, rider_seg, rider_tilt, cam_focal, gaze_yaw, sky_top, sky_horizon, sun_visible, sun_x, sun_y, sun_scale, rider_v, truck_lead, truck_v }
