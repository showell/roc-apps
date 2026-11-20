## EyePath is where the guest's eye goes through the movie: a list of
## moves, each easing the eye from wherever the last one left it, either by
## a distance or to a spot. Each is named for the shot it ends on, so the
## path reads as a shot list.
import Ease
import Script

EyePath :: [].{

	## Where the eye is at `tick`, in the backyard's metres.
	eye_spot : I64 -> Spot
	eye_spot = |tick| {
		now = Script.held_tick(tick)
		moves.fold(
			seated,
			|spot, move| {
				fraction = Ease.smooth(Ease.ramp(now - move.start, move.frames))
				moved_spot(spot, { goes: move.goes, fraction })
			},
		)
	}
}

Spot : { right : F64, forward : F64, height : F64 }

Move : { start : I64, frames : I64, goes : Going }

# A move goes by a distance, or to a spot.
Going : [By(Spot), To(Spot)]

# The guest's own seat, at the near end of the table.
seated : Spot
seated = { right: -0.4, forward: 0.0, height: 1.15 }

moves : List(Move)
moves = [
	# Eased back and up until the whole table is in view.
	{ start: Script.pull_tick, frames: 180, goes: By({ right: 0.4, forward: -1.8, height: 0.4 }) },
	# Close on the dancer, its head and arms filling the screen.
	{ start: Script.close_up_tick, frames: 60, goes: To({ right: 1.25, forward: 0.15, height: 1.75 }) },
	# Far back and high, over the empty lawn where the copies will stand.
	{ start: Script.wide_tick, frames: Script.section_tick(Multiply) - Script.wide_tick, goes: To(wide) },
	# Up and back a little as the army marches out under the eye.
	{ start: Script.army_tick, frames: Script.march_frames, goes: To({ right: 0.4, forward: -30.0, height: 4.2 }) },
]

wide : Spot
wide = { right: 0.4, forward: -25.5, height: 3.4 }

moved_spot : Spot, { goes : Going, fraction : F64 } -> Spot
moved_spot = |from, { goes, fraction }|
	match goes {
		By(distance) => {
			right: from.right + distance.right * fraction,
			forward: from.forward + distance.forward * fraction,
			height: from.height + distance.height * fraction,
		}
		To(to) => {
			right: from.right + (to.right - from.right) * fraction,
			forward: from.forward + (to.forward - from.forward) * fraction,
			height: from.height + (to.height - from.height) * fraction,
		}
	}

# The eye starts in the guest's seat and is at the wide shot as the first
# copy pops up.
expect EyePath.eye_spot(0) == seated
expect (EyePath.eye_spot(Script.section_tick(Multiply)).forward - wide.forward).abs() < 0.000001
