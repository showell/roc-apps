## The widget for the Safari tutorial's setting sun. Six buttons, like a video
## recorder's, run the ride's clock forward and back or step it one at a time,
## and each frame is worked out from that clock alone. A click anywhere else does nothing. The picture is
## the ride's own sky, looking straight at the sun, drawn by Sky and Sun at two
## thirds of its size. Below it, lines of text read out the calls to Sky, and a
## small chart plots their answers over the whole sunset. The book opens it at
## one of three jobs, and each job adds a call.
import game.Angle
import game.Clock
import game.Lens
import game.Pixels
import game.Sky
import game.Steps
import game.Sun
import lib.Brush
import lib.CanvasApp
import lib.Input
import lib.Shapes
import lib.RgbColor
import widget.ReadoutText
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
## night.
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
	ScrubWidget.ride_shapes({
		backdrop: {
			sky_colors: sky_colors(job, clock),
			sun_sighting: Sun.sighting({ heading: Sun.bearing, cam_focal: Lens.resting_focal }, clock),
		},
		ride_shapes: [],
		roll: Angle.upright,
	})

## One call to Sky or Sun that the chart plots: the line of text that reads out
## the call at a clock, where its answer sits up the chart at that clock, from 0
## at the bottom to 1 at the top, and the color of both.
Curve : {
	call_line : Clock -> Str,
	level_at : Clock -> F64,
	color : RgbColor,
}

## A line of the readout, in its color.
CallRow : { text : Str, color : RgbColor }

sun_curve : Curve
sun_curve = {
	call_line: |clock| "Sun.height_at(clock) = ${height_text(Sun.height_at(clock))}",
	level_at: sun_level,
	color: sun_color,
}

darkness_curve : Curve
darkness_curve = {
	call_line: |clock| "Sky.darkness_at(clock) = ${ReadoutText.percent_text(Sky.darkness_at(clock))}",
	level_at: darkness_level,
	color: darkness_color,
}

warmth_curve : Curve
warmth_curve = {
	call_line: |clock| "Sky.horizon_warmth_at(clock) = ${ReadoutText.percent_text(Sky.horizon_warmth_at(clock))}",
	level_at: warmth_level,
	color: warmth_color,
}

## The curves `job` has got to. Each job adds one.
job_curves : SkyWidgetApp.Job -> List(Curve)
job_curves = |job|
	match job {
		SunSets => [sun_curve]
		SkyDarkens => [sun_curve, darkness_curve]
		HorizonWarms => [sun_curve, darkness_curve, warmth_curve]
	}

## The clock, then each call `job` makes at `clock` and its answer, a row each.
call_rows : SkyWidgetApp.Job, Clock -> List(CallRow)
call_rows = |job, clock| {
	clock_row = { text: "clock = step ${clock.to_str()}", color: clock_color }
	job_curves(job).map(|curve| { text: (curve.call_line)(clock), color: curve.color }).prepend(clock_row)
}

## How high the sun stands, in pixels, negative below the horizon.
height_text : Pixels -> Str
height_text = |height|
	"${ReadoutText.tenths_text(height.to_f64())} px"

clock_color : RgbColor
clock_color = RgbColor.of(0x202020)

sun_color : RgbColor
sun_color = RgbColor.of(0x9A6A00)

darkness_color : RgbColor
darkness_color = RgbColor.of(0x24406E)

warmth_color : RgbColor
warmth_color = RgbColor.of(0xC0392B)

## The rows of the readout, each in the color of its curve on the chart.
call_lines : SkyWidgetApp.Job, Clock -> List(Shapes.Shape)
call_lines = |job, clock|
	call_rows(job, clock).map_with_index(
		|{ text, color }, row| ScrubWidget.readout({ text, color, row, style: ScrubWidget.panel_readout }),
	)

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
	lowest = Sun.height_at(sunset.last)
	Sun.height_at(clock).minus(lowest).portion(Sun.height_at_start.minus(lowest))
}

darkness_level : Clock -> F64
darkness_level = |clock| Sky.darkness_at(clock).to_f64()

warmth_level : Clock -> F64
warmth_level = |clock| Sky.horizon_warmth_at(clock).to_f64()

## Where the chart shows `level_at` at `clock`.
chart_point : Clock, (Clock -> F64) -> { x : F64, y : F64 }
chart_point = |clock, level_at| {
	x: chart_x(clock.to_f64() / sunset.last.to_f64()),
	y: chart_y(level_at(clock)),
}

## How far apart the clocks a curve is drawn through are.
chart_spacing : Steps
chart_spacing = Steps.of(100)

## The clocks a curve is drawn through, from the sunset's start to its end.
chart_clocks : List(Clock)
chart_clocks = {
	spaces = sunset.last.steps_since(sunset.first).to_u32() // chart_spacing.to_u32()
	List.from_iter(U32.until(0, spaces + 1)).map(|space| sunset.first.plus(chart_spacing.times(space)))
}

## One curve of the chart.
curve_shapes : Curve -> List(Shapes.Shape)
curve_shapes = |{ level_at, color, .. }| {
	points = chart_clocks.map(|clock| chart_point(clock, level_at))
	List.map2(
		points,
		points.drop_first(1),
		|a, b| Shapes.line({ from: a, to: b, width: 2.0 }, Brush.flat(color)),
	)
}

## The curves `job` has got to.
chart_shapes : SkyWidgetApp.Job -> List(Shapes.Shape)
chart_shapes = |job| job_curves(job).join_map(curve_shapes)

## A line down the chart at `clock`, with a dot on each curve.
cursor_shapes : SkyWidgetApp.Job, Clock -> List(Shapes.Shape)
cursor_shapes = |job, clock| {
	x = chart_point(clock, darkness_level).x
	cursor =
		Shapes.line(
			{ from: { x, y: chart_top }, to: { x, y: chart_bottom }, width: 1.0 },
			Brush.flat(clock_color),
		)
	job_curves(job).map(|curve| curve_dot(chart_point(clock, curve.level_at), curve.color)).prepend(cursor)
}

curve_dot : { x : F64, y : F64 }, RgbColor -> Shapes.Shape
curve_dot = |{ x, y }, color|
	Disc({
		x,
		y,
		radius: 4.0,
		fill: Brush.flat(color),
	})

## The text of the rows `job` reads out at `clock`.
row_texts : SkyWidgetApp.Job, Clock -> List(Str)
row_texts = |job, clock| call_rows(job, clock).map(|row| row.text)

expect
	row_texts(HorizonWarms, Clock.start)
		== [
			"clock = step 0",
			"Sun.height_at(clock) = 244.0 px",
			"Sky.darkness_at(clock) = 0%",
			"Sky.horizon_warmth_at(clock) = 0%",
		]

# The chart's levels stay on the chart: the sun runs from top to bottom.
expect sun_level(Clock.start) == 1.0
expect sun_level(sunset.last) == 0.0

# The chart's curves run from the sunset's first clock to its last.
expect chart_clocks.first() == Ok(sunset.first)
expect chart_clocks.last() == Ok(sunset.last)

# Each job adds a call to the lines under the picture.
expect row_texts(SunSets, Clock.start).len() == 2
expect row_texts(SkyDarkens, Clock.start).len() == 3
expect row_texts(HorizonWarms, Clock.start).len() == 4

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
expect next_model(at_start, Input.none.with_key_pressed(KeyRight)).job == SkyDarkens
expect next_model({ ..at_start, job: SkyDarkens }, Input.none).job == SkyDarkens
expect pressed_on({ ..at_start, job: SkyDarkens }, Play).job == SkyDarkens

# The chart's two ends are the sunset's two ends.
expect chart_point(Clock.start, darkness_level).x == chart_left
expect chart_point(sunset.last, darkness_level).x == chart_right
expect chart_point(Clock.start, darkness_level).y == chart_bottom
expect chart_point(Clock.start, sun_level).y == chart_top

# The cursor is a line and three dots.
expect cursor_shapes(HorizonWarms, Clock.at_step(3000)).len() == 4
expect cursor_shapes(SunSets, Clock.at_step(3000)).len() == 2

# The hint goes once the clock has moved.
expect shapes_at(at_start).len() > shapes_at(stopped_at(1)).len()

# The picture depends on the clock.
expect picture_shapes(HorizonWarms, Clock.at_step(3000)) != picture_shapes(HorizonWarms, Clock.at_step(3001))
