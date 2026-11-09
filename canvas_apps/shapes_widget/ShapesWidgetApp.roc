## The widget for the Safari tutorial's first look at shapes: the frame TwoShapes
## makes, on a plain background, as a fixed picture with no controls.
import lib.CanvasApp
import widget.WidgetPage
import widget.WidgetPalette
import TwoShapes

ShapesWidgetApp :: [].{

	## A fixed picture has no state.
	Model : {}

	canvas_app : CanvasApp.CanvasApp(ShapesWidgetApp.Model)
	canvas_app = WidgetPage.fixed_picture_app({
		title: "Two shapes",
		shapes: [WidgetPage.picture_backdrop(WidgetPalette.picture_background_color)]
			.concat(TwoShapes.shapes),
	})
}
