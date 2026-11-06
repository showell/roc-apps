## The widget for the Safari tutorial's section on rehearsal. It takes one real
## step of the ride, just after the first bend, and walks through the search
## that step ran. The tries are separate things and not a motion, so there's a
## mark for each, and a click on one goes to it. The arrow keys go one at a time.
## Each try draws its coasting arc on the road, seen from above: the bike's own
## physics run on a rider who doesn't exist. After the twelfth, the picture
## shows the lean the real rider took.
import game.Acceleration
import game.Across
import game.Along
import game.Angle
import game.Coast
import game.Bike
import game.Clock
import game.Distance
import game.LeanSearch
import game.Scenery
import game.Speed
import game.Tour
import lib.CanvasApp
import lib.Input
import lib.Mouse
import lib.Shapes
import lib.Trig
import widget.ScrubWidget

RehearsalWidgetApp :: [].{

	## The whole state of the widget: how many of the tries are on show.
	Model : { tries_shown : U64 }

	canvas_app : CanvasApp.CanvasApp(RehearsalWidgetApp.Model)
	canvas_app = {
		size: { width: ScrubWidget.canvas_width, height: ScrubWidget.canvas_height },
		fps: 60,
		init: { tries_shown: 0 },
		advance: |model, input, _seconds| { tries_shown: stepped(model.tries_shown, input) },
		frame: |model| frame_at(model.tries_shown),
		sounds: |_model| 0,
		tones: [],
		title: "Twelve rehearsals",
	}
}

## The step of the ride this widget looks inside.
step_shown : U32
step_shown = 370

## The rider at that step, a record like any other. An `expect` below rides
## there and compares.
rider : Bike.Motion({})
rider = {
	along: Along.metres(4.90868673787897),
	across: Across.metres(-1.930897632424363),
	yaw: Angle.Turn.radians(0.04392681817843164),
	speed: Speed.metres_a_step(0.08377159378729097),
	lean: Angle.Lean.radians(0.006118878920566433),
	heading: Angle.Bearing.radians(0.9165914441755961),
}

target : Across
target = LeanSearch.lean_target(rider.across)

## A point on an arc: how far along the road from the rider, and where across it.
ArcPoint : { forward : F64, across : F64 }

## One try of the search: the lean it tried, the bounds it tried it between,
## what the rehearsal found, and the way the rehearsal drew it.
Rehearsal : {
	lean : Angle.Lean,
	low : Angle.Lean,
	high : Angle.Lean,
	outcome : Coast.Outcome,
	wants_more_right : Bool,
	path : List(ArcPoint),
}

## The road's edge that stops an arc, on the right. The left's is its mirror.
arc_edge : Distance
arc_edge = Scenery.road_half_width.minus(Coast.straighten_margin)

## Whether an arc that has reached `motion` runs on. These are the tests in
## `Coast.judge_place`, which answers with only where an arc ends. An `expect` below
## holds the two to the same end.
runs_on : Bike.Motion({}) -> Bool
runs_on = |motion| {
	forward = motion.along.distance_from(rider.along)
	on_road =
		motion.across >= Across.left_of_middle(arc_edge)
			and motion.across <= Across.right_of_middle(arc_edge)
	on_road and forward >= Distance.zero and forward < Coast.clear_distance
}

## The way a rider coasts with `lean`: the call `Coast.coast_from` makes.
path_of : Angle.Lean -> List(ArcPoint)
path_of = |lean| {
	var $motion = Bike.with_lean(rider, lean)
	var $points = []
	var $going = True
	while $going {
		$motion = Bike.advance(
			$motion,
			{ lean_step: Angle.upright, acceleration: Acceleration.steady },
		)
		$points = $points.append({
			forward: $motion.along.distance_from(rider.along).to_metres(),
			across: $motion.across.to_metres(),
		})
		$going = runs_on($motion)
	}
	$points
}

## The tries from `at` on, between `low` and `high`: the bisection in
## `LeanSearch.search_lean`, keeping what that throws away.
rehearsals_from : { low : Angle.Lean, high : Angle.Lean, at : I64 } -> List(Rehearsal)
rehearsals_from = |{ low, high, at }|
	if at >= LeanSearch.lean_search_rounds {
		[]
	} else {
		lean = low.halfway_to(high)
		outcome = Coast.project(Bike.with_lean(rider, lean))
		wants_more_right = LeanSearch.want_more_right(outcome, target)
		next =
			if wants_more_right {
				{ low: lean, high, at: at + 1 }
			} else {
				{ low, high: lean, at: at + 1 }
			}
		rehearsals_from(next).prepend({
			lean,
			low,
			high,
			outcome,
			wants_more_right,
			path: path_of(lean),
		})
	}

rehearsals : List(Rehearsal)
rehearsals =
	rehearsals_from({
		low: rider.lean.minus(LeanSearch.max_lean_change),
		high: rider.lean.plus(LeanSearch.max_lean_change),
		at: 0,
	})

## The lean the search settled on, midway between its last bounds.
chosen_lean : Angle.Lean
chosen_lean =
	match rehearsals.last() {
		Ok({ lean, low, high, wants_more_right, .. }) =>
			if wants_more_right {
				lean.halfway_to(high)
			} else {
				low.halfway_to(lean)
			}
		Err(_) => crash "RehearsalWidgetApp.chosen_lean: the search has tries"
	}

chosen_path : List(ArcPoint)
chosen_path = path_of(chosen_lean)

## How many tries are on show at the last stop, which is the choice.
last_stop : U64
last_stop = rehearsals.len() + 1

## The stop after `tries_shown`, going round to the start after the last.
next_stop : U64 -> U64
next_stop = |tries_shown|
	if tries_shown >= last_stop {
		0
	} else {
		tries_shown + 1
	}

## The stop before `tries_shown`, staying at the start.
previous_stop : U64 -> U64
previous_stop = |tries_shown|
	if tries_shown == 0 {
		0
	} else {
		tries_shown - 1
	}

## The stop after this step's clicks and keys. A click that isn't on a mark
## leaves the stop as it was.
stepped : U64, Input.Snapshot -> U64
stepped = |tries_shown, input|
	if input.mouse.button_pressed(Left) {
		{ x, y } = input.mouse.position()
		mark_under(x.to_f64(), y.to_f64()) ?? tries_shown
	} else if input.key_pressed(KeyRight) {
		next_stop(tries_shown)
	} else if input.key_pressed(KeyLeft) {
		previous_stop(tries_shown)
	} else {
		tries_shown
	}

## Whether `tries_shown` has got past the last try, to the choice.
is_past_the_tries : U64 -> Bool
is_past_the_tries = |tries_shown| tries_shown > rehearsals.len()

ground_color : I64
ground_color = 0x6f9a55

road_color : I64
road_color = 0x4a4a46

line_color : I64
line_color = 0xc8c8c0

off_left_color : I64
off_left_color = 0x6aa0e8

off_right_color : I64
off_right_color = 0xe8805a

kept_color : I64
kept_color = 0xf2efe4

target_color : I64
target_color = 0xe8c84a

## How many pixels a metre along the road takes up.
pixels_a_metre_along : F64
pixels_a_metre_along = 23.0

## How many pixels a metre across the road takes up. This is twice the figure
## along it, or the arcs would be too close together to tell apart.
pixels_a_metre_across : F64
pixels_a_metre_across = 46.0

## Where the rider sits on the canvas.
rider_x : F64
rider_x = 30.0

road_middle_y : F64
road_middle_y = ScrubWidget.picture_bottom_y / 2.0

## The right of the road is down the canvas, for a rider heading across it.
canvas_point : ArcPoint -> { x : F64, y : F64 }
canvas_point = |{ forward, across }| {
	x: rider_x + forward * pixels_a_metre_along,
	y: road_middle_y + across * pixels_a_metre_across,
}

ground : Shapes.Shape
ground = Rect({
	x: 0.0,
	y: 0.0,
	w: ScrubWidget.canvas_width,
	h: ScrubWidget.picture_bottom_y,
	fill: ScrubWidget.flat(ground_color),
})

## A line right along the road, `across` metres from its middle.
road_line : { across : F64, color : I64, width : F64 } -> Shapes.Shape
road_line = |{ across, color, width }| {
	y = canvas_point({ forward: 0.0, across }).y
	Shapes.line(
		0.0,
		y,
		ScrubWidget.canvas_width,
		y,
		width,
		ScrubWidget.flat(color),
	)
}

## The road from above, with the line the rider is aiming for.
road : List(Shapes.Shape)
road = {
	half_lane = Scenery.road_half_width.to_metres()
	[
		ground,
		Rect({
			x: 0.0,
			y: canvas_point({ forward: 0.0, across: -half_lane }).y,
			w: ScrubWidget.canvas_width,
			h: 2.0 * half_lane * pixels_a_metre_across,
			fill: ScrubWidget.flat(road_color),
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
drawn_points = |path| {
	numbered = path.map_with_index(|point, index| { point, index })
	spaced = numbered.keep_if(|{ index, .. }| index % steps_a_line == 0).map(|{ point, .. }| point)
	match path.last() {
		Ok(end) => spaced.append(end)
		Err(_) => spaced
	}
}

## One arc as a run of lines from the rider.
arc_shapes : List(ArcPoint), { color : I64, width : F64 } -> List(Shapes.Shape)
arc_shapes = |path, { color, width }| {
	start = { forward: 0.0, across: rider.across.to_metres() }
	points = drawn_points(path).prepend(start).map(canvas_point)
	points.map2(
		points.drop_first(1),
		|a, b|
			Shapes.line(
				a.x,
				a.y,
				b.x,
				b.y,
				width,
				ScrubWidget.flat(color),
			),
	)
}

## The colour that says where an arc ended.
color_of : Coast.Outcome -> I64
color_of = |outcome|
	match outcome.exit {
		Leaves({ side: Left, .. }) => off_left_color
		Leaves({ side: Right, .. }) => off_right_color
		StaysOn => kept_color
	}

## The arcs for a list of tries.
tries_shapes : List(Rehearsal), F64 -> List(Shapes.Shape)
tries_shapes = |tries, width|
	tries.join_map(|{ path, outcome, .. }| arc_shapes(path, { color: color_of(outcome), width }))

rider_mark : Shapes.Shape
rider_mark = {
	{ x, y } = canvas_point({ forward: 0.0, across: rider.across.to_metres() })
	Disc({
		x,
		y,
		r: 7.0,
		fill: ScrubWidget.flat(kept_color),
		clip: Anywhere,
	})
}

## A line of words on the grass along the picture's bottom edge.
caption : List(Shapes.Shape)
caption = [ScrubWidget.label({ text: "from above, stretched x2 across the road", x: 10.0, y: 213.0 })]

## The road and the arcs so far. The newest try is drawn bold, and once the
## tries are over the arc that was chosen is.
picture : U64 -> List(Shapes.Shape)
picture = |tries_shown|
	[
		road,
		arcs_shown(tries_shown),
		[rider_mark],
		caption,
	].join()

## The arcs with `tries_shown` tries on show, the boldest last.
arcs_shown : U64 -> List(Shapes.Shape)
arcs_shown = |tries_shown|
	if tries_shown == 0 {
		[]
	} else if is_past_the_tries(tries_shown) {
		tries_shapes(rehearsals, 1.0).concat(arc_shapes(chosen_path, { color: kept_color, width: 4.0 }))
	} else {
		earlier = rehearsals.take_first(tries_shown - 1)
		newest = rehearsals.drop_first(tries_shown - 1).take_first(1)
		tries_shapes(earlier, 1.0).concat(tries_shapes(newest, 4.0))
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
	degrees = lean.to_radians() / Trig.deg
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
		"${ScrubWidget.tenths_text(0.0 - metres)} m left"
	} else {
		"${ScrubWidget.tenths_text(metres)} m right"
	}
}

## What a rehearsal found, in words.
outcome_text : Rehearsal -> Str
outcome_text = |{ outcome, path, .. }| {
	steps = path.len().to_str()
	match outcome.exit {
		Leaves({ side: Left, .. }) => "Off the left edge in ${steps} steps"
		Leaves({ side: Right, .. }) => "Off the right edge in ${steps} steps"
		StaysOn => "Stays on, ends ${across_text(outcome.end_across)}"
	}
}

## What the search does next, in words.
verdict_text : Rehearsal -> Str
verdict_text = |{ wants_more_right, .. }|
	if wants_more_right {
		"So try further right"
	} else {
		"So try further left"
	}

## How many steps of physics all the tries ran.
steps_rehearsed : U64
steps_rehearsed = rehearsals.fold(0, |sum, { path, .. }| sum + path.len())

## What the search has done so far, a line each.
status_lines : U64 -> List(Str)
status_lines = |tries_shown|
	if tries_shown == 0 {
		[
			"Step ${step_shown.to_str()}, just after a bend",
			"Leaning ${lean_text(rider.lean)}",
			"Aiming for ${across_text(target)}",
			"Each mark is one try at a lean",
		]
	} else if is_past_the_tries(tries_shown) {
		[
			"Chosen: ${lean_text(chosen_lean)}",
			"${rehearsals.len().to_str()} rehearsals, ${steps_rehearsed.to_str()} steps of physics",
			"None of them happened",
			"The real rider takes one step",
		]
	} else {
		match rehearsals.get(tries_shown - 1) {
			Ok(rehearsal) =>
				[
					"Try ${tries_shown.to_str()} of ${rehearsals.len().to_str()}: lean ${lean_text(rehearsal.lean)}",
					"Between ${lean_text(rehearsal.low)} and ${lean_text(rehearsal.high)}",
					outcome_text(rehearsal),
					verdict_text(rehearsal),
				]
			Err(_) => crash "RehearsalWidgetApp.status_lines: this try is in the list"
		}
	}

## How far apart the marks are.
mark_spacing : F64
mark_spacing = 22.0

marks_y : F64
marks_y = 232.0

## How far from the row of marks a click still counts as on it.
marks_reach : F64
marks_reach = 12.0

## Where the mark for stop `stop` sits. Stop 1 is the first, and there's one
## for each try and one for the choice.
mark_x : U64 -> F64
mark_x = |stop| ScrubWidget.side_margin + 8.0 + (stop.to_f64() - 1.0) * mark_spacing

## The stop whose mark is at (`x`, `y`). Each mark's reach ends halfway to the
## next one, so no click is on two.
mark_under : F64, F64 -> Try(U64, [NoMark])
mark_under = |x, y| {
	stop = ((x - mark_x(1)) / mark_spacing + 1.5).to_i64_wrap()
	if (y - marks_y).abs() > marks_reach or stop < 1 or stop > last_stop.to_i64_wrap() {
		Err(NoMark)
	} else {
		Ok(stop.to_u64_wrap())
	}
}

## The colour of the mark for `stop`: the current one stands out, those before
## it are filled in, and the rest are still to come.
mark_color : U64, U64 -> I64
mark_color = |stop, tries_shown|
	if stop == tries_shown {
		current_color
	} else if stop < tries_shown {
		0x303030
	} else {
		0xb8b8b8
	}

current_color : I64
current_color = 0xd0603a

## The mark for one try: a disc, larger when it's the current one.
try_mark : U64, U64 -> Shapes.Shape
try_mark = |stop, tries_shown|
	Disc({
		x: mark_x(stop),
		y: marks_y,
		r: if stop == tries_shown {
			9.0
		} else {
			6.0
		},
		fill: ScrubWidget.flat(mark_color(stop, tries_shown)),
		clip: Anywhere,
	})

## The mark for the choice, which isn't a try, so it's a square.
choice_mark : U64 -> Shapes.Shape
choice_mark = |tries_shown| {
	half = if last_stop == tries_shown {
		8.0
	} else {
		6.0
	}
	Rect({
		x: mark_x(last_stop) - half,
		y: marks_y - half,
		w: 2.0 * half,
		h: 2.0 * half,
		fill: ScrubWidget.flat(mark_color(last_stop, tries_shown)),
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
marks : U64 -> List(Shapes.Shape)
marks = |tries_shown|
	rehearsals.map_with_index(|_rehearsal, index| try_mark(index + 1, tries_shown))
		.append(choice_mark(tries_shown))
		.append(hint)

## Everything on the canvas with `tries_shown` tries on show.
frame_at : U64 -> List(Shapes.Shape)
frame_at = |tries_shown|
	ScrubWidget.frame_shapes({
		picture: picture(tries_shown),
		status: status_lines(tries_shown),
	}).concat(marks(tries_shown))

## The ride at `step`, played from its start.
ridden_to : U32 -> Tour
ridden_to = |step| {
	var $tour = Tour.initial
	while $tour.instant.clock != Clock.at_step(step) {
		$tour = Tour.step_forward($tour)
	}
	$tour
}

# The record above is the real rider at that step, field by field.
expect {
	real = ridden_to(step_shown).instant.rider
	real.along == rider.along
		and real.across == rider.across
		and real.yaw == rider.yaw
		and real.speed == rider.speed
		and real.lean == rider.lean
		and real.heading == rider.heading
}

# The tries come to the lean the game's own search comes to.
expect rehearsals.len() == 12
expect chosen_lean.to_radians() == LeanSearch.best_lean(rider).to_radians()

# Each path ends where the game's own arc says that arc ends.
expect
	rehearsals.all(
		|{ path, outcome, .. }|
			match path.last() {
				Ok(point) => point.across == outcome.end_across.to_metres()
				Err(_) => False
			},
	)

# Every arc of this step stays on the road, and the search goes both ways.
expect rehearsals.all(|{ outcome, .. }| color_of(outcome) == kept_color)
expect rehearsals.any(|{ wants_more_right, .. }| wants_more_right)
expect rehearsals.any(|{ wants_more_right, .. }| !wants_more_right)

# Going forward runs through every stop and round to the start.
expect next_stop(0) == 1
expect next_stop(12) == 13
expect next_stop(13) == 0

# Going back stops at the start.
expect previous_stop(13) == 12
expect previous_stop(1) == 0
expect previous_stop(0) == 0

## A snapshot with the pointer at (`x`, `y`) and the left button just pressed,
## or held from before.
pointer_at : { x : F32, y : F32, struck : U32 } -> Input.Snapshot
pointer_at = |{ x, y, struck }| Input.none.with_mouse(
	Mouse.of(
		1,
		struck,
		x,
		y,
		0.0,
	),
)

## The stop after a click at (`x`, `y`) from stop 3.
clicked_from_three : F32, F32 -> U64
clicked_from_three = |x, y| stepped(3, pointer_at({ x, y, struck: 1 }))

# A click on a mark goes straight to that stop, either way along the row.
expect clicked_from_three(mark_x(9).to_f32_wrap(), 232.0) == 9
expect clicked_from_three(mark_x(1).to_f32_wrap(), 232.0) == 1
expect clicked_from_three(mark_x(13).to_f32_wrap(), 232.0) == 13
expect clicked_from_three(mark_x(3).to_f32_wrap(), 232.0) == 3

# A click anywhere else leaves it alone: on the picture, on the text, past
# either end of the row.
expect clicked_from_three(320.0, 100.0) == 3
expect clicked_from_three(320.0, 300.0) == 3
expect clicked_from_three(2.0, 232.0) == 3
expect clicked_from_three(620.0, 232.0) == 3

# Holding the button on another mark isn't a click, and nor is nothing at all.
expect stepped(3, pointer_at({ x: mark_x(9).to_f32_wrap(), y: 232.0, struck: 0 })) == 3
expect stepped(3, Input.none) == 3

# Each mark reaches halfway to the next, and the row's reach ends above and below.
expect mark_under(mark_x(5) + 10.0, marks_y) == Ok(5)
expect mark_under(mark_x(5) + 12.0, marks_y) == Ok(6)
expect mark_under(mark_x(5), marks_y + marks_reach) == Ok(5)
expect mark_under(mark_x(5), marks_y + marks_reach + 1.0) == Err(NoMark)
expect mark_under(mark_x(5), marks_y - marks_reach - 1.0) == Err(NoMark)

expect !is_past_the_tries(12)
expect is_past_the_tries(13)

# An arc is drawn by fewer points than it has, and it still ends at its end.
expect
	rehearsals.all(
		|{ path, .. }| {
			drawn = drawn_points(path)
			drawn.len() < path.len() and drawn.last() == path.last()
		},
	)

# The current mark stands apart from those before and after it.
expect mark_color(5, 5) == current_color
expect mark_color(4, 5) != current_color
expect mark_color(6, 5) != current_color
expect mark_color(4, 5) != mark_color(6, 5)

# A mark for each try and one for the choice, then the words.
expect marks(0).len() > 13
expect marks(1) != marks(2)

expect lean_text(Angle.Lean.degrees(12.0)) == "12.00 right"
expect lean_text(Angle.Lean.degrees(12.05)) == "12.05 right"
expect lean_text(Angle.Lean.degrees(-0.5)) == "0.50 left"

expect across_text(Across.metres(-0.5)) == "0.5 m left"
expect across_text(Across.metres(0.5)) == "0.5 m right"

expect verdict_text({ ..rehearsal_one, wants_more_right: True }) == "So try further right"
expect verdict_text({ ..rehearsal_one, wants_more_right: False }) == "So try further left"

## The search's first try.
rehearsal_one : Rehearsal
rehearsal_one = rehearsals.first() ?? crash "RehearsalWidgetApp.rehearsal_one: the search has tries"

# The picture changes with every stop along the ruler.
expect picture(0) != picture(1)
expect picture(1) != picture(2)
expect picture(12) != picture(13)
