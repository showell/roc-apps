## SafariRide is the screensaver between frames, for any platform that draws
## it. It keeps the ride and a history for stepping back, and it says what a
## frame shows in the terms a painter needs: the shapes, the camera roll, the
## two sky colours and the sun. SafariApp turns it into a canvas app, with the
## keys, the pause, and the frame leaned by the roll.
import Angle
import World
import Safari
import Sky
import Rider
import CanvasRoll
import RideFocal
import ViewYaw
import Frame
import Lens
import lib.Shapes

SafariRide :: [].{
	Model : {
		world : List(World.Segment),
		ride : Safari.Ride,
		hist : List(Safari.Ride),
	}

	# How far back a step back can go: 2048 frames, about half the route.
	#
	# **IT KEEPS THE NEWEST, WHICH IT DID NOT USED TO.** Once the list was
	# full, `advance` simply stopped recording -- so the history was the FIRST
	# 2048 frames, and a step back from frame 3000 landed on 2047. Pressing J
	# a few times fills it in a moment, which is how anyone would find this.
	hist_cap : U64
	hist_cap = 2048

	init : SafariRide.Model
	init = {
		world: World.segments,
		ride: Safari.ride_initial,
		hist: [],
	}

	advance : SafariRide.Model -> SafariRide.Model
	advance = |m| {
		finished = Rider.is_finished(m.ride.rider, m.world)
		# Dropping one frame per step would copy the whole list every step, so
		# half of it goes at once and the copy falls on one step in a thousand.
		# The history is therefore between half a cap and a cap deep, never
		# empty, and always the most recent frames.
		hist =
			if finished {
				[]
			} else if m.hist.len() < hist_cap {
				m.hist.append(m.ride)
			} else {
				m.hist.drop_first(hist_cap // 2).append(m.ride)
			}
		{
			world: m.world,
			ride: Safari.ride_next(m.world, m.ride),
			hist: hist,
		}
	}

	back : SafariRide.Model -> SafariRide.Model
	back = |m| {
		match m.hist.last() {
			Ok(prev) => {
				world: m.world,
				ride: prev,
				hist: m.hist.drop_last(1),
			}
			Err(_) => m
		}
	}

	## The frame's shapes in paint order. A bird is sorted by depth with
	## everything else, so a nearer tree hides it.
	shapes : SafariRide.Model -> List(Shapes.Shape)
	shapes = |m| Safari.ride_frame(m.world, m.ride)

	# The camera roll: the whole frame, backdrop and shapes, turns
	# by minus this about the screen's centre.
	roll : SafariRide.Model -> Angle.Lean
	roll = |m| CanvasRoll.rider_roll(m.ride.rider)

	# The sky at the top of the frame and at the horizon, as 0xRRGGBB.
	sky_top : SafariRide.Model -> I64
	sky_top = |m| Sky.sky_color(m.ride.clock)

	sky_horizon : SafariRide.Model -> I64
	sky_horizon = |m| Sky.horizon_color(m.ride.clock)

	sun : SafariRide.Model -> Sky.SunPos
	sun = |m| Safari.ride_sun(m.world, m.ride)
}
