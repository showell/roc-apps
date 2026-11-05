## The widget for the Safari tutorial's sky. Dragging across the canvas sets
## the ride's clock, and each frame is worked out from that clock alone, so the
## sun sets and rises again under the pointer. The picture is the ride's own
## sky, looking straight at the sun, drawn by SafariShapes at two thirds of its
## size. Below it, a ruler shows the clock, and four lines of text read out
## what Sky makes of it.
import game.Clock
import game.Fraction
import game.Lens
import game.SafariShapes
import game.Screen
import game.Sky
import lib.Brush
import lib.CanvasApp
import lib.Font
import lib.Input
import lib.Mouse
import lib.Shapes

SkyWidgetApp :: [].{

	## The whole state of the widget: the ride's clock.
	Model : { clock : Clock }

	canvas_app : CanvasApp.CanvasApp(SkyWidgetApp.Model)
	canvas_app = {
		size: { width: canvas_width, height: canvas_height },
		fps: 60,
		init: { clock: Clock.start },
		advance: |
			model,
			input,
			_seconds,
		| followed_pointer(model, input),
		frame: |model| frame_at(model.clock),
		sounds: |_model| 0,
		tones: [],
		title: "The sun going down",
	}
}

canvas_width : F64
canvas_width = 640.0

canvas_height : F64
canvas_height = 360.0

## The clock at the canvas's right edge, after full dusk. At its left edge the
## ride starts.
last_step : F64
last_step = 6000.0

## The model after one step: a pointer held down sets the clock, and the clock
## stays where it is left.
followed_pointer : SkyWidgetApp.Model, Input.Snapshot -> SkyWidgetApp.Model
followed_pointer = |model, input|
	if input.mouse.button_down(Left) {
		{ clock: clock_under(input.mouse.position().x.to_f64()) }
	} else {
		model
	}

## The clock under a pointer at `x`, which may be off the canvas during a drag.
clock_under : F64 -> Clock
clock_under = |x|
	Clock.at_step((last_step * Brush.clamp01(x / canvas_width)).to_u32_wrap())

## Where step `step` sits on the ruler.
ruler_x : F64 -> F64
ruler_x = |step| canvas_width * step / last_step

## Everything on the canvas at `clock`.
frame_at : Clock -> List(Shapes.Shape)
frame_at = |clock|
	[
		picture(clock),
		[panel],
		ruler(clock),
		status_lines(clock).map_with_index(status_line).join(),
	].join()

## How much smaller Safari's screen is in the picture.
picture_zoom : F64
picture_zoom = 2.0 / 3.0

## The top of the panel under the picture, where a strip of grass ends.
panel_top_y : F64
panel_top_y = 216.0

## The ride's sky at `clock`, for a rider facing the sun.
picture : Clock -> List(Shapes.Shape)
picture = |clock| {
	corner = { x: 0.0, y: 0.0 }
	sky = SafariShapes.frame(
		[],
		{
			sky_top_color: Sky.sky_color(clock),
			sky_horizon_color: Sky.horizon_color(clock),
			sun_position: Sky.sun_pos({
				heading: Sky.sun_bearing,
				clock,
				cam_focal: Lens.focal,
			}),
		},
	)
	[
		[
			View(
				World({
					target: corner,
					offset: corner,
					rotation: 0.0,
					zoom: picture_zoom,
				}),
			),
		],
		sky,
		[View(Screen)],
	].join()
}

flat : I64 -> Brush.Fill
flat = |color| Flat(Brush.opaque(color))

panel : Shapes.Shape
panel = Rect({
	x: 0.0,
	y: panel_top_y,
	w: canvas_width,
	h: canvas_height - panel_top_y,
	fill: flat(0xdcecf5),
})

ruler_y : F64
ruler_y = 232.0

## The step at which the sun stands `height` pixels up.
step_at_height : F64 -> F64
step_at_height = |height| (Sky.sun_start_px - height) / Sky.sun_drop_px_per_step

## A bar with the stretch of the sunset's warmth marked on it, and a dot for
## the clock.
ruler : Clock -> List(Shapes.Shape)
ruler = |clock| {
	warmth_starts_x = ruler_x(step_at_height(Sky.warmth_falloff_px))
	warmth_ends_x = ruler_x(step_at_height(0.0 - Sky.warmth_falloff_px))
	[
		Rect({
			x: 0.0,
			y: ruler_y - 3.0,
			w: canvas_width,
			h: 6.0,
			fill: flat(0xb8b8b8),
		}),
		Rect({
			x: warmth_starts_x,
			y: ruler_y - 3.0,
			w: warmth_ends_x - warmth_starts_x,
			h: 6.0,
			fill: flat(0xd0603a),
		}),
		Disc({
			x: ruler_x(clock.to_f64()),
			y: ruler_y,
			r: 8.0,
			fill: flat(0x303030),
			clip: Anywhere,
		}),
	]
}

## What Sky says at `clock`, a line each.
status_lines : Clock -> List(Str)
status_lines = |clock|
	[
		"Clock: step ${clock.to_str()}",
		sun_text(Sky.sun_height_px(clock)),
		"Dusk: ${percent_text(Sky.dusk_at(clock))}",
		"Sunset warmth: ${percent_text(Sky.sunset_warmth(clock))}",
	]

status_line : Str, U64 -> List(Shapes.Shape)
status_line = |text, row|
	Font.text(
		text,
		20.0,
		252.0 + row.to_f64() * 26.0,
		16.0,
		Brush.opaque(0x202020),
	)

## How high the sun stands, in words.
sun_text : F64 -> Str
sun_text = |height|
	if height < 0.0 {
		"Sun: ${tenths_text(0.0 - height)} px below the horizon"
	} else {
		"Sun: ${tenths_text(height)} px above the horizon"
	}

percent_text : Fraction -> Str
percent_text = |fraction| "${(fraction.to_f64() * 100.0 + 0.5).to_i64_wrap().to_str()}%"

## A number of at least zero, to one decimal place.
tenths_text : F64 -> Str
tenths_text = |number| {
	tenths = (number * 10.0 + 0.5).to_i64_wrap()
	"${(tenths // 10).to_str()}.${(tenths % 10).to_str()}"
}

expect clock_under(0.0 - 5.0) == Clock.start
expect clock_under(0.0) == Clock.start
expect clock_under(canvas_width) == Clock.at_step(6000)
expect clock_under(canvas_width + 5.0) == Clock.at_step(6000)
expect clock_under(canvas_width / 2.0) == Clock.at_step(3000)
expect ruler_x(clock_under(160.0).to_f64()) == 160.0

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

## A model left at step 7.
left_at_seven : SkyWidgetApp.Model
left_at_seven = { clock: Clock.at_step(7) }

expect followed_pointer(left_at_seven, pointer_at_middle(1)).clock == Clock.at_step(3000)
expect followed_pointer(left_at_seven, pointer_at_middle(0)).clock == Clock.at_step(7)

expect step_at_height(Sky.sun_start_px) == 0.0
expect {
	at_horizon = Clock.at_step(step_at_height(0.0).to_u32_wrap())
	Sky.sun_height_px(at_horizon).abs() < 0.1
}

expect
	status_lines(Clock.start)
		== [
			"Clock: step 0",
			"Sun: 244.0 px above the horizon",
			"Dusk: 0%",
			"Sunset warmth: 0%",
		]

expect
	status_lines(Clock.at_step(3000))
		== [
			"Clock: step 3000",
			"Sun: 60.2 px above the horizon",
			"Dusk: 24%",
			"Sunset warmth: 45%",
		]

expect
	status_lines(Clock.at_step(6000))
		== [
			"Clock: step 6000",
			"Sun: 123.6 px below the horizon",
			"Dusk: 100%",
			"Sunset warmth: 0%",
		]

# Two view marks around the sky, the grass, the glow and the sun.
expect picture(Clock.start).len() == 6

# The picture depends on the clock and on nothing else.
expect picture(Clock.at_step(3000)) == picture(Clock.at_step(3000))
expect picture(Clock.at_step(3000)) != picture(Clock.at_step(3001))
