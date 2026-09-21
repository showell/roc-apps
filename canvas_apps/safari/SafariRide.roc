# SafariRide -- the screensaver between frames, and what a frame shows, for
# any platform that draws it.
#
# Hand-written, beside the emitted chapters it calls. It holds what the Codex
# program cannot -- the ride between frames, a history for stepping back --
# and says what a frame is in the terms a painter needs: the draw commands
# after blit expansion, the camera roll, the two sky colours and the sun.
# SafariApp turns it into a canvas app: the keys, the pause, and the frame
# leaned by the roll.
import World
import Safari
import Blit
import Paint
import Sky
import Rider
import CanvasRoll
import RideFocal
import ViewYaw
import Frame
import Lens
import RocBird

SafariRide :: [].{
	Model : { world : List(World.Segment), ride : Safari.Ride, hist : List(Safari.Ride) }

	# How far back a step back can go: 2048 frames, about half the route.
	#
	# **IT KEEPS THE NEWEST, WHICH IT DID NOT USED TO.** Once the list was
	# full, `advance` simply stopped recording -- so the history was the FIRST
	# 2048 frames, and a step back from frame 3000 landed on 2047. Pressing J
	# a few times fills it in a moment, which is how anyone would find this.
	hist_cap : U64
	hist_cap = 2048

	init : SafariRide.Model
	init = { world: World.build_world, ride: Safari.ride_initial, hist: [] }

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
			} else if List.len(m.hist) < hist_cap {
				List.append(m.hist, m.ride)
			} else {
				List.append(List.drop_first(m.hist, hist_cap // 2), m.ride)
			}
		{ world: m.world, ride: Safari.ride_next(m.world, m.ride), hist: hist }
	}

	back : SafariRide.Model -> SafariRide.Model
	back = |m| {
		match List.last(m.hist) {
			Ok(prev) => { world: m.world, ride: prev, hist: List.drop_last(m.hist, 1) }
			Err(_) => m
		}
	}

	# The frame's commands in paint order, expanded as the blitter reads them.
	#
	# **THE BIRD IS NOT PASTED ON THE END ANY MORE.** It used to be: the frame,
	# then the Roc flair concatenated after it, which put a bird in front of
	# every tree nearer than its own. It is collected and sorted with the rest
	# now -- Render.collect gathers it, DepthSort orders it, ItemDraw draws it.
	commands : SafariRide.Model -> List(Paint.DrawCmd)
	commands = |m| Blit.blit_expand(Safari.ride_frame(m.world, m.ride), 0)

	# The camera roll in radians: the whole frame, backdrop and commands, turns
	# by minus this about the screen's centre.
	roll : SafariRide.Model -> F64
	roll = |m| CanvasRoll.rider_roll(m.ride.rider)

	# The sky at the top of the frame and at the horizon, as 0xRRGGBB.
	sky_top : SafariRide.Model -> I64
	sky_top = |m| Sky.sky_color(m.ride.clock)

	sky_horizon : SafariRide.Model -> I64
	sky_horizon = |m| Sky.horizon_color(m.ride.clock)

	sun : SafariRide.Model -> Sky.SunPos
	sun = |m| Safari.ride_sun(m.world, m.ride)
}
