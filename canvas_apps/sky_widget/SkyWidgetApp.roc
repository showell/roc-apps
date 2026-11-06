## The widget for the Safari tutorial's setting sun. Dragging across the canvas
## sets the ride's clock, and each frame is worked out from that clock alone, so
## the sun sets and rises again under the pointer. The picture is the ride's own
## sky, looking straight at the sun, drawn by Backdrop at two thirds of its
## size. Below it, a ruler shows the clock, four lines of text read out the calls
## to Sky, and a small chart plots their answers over the whole sunset.
import game.Clock
import game.Lens
import game.Pixels
import game.Sky
import lib.Brush
import lib.CanvasApp
import lib.Font
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
clock_range = { first_step: 0.0, last_step: 6000.0 }

## Everything on the canvas at `clock`.
frame_at : Clock -> List(Shapes.Shape)
frame_at = |clock|
	[
		ScrubWidget.frame_shapes({
			picture: picture(clock),
			dot_at: ScrubWidget.step_share(clock.to_f64(), clock_range),
			marked: [warmth_stretch],
			status: [],
		}),
		call_lines(clock),
		chart,
		chart_cursor(clock),
		hint(clock),
	].join()

## The ride's sky at `clock`, for a rider facing the sun.
picture : Clock -> List(Shapes.Shape)
picture = |clock|
	ScrubWidget.ride_picture(
		[],
		{
			clock,
			sun: Sky.sun_sighting({ heading: Sky.sun_bearing, clock, cam_focal: Lens.focal }),
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

## The calls this widget makes at `clock`, and their answers, a line each.
status_lines : Clock -> List(Str)
status_lines = |clock|
	[
		"clock = step ${clock.to_str()}",
		"Sky.sun_height_px(clock) = ${height_text(Sky.sun_height_px(clock))}",
		"Sky.dusk_at(clock) = ${ScrubWidget.percent_text(Sky.dusk_at(clock))}",
		"Sky.sunset_warmth(clock) = ${ScrubWidget.percent_text(Sky.sunset_warmth(clock))}",
	]

## How high the sun stands, with a minus sign below the horizon.
height_text : Pixels -> Str
height_text = |height|
	if height < Pixels.zero {
		"-${ScrubWidget.tenths_text(height.opposite().to_f64())} px"
	} else {
		"${ScrubWidget.tenths_text(height.to_f64())} px"
	}

clock_color : I64
clock_color = 0x202020

sun_color : I64
sun_color = 0x9a6a00

dusk_color : I64
dusk_color = 0x24406e

warmth_color : I64
warmth_color = 0xc0392b

## The status lines, each in the color of its curve on the chart.
call_lines : Clock -> List(Shapes.Shape)
call_lines = |clock|
	List.map2(
		status_lines(clock),
		[clock_color, sun_color, dusk_color, warmth_color],
		|text, color| { text, color },
	).map_with_index(call_line).join()

call_line : { text : Str, color : I64 }, U64 -> List(Shapes.Shape)
call_line = |{ text, color }, row|
	Font.text(
		text,
		ScrubWidget.side_margin,
		252.0 + row.to_f64() * 26.0,
		10.5,
		Brush.opaque(color),
	)

chart_left : F64
chart_left = 372.0

chart_right : F64
chart_right = 616.0

chart_top : F64
chart_top = 250.0

chart_bottom : F64
chart_bottom = 348.0

## Where a share of the ruler is across the chart.
chart_x : F64 -> F64
chart_x = |share| chart_left + (chart_right - chart_left) * share

## Where a level from 0 to 1 is up the chart.
chart_y : F64 -> F64
chart_y = |level| chart_bottom - (chart_bottom - chart_top) * level

## The sun's height as a level on the chart, from its lowest to its highest.
sun_level : Clock -> F64
sun_level = |clock| {
	lowest = Sky.sun_height_px(Clock.at_step(6000))
	Sky.sun_height_px(clock).minus(lowest).ratio_to(Sky.sun_start_px.minus(lowest))
}

dusk_level : Clock -> F64
dusk_level = |clock| Sky.dusk_at(clock).to_f64()

warmth_level : Clock -> F64
warmth_level = |clock| Sky.sunset_warmth(clock).to_f64()

## Where the chart shows `level_at` at `clock`.
chart_point : Clock, (Clock -> F64) -> { x : F64, y : F64 }
chart_point = |clock, level_at| {
	x: chart_x(ScrubWidget.step_share(clock.to_f64(), clock_range).to_f64()),
	y: chart_y(level_at(clock)),
}

## The clocks a curve is drawn through, every hundred steps.
chart_clocks : List(Clock)
chart_clocks = List.from_iter(U32.until(0, 61)).map(|i| Clock.at_step(i * 100))

## One curve of the chart.
curve : (Clock -> F64), I64 -> List(Shapes.Shape)
curve = |level_at, color| {
	points = chart_clocks.map(|clock| chart_point(clock, level_at))
	List.map2(
		points,
		points.drop_first(1),
		|a, b| Shapes.line(
			a.x,
			a.y,
			b.x,
			b.y,
			2.0,
			ScrubWidget.flat(color),
		),
	)
}

## The whole chart, which is the same at every clock.
chart : List(Shapes.Shape)
chart = [
	curve(sun_level, sun_color),
	curve(dusk_level, dusk_color),
	curve(warmth_level, warmth_color),
].join()

## A line down the chart at `clock`, with a dot on each curve.
chart_cursor : Clock -> List(Shapes.Shape)
chart_cursor = |clock| {
	x = chart_point(clock, dusk_level).x
	[
		[
			Shapes.line(
				x,
				chart_top,
				x,
				chart_bottom,
				1.0,
				ScrubWidget.flat(clock_color),
			),
		],
		[
			curve_dot(chart_point(clock, sun_level), sun_color),
			curve_dot(chart_point(clock, dusk_level), dusk_color),
			curve_dot(chart_point(clock, warmth_level), warmth_color),
		],
	].join()
}

curve_dot : { x : F64, y : F64 }, I64 -> Shapes.Shape
curve_dot = |{ x, y }, color|
	Disc({
		x,
		y,
		r: 4.0,
		fill: ScrubWidget.flat(color),
		clip: Anywhere,
	})

## A word for a reader who hasn't touched the widget yet.
hint : Clock -> List(Shapes.Shape)
hint = |clock|
	if clock == Clock.start {
		Font.text(
			"Drag me",
			16.0,
			16.0,
			16.0,
			Brush.opaque(0xffffff),
		)
	} else {
		[]
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
			"clock = step 0",
			"Sky.sun_height_px(clock) = 244.0 px",
			"Sky.dusk_at(clock) = 0%",
			"Sky.sunset_warmth(clock) = 0%",
		]

expect
	status_lines(Clock.at_step(3000))
		== [
			"clock = step 3000",
			"Sky.sun_height_px(clock) = 60.2 px",
			"Sky.dusk_at(clock) = 23%",
			"Sky.sunset_warmth(clock) = 45%",
		]

expect
	status_lines(Clock.at_step(6000))
		== [
			"clock = step 6000",
			"Sky.sun_height_px(clock) = -123.6 px",
			"Sky.dusk_at(clock) = 100%",
			"Sky.sunset_warmth(clock) = 0%",
		]

# The chart's levels stay on the chart: the sun runs from top to bottom.
expect sun_level(Clock.start) == 1.0
expect sun_level(Clock.at_step(6000)) == 0.0
expect chart_clocks.len() == 61
expect chart.len() == 180

# The chart's two ends are the ruler's two ends.
expect chart_point(Clock.start, dusk_level).x == chart_left
expect chart_point(Clock.at_step(6000), dusk_level).x == chart_right
expect chart_point(Clock.start, dusk_level).y == chart_bottom
expect chart_point(Clock.start, sun_level).y == chart_top

# The cursor is a line and three dots.
expect chart_cursor(Clock.at_step(3000)).len() == 4

# The hint shows until the clock has moved, and the frame carries it.
expect hint(Clock.start).len() > 0
expect hint(Clock.at_step(1)).len() == 0
expect frame_at(Clock.start).len() > frame_at(Clock.at_step(1)).len()

# Two view marks around the sky, the grass, the glow and the sun.
expect picture(Clock.start).len() == 6

# The picture depends on the clock and on nothing else.
expect picture(Clock.at_step(3000)) == picture(Clock.at_step(3000))
expect picture(Clock.at_step(3000)) != picture(Clock.at_step(3001))
