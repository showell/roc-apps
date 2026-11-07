## A scrub widget is a small canvas app for the Safari tutorial. Every frame is a
## pure function of its state, so what it shows can play forward and backward.
## This module holds what each widget has in common: the canvas, and laying out
## the picture and the lines of text below it. VcrButtons reads a widget's buttons
## into its state.
import game.Animation
import game.Clock
import game.Distance
import game.Fraction
import game.Backdrop
import game.HexColor
import game.Sky
import game.Sun
import lib.Brush
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
		model_at_next_step: |model, input, _seconds| model_at_next_step(model, input),
		frame_shapes,
		sounds: |_model| 0,
		tones: [],
		title,
	}

	flat : I64 -> Brush.Fill
	flat = |color| Flat(Brush.opaque(color))

	## The size of the lines under the picture, and of the words in it, on a
	## canvas of the usual width.
	readout_size : F64
	readout_size = 15.0

	label_size : F64
	label_size = 14.0

	## A line of what the widget reads out, on row `row` of the panel.
	readout : {
		text : Str,
		color : I64,
		row : U64,
	} -> Shapes.Shape
	readout = |{ text, color, row }|
		Text({
			text,
			x: side_margin,
			y: 266.0 + row.to_f64() * 26.0,
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

	## The ride's sky and grass with `shapes` over them, at two thirds of
	## Safari's screen, so a widget's picture is what the ride's frame shows.
	## The sky is `clock`'s, and `sun` is where the sun stands in it.
	ride_shapes : List(Shapes.Shape), { clock : Clock, sun : Sun.Sighting } -> List(Shapes.Shape)
	ride_shapes = |shapes, { clock, sun }|
		ride_shapes_in(
			shapes,
			{
				sky_top_color: Sky.sky_top_color(clock),
				sky_horizon_color: Sky.sky_horizon_color(clock),
				sun_sighting: sun,
			},
		)

	## The same picture under any sky, for a widget that shows part of a sunset.
	ride_shapes_in : List(Shapes.Shape),
	{
		sky_top_color : HexColor.Rgb,
		sky_horizon_color : HexColor.Rgb,
		sun_sighting : Sun.Sighting,
	} -> List(Shapes.Shape)
	ride_shapes_in = |shapes, sky| {
		corner = { x: 0.0, y: 0.0 }
		ride = Backdrop.frame_shapes(shapes, sky)
		[
			[
				View(
					World({
						target: corner,
						offset: corner,
						rotation: 0.0,
						zoom: 2.0 / 3.0,
					}),
				),
			],
			ride,
			[View(Screen)],
		].join()
	}

	## Where an animation has got to, in words.
	stage_text : Animation.Stage -> Str
	stage_text = |stage|
		match stage {
			Waiting => "Waiting"
			Playing(progress) => "Playing: ${percent_text(progress)}"
			Past(_) => "Past"
		}

	## A number of at least zero, to one decimal place.
	tenths_text : F64 -> Str
	tenths_text = |number| {
		tenths = (number * 10.0 + 0.5).to_i64_wrap()
		"${(tenths // 10).to_str()}.${(tenths % 10).to_str()}"
	}

	## A fraction as a whole percentage, rounded down.
	percent_text : Fraction -> Str
	percent_text = |fraction| "${(fraction.to_f64() * 100.0).to_i64_wrap().to_str()}%"

	## A count as the book writes it, with commas.
	count_text : U64 -> Str
	count_text = |count| {
		thousands = count // 1000
		rest = count % 1000
		if thousands == 0 {
			rest.to_str()
		} else if rest < 10 {
			"${count_text(thousands)},00${rest.to_str()}"
		} else if rest < 100 {
			"${count_text(thousands)},0${rest.to_str()}"
		} else {
			"${count_text(thousands)},${rest.to_str()}"
		}
	}
}

panel_color : I64
panel_color = 0xdcecf5

ink_color : I64
ink_color = 0x202020

## The text sits on this, and a widget's buttons do too.
panel : Shapes.Shape
panel = Rect({
	x: 0.0,
	y: ScrubWidget.picture_bottom_y,
	w: ScrubWidget.canvas_width,
	h: ScrubWidget.canvas_height - ScrubWidget.picture_bottom_y,
	fill: ScrubWidget.flat(panel_color),
})

status_line : Str, U64 -> Shapes.Shape
status_line = |text, row| ScrubWidget.readout({ text, color: ink_color, row })

expect ScrubWidget.stage_text(Waiting) == "Waiting"
expect ScrubWidget.stage_text(Playing(Fraction.of(0.5))) == "Playing: 50%"
expect ScrubWidget.stage_text(Past(Distance.metres(1.0))) == "Past"

# The first view mark, the sky, the grass, the shapes, and the mark back to the
# screen.
expect
	ScrubWidget.ride_shapes(
		[
			Rect({
				x: 0.0,
				y: 0.0,
				w: 1.0,
				h: 1.0,
				fill: Skip,
			}),
		],
		{ clock: Clock.start, sun: OutOfView },
	).len()
		== 5

expect ScrubWidget.tenths_text(0.0) == "0.0"
expect ScrubWidget.tenths_text(0.04) == "0.0"
expect ScrubWidget.tenths_text(0.06) == "0.1"
expect ScrubWidget.tenths_text(21.0) == "21.0"
expect ScrubWidget.tenths_text(9.96) == "10.0"

expect ScrubWidget.percent_text(Fraction.zero) == "0%"
expect ScrubWidget.percent_text(Fraction.of(0.529)) == "52%"
expect ScrubWidget.percent_text(Fraction.whole) == "100%"

expect ScrubWidget.count_text(0) == "0"
expect ScrubWidget.count_text(999) == "999"
expect ScrubWidget.count_text(1000) == "1,000"
expect ScrubWidget.count_text(1005) == "1,005"
expect ScrubWidget.count_text(1050) == "1,050"
expect ScrubWidget.count_text(2198) == "2,198"
expect ScrubWidget.count_text(1000000) == "1,000,000"

# A page is the panel and its text.
expect ScrubWidget.frame_shapes({ picture_shapes: [], status_lines: [] }).len() == 1
expect ScrubWidget.frame_shapes({ picture_shapes: [], status_lines: ["I"] }).len() == 2

# Each row of the readout sits under the last, in monospace.
expect
	ScrubWidget.readout({
		text: "I",
		color: 0x202020,
		row: 1,
	})
		== Text({
			text: "I",
			x: ScrubWidget.side_margin,
			y: 292.0,
			size: ScrubWidget.readout_size,
			face: Code,
			align: Left,
			color: Brush.opaque(0x202020),
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
			color: Brush.opaque(0x202020),
		})
