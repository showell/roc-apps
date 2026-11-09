## A widget page is the canvas a Safari tutorial widget is drawn on: a picture
## across the top, and a panel under it for the lines of text and any buttons.
## A widget is a small canvas app, and every frame is a pure function of its
## state. This module holds the page's sizes, the canvas app around a widget,
## and laying out the picture and the text. ReadoutText puts a widget's numbers
## into words for those lines, VcrButtons reads a widget's buttons into its
## state, Click reads where the pointer was pressed, PlanView holds the one
## mapping of the pictures that look down on the road, and WidgetPalette holds
## the colors the widgets share.
import game.FrameView
import game.Lens
import game.Sprite
import game.Pixels
import game.Pipeline
import game.Screen
import lib.Brush
import lib.RgbColor
import lib.CanvasApp
import lib.Input
import lib.Point
import lib.Shapes
import WidgetPalette

WidgetPage :: [].{

	canvas_width : F64
	canvas_width = 640.0

	canvas_height : F64
	canvas_height = 360.0

	## The x on the ride's screen that the picture shows at `canvas_x`.
	screen_x_at_canvas_x : F64 -> Pixels
	screen_x_at_canvas_x = |canvas_x| Pixels.of(canvas_x / canvas_per_screen)

	## Where the picture shows a point of the ride's screen, given in pixels.
	canvas_point_of_screen : Point.Point -> Point.Point
	canvas_point_of_screen = |{ x, y }| { x: x * canvas_per_screen, y: y * canvas_per_screen }

	## How much ground shows below the horizon, chosen by eye.
	ground_depth : F64
	ground_depth = 16.0

	## The picture fills the canvas above this line.
	picture_bottom_y : F64
	picture_bottom_y = horizon_y + ground_depth

	## Whether `point` is in the picture, edges included.
	is_in_picture : Point.Point -> Bool
	is_in_picture = |{ x, y }| x >= 0.0 and x <= canvas_width and y >= 0.0 and y <= picture_bottom_y

	## The space left and right of what sits on the panel.
	side_margin : F64
	side_margin = 24.0

	## How wide the panel is between its margins.
	panel_width : F64
	panel_width = canvas_width - 2.0 * side_margin

	## How often a widget whose picture moves is painted: as often as a page
	## paints.
	moving_frames_a_second : U32
	moving_frames_a_second = 60

	## How often a fixed picture is painted: seldom, since it never changes, but
	## often enough that a page's check, which runs a page for a few frames, sees
	## it painted more than once.
	fixed_picture_frames_a_second : U32
	fixed_picture_frames_a_second = 20

	## A canvas app from a widget's model, what a frame does to it and what it
	## draws, painted `frames_a_second` times a second.
	canvas_app : {
		title : Str,
		frames_a_second : U32,
		init : model,
		model_at_next_step : model, Input.Snapshot -> model,
		frame_shapes : model -> List(Shapes.Shape),
	} -> CanvasApp.CanvasApp(model)
	canvas_app = |{ title, frames_a_second, init, model_at_next_step, frame_shapes }| {
		size: { width: canvas_width, height: canvas_height },
		frames_a_second,
		init,
		model_at_next_step: CanvasApp.untimed_model_at_next_step(model_at_next_step),
		frame_shapes,
		sounds: |_model| 0,
		tones: [],
		title,
	}

	## A canvas app for a widget that draws one picture that never changes. Such a
	## picture needn't be painted again sixty times a second.
	fixed_picture_app : { title : Str, shapes : List(Shapes.Shape) } -> CanvasApp.CanvasApp({})
	fixed_picture_app = |{ title, shapes }|
		canvas_app({
			title,
			frames_a_second: fixed_picture_frames_a_second,
			init: {},
			model_at_next_step: |model, _input| model,
			frame_shapes: |_model| shapes,
		})

	## A plain color behind the picture, first under everything else. It fills
	## the canvas, and a widget's panel covers its lower part.
	picture_backdrop : RgbColor -> Shapes.Shape
	picture_backdrop = |color|
		Rectangle({
			top_left: { x: 0.0, y: 0.0 },
			width: canvas_width,
			height: canvas_height,
			fill: Brush.flat(color),
		})

	## Where and how large the rows of a readout are set: the x they are aligned
	## on, the baseline of the first row, how far each row sits below the last,
	## and the size of their type.
	ReadoutRows : {
		x : F64,
		first_baseline : F64,
		row_spacing : F64,
		size : F64,
		align : Shapes.Align,
	}

	## The rows of text on the panel under the picture, from its left margin.
	panel_rows : ReadoutRows
	panel_rows = {
		x: side_margin,
		first_baseline: picture_bottom_y + 50.0,
		row_spacing: 26.0,
		size: 15.0,
		align: Left,
	}

	## A line of what the widget reads out, on row `row` of `style`, in
	## monospace.
	readout_line : {
		text : Str,
		color : RgbColor,
		row : U64,
		style : ReadoutRows,
	} -> Shapes.Shape
	readout_line = |{ text, color, row, style }|
		Text({
			text,
			x: style.x,
			y: style.first_baseline + row.to_f64() * style.row_spacing,
			size: style.size,
			face: Code,
			align: style.align,
			color: Brush.opaque_rgba(color),
		})

	## A few words beside what they name, with their baseline at `y`.
	label : {
		text : Str,
		x : F64,
		y : F64,
	} -> Shapes.Shape
	label = |{ text, x, y }|
		Text({
			text,
			x,
			y,
			size: label_size,
			face: Prose,
			align: Left,
			color: Brush.opaque_rgba(WidgetPalette.ink_color),
		})

	## The picture, and the panel with the lines of text on it.
	frame_shapes : { picture_shapes : List(Shapes.Shape), status_lines : List(Str) } -> List(Shapes.Shape)
	frame_shapes = |{ picture_shapes, status_lines }|
		[picture_shapes, [panel], status_lines.map_with_index(status_line)].join()

	## The ride's `ride_shapes` over its `backdrop`, at the canvas's share of
	## Safari's screen, so a widget's picture is what the ride's frame shows.
	## A widget's picture is never rolled.
	picture_shapes : {
		backdrop : FrameView.Backdrop,
		ride_shapes : List(Shapes.Shape),
	} -> List(Shapes.Shape)
	picture_shapes = |{ backdrop, ride_shapes }| {
		corner = { x: 0.0, y: 0.0 }
		FrameView.painted_shapes({
			backdrop,
			ride_shape_lists: [ride_shapes],
			space: Shapes.world_space({
				target: corner,
				offset: corner,
				rotation: 0.0,
				zoom: canvas_per_screen,
			}),
		})
	}

	## What `sighting` shows through the lens at rest, with `context` for whatever
	## else its kind needs, or nothing if it stood behind the camera.
	resting_lens_shapes : Try(Pipeline.Sighted(kind), [BehindCamera]), context -> List(Shapes.Shape)
		where [kind.scenery_sprite : kind, Sprite.Setting(context) -> Sprite]
	resting_lens_shapes = |sighting, context|
		match sighting {
			Ok(sighted) =>
				Pipeline.rendering_of(sighted, { focal_length: Lens.resting_focal_length, context }).sprite().to_shapes()
			Err(BehindCamera) => []
		}
}

## How many canvas pixels the picture gives a pixel of the ride's screen.
canvas_per_screen : F64
canvas_per_screen = WidgetPage.canvas_width / Screen.width.to_f64()

## Where the ride's horizon crosses the picture.
horizon_y : F64
horizon_y = Screen.horizon_y.to_f64() * canvas_per_screen

## The size of a label's words, on a canvas of the usual width.
label_size : F64
label_size = 14.0

## The text sits on this, and a widget's buttons do too.
panel : Shapes.Shape
panel = Rectangle({
	top_left: { x: 0.0, y: WidgetPage.picture_bottom_y },
	width: WidgetPage.canvas_width,
	height: WidgetPage.canvas_height - WidgetPage.picture_bottom_y,
	fill: Brush.flat(WidgetPalette.panel_color),
})

status_line : Str, U64 -> Shapes.Shape
status_line = |text, row| WidgetPage.readout_line({ text, color: WidgetPalette.ink_color, row, style: WidgetPage.panel_rows })

# A page is the panel and its text.
expect WidgetPage.frame_shapes({ picture_shapes: [], status_lines: [] }).len() == 1
expect WidgetPage.frame_shapes({ picture_shapes: [], status_lines: ["I"] }).len() == 2
