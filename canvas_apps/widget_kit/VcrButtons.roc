## A video recorder's buttons for a widget whose whole state is one number. A
## widget says what its number runs over and how fast it plays, and this module
## does the rest: it reads a press into the number and draws the buttons where
## the panel starts. Six buttons go to the start, play backward, step back, step
## forward, play and go to the end. A click anywhere else does nothing.
import game.EncounterPlan
import game.Clock
import game.Distance
import game.Speed
import lib.Brush
import lib.CanvasApp
import lib.Input
import lib.Shapes
import lib.RgbColor
import Click
import PlanView
import ScrubWidget

VcrButtons :: [].{

	## Which way the number is running.
	Motion : [Stopped, Forward, Backward]

	## What a button does.
	Control : [ToStart, PlayBack, StepBack, StepForward, Play, ToEnd]

	## What a widget says about its number. `place_of` says how far along the range
	## a number is, growing from `first` to `last`, and `number_at` is its inverse.
	## A step moves a number one along the range, and `play_reach` is how far a
	## frame of play moves it.
	NumberRange(number) : {
		first : number,
		last : number,
		place_of : number -> F64,
		number_at : F64 -> number,
		play_reach : F64,
	}

	## The whole state of the buttons: the number, and which way it's running.
	Transport(number) : { at : number, motion : VcrButtons.Motion }

	## A range over the ride's clock, where one step is one step of the ride.
	clock_range : {
		first_step : U32,
		last_step : U32,
		steps_a_frame : F64,
	} -> VcrButtons.NumberRange(Clock)
	clock_range = |{ first_step, last_step, steps_a_frame }| {
		first: Clock.at_step(first_step),
		last: Clock.at_step(last_step),
		place_of: Clock.to_f64,
		number_at: |step| Clock.at_step(step.to_u32_wrap()),
		play_reach: steps_a_frame,
	}

	## A range over the gap to something the rider is nearing, from `farthest` down
	## to zero, where one step is a metre.
	gap_range : { farthest : Distance, metres_a_frame : F64 } -> VcrButtons.NumberRange(Distance)
	gap_range = |{ farthest, metres_a_frame }| {
		first: farthest,
		last: Distance.zero,
		place_of: |gap| farthest.minus(gap).to_metres(),
		number_at: |place| farthest.minus(Distance.metres(place)),
		play_reach: metres_a_frame,
	}

	## The timing of an animation `span` long, for a rider `gap` short of its
	## animal on a gap's `range`, coming at `speed` from the range's far end at
	## step 0 of the ride's clock. It is planned as the ride plans it, on the
	## first step that the rider comes within reach.
	planned_timing : EncounterPlan.StepSpan,
	{
		range : VcrButtons.NumberRange(Distance),
		speed : Speed,
		gap : Distance,
	} -> EncounterPlan.Timing
	planned_timing = |span, { range, speed, gap }| {
		now = Clock.at_step(range.first.minus(gap).portion(speed.step_length()).to_u32_wrap())
		var $step = Clock.start
		var $start = Unplanned
		while $start == Unplanned and !(now < $step) {
			$start = EncounterPlan.planned_start(
				span,
				{
					gap: range.first.minus(speed.distance_in($step.steps_since(Clock.start))),
					speed,
					now: $step,
				},
			)
			$step = $step.next()
		}
		EncounterPlan.timing_of($start, now)
	}

	## The buttons at rest with the number at `number`.
	transport_at : number -> VcrButtons.Transport(number)
	transport_at = |number| { at: number, motion: Stopped }

	## A canvas app for a widget that is its buttons and a page drawn from them.
	canvas_app : {
		title : Str,
		range : VcrButtons.NumberRange(number),
		opens_at : number,
		frame_shapes : VcrButtons.Transport(number) -> List(Shapes.Shape),
	} -> CanvasApp.CanvasApp(VcrButtons.Transport(number))
	canvas_app = |{ title, range, opens_at, frame_shapes }|
		ScrubWidget.canvas_app({
			title,
			init: VcrButtons.transport_at(opens_at),
			model_at_next_step: |transport, input| VcrButtons.next_transport(transport, { input, range }),
			frame_shapes,
		})

	## The buttons after one frame: a press, then the number's own run.
	next_transport : VcrButtons.Transport(number),
	{
		input : Input.Snapshot,
		range : VcrButtons.NumberRange(number),
	} -> VcrButtons.Transport(number)
	next_transport = |transport, { input, range }| {
		pressed =
			match pressed_control(input) {
				Ok(control) => transport_after_press(transport, { control, range })
				Err(NoButton) => transport
			}
		run_on(pressed, range)
	}

	## `transport` with a press this frame counting from `shown`. A widget whose
	## picture catches up with the number asks this first, so that a press acts on
	## what the reader can see.
	catch_up : VcrButtons.Transport(number),
	{
		input : Input.Snapshot,
		shown : number,
	} -> VcrButtons.Transport(number)
	catch_up = |transport, { input, shown }|
		match pressed_control(input) {
			Ok(_) => { ..transport, at: shown }
			Err(NoButton) => transport
		}

	## A frame's snapshot with a click in the middle of `control`'s button, for a
	## widget's expects.
	click_on : VcrButtons.Control -> Input.Snapshot
	click_on = |control| {
		button = buttons.find_first(|each| each.control == control)
			?? crash "VcrButtons.click_on: every control has a button"
		Click.click_at({ x: button.left + button_width / 2.0, y: button_middle_y })
	}

	## Everything on the canvas: the page, with the buttons on it.
	frame_shapes : VcrButtons.Transport(number),
	{
		range : VcrButtons.NumberRange(number),
		picture_shapes : List(Shapes.Shape),
		status_lines : List(Str),
	} -> List(Shapes.Shape)
	frame_shapes = |transport, { range, picture_shapes, status_lines }|
		[
			ScrubWidget.frame_shapes({ picture_shapes, status_lines }),
			buttons.join_map(|button| button_shapes(button, transport.motion)),
			hint_shapes(transport, range),
		].join()
}

## How far along `range` a number is.
place_in : VcrButtons.NumberRange(number), number -> F64
place_in = |range, number| (range.place_of)(number)

## Whether `control` is the one that's running the number.
is_lit : VcrButtons.Control, VcrButtons.Motion -> Bool
is_lit = |control, motion|
	match (control, motion) {
		(Play, Forward) | (PlayBack, Backward) => True
		_ => False
	}

## `wanted`, or stopped if the number is already running that way.
toggle : VcrButtons.Motion, VcrButtons.Motion -> VcrButtons.Motion
toggle = |motion, wanted|
	if motion == wanted {
		Stopped
	} else {
		wanted
	}

## `transport` with its number `by` farther along the range. It stops at either end.
transport_moved_by : VcrButtons.Transport(number),
{
	by : F64,
	range : VcrButtons.NumberRange(number),
} -> VcrButtons.Transport(number)
transport_moved_by = |transport, { by, range }| {
	place = place_in(range, transport.at) + by
	if place <= place_in(range, range.first) {
		{ at: range.first, motion: Stopped }
	} else if place >= place_in(range, range.last) {
		{ at: range.last, motion: Stopped }
	} else {
		{ ..transport, at: (range.number_at)(place) }
	}
}

## `transport` after a frame of its own run.
run_on : VcrButtons.Transport(number), VcrButtons.NumberRange(number) -> VcrButtons.Transport(number)
run_on = |transport, range|
	match transport.motion {
		Stopped => transport
		Forward => transport_moved_by(transport, { by: range.play_reach, range })
		Backward => transport_moved_by(transport, { by: -range.play_reach, range })
	}

## `transport` after a press of `control`. A lit play button pauses, a step stops
## the number wherever it was running, and play from the end starts over.
transport_after_press : VcrButtons.Transport(number),
{
	control : VcrButtons.Control,
	range : VcrButtons.NumberRange(number),
} -> VcrButtons.Transport(number)
transport_after_press = |transport, { control, range }|
	match control {
		ToStart => VcrButtons.transport_at(range.first)
		PlayBack => { ..transport, motion: toggle(transport.motion, Backward) }
		StepBack => transport_moved_by(
			{ ..transport, motion: Stopped },
			{ by: -1.0, range },
		)
		StepForward => transport_moved_by(
			{ ..transport, motion: Stopped },
			{ by: 1.0, range },
		)
		Play =>
			if place_in(range, transport.at) == place_in(range, range.last) {
				{ at: range.first, motion: Forward }
			} else {
				{ ..transport, motion: toggle(transport.motion, Forward) }
			}
		ToEnd => VcrButtons.transport_at(range.last)
	}

## A button, and how far it is from the canvas's left edge.
Button : { control : VcrButtons.Control, left : F64 }

## The buttons, side by side from the left margin.
buttons : List(Button)
buttons =
	[ToStart, PlayBack, StepBack, StepForward, Play, ToEnd].map_with_index(
		|control, index| {
			control,
			left: ScrubWidget.side_margin + index.to_f64() * button_spacing,
		},
	)

button_spacing : F64
button_spacing = 50.0

button_width : F64
button_width = 44.0

## The space between the picture and the top of the buttons.
button_gap : F64
button_gap = 6.0

button_top : F64
button_top = ScrubWidget.picture_bottom_y + button_gap

button_height : F64
button_height = 24.0

## The part of the canvas a click on `button` lands in.
button_area : Button -> Click.Area
button_area = |button| {
	left: button.left,
	top: button_top,
	width: button_width,
	height: button_height,
}

## The control under a click this frame, if there's a click and it's on a button.
pressed_control : Input.Snapshot -> Try(VcrButtons.Control, [NoButton])
pressed_control = |input|
	match Click.click_point(input) {
		Ok(spot) => control_at(spot)
		Err(NoClick) => Err(NoButton)
	}

## The control at `spot`.
control_at : { x : F64, y : F64 } -> Try(VcrButtons.Control, [NoButton])
control_at = |spot|
	match buttons.keep_if(|button| button_area(button).contains(spot)) {
		[button, ..] => Ok(button.control)
		[] => Err(NoButton)
	}

button_middle_y : F64
button_middle_y = button_top + button_height / 2.0

icon_color : RgbColor
icon_color = RgbColor.of(0xf7f5f0)

## A triangle pointing right when `reach` is positive, and left when it's not.
triangle : { tip_x : F64, reach : F64 } -> Shapes.Shape
triangle = |{ tip_x, reach }|
	Poly({
		coordinates: [
			tip_x - reach,
			button_middle_y - 7.0,
			tip_x,
			button_middle_y,
			tip_x - reach,
			button_middle_y + 7.0,
		],
		fill: Brush.flat(icon_color),
	})

## A bar across a button's height, for a pause or a stop at either end.
bar : F64 -> Shapes.Shape
bar = |x|
	Rect({
		x,
		y: button_middle_y - 7.0,
		width: 3.0,
		height: 14.0,
		fill: Brush.flat(icon_color),
	})

## What a button shows, around `middle`. A lit play button shows a pause.
icon_shapes : VcrButtons.Control, { middle : F64, lit : Bool } -> List(Shapes.Shape)
icon_shapes = |control, { middle, lit }|
	if lit {
		[bar(middle - 5.0), bar(middle + 2.0)]
	} else {
		match control {
			ToStart => [bar(middle - 9.0), triangle({ tip_x: middle - 5.0, reach: -11.0 })]
			PlayBack => [triangle({ tip_x: middle - 6.0, reach: -12.0 })]
			StepBack => [triangle({ tip_x: middle - 7.0, reach: -9.0 }), bar(middle + 5.0)]
			StepForward => [bar(middle - 8.0), triangle({ tip_x: middle + 7.0, reach: 9.0 })]
			Play => [triangle({ tip_x: middle + 6.0, reach: 12.0 })]
			ToEnd => [triangle({ tip_x: middle + 5.0, reach: 11.0 }), bar(middle + 6.0)]
		}
	}

## A button on the canvas, lit if it's running the number.
button_shapes : Button, VcrButtons.Motion -> List(Shapes.Shape)
button_shapes = |button, motion| {
	lit = is_lit(button.control, motion)
	color =
		if lit {
			PlanView.accent_color
		} else {
			RgbColor.of(0x303030)
		}
	[
		Rect({
			x: button.left,
			y: button_top,
			width: button_width,
			height: button_height,
			fill: Brush.flat(color),
		}),
	].concat(icon_shapes(button.control, { middle: button.left + button_width / 2.0, lit }))
}

## A word for a reader who hasn't touched the widget yet, right of the buttons.
hint_shapes : VcrButtons.Transport(number), VcrButtons.NumberRange(number) -> List(Shapes.Shape)
hint_shapes = |transport, range|
	if transport.motion == Stopped and place_in(
		range,
		transport.at,
	) == place_in(range, range.first) {
		gaps_before_last = (buttons.len() - 1).to_f64()
		last_button_right = ScrubWidget.side_margin + gaps_before_last * button_spacing + button_width
		[
			ScrubWidget.label({
				text: "Press play",
				x: last_button_right + 14.0,
				y: hint_baseline,
			}),
		]
	} else {
		[]
	}

## The baseline of the hint's words, below the picture and level with the
## buttons.
hint_baseline : F64
hint_baseline = ScrubWidget.picture_bottom_y + 23.0

## A range over steps 0 to 6000, eight steps a frame.
sample_clock_run : VcrButtons.NumberRange(Clock)
sample_clock_run = VcrButtons.clock_range({
	first_step: 0,
	last_step: 6000,
	steps_a_frame: 8.0,
})

## A range over a gap of 50 metres, a quarter of a metre a frame.
sample_gap_run : VcrButtons.NumberRange(Distance)
sample_gap_run = VcrButtons.gap_range({ farthest: Distance.metres(50.0), metres_a_frame: 0.25 })

## The sample clock, stopped at `step`.
stopped_at : U32 -> VcrButtons.Transport(Clock)
stopped_at = |step| VcrButtons.transport_at(Clock.at_step(step))

## The sample clock at `step`, running.
running_at : U32, VcrButtons.Motion -> VcrButtons.Transport(Clock)
running_at = |step, motion| { at: Clock.at_step(step), motion }

## What a press of `control` on the sample clock does, after that frame.
clock_after_press : VcrButtons.Transport(Clock), VcrButtons.Control -> VcrButtons.Transport(Clock)
clock_after_press = |transport, control|
	VcrButtons.next_transport(
		transport,
		{ input: VcrButtons.click_on(control), range: sample_clock_run },
	)

## What a click at `spot` on the sample clock does, after that frame.
clock_after_click : VcrButtons.Transport(Clock), { x : F64, y : F64 } -> VcrButtons.Transport(Clock)
clock_after_click = |transport, spot|
	VcrButtons.next_transport(transport, { input: Click.click_at(spot), range: sample_clock_run })

## What a frame with nothing pressed does to the sample clock.
clock_left_alone : VcrButtons.Transport(Clock) -> VcrButtons.Transport(Clock)
clock_left_alone = |transport|
	VcrButtons.next_transport(transport, { input: Input.none, range: sample_clock_run })

# Every button does its job.
expect clock_after_press(stopped_at(0), Play) == running_at(8, Forward)
expect clock_after_press(stopped_at(100), PlayBack) == running_at(92, Backward)
expect clock_after_press(stopped_at(100), StepBack) == stopped_at(99)
expect clock_after_press(stopped_at(100), StepForward) == stopped_at(101)
expect clock_after_press(stopped_at(100), ToStart) == stopped_at(0)
expect clock_after_press(stopped_at(100), ToEnd) == stopped_at(6000)

# A click off the buttons does nothing: above, below and between them, and at the
# first pixel past each edge.
expect clock_after_click(stopped_at(0), { x: 320.0, y: 100.0 }) == stopped_at(0)
expect clock_after_click(stopped_at(0), { x: 320.0, y: 300.0 }) == stopped_at(0)
expect clock_after_click(stopped_at(0), { x: 70.0, y: 234.0 }) == stopped_at(0)
expect clock_after_click(stopped_at(0), { x: 23.0, y: 234.0 }) == stopped_at(0)
expect clock_after_click(stopped_at(100), { x: 196.0, y: 221.0 }) == stopped_at(100)
expect clock_after_click(stopped_at(100), { x: 196.0, y: 246.0 }) == stopped_at(100)
expect clock_after_click(stopped_at(100), { x: 268.0, y: 234.0 }) == stopped_at(100)
expect clock_after_click(stopped_at(100), { x: 196.0, y: 222.0 }) == stopped_at(101)
expect clock_after_click(stopped_at(100), { x: 174.0, y: 245.0 }) == stopped_at(101)

# A click off the buttons leaves a running number running.
expect clock_after_click(
	running_at(100, Forward),
	{ x: 320.0, y: 100.0 },
) == running_at(108, Forward)

# A lit play button pauses, the other one turns the number round, and a step stops
# it.
expect clock_after_press(running_at(100, Forward), Play) == stopped_at(100)
expect clock_after_press(running_at(100, Backward), PlayBack) == stopped_at(100)
expect clock_after_press(running_at(100, Forward), PlayBack) == running_at(92, Backward)
expect clock_after_press(running_at(100, Backward), Play) == running_at(108, Forward)
expect clock_after_press(running_at(100, Forward), StepForward) == stopped_at(101)
expect clock_after_press(running_at(100, Forward), StepBack) == stopped_at(99)
expect clock_after_press(running_at(100, Backward), StepForward) == stopped_at(101)
expect clock_after_press(running_at(100, Backward), StepBack) == stopped_at(99)
expect clock_after_press(running_at(100, Forward), ToStart) == stopped_at(0)
expect clock_after_press(running_at(100, Backward), ToEnd) == stopped_at(6000)

# A step stays on the range at both ends.
expect clock_after_press(stopped_at(0), StepBack) == stopped_at(0)
expect clock_after_press(stopped_at(6000), StepForward) == stopped_at(6000)
expect clock_after_press(stopped_at(1), StepBack) == stopped_at(0)
expect clock_after_press(stopped_at(5999), StepForward) == stopped_at(6000)

# A held button isn't a new click.
expect
	VcrButtons.next_transport(
		stopped_at(100),
		{
			input: Click.held_at({ x: 196.0, y: 234.0 }),
			range: sample_clock_run,
		},
	)
		== stopped_at(100)

# A number left alone stays, or runs on, and it stops at either end.
expect clock_left_alone(stopped_at(100)) == stopped_at(100)
expect clock_left_alone(running_at(100, Forward)) == running_at(108, Forward)
expect clock_left_alone(running_at(100, Backward)) == running_at(92, Backward)
expect clock_left_alone(running_at(4, Backward)) == stopped_at(0)
expect clock_left_alone(running_at(8, Backward)) == stopped_at(0)
expect clock_left_alone(running_at(9, Backward)) == running_at(1, Backward)
expect clock_left_alone(running_at(5996, Forward)) == stopped_at(6000)
expect clock_left_alone(running_at(5992, Forward)) == stopped_at(6000)
expect clock_left_alone(running_at(5991, Forward)) == running_at(5999, Forward)

# Play from the end starts over, and play back from the start has nowhere to go.
expect transport_after_press(
	stopped_at(6000),
	{ control: Play, range: sample_clock_run },
) == running_at(0, Forward)
expect transport_after_press(
	stopped_at(5999),
	{ control: Play, range: sample_clock_run },
) == running_at(5999, Forward)
expect clock_after_press(stopped_at(0), PlayBack) == stopped_at(0)

# The lit button is the one running the number, and nothing is lit at rest.
expect is_lit(Play, Forward)
expect is_lit(PlayBack, Backward)
expect !is_lit(Play, Stopped)
expect !is_lit(PlayBack, Stopped)
expect !is_lit(Play, Backward)
expect !is_lit(PlayBack, Forward)
expect !is_lit(ToEnd, Forward)

# Each button shows an icon, and a button is its square and that icon. A lit one
# shows the two bars of a pause, in a color of its own.
expect buttons.len() == 6
expect buttons.all(|button| button_shapes(button, Stopped).len() > 1)
expect button_shapes({ control: Play, left: 24.0 }, Forward).len() == 3
expect button_shapes({ control: Play, left: 24.0 }, Stopped).len() == 2
expect button_shapes({ control: Play, left: 24.0 }, Forward) != button_shapes(
	{ control: Play, left: 24.0 },
	Backward,
)

# A gap's range falls from its farthest to zero, and a metre is a step.
expect VcrButtons.transport_at(Distance.metres(50.0)).at == sample_gap_run.first
expect sample_gap_run.last == Distance.zero
expect place_in(sample_gap_run, Distance.metres(50.0)) == 0.0
expect place_in(sample_gap_run, Distance.zero) == 50.0
expect (sample_gap_run.number_at)(10.0) == Distance.metres(40.0)

## What a press of `control` on the sample gap does, after that frame.
gap_after_press : Distance, VcrButtons.Control -> VcrButtons.Transport(Distance)
gap_after_press = |gap, control|
	VcrButtons.next_transport(
		VcrButtons.transport_at(gap),
		{ input: VcrButtons.click_on(control), range: sample_gap_run },
	)

expect gap_after_press(Distance.metres(20.0), StepForward).at == Distance.metres(19.0)
expect gap_after_press(Distance.metres(20.0), StepBack).at == Distance.metres(21.0)
expect gap_after_press(Distance.metres(20.0), Play).at == Distance.metres(19.75)
expect gap_after_press(Distance.metres(20.0), ToStart).at == Distance.metres(50.0)
expect gap_after_press(Distance.metres(20.0), ToEnd).at == Distance.zero
expect gap_after_press(Distance.metres(50.0), StepBack).at == Distance.metres(50.0)
expect gap_after_press(Distance.zero, StepForward).at == Distance.zero

# A spot picks the button under it, and a spot past the last button picks none.
expect control_at({ x: 90.0, y: 234.0 }) == Ok(PlayBack)
expect control_at({ x: 240.0, y: 234.0 }) == Ok(Play)
expect control_at({ x: 340.0, y: 234.0 }) == Err(NoButton)

## The sample clock caught up with a picture at step 40.
caught_up_to_forty : Input.Snapshot -> VcrButtons.Transport(Clock)
caught_up_to_forty = |input|
	VcrButtons.catch_up(stopped_at(6000), { input, shown: Clock.at_step(40) })

# A press counts from what's on show, and only a press on a button does.
expect caught_up_to_forty(VcrButtons.click_on(StepBack)) == stopped_at(40)
expect caught_up_to_forty(Input.none) == stopped_at(6000)
expect caught_up_to_forty(Click.click_at({ x: 320.0, y: 100.0 })) == stopped_at(6000)
expect caught_up_to_forty(Click.held_at({ x: 196.0, y: 234.0 })) == stopped_at(6000)

# The hint shows until the number has moved or started to.
expect hint_shapes(stopped_at(0), sample_clock_run).len() == 1
expect hint_shapes(running_at(0, Forward), sample_clock_run).len() == 0
expect hint_shapes(stopped_at(1), sample_clock_run).len() == 0

# The page is the panel, then each button's square and icon, then the hint.
expect
	VcrButtons.frame_shapes(
		stopped_at(1),
		{ range: sample_clock_run, picture_shapes: [], status_lines: [] },
	).len()
		> ScrubWidget.frame_shapes({ picture_shapes: [], status_lines: [] }).len()
expect
	VcrButtons.frame_shapes(
		stopped_at(0),
		{ range: sample_clock_run, picture_shapes: [], status_lines: [] },
	).len()
		== VcrButtons.frame_shapes(
			stopped_at(1),
			{ range: sample_clock_run, picture_shapes: [], status_lines: [] },
		).len() + 1

# A canvas app opens where the widget says, at rest.
expect
	VcrButtons.canvas_app({
		title: "I",
		range: sample_clock_run,
		opens_at: Clock.at_step(7),
		frame_shapes: |_transport| [],
	}).init
		== stopped_at(7)
