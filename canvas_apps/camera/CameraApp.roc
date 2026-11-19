## CameraApp is roc-ray's examples/camera as a value canvas_apps can run. The
## rules are in Rules.roc and the drawing is in CameraDraw.roc, so what is left
## here is the canvas size, the frame rate and the title. The app plays no
## tones, because upstream's camera makes no sound.
##
## Nothing in this module mentions a camera. The rules build the camera and the
## drawing uses it, so the seam between them never needs the word.
import lib.CanvasApp
import Rules
import CameraDraw

CameraApp :: [].{
	Model : Rules.World

	canvas_app : CanvasApp.CanvasApp(CameraApp.Model)
	canvas_app = {
		size: { width: 800.0, height: 600.0 },
		frames_a_second: 60,
		init: Rules.start,
		model_at_next_step: |world, input, dt| Rules.step(world, input, dt),
		frame_shapes: |world| CameraDraw.frame_shapes(world),
		sounds: |_world| 0,
		tones: [],
		title: "Camera world",
	}
}
