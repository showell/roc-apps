## SafariApp is the ride as a value the canvas apps can run. It sits between the
## ride and what a runner wants: Tour holds the ride and its history, FrameView
## says what the camera shows, and this module says which keys move it.
##
## The ride plays on its own. Space pauses it. Left steps back through the ride's
## history and Right forward, a frame at a time while paused and faster while it
## runs. J jumps to the next of the route's segments, and R starts the
## ride again.
import lib.CanvasApp
import lib.Input
import FrameView
import Screen
import Steps
import Tour

SafariApp :: [].{
	Model : { tour : Tour, motion : [Playing, Paused] }

	canvas_app : CanvasApp.CanvasApp(SafariApp.Model)
	canvas_app = {
		size: { width: Screen.width.to_f64(), height: Screen.height.to_f64() },
		# The ride's motion is written per step, and thirty steps a second is the
		# speed it is meant to look like, chosen by eye.
		frames_a_second: 30,
		init: initial_model,
		model_at_next_step: CanvasApp.untimed_model_at_next_step(model_at_next_step),
		frame_shapes: |m| FrameView.frame_view_at(m.tour.route(), m.tour.instant()).leaned_shapes(),
		sounds: |_m| 0,
		tones: [],
		title: "Safari",
	}
}

model_at_next_step : SafariApp.Model, Input.Snapshot -> SafariApp.Model
model_at_next_step = |m, input|
	if input.key_pressed(KeyR) {
		initial_model
	} else {
		motion = if input.key_pressed(KeySpace) {
			match m.motion {
				Playing => Paused
				Paused => Playing
			}
		} else {
			m.motion
		}
		steps_a_frame = match motion {
			Paused => Steps.one_step
			Playing => Steps.of(4)
		}
		moved =
			if input.key_down(KeyRight) {
				m.tour.steps_forward(steps_a_frame)
			} else if input.key_down(KeyLeft) {
				m.tour.steps_back(steps_a_frame)
			} else {
				match motion {
					Paused => m.tour
					Playing => m.tour.step_forward()
				}
			}
		tour = if input.key_pressed(KeyJ) {
			moved.at_next_segment()
		} else {
			moved
		}
		{ tour, motion }
	}

## The ride at its start, playing.
initial_model : SafariApp.Model
initial_model = { tour: Tour.initial, motion: Playing }
