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
import lib.CanvasApp
import lib.Shapes
import widget.ScrubWidget

SkyWidgetApp :: [].{

	## The whole state of the widget: the ride's clock.
	Model : { clock : Clock }

	canvas_app : CanvasApp.CanvasApp(SkyWidgetApp.Model)
	canvas_app = ScrubWidget.canvas_app({
		title: "The sun going down",
		init: { clock: Clock.start },
		model_at: |share| { clock: clock_at(share) },
		frame: |model| frame_at(model.clock),
	})
}

## The clock at the canvas's right edge, after full dusk. At its left edge the
## ride starts.
last_step : F64
last_step = 6000.0

## The clock with the pointer `share` of the way across the canvas.
clock_at : Fraction -> Clock
clock_at = |share| Clock.at_step((last_step * share.to_f64()).to_u32_wrap())

## How far along the ruler step `step` sits.
share_at : F64 -> Fraction
share_at = |step| Fraction.clamp(step / last_step)

## Everything on the canvas at `clock`.
frame_at : Clock -> List(Shapes.Shape)
frame_at = |clock|
	ScrubWidget.frame_shapes({
		picture: picture(clock),
		dot_at: share_at(clock.to_f64()),
		marked: [warmth_stretch],
		status: status_lines(clock),
	})

## How much smaller Safari's screen is in the picture.
picture_zoom : F64
picture_zoom = 2.0 / 3.0

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

## The step at which the sun stands `height` pixels up.
step_at_height : F64 -> F64
step_at_height = |height| (Sky.sun_start_px - height) / Sky.sun_drop_px_per_step

## The stretch of the ruler with any warmth in the sunset.
warmth_stretch : ScrubWidget.Stretch
warmth_stretch = {
	from: share_at(step_at_height(Sky.warmth_falloff_px)),
	to: share_at(step_at_height(0.0 - Sky.warmth_falloff_px)),
}

## What Sky says at `clock`, a line each.
status_lines : Clock -> List(Str)
status_lines = |clock|
	[
		"Clock: step ${clock.to_str()}",
		sun_text(Sky.sun_height_px(clock)),
		"Dusk: ${ScrubWidget.percent_text(Sky.dusk_at(clock))}",
		"Sunset warmth: ${ScrubWidget.percent_text(Sky.sunset_warmth(clock))}",
	]

## How high the sun stands, in words.
sun_text : F64 -> Str
sun_text = |height|
	if height < 0.0 {
		"Sun: ${ScrubWidget.tenths_text(0.0 - height)} px below the horizon"
	} else {
		"Sun: ${ScrubWidget.tenths_text(height)} px above the horizon"
	}

expect clock_at(Fraction.zero) == Clock.start
expect clock_at(Fraction.whole) == Clock.at_step(6000)
expect clock_at(Fraction.of(0.5)) == Clock.at_step(3000)
expect share_at(1500.0) == Fraction.of(0.25)
expect share_at(7000.0) == Fraction.whole
expect warmth_stretch.from.to_f64() < warmth_stretch.to.to_f64()

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
			"Dusk: 23%",
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
