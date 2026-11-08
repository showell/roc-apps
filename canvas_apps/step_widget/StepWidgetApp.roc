## The widget for the Safari tutorial's chapters on what's stored and on the
## stepped things. It holds a real Tour, and the lines of text read out three of
## the four fields of its current RideInstant. Video recorder buttons set a step
## to reach. Going forward the ride has to be played, a few steps a frame, so the
## end takes a while to reach. Going back it's a list lookup, so the start
## doesn't.
import game.Across
import game.Angle
import game.Clock
import game.Distance
import game.Geom
import game.RideInstant
import game.Steps
import game.Tour
import game.TruckBrakeLights
import game.World
import lib.Brush
import lib.CanvasApp
import lib.Input
import lib.Shapes
import lib.RgbColor
import widget.ReadoutText
import widget.WidgetPage
import widget.WidgetPalette
import widget.VcrButtons

StepWidgetApp :: [].{

	## The whole state of the widget: the tour, the buttons, which hold the
	## step it's heading for, and how it last moved.
	Model : {
		tour : Tour,
		transport : VcrButtons.Transport(Clock),
		last_move : [NotYet, Played, ReadBack],
	}

	canvas_app : CanvasApp.CanvasApp(StepWidgetApp.Model)
	canvas_app = WidgetPage.canvas_app({
		frames_a_second: WidgetPage.moving_frames_a_second,
		title: "Three stored fields",
		init: heading_for_step(0),
		model_at_next_step: |model, input| move_tour(aim_transport(model, input)),
		frame_shapes: shapes_at,
	})
}

## How many steps of the ride are worked out in one frame of the widget.
steps_a_frame : Steps
steps_a_frame = Steps.of(8)

## The steps the buttons reach. Play goes as fast as the ride can be worked out.
step_range : VcrButtons.NumberRange(Clock)
step_range = VcrButtons.clock_range({
	first_step: 0,
	last_step: step_range_end,
	steps_a_frame: steps_a_frame.to_f64(),
})

## Where the range ends: a round 2000 steps, which is far enough along the bar
## to see the rider and the truck move, and near enough that To the end, which
## has to play every step, gets there in about four seconds.
step_range_end : U32
step_range_end = 2000

## How many instants are taken back off the list in one frame of the widget.
read_back_a_frame : Steps
read_back_a_frame = Steps.of(200)

## `model` with its buttons setting the step it's heading for. A press counts from
## where the ride is, which may not have reached the step it was heading for.
aim_transport : StepWidgetApp.Model, Input.Snapshot -> StepWidgetApp.Model
aim_transport = |model, input| {
	caught_up = VcrButtons.catch_up(model.transport, { input, shown: model.tour.instant().clock })
	{ ..model, transport: VcrButtons.next_transport(caught_up, { input, range: step_range }) }
}

## `model` a frame on: closer to the step it's heading for, or left alone.
move_tour : StepWidgetApp.Model -> StepWidgetApp.Model
move_tour = |model| {
	now = model.tour.instant().clock
	wanted = model.transport.at
	if now < wanted {
		length = steps_a_frame.min(wanted.steps_since(now))
		{
			..model,
			tour: model.tour.steps_forward(length),
			last_move: Played,
		}
	} else if wanted < now {
		length = read_back_a_frame.min(now.steps_since(wanted))
		{
			..model,
			tour: model.tour.steps_back(length),
			last_move: ReadBack,
		}
	} else {
		model
	}
}

## Everything on the canvas.
shapes_at : StepWidgetApp.Model -> List(Shapes.Shape)
shapes_at = |model|
	VcrButtons.frame_shapes(
		model.transport,
		{
			range: step_range,
			picture_shapes: picture_shapes(model.tour),
			status_lines: status_lines(model),
		},
	)

rider_color : RgbColor
rider_color = WidgetPalette.highlight_color

truck_color : RgbColor
truck_color = WidgetPalette.accent_color

## The left end of the bar that stands for the whole route.
route_left_x : F64
route_left_x = 30.0

route_width : F64
route_width = 580.0

route_y : F64
route_y = 62.0

route_length : Distance
route_length = World.route.route_length()

## Where `distance` along the route falls on the bar.
route_x : Distance -> F64
route_x = |distance| route_left_x + route_width * distance.ratio_to(route_length)

## The route as a straight bar, with a mark where each segment ends.
bar_shapes : List(Shapes.Shape)
bar_shapes =
	[
		Rect({
			x: route_left_x,
			y: route_y - 4.0,
			width: route_width,
			height: 8.0,
			fill: Brush.flat(WidgetPalette.plan_road_color),
		}),
	].concat(
		World.route.segments_with_ends().map(
			|stretch|
				Rect({
					x: route_x(stretch.end) - 1.0,
					y: route_y - 8.0,
					width: 2.0,
					height: 16.0,
					fill: Brush.flat(WidgetPalette.plan_road_color),
				}),
		),
	)

## A disc on the bar with its name above or below it.
marker_shapes : {
	at : Distance,
	color : RgbColor,
	name : Str,
	name_y : F64,
} -> List(Shapes.Shape)
marker_shapes = |{ at, color, name, name_y }|
	[
		Disc({
			x: route_x(at),
			y: route_y,
			radius: 8.0,
			fill: Brush.flat(color),
		}),
		WidgetPage.label({
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

## The road from behind, with the rider at `across`, leaning by `lean`.
shapes_from_behind_rider : { across : Across, lean : Angle.Lean } -> List(Shapes.Shape)
shapes_from_behind_rider = |{ across, lean }| {
	road_half_width_on_canvas = Geom.road_half_width.to_metres() * pixels_a_metre
	middle = WidgetPage.canvas_width / 2.0
	foot = middle + across.to_metres() * pixels_a_metre
	lean_shown = lean.to_radians() * lean_shown_at
	head_x = foot + rider_height * lean_shown.sin()
	head_y = surface_y - rider_height * lean_shown.cos()
	[
		[
			WidgetPage.label({
				text: "from behind, lean x${ReadoutText.whole_text(lean_shown_at)}",
				x: 20.0,
				y: surface_y - 12.0,
			}),
		],
		[
			Rect({
				x: middle - road_half_width_on_canvas,
				y: surface_y,
				width: 2.0 * road_half_width_on_canvas,
				height: 8.0,
				fill: Brush.flat(WidgetPalette.plan_road_color),
			}),
			Shapes.line(
				{
					from: { x: foot, y: surface_y },
					to: { x: head_x, y: head_y },
					width: 6.0,
				},
				Brush.flat(rider_color),
			),
			Disc({
				x: head_x,
				y: head_y,
				radius: 9.0,
				fill: Brush.flat(rider_color),
			}),
		],
	].join()
}

## Where the rider and the truck are on the route, and the rider from behind.
picture_shapes : Tour -> List(Shapes.Shape)
picture_shapes = |tour| {
	rider = tour.instant().rider
	truck = tour.instant().truck
	[
		[WidgetPage.picture_backdrop(WidgetPalette.plan_ground_color)],
		bar_shapes,
		marker_shapes({
			at: truck.route_position,
			color: truck_color,
			name: "truck",
			name_y: route_y - 28.0,
		}),
		marker_shapes({
			at: RideInstant.rider_distance(tour.route(), tour.instant()),
			color: rider_color,
			name: "rider",
			name_y: route_y + 16.0,
		}),
		shapes_from_behind_rider({
			across: rider.motorcycle.route_place.road_point.across,
			lean: rider.motorcycle.lean,
		}),
	].join()
}

## How the ride last moved, in words.
move_text : StepWidgetApp.Model -> Str
move_text = |model|
	match model.last_move {
		NotYet => "Play it forward, then go back"
		Played => "Played on, one step at a time"
		ReadBack => "Read back: ${model.tour.past_instant_count().to_str()} instants kept"
	}

## The three stored fields, and how they got there.
status_lines : StepWidgetApp.Model -> List(Str)
status_lines = |model| {
	rider = model.tour.instant().rider
	truck = model.tour.instant().truck
	clock = model.tour.instant().clock
	rider_place = rider.motorcycle.route_place
	rider_segment = (rider_place.segment_index.to_u32() + 1).to_str()
	rider_along = ReadoutText.tenths_text(rider_place.road_point.along.to_metres())
	rider_speed = ReadoutText.tenths_text(rider.motorcycle.speed.to_metres_a_step())
	truck_along = ReadoutText.tenths_text(truck.route_position.to_metres())
	truck_speed = ReadoutText.tenths_text(truck.speed.to_metres_a_step())
	brake_lights =
		match TruckBrakeLights.at(truck.pace) {
			On => "On"
			Off => "Off"
		}
	[
		"clock: step ${clock.to_str()}",
		"rider: segment ${rider_segment}, ${rider_along} m, speed ${rider_speed}",
		"truck: ${truck_along} m, speed ${truck_speed}, brake ${brake_lights}",
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
head_for_step : StepWidgetApp.Model, U32 -> StepWidgetApp.Model
head_for_step = |model, step| { ..model, transport: VcrButtons.transport_at(Clock.at_step(step)) }

## A frame of `model` with a press of `control`.
pressed_on : StepWidgetApp.Model, VcrButtons.Control -> StepWidgetApp.Model
pressed_on = |model, control| move_tour(aim_transport(model, VcrButtons.click_on(control)))

## `model` after `frames` frames with nobody touching it.
left_alone : StepWidgetApp.Model, U64 -> StepWidgetApp.Model
left_alone = |model, frames| {
	var $model = model
	var $left = frames
	while $left > 0 {
		$model = move_tour($model)
		$left = $left - 1
	}
	$model
}

steps_in : StepWidgetApp.Model -> F64
steps_in = |model| model.tour.instant().clock.steps_since(Clock.start).to_f64()

# Going forward, a frame plays a few steps and no more than it takes.
expect steps_in(move_tour(heading_for_step(100))) == steps_a_frame.to_f64()
expect steps_in(move_tour(heading_for_step(3))) == 3.0
expect steps_in(left_alone(heading_for_step(20), 10)) == 20.0

# A model at the step it's heading for doesn't move.
expect steps_in(move_tour(heading_for_step(0))) == 0.0
expect move_tour(heading_for_step(0)).last_move == NotYet

# Going back, one frame covers far more than a frame of playing does.
expect {
	played = left_alone(heading_for_step(300), 40)
	back = move_tour(head_for_step(played, 100))
	steps_in(played) == 300.0 and steps_in(back) == 100.0 and back.last_move == ReadBack
}

# Going back lands on the very instant the ride passed through.
expect {
	on_the_way = left_alone(heading_for_step(16), 2)
	past_it = left_alone(head_for_step(on_the_way, 40), 3)
	back = move_tour(head_for_step(past_it, 16))
	back_motorcycle = back.tour.instant().rider.motorcycle
	on_the_way_motorcycle = on_the_way.tour.instant().rider.motorcycle
	back_along = back_motorcycle.route_place.road_point.along
	back_along == on_the_way_motorcycle.route_place.road_point.along
		and back_motorcycle.speed == on_the_way_motorcycle.speed
}

# Play keeps pace with the ride, and pausing leaves the ride where it is.
expect steps_in(pressed_on(heading_for_step(0), Play)) == steps_a_frame.to_f64()
expect {
	playing = pressed_on(heading_for_step(0), Play)
	on = move_tour(aim_transport(playing, Input.none))
	paused = pressed_on(on, Play)
	steps_in(on) == 2.0 * steps_a_frame.to_f64()
		and steps_in(paused) == steps_in(on)
		and paused.transport.motion == Stopped
}

# A step moves the ride exactly one, either way.
expect steps_in(pressed_on(heading_for_step(0), StepForward)) == 1.0
expect {
	played = left_alone(heading_for_step(40), 5)
	stepped = pressed_on(played, StepBack)
	steps_in(stepped) == 39.0 and stepped.last_move == ReadBack
}

# To the end has to play there, and to the start reads back almost at once.
expect steps_in(pressed_on(heading_for_step(0), ToEnd)) == steps_a_frame.to_f64()
expect pressed_on(heading_for_step(0), ToEnd).transport.at == step_range.last
expect {
	played = left_alone(heading_for_step(300), 40)
	steps_in(pressed_on(played, ToStart)) == 100.0
}

# A step while the ride is playing up to the end stops it where it is.
expect {
	chasing = pressed_on(heading_for_step(0), ToEnd)
	stepped = pressed_on(chasing, StepBack)
	steps_in(stepped) == steps_a_frame.to_f64() - 1.0 and stepped.transport.at == Clock.at_step(7)
}

expect route_x(Distance.zero) == route_left_x
expect route_x(route_length) == route_left_x + route_width

# The lines read the clock, the rider and how the ride last moved. The truck's
# line, between them, reads the truck's own numbers.
expect {
	lines = status_lines(heading_for_step(0))
	[lines.take_first(2), lines.drop_first(3)].join()
		== ["clock: step 0", "rider: segment 1, 0.0 m, speed 0.3", "Play it forward, then go back"]
}
