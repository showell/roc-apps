## ChessControls draws what sits around a chess toy's board: its title above,
## and below it the status line, the transport row (rewind, step back, play,
## step forward, and the speed slider with its rate), the hint and the
## legend. It also says which control the pointer is on and which slider
## position a point picks. All of it is set in monospace on the page's dark
## ground.
import lib.Brush
import lib.CurvedShapes
import lib.Math
import lib.Pixels
import lib.Point
import lib.Shapes

ChessControls :: [].{

	## The page's size.
	width : F64
	width = 660.0

	height : F64
	height = 740.0

	## A button of the transport row.
	Button : [Rewind, StepBack, Play, StepForward]

	## Where a point on the page lands among the controls.
	Spot : [OnButton(ChessControls.Button), OnSlider, Elsewhere]

	## How fast the search plays, as the slider's position: 0 to 17, which is
	## 2 to 262,144 steps a second, doubling each place.
	most_speed : U64
	most_speed = 17

	## The steps a second at a slider position.
	steps_a_second : U64 -> U64
	steps_a_second = |speed| U64.shl_wrap(2, speed.to_u8_wrap())

	## The control under `point`.
	spot_at : Math.Vec2 -> ChessControls.Spot
	spot_at = |point| {
		x = point.x.to_f64()
		y = point.y.to_f64()
		on_row = y >= row_top and y <= row_top + row_height
		if on_row and x >= slider_left and x <= slider_left + slider_width {
			OnSlider
		} else if on_row {
			match buttons.find_first(|button| x >= button.left and x <= button.left + button.width) {
				Ok(button) => OnButton(button.button)
				Err(NotFound) => Elsewhere
			}
		} else {
			Elsewhere
		}
	}

	## The slider position nearest the point's place across the slider.
	speed_at : Math.Vec2 -> U64
	speed_at = |point| {
		travel = slider_width - 2.0 * knob_radius
		fraction = F64.min(1.0, F64.max(0.0, (point.x.to_f64() - slider_left - knob_radius) / travel))
		place = (fraction * most_speed.to_f64() + 0.5).floor_to_i64_try() ?? crash "ChessControls.speed_at: a fraction of the slider is finite"
		place.to_u64_wrap()
	}

	## What the controls show, beside the words the toy chose.
	View : {
		title : Str,
		status : Str,
		hint : Str,
		legend : Str,
		playing : [Paused, Playing, Rewinding],
		speed : U64,
	}

	## The shapes around the board.
	controls_shapes : ChessControls.View -> List(Shapes.Shape)
	controls_shapes = |view| {
		middle = ChessControls.width / 2.0
		List.join([
			[
				text_at({ text: view.title, x: middle, y: 36.0, size: 20.0, color: title_ink, align: Center }),
				text_at({ text: view.status, x: middle, y: 625.0, size: 13.0, color: status_ink, align: Center }),
			],
			buttons.map(|button| button_shapes(button, view.playing)).join(),
			slider_shapes(view.speed),
			[
				text_at({
					text: "${grouped(ChessControls.steps_a_second(view.speed))}/s",
					x: slider_left + slider_width + gap,
					y: row_top + 18.0,
					size: 12.0,
					color: status_ink,
					align: Left,
				}),
				text_at({ text: view.hint, x: middle, y: 692.0, size: 12.0, color: hint_ink, align: Center }),
				text_at({ text: view.legend, x: middle, y: 719.0, size: 12.0, color: hint_ink, align: Center }),
			],
		])
	}

	## A count as the page writes one, a comma between each three digits.
	grouped : U64 -> Str
	grouped = |count| {
		digits = count.to_str().to_utf8()
		length = digits.len()
		grouped_digits = digits.map_with_index(
			|digit, index|
				if index > 0 and (length - index) % 3 == 0 {
					[comma, digit]
				} else {
					[digit]
				},
		)
		Str.from_utf8(grouped_digits.join()) ?? crash "ChessControls.grouped: digits and commas are ASCII"
	}
}

## The byte of a comma.
comma : U8
comma = 44

## A button's place in the row and its kind.
PlacedButton : { button : ChessControls.Button, left : F64, width : F64 }

## The transport row's buttons, left to right, each as wide as its longer
## label in the row's type.
buttons : List(PlacedButton)
buttons = [
	{ button: Rewind, left: 42.0, width: 88.0 },
	{ button: StepBack, left: 138.0, width: 73.0 },
	{ button: Play, left: 219.0, width: 81.0 },
	{ button: StepForward, left: 308.0, width: 73.0 },
]

row_top : F64
row_top = 640.0

row_height : F64
row_height = 28.0

gap : F64
gap = 8.0

slider_left : F64
slider_left = 389.0

slider_width : F64
slider_width = 140.0

knob_radius : F64
knob_radius = 8.0

## How wide a letter of the buttons' 13-pixel monospace is.
letter_width : F64
letter_width = 13.0 * 0.6

## The icon a button shows before or after its words: a pause where the
## button would stop what plays.
Icon : [RewindIcon, PauseIcon, StepBackIcon, PlayIcon, StepForwardIcon]

## A button: its box, its icon and its words.
button_shapes : PlacedButton, [Paused, Playing, Rewinding] -> List(Shapes.Shape)
button_shapes = |placed, playing| {
	(icon, words, icon_first) =
		match placed.button {
			Rewind =>
				match playing {
					Rewinding => (PauseIcon, "pause", Bool.True)
					Paused | Playing => (RewindIcon, "rewind", Bool.True)
				}
			StepBack => (StepBackIcon, "step", Bool.True)
			Play =>
				match playing {
					Playing => (PauseIcon, "pause", Bool.True)
					Paused | Rewinding => (PlayIcon, "play", Bool.True)
				}
			StepForward => (StepForwardIcon, "step", Bool.False)
		}
	box = [
		CurvedShapes.rounded_rect(
			{
				top_left: Point.at(placed.left, row_top),
				width: Pixels.of(placed.width),
				height: Pixels.of(row_height),
				corner_radius: Pixels.of(4.0),
				corner_steps: 4,
			},
			Flat(button_edge),
		),
		CurvedShapes.rounded_rect(
			{
				top_left: Point.at(placed.left + 1.0, row_top + 1.0),
				width: Pixels.of(placed.width - 2.0),
				height: Pixels.of(row_height - 2.0),
				corner_radius: Pixels.of(3.0),
				corner_steps: 4,
			},
			Flat(button_face),
		),
	]
	inner_left = placed.left + 13.0
	baseline = row_top + 18.5
	middle_y = row_top + row_height / 2.0
	(icon_left, words_left) =
		if icon_first {
			(inner_left, inner_left + 2.0 * letter_width)
		} else {
			(inner_left + (words.count_utf8_bytes() + 1).to_f64() * letter_width, inner_left)
		}
	List.join([
		box,
		icon_shapes(icon, { left: icon_left, middle: middle_y }),
		[text_at({ text: words, x: words_left, y: baseline, size: 13.0, color: button_ink, align: Left })],
	])
}

## An icon in a letter's cell whose left edge is `left`, centred on `middle`.
icon_shapes : Icon, { left : F64, middle : F64 } -> List(Shapes.Shape)
icon_shapes = |icon, { left, middle }| {
	triangle = |tip_x, back_x, half_height|
		Triangle({
			first: Point.at(tip_x, middle),
			second: Point.at(back_x, middle - half_height),
			third: Point.at(back_x, middle + half_height),
			fill: Flat(button_ink),
		})
	bar = |bar_left|
		Shapes.rectangle({
			top_left: Point.at(bar_left, middle - 4.5),
			width: Pixels.of(2.5),
			height: Pixels.of(9.0),
			fill: Flat(button_ink),
		})
	match icon {
		RewindIcon => [triangle(left, left + 4.0, 4.0), triangle(left + 4.0, left + 8.0, 4.0)]
		PauseIcon => [bar(left + 1.0), bar(left + 5.0)]
		StepBackIcon => [triangle(left + 1.5, left + 6.5, 3.5)]
		PlayIcon => [triangle(left + 7.5, left + 0.5, 4.5)]
		StepForwardIcon => [triangle(left + 6.5, left + 1.5, 3.5)]
	}
}

## The slider: its track, filled in up to the knob, and the knob.
slider_shapes : U64 -> List(Shapes.Shape)
slider_shapes = |speed| {
	middle = row_top + row_height / 2.0
	travel = slider_width - 2.0 * knob_radius
	knob_x = slider_left + knob_radius + travel * speed.to_f64() / ChessControls.most_speed.to_f64()
	track = |from_x, to_x, color|
		CurvedShapes.rounded_rect(
			{
				top_left: Point.at(from_x, middle - 2.0),
				width: Pixels.of(to_x - from_x),
				height: Pixels.of(4.0),
				corner_radius: Pixels.of(2.0),
				corner_steps: 3,
			},
			Flat(color),
		)
	[
		track(slider_left, slider_left + slider_width, slider_rest),
		track(slider_left, knob_x, slider_accent),
		Disc({ center: Point.at(knob_x, middle), radius: Pixels.of(knob_radius), fill: Flat(slider_accent) }),
	]
}

## A line of the page's monospace.
text_at : {
	text : Str,
	x : F64,
	y : F64,
	size : F64,
	color : Brush.Rgba,
	align : Shapes.Align,
} -> Shapes.Shape
text_at = |{ text, x, y, size, color, align }|
	Text({
		text,
		x,
		y,
		size,
		face: Code,
		align,
		color,
	})

title_ink : Brush.Rgba
title_ink = { r: 232.0, g: 226.0, b: 214.0, a: 1.0 }

status_ink : Brush.Rgba
status_ink = { r: 154.0, g: 160.0, b: 166.0, a: 1.0 }

hint_ink : Brush.Rgba
hint_ink = { r: 109.0, g: 114.0, b: 120.0, a: 1.0 }

button_ink : Brush.Rgba
button_ink = { r: 207.0, g: 210.0, b: 214.0, a: 1.0 }

button_face : Brush.Rgba
button_face = { r: 29.0, g: 31.0, b: 36.0, a: 1.0 }

button_edge : Brush.Rgba
button_edge = { r: 51.0, g: 54.0, b: 61.0, a: 1.0 }

slider_accent : Brush.Rgba
slider_accent = { r: 138.0, g: 147.0, b: 160.0, a: 1.0 }

slider_rest : Brush.Rgba
slider_rest = { r: 74.0, g: 77.0, b: 85.0, a: 1.0 }

# The rate doubles each place, from 2 a second to 262,144.
expect [(0, 2), (3, 16), (17, 262144)].all(|(speed, rate)| ChessControls.steps_a_second(speed) == rate)

# Counts are grouped by threes, as a browser's English locale writes them.
expect [(0, "0"), (999, "999"), (1000, "1,000"), (2520884, "2,520,884"), (262144, "262,144")].all(|(count, text)| ChessControls.grouped(count) == text)

# Each button answers over its own box, the slider over its track, and a
# point between them or off the row answers nothing.
expect ChessControls.spot_at({ x: 50, y: 650 }) == OnButton(Rewind)
expect ChessControls.spot_at({ x: 300, y: 668 }) == OnButton(Play)
expect ChessControls.spot_at({ x: 381, y: 640 }) == OnButton(StepForward)
expect ChessControls.spot_at({ x: 400, y: 654 }) == OnSlider
expect [{ x: 134, y: 650 }, { x: 50, y: 639 }, { x: 50, y: 669 }, { x: 600, y: 654 }].all(|point| ChessControls.spot_at(point) == Elsewhere)

# The slider's ends pick its first and last place, and its middle the place
# nearest the middle.
expect ChessControls.speed_at({ x: 389, y: 654 }) == 0 and ChessControls.speed_at({ x: 529, y: 654 }) == 17
expect ChessControls.speed_at({ x: 459, y: 654 }) == 9
