# CameraApp -- roc-ray's examples/camera as a value canvas_apps can run.
#
# Hand-written, and the shortest of these yet: the rules are Rules.roc and the
# drawing is CameraDraw.roc, so what is left is the size, the rate and the
# name. There are no tones -- upstream's camera makes no sound, and a game with
# none is the case the page's speaker widget had never been handed.
#
# **NOTHING HERE MENTIONS A CAMERA.** The camera is built inside the rules and
# spent inside the drawing; the seam did not have to learn the word.
import lib.CanvasApp
import Rules
import CameraDraw

CameraApp :: [].{
	Model : Rules.World

	canvas_app : CanvasApp.CanvasApp(CameraApp.Model)
	canvas_app = {
		size: { width: 800.0, height: 600.0 },
		fps: 60,
		init: Rules.start,
		advance: |m, input, dt| Rules.step(m, input, dt),
		frame: |m| CameraDraw.frame(m),
		sounds: |_m| 0,
		tones: [],
		title: "Camera world",
	}
}
