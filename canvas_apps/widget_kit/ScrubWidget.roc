## A scrub widget is a small canvas app for the Safari tutorial whose whole
## state is one number, set by dragging across the canvas. Every frame is a pure
## function of that number, so what it shows plays forward and backward under
## the pointer. This module holds what each widget has in common: reading the
## pointer into the number, and laying out the picture, the ruler under it and
## the lines of text below that. A widget says what the number means.
import game.Fraction
import lib.Brush
import lib.CanvasApp
import lib.Font
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
	canvas_app = |
		{
			title,
			init,
			model_at,
			frame,
		},
	| {
		size: { width: canvas_width, height: canvas_height },
		fps: 60,
		init,
		advance: |
			model,
			input,
			_seconds,
		| followed_pointer(model, { input, model_at }),
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

	## How far across the canvas a pointer at `x` is. During a drag it may be
	## off the canvas.
	share_under : F64 -> Fraction
	share_under = |x| Fraction.clamp(x / canvas_width)

	flat : I64 -> Brush.Fill
	flat = |color| Flat(Brush.opaque(color))

	## Everything on the canvas.
	frame_shapes : ScrubWidget.Page -> List(Shapes.Shape)
	frame_shapes = |
		{
			picture,
			dot_at,
			marked,
			status,
		},
	|
		[
			picture,
			[panel],
			ruler({ dot_at, marked }),
			status.map_with_index(status_line).join(),
		].join()

	## A number of at least zero, to one decimal place.
	tenths_text : F64 -> Str
	tenths_text = |number| {
		tenths = (number * 10.0 + 0.5).to_i64_wrap()
		"${(tenths // 10).to_str()}.${(tenths % 10).to_str()}"
	}

	## A fraction as a whole percentage, rounded down.
	percent_text : Fraction -> Str
	percent_text = |fraction| "${(fraction.to_f64() * 100.0).to_i64_wrap().to_str()}%"
}

panel_color : I64
panel_color = 0xdcecf5

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
ruler_x = |share| ScrubWidget.canvas_width * share.to_f64()

## A bar across the canvas, 6 px thick, in `color`, from `x` for `width`.
bar : {
	x : F64,
	width : F64,
	color : I64,
} -> Shapes.Shape
bar = |
	{
		x,
		width,
		color,
	},
|
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
				x: 0.0,
				width: ScrubWidget.canvas_width,
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

status_line : Str, U64 -> List(Shapes.Shape)
status_line = |text, row|
	Font.text(
		text,
		20.0,
		252.0 + row.to_f64() * 26.0,
		16.0,
		Brush.opaque(0x202020),
	)

expect ScrubWidget.share_under(0.0 - 5.0) == Fraction.zero
expect ScrubWidget.share_under(0.0) == Fraction.zero
expect ScrubWidget.share_under(ScrubWidget.canvas_width) == Fraction.whole
expect ScrubWidget.share_under(ScrubWidget.canvas_width + 5.0) == Fraction.whole
expect ScrubWidget.share_under(160.0) == Fraction.of(0.25)
expect ruler_x(ScrubWidget.share_under(160.0)) == 160.0

## A snapshot with the left button held or not, the pointer mid-canvas.
pointer_at_middle : U32 -> Input.Snapshot
pointer_at_middle = |held| Input.none.with_mouse(
	Mouse.of(
		held,
		0,
		320.0,
		0.0,
		0.0,
	),
)

## The model after a step from 0.7, with the left button held or not.
stepped_from_seven_tenths : U32 -> F64
stepped_from_seven_tenths = |held|
	ScrubWidget.followed_pointer(
		0.7,
		{
			input: pointer_at_middle(held),
			model_at: |share| share.to_f64(),
		},
	)

expect stepped_from_seven_tenths(1) == 0.5
expect stepped_from_seven_tenths(0) == 0.7

expect ScrubWidget.tenths_text(0.0) == "0.0"
expect ScrubWidget.tenths_text(0.04) == "0.0"
expect ScrubWidget.tenths_text(0.06) == "0.1"
expect ScrubWidget.tenths_text(21.0) == "21.0"
expect ScrubWidget.tenths_text(9.96) == "10.0"

expect ScrubWidget.percent_text(Fraction.zero) == "0%"
expect ScrubWidget.percent_text(Fraction.of(0.529)) == "52%"
expect ScrubWidget.percent_text(Fraction.whole) == "100%"

## A page with `count` lines of text and `stretches` marked stretches.
page_of : { lines : List(Str), stretches : List(ScrubWidget.Stretch) } -> List(Shapes.Shape)
page_of = |{ lines, stretches }|
	ScrubWidget.frame_shapes({
		picture: [],
		dot_at: Fraction.zero,
		marked: stretches,
		status: lines,
	})

# The panel, the bar, the dot; then a shape for each stretch, and more for text.
expect page_of({ lines: [], stretches: [] }).len() == 3
expect
	page_of({
		lines: [],
		stretches: [{ from: Fraction.zero, to: Fraction.whole }],
	}).len()
		== 4
expect page_of({ lines: ["I"], stretches: [] }).len() > 3
