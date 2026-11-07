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
import game.Distance
import game.Gawking
import game.Gaze
import game.Geom
import game.Rider
import game.RiderState
import game.Speed
import game.Tour
import game.World
import lib.CanvasApp
import lib.Input
import lib.Shapes
import lib.RgbColor
import lib.Trig
import widget.ScrubWidget
import widget.VcrButtons

GazeWidgetApp :: [].{

	## The whole state of the widget: the states of the stretch played so far,
	## first step first, and the buttons, which hold the step asked for.
	Model : { played : List(RiderState), transport : VcrButtons.Transport(Clock) }

	canvas_app : CanvasApp.CanvasApp(GazeWidgetApp.Model)
	canvas_app = ScrubWidget.canvas_app({
		title: "The rider's gaze",
		init: starting_model,
		model_at_next_step: |model, input| played_on(with_buttons(model, input)),
		frame_shapes: shapes_at,
	})
}

## What the rider is doing about the pig at one step.
GazePhase : [EyesOnRoad, LookingAtPig, EasingBack, EyesBack]

## The first step on show, with the pig still too far off to notice.
first_step : U32
first_step = 860

## The last step on show, a little after the gaze is back on the road.
last_step : U32
last_step = 1320

## The steps of the look, from its first to the first without it. An `expect`
## below holds them to the ride.
look_first_step : U32
look_first_step = 889

look_end_step : U32
look_end_step = 1051

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

## The rider at `first_step`, a record like any other, so the widget needn't ride
## there. An `expect` below rides there and compares.
first_rider : RiderState
first_rider = {
	segment_index: World.SegmentIndex.number(2),
	motorcycle: {
		along: Along.metres(140.3590433880225),
		across: Across.metres(-0.027010758256703966),
		yaw: Angle.Turn.radians(-0.00037326865836414446),
		speed: Speed.metres_a_step(1.6528903626175844),
		lean: Angle.Lean.radians(-0.00020453077171767937),
		heading: Angle.Bearing.radians(-0.3494391190572302),
	},
	eyes: RiderState.initial.eyes,
}

starting_model : GazeWidgetApp.Model
starting_model = { played: [first_rider], transport: VcrButtons.transport_at(stretch.first) }

## The first segment of the route whose pigs catch the rider's eye.
pig_segment : World.Segment
pig_segment =
	World.segments.find_first(is_distracting)
		?? crash "GazeWidgetApp.pig_segment: the route has a distracting pig"

## Whether a segment's pigs catch the rider's eye.
is_distracting : World.Segment -> Bool
is_distracting = |segment|
	match segment.pig_interest {
		Distracting => True
		Unnoticed => False
	}

## The pig that catches the rider's eye.
gaze_pig : Geom.Placed(Billboard)
gaze_pig =
	match Gawking.eye_catching_pig(pig_segment) {
		CatchesEye(pig) => pig
		NoPigCatchesEye => crash "GazeWidgetApp.gaze_pig: this segment's pigs catch the eye"
	}

## `model` after a frame of its buttons. A press counts from the step on show,
## which the ride may not have reached the one asked for.
with_buttons : GazeWidgetApp.Model, Input.Snapshot -> GazeWidgetApp.Model
with_buttons = |model, input| {
	shown = Clock.at_step(first_step + shown_offset(model).to_u32_wrap())
	caught_up = VcrButtons.catch_up(model.transport, { input, shown })
	{ ..model, transport: VcrButtons.next_transport(caught_up, { input, range: stretch }) }
}

## `model` a frame on, with a few more steps played until the stretch is.
played_on : GazeWidgetApp.Model -> GazeWidgetApp.Model
played_on = |model| {
	reach = stretch_length.min(model.played.len() + played_a_frame)
	var $played = model.played
	while $played.len() < reach {
		latest = $played.last() ?? crash "GazeWidgetApp.played_on: the stretch starts with a state"
		$played = $played.append(Rider.rider_state_at_next_step(latest, World.segments))
	}
	{ ..model, played: $played }
}

## How far into the stretch the state on show is: where the buttons asked for, or
## the last step played if the ride hasn't got there yet.
shown_offset : GazeWidgetApp.Model -> U64
shown_offset = |model| {
	asked_for = (model.transport.at.to_f64() - first_step.to_f64()).to_u64_wrap()
	asked_for.min(model.played.len() - 1)
}

state_at : List(RiderState), U64 -> RiderState
state_at = |played, offset|
	played.get(offset) ?? crash "GazeWidgetApp.state_at: offsets stay within what's played"

## What the rider is doing about the pig in `rider`'s state.
phase_of : RiderState -> GazePhase
phase_of = |rider|
	if !Gawking.is_gawking(rider.motorcycle, pig_segment) {
		EyesOnRoad
	} else {
		match Gaze.desired_gaze(rider.motorcycle, pig_segment) {
			OnPig(_) => LookingAtPig
			OnRoad if rider.eyes.gaze_yaw == Angle.straight_ahead => EyesBack
			OnRoad => EasingBack
		}
	}

## Everything on the canvas.
shapes_at : GazeWidgetApp.Model -> List(Shapes.Shape)
shapes_at = |model| {
	offset = shown_offset(model)
	rider = state_at(model.played, offset)
	step = first_step.to_f64() + offset.to_f64()
	VcrButtons.frame_shapes(
		model.transport,
		{
			range: stretch,
			picture_shapes: picture_shapes(rider),
			status_lines: status_lines(rider, step),
		},
	)
}

ground_color : RgbColor
ground_color = RgbColor.of(0x6f9a55)

road_color : RgbColor
road_color = RgbColor.of(0x8a8a8a)

rider_color : RgbColor
rider_color = RgbColor.of(0xf2efe4)

herd_color : RgbColor
herd_color = RgbColor.of(0xe9b7b0)

gaze_pig_color : RgbColor
gaze_pig_color = RgbColor.of(0xd0603a)

sight_color : RgbColor
sight_color = RgbColor.of(0xf6d743)

## How many pixels a metre takes up, along the road and across it.
pixels_a_metre : F64
pixels_a_metre = 2.4

## Where the canvas's left edge is along the segment, in metres.
left_edge_metres : F64
left_edge_metres = 130.0

## Where the middle of the road is, on the canvas.
road_middle_y : F64
road_middle_y = 52.0

## Where a point on the segment falls on the canvas. The road runs left to right,
## so the rider's right is down the canvas.
screen_x : Along -> F64
screen_x = |along| (along.to_metres() - left_edge_metres) * pixels_a_metre

screen_y : Across -> F64
screen_y = |across| road_middle_y + across.to_metres() * pixels_a_metre

ground : Shapes.Shape
ground = Rect({
	x: 0.0,
	y: 0.0,
	width: ScrubWidget.canvas_width,
	height: ScrubWidget.picture_bottom_y,
	fill: ScrubWidget.flat(ground_color),
})

road : Shapes.Shape
road = {
	half_width = Geom.road_half_width.to_metres() * pixels_a_metre
	Rect({
		x: 0.0,
		y: road_middle_y - half_width,
		width: ScrubWidget.canvas_width,
		height: 2.0 * half_width,
		fill: ScrubWidget.flat(road_color),
	})
}

## A disc on the road's plan, of radius `radius` and in `color`.
plan_disc : {
	along : Along,
	across : Across,
	radius : F64,
	color : RgbColor,
} -> Shapes.Shape
plan_disc = |{ along, across, radius, color }|
	Disc({
		x: screen_x(along),
		y: screen_y(across),
		radius: radius,
		fill: ScrubWidget.flat(color),
	})

## One pig of the herd, the one that catches the eye drawn larger.
pig_disc : Geom.Placed(Billboard) -> Shapes.Shape
pig_disc = |pig|
	if pig == gaze_pig {
		plan_disc({
			along: pig.along,
			across: pig.across,
			radius: 6.0,
			color: gaze_pig_color,
		})
	} else {
		plan_disc({
			along: pig.along,
			across: pig.across,
			radius: 3.0,
			color: herd_color,
		})
	}

## The segment's whole herd, and the name of the pig that catches the eye.
pigs : List(Shapes.Shape)
pigs =
	World.segment_pigs(pig_segment)
		.map(pig_disc)
		.append(
			ScrubWidget.label({
				text: "the pig",
				x: screen_x(gaze_pig.along) - 62.0,
				y: screen_y(gaze_pig.across) + 20.0,
			}),
		)

## The way the rider looks: as far as a pig can catch the eye, turned from the
## road by the bike's yaw and the rider's gaze.
sight_line : RiderState -> Shapes.Shape
sight_line = |rider| {
	x = screen_x(rider.motorcycle.along)
	y = screen_y(rider.motorcycle.across)
	turn = rider.motorcycle.yaw.plus(rider.eyes.gaze_yaw).to_radians()
	reach = Gawking.notice_distance.to_metres() * pixels_a_metre
	Shapes.line(
		{
			from: { x, y },
			to: { x: x + reach * turn.cos(), y: y + reach * turn.sin() },
			width: 2.0,
		},
		ScrubWidget.flat(sight_color),
	)
}

## The road from above, with the pigs, the rider and the rider's sight line.
picture_shapes : RiderState -> List(Shapes.Shape)
picture_shapes = |rider|
	[
		[ground, road],
		pigs,
		[
			sight_line(rider),
			plan_disc({
				along: rider.motorcycle.along,
				across: rider.motorcycle.across,
				radius: 5.0,
				color: rider_color,
			}),
		],
	].join()

## What the rider is doing, in words.
phase_text : GazePhase -> Str
phase_text = |phase|
	match phase {
		EyesOnRoad => "Eyes on the road"
		LookingAtPig => "Looking at the pig, and slowing"
		EasingBack => "Too far round: the gaze eases back"
		EyesBack => "Eyes back on the road, still slow"
	}

## How far the rider looks from the way the bike points, in degrees. A pig on the
## right turns the gaze right, so on this stretch it's never negative.
gaze_degrees : RiderState -> F64
gaze_degrees = |rider| rider.eyes.gaze_yaw.to_radians() / Trig.deg

## The state at `step`, a line each.
status_lines : RiderState, F64 -> List(Str)
status_lines = |rider, step|
	[
		phase_text(phase_of(rider)),
		"Step ${step.to_u64_wrap().to_str()}: speed ${ScrubWidget.tenths_text(rider.motorcycle.speed.to_metres_a_step())} m a step",
		"Gaze yaw: ${ScrubWidget.tenths_text(gaze_degrees(rider))} degrees",
		"Look depth: ${ScrubWidget.percent_text(rider.eyes.look_depth)}",
	]

## The whole stretch, played, for the expects. As a constant it's ridden once, at
## compile time, which adds under half a second to a check.
stretch_states : List(RiderState)
stretch_states = {
	var $model = starting_model
	while $model.played.len() < stretch_length {
		$model = played_on($model)
	}
	$model.played
}

## The state at `step` of a played stretch.
state_at_step : List(RiderState), U32 -> RiderState
state_at_step = |played, step| state_at(played, (step - first_step).to_u64())

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
	real = ridden_to(first_step).instant.rider
	real.segment_index == first_rider.segment_index
		and real.motorcycle == first_rider.motorcycle
		and real.eyes == first_rider.eyes
}

# This stretch is on the route's first distracting segment.
expect is_distracting(first_rider.segment_index.segment_in(World.segments))
expect World.segments.take_first(2).all(|segment| segment.pig_herd == NoPigs)
expect pig_segment.length == Distance.metres(400.0)

# The steps the book's table quotes, each with its speed in metres a step, its
# gaze_yaw in degrees and its look depth, to the table's precision.
expect {
	played = stretch_states
	[
		{
			step: 889,
			speed: 1.9429,
			gaze: 4.0,
			look_depth: 0.1143,
		},
		{
			step: 1050,
			speed: 0.2000,
			gaze: 34.6686,
			look_depth: 0.9905,
		},
		{
			step: 1051,
			speed: 0.2000,
			gaze: 34.4686,
			look_depth: 0.9905,
		},
		{
			step: 1308,
			speed: 0.2000,
			gaze: 0.0,
			look_depth: 0.9893,
		},
	].all(
		|{ step, speed, gaze, look_depth }| {
			rider = state_at_step(played, step)
			(rider.motorcycle.speed.to_metres_a_step() - speed).abs() <= 0.00005
				and (gaze_degrees(rider) - gaze).abs() <= 0.00005
				and (rider.eyes.look_depth.to_f64() - look_depth).abs() <= 0.00005
		},
	)
}

# Each phase starts at the step the book says, and not one step before it.
expect {
	played = stretch_states
	[
		(first_step, EyesOnRoad),
		(look_first_step - 1, EyesOnRoad),
		(look_first_step, LookingAtPig),
		(look_end_step - 1, LookingAtPig),
		(look_end_step, EasingBack),
		(1307, EasingBack),
		(1308, EyesBack),
		(last_step, EyesBack),
	].all(|(step, phase)| phase_of(state_at_step(played, step)) == phase)
}

# The gawking and the look start on one step, because both start the same
# distance from the pig. The brake bites a step later.
expect {
	played = stretch_states
	before = state_at_step(played, 888)
	first = state_at_step(played, 889)
	next = state_at_step(played, 890)
	!Gawking.is_gawking(before.motorcycle, pig_segment)
		and Gawking.is_gawking(first.motorcycle, pig_segment)
		and first.motorcycle.speed > before.motorcycle.speed
		and next.motorcycle.speed < first.motorcycle.speed
}

# The gaze is at its widest on the look's last step, and the look ends short of
# the release angle, because the next step would pass it.
expect {
	played = stretch_states
	widest = gaze_degrees(state_at_step(played, look_end_step - 1))
	played.all(|rider| gaze_degrees(rider) <= widest)
		and gaze_degrees(state_at_step(played, look_end_step)) < widest
		and gaze_degrees(state_at_step(played, look_end_step - 2)) < widest
		and widest < Gaze.look_release_angle.to_radians() / Trig.deg
}

# The gaze never turns left on this stretch, as `gaze_degrees` says.
expect stretch_states.all(|rider| gaze_degrees(rider) >= 0.0)

# The whole stretch stays on the canvas, and on the one segment.
expect
	stretch_states.all(
		|rider|
			rider.segment_index == first_rider.segment_index
				and screen_x(rider.motorcycle.along) > 0.0
				and screen_x(rider.motorcycle.along) < ScrubWidget.canvas_width,
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
expect left_alone(starting_model, 57).played.len() == 457
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
	stepped.transport == { at: Clock.at_step(first_step + 2 * 8 + 1), motion: Stopped }
}

expect look_first_step < look_end_step

# Where the road's plan falls on the canvas.
expect screen_x(Along.metres(left_edge_metres)) == 0.0
expect screen_x(Along.metres(left_edge_metres + 100.0)) == 100.0 * pixels_a_metre
expect screen_y(Across.middle) == road_middle_y
expect screen_y(Across.metres(10.0)) == road_middle_y + 10.0 * pixels_a_metre
expect screen_y(Across.metres(-10.0)) == road_middle_y - 10.0 * pixels_a_metre
expect screen_x(gaze_pig.along) < ScrubWidget.canvas_width
expect screen_y(gaze_pig.across) < ScrubWidget.picture_bottom_y

expect World.segment_pigs(pig_segment).len() == 49

# Each pig of the herd is one disc, and the one that catches the eye is among them.
expect pigs.len() == 50
expect World.segment_pigs(pig_segment).count_if(|pig| pig == gaze_pig) == 1

expect phase_text(EyesOnRoad) == "Eyes on the road"
expect phase_text(LookingAtPig) == "Looking at the pig, and slowing"
expect phase_text(EasingBack) == "Too far round: the gaze eases back"
expect phase_text(EyesBack) == "Eyes back on the road, still slow"

expect
	status_lines(first_rider, 860.0)
		== [
			"Eyes on the road",
			"Step 860: speed 1.7 m a step",
			"Gaze yaw: 0.0 degrees",
			"Look depth: 0%",
		]

expect {
	widest_gaze = state_at_step(stretch_states, 1050)
	status_lines(widest_gaze, 1050.0)
		== [
			"Looking at the pig, and slowing",
			"Step 1050: speed 0.2 m a step",
			"Gaze yaw: 34.7 degrees",
			"Look depth: 99%",
		]
}

# The sight line moves with the gaze, and the picture with the rider.
expect {
	looking = { ..first_rider, eyes: { ..first_rider.eyes, gaze_yaw: Angle.Turn.degrees(20.0) } }
	picture_shapes(first_rider) != picture_shapes(looking)
}
expect {
	further = { ..first_rider, motorcycle: { ..first_rider.motorcycle, along: Along.metres(200.0) } }
	picture_shapes(first_rider) != picture_shapes(further)
}
