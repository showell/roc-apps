## The widget for the Safari tutorial's chapter on the rider's gaze. It rides the
## stretch around the first pig that catches the rider's eye, with the real
## Rider, a few steps a frame, and keeps every state it reaches. Video recorder
## buttons pick one of those states, so the look plays forward and backward. The
## picture looks down on the road, with both directions to one scale, so the sight
## line's angle is the real one. Below it, the buttons and the text that reads out
## that step's state.
import game.Across
import game.Along
import game.Angle
import game.Billboard
import game.Clock
import game.Gawking
import game.Gaze
import game.Geom
import game.Rider
import game.RiderMind
import game.Segment
import game.Steps
import game.Tour
import game.World
import lib.Brush
import lib.CanvasApp
import lib.Input
import lib.Shapes
import lib.RgbColor
import lib.Pixels
import lib.Point
import widget.PlanView
import widget.ReadoutText
import widget.WidgetPage
import widget.WidgetPalette
import widget.VcrButtons

GazeWidgetApp :: [].{

	## The whole state of the widget: the states of the stretch played so far,
	## first step first, and the buttons, which hold the step asked for.
	Model : { played : List(Rider), transport : VcrButtons.Transport(Clock) }

	canvas_app : CanvasApp.CanvasApp(GazeWidgetApp.Model)
	canvas_app = WidgetPage.canvas_app({
		frames_a_second: WidgetPage.moving_frames_a_second,
		title: "The rider's gaze",
		init: starting_model,
		model_at_next_step: |model, input| played_on(with_buttons(model, input)),
		frame_shapes: shapes_at,
	})
}

## What the rider is doing about the pig at one step.
GazePhase : [EyesOnRoad, LookingAtPig, TurningBack, EyesBack]

## The first step on show, with the pig still too far off to notice.
first_step : U32
first_step = 860

## The last step on show, a little after the gaze is back on the road.
last_step : U32
last_step = 1320

## The steps of the look, from its first to the first without it.
## gates/expects/RiderExpects.roc holds them to the ride.
look_first_step : U32
look_first_step = 885

look_end_step : U32
look_end_step = 1050

## The first step with the gaze back straight ahead after the look.
eyes_back_step : U32
eyes_back_step = 1224

## The whole stretch, in about eight seconds.
stretch : VcrButtons.NumberRange(Clock)
stretch = VcrButtons.clock_range({ first_step, last_step, steps_a_frame: 1.0 })

## How many states the whole stretch holds.
stretch_length : U64
stretch_length = (last_step - first_step + 1).to_u64()

## How many steps of the ride are worked out in one frame of the widget, which
## plays the whole stretch in about a second.
played_a_frame : U64
played_a_frame = 8

## The rider at `first_step`, the ride's own.
first_rider : Rider
first_rider = Tour.at_step(Clock.at_step(first_step)).instant().rider

starting_model : GazeWidgetApp.Model
starting_model = { played: [first_rider], transport: VcrButtons.transport_at(stretch.first) }

## The first segment of the route whose pigs catch the rider's eye.
pig_segment : Segment
pig_segment = World.first_distracting_segment

## The pig that catches the rider's eye.
gaze_pig : Geom.Placed(Billboard)
gaze_pig =
	match Gaze.eye_catching_pig(pig_segment) {
		CatchesEye(pig) => pig
		NoPigCatchesEye => crash "GazeWidgetApp.gaze_pig: this segment's pigs catch the eye"
	}

## `model` after a frame of its buttons. A press counts from the step on show,
## which the ride may not have reached the one asked for.
with_buttons : GazeWidgetApp.Model, Input.Snapshot -> GazeWidgetApp.Model
with_buttons = |model, input| {
	caught_up = VcrButtons.catch_up(model.transport, { input, shown: shown_clock(model) })
	{ ..model, transport: VcrButtons.next_transport(caught_up, { input, range: stretch }) }
}

## `model` a frame on, with a few more steps played until the stretch is. The
## encounter on the stretch's segment asks nothing of the rider, so it is left
## unplanned; an `expect` below holds the stretch to the ride.
played_on : GazeWidgetApp.Model -> GazeWidgetApp.Model
played_on = |model| {
	reach = stretch_length.min(model.played.len() + played_a_frame)
	var $played = model.played
	while $played.len() < reach {
		latest = $played.last() ?? crash "GazeWidgetApp.played_on: the stretch starts with a state"
		next = latest.rider_at_next_step({ route: World.route, encounter_stage: Waiting })
		$played = $played.append(next)
	}
	{ ..model, played: $played }
}

## How far into the stretch the state on show is: where the buttons asked for, or
## the last step played if the ride hasn't got there yet.
shown_offset : GazeWidgetApp.Model -> U64
shown_offset = |model| {
	asked_for = model.transport.at.steps_since(Clock.at_step(first_step)).to_u32().to_u64()
	asked_for.min(model.played.len() - 1)
}

## The ride's clock at the state on show.
shown_clock : GazeWidgetApp.Model -> Clock
shown_clock = |model| Clock.at_step(first_step).plus(Steps.of(shown_offset(model).to_u32_wrap()))

rider_at : List(Rider), U64 -> Rider
rider_at = |played, offset|
	played.get(offset) ?? crash "GazeWidgetApp.rider_at: offsets stay within what's played"

## What the rider is doing about the pig in `rider`'s state.
phase_of : Rider -> GazePhase
phase_of = |rider|
	if !Gawking.is_gawking(rider.motorcycle, pig_segment) {
		EyesOnRoad
	} else {
		match RiderMind.gaze_target(rider.motorcycle, pig_segment) {
			OnPig(_) => LookingAtPig
			OnRoad if rider.eyes.gaze_yaw == Angle.straight_ahead => EyesBack
			OnRoad => TurningBack
		}
	}

## Everything on the canvas.
shapes_at : GazeWidgetApp.Model -> List(Shapes.Shape)
shapes_at = |model| {
	rider = rider_at(model.played, shown_offset(model))
	VcrButtons.frame_shapes(
		model.transport,
		{
			range: stretch,
			picture_shapes: picture_shapes(rider),
			status_lines: status_lines(rider, shown_clock(model)),
		},
	)
}

herd_color : RgbColor
herd_color = RgbColor.of(0xe9b7b0)

## Where the canvas's left edge is along the segment, in metres.
left_edge_metres : F64
left_edge_metres = 130.0

## The road from above, with the canvas's left edge at `left_edge_metres` along
## the segment, the road's middle a little below the top of the picture, and
## both directions to one scale.
road_plan : PlanView
road_plan = { origin: Point.at(0.0, 52.0), pixels_a_metre: 2.4 }

## Where a point on the segment falls on the canvas. The road runs left to right,
## so the rider's right is down the canvas.
canvas_point : { along : Along, across : Across } -> Point.Point
canvas_point = |{ along, across }|
	road_plan.canvas_point({
		metres_right: along.to_metres() - left_edge_metres,
		metres_down: across.to_metres(),
	})

road : Shapes.Shape
road = {
	half_width = Geom.road_half_width.to_metres() * road_plan.pixels_a_metre
	Shapes.rectangle({
		top_left: Point.at(0.0, road_plan.origin.y.to_f64() - half_width),
		width: Pixels.of(WidgetPage.canvas_width),
		height: Pixels.of(2.0 * half_width),
		fill: Brush.flat(WidgetPalette.plan_road_color),
	})
}

## A disc on the road's plan, of radius `radius` and in `color`.
plan_disc : {
	along : Along,
	across : Across,
	radius : F64,
	color : RgbColor,
} -> Shapes.Shape
plan_disc = |{ along, across, radius, color }| {
	on_canvas = canvas_point({ along, across })
	x = on_canvas.x.to_f64()
	y = on_canvas.y.to_f64()
	Disc({
		center: Point.at(x, y),
		radius: Pixels.of(radius),
		fill: Brush.flat(color),
	})
}

## One pig of the herd, the one that catches the eye drawn larger.
pig_disc : Geom.Placed(Billboard) -> Shapes.Shape
pig_disc = |pig|
	if pig == gaze_pig {
		plan_disc({
			along: pig.road_point.along,
			across: pig.road_point.across,
			radius: 6.0,
			color: WidgetPalette.accent_color,
		})
	} else {
		plan_disc({
			along: pig.road_point.along,
			across: pig.road_point.across,
			radius: 3.0,
			color: herd_color,
		})
	}

## The segment's whole herd, and the name of the pig that catches the eye.
pigs : List(Shapes.Shape)
pigs = {
	pig_on_canvas = canvas_point(gaze_pig.road_point)
	pig_segment.segment_pigs()
		.map(pig_disc)
		.append(
			WidgetPage.label({
				text: "the pig",
				x: pig_on_canvas.x.to_f64() - 62.0,
				y: pig_on_canvas.y.to_f64() + 20.0,
			}),
		)
}

## The way the rider looks: as far as a pig can catch the eye, turned from the
## road by the bike's yaw and the rider's gaze.
sight_line : Rider -> Shapes.Shape
sight_line = |rider| {
	on_canvas = canvas_point(rider.motorcycle.route_place.road_point)
	x = on_canvas.x.to_f64()
	y = on_canvas.y.to_f64()
	turn = rider.motorcycle.yaw.plus(rider.eyes.gaze_yaw).to_radians()
	reach = Gaze.notice_distance.to_metres() * road_plan.pixels_a_metre
	Shapes.line(
		{
			from: Point.at(x, y),
			to: Point.at(x + reach * turn.cos(), y + reach * turn.sin()),
			width: Pixels.of(2.0),
		},
		Brush.flat(WidgetPalette.aim_color),
	)
}

## The road from above, with the pigs, the rider and the rider's sight line.
picture_shapes : Rider -> List(Shapes.Shape)
picture_shapes = |rider|
	[
		[WidgetPage.picture_backdrop(WidgetPalette.plan_ground_color), road],
		pigs,
		[
			sight_line(rider),
			plan_disc({
				along: rider.motorcycle.route_place.road_point.along,
				across: rider.motorcycle.route_place.road_point.across,
				radius: 5.0,
				color: WidgetPalette.highlight_color,
			}),
		],
	].join()

## What the rider is doing, in words.
phase_text : GazePhase -> Str
phase_text = |phase|
	match phase {
		EyesOnRoad => "Eyes on the road"
		LookingAtPig => "Looking at the pig, and slowing"
		TurningBack => "Too far round: the gaze turns back"
		EyesBack => "Eyes back on the road, still slow"
	}

## How far the rider looks from the way the bike points, in degrees. A pig on the
## right turns the gaze right, so on this stretch it's never negative.
gaze_degrees : Rider -> F64
gaze_degrees = |rider| rider.eyes.gaze_yaw.to_degrees()

## The state at `clock`, a line each.
status_lines : Rider, Clock -> List(Str)
status_lines = |rider, clock|
	[
		phase_text(phase_of(rider)),
		"Step ${clock.to_str()}: speed ${ReadoutText.tenths_text(rider.motorcycle.speed.to_metres_a_step())} m a step",
		"Gaze yaw: ${ReadoutText.tenths_text(gaze_degrees(rider))} degrees",
		"Look depth: ${ReadoutText.percent_text(rider.eyes.look_depth)}",
	]

## The whole stretch, played, for the expects. As a constant it's ridden once, at
## compile time, which adds under half a second to a check.
stretch_states : List(Rider)
stretch_states = {
	var $model = starting_model
	while $model.played.len() < stretch_length {
		$model = played_on($model)
	}
	$model.played
}

## The state at `step` of a played stretch.
state_at_step : List(Rider), U32 -> Rider
state_at_step = |played, step| rider_at(played, (step - first_step).to_u64())

# This stretch is on the route's first distracting segment, and with its
# encounter unplanned it still ends where the ride does.
expect
	World.route.segment_at(first_rider.motorcycle.route_place.segment_index).has_distracting_pigs()
expect {
	played = state_at_step(stretch_states, last_step)
	ridden = Tour.at_step(Clock.at_step(last_step)).instant().rider
	played_place = played.motorcycle.route_place
	ridden_place = ridden.motorcycle.route_place
	played_place.segment_index == ridden_place.segment_index
		and played_place.road_point.along.to_metres() == ridden_place.road_point.along.to_metres()
		and played.motorcycle.speed.to_metres_a_step() == ridden.motorcycle.speed.to_metres_a_step()
		and played.eyes.gaze_yaw == ridden.eyes.gaze_yaw
		and played.eyes.look_depth.to_f64() == ridden.eyes.look_depth.to_f64()
}
expect World.route.route_segments().take_first(2).all(|segment| segment.pigs == NoPigs)

# Each of the four phases shows on the stretch, at the steps above.
# gates/expects/RiderExpects.roc holds where each starts on the ride.
expect
	[
		(first_step, EyesOnRoad),
		(look_first_step, LookingAtPig),
		(look_end_step, TurningBack),
		(eyes_back_step, EyesBack),
	].all(|(step, phase)| phase_of(state_at_step(stretch_states, step)) == phase)

# The gaze never turns left on this stretch, as `gaze_degrees` says.
expect stretch_states.all(|rider| gaze_degrees(rider) >= 0.0)

# The whole stretch stays on the canvas, and on the one segment.
expect
	stretch_states.all(
		|rider| {
			place = rider.motorcycle.route_place
			canvas_x = canvas_point(place.road_point).x.to_f64()
			place.segment_index == first_rider.motorcycle.route_place.segment_index
				and canvas_x > 0.0
				and canvas_x < WidgetPage.canvas_width
		},
	)

## A model at its start, asking for `step`.
asking_for : U32 -> GazeWidgetApp.Model
asking_for = |step| { ..starting_model, transport: VcrButtons.transport_at(Clock.at_step(step)) }

## `model` after `frames` frames with nobody touching it.
left_alone : GazeWidgetApp.Model, U64 -> GazeWidgetApp.Model
left_alone = |model, frames| {
	var $model = model
	var $left = frames
	while $left > 0 {
		$model = played_on($model)
		$left = $left - 1
	}
	$model
}

# A frame plays a few steps, and playing stops at the end of the stretch.
expect played_on(starting_model).played.len() == 1 + played_a_frame
expect left_alone(starting_model, 2).played.len() == 1 + 2 * played_a_frame
expect left_alone(starting_model, 57).played.len() == 1 + 57 * played_a_frame
expect left_alone(starting_model, 58).played.len() == stretch_length
expect left_alone(starting_model, 59).played.len() == stretch_length

# The buttons ask for a step, at either end of the stretch or one on, and a frame
# with nothing pressed leaves it alone.
expect with_buttons(
	starting_model,
	VcrButtons.click_on(ToEnd),
).transport.at == Clock.at_step(last_step)
expect with_buttons(
	asking_for(1000),
	VcrButtons.click_on(ToStart),
).transport.at == Clock.at_step(first_step)
expect with_buttons(
	starting_model,
	VcrButtons.click_on(StepForward),
).transport.at == Clock.at_step(861)
expect with_buttons(starting_model, VcrButtons.click_on(Play)).transport.at == Clock.at_step(861)
expect with_buttons(starting_model, Input.none).transport.at == Clock.at_step(first_step)

# The state on show waits for the ride, then matches the buttons.
expect shown_offset(starting_model) == 0
expect shown_offset(asking_for(last_step)) == 0
expect shown_offset(left_alone(asking_for(last_step), 2)) == 2 * played_a_frame
expect shown_offset(left_alone(asking_for(870), 2)) == 10
expect shown_offset(left_alone(asking_for(870), 1)) == 8

# A step while the ride is catching up counts from the step on show.
expect {
	catching_up = left_alone(asking_for(last_step), 2)
	stepped = with_buttons(catching_up, VcrButtons.click_on(StepForward))
	stepped.transport == {
		at: Clock.at_step(first_step).plus(Steps.of((2 * played_a_frame + 1).to_u32_wrap())),
		motion: Stopped,
	}
}

# The pig that catches the eye is in the picture, and is one of the herd.
expect canvas_point(gaze_pig.road_point).x.to_f64() < WidgetPage.canvas_width
expect canvas_point(gaze_pig.road_point).y.to_f64() < WidgetPage.picture_bottom_y
expect pig_segment.segment_pigs().count_if(|pig| pig == gaze_pig) == 1

expect
	status_lines(first_rider, Clock.at_step(first_step))
		== [
			"Eyes on the road",
			"Step 860: speed 1.7 m a step",
			"Gaze yaw: 0.0 degrees",
			"Look depth: 0%",
		]

expect {
	widest_gaze = state_at_step(stretch_states, look_end_step - 1)
	status_lines(widest_gaze, Clock.at_step(look_end_step - 1))
		== [
			"Looking at the pig, and slowing",
			"Step 1049: speed 0.2 m a step",
			"Gaze yaw: 35.0 degrees",
			"Look depth: 99%",
		]
}

# The sight line moves with the gaze, and the picture with the rider.
expect {
	looking = { ..first_rider, eyes: { ..first_rider.eyes, gaze_yaw: Angle.Turn.degrees(20.0) } }
	picture_shapes(first_rider) != picture_shapes(looking)
}
expect {
	further = {
		..first_rider,
		motorcycle: {
			..first_rider.motorcycle,
			route_place: {
				..first_rider.motorcycle.route_place,
				road_point: {
					..first_rider.motorcycle.route_place.road_point,
					along: Along.metres(200.0),
				},
			},
		},
	}
	picture_shapes(first_rider) != picture_shapes(further)
}
