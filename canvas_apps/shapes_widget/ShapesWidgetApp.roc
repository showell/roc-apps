## The widget for the Safari tutorial's first look at shapes: the frame TwoShapes
## makes, on a plain background, as a still picture with no controls.
import lib.CanvasApp
import lib.RgbColor
import widget.ScrubWidget
import TwoShapes

ShapesWidgetApp :: [].{

	## A still picture has no state.
	Model : {}

	canvas_app : CanvasApp.CanvasApp(ShapesWidgetApp.Model)
	canvas_app = ScrubWidget.still_app({
		title: "Two shapes",
		shapes: [ScrubWidget.picture_backdrop(RgbColor.of(0xf7f5f0))].concat(TwoShapes.shapes),
	})
}
