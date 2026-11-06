## The widget for the Safari tutorial's chapters on what's stored and on the
## stepped things. It holds a real Tour, and the lines of text read out the
## three fields of its current RideInstant. Video recorder buttons set a step to
## reach. Going forward the ride has to be played, a few steps a frame, so the end
## takes a while to reach. Going back it's a list lookup, so the start doesn't.
import game.Across
import game.Clock
import game.Distance
import game.Scenery
import game.Tour
import game.World
import lib.CanvasApp
import lib.Input
import lib.Shapes
import widget.ScrubWidget
import widget.VcrButtons

StepWidgetApp :: [].{

	## The whole state of the widget: the journey, the buttons, which hold the
	## step it's heading for, and how it last moved.
	Model : {
		tour : Tour,
		transport : VcrButtons.Transport(Clock),
		last_move : [NotYet, Played, ReadBack],
	}

	canvas_app : CanvasApp.CanvasApp(StepWidgetApp.Model)
	canvas_app = ScrubWidget.canvas_app({
		title: "Three stored fields",
		init: heading_for_step(0),
		advance: |model, input| moved(aimed(model, input)),
		frame: frame_at,
	})
}

## How many steps of the ride are worked out in one frame of the widget.
played_a_frame : F64
played_a_frame = 8.0

## The range stops short of the cap on a Tour's history, so all of it can be read
## back. Play goes as fast as the ride can be worked out.
journey : VcrButtons.NumberRange(Clock)
journey = VcrButtons.clock_range({
	first_step: 0,
	last_step: 2000,
	steps_a_frame: played_a_frame,
})

## How many instants are taken back off the list in one frame of the widget.
read_back_a_frame : F64
read_back_a_frame = 200.0

## `model` with its buttons setting the step it's heading for. A press counts from
## where the ride is, which may not have reached the step it was heading for.
aimed : StepWidgetApp.Model, Input.Snapshot -> StepWidgetApp.Model
aimed = |model, input| {
	caught_up = VcrButtons.catch_up(
		model.transport,
		{ input, range: journey, shown: model.tour.instant.clock },
	)
	{ ..model, transport: VcrButtons.next_transport(caught_up, { input, range: journey }) }
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
	wanted = model.transport.at.to_f64()
	if now < wanted {
		count = played_a_frame.min(wanted - now)
		{
			..model,
			tour: repeated(model.tour, { count, step_once: Tour.step_forward }),
			last_move: Played,
		}
	} else if now > wanted {
		count = read_back_a_frame.min(now - wanted)
		{
			..model,
			tour: repeated(model.tour, { count, step_once: Tour.step_back }),
			last_move: ReadBack,
		}
	} else {
		model
	}
}

## Everything on the canvas.
frame_at : StepWidgetApp.Model -> List(Shapes.Shape)
frame_at = |model|
	VcrButtons.frame_shapes(
		model.transport,
		{
			range: journey,
			picture: picture(model.tour),
			status: status_lines(model),
		},
	)

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
marker : {
	at : Distance,
	color : I64,
	name : Str,
	name_y : F64,
} -> List(Shapes.Shape)
marker = |{ at, color, name, name_y }|
	[
		Disc({
			x: route_x(at),
			y: route_y,
			r: 8.0,
			fill: ScrubWidget.flat(color),
			clip: Anywhere,
		}),
		ScrubWidget.label({
			text: name,
			x: route_x(at) - 16.0,
			y: name_y + 12.0,
		}),
	]

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
	road = Scenery.road_half_width.to_metres() * pixels_a_metre
	middle = ScrubWidget.canvas_width / 2.0
	foot = middle + across.to_metres() * pixels_a_metre
	head_x = foot + rider_height * (lean * lean_shown_at).sin()
	head_y = surface_y - rider_height * (lean * lean_shown_at).cos()
	[
		[
			ScrubWidget.label({
				text: "from behind, lean x3",
				x: 20.0,
				y: surface_y - 12.0,
			}),
		],
		[
			Rect({
				x: middle - road,
				y: surface_y,
				w: 2.0 * road,
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
		NotYet => "Play it forward, then go back"
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
	transport: VcrButtons.transport_at(Clock.at_step(step)),
	last_move: NotYet,
}

## `model` heading for `step` instead.
heading_on_to : StepWidgetApp.Model, U32 -> StepWidgetApp.Model
heading_on_to = |model, step| { ..model, transport: VcrButtons.transport_at(Clock.at_step(step)) }

## A frame of `model` with a press of `control`.
pressed_on : StepWidgetApp.Model, VcrButtons.Control -> StepWidgetApp.Model
pressed_on = |model, control| moved(aimed(model, VcrButtons.click_on(control, journey.playing)))

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
	back = moved(heading_on_to(played, 100))
	clock_of(played) == 300.0 and clock_of(back) == 100.0 and back.last_move == ReadBack
}

# Going back lands on the very instant the ride passed through.
expect {
	on_the_way = left_alone(heading_for_step(16), 2)
	past_it = left_alone(heading_on_to(on_the_way, 40), 3)
	back = moved(heading_on_to(past_it, 16))
	back.tour.instant.rider.along == on_the_way.tour.instant.rider.along
		and back.tour.instant.rider.speed == on_the_way.tour.instant.rider.speed
}

# Play keeps pace with the ride, and pausing leaves the ride where it is.
expect clock_of(pressed_on(heading_for_step(0), Play)) == played_a_frame
expect {
	playing = pressed_on(heading_for_step(0), Play)
	on = moved(aimed(playing, Input.none))
	paused = pressed_on(on, Play)
	clock_of(on) == 2.0 * played_a_frame
		and clock_of(paused) == clock_of(on)
		and paused.transport.motion == Stopped
}

# A step moves the ride exactly one, either way.
expect clock_of(pressed_on(heading_for_step(0), StepForward)) == 1.0
expect {
	played = left_alone(heading_for_step(40), 5)
	stepped = pressed_on(played, StepBack)
	clock_of(stepped) == 39.0 and stepped.last_move == ReadBack
}

# To the end has to play there, and to the start reads back almost at once.
expect clock_of(pressed_on(heading_for_step(0), ToEnd)) == played_a_frame
expect pressed_on(heading_for_step(0), ToEnd).transport.at == journey.last
expect {
	played = left_alone(heading_for_step(300), 40)
	clock_of(pressed_on(played, ToStart)) == 100.0
}

# A step while the ride is playing up to the end stops it where it is.
expect {
	chasing = pressed_on(heading_for_step(0), ToEnd)
	stepped = pressed_on(chasing, StepBack)
	clock_of(stepped) == played_a_frame - 1.0 and stepped.transport.at == Clock.at_step(7)
}

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
			"Play it forward, then go back",
		]
