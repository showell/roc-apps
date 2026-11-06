## The widget for the Safari tutorial's setting sun. Five buttons, like a video
## recorder's, run the ride's clock forward and back, and each frame is worked
## out from that clock alone. A click anywhere else does nothing. The picture is
## the ride's own sky, looking straight at the sun, drawn by Backdrop at two
## thirds of its size. Below it, lines of text read out the calls to Sky, and a
## small chart plots their answers over the whole sunset. The book opens it at
## one of three jobs, and each job adds a call.
import game.Clock
import game.Lens
import game.Pixels
import game.Sky
import lib.Brush
import lib.CanvasApp
import lib.Font
import lib.Input
import lib.Mouse
import lib.Shapes
import widget.ScrubWidget

SkyWidgetApp :: [].{

	## How much of the sunset the widget does.
	Job : [SunSets, SkyDarkens, HorizonWarms]

	## Which way the clock is running.
	Motion : [Stopped, Forward, Backward]

	## What a button does.
	Control : [ToStart, PlayBack, Pause, Play, ToEnd]

	## The whole state of the widget: the ride's clock, the job, and which way
	## the clock is running.
	Model : {
		clock : Clock,
		job : SkyWidgetApp.Job,
		motion : SkyWidgetApp.Motion,
	}

	canvas_app : CanvasApp.CanvasApp(SkyWidgetApp.Model)
	canvas_app = {
		..ScrubWidget.canvas_app({
			title: "The sun going down",
			init: {
				clock: Clock.start,
				job: SunSets,
				motion: Stopped,
			},
			model_at: |_share| {
				clock: Clock.start,
				job: SunSets,
				motion: Stopped,
			},
			frame: frame_at,
		}),
		advance: |model, input, _seconds| next_model(model, input),
	}
}

## How far the clock moves in a frame while it runs: a sunset in twelve seconds.
steps_a_frame : F64
steps_a_frame = 8.0

## The clock at the far end of the sunset.
last_clock : Clock
last_clock = Clock.at_step(6000)

## The model after one frame: a click on a button, then the clock's own run. The
## Right key is how the page opens at a job.
next_model : SkyWidgetApp.Model, Input.Snapshot -> SkyWidgetApp.Model
next_model = |model, input| {
	clicked =
		if input.mouse.button_pressed(Left) {
			position = input.mouse.position()
			after_click(model, { x: position.x.to_f64(), y: position.y.to_f64() })
		} else {
			model
		}
	job =
		if input.key_pressed(KeyRight) {
			next_job(clicked.job)
		} else {
			clicked.job
		}
	run_on({ ..clicked, job })
}

## The model after one frame of the clock's run. It stops at either end.
run_on : SkyWidgetApp.Model -> SkyWidgetApp.Model
run_on = |model|
	match model.motion {
		Stopped => model
		Forward => clock_moved_by(model, steps_a_frame)
		Backward => clock_moved_by(model, -steps_a_frame)
	}

clock_moved_by : SkyWidgetApp.Model, F64 -> SkyWidgetApp.Model
clock_moved_by = |model, steps| {
	step = model.clock.to_f64() + steps
	if step <= 0.0 {
		{ ..model, clock: Clock.start, motion: Stopped }
	} else if step >= last_clock.to_f64() {
		{ ..model, clock: last_clock, motion: Stopped }
	} else {
		{ ..model, clock: Clock.at_step(step.to_u32_wrap()) }
	}
}

## The model after a press of `control`.
pressed : SkyWidgetApp.Model, SkyWidgetApp.Control -> SkyWidgetApp.Model
pressed = |model, control|
	match control {
		ToStart => { ..model, clock: Clock.start, motion: Stopped }
		PlayBack => { ..model, motion: Backward }
		Pause => { ..model, motion: Stopped }
		Play =>
			if model.clock == last_clock {
				{ ..model, clock: Clock.start, motion: Forward }
			} else {
				{ ..model, motion: Forward }
			}
		ToEnd => { ..model, clock: last_clock, motion: Stopped }
	}

## `model` after a click at `spot`, which does nothing off the buttons.
after_click : SkyWidgetApp.Model, { x : F64, y : F64 } -> SkyWidgetApp.Model
after_click = |model, spot|
	match buttons.keep_if(|button| is_on(button, spot)) {
		[button, ..] => pressed(model, button.control)
		[] => model
	}

## A button, and how far it is from the canvas's left edge.
Button : { control : SkyWidgetApp.Control, left : F64 }

buttons : List(Button)
buttons = [
	{ control: ToStart, left: 24.0 },
	{ control: PlayBack, left: 74.0 },
	{ control: Pause, left: 124.0 },
	{ control: Play, left: 174.0 },
	{ control: ToEnd, left: 224.0 },
]

button_width : F64
button_width = 44.0

button_top : F64
button_top = 222.0

button_height : F64
button_height = 24.0

is_on : Button, { x : F64, y : F64 } -> Bool
is_on = |button, { x, y }|
	x >= button.left
		and x < button.left + button_width
		and y >= button_top
		and y < button_top + button_height

## The control that shows as lit while the clock runs this way.
lit_control : SkyWidgetApp.Motion -> SkyWidgetApp.Control
lit_control = |motion|
	match motion {
		Stopped => Pause
		Forward => Play
		Backward => PlayBack
	}

## A triangle pointing right when `reach` is positive, and left when it's not.
triangle : F64, F64 -> Shapes.Shape
triangle = |tip_x, reach|
	Poly({
		pts: [
			tip_x - reach,
			button_middle_y - 7.0,
			tip_x,
			button_middle_y,
			tip_x - reach,
			button_middle_y + 7.0,
		],
		fill: ScrubWidget.flat(icon_color),
	})

## A bar across a button's height, for a pause or a stop at either end.
bar : F64 -> Shapes.Shape
bar = |x|
	Rect({
		x,
		y: button_middle_y - 7.0,
		w: 3.0,
		h: 14.0,
		fill: ScrubWidget.flat(icon_color),
	})

button_middle_y : F64
button_middle_y = button_top + button_height / 2.0

icon_color : I64
icon_color = 0xf7f5f0

## What a button shows, around `middle`.
icon : SkyWidgetApp.Control, F64 -> List(Shapes.Shape)
icon = |control, middle|
	match control {
		ToStart => [bar(middle - 9.0), triangle(middle - 5.0, -11.0)]
		PlayBack => [triangle(middle - 6.0, -12.0)]
		Pause => [bar(middle - 5.0), bar(middle + 2.0)]
		Play => [triangle(middle + 6.0, 12.0)]
		ToEnd => [triangle(middle + 5.0, 11.0), bar(middle + 6.0)]
	}

## A button on the canvas, lit if it matches `motion`.
button_shapes : Button, SkyWidgetApp.Motion -> List(Shapes.Shape)
button_shapes = |button, motion| {
	color =
		if button.control == lit_control(motion) {
			0xd0603a
		} else {
			0x303030
		}
	[
		Rect({
			x: button.left,
			y: button_top,
			w: button_width,
			h: button_height,
			fill: ScrubWidget.flat(color),
		}),
	].concat(icon(button.control, button.left + button_width / 2.0))
}

next_job : SkyWidgetApp.Job -> SkyWidgetApp.Job
next_job = |job|
	match job {
		SunSets => SkyDarkens
		SkyDarkens => HorizonWarms
		HorizonWarms => SunSets
	}

## The ruler runs from the ride's start to a little after full dusk.
clock_range : ScrubWidget.ClockRange
clock_range = { first_step: 0.0, last_step: 6000.0 }

## Everything on the canvas.
frame_at : SkyWidgetApp.Model -> List(Shapes.Shape)
frame_at = |{ clock, job, motion }|
	[
		ScrubWidget.still_frame_shapes({ picture: picture(job, clock), status: [] }),
		buttons.join_map(|button| button_shapes(button, motion)),
		call_lines(job, clock),
		chart(job),
		chart_cursor(job, clock),
		hint(clock, motion),
	].join()

## The two colors of the sky, as far as `job` goes.
sky_colors : SkyWidgetApp.Job, Clock -> { top : Sky.Rgb, horizon : Sky.Rgb }
sky_colors = |job, clock|
	match job {
		SunSets => {
			day = Sky.sky_top_color(Clock.start)
			{ top: day, horizon: day }
		}
		SkyDarkens => {
			now = Sky.sky_top_color(clock)
			{ top: now, horizon: now }
		}
		HorizonWarms => { top: Sky.sky_top_color(clock), horizon: Sky.sky_horizon_color(clock) }
	}

## The ride's sky at `clock`, for a rider facing the sun.
picture : SkyWidgetApp.Job, Clock -> List(Shapes.Shape)
picture = |job, clock| {
	colors = sky_colors(job, clock)
	ScrubWidget.ride_picture_in(
		[],
		{
			sky_top_color: colors.top,
			sky_horizon_color: colors.horizon,
			sun_sighting: Sky.sun_sighting({
				heading: Sky.sun_bearing,
				clock,
				cam_focal: Lens.focal,
			}),
		},
	)
}

## The calls this widget makes at `clock`, and their answers, a line each.
status_lines : SkyWidgetApp.Job, Clock -> List(Str)
status_lines = |job, clock|
	[
		"clock = step ${clock.to_str()}",
		"Sky.sun_height_px(clock) = ${height_text(Sky.sun_height_px(clock))}",
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

clock_color : I64
clock_color = 0x202020

sun_color : I64
sun_color = 0x9a6a00

dusk_color : I64
dusk_color = 0x24406e

warmth_color : I64
warmth_color = 0xc0392b

## The status lines, each in the color of its curve on the chart.
call_lines : SkyWidgetApp.Job, Clock -> List(Shapes.Shape)
call_lines = |job, clock|
	List.map2(
		status_lines(job, clock),
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

## The chart's curves, which are the same at every clock.
all_curves : List(List(Shapes.Shape))
all_curves = [
	curve(sun_level, sun_color),
	curve(dusk_level, dusk_color),
	curve(warmth_level, warmth_color),
]

## The curves `job` has got to.
chart : SkyWidgetApp.Job -> List(Shapes.Shape)
chart = |job| all_curves.take_first(curves_of(job)).join()

## A line down the chart at `clock`, with a dot on each curve.
chart_cursor : SkyWidgetApp.Job, Clock -> List(Shapes.Shape)
chart_cursor = |job, clock| {
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
		].take_first(curves_of(job)),
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
hint : Clock, SkyWidgetApp.Motion -> List(Shapes.Shape)
hint = |clock, motion|
	if clock == Clock.start and motion == Stopped {
		Font.text(
			"Press play",
			300.0,
			227.0,
			13.0,
			Brush.opaque(0x202020),
		)
	} else {
		[]
	}

expect
	status_lines(HorizonWarms, Clock.start)
		== [
			"clock = step 0",
			"Sky.sun_height_px(clock) = 244.0 px",
			"Sky.dusk_at(clock) = 0%",
			"Sky.sunset_warmth(clock) = 0%",
		]

expect
	status_lines(HorizonWarms, Clock.at_step(3000))
		== [
			"clock = step 3000",
			"Sky.sun_height_px(clock) = 60.2 px",
			"Sky.dusk_at(clock) = 23%",
			"Sky.sunset_warmth(clock) = 45%",
		]

expect
	status_lines(HorizonWarms, Clock.at_step(6000))
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
expect chart(HorizonWarms).len() == 180
expect chart(SkyDarkens).len() == 120
expect chart(SunSets).len() == 60

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

## A model at the start of the first job, and a click on one spot.
at_start : SkyWidgetApp.Model
at_start = {
	clock: Clock.start,
	job: SunSets,
	motion: Stopped,
}

## What a press at (`x`, `y`) on `model` does, after that frame.
clicked_at : SkyWidgetApp.Model, { x : F64, y : F64 } -> SkyWidgetApp.Model
clicked_at = |model, { x, y }|
	next_model(model, Input.none.with_mouse(Mouse.of(1, 1, x.to_f32_wrap(), y.to_f32_wrap(), 0.0)))

## The middle of the button for `control`, and the same model with it pressed.
pressed_on : SkyWidgetApp.Model, F64 -> SkyWidgetApp.Model
pressed_on = |model, left| clicked_at(model, { x: left + button_width / 2.0, y: button_middle_y })

# Every button does its job, and nothing else on the canvas does anything.
expect pressed_on(at_start, 174.0).motion == Forward
expect pressed_on(at_start, 174.0).clock == Clock.at_step(8)
expect pressed_on({ ..at_start, clock: Clock.at_step(100) }, 74.0).motion == Backward
expect pressed_on({ ..at_start, clock: Clock.at_step(100) }, 74.0).clock == Clock.at_step(92)
expect pressed_on({ ..at_start, motion: Forward }, 124.0).motion == Stopped
expect pressed_on({ ..at_start, clock: Clock.at_step(100) }, 24.0).clock == Clock.start
expect pressed_on(at_start, 224.0).clock == last_clock
expect clicked_at(at_start, { x: 320.0, y: 100.0 }) == at_start
expect clicked_at(at_start, { x: 320.0, y: 300.0 }) == at_start
expect clicked_at(at_start, { x: 70.0, y: button_middle_y }) == at_start
expect clicked_at(at_start, { x: 196.0, y: button_top - 1.0 }) == at_start

# A held button isn't a new click.
expect
	next_model(at_start, Input.none.with_mouse(Mouse.of(1, 0, 196.0, 234.0, 0.0)))
		== at_start

# The clock stops at either end, and play from the end starts over.
expect run_on({
	..at_start,
	clock: Clock.at_step(4),
	motion: Backward,
}) == at_start
expect run_on({
	..at_start,
	clock: Clock.at_step(5996),
	motion: Forward,
}) == { ..at_start, clock: last_clock }
expect run_on(at_start) == at_start
expect pressed({ ..at_start, clock: last_clock }, Play) == { ..at_start, motion: Forward }

# The lit button says which way the clock runs.
expect lit_control(Stopped) == Pause
expect lit_control(Forward) == Play
expect lit_control(Backward) == PlayBack

# Each button shows an icon, and a button is its square and that icon.
expect buttons.all(|button| button_shapes(button, Stopped).len() > 1)
expect buttons.len() == 5

# The Right key moves through the jobs, and the pointer leaves them alone.
expect next_job(SunSets) == SkyDarkens
expect next_job(SkyDarkens) == HorizonWarms
expect next_job(HorizonWarms) == SunSets
expect next_model(at_start, Input.none.with_key_pressed(KeyRight)).job == SkyDarkens
expect next_model({ ..at_start, job: SkyDarkens }, Input.none).job == SkyDarkens

# The chart's two ends are the sunset's two ends.
expect chart_point(Clock.start, dusk_level).x == chart_left
expect chart_point(Clock.at_step(6000), dusk_level).x == chart_right
expect chart_point(Clock.start, dusk_level).y == chart_bottom
expect chart_point(Clock.start, sun_level).y == chart_top

# The cursor is a line and three dots.
expect chart_cursor(HorizonWarms, Clock.at_step(3000)).len() == 4
expect chart_cursor(SunSets, Clock.at_step(3000)).len() == 2

# The hint shows until the clock has moved or started to.
expect hint(Clock.start, Stopped).len() > 0
expect hint(Clock.start, Forward).len() == 0
expect hint(Clock.at_step(1), Stopped).len() == 0
expect frame_at(at_start).len() > frame_at({ ..at_start, clock: Clock.at_step(1) }).len()

# Two view marks around the sky, the grass, the glow and the sun.
expect picture(HorizonWarms, Clock.start).len() == 6

# The picture depends on the clock and on nothing else.
expect picture(HorizonWarms, Clock.at_step(3000)) == picture(HorizonWarms, Clock.at_step(3000))
expect picture(HorizonWarms, Clock.at_step(3000)) != picture(HorizonWarms, Clock.at_step(3001))
