## A video recorder's buttons for a widget whose whole state is one number. A
## widget says what its number runs over, how fast it plays and what one step is,
## and this module does the rest: it reads a press into the number and draws the
## buttons where the panel starts. Six buttons go to the start, play backward,
## step back, step forward, play and go to the end. A widget that doesn't play
## has the four without the two plays. A click anywhere else does nothing.
import game.Clock
import game.Distance
import lib.CanvasApp
import lib.Input
import lib.Mouse
import lib.Shapes
import ScrubWidget

VcrButtons :: [].{

	## Which way the number is running.
	Motion : [Stopped, Forward, Backward]

	## What a button does.
	Control : [ToStart, PlayBack, StepBack, StepForward, Play, ToEnd]

	## Whether the number plays by itself, and how far along its run a frame of
	## play moves it.
	Playing : [Plays(F64), StepsOnly]

	## What a widget says about its number. `place_of` says how far along the run
	## a number is, growing from `first` to `last`, and `number_at` is its inverse.
	## `one_step` is how far along the run a step moves.
	Run(number) : {
		first : number,
		last : number,
		place_of : number -> F64,
		number_at : F64 -> number,
		one_step : F64,
		playing : VcrButtons.Playing,
	}

	## The whole state of the buttons: the number, and which way it's running.
	Transport(number) : { at : number, motion : VcrButtons.Motion }

	## A run over the ride's clock, where one step is one step of the ride.
	clock_run : {
		first_step : U32,
		last_step : U32,
		steps_a_frame : F64,
	} -> VcrButtons.Run(Clock)
	clock_run = |{ first_step, last_step, steps_a_frame }| {
		first: Clock.at_step(first_step),
		last: Clock.at_step(last_step),
		place_of: Clock.to_f64,
		number_at: |step| Clock.at_step(step.to_u32_wrap()),
		one_step: 1.0,
		playing: Plays(steps_a_frame),
	}

	## A run over the gap to something the rider is nearing, from `farthest` down
	## to zero, where one step is a metre.
	gap_run : { farthest : Distance, metres_a_frame : F64 } -> VcrButtons.Run(Distance)
	gap_run = |{ farthest, metres_a_frame }| {
		first: farthest,
		last: Distance.zero,
		place_of: |gap| farthest.minus(gap).to_metres(),
		number_at: |place| farthest.minus(Distance.metres(place)),
		one_step: 1.0,
		playing: Plays(metres_a_frame),
	}

	## The buttons at rest with the number at `number`.
	transport_at : number -> VcrButtons.Transport(number)
	transport_at = |number| { at: number, motion: Stopped }

	## A canvas app for a widget that is its buttons and a page drawn from them.
	canvas_app : {
		title : Str,
		run : VcrButtons.Run(number),
		opens_at : number,
		frame : VcrButtons.Transport(number) -> List(Shapes.Shape),
	} -> CanvasApp.CanvasApp(VcrButtons.Transport(number))
	canvas_app = |{ title, run, opens_at, frame }|
		ScrubWidget.canvas_app({
			title,
			init: VcrButtons.transport_at(opens_at),
			advance: |transport, input| VcrButtons.next_transport(transport, { input, run }),
			frame,
		})

	## The buttons after one frame: a press, then the number's own run.
	next_transport : VcrButtons.Transport(number),
	{
		input : Input.Snapshot,
		run : VcrButtons.Run(number),
	} -> VcrButtons.Transport(number)
	next_transport = |transport, { input, run }| {
		pressed =
			match pressed_control(input, run.playing) {
				Ok(control) => transport_after_press(transport, { control, run })
				Err(NoButton) => transport
			}
		transport_run_on(pressed, run)
	}

	## `transport` with a press this frame counting from `shown`. A widget whose
	## picture catches up with the number asks this first, so that a press acts on
	## what the reader can see.
	catch_up : VcrButtons.Transport(number),
	{
		input : Input.Snapshot,
		run : VcrButtons.Run(number),
		shown : number,
	} -> VcrButtons.Transport(number)
	catch_up = |transport, { input, run, shown }|
		match pressed_control(input, run.playing) {
			Ok(_) => { ..transport, at: shown }
			Err(NoButton) => transport
		}

	## A frame's snapshot with a click in the middle of `control`'s button, for a
	## widget's expects.
	click_on : VcrButtons.Control, VcrButtons.Playing -> Input.Snapshot
	click_on = |control, playing| {
		button = buttons_of(playing).find_first(|each| each.control == control) ?? crash "VcrButtons.click_on: this widget has no such button"
		middle_x = button.left + button_width / 2.0
		Input.none.with_mouse(Mouse.of(1, 1, middle_x.to_f32_wrap(), button_middle_y.to_f32_wrap(), 0.0))
	}

	## Everything on the canvas: the page, with the buttons on it.
	frame_shapes : VcrButtons.Transport(number),
	{
		run : VcrButtons.Run(number),
		picture : List(Shapes.Shape),
		status : List(Str),
	} -> List(Shapes.Shape)
	frame_shapes = |transport, { run, picture, status }|
		[
			ScrubWidget.frame_shapes({ picture, status }),
			buttons_of(run.playing).join_map(|button| button_shapes(button, transport.motion)),
			hint(transport, run),
		].join()
}

## How far along `run` a number is.
place_in : VcrButtons.Run(number), number -> F64
place_in = |run, number| (run.place_of)(number)

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

## `transport` with its number `by` farther along the run. It stops at either end.
transport_moved_by : VcrButtons.Transport(number),
{
	by : F64,
	run : VcrButtons.Run(number),
} -> VcrButtons.Transport(number)
transport_moved_by = |transport, { by, run }| {
	place = place_in(run, transport.at) + by
	if place <= place_in(run, run.first) {
		{ at: run.first, motion: Stopped }
	} else if place >= place_in(run, run.last) {
		{ at: run.last, motion: Stopped }
	} else {
		{ ..transport, at: (run.number_at)(place) }
	}
}

## `transport` after a frame of its own run.
transport_run_on : VcrButtons.Transport(number), VcrButtons.Run(number) -> VcrButtons.Transport(number)
transport_run_on = |transport, run|
	match (transport.motion, run.playing) {
		(Stopped, _) => transport
		(Forward, Plays(reach)) => transport_moved_by(transport, { by: reach, run })
		(Backward, Plays(reach)) => transport_moved_by(transport, { by: -reach, run })
		(Forward, StepsOnly) | (Backward, StepsOnly) =>
			crash "VcrButtons.transport_run_on: a run that doesn't play has no button to start it"
	}

## `transport` after a press of `control`. A lit play button pauses, a step stops
## the number wherever it was running, and play from the end starts over.
transport_after_press : VcrButtons.Transport(number),
{
	control : VcrButtons.Control,
	run : VcrButtons.Run(number),
} -> VcrButtons.Transport(number)
transport_after_press = |transport, { control, run }|
	match control {
		ToStart => VcrButtons.transport_at(run.first)
		PlayBack => { ..transport, motion: toggle(transport.motion, Backward) }
		StepBack => transport_moved_by({ ..transport, motion: Stopped }, { by: -run.one_step, run })
		StepForward => transport_moved_by({ ..transport, motion: Stopped }, { by: run.one_step, run })
		Play =>
			if place_in(run, transport.at) == place_in(run, run.last) {
				{ at: run.first, motion: Forward }
			} else {
				{ ..transport, motion: toggle(transport.motion, Forward) }
			}
		ToEnd => VcrButtons.transport_at(run.last)
	}

## A button, and how far it is from the canvas's left edge.
Button : { control : VcrButtons.Control, left : F64 }

## The buttons a widget has, side by side from the left margin.
buttons_of : VcrButtons.Playing -> List(Button)
buttons_of = |playing| {
	controls =
		match playing {
			Plays(_) => [ToStart, PlayBack, StepBack, StepForward, Play, ToEnd]
			StepsOnly => [ToStart, StepBack, StepForward, ToEnd]
		}
	controls.map_with_index(|control, index| { control, left: ScrubWidget.side_margin + index.to_f64() * button_spacing })
}

button_spacing : F64
button_spacing = 50.0

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

## The control under a press this frame, if there's a press and it's on a button.
## A button held down from an earlier frame isn't a press.
pressed_control : Input.Snapshot, VcrButtons.Playing -> Try(VcrButtons.Control, [NoButton])
pressed_control = |input, playing|
	if input.mouse.button_pressed(Left) {
		position = input.mouse.position()
		control_at(playing, { x: position.x.to_f64(), y: position.y.to_f64() })
	} else {
		Err(NoButton)
	}

## The control at `spot`.
control_at : VcrButtons.Playing, { x : F64, y : F64 } -> Try(VcrButtons.Control, [NoButton])
control_at = |playing, spot|
	match buttons_of(playing).keep_if(|button| is_on(button, spot)) {
		[button, ..] => Ok(button.control)
		[] => Err(NoButton)
	}

button_middle_y : F64
button_middle_y = button_top + button_height / 2.0

icon_color : I64
icon_color = 0xf7f5f0

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

## What a button shows, around `middle`. A lit play button shows a pause.
icon : VcrButtons.Control, { middle : F64, lit : Bool } -> List(Shapes.Shape)
icon = |control, { middle, lit }|
	if lit {
		[bar(middle - 5.0), bar(middle + 2.0)]
	} else {
		match control {
			ToStart => [bar(middle - 9.0), triangle(middle - 5.0, -11.0)]
			PlayBack => [triangle(middle - 6.0, -12.0)]
			StepBack => [triangle(middle - 7.0, -9.0), bar(middle + 5.0)]
			StepForward => [bar(middle - 8.0), triangle(middle + 7.0, 9.0)]
			Play => [triangle(middle + 6.0, 12.0)]
			ToEnd => [triangle(middle + 5.0, 11.0), bar(middle + 6.0)]
		}
	}

## A button on the canvas, lit if it's running the number.
button_shapes : Button, VcrButtons.Motion -> List(Shapes.Shape)
button_shapes = |button, motion| {
	lit = is_lit(button.control, motion)
	color =
		if lit {
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
	].concat(icon(button.control, { middle: button.left + button_width / 2.0, lit }))
}

## A word for a reader who hasn't touched the widget yet, right of the buttons.
hint : VcrButtons.Transport(number), VcrButtons.Run(number) -> List(Shapes.Shape)
hint = |transport, run|
	if transport.motion == Stopped and place_in(run, transport.at) == place_in(run, run.first) {
		last_button_right = ScrubWidget.side_margin + (buttons_of(run.playing).len() - 1).to_f64() * button_spacing + button_width
		text =
			match run.playing {
				Plays(_) => "Press play"
				StepsOnly => "Press a step button"
			}
		[ScrubWidget.label({ text, x: last_button_right + 14.0, y: 239.0 })]
	} else {
		[]
	}

## A run over steps 0 to 6000, eight steps a frame.
sample_clock_run : VcrButtons.Run(Clock)
sample_clock_run = VcrButtons.clock_run({ first_step: 0, last_step: 6000, steps_a_frame: 8.0 })

## A run over a gap of 50 metres, a quarter of a metre a frame.
sample_gap_run : VcrButtons.Run(Distance)
sample_gap_run = VcrButtons.gap_run({ farthest: Distance.metres(50.0), metres_a_frame: 0.25 })

## A run over the numbers 1 to 5 that doesn't play.
sample_stepped_run : VcrButtons.Run(U64)
sample_stepped_run = {
	first: 1,
	last: 5,
	place_of: |number| number.to_f64(),
	number_at: |place| place.to_u64_wrap(),
	one_step: 1.0,
	playing: StepsOnly,
}

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
		{ input: VcrButtons.click_on(control, sample_clock_run.playing), run: sample_clock_run },
	)

## What a click at (`x`, `y`) on the sample clock does, after that frame.
clock_after_click : VcrButtons.Transport(Clock), { x : F32, y : F32 } -> VcrButtons.Transport(Clock)
clock_after_click = |transport, { x, y }|
	VcrButtons.next_transport(
		transport,
		{ input: Input.none.with_mouse(Mouse.of(1, 1, x, y, 0.0)), run: sample_clock_run },
	)

## What a frame with nothing pressed does to the sample clock.
clock_left_alone : VcrButtons.Transport(Clock) -> VcrButtons.Transport(Clock)
clock_left_alone = |transport|
	VcrButtons.next_transport(transport, { input: Input.none, run: sample_clock_run })

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
expect clock_after_click(running_at(100, Forward), { x: 320.0, y: 100.0 }) == running_at(108, Forward)

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

# A step stays on the run at both ends.
expect clock_after_press(stopped_at(0), StepBack) == stopped_at(0)
expect clock_after_press(stopped_at(6000), StepForward) == stopped_at(6000)
expect clock_after_press(stopped_at(1), StepBack) == stopped_at(0)
expect clock_after_press(stopped_at(5999), StepForward) == stopped_at(6000)

# A held button isn't a new click.
expect
	VcrButtons.next_transport(
		stopped_at(100),
		{ input: Input.none.with_mouse(Mouse.of(1, 0, 196.0, 234.0, 0.0)), run: sample_clock_run },
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
expect transport_after_press(stopped_at(6000), { control: Play, run: sample_clock_run }) == running_at(0, Forward)
expect transport_after_press(stopped_at(5999), { control: Play, run: sample_clock_run }) == running_at(5999, Forward)
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
expect buttons_of(Plays(1.0)).len() == 6
expect buttons_of(StepsOnly).len() == 4
expect buttons_of(Plays(1.0)).all(|button| button_shapes(button, Stopped).len() > 1)
expect buttons_of(StepsOnly).all(|button| button_shapes(button, Stopped).len() > 1)
expect button_shapes({ control: Play, left: 24.0 }, Forward).len() == 3
expect button_shapes({ control: Play, left: 24.0 }, Stopped).len() == 2
expect button_shapes({ control: Play, left: 24.0 }, Forward) != button_shapes({ control: Play, left: 24.0 }, Backward)

# A gap's run falls from its farthest to zero, and a metre is a step.
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
		{ input: VcrButtons.click_on(control, sample_gap_run.playing), run: sample_gap_run },
	)

expect gap_after_press(Distance.metres(20.0), StepForward).at == Distance.metres(19.0)
expect gap_after_press(Distance.metres(20.0), StepBack).at == Distance.metres(21.0)
expect gap_after_press(Distance.metres(20.0), Play).at == Distance.metres(19.75)
expect gap_after_press(Distance.metres(20.0), ToStart).at == Distance.metres(50.0)
expect gap_after_press(Distance.metres(20.0), ToEnd).at == Distance.zero
expect gap_after_press(Distance.metres(50.0), StepBack).at == Distance.metres(50.0)
expect gap_after_press(Distance.zero, StepForward).at == Distance.zero

## What a press of `control` on the sample run that doesn't play does.
stepped_after_press : U64, VcrButtons.Control -> VcrButtons.Transport(U64)
stepped_after_press = |number, control|
	VcrButtons.next_transport(
		VcrButtons.transport_at(number),
		{ input: VcrButtons.click_on(control, StepsOnly), run: sample_stepped_run },
	)

# A run that doesn't play has four buttons, side by side, and they step.
expect stepped_after_press(3, StepForward) == VcrButtons.transport_at(4)
expect stepped_after_press(3, StepBack) == VcrButtons.transport_at(2)
expect stepped_after_press(3, ToStart) == VcrButtons.transport_at(1)
expect stepped_after_press(3, ToEnd) == VcrButtons.transport_at(5)
expect stepped_after_press(5, StepForward) == VcrButtons.transport_at(5)
expect stepped_after_press(1, StepBack) == VcrButtons.transport_at(1)
expect control_at(StepsOnly, { x: 90.0, y: 234.0 }) == Ok(StepBack)
expect control_at(StepsOnly, { x: 240.0, y: 234.0 }) == Err(NoButton)
expect control_at(Plays(1.0), { x: 90.0, y: 234.0 }) == Ok(PlayBack)
expect control_at(Plays(1.0), { x: 240.0, y: 234.0 }) == Ok(Play)

## The sample clock caught up with a picture at step 40.
caught_up_to_forty : Input.Snapshot -> VcrButtons.Transport(Clock)
caught_up_to_forty = |input|
	VcrButtons.catch_up(stopped_at(6000), { input, run: sample_clock_run, shown: Clock.at_step(40) })

# A press counts from what's on show, and only a press on a button does.
expect caught_up_to_forty(VcrButtons.click_on(StepBack, Plays(1.0))) == stopped_at(40)
expect caught_up_to_forty(Input.none) == stopped_at(6000)
expect caught_up_to_forty(Input.none.with_mouse(Mouse.of(1, 1, 320.0, 100.0, 0.0))) == stopped_at(6000)
expect caught_up_to_forty(Input.none.with_mouse(Mouse.of(1, 0, 196.0, 234.0, 0.0))) == stopped_at(6000)

# The hint shows until the number has moved or started to, and says what the
# widget's buttons can do.
expect hint(stopped_at(0), sample_clock_run).len() == 1
expect hint(running_at(0, Forward), sample_clock_run).len() == 0
expect hint(stopped_at(1), sample_clock_run).len() == 0
expect hint(VcrButtons.transport_at(1), sample_stepped_run).len() == 1
expect hint(VcrButtons.transport_at(2), sample_stepped_run).len() == 0
expect hint(stopped_at(0), sample_clock_run) != hint(VcrButtons.transport_at(1), sample_stepped_run)

# The page is the panel, then each button's square and icon, then the hint.
expect
	VcrButtons.frame_shapes(stopped_at(1), { run: sample_clock_run, picture: [], status: [] }).len()
		> ScrubWidget.frame_shapes({ picture: [], status: [] }).len()
expect
	VcrButtons.frame_shapes(stopped_at(0), { run: sample_clock_run, picture: [], status: [] }).len()
		== VcrButtons.frame_shapes(stopped_at(1), { run: sample_clock_run, picture: [], status: [] }).len() + 1

# A canvas app opens where the widget says, at rest.
expect
	VcrButtons.canvas_app({
		title: "I",
		run: sample_clock_run,
		opens_at: Clock.at_step(7),
		frame: |_transport| [],
	}).init
		== stopped_at(7)
