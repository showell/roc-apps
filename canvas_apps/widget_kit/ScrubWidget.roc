## A scrub widget is a small canvas app for the Safari tutorial. Every frame is a
## pure function of its state, so what it shows can play forward and backward.
## This module holds the page each widget is drawn on: the canvas, and laying out
## the picture and the lines of text below it. ReadoutText puts a widget's numbers
## into words for those lines, VcrButtons reads a widget's buttons into its
## state, Click reads where the pointer was pressed, and PlanView draws a picture
## that looks down on the road.
import game.FrameView
import game.Screen
import lib.Brush
import lib.RgbColor
import lib.CanvasApp
import lib.Input
import lib.Shapes

ScrubWidget :: [].{

	canvas_width : F64
	canvas_width = 640.0

	canvas_height : F64
	canvas_height = 360.0

	## The picture fills the canvas above this line.
	picture_bottom_y : F64
	picture_bottom_y = 216.0

	## The space left and right of what sits on the panel.
	side_margin : F64
	side_margin = 24.0

	## How wide the panel is between its margins.
	panel_width : F64
	panel_width = canvas_width - 2.0 * side_margin

	## The words and the lines on the panel.
	ink_color : RgbColor
	ink_color = RgbColor.of(0x202020)

	## The panel under the picture, which the text and the buttons sit on.
	panel_color : RgbColor
	panel_color = RgbColor.of(0xDCECF5)

	## A canvas app from a widget's model, what a frame does to it and what it
	## draws.
	canvas_app : {
		title : Str,
		init : model,
		model_at_next_step : model, Input.Snapshot -> model,
		frame_shapes : model -> List(Shapes.Shape),
	} -> CanvasApp.CanvasApp(model)
	canvas_app = |{ title, init, model_at_next_step, frame_shapes }| {
		size: { width: canvas_width, height: canvas_height },
		fps: 60,
		init,
		model_at_next_step: CanvasApp.untimed_model_at_next_step(model_at_next_step),
		frame_shapes,
		sounds: |_model| 0,
		tones: [],
		title,
	}

	## A canvas app for a widget that draws one picture that never changes. Such a
	## picture needn't be painted again sixty times a second.
	still_app : { title : Str, shapes : List(Shapes.Shape) } -> CanvasApp.CanvasApp({})
	still_app = |{ title, shapes }| {
		size: { width: canvas_width, height: canvas_height },
		fps: still_frames_a_second,
		init: {},
		model_at_next_step: |model, _input, _seconds| model,
		frame_shapes: |_model| shapes,
		sounds: |_model| 0,
		tones: [],
		title,
	}

	## A plain color behind the picture, first under everything else. It fills
	## the canvas, and a widget's panel covers its lower part.
	picture_backdrop : RgbColor -> Shapes.Shape
	picture_backdrop = |color|
		Rect({
			x: 0.0,
			y: 0.0,
			width: canvas_width,
			height: canvas_height,
			fill: Brush.flat(color),
		})

	## The size of a label's words, on a canvas of the usual width.
	label_size : F64
	label_size = 14.0

	## Where and how large the rows of a readout are set: the x they are aligned
	## on, the baseline of the first row, how far each row sits below the last,
	## and the size of their type.
	ReadoutStyle : {
		x : F64,
		first_baseline : F64,
		row_spacing : F64,
		size : F64,
		align : Shapes.Align,
	}

	## The rows of text on the panel under the picture, from its left margin.
	panel_readout : ScrubWidget.ReadoutStyle
	panel_readout = {
		x: side_margin,
		first_baseline: picture_bottom_y + 50.0,
		row_spacing: 26.0,
		size: 15.0,
		align: Left,
	}

	## A line of what the widget reads out, on row `row` of `style`, in
	## monospace.
	readout : {
		text : Str,
		color : RgbColor,
		row : U64,
		style : ScrubWidget.ReadoutStyle,
	} -> Shapes.Shape
	readout = |{ text, color, row, style }|
		Text({
			text,
			x: style.x,
			y: style.first_baseline + row.to_f64() * style.row_spacing,
			size: style.size,
			face: Code,
			align: style.align,
			color: Brush.opaque(color),
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
			color: Brush.opaque(ScrubWidget.ink_color),
		})

	## The picture, and the panel with the lines of text on it.
	frame_shapes : { picture_shapes : List(Shapes.Shape), status_lines : List(Str) } -> List(Shapes.Shape)
	frame_shapes = |{ picture_shapes, status_lines }|
		[picture_shapes, [panel], status_lines.map_with_index(status_line)].join()

	## The whole of `view`, backdrop and shapes, at the canvas's share of
	## Safari's screen, so a widget's picture is what the ride's frame shows.
	## A widget's picture is never rolled.
	ride_shapes : FrameView -> List(Shapes.Shape)
	ride_shapes = |view| {
		corner = { x: 0.0, y: 0.0 }
		view.framed_shapes(
			World({
				target: corner,
				offset: corner,
				rotation: 0.0,
				zoom: canvas_width / Screen.width.to_f64(),
			}),
		)
	}
}

## How often a still picture is painted: seldom, since it never changes, but
## often enough that a page's check, which runs a page for a few frames, sees
## it painted more than once.
still_frames_a_second : U32
still_frames_a_second = 20

## The text sits on this, and a widget's buttons do too.
panel : Shapes.Shape
panel = Rect({
	x: 0.0,
	y: ScrubWidget.picture_bottom_y,
	width: ScrubWidget.canvas_width,
	height: ScrubWidget.canvas_height - ScrubWidget.picture_bottom_y,
	fill: Brush.flat(ScrubWidget.panel_color),
})

status_line : Str, U64 -> Shapes.Shape
status_line = |text, row| ScrubWidget.readout({ text, color: ScrubWidget.ink_color, row, style: ScrubWidget.panel_readout })

# A page is the panel and its text.
expect ScrubWidget.frame_shapes({ picture_shapes: [], status_lines: [] }).len() == 1
expect ScrubWidget.frame_shapes({ picture_shapes: [], status_lines: ["I"] }).len() == 2

# Each row of the readout sits under the last, in monospace.
expect
	ScrubWidget.readout({
		text: "I",
		color: RgbColor.of(0x202020),
		row: 1,
		style: ScrubWidget.panel_readout,
	})
		== Text({
			text: "I",
			x: ScrubWidget.side_margin,
			y: 292.0,
			size: 15.0,
			face: Code,
			align: Left,
			color: Brush.opaque(RgbColor.of(0x202020)),
		})

# A label is words, set where it is asked.
expect
	ScrubWidget.label({
		text: "I",
		x: 3.0,
		y: 4.0,
	})
		== Text({
			text: "I",
			x: 3.0,
			y: 4.0,
			size: ScrubWidget.label_size,
			face: Prose,
			align: Left,
			color: Brush.opaque(RgbColor.of(0x202020)),
		})
