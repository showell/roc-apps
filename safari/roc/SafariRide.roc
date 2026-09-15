# SafariRide -- the screensaver between frames, and what a frame shows, for
# any platform that draws it.
#
# Hand-written, beside the emitted chapters it calls. It holds what the Codex
# program cannot -- the ride between frames, a history for stepping back --
# and says what a frame is in the terms a painter needs: the draw commands
# after blit expansion, the camera roll, the two sky colours and the sun.
# SafariApp boxes the model for the wasm page and packs the commands into the
# blitter's words; ray/apps/safari paints them on roc-ray.
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

	# The shim's ring: 2048 frames of history, about half the route.
	hist_cap : U64
	hist_cap = 2048

	init : SafariRide.Model
	init = { world: World.build_world, ride: Safari.ride_initial, hist: [] }

	advance : SafariRide.Model -> SafariRide.Model
	advance = |m| {
		finished = Rider.is_finished(m.ride.rider, m.world)
		hist = if finished { [] } else if List.len(m.hist) < hist_cap { List.append(m.hist, m.ride) } else { m.hist }
		{ world: m.world, ride: Safari.ride_next(m.world, m.ride), hist: hist }
	}

	back : SafariRide.Model -> SafariRide.Model
	back = |m| {
		match List.last(m.hist) {
			Ok(prev) => { world: m.world, ride: prev, hist: List.drop_last(m.hist, 1) }
			Err(_) => m
		}
	}

	# The frame's commands in paint order, expanded as the blitter reads them:
	# the Codex frame, then the Roc flair, a bird on the fifth tree on the right
	# of every segment (RocBird), appended so it paints on top.
	commands : SafariRide.Model -> List(Paint.DrawCmd)
	commands = |m| {
		s = m.ride.rider
		cf = RideFocal.ride_focal(m.world, s)
		birds = RocBird.draw_all(m.world, Frame.build_chain(m.world, s.segment), ViewYaw.pose_for(m.world, s), cf, Lens.camera_w)
		Blit.blit_expand(List.concat(Safari.ride_frame(m.world, m.ride), birds), 0)
	}

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
