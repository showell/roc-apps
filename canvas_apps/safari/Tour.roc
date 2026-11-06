## Tour is the whole ride, for any platform that draws it. It keeps the
## current instant of the ride and the instants behind it for stepping back, and
## it says what a frame shows in the terms a painter needs: the shapes, the
## camera roll, the two sky colours and the sun. SafariApp turns it into a
## canvas app, with the keys, the pause, and the frame leaned by the roll.
import Angle
import World
import RideInstant
import Sky
import Rider
import CanvasRoll
import RideFocal
import ViewYaw
import Chain
import Lens
import lib.Shapes

## The route, the instant the ride has reached, and the instants before it.
Tour := {
	route : List(World.Segment),
	instant : RideInstant,
	past_instants : List(RideInstant),
}.{

	# How far back a step back can go: 2048 instants, about half the route.
	# The newest are the ones kept.
	past_instants_cap : U64
	past_instants_cap = 2048

	initial : Tour
	initial = { route: World.segments, instant: RideInstant.initial, past_instants: [] }

	step_forward : Tour -> Tour
	step_forward = |tour| {
		finished = Rider.is_finished(tour.instant.rider, tour.route)
		# Dropping one instant per step would copy the whole list every step, so
		# half of it goes at once and the copy falls on one step in a thousand.
		# The list is therefore between half a cap and a cap deep, never empty,
		# and always the most recent instants.
		past_instants =
			if finished {
				[]
			} else if tour.past_instants.len() < past_instants_cap {
				tour.past_instants.append(tour.instant)
			} else {
				tour.past_instants.drop_first(past_instants_cap // 2).append(tour.instant)
			}
		{
			route: tour.route,
			instant: RideInstant.next_or_restart(tour.route, tour.instant),
			past_instants,
		}
	}

	step_back : Tour -> Tour
	step_back = |tour| {
		match tour.past_instants.last() {
			Ok(prev) => {
				route: tour.route,
				instant: prev,
				past_instants: tour.past_instants.drop_last(1),
			}
			Err(_) => tour
		}
	}

	## The frame's shapes in paint order. A bird is sorted by depth with
	## everything else, so a nearer tree hides it.
	shapes : Tour -> List(Shapes.Shape)
	shapes = |tour| RideInstant.shapes(tour.route, tour.instant)

	# The camera roll: the whole frame, backdrop and shapes, turns
	# by minus this about the screen's centre.
	roll : Tour -> Angle.Lean
	roll = |tour| CanvasRoll.rider_roll(tour.instant.rider.lean)

	# The sky at the top of the frame and at the horizon, as 0xRRGGBB.
	sky_top_color : Tour -> I64
	sky_top_color = |tour| Sky.sky_top_color(tour.instant.clock)

	sky_horizon_color : Tour -> I64
	sky_horizon_color = |tour| Sky.sky_horizon_color(tour.instant.clock)

	sun : Tour -> Sky.SunSighting
	sun = |tour| RideInstant.sun(tour.route, tour.instant)
}
