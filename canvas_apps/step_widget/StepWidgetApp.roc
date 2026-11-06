## The widget for the Safari tutorial's chapters on what's stored and on the
## stepped things. It holds a real Tour, and the lines of text read out the
## three fields of its current RideInstant. Dragging across the canvas sets a
## step to reach. Going forward the ride has to be played, a few steps a frame,
## so the dot lags the pointer. Going back it's a list lookup, so it barely does.
import game.Across
import game.Clock
import game.Distance
import game.Fraction
import game.Scenery
import game.Tour
import game.World
import lib.Brush
import lib.CanvasApp
import lib.Font
import lib.Input
import lib.Shapes
import lib.Trig
import widget.ScrubWidget

StepWidgetApp :: [].{

	## The whole state of the widget: the journey, the step it's heading for,
	## and how it last moved.
	Model : {
		tour : Tour,
		heading_for : Clock,
		last_move : [NotYet, Played, ReadBack],
	}

	canvas_app : CanvasApp.CanvasApp(StepWidgetApp.Model)
	canvas_app = {
		size: { width: ScrubWidget.canvas_width, height: ScrubWidget.canvas_height },
		fps: 60,
		init: { tour: Tour.initial, heading_for: Clock.start, last_move: NotYet },
		advance: |model, input, _seconds| moved(aimed(model, input)),
		frame: frame_at,
		sounds: |_model| 0,
		tones: [],
		title: "Three stored fields",
	}
}

## The ruler stops short of the cap on a Tour's history, so all of it can be
## read back.
clock_range : ScrubWidget.ClockRange
clock_range = {
	first_step: 0.0,
	last_step: 2000.0,
}

## How many steps of the ride are worked out in one frame of the widget.
played_a_frame : F64
played_a_frame = 8.0

## How many instants are taken back off the list in one frame of the widget.
read_back_a_frame : F64
read_back_a_frame = 200.0

## `model` with a pointer held down setting the step it's heading for.
aimed : StepWidgetApp.Model, Input.Snapshot -> StepWidgetApp.Model
aimed = |model, input|
	if input.mouse.button_down(Left) {
		share = ScrubWidget.share_under(input.mouse.position().x.to_f64())
		{ ..model, heading_for: ScrubWidget.clock_at(share, clock_range) }
	} else {
		model
	}

## `step_once` applied `count` times.
repeated : Tour, { count : F64, step_once : Tour -> Tour } -> Tour
repeated = |tour, { count, step_once }| {
	var $tour = tour
	var $left = count
	while $left > 0.0 {
		$tour = step_once($tour)
		$left = $left - 1.0
	}
	$tour
}

## `model` a frame on: closer to the step it's heading for, or left alone.
moved : StepWidgetApp.Model -> StepWidgetApp.Model
moved = |model| {
	now = model.tour.instant.clock.to_f64()
	wanted = model.heading_for.to_f64()
	if now < wanted {
		count = F64.min(played_a_frame, wanted - now)
		{
			..model,
			tour: repeated(model.tour, { count, step_once: Tour.step_forward }),
			last_move: Played,
		}
	} else if now > wanted {
		count = F64.min(read_back_a_frame, now - wanted)
		{
			..model,
			tour: repeated(model.tour, { count, step_once: Tour.step_back }),
			last_move: ReadBack,
		}
	} else {
		model
	}
}

## The part of the ruler the ride still has to play.
still_to_play : StepWidgetApp.Model -> List(ScrubWidget.Stretch)
still_to_play = |model| {
	now = model.tour.instant.clock.to_f64()
	wanted = model.heading_for.to_f64()
	if now < wanted {
		[
			{
				from: ScrubWidget.step_share(now, clock_range),
				to: ScrubWidget.step_share(wanted, clock_range),
			},
		]
	} else {
		[]
	}
}

## Everything on the canvas.
frame_at : StepWidgetApp.Model -> List(Shapes.Shape)
frame_at = |model|
	ScrubWidget.frame_shapes({
		picture: picture(model.tour),
		dot_at: ScrubWidget.step_share(model.tour.instant.clock.to_f64(), clock_range),
		marked: still_to_play(model),
		status: status_lines(model),
	})

ground_color : I64
ground_color = 0x6f9a55

road_color : I64
road_color = 0x4a4a46

rider_color : I64
rider_color = 0xf2efe4

truck_color : I64
truck_color = 0xd0603a

## The left end of the bar that stands for the whole route.
route_left_x : F64
route_left_x = 30.0

route_width : F64
route_width = 580.0

route_y : F64
route_y = 62.0

route_length : Distance
route_length = World.route_length(World.segments)

## Where `distance` along the route falls on the bar.
route_x : Distance -> F64
route_x = |distance| route_left_x + route_width * distance.ratio_to(route_length)

## How far along the route the rider of `tour` is.
rider_distance : Tour -> Distance
rider_distance = |tour| {
	rider = tour.instant.rider
	World.distance_along_route(tour.route, { index: rider.segment_index, along: rider.along })
}

ground : Shapes.Shape
ground = Rect({
	x: 0.0,
	y: 0.0,
	w: ScrubWidget.canvas_width,
	h: ScrubWidget.picture_bottom_y,
	fill: ScrubWidget.flat(ground_color),
})

## The route as a straight bar, with a mark where each segment ends.
route_bar : List(Shapes.Shape)
route_bar = {
	ends = World.segments.fold(
		{ reached: Distance.zero, marks: [] },
		|{ reached, marks }, segment| {
			end = reached.plus(segment.length)
			{ reached: end, marks: marks.append(route_x(end)) }
		},
	)
	[
		Rect({
			x: route_left_x,
			y: route_y - 4.0,
			w: route_width,
			h: 8.0,
			fill: ScrubWidget.flat(road_color),
		}),
	].concat(
		ends.marks.map(
			|x|
				Rect({
					x: x - 1.0,
					y: route_y - 8.0,
					w: 2.0,
					h: 16.0,
					fill: ScrubWidget.flat(road_color),
				}),
		),
	)
}

## A disc on the bar with its name above or below it.
marker : { at : Distance, color : I64, name : Str, name_y : F64 } -> List(Shapes.Shape)
marker = |{ at, color, name, name_y }|
	Font.text(
		name,
		route_x(at) - 16.0,
		name_y,
		12.0,
		Brush.opaque(0x202020),
	).prepend(
		Disc({
			x: route_x(at),
			y: route_y,
			r: 8.0,
			fill: ScrubWidget.flat(color),
			clip: Anywhere,
		}),
	)

## The road's surface in the view from behind the rider.
surface_y : F64
surface_y = 196.0

## How many pixels a metre across the road takes up, from behind.
pixels_a_metre : F64
pixels_a_metre = 56.0

## How tall the rider stands in that view.
rider_height : F64
rider_height = 74.0

## The rider's lean is too small to see true to size, so it's drawn at this
## many times the real angle.
lean_shown_at : F64
lean_shown_at = 3.0

## The road from behind, with the rider at `across`, leaning by `lean` radians.
from_behind : { across : Across, lean : F64 } -> List(Shapes.Shape)
from_behind = |{ across, lean }| {
	lane = Scenery.road_half_width.to_metres() * pixels_a_metre
	middle = ScrubWidget.canvas_width / 2.0
	foot = middle + across.to_metres() * pixels_a_metre
	head_x = foot + rider_height * Trig.r_sin(lean * lean_shown_at)
	head_y = surface_y - rider_height * Trig.r_cos(lean * lean_shown_at)
	[
		Font.text(
			"from behind, lean x3",
			20.0,
			surface_y - 22.0,
			10.0,
			Brush.opaque(0x202020),
		),
		[
			Rect({
				x: middle - lane,
				y: surface_y,
				w: 2.0 * lane,
				h: 8.0,
				fill: ScrubWidget.flat(road_color),
			}),
			Shapes.line(
				foot,
				surface_y,
				head_x,
				head_y,
				6.0,
				ScrubWidget.flat(rider_color),
			),
			Disc({
				x: head_x,
				y: head_y,
				r: 9.0,
				fill: ScrubWidget.flat(rider_color),
				clip: Anywhere,
			}),
		],
	].join()
}

## Where the rider and the truck are on the route, and the rider from behind.
picture : Tour -> List(Shapes.Shape)
picture = |tour| {
	rider = tour.instant.rider
	truck = tour.instant.truck
	[
		[ground],
		route_bar,
		marker({
			at: truck.route_position,
			color: truck_color,
			name: "truck",
			name_y: route_y - 28.0,
		}),
		marker({
			at: rider_distance(tour),
			color: rider_color,
			name: "rider",
			name_y: route_y + 16.0,
		}),
		from_behind({ across: rider.across, lean: rider.lean.to_radians() }),
	].join()
}

## The brake lights in words.
brakes_text : [On, Off] -> Str
brakes_text = |lights|
	match lights {
		On => "On"
		Off => "Off"
	}

## How the ride last moved, in words.
move_text : StepWidgetApp.Model -> Str
move_text = |model|
	match model.last_move {
		NotYet => "Drag right to play, left to go back"
		Played => "Played on, one step at a time"
		ReadBack => "Read back: ${model.tour.past_instants.len().to_str()} instants kept"
	}

## The three stored fields, and how they got there.
status_lines : StepWidgetApp.Model -> List(Str)
status_lines = |model| {
	rider = model.tour.instant.rider
	truck = model.tour.instant.truck
	clock = model.tour.instant.clock
	[
		"clock: step ${clock.to_str()}",
		"rider: segment ${(rider.segment_index.to_u32() + 1).to_str()}, ${ScrubWidget.tenths_text(rider.along.to_metres())} m, speed ${ScrubWidget.tenths_text(rider.speed.to_metres_a_step())}",
		"truck: ${ScrubWidget.tenths_text(truck.route_position.to_metres())} m, speed ${ScrubWidget.tenths_text(truck.speed.to_metres_a_step())}, brake ${brakes_text(truck.brake_lights)}",
		move_text(model),
	]
}

## The widget as it starts, heading for `step`.
heading_for_step : U32 -> StepWidgetApp.Model
heading_for_step = |step| {
	tour: Tour.initial,
	heading_for: Clock.at_step(step),
	last_move: NotYet,
}

## `model` after `frames` frames with nobody touching it.
left_alone : StepWidgetApp.Model, U64 -> StepWidgetApp.Model
left_alone = |model, frames| {
	var $model = model
	var $left = frames
	while $left > 0 {
		$model = moved($model)
		$left = $left - 1
	}
	$model
}

clock_of : StepWidgetApp.Model -> F64
clock_of = |model| model.tour.instant.clock.to_f64()

# Going forward, a frame plays a few steps and no more than it takes.
expect clock_of(moved(heading_for_step(100))) == played_a_frame
expect clock_of(moved(heading_for_step(3))) == 3.0
expect clock_of(left_alone(heading_for_step(20), 10)) == 20.0

# A model at the step it's heading for doesn't move.
expect clock_of(moved(heading_for_step(0))) == 0.0
expect moved(heading_for_step(0)).last_move == NotYet

# Going back, one frame covers far more than a frame of playing does.
expect {
	played = left_alone(heading_for_step(300), 40)
	back = moved({ ..played, heading_for: Clock.at_step(100) })
	clock_of(played) == 300.0 and clock_of(back) == 100.0 and back.last_move == ReadBack
}

# Going back lands on the very instant the ride passed through.
expect {
	on_the_way = left_alone(heading_for_step(16), 2)
	past_it = left_alone({ ..on_the_way, heading_for: Clock.at_step(40) }, 3)
	back = moved({ ..past_it, heading_for: Clock.at_step(16) })
	back.tour.instant.rider.along == on_the_way.tour.instant.rider.along
		and back.tour.instant.rider.speed == on_the_way.tour.instant.rider.speed
}

# Only the stretch ahead of the ride is marked.
expect still_to_play(heading_for_step(1000)).len() == 1
expect still_to_play(heading_for_step(0)).len() == 0
expect still_to_play(left_alone(heading_for_step(16), 2)).len() == 0

expect route_x(Distance.zero) == route_left_x
expect route_x(route_length) == route_left_x + route_width

expect brakes_text(On) == "On"
expect brakes_text(Off) == "Off"

expect
	status_lines(heading_for_step(0))
		== [
			"clock: step 0",
			"rider: segment 1, 0.0 m, speed 0.3",
			"truck: 500.0 m, speed 0.3, brake Off",
			"Drag right to play, left to go back",
		]
