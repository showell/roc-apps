## The widget for the Safari tutorial's section on rehearsal. It takes one real
## step of the ride, just after the first bend, and walks through the search
## that step ran. The tries are separate things and not a motion, so there's a
## mark for each, and a click on one goes to it. The arrow keys go one at a time.
## Each try draws its coasting arc on the road, seen from above: the bike's own
## physics run on a rider who doesn't exist. After the twelfth, the picture
## shows the lean the real rider took.
import game.Across
import game.Angle
import game.Coast
import game.Motorcycle
import game.LeanSearch
import game.Geom
import game.Tour
import lib.Brush
import lib.CanvasApp
import lib.Input
import lib.Shapes
import lib.RgbColor
import lib.Trig
import widget.Click
import widget.PlanView
import widget.ReadoutText
import widget.ScrubWidget

RehearsalWidgetApp :: [].{

	## Where the widget has got to: the start, before any try; a try, counted
	## from 1, with it and the tries before it on show; or the choice the search
	## made after its last try.
	Stop : [Start, Shown(U64), Choice]

	## The whole state of the widget: the stop on show.
	Model : { stop : RehearsalWidgetApp.Stop }

	canvas_app : CanvasApp.CanvasApp(RehearsalWidgetApp.Model)
	canvas_app = ScrubWidget.canvas_app({
		frames_a_second: ScrubWidget.moving_frames_a_second,
		title: "Twelve rehearsals",
		init: { stop: Start },
		model_at_next_step: |model, input| { stop: stepped(model.stop, input) },
		frame_shapes: |model| shapes_at(model.stop),
	})
}

## The step of the ride this widget looks inside.
step_shown : U32
step_shown = 374

## The rider's motorcycle at that step, the ride's own.
rider : Motorcycle
rider = Tour.at_step(step_shown).instant.rider.motorcycle

## Where the rider aims: the road's middle, as `LeanSearch.best_lean` does.
target : Across
target = Across.middle

## A point on an arc: how far along the road from the rider, and where across it.
ArcPoint : { forward : F64, across : F64 }

## One try of the search, and the way its coast drew it.
Rehearsal : { lean_try : LeanSearch.LeanTry, path_points : List(ArcPoint) }

## Where a coast with `lean` goes, each step as a point on the arc.
points_of : Angle.Lean -> List(ArcPoint)
points_of = |lean|
	Coast.coast_path(rider.with_lean(lean)).path_motorcycles.map(
		|motion| {
			forward: motion.along.distance_from(rider.along).to_metres(),
			across: motion.across.to_metres(),
		},
	)

rehearsals : List(Rehearsal)
rehearsals =
	LeanSearch.search_tries(rider).map(
		|lean_try| { lean_try, path_points: points_of(LeanSearch.tried_lean(lean_try)) },
	)

## Which way the search went after a try.
lean_correction_of : Rehearsal -> [MoreRight, MoreLeft]
lean_correction_of = |{ lean_try, .. }| LeanSearch.lean_correction(lean_try.outcome)

## The lean the search settled on.
chosen_lean : Angle.Lean
chosen_lean = LeanSearch.best_lean(rider)

chosen_points : List(ArcPoint)
chosen_points = points_of(chosen_lean)

## The place of the choice's mark in the row, after one for each try.
last_stop : U64
last_stop = rehearsals.len() + 1

## The place of `stop` in the row of marks: the start is 0, a try its count, and
## the choice the last.
stop_number : Stop -> U64
stop_number = |stop|
	match stop {
		Start => 0
		Shown(try) => try
		Choice => last_stop
	}

## The stop in place `number` of the row of marks, from 1 to `last_stop`.
stop_at_number : U64 -> Stop
stop_at_number = |number|
	if number == last_stop {
		Choice
	} else {
		Shown(number)
	}

## The stop after `stop`, going round to the start after the choice.
next_stop : Stop -> Stop
next_stop = |stop|
	match stop {
		Start => Shown(1)
		Shown(try) if try < rehearsals.len() => Shown(try + 1)
		Shown(_) => Choice
		Choice => Start
	}

## The stop before `stop`, staying at the start.
previous_stop : Stop -> Stop
previous_stop = |stop|
	match stop {
		Start | Shown(1) => Start
		Shown(try) => Shown(try - 1)
		Choice => Shown(rehearsals.len())
	}

## The stop after this step's clicks and keys. A click that isn't on a mark
## leaves the stop as it was.
stepped : Stop, Input.Snapshot -> Stop
stepped = |stop, input|
	match Click.click_point(input) {
		Ok(spot) => mark_under(spot) ?? stop
		Err(NoClick) =>
			if input.key_pressed(KeyRight) {
				next_stop(stop)
			} else if input.key_pressed(KeyLeft) {
				previous_stop(stop)
			} else {
				stop
			}
	}

line_color : RgbColor
line_color = RgbColor.of(0xc8c8c0)

off_left_color : RgbColor
off_left_color = RgbColor.of(0x6aa0e8)

off_right_color : RgbColor
off_right_color = RgbColor.of(0xe8805a)

kept_color : RgbColor
kept_color = PlanView.standout_color

target_color : RgbColor
target_color = RgbColor.of(0xe8c84a)

## The road from above, with the rider on the road's middle line at the left of
## the picture, and 23 pixels to a metre along the road.
road_plan : PlanView
road_plan = {
	origin: { x: 30.0, y: ScrubWidget.picture_bottom_y / 2.0 },
	pixels_a_metre: 23.0,
}

## How many times its true width the road is drawn across. At its true width
## the arcs would be too close together to tell apart.
across_stretch : F64
across_stretch = 2.0

## The right of the road is down the canvas, for a rider heading across it.
canvas_point : ArcPoint -> { x : F64, y : F64 }
canvas_point = |{ forward, across }|
	road_plan.canvas_point({ metres_right: forward, metres_down: across * across_stretch })

## A line right along the road, `across` metres from its middle.
road_line : { across : F64, color : RgbColor, width : F64 } -> Shapes.Shape
road_line = |{ across, color, width }| {
	y = canvas_point({ forward: 0.0, across }).y
	Shapes.line(
		{ from: { x: 0.0, y }, to: { x: ScrubWidget.canvas_width, y }, width },
		Brush.flat(color),
	)
}

## The road from above, with the line the rider is aiming for.
road_shapes : List(Shapes.Shape)
road_shapes = {
	half_lane = Geom.road_half_width.to_metres()
	[
		ScrubWidget.picture_backdrop(PlanView.ground_color),
		Rect({
			x: 0.0,
			y: canvas_point({ forward: 0.0, across: -half_lane }).y,
			width: ScrubWidget.canvas_width,
			height: 2.0 * half_lane * across_stretch * road_plan.pixels_a_metre,
			fill: Brush.flat(PlanView.road_color),
		}),
		road_line({ across: -half_lane, color: line_color, width: 2.0 }),
		road_line({ across: half_lane, color: line_color, width: 2.0 }),
		road_line({ across: target.to_metres(), color: target_color, width: 1.0 }),
	]
}

## An arc runs for hundreds of steps, each too short to see, so every this
## many is enough to draw it by.
steps_a_line : U64
steps_a_line = 8

## The points to draw an arc through: every so many, and the last.
drawn_points : List(ArcPoint) -> List(ArcPoint)
drawn_points = |path_points| {
	numbered = path_points.map_with_index(|point, index| { point, index })
	spaced = numbered.keep_if(|{ index, .. }| index % steps_a_line == 0).map(|{ point, .. }| point)
	match path_points.last() {
		Ok(end) => spaced.append(end)
		Err(_) => spaced
	}
}

## One arc as a run of lines from the rider. An arc can stand still between
## two of its points, as at its end, where no line is drawn.
arc_shapes : List(ArcPoint), { color : RgbColor, width : F64 } -> List(Shapes.Shape)
arc_shapes = |path_points, { color, width }| {
	start = { forward: 0.0, across: rider.across.to_metres() }
	points = drawn_points(path_points).prepend(start).map(canvas_point)
	points
		.map2(points.drop_first(1), |from, to| { from, to })
		.keep_if(|{ from, to }| from != to)
		.map(|{ from, to }| Shapes.line({ from, to, width }, Brush.flat(color)))
}

## The colour that says where an arc ended.
color_of : Coast.Outcome -> RgbColor
color_of = |outcome|
	match outcome {
		Leaves({ side: Left, .. }) => off_left_color
		Leaves({ side: Right, .. }) => off_right_color
		EndsAt(_) => kept_color
	}

## The arcs for a list of tries.
tries_shapes : List(Rehearsal), F64 -> List(Shapes.Shape)
tries_shapes = |tries, width|
	tries.join_map(|{ path_points, lean_try }| arc_shapes(path_points, { color: color_of(lean_try.outcome), width }))

rider_mark : Shapes.Shape
rider_mark = {
	{ x, y } = canvas_point({ forward: 0.0, across: rider.across.to_metres() })
	Disc({
		x,
		y,
		radius: 7.0,
		fill: Brush.flat(kept_color),
	})
}

## A line of words on the grass along the picture's bottom edge.
caption_shapes : List(Shapes.Shape)
caption_shapes = [ScrubWidget.label({ text: "from above, stretched x2 across the road", x: 10.0, y: 213.0 })]

## The road and the arcs so far. The newest try is drawn bold, and once the
## tries are over the arc that was chosen is.
picture_shapes : Stop -> List(Shapes.Shape)
picture_shapes = |stop|
	[
		road_shapes,
		arcs_shown(stop),
		[rider_mark],
		caption_shapes,
	].join()

## The arcs on show at `stop`, the boldest last.
arcs_shown : Stop -> List(Shapes.Shape)
arcs_shown = |stop|
	match stop {
		Start => []
		Shown(try) => {
			earlier = rehearsals.take_first(try - 1)
			newest = rehearsals.drop_first(try - 1).take_first(1)
			tries_shapes(earlier, 1.0).concat(tries_shapes(newest, 4.0))
		}
		Choice => tries_shapes(rehearsals, 1.0).concat(arc_shapes(chosen_points, { color: kept_color, width: 4.0 }))
	}

## A number of at least zero, to two decimal places.
hundredths_text : F64 -> Str
hundredths_text = |number| {
	hundredths = (number * 100.0 + 0.5).to_i64_wrap()
	whole = (hundredths // 100).to_str()
	part = hundredths % 100
	if part < 10 {
		"${whole}.0${part.to_str()}"
	} else {
		"${whole}.${part.to_str()}"
	}
}

## A lean in degrees, and which way.
lean_text : Angle.Lean -> Str
lean_text = |lean| {
	degrees = lean.to_radians() / Trig.degree
	if degrees < 0.0 {
		"${hundredths_text(0.0 - degrees)} left"
	} else {
		"${hundredths_text(degrees)} right"
	}
}

## Where something across the road is, in words.
across_text : Across -> Str
across_text = |across| {
	metres = across.to_metres()
	if metres < 0.0 {
		"${ReadoutText.tenths_text(metres.abs())} m left"
	} else {
		"${ReadoutText.tenths_text(metres)} m right"
	}
}

## What a rehearsal found, in words.
outcome_text : Rehearsal -> Str
outcome_text = |{ lean_try, path_points }| {
	steps = path_points.len().to_str()
	match lean_try.outcome {
		Leaves({ side: Left, .. }) => "Off the left edge in ${steps} steps"
		Leaves({ side: Right, .. }) => "Off the right edge in ${steps} steps"
		EndsAt(end_across) => "Stays on, ends ${across_text(end_across)}"
	}
}

## What the search does next, in words.
verdict_text : [MoreRight, MoreLeft] -> Str
verdict_text = |lean_correction|
	match lean_correction {
		MoreRight => "So try further right"
		MoreLeft => "So try further left"
	}

## How many steps of physics all the tries ran.
steps_rehearsed : U64
steps_rehearsed = rehearsals.fold(0, |sum, { path_points, .. }| sum + path_points.len())

## What the search has done so far, a line each.
status_lines : Stop -> List(Str)
status_lines = |stop|
	match stop {
		Start =>
			[
				"Step ${step_shown.to_str()}, just after a bend",
				"Leaning ${lean_text(rider.lean)}",
				"Aiming for ${across_text(target)}",
				"Each mark is one try at a lean",
			]
		Shown(try) =>
			match rehearsals.get(try - 1) {
				Ok(rehearsal) =>
					[
						"Try ${try.to_str()} of ${rehearsals.len().to_str()}: lean ${lean_text(LeanSearch.tried_lean(rehearsal.lean_try))}",
						"Between ${lean_text(rehearsal.lean_try.low)} and ${lean_text(rehearsal.lean_try.high)}",
						outcome_text(rehearsal),
						verdict_text(lean_correction_of(rehearsal)),
					]
				Err(_) => crash "RehearsalWidgetApp.status_lines: this try is in the list"
			}
		Choice =>
			[
				"Chosen: ${lean_text(chosen_lean)}",
				"${rehearsals.len().to_str()} rehearsals, ${steps_rehearsed.to_str()} steps of physics",
				"None of them happened",
				"The real rider takes one step",
			]
	}

## How far apart the marks are.
mark_spacing : F64
mark_spacing = 22.0

marks_y : F64
marks_y = 232.0

## How far from the row of marks a click still counts as on it.
marks_reach : F64
marks_reach = 12.0

## Where the mark in place `number` of the row sits. Place 1 is the first, and
## there's one for each try and one for the choice.
mark_x : U64 -> F64
mark_x = |number| ScrubWidget.side_margin + 8.0 + (number.to_f64() - 1.0) * mark_spacing

## The stop whose mark is at `spot`. Each mark's reach ends halfway to the next
## one, so no click is on two.
mark_under : { x : F64, y : F64 } -> Try(Stop, [NoMark])
mark_under = |{ x, y }| {
	number = ((x - mark_x(1)) / mark_spacing + 1.5).to_i64_wrap()
	if (y - marks_y).abs() > marks_reach or number < 1 or number > last_stop.to_i64_wrap() {
		Err(NoMark)
	} else {
		Ok(stop_at_number(number.to_u64_wrap()))
	}
}

## A mark of the row, and the stop on show.
MarkAndStop : { mark : Stop, current : Stop }

## The colour of a mark: the current one stands out, those before it are filled
## in, and the rest are still to come.
mark_color : MarkAndStop -> RgbColor
mark_color = |{ mark, current }|
	if mark == current {
		current_color
	} else if stop_number(mark) < stop_number(current) {
		RgbColor.of(0x303030)
	} else {
		RgbColor.of(0xb8b8b8)
	}

current_color : RgbColor
current_color = PlanView.accent_color

## The mark for one try: a disc, larger when it's the current one.
try_mark : MarkAndStop -> Shapes.Shape
try_mark = |{ mark, current }|
	Disc({
		x: mark_x(stop_number(mark)),
		y: marks_y,
		radius: if mark == current {
			9.0
		} else {
			6.0
		},
		fill: Brush.flat(mark_color({ mark, current })),
	})

## The mark for the choice, which isn't a try, so it's a square.
choice_mark : Stop -> Shapes.Shape
choice_mark = |current| {
	half = if current == Choice {
		8.0
	} else {
		6.0
	}
	Rect({
		x: mark_x(last_stop) - half,
		y: marks_y - half,
		width: 2.0 * half,
		height: 2.0 * half,
		fill: Brush.flat(mark_color({ mark: Choice, current })),
	})
}

## What to do, beside the marks.
hint : Shapes.Shape
hint =
	ScrubWidget.label({
		text: "Click a mark to see that try",
		x: mark_x(last_stop) + 24.0,
		y: marks_y + 5.0,
	})

## The row of marks and what to do with them.
marks : Stop -> List(Shapes.Shape)
marks = |current|
	rehearsals.map_with_index(|_rehearsal, index| try_mark({ mark: Shown(index + 1), current }))
		.append(choice_mark(current))
		.append(hint)

## Everything on the canvas at `stop`.
shapes_at : Stop -> List(Shapes.Shape)
shapes_at = |stop|
	ScrubWidget.frame_shapes({
		picture_shapes: picture_shapes(stop),
		status_lines: status_lines(stop),
	}).concat(marks(stop))

## How many tries the search makes.
round_count : U64
round_count = LeanSearch.lean_search_round_count.to_u64()

# Every arc of this step stays on the road, and the search goes both ways.
expect rehearsals.all(|{ lean_try, .. }| color_of(lean_try.outcome) == kept_color)
expect rehearsals.any(|rehearsal| lean_correction_of(rehearsal) == MoreRight)
expect rehearsals.any(|rehearsal| lean_correction_of(rehearsal) == MoreLeft)

# Going forward runs through every stop and round to the start.
expect next_stop(Start) == Shown(1)
expect next_stop(Shown(1)) == Shown(2)
expect next_stop(Shown(round_count)) == Choice
expect next_stop(Choice) == Start

# Going back stops at the start.
expect previous_stop(Choice) == Shown(round_count)
expect previous_stop(Shown(2)) == Shown(1)
expect previous_stop(Shown(1)) == Start
expect previous_stop(Start) == Start

## The stop after a click at `spot` from the third try.
clicked_from_three : { x : F64, y : F64 } -> Stop
clicked_from_three = |spot| stepped(Shown(3), Click.click_at(spot))

# A click on a mark goes straight to that stop, either way along the row.
expect clicked_from_three({ x: mark_x(9), y: marks_y }) == Shown(9)
expect clicked_from_three({ x: mark_x(1), y: marks_y }) == Shown(1)
expect clicked_from_three({ x: mark_x(last_stop), y: marks_y }) == Choice
expect clicked_from_three({ x: mark_x(3), y: marks_y }) == Shown(3)

# A click anywhere else leaves it alone: on the picture, on the text, past
# either end of the row.
expect clicked_from_three({ x: 320.0, y: 100.0 }) == Shown(3)
expect clicked_from_three({ x: 320.0, y: 300.0 }) == Shown(3)
expect clicked_from_three({ x: 2.0, y: marks_y }) == Shown(3)
expect clicked_from_three({ x: 620.0, y: marks_y }) == Shown(3)

# Holding the button on another mark isn't a click, and nor is nothing at all.
expect stepped(Shown(3), Click.held_at({ x: mark_x(9), y: marks_y })) == Shown(3)
expect stepped(Shown(3), Input.none) == Shown(3)

# Each mark reaches halfway to the next, and the row's reach ends above and below.
expect mark_under({ x: mark_x(5) + 10.0, y: marks_y }) == Ok(Shown(5))
expect mark_under({ x: mark_x(5) + 12.0, y: marks_y }) == Ok(Shown(6))
expect mark_under({ x: mark_x(5), y: marks_y + marks_reach }) == Ok(Shown(5))
expect mark_under({ x: mark_x(5), y: marks_y + marks_reach + 1.0 }) == Err(NoMark)
expect mark_under({ x: mark_x(5), y: marks_y - marks_reach - 1.0 }) == Err(NoMark)

# An arc is drawn by fewer points than it has, and it still ends at its end.
expect
	rehearsals.all(
		|{ path_points, .. }| {
			drawn = drawn_points(path_points)
			drawn.len() < path_points.len() and drawn.last() == path_points.last()
		},
	)

# The current mark stands apart from those before and after it.
expect mark_color({ mark: Shown(5), current: Shown(5) }) == current_color
expect mark_color({ mark: Shown(4), current: Shown(5) }) != current_color
expect mark_color({ mark: Shown(6), current: Shown(5) }) != current_color
expect mark_color({ mark: Shown(4), current: Shown(5) }) != mark_color({ mark: Shown(6), current: Shown(5) })

# A mark for each try and one for the choice, then the words.
expect marks(Start).len() > last_stop
expect marks(Shown(1)) != marks(Shown(2))

expect lean_text(Angle.Lean.degrees(12.0)) == "12.00 right"
expect lean_text(Angle.Lean.degrees(12.05)) == "12.05 right"
expect lean_text(Angle.Lean.degrees(-0.5)) == "0.50 left"

expect across_text(Across.metres(-0.5)) == "0.5 m left"
expect across_text(Across.metres(0.5)) == "0.5 m right"

expect verdict_text(MoreRight) == "So try further right"
expect verdict_text(MoreLeft) == "So try further left"

# The picture changes with every stop along the ruler.
expect picture_shapes(Start) != picture_shapes(Shown(1))
expect picture_shapes(Shown(1)) != picture_shapes(Shown(2))
expect picture_shapes(Shown(round_count)) != picture_shapes(Choice)
