## ThanksgivingApp is the Thanksgiving movie as a value canvas_apps can run.
## A movie is a game that reads only the viewer's keys: Space pauses, Left and
## Right scrub, J skips a second on and R goes back to the start, as in Trick
## or Treat. The movie stops at its last frame and holds there, so a running
## movie and a scrub forward both stop at the end.
import lib.CanvasApp
import lib.Input
import Script
import Thanksgiving

ThanksgivingApp :: [].{

	## The movie's own state is the tick; `paused` is the viewer's.
	Model : { tick : I64, paused : Bool }

	canvas_app : CanvasApp.CanvasApp(ThanksgivingApp.Model)
	canvas_app = {
		size: { width: Thanksgiving.width, height: Thanksgiving.height },
		# The motion is written per tick, so the movie sets the rate.
		frames_a_second: 60,
		init: { tick: 0, paused: False },
		model_at_next_step: |model, input, _dt| step(model, input),
		frame_shapes: |model| Thanksgiving.shapes({ tick: model.tick }),
		sounds: |_model| 0,
		tones: [],
		title: "Thanksgiving",
	}

	## How fast a held arrow scrubs: one tick a tick while paused, four while
	## running, so a nudge is a nudge and a hold is a hunt.
	scrub : Bool -> I64
	scrub = |paused|
		if paused {
			1
		} else {
			4
		}

	step : ThanksgivingApp.Model, Input.Snapshot -> ThanksgivingApp.Model
	step = |model, input| {
		paused =
			if input.key_pressed(KeySpace) {
				!model.paused
			} else {
				model.paused
			}
		speed = scrub(paused)
		moved =
			if input.key_down(KeyRight) {
				model.tick + speed
			} else if input.key_down(KeyLeft) {
				model.tick - speed
			} else if paused {
				model.tick
			} else {
				model.tick + 1
			}
		jumped =
			if input.key_pressed(KeyJ) {
				moved + 60
			} else {
				moved
			}
		tick =
			if input.key_pressed(KeyR) {
				0
			} else {
				Script.held_tick(jumped)
			}
		{ tick, paused }
	}
}

## Space pauses, and a paused movie sits on the frame it was on.
expect {
	held = ThanksgivingApp.step(
		ThanksgivingApp.canvas_app.init,
		Input.none.with_key_pressed(KeySpace),
	)
	held.paused and ThanksgivingApp.step(held, Input.none).tick == held.tick
}

## Space again plays it, and a playing movie moves on by one.
expect {
	playing = ThanksgivingApp.step({ tick: 5, paused: True }, Input.none.with_key_pressed(KeySpace))
	!playing.paused and playing.tick == 6
}

## Right scrubs forward and Left back, one a tick paused and four running;
## Left stops at the beginning rather than before it.
expect ThanksgivingApp.step({ tick: 2, paused: True }, Input.none.with_key_down(KeyRight)).tick == 3
expect ThanksgivingApp.step(
	{ tick: 2, paused: False },
	Input.none.with_key_down(KeyRight),
).tick == 6
expect ThanksgivingApp.step({ tick: 2, paused: True }, Input.none.with_key_down(KeyLeft)).tick == 1
expect ThanksgivingApp.step({ tick: 9, paused: False }, Input.none.with_key_down(KeyLeft)).tick == 5
expect ThanksgivingApp.step({ tick: 0, paused: True }, Input.none.with_key_down(KeyLeft)).tick == 0

## J jumps a second on.
expect ThanksgivingApp.step(
	{ tick: 10, paused: True },
	Input.none.with_key_pressed(KeyJ),
).tick == 70

## R goes back to the top.
expect ThanksgivingApp.step(
	{ tick: 900, paused: False },
	Input.none.with_key_pressed(KeyR),
).tick == 0

## The movie holds at its last frame: running, scrubbing and jumping all stop
## there, and the tick before it still moves on.
expect ThanksgivingApp.step(
	{ tick: Script.end_tick, paused: False },
	Input.none,
).tick == Script.end_tick
expect ThanksgivingApp.step(
	{ tick: Script.end_tick - 1, paused: False },
	Input.none,
).tick == Script.end_tick
expect ThanksgivingApp.step(
	{ tick: Script.end_tick - 2, paused: False },
	Input.none,
).tick == Script.end_tick - 1
expect ThanksgivingApp.step(
	{ tick: Script.end_tick - 10, paused: True },
	Input.none.with_key_pressed(KeyJ),
).tick == Script.end_tick
