## The camera the ride is seen through at one instant, worked out once a frame
## from the rider: where it stands, which way it faces, its lens, and its roll.
## It turns with the rider's gaze, and a little with the motorcycle's lean, as a
## rider's head turns into a bend.
import Angle
import EncounterPlan
import CanvasRoll
import EncounterReaction
import Gaze
import Geom
import Lens
import Pixels
import RiderState
import Route
import RoutePlace

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
	Lens.focal_for({ lean: rider.motorcycle.lean, attention })
}

## A rider leaning `lean`, looking `gaze_yaw` from the way the motorcycle
## points.
rider : { lean : Angle.Lean, gaze_yaw : Angle.Turn } -> RiderState
rider = |{ lean, gaze_yaw }| {
	..RiderState.initial,
	motorcycle: { ..RiderState.initial.motorcycle, lean },
	eyes: { ..RiderState.initial.eyes, gaze_yaw },
}

expect {
	leaning = Angle.Lean.radians
	looking = Angle.Turn.radians
	[
		({ lean: leaning(0.0), gaze_yaw: looking(0.0) }, 0.0),
		({ lean: leaning(0.125), gaze_yaw: looking(0.375) }, 0.39375),
		({ lean: leaning(0.5), gaze_yaw: looking(-0.25) }, -0.175),
		({ lean: leaning(-0.75), gaze_yaw: looking(0.125) }, 0.012500000000000011),
		({ lean: leaning(1.25), gaze_yaw: looking(0.0) }, 0.1875),
	].all(|(look, yaw)| view_yaw_for(rider(look)).to_radians() == yaw)
}
