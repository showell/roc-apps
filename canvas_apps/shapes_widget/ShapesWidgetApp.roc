## The pictures for the Safari tutorial's first look at shapes: a triangle,
## then a rectangle, each on a plain background. The Right key steps from one
## to the other, which is how the page opens at each.
import game.Polygon
import game.Screen
import lib.Brush
import lib.CanvasApp
import lib.Input
import lib.RgbColor
import lib.Shapes
import widget.WidgetPage
import widget.WidgetPalette

ShapesWidgetApp :: [].{

	## Which shape the picture shows.
	Model : [Triangle, Rectangle]

	canvas_app : CanvasApp.CanvasApp(ShapesWidgetApp.Model)
	canvas_app = WidgetPage.canvas_app({
		title: "A triangle and a rectangle",
		frames_a_second: WidgetPage.fixed_picture_frames_a_second,
		init: Triangle,
		model_at_next_step: next_model,
		frame_shapes: shapes_of,
	})

	## A green triangle.
	green_triangle : Shapes.Shape
	green_triangle = Polygon.triangle(
		{
			first_corner: Screen.point(180.0, 280.0),
			second_corner: Screen.point(420.0, 280.0),
			third_corner: Screen.point(300.0, 60.0),
		},
		RgbColor.of(0x2e8b57),
	)

	## A brown rectangle.
	brown_rectangle : Shapes.Shape
	brown_rectangle = Rectangle({
		top_left: { x: 240.0, y: 100.0 },
		width: 120.0,
		height: 160.0,
		fill: Brush.flat(RgbColor.of(0x8b5a2b)),
	})
}

## The picture after one frame: the Right key shows the other shape.
next_model : ShapesWidgetApp.Model, Input.Snapshot -> ShapesWidgetApp.Model
next_model = |shown, input|
	if input.key_pressed(KeyRight) {
		match shown {
			Triangle => Rectangle
			Rectangle => Triangle
		}
	} else {
		shown
	}

## Everything on the canvas: the background, then the shape shown.
shapes_of : ShapesWidgetApp.Model -> List(Shapes.Shape)
shapes_of = |shown| {
	shape =
		match shown {
			Triangle => ShapesWidgetApp.green_triangle
			Rectangle => ShapesWidgetApp.brown_rectangle
		}
	[WidgetPage.picture_backdrop(WidgetPalette.picture_background_color), shape]
}

expect
	shapes_of(Triangle)
		== [
			WidgetPage.picture_backdrop(WidgetPalette.picture_background_color),
			ShapesWidgetApp.green_triangle,
		]
expect next_model(Triangle, Input.none.with_key_pressed(KeyRight)) == Rectangle
expect next_model(Rectangle, Input.none.with_key_pressed(KeyRight)) == Triangle
expect next_model(Triangle, Input.none) == Triangle
