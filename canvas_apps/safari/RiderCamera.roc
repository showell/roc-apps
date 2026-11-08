## The camera the ride is seen through at one instant, worked out once a frame
## from the rider: where it stands, which way it faces, its lens, and its roll.
## It turns with the rider's gaze, and a little with the motorcycle's lean, as a
## rider's head turns into a bend.
import Angle
import Animation
import Attention
import Fraction
import Geom
import Lens
import Pipeline
import Pixels
import Rider
import Route
import RoutePlace

## Where the camera stands, which way it faces, its lens and its roll. It is
## nominal, not opaque: other modules read its fields, and Sun and Skyline
## take it as an open record of the heading and the lens.
RiderCamera := {
	## Where the camera stands on the route, which is where the rider is.
	route_place : RoutePlace,

	## Which way the camera faces, as a turn from its segment's axis.
	yaw : Angle.Turn,

	## The camera's bearing in the world.
	heading : Angle.Bearing,

	## The lens's focal length.
	focal_length : Pixels,

	## The roll the camera is held at: the whole frame turns by minus this about
	## the screen's centre.
	roll : Angle.Lean,
}.{

	## The camera for `rider` on `route`, with the encounter on their segment at
	## `encounter_stage`. Its heading is the bearing the rider's segment sets off on,
	## turned by the camera's yaw.
	of : Rider, { route : Route, encounter_stage : Animation.Stage } -> RiderCamera
	of = |rider, { route, encounter_stage }| {
		route_place = rider.motorcycle.route_place
		yaw = rider.motorcycle.yaw.plus(rider.head_yaw())
		{
			route_place,
			yaw,
			heading: route.bearing_of(route_place.segment_index).plus(yaw),
			focal_length: ride_focal(rider, { route, encounter_stage }),
			roll: rider_roll(rider.motorcycle.lean),
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

	## This camera as a sighting takes it: its vantage and its lens.
	sighting_camera : RiderCamera -> Pipeline.SightingCamera
	sighting_camera = |camera| { vantage: camera.vantage(), focal_length: camera.focal_length }

	## The lean that widens the view all it can. Nothing holds the bike to it:
	## a deeper lean just widens the view no further.
	full_lean : Angle.Lean
	full_lean = Angle.Lean.degrees(20.0)
}

## A lean smaller than this leaves the canvas level.
roll_deadband : Angle.Lean
roll_deadband = Angle.Lean.radians(0.001)

## How far the canvas rolls with the rider's `lean`: not at all inside the
## deadband, and with the lean past it.
rider_roll : Angle.Lean -> Angle.Lean
rider_roll = |lean|
	if lean.abs() < roll_deadband {
		Angle.upright
	} else {
		lean
	}

## The camera's focal length for where the rider is and how they ride. The
## view widens as the rider leans, and as the rider's attention is caught, by
## an encounter on the road or by a look to the side.
ride_focal : Rider, { route : Route, encounter_stage : Animation.Stage } -> Pixels
ride_focal = |rider, { route, encounter_stage }| {
	attention = rider.attention({ route, encounter_stage })
	focal_length_for({ lean: rider.motorcycle.lean, attention })
}

## The focal length the camera uses: the shorter of the two, which
## gives the wider view. A lean to either side widens it alike.
focal_length_for : { lean : Angle.Lean, attention : Attention } -> Pixels
focal_length_for = |{ lean, attention }| {
	lean_fraction = Fraction.clamp(lean.abs().ratio_to(RiderCamera.full_lean))
	for_lean = focal_length_for_lean(lean_fraction)
	for_attention = focal_length_for_attention(attention)
	if for_lean < for_attention {
		for_lean
	} else {
		for_attention
	}
}

## How much of the resting focal length is left at `RiderCamera.full_lean`.
focal_length_share_at_full_lean : Fraction
focal_length_share_at_full_lean = Fraction.of(0.35)

## How much of the resting focal length is left at an attention of 1. It is no
## minimum, because a cat in the road holds the eye harder than that.
focal_length_share_at_full_attention : Fraction
focal_length_share_at_full_attention = Fraction.of(0.61)

## The focal length for a lean, from 0 (upright) to 1 (`RiderCamera.full_lean`).
focal_length_for_lean : Fraction -> Pixels
focal_length_for_lean = |lean_fraction| {
	lean = lean_fraction.to_f64()
	lost_at_full_lean = focal_length_share_at_full_lean.complement().to_f64()
	Lens.resting_focal_length.times(1.0 - lost_at_full_lean * lean * lean)
}

## The focal length for the rider's attention.
focal_length_for_attention : Attention -> Pixels
focal_length_for_attention = |attention| {
	lost_at_full_attention = focal_length_share_at_full_attention.complement().to_f64()
	Lens.resting_focal_length.times(1.0 - lost_at_full_attention * attention.to_f64())
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
	].all(|(lean, want)| is_close(focal_length_for_lean(Fraction.of(lean)).to_f64(), want))

expect
	[
		(0.0, 685.5110432362151),
		(0.5, 551.8363898051531),
		(1.0, 418.16173637409116),
		(1.5, 284.4870829430293),
	].all(
		|(strength, want)| {
			got = focal_length_for_attention(Attention.of(strength)).to_f64()
			is_close(got, want)
		},
	)

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
			got = focal_length_for({
				lean: Angle.Lean.degrees(lean * 20.0),
				attention: Attention.of(strength),
			})
			is_close(got.to_f64(), want)
		},
	)

# Inside the deadband the canvas stays level; at its edge and past it, either
# way, the canvas rolls with the rider.
expect
	[
		(0.0, 0.0),
		(0.00001, 0.0),
		(0.0005, 0.0),
		(-0.0005, 0.0),
		(0.0009999, 0.0),
		(0.001, 0.001),
		(-0.001, -0.001),
		(0.002, 0.002),
		(-0.002, -0.002),
		(0.35, 0.35),
		(-0.42, -0.42),
	].all(|(lean, roll)| rider_roll(Angle.Lean.radians(lean)).to_radians() == roll)
