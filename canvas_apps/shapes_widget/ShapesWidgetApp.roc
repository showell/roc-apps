## The widget for the Safari tutorial's first look at shapes: the simple tree's
## foliage, its trunk, or the whole tree, each a fixed picture on a plain
## background. The Right key steps from one to the next, which is how the page
## opens at each.
import lib.CanvasApp
import lib.Input
import lib.Shapes
import widget.WidgetPage
import widget.WidgetPalette
import SimpleTree

ShapesWidgetApp :: [].{

	## Which part of the simple tree the widget shows.
	Model : [Foliage, Trunk, Tree]

	canvas_app : CanvasApp.CanvasApp(ShapesWidgetApp.Model)
	canvas_app = WidgetPage.canvas_app({
		title: "A simple tree",
		frames_a_second: WidgetPage.fixed_picture_frames_a_second,
		init: Foliage,
		model_at_next_step: next_model,
		frame_shapes: shapes_of,
	})
}

## The widget after one frame: the Right key shows the next part.
next_model : ShapesWidgetApp.Model, Input.Snapshot -> ShapesWidgetApp.Model
next_model = |shown, input|
	if input.key_pressed(KeyRight) {
		match shown {
			Foliage => Trunk
			Trunk => Tree
			Tree => Foliage
		}
	} else {
		shown
	}

## Everything on the canvas: the background, then the part shown.
shapes_of : ShapesWidgetApp.Model -> List(Shapes.Shape)
shapes_of = |shown| {
	part =
		match shown {
			Foliage => [SimpleTree.foliage]
			Trunk => [SimpleTree.trunk]
			Tree => SimpleTree.tree.to_shapes()
		}
	[WidgetPage.picture_backdrop(WidgetPalette.picture_background_color)].concat(part)
}

expect shapes_of(Tree).len() == 3
expect next_model(Tree, Input.none.with_key_pressed(KeyRight)) == Foliage
expect next_model(Foliage, Input.none) == Foliage
