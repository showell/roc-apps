## A scrub widget is a small canvas app for the Safari tutorial whose whole
## state is one number, set by dragging across the canvas. Every frame is a pure
## function of that number, so what it shows plays forward and backward under
## the pointer. This module holds what each widget has in common: reading the
## pointer into the number, and laying out the picture, the ruler under it and
## the lines of text below that. A widget says what the number means.
import game.Animation
import game.Clock
import game.Distance
import game.Fraction
import game.Backdrop
import game.Sky
import game.Sun
import lib.Brush
import lib.CanvasApp
import lib.Input
import lib.Mouse
import lib.Shapes

ScrubWidget :: [].{

	canvas_width : F64
	canvas_width = 640.0

	canvas_height : F64
	canvas_height = 360.0

	## The picture fills the canvas above this line.
	picture_bottom_y : F64
	picture_bottom_y = 216.0

	## The space left of the ruler and of the text, and right of the ruler.
	side_margin : F64
	side_margin = 24.0

	## The ruler's length, which is what a share of it is a share of.
	ruler_length : F64
	ruler_length = canvas_width - 2.0 * side_margin

	## The steps of the ride that a ruler shows, from its left end to its right.
	ClockRange : { first_step : F64, last_step : F64 }

	## A stretch of the ruler, as shares of its length.
	Stretch : { from : Fraction, to : Fraction }

	## What a frame shows: its picture, where the dot sits on the ruler, the
	## stretches marked on the ruler, and the lines of text.
	Page : {
		picture : List(Shapes.Shape),
		dot_at : Fraction,
		marked : List(ScrubWidget.Stretch),
		status : List(Str),
	}

	## A canvas app from what a widget says about its number. `model_at` is the
	## model with the pointer that share of the way across the canvas.
	canvas_app : {
		title : Str,
		init : model,
		model_at : Fraction -> model,
		frame : model -> List(Shapes.Shape),
	} -> CanvasApp.CanvasApp(model)
	canvas_app = |{ title, init, model_at, frame }| {
		size: { width: canvas_width, height: canvas_height },
		fps: 60,
		init,
		advance: |model, input, _seconds| followed_pointer(model, { input, model_at }),
		frame,
		sounds: |_model| 0,
		tones: [],
		title,
	}

	## A canvas app from a widget's model, what a frame does to it and what it
	## draws.
	app_with_advance : {
		title : Str,
		init : model,
		advance : model, Input.Snapshot -> model,
		frame : model -> List(Shapes.Shape),
	} -> CanvasApp.CanvasApp(model)
	app_with_advance = |{ title, init, advance, frame }| {
		size: { width: canvas_width, height: canvas_height },
		fps: 60,
		init,
		advance: |model, input, _seconds| advance(model, input),
		frame,
		sounds: |_model| 0,
		tones: [],
		title,
	}

	## The model after one step: a pointer held down sets it, and it stays
	## where it is left.
	followed_pointer : model, { input : Input.Snapshot, model_at : Fraction -> model } -> model
	followed_pointer = |model, { input, model_at }|
		if input.mouse.button_down(Left) {
			pointer_x = input.mouse.position().x.to_f64()
			model_at(share_under(pointer_x))
		} else {
			model
		}

	## How far along the ruler a pointer at `x` is. Past either end of the ruler
	## it holds at that end, and during a drag it may be off the canvas.
	share_under : F64 -> Fraction
	share_under = |x| Fraction.clamp((x - side_margin) / ruler_length)

	## The gap with the pointer `share` of the way along a ruler that runs from
	## `farthest` at the left down to zero at the right.
	gap_at : Fraction, { farthest : Distance } -> Distance
	gap_at = |share, { farthest }| farthest.times(share.complement().to_f64())

	## How far along such a ruler `gap` sits.
	gap_share : Distance, { farthest : Distance } -> Fraction
	gap_share = |gap, { farthest }| Fraction.clamp(1.0 - gap.ratio_to(farthest))

	## The clock with the pointer `share` of the way along a ruler.
	clock_at : Fraction, ScrubWidget.ClockRange -> Clock
	clock_at = |share, { first_step, last_step }| {
		step = first_step + (last_step - first_step) * share.to_f64()
		Clock.at_step(step.to_u32_wrap())
	}

	## How far along a ruler `step` sits, which need not be a whole step.
	step_share : F64, ScrubWidget.ClockRange -> Fraction
	step_share = |step, { first_step, last_step }|
		Fraction.clamp((step - first_step) / (last_step - first_step))

	flat : I64 -> Brush.Fill
	flat = |color| Flat(Brush.opaque(color))

	## The size of the lines under the picture, and of the words in it, on a
	## canvas of the usual width.
	readout_size : F64
	readout_size = 15.0

	label_size : F64
	label_size = 14.0

	## A line of what the widget reads out, on row `row` of the panel.
	readout : { text : Str, color : I64, row : U64 } -> Shapes.Shape
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
	label : { text : Str, x : F64, y : F64 } -> Shapes.Shape
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

	## Everything on the canvas.
	frame_shapes : ScrubWidget.Page -> List(Shapes.Shape)
	frame_shapes = |{ picture, dot_at, marked, status }|
		[
			picture,
			[panel],
			ruler({ dot_at, marked }),
			status.map_with_index(status_line),
		].join()

	## A page with no ruler, for a widget that isn't dragged.
	still_frame_shapes : { picture : List(Shapes.Shape), status : List(Str) } -> List(Shapes.Shape)
	still_frame_shapes = |{ picture, status }|
		[picture, [panel], status.map_with_index(status_line)].join()

	## The ride's sky and grass with `shapes` over them, at two thirds of
	## Safari's screen, so a widget's picture is what the ride's frame shows.
	## The sky is `clock`'s, and `sun` is where the sun stands in it.
	ride_picture : List(Shapes.Shape),
	{
		clock : Clock,
		sun : Sun.Sighting,
	} -> List(Shapes.Shape)
	ride_picture = |shapes, { clock, sun }|
		ride_picture_in(
			shapes,
			{
				sky_top_color: Sky.sky_top_color(clock),
				sky_horizon_color: Sky.sky_horizon_color(clock),
				sun_sighting: sun,
			},
		)

	## The same picture under any sky, for a widget that shows part of a sunset.
	ride_picture_in : List(Shapes.Shape),
	{
		sky_top_color : Sky.Rgb,
		sky_horizon_color : Sky.Rgb,
		sun_sighting : Sun.Sighting,
	} -> List(Shapes.Shape)
	ride_picture_in = |shapes, sky| {
		corner = { x: 0.0, y: 0.0 }
		ride = Backdrop.behind(shapes, sky)
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

## The ruler and the text sit on this.
panel : Shapes.Shape
panel = Rect({
	x: 0.0,
	y: ScrubWidget.picture_bottom_y,
	w: ScrubWidget.canvas_width,
	h: ScrubWidget.canvas_height - ScrubWidget.picture_bottom_y,
	fill: ScrubWidget.flat(panel_color),
})

ruler_y : F64
ruler_y = 232.0

## Where a share of the ruler is on the canvas.
ruler_x : Fraction -> F64
ruler_x = |share| ScrubWidget.side_margin + ScrubWidget.ruler_length * share.to_f64()

## A bar across the canvas, 6 px thick, in `color`, from `x` for `width`.
bar : {
	x : F64,
	width : F64,
	color : I64,
} -> Shapes.Shape
bar = |{ x, width, color }|
	Rect({
		x,
		y: ruler_y - 3.0,
		w: width,
		h: 6.0,
		fill: ScrubWidget.flat(color),
	})

## A marked stretch of the ruler.
marked_bar : ScrubWidget.Stretch -> Shapes.Shape
marked_bar = |{ from, to }|
	bar({
		x: ruler_x(from),
		width: ruler_x(to) - ruler_x(from),
		color: 0xd0603a,
	})

## A bar with its stretches marked on it, and a dot.
ruler : { dot_at : Fraction, marked : List(ScrubWidget.Stretch) } -> List(Shapes.Shape)
ruler = |{ dot_at, marked }|
	[
		[
			bar({
				x: ScrubWidget.side_margin,
				width: ScrubWidget.ruler_length,
				color: 0xb8b8b8,
			}),
		],
		marked.map(marked_bar),
		[
			Disc({
				x: ruler_x(dot_at),
				y: ruler_y,
				r: 8.0,
				fill: ScrubWidget.flat(0x303030),
				clip: Anywhere,
			}),
		],
	].join()

status_line : Str, U64 -> Shapes.Shape
status_line = |text, row| ScrubWidget.readout({ text, color: ink_color, row })

## Where the ruler's right end is on the canvas.
ruler_right_x : F64
ruler_right_x = ScrubWidget.canvas_width - ScrubWidget.side_margin

# The ruler's two ends read 0 and 1, and past them the share holds.
expect ScrubWidget.share_under(ScrubWidget.side_margin) == Fraction.zero
expect ScrubWidget.share_under(ruler_right_x) == Fraction.whole
expect ScrubWidget.share_under(ScrubWidget.side_margin - 1.0) == Fraction.zero
expect ScrubWidget.share_under(ruler_right_x + 1.0) == Fraction.whole
expect ScrubWidget.share_under(-5.0) == Fraction.zero
expect ScrubWidget.share_under(ScrubWidget.canvas_width + 5.0) == Fraction.whole

# Just inside either end isn't the end, and the middle is the canvas's.
expect ScrubWidget.share_under(ScrubWidget.side_margin + 1.0).to_f64() > 0.0
expect ScrubWidget.share_under(ruler_right_x - 1.0).to_f64() < 1.0
expect ScrubWidget.share_under(ScrubWidget.canvas_width / 2.0) == Fraction.of(0.5)

# Drawing and dragging agree on where the ruler is.
expect ruler_x(Fraction.zero) == ScrubWidget.side_margin
expect ruler_x(Fraction.whole) == ruler_right_x
expect ruler_x(ScrubWidget.share_under(172.0)) == 172.0

## A snapshot with the left button held or not, the pointer mid-canvas.
pointer_at_middle : U32 -> Input.Snapshot
pointer_at_middle = |held| Input.none.with_mouse(Mouse.of(held, 0, 320.0, 0.0, 0.0))

## The model after a step from 0.7, with the left button held or not.
stepped_from_seven_tenths : U32 -> F64
stepped_from_seven_tenths = |held|
	ScrubWidget.followed_pointer(
		0.7,
		{ input: pointer_at_middle(held), model_at: |share| share.to_f64() },
	)

expect stepped_from_seven_tenths(1) == 0.5
expect stepped_from_seven_tenths(0) == 0.7

## The gap on a ruler 50 metres long.
gap_on_ruler : Fraction -> Distance
gap_on_ruler = |share| ScrubWidget.gap_at(share, { farthest: Distance.metres(50.0) })

## How far along a ruler 50 metres long a gap of `metres` sits.
share_on_ruler : F64 -> Fraction
share_on_ruler = |metres|
	ScrubWidget.gap_share(Distance.metres(metres), { farthest: Distance.metres(50.0) })

expect gap_on_ruler(Fraction.zero) == Distance.metres(50.0)
expect gap_on_ruler(Fraction.whole) == Distance.zero
expect gap_on_ruler(Fraction.of(0.5)) == Distance.metres(25.0)
expect share_on_ruler(37.5) == Fraction.of(0.25)
expect share_on_ruler(60.0) == Fraction.zero
expect share_on_ruler(-1.0) == Fraction.whole

## A ruler over steps 100 to 300.
sample_range : ScrubWidget.ClockRange
sample_range = { first_step: 100.0, last_step: 300.0 }

expect ScrubWidget.clock_at(Fraction.zero, sample_range) == Clock.at_step(100)
expect ScrubWidget.clock_at(Fraction.whole, sample_range) == Clock.at_step(300)
expect ScrubWidget.clock_at(Fraction.of(0.5), sample_range) == Clock.at_step(200)
expect ScrubWidget.step_share(150.0, sample_range) == Fraction.of(0.25)
expect ScrubWidget.step_share(99.0, sample_range) == Fraction.zero
expect ScrubWidget.step_share(301.0, sample_range) == Fraction.whole

expect ScrubWidget.stage_text(Waiting) == "Waiting"
expect ScrubWidget.stage_text(Playing(Fraction.of(0.5))) == "Playing: 50%"
expect ScrubWidget.stage_text(Past(Distance.metres(1.0))) == "Past"

# The first view mark, the sky, the grass, the shapes, and the mark back to the
# screen.
expect
	ScrubWidget.ride_picture(
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

## A page with `count` lines of text and `stretches` marked stretches.
page_of : { lines : List(Str), stretches : List(ScrubWidget.Stretch) } -> List(Shapes.Shape)
page_of = |{ lines, stretches }|
	ScrubWidget.frame_shapes({
		picture: [],
		dot_at: Fraction.zero,
		marked: stretches,
		status: lines,
	})

# With no ruler a page is the panel and its text.
expect ScrubWidget.still_frame_shapes({ picture: [], status: [] }).len() == 1
expect ScrubWidget.still_frame_shapes({ picture: [], status: ["I"] }).len() == 2

# Each row of the readout sits under the last, in monospace.
expect
	ScrubWidget.readout({ text: "I", color: 0x202020, row: 1 })
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
	ScrubWidget.label({ text: "I", x: 3.0, y: 4.0 })
		== Text({
			text: "I",
			x: 3.0,
			y: 4.0,
			size: ScrubWidget.label_size,
			face: Prose,
			align: Left,
			color: Brush.opaque(0x202020),
		})

# The panel, the bar, the dot; then a shape for each stretch and each line.
expect page_of({ lines: [], stretches: [] }).len() == 3
expect
	page_of({ lines: [], stretches: [{ from: Fraction.zero, to: Fraction.whole }] }).len()
		== 4
expect page_of({ lines: ["I"], stretches: [] }).len() == 4
