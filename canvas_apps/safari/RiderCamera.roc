## The camera the ride is seen through at one instant, worked out once a frame
## from the rider: where it stands, which way it faces, its lens, and its roll.
## It turns with the rider's gaze, and a little with the motorcycle's lean, as a
## rider's head turns into a bend.
import Angle
import Attention
import EncounterPlan
import CanvasRoll
import EncounterReaction
import Fraction
import Gaze
import Geom
import Lens
import Pixels
import RiderState
import Route
import RoutePlace

## Where the camera stands, which way it faces, its lens and its roll. It is
## nominal, not opaque: other modules read its fields, and Sun and Mountains
## take it as an open record of the heading and the lens.
RiderCamera := {
	## Where the camera stands on the route, which is where the rider is.
	route_place : RoutePlace,

	## Which way the camera faces, as a turn from its segment's axis.
	yaw : Angle.Turn,

	## The camera's bearing in the world.
	heading : Angle.Bearing,

	## The lens's focal length.
	cam_focal : Pixels,

	## The roll the camera is held at: the whole frame turns by minus this about
	## the screen's centre.
	roll : Angle.Lean,
}.{

	## The camera for `rider` on `route`, with the encounter on their segment at
	## `encounter_timing`. Its heading is the bearing the rider's segment sets off on,
	## turned by the camera's yaw.
	of : RiderState, { route : Route, encounter_timing : EncounterPlan.Timing } -> RiderCamera
	of = |rider, { route, encounter_timing }| {
		route_place = rider.motorcycle.route_place
		yaw = rider.motorcycle.yaw.plus(view_yaw_for(rider))
		{
			route_place,
			yaw,
			heading: route.bearing_of(route_place.segment_index).plus(yaw),
			cam_focal: ride_focal(rider, { route, encounter_timing }),
			roll: CanvasRoll.rider_roll(rider.motorcycle.lean),
		}
	}

	## Where this camera stands on its segment, and which way it faces, as the
	## projection onto the screen takes them.
	vantage : RiderCamera -> Geom.Vantage
	vantage = |camera| {
		along: camera.route_place.along,
		across: camera.route_place.across,
		yaw: camera.yaw,
	}

	## The lean that widens the view all it can. Nothing holds the bike to it:
	## a deeper lean just widens the view no further.
	full_lean : Angle.Lean
	full_lean = Angle.Lean.degrees(20.0)
}

## How far the head turns for each radian of lean.
head_turn_per_lean : F64
head_turn_per_lean = 0.15

## The camera's turn from the way the motorcycle points.
view_yaw_for : RiderState -> Angle.Turn
view_yaw_for = |s| s.eyes.gaze_yaw.plus(s.motorcycle.lean.steer(head_turn_per_lean))

## The camera's focal length for where the rider is and how they ride. The
## view widens as the rider leans, and as the rider's attention is caught, by
## an encounter on the road or by a look to the side.
ride_focal : RiderState, { route : Route, encounter_timing : EncounterPlan.Timing } -> Pixels
ride_focal = |rider, { route, encounter_timing }| {
	seg = rider.motorcycle.route_place.segment_on(route)
	attention =
		EncounterReaction.encounter_attention(seg, encounter_timing)
			.max(Gaze.gaze_attention(rider.eyes.look_depth))
	focal_for({ lean: rider.motorcycle.lean, attention })
}

## The focal length the camera uses: the shorter of the two, which
## gives the wider view. A lean to either side widens it alike.
focal_for : { lean : Angle.Lean, attention : Attention } -> Pixels
focal_for = |{ lean, attention }| {
	lean_fraction = Fraction.clamp(lean.abs().portion(RiderCamera.full_lean))
	for_lean = focal_for_lean(lean_fraction)
	for_attention = focal_for_attention(attention)
	if for_lean < for_attention {
		for_lean
	} else {
		for_attention
	}
}

## How much of the resting focal length is left at `RiderCamera.full_lean`.
focal_factor_at_full_lean : Fraction
focal_factor_at_full_lean = Fraction.of(0.35)

## How much of the resting focal length is left at an attention of 1. It is no
## minimum, because a cat in the road holds the eye harder than that.
focal_factor_at_full_attention : Fraction
focal_factor_at_full_attention = Fraction.of(0.61)

## The focal length for a lean, from 0 (upright) to 1 (`RiderCamera.full_lean`).
focal_for_lean : Fraction -> Pixels
focal_for_lean = |lean_fraction| {
	lean = lean_fraction.to_f64()
	Lens.resting_focal.times(1.0 - focal_factor_at_full_lean.less().to_f64() * lean * lean)
}

## The focal length for the rider's attention.
focal_for_attention : Attention -> Pixels
focal_for_attention = |attention| {
	lost_at_full_attention = focal_factor_at_full_attention.less().to_f64()
	Lens.resting_focal.times(1.0 - lost_at_full_attention * attention.to_f64())
}

## Whether `got` is within 1e-9 of `want`, scaled up by a want past 1.
is_close : F64, F64 -> Bool
is_close = |got, want| (got - want).abs() <= 0.000000001 * want.abs().max(1.0)

expect
	[
		(0.0, 685.5110432362151),
		(0.25, 657.6621571047439),
		(0.5, 574.1154987103301),
		(0.75, 434.8710680529739),
		(1.0, 239.92886513267527),
	].all(|(lean, want)| is_close(focal_for_lean(Fraction.of(lean)).to_f64(), want))

expect
	[
		(0.0, 685.5110432362151),
		(0.5, 551.8363898051531),
		(1.0, 418.16173637409116),
		(1.5, 284.4870829430293),
	].all(|(strength, want)| is_close(focal_for_attention(Attention.of(strength)).to_f64(), want))

expect
	[
		((0.0, 0.0), 685.5110432362151),
		((1.0, 0.0), 239.92886513267527),
		((0.0, 1.0), 418.16173637409116),
		((0.5, 0.3), 574.1154987103301),
		((0.9, 1.4), 311.2220136292417),
		((0.6, 0.5), 525.1014591189407),
	].all(
		|((lean, strength), want)| {
			got = focal_for({
				lean: Angle.Lean.degrees(lean * 20.0),
				attention: Attention.of(strength),
			})
			is_close(got.to_f64(), want)
		},
	)

# With no lean, the camera turns from the way the motorcycle points exactly as
# far as the rider looks.
expect {
	gaze_yaw = Angle.Turn.radians(0.375)
	upright = { ..RiderState.initial.motorcycle, lean: Angle.Lean.radians(0.0) }
	eyes = { ..RiderState.initial.eyes, gaze_yaw }
	looking = { ..RiderState.initial, motorcycle: upright, eyes }
	view_yaw_for(looking) == gaze_yaw
}
