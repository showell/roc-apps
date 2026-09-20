# TrickOrTreatGame -- the Halloween movie as a value the arcade can run.
#
# **A MOVIE IS A GAME THAT DOES NOT READ ITS KEYBOARD.** That is the whole of
# what this file had to work out. `Game` and `Movie` asked for the same size,
# rate, init, frame and title; what `Movie` had besides were `back`, `skip`,
# `scene`, `scenes`, `roll` and `clock`, and every one of those is a thing a
# PLAYER did with a movie rather than a thing a movie is:
#
#   back / skip    scrubbing, which is Left, Right and Enter here
#   scene / scenes a place to skip to, which Halloween never had (it has one)
#   clock          a number for naming a screenshot, which no runner here takes
#   roll           a camera turned, which is `Camera.with_rotation` now and a
#                  `View` mark in the frame -- Halloween does not turn, so it
#                  says nothing and nothing is emitted
#
# So the six fields became five keys and a `paused` flag, and a movie needs no
# seam of its own. The old player owned the scrubbing and each runner had to
# implement it; here it is in the movie, written once, and it runs on a page
# and on roc-ray without either knowing a movie from a game.
import lib.Game
import lib.Input
import Halloween

TrickOrTreatGame :: [].{
	## The movie's own state is the tick; `paused` is the viewer's.
	Model : { tick : I64, paused : Bool }

	game : Game.Game(TrickOrTreatGame.Model)
	game = {
		size: { width: Halloween.width, height: Halloween.height },
		# **THE MOVIE SETS THE RATE**, as it always did: its motion is written
		# per tick, so a runner that paces to anything else plays it at the
		# wrong speed.
		fps: 60,
		init: { tick: 0, paused: Bool.False },
		advance: |m, input, _dt| step(m, input),
		frame: |m| Halloween.shapes({ tick: m.tick }),
		# A movie makes no sound. This is the second program here with none,
		# and the page draws no speaker for it.
		sounds: |_m| 0,
		tones: [],
		title: "Trick or Treat",
	}

	## How fast a held arrow scrubs: a second of film a second while paused,
	## four times that while it is running, so a nudge is a nudge and a hold
	## is a hunt.
	scrub : Bool -> I64
	scrub = |paused| if paused { 1 } else { 4 }

	step : TrickOrTreatGame.Model, Input.Snapshot -> TrickOrTreatGame.Model
	step = |m, input| {
		paused = if input.key_pressed(KeySpace) { !m.paused } else { m.paused }
		speed = scrub(paused)
		# Right and Left scrub whether it is running or not; with neither
		# held, a paused movie sits still and a running one advances by one.
		moved =
			if input.key_down(KeyRight) {
				m.tick + speed
			} else if input.key_down(KeyLeft) {
				m.tick - speed
			} else if paused {
				m.tick
			} else {
				m.tick + 1
			}
		# Enter is the old `skip`: a second on, which for a movie with one
		# scene is what skipping to the next one meant.
		jumped = if input.key_pressed(KeyEnter) { moved + 60 } else { moved }
		tick = if input.key_pressed(KeyR) { 0 } else if jumped < 0 { 0 } else { jumped }
		{ tick, paused }
	}
}

## Space pauses, and a paused movie sits on the frame it was on.
expect {
    held = TrickOrTreatGame.step(TrickOrTreatGame.game.init, Input.none.with_key_pressed(KeySpace))
    held.paused and TrickOrTreatGame.step(held, Input.none).tick == held.tick
}

## Left scrubs backwards and stops at the beginning rather than before it.
expect TrickOrTreatGame.step({ tick: 2, paused: Bool.True }, Input.none.with_key_down(KeyLeft)).tick == 1
expect TrickOrTreatGame.step({ tick: 0, paused: Bool.True }, Input.none.with_key_down(KeyLeft)).tick == 0

## Enter jumps a second on, which is what `skip` did.
expect TrickOrTreatGame.step({ tick: 10, paused: Bool.True }, Input.none.with_key_pressed(KeyEnter)).tick == 70

## R goes back to the top.
expect TrickOrTreatGame.step({ tick: 900, paused: Bool.False }, Input.none.with_key_pressed(KeyR)).tick == 0
