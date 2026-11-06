## The widget for the Safari tutorial's sky. Dragging across the canvas sets
## the ride's clock, and each frame is worked out from that clock alone, so the
## sun sets and rises again under the pointer. The picture is the ride's own
## sky, looking straight at the sun, drawn by Backdrop at two thirds of its
## size. Below it, a ruler shows the clock, and four lines of text read out
## what Sky makes of it.
import game.Clock
import game.Lens
import game.Pixels
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
		model_at: |share| { clock: ScrubWidget.clock_at(share, clock_range) },
		frame: |model| frame_at(model.clock),
	})
}

## The ruler runs from the ride's start to a little after full dusk.
clock_range : ScrubWidget.ClockRange
clock_range = {
	first_step: 0.0,
	last_step: 6000.0,
}

## Everything on the canvas at `clock`.
frame_at : Clock -> List(Shapes.Shape)
frame_at = |clock|
	ScrubWidget.frame_shapes({
		picture: picture(clock),
		dot_at: ScrubWidget.step_share(clock.to_f64(), clock_range),
		marked: [warmth_stretch],
		status: status_lines(clock),
	})

## The ride's sky at `clock`, for a rider facing the sun.
picture : Clock -> List(Shapes.Shape)
picture = |clock|
	ScrubWidget.ride_picture(
		[],
		{
			clock,
			sun: Sky.sun_sighting({
				heading: Sky.sun_bearing,
				clock,
				cam_focal: Lens.focal,
			}),
		},
	)

## The step at which the sun stands `height` pixels up.
step_at_height : Pixels -> F64
step_at_height = |height| Sky.sun_start_px.minus(height).ratio_to(Sky.sun_drop_px_per_step)

## The stretch of the ruler with any warmth in the sunset.
warmth_stretch : ScrubWidget.Stretch
warmth_stretch = {
	from: ScrubWidget.step_share(step_at_height(Sky.warmth_falloff_px), clock_range),
	to: ScrubWidget.step_share(step_at_height(Sky.warmth_falloff_px.opposite()), clock_range),
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
sun_text : Pixels -> Str
sun_text = |height|
	if height < Pixels.zero {
		"Sun: ${ScrubWidget.tenths_text(height.opposite().to_f64())} px below the horizon"
	} else {
		"Sun: ${ScrubWidget.tenths_text(height.to_f64())} px above the horizon"
	}

expect warmth_stretch.from.to_f64() < warmth_stretch.to.to_f64()

expect step_at_height(Sky.sun_start_px) == 0.0
expect {
	at_horizon = Clock.at_step(step_at_height(Pixels.zero).to_u32_wrap())
	Sky.sun_height_px(at_horizon).abs() < Pixels.of(0.1)
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
