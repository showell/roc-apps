## Dinner says what happens around the party at one table that is not the
## guests: how bright each string light is, how far the banner has dropped
## and how long the leaves have blown, and how the dancer moves. Guests and
## Serving say where the guests and their dishes are. It asks Script when
## the beats are. Every drawing module is handed numbers, so none of them is
## re-timed when the cut changes.
##
## Once everyone is sat, the lights blink on down the table, each guest's
## eyes lighting with the bulb above its place. A fifth robot walks in and
## dances the routine, while the others turn their heads to watch.
import lib.Eye
import Dancer
import Ease
import Lights
import Moves
import Routine
import Script

Dinner :: [].{

	## Where the dancer's feet are: walking in from the right, then on its spot
	## beside the near end of the table.
	dancer_feet : I64 -> Eye.At
	dancer_feet = |tick| {
		right: dancer_right(Script.held_tick(tick)),
		forward: 1.4,
		height: 0.0,
	}

	## How the dancer stands at `tick`: arms swinging in steps on the walk in,
	## then the routine. Its antenna boings after the wink.
	dancer_pose : I64 -> Dancer.Pose
	dancer_pose = |tick| {
		now = Script.held_tick(tick)
		walked = dancer_from - dancer_right(now)
		phase = walked * F64.tau / 0.55
		pace = ((dancer_right(now - 5) - dancer_right(now)) / 0.09).min(1.0)
		rest = Moves.rest
		move =
			if now < Script.dance_tick {
				clicks = (phase.sin() * 2.0 + 2.5).to_i64_wrap() - 2
				swing = 0.18 * I64.to_f64(clicks) * pace
				{
					..rest,
					left_upper: rest.left_upper - swing,
					right_upper: rest.right_upper - swing,
				}
			} else {
				Routine.move_at(now - Script.dance_tick)
			}
		{
			left_upper: move.left_upper,
			left_fore: move.left_fore,
			right_upper: move.right_upper,
			right_fore: move.right_fore,
			head: move.head,
			pop: move.pop,
			turn: move.turn,
			bounce: move.bounce,
			wink: move.wink,
			antenna_sway: Ease.boing(now - Script.wink_tick - 16),
			phase,
			stride: pace,
		}
	}

	## How bright each bulb is, nearest the guest first.
	bulb_glows : I64 -> List(F64)
	bulb_glows = |tick| {
		now = Script.held_tick(tick)
		var $out = List.with_capacity(Lights.bulb_count)
		for k in 0..<Lights.bulb_count {
			$out = $out.append(bulb_glow(k, now))
		}
		$out
	}

	## How far the banner has dropped in, from 0 to 1.
	banner_drop : I64 -> F64
	banner_drop = |tick| {
		drop_progress = Ease.ramp(Script.held_tick(tick) - Script.banner_tick, banner_frames)
		1.0 - (1.0 - drop_progress) * (1.0 - drop_progress)
	}

	## A bulb's brightness at `tick`: off until its turn, then a blink, on,
	## dim, on.
	bulb_glow : U64, I64 -> F64
	bulb_glow = |index, tick| {
		since = tick - (Script.lights_tick + bulb_gap * index.to_i64_wrap())
		if since < 0 {
			0.0
		} else if since < 3 {
			1.0
		} else if since < 6 {
			0.25
		} else {
			1.0
		}
	}

	## How many seconds the leaves have been blowing; negative before.
	gust_seconds : I64 -> F64
	gust_seconds = |tick| (Script.held_tick(tick) - Script.gust_tick).to_f64() / 60.0
}

banner_frames : I64
banner_frames = 60

bulb_gap : I64
bulb_gap = 7

# The dancer walks in from the right, after the banner is up, to a spot
# beside the near end of the table where the pulled-back eye sees it whole.
dancer_from : F64
dancer_from = 4.5

dancer_right : I64 -> F64
dancer_right = |tick| {
	walk_progress = Ease.smooth(
		Ease.ramp(tick - Script.walk_in_tick, Script.dance_tick - 6 - Script.walk_in_tick),
	)
	dancer_from + (1.25 - dancer_from) * walk_progress
}

# No bulb is lit before the lights start, and every bulb is lit at the end.
expect Dinner.bulb_glows(Script.lights_tick - 1).all(|glow| glow == 0.0)
expect Dinner.bulb_glows(Script.end_tick).all(|glow| glow == 1.0)
