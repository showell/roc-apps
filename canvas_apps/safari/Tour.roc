## Tour is the whole journey, for any platform that draws it. It keeps the
## current moment of the ride and the moments behind it for stepping back, and
## it says what a frame shows in the terms a painter needs: the shapes, the
## camera roll, the two sky colours and the sun. SafariApp turns it into a
## canvas app, with the keys, the pause, and the frame leaned by the roll.
import Angle
import World
import RideMoment
import Sky
import Rider
import CanvasRoll
import RideFocal
import ViewYaw
import Frame
import Lens
import lib.Shapes

## The route, the moment the ride has reached, and the moments before it.
Tour := {
	world : List(World.Segment),
	moment : RideMoment,
	past_moments : List(RideMoment),
}.{

	# How far back a step back can go: 2048 moments, about half the route.
	# The newest are the ones kept.
	past_moments_cap : U64
	past_moments_cap = 2048

	init : Tour
	init = {
		world: World.segments,
		moment: RideMoment.initial,
		past_moments: [],
	}

	advance : Tour -> Tour
	advance = |tour| {
		finished = Rider.is_finished(tour.moment.rider, tour.world)
		# Dropping one moment per step would copy the whole list every step, so
		# half of it goes at once and the copy falls on one step in a thousand.
		# The list is therefore between half a cap and a cap deep, never empty,
		# and always the most recent moments.
		past_moments =
			if finished {
				[]
			} else if tour.past_moments.len() < past_moments_cap {
				tour.past_moments.append(tour.moment)
			} else {
				tour.past_moments.drop_first(past_moments_cap // 2).append(tour.moment)
			}
		{
			world: tour.world,
			moment: RideMoment.next(tour.world, tour.moment),
			past_moments,
		}
	}

	back : Tour -> Tour
	back = |tour| {
		match tour.past_moments.last() {
			Ok(prev) => {
				world: tour.world,
				moment: prev,
				past_moments: tour.past_moments.drop_last(1),
			}
			Err(_) => tour
		}
	}

	## The frame's shapes in paint order. A bird is sorted by depth with
	## everything else, so a nearer tree hides it.
	shapes : Tour -> List(Shapes.Shape)
	shapes = |tour| RideMoment.frame(tour.world, tour.moment)

	# The camera roll: the whole frame, backdrop and shapes, turns
	# by minus this about the screen's centre.
	roll : Tour -> Angle.Lean
	roll = |tour| CanvasRoll.rider_roll(tour.moment.rider.tilt)

	# The sky at the top of the frame and at the horizon, as 0xRRGGBB.
	sky_top : Tour -> I64
	sky_top = |tour| Sky.sky_color(tour.moment.clock)

	sky_horizon : Tour -> I64
	sky_horizon = |tour| Sky.horizon_color(tour.moment.clock)

	sun : Tour -> Sky.SunPos
	sun = |tour| RideMoment.sun(tour.world, tour.moment)
}
