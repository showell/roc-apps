## The widget for the Safari tutorial's setting sun. Six buttons, like a video
## recorder's, run the ride's clock forward and back or step it one at a time,
## and each frame is worked out from that clock alone. A click anywhere else does nothing. The picture is
## the ride's own sky, looking straight at the sun, drawn by Backdrop at two
## thirds of its size. Below it, lines of text read out the calls to Sky, and a
## small chart plots their answers over the whole sunset. The book opens it at
## one of three jobs, and each job adds a call.
import game.Clock
import game.Lens
import game.Pixels
import game.Sky
import game.Sun
import lib.CanvasApp
import lib.Input
import lib.Shapes
import lib.RgbColor
import widget.ScrubWidget
import widget.VcrButtons

SkyWidgetApp :: [].{

	## How much of the sunset the widget does.
	Job : [SunSets, SkyDarkens, HorizonWarms]

	## The whole state of the widget: the buttons, which hold the ride's clock,
	## and the job.
	Model : { transport : VcrButtons.Transport(Clock), job : SkyWidgetApp.Job }

	canvas_app : CanvasApp.CanvasApp(SkyWidgetApp.Model)
	canvas_app = ScrubWidget.canvas_app({
		title: "The sun going down",
		init: at_start,
		model_at_next_step: next_model,
		frame_shapes: shapes_at,
	})
}

## The widget as it opens.
at_start : SkyWidgetApp.Model
at_start = { transport: VcrButtons.transport_at(sunset.first), job: SunSets }

## The sunset, in twelve seconds, from the ride's start to a little after full
## dusk.
sunset : VcrButtons.NumberRange(Clock)
sunset = VcrButtons.clock_range({
	first_step: 0,
	last_step: 6000,
	steps_a_frame: 8.0,
})

## The model after one frame: the buttons, and the Right key, which is how the
## page opens at a job.
next_model : SkyWidgetApp.Model, Input.Snapshot -> SkyWidgetApp.Model
next_model = |model, input| {
	job =
		if input.key_pressed(KeyRight) {
			next_job(model.job)
		} else {
			model.job
		}
	{ transport: VcrButtons.next_transport(model.transport, { input, range: sunset }), job }
}

next_job : SkyWidgetApp.Job -> SkyWidgetApp.Job
next_job = |job|
	match job {
		SunSets => SkyDarkens
		SkyDarkens => HorizonWarms
		HorizonWarms => SunSets
	}

## Everything on the canvas.
shapes_at : SkyWidgetApp.Model -> List(Shapes.Shape)
shapes_at = |{ transport, job }| {
	clock = transport.at
	[
		VcrButtons.frame_shapes(
			transport,
			{
				range: sunset,
				picture_shapes: picture_shapes(job, clock),
				status_lines: [],
			},
		),
		call_lines(job, clock),
		chart_shapes(job),
		cursor_shapes(job, clock),
	].join()
}

## The two colors of the sky, as far as `job` goes.
sky_colors : SkyWidgetApp.Job, Clock -> Sky.Colors
sky_colors = |job, clock|
	match job {
		SunSets => {
			day = Sky.colors_at(Clock.start).top
			{ top: day, horizon: day }
		}
		SkyDarkens => {
			now = Sky.colors_at(clock).top
			{ top: now, horizon: now }
		}
		HorizonWarms => Sky.colors_at(clock)
	}

## The ride's sky at `clock`, for a rider facing the sun.
picture_shapes : SkyWidgetApp.Job, Clock -> List(Shapes.Shape)
picture_shapes = |job, clock|
	ScrubWidget.ride_shapes_in(
		[],
		{
			sky_colors: sky_colors(job, clock),
			sun_sighting: Sun.sighting({ heading: Sun.bearing, cam_focal: Lens.resting_focal }, clock),
		},
	)

## The calls this widget makes at `clock`, and their answers, a line each.
status_lines : SkyWidgetApp.Job, Clock -> List(Str)
status_lines = |job, clock|
	[
		"clock = step ${clock.to_str()}",
		"Sun.height(clock) = ${height_text(Sun.height(clock))}",
		"Sky.dusk_at(clock) = ${ScrubWidget.percent_text(Sky.dusk_at(clock))}",
		"Sky.sunset_warmth(clock) = ${ScrubWidget.percent_text(Sky.sunset_warmth(clock))}",
	].take_first(curves_of(job) + 1)

## How many curves `job` has on its chart.
curves_of : SkyWidgetApp.Job -> U64
curves_of = |job|
	match job {
		SunSets => 1
		SkyDarkens => 2
		HorizonWarms => 3
	}

## How high the sun stands, with a minus sign below the horizon.
height_text : Pixels -> Str
height_text = |height|
	if height < Pixels.zero {
		"-${ScrubWidget.tenths_text(height.opposite().to_f64())} px"
	} else {
		"${ScrubWidget.tenths_text(height.to_f64())} px"
	}

clock_color : RgbColor
clock_color = RgbColor.of(0x202020)

sun_color : RgbColor
sun_color = RgbColor.of(0x9A6A00)

dusk_color : RgbColor
dusk_color = RgbColor.of(0x24406E)

warmth_color : RgbColor
warmth_color = RgbColor.of(0xC0392B)

## The status lines, each in the color of its curve on the chart.
call_lines : SkyWidgetApp.Job, Clock -> List(Shapes.Shape)
call_lines = |job, clock|
	List.map2(
		status_lines(job, clock),
		[clock_color, sun_color, dusk_color, warmth_color],
		|text, color| { text, color },
	).map_with_index(|{ text, color }, row| ScrubWidget.readout({ text, color, row }))

chart_left : F64
chart_left = 372.0

chart_right : F64
chart_right = 616.0

chart_top : F64
chart_top = 250.0

chart_bottom : F64
chart_bottom = 348.0

## Where a share of the sunset is across the chart.
chart_x : F64 -> F64
chart_x = |share| chart_left + (chart_right - chart_left) * share

## Where a level from 0 to 1 is up the chart.
chart_y : F64 -> F64
chart_y = |level| chart_bottom - (chart_bottom - chart_top) * level

## The sun's height as a level on the chart, from its lowest to its highest.
sun_level : Clock -> F64
sun_level = |clock| {
	lowest = Sun.height(sunset.last)
	Sun.height(clock).minus(lowest).ratio_to(Sun.height_at_start.minus(lowest))
}

dusk_level : Clock -> F64
dusk_level = |clock| Sky.dusk_at(clock).to_f64()

warmth_level : Clock -> F64
warmth_level = |clock| Sky.sunset_warmth(clock).to_f64()

## Where the chart shows `level_at` at `clock`.
chart_point : Clock, (Clock -> F64) -> { x : F64, y : F64 }
chart_point = |clock, level_at| {
	x: chart_x(clock.to_f64() / sunset.last.to_f64()),
	y: chart_y(level_at(clock)),
}

## The clocks a curve is drawn through, every hundred steps.
chart_clocks : List(Clock)
chart_clocks = List.from_iter(U32.until(0, 61)).map(|i| Clock.at_step(i * 100))

## One curve of the chart.
curve_shapes : (Clock -> F64), RgbColor -> List(Shapes.Shape)
curve_shapes = |level_at, color| {
	points = chart_clocks.map(|clock| chart_point(clock, level_at))
	List.map2(
		points,
		points.drop_first(1),
		|a, b| Shapes.line({ from: a, to: b, width: 2.0 }, ScrubWidget.flat(color)),
	)
}

## The chart's curves, which are the same at every clock.
all_curves : List(List(Shapes.Shape))
all_curves = [
	curve_shapes(sun_level, sun_color),
	curve_shapes(dusk_level, dusk_color),
	curve_shapes(warmth_level, warmth_color),
]

## The curves `job` has got to.
chart_shapes : SkyWidgetApp.Job -> List(Shapes.Shape)
chart_shapes = |job| all_curves.take_first(curves_of(job)).join()

## A line down the chart at `clock`, with a dot on each curve.
cursor_shapes : SkyWidgetApp.Job, Clock -> List(Shapes.Shape)
cursor_shapes = |job, clock| {
	x = chart_point(clock, dusk_level).x
	[
		[
			Shapes.line(
				{ from: { x, y: chart_top }, to: { x, y: chart_bottom }, width: 1.0 },
				ScrubWidget.flat(clock_color),
			),
		],
		[
			curve_dot(chart_point(clock, sun_level), sun_color),
			curve_dot(chart_point(clock, dusk_level), dusk_color),
			curve_dot(chart_point(clock, warmth_level), warmth_color),
		].take_first(curves_of(job)),
	].join()
}

curve_dot : { x : F64, y : F64 }, RgbColor -> Shapes.Shape
curve_dot = |{ x, y }, color|
	Disc({
		x,
		y,
		radius: 4.0,
		fill: ScrubWidget.flat(color),
	})

expect
	status_lines(HorizonWarms, Clock.start)
		== [
			"clock = step 0",
			"Sun.height(clock) = 244.0 px",
			"Sky.dusk_at(clock) = 0%",
			"Sky.sunset_warmth(clock) = 0%",
		]

expect
	status_lines(HorizonWarms, Clock.at_step(3000))
		== [
			"clock = step 3000",
			"Sun.height(clock) = 60.3 px",
			"Sky.dusk_at(clock) = 24%",
			"Sky.sunset_warmth(clock) = 45%",
		]

expect
	status_lines(HorizonWarms, sunset.last)
		== [
			"clock = step 6000",
			"Sun.height(clock) = -123.5 px",
			"Sky.dusk_at(clock) = 100%",
			"Sky.sunset_warmth(clock) = 0%",
		]

# The chart's levels stay on the chart: the sun runs from top to bottom.
expect sun_level(Clock.start) == 1.0
expect sun_level(sunset.last) == 0.0
expect chart_clocks.len() == 61
expect chart_shapes(HorizonWarms).len() == 180
expect chart_shapes(SkyDarkens).len() == 120
expect chart_shapes(SunSets).len() == 60

# Each job adds a call to the lines under the picture.
expect status_lines(SunSets, Clock.start).len() == 2
expect status_lines(SkyDarkens, Clock.start).len() == 3
expect status_lines(HorizonWarms, Clock.start).len() == 4

# The sky holds at day for the first job, darkens evenly for the second, and
# warms at the horizon only for the third.
expect sky_colors(SunSets, Clock.at_step(3980)) == sky_colors(SunSets, Clock.start)
expect sky_colors(SkyDarkens, Clock.at_step(3980)) != sky_colors(SkyDarkens, Clock.start)
expect {
	even = sky_colors(SkyDarkens, Clock.at_step(3980))
	even.top == even.horizon
}
expect {
	warm = sky_colors(HorizonWarms, Clock.at_step(3980))
	warm.top != warm.horizon
}

## The widget at `step`, stopped.
stopped_at : U32 -> SkyWidgetApp.Model
stopped_at = |step| { ..at_start, transport: VcrButtons.transport_at(Clock.at_step(step)) }

## What a press of `control` does, after that frame.
pressed_on : SkyWidgetApp.Model, VcrButtons.Control -> SkyWidgetApp.Model
pressed_on = |model, control| next_model(model, VcrButtons.click_on(control))

# The buttons run over the sunset, eight steps a frame and one step at a press.
expect pressed_on(at_start, Play).transport == { at: Clock.at_step(8), motion: Forward }
expect pressed_on(stopped_at(100), StepBack).transport.at == Clock.at_step(99)
expect pressed_on(stopped_at(100), StepForward).transport.at == Clock.at_step(101)
expect pressed_on(stopped_at(100), ToStart).transport.at == Clock.start
expect pressed_on(at_start, ToEnd).transport.at == sunset.last

# The Right key moves through the jobs, and the pointer leaves them alone.
expect next_job(SunSets) == SkyDarkens
expect next_job(SkyDarkens) == HorizonWarms
expect next_job(HorizonWarms) == SunSets
expect next_model(at_start, Input.none.with_key_pressed(KeyRight)).job == SkyDarkens
expect next_model({ ..at_start, job: SkyDarkens }, Input.none).job == SkyDarkens
expect pressed_on({ ..at_start, job: SkyDarkens }, Play).job == SkyDarkens

# The chart's two ends are the sunset's two ends.
expect chart_point(Clock.start, dusk_level).x == chart_left
expect chart_point(sunset.last, dusk_level).x == chart_right
expect chart_point(Clock.start, dusk_level).y == chart_bottom
expect chart_point(Clock.start, sun_level).y == chart_top

# The cursor is a line and three dots.
expect cursor_shapes(HorizonWarms, Clock.at_step(3000)).len() == 4
expect cursor_shapes(SunSets, Clock.at_step(3000)).len() == 2

# The hint goes once the clock has moved.
expect shapes_at(at_start).len() > shapes_at(stopped_at(1)).len()

# Two view marks around the sky, the grass, the glow and the sun.
expect picture_shapes(HorizonWarms, Clock.start).len() == 6

# The picture depends on the clock and on nothing else.
expect picture_shapes(HorizonWarms, Clock.at_step(3000)) == picture_shapes(HorizonWarms, Clock.at_step(3000))
expect picture_shapes(HorizonWarms, Clock.at_step(3000)) != picture_shapes(HorizonWarms, Clock.at_step(3001))
