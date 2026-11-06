## The widget for the Safari tutorial's first look at shapes: the frame TwoShapes
## makes, on a plain background, as a still picture with no controls.
import lib.CanvasApp
import lib.Shapes
import widget.ScrubWidget
import TwoShapes

ShapesWidgetApp :: [].{

	## A still picture has no state.
	Model : {}

	canvas_app : CanvasApp.CanvasApp(ShapesWidgetApp.Model)
	canvas_app = ScrubWidget.canvas_app({
		title: "Two shapes",
		init: {},
		advance: |model, _input| model,
		frame: |_model| [background].concat(TwoShapes.shapes),
	})
}

background : Shapes.Shape
background = Rect({
	x: 0.0,
	y: 0.0,
	w: ScrubWidget.canvas_width,
	h: ScrubWidget.canvas_height,
	fill: ScrubWidget.flat(0xf7f5f0),
})

# The background goes down first, so the shapes show over it.
expect (ShapesWidgetApp.canvas_app.frame)({}) == [background].concat(TwoShapes.shapes)
