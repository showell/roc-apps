## SafariApp is the ride as a value the canvas apps can run. It sits between the
## ride and what a runner wants: Tour holds the ride and its history, FrameView
## says what the camera shows, and this module says which keys move it and how
## the camera leans.
##
## The ride plays on its own. Space pauses it. Left steps back through the ride's
## history and Right forward, a frame at a time while paused and faster while it
## runs. J jumps to the next of the route's nineteen segments, and R starts the
## ride again.
import lib.CanvasApp
import lib.Input
import lib.Shapes
import Angle
import Screen
import Tour

SafariApp :: [].{
	Model : { tour : Tour, motion : [Playing, Paused] }

	canvas_app : CanvasApp.CanvasApp(SafariApp.Model)
	canvas_app = {
		size: { width: Screen.width.to_f64(), height: Screen.height.to_f64() },
		# The ride's motion is written per step, and thirty steps a second is the
		# speed it is meant to look like, chosen by eye.
		fps: 30,
		init: initial_model,
		model_at_next_step: CanvasApp.untimed_model_at_next_step(model_at_next_step),
		frame_shapes: |m| frame_shapes(m.tour),
		sounds: |_m| 0,
		tones: [],
		title: "Safari",
	}

	## What to draw, turned by the rider's lean.
	##
	## The whole frame leans, backdrop and all, so the world banks into a turn.
	## That is a camera whose target and offset are both the middle of the
	## screen and whose rotation is the roll, the other way round: a space
	## around everything else.
	frame_shapes : Tour -> List(Shapes.Shape)
	frame_shapes = |tour| {
		view = Tour.frame_view(tour)
		view.framed_shapes(lean_space(view.roll))
	}

	## The space the whole frame leans in, at the camera's `roll`.
	lean_space : Angle.Lean -> Shapes.Space
	lean_space = |roll| {
		centre = { x: Screen.width.to_f64() / 2.0, y: Screen.height.to_f64() / 2.0 }
		World({
			target: centre,
			offset: centre,
			rotation: 0.0 - roll.to_degrees(),
			zoom: 1.0,
		})
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
			steps_a_press = match motion {
				Paused => 1
				Playing => 4
			}
			moved =
				if input.key_down(KeyRight) {
					m.tour.steps_forward(steps_a_press)
				} else if input.key_down(KeyLeft) {
					m.tour.steps_back(steps_a_press)
				} else {
					match motion {
						Paused => m.tour
						Playing => Tour.step_forward(m.tour)
					}
				}
			tour = if input.key_pressed(KeyJ) {
				moved.at_next_segment()
			} else {
				moved
			}
			{ tour, motion }
		}

}

## The ride at its start, playing.
initial_model : SafariApp.Model
initial_model = { tour: Tour.initial, motion: Playing }
