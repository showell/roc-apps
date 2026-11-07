## A scrub widget is a small canvas app for the Safari tutorial. Every frame is a
## pure function of its state, so what it shows can play forward and backward.
## This module holds the page each widget is drawn on: the canvas, and laying out
## the picture and the lines of text below it. ReadoutText puts a widget's numbers
## into words for those lines, and VcrButtons reads a widget's buttons into its
## state.
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

	## The size of a label's words, on a canvas of the usual width.
	label_size : F64
	label_size = 14.0

	## A line of what the widget reads out, on row `row` of the panel.
	readout : {
		text : Str,
		color : RgbColor,
		row : U64,
	} -> Shapes.Shape
	readout = |{ text, color, row }|
		Text({
			text,
			x: side_margin,
			y: readout_first_baseline + row.to_f64() * readout_row_spacing,
			size: readout_size,
			face: Code,
			align: Left,
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
			color: Brush.opaque(ink_color),
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

## The size of the lines under the picture, on a canvas of the usual width.
readout_size : F64
readout_size = 15.0

## The baseline of the readout's first row, below the picture.
readout_first_baseline : F64
readout_first_baseline = ScrubWidget.picture_bottom_y + 50.0

## How far each row of the readout sits below the last.
readout_row_spacing : F64
readout_row_spacing = 26.0

panel_color : RgbColor
panel_color = RgbColor.of(0xDCECF5)

ink_color : RgbColor
ink_color = RgbColor.of(0x202020)

## The text sits on this, and a widget's buttons do too.
panel : Shapes.Shape
panel = Rect({
	x: 0.0,
	y: ScrubWidget.picture_bottom_y,
	width: ScrubWidget.canvas_width,
	height: ScrubWidget.canvas_height - ScrubWidget.picture_bottom_y,
	fill: Brush.flat(panel_color),
})

status_line : Str, U64 -> Shapes.Shape
status_line = |text, row| ScrubWidget.readout({ text, color: ink_color, row })

# A page is the panel and its text.
expect ScrubWidget.frame_shapes({ picture_shapes: [], status_lines: [] }).len() == 1
expect ScrubWidget.frame_shapes({ picture_shapes: [], status_lines: ["I"] }).len() == 2

# Each row of the readout sits under the last, in monospace.
expect
	ScrubWidget.readout({
		text: "I",
		color: RgbColor.of(0x202020),
		row: 1,
	})
		== Text({
			text: "I",
			x: ScrubWidget.side_margin,
			y: 292.0,
			size: readout_size,
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
