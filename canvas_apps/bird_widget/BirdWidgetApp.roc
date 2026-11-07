## The widget for the Safari tutorial's chapter on the Roc bird. Video recorder
## buttons run how far the rider is from the tree the bird starts on, coming at
## the cruising 1.25 m a step, and each frame is worked out from that gap alone:
## the step of the ride it is, and the start the ride plans for the flight, so the
## flight plays forward and backward. The picture stays still, looking up the road from a place short of
## the first tree, so the bird shrinks as it flies off. It is drawn by Safari's own
## Tree and PosedBird. Below it, the buttons and four lines of text that say what
## BirdFlight makes of the gap.
import game.Across
import game.Along
import game.Angle
import game.Animation
import game.BirdFlight
import game.Camera
import game.Clock
import game.Distance
import game.Lens
import game.PosedBird
import game.Geom
import game.Segment
import game.Speed
import game.Trees
import game.Sky
import game.Spot
import game.Steps
import game.World
import lib.CanvasApp
import lib.Shapes
import lib.RgbColor
import widget.ReadoutText
import widget.ScrubWidget
import widget.VcrButtons

BirdWidgetApp :: [].{

	## The whole state of the widget: the buttons, which hold the gap from the
	## rider to the bird's first tree.
	Model : VcrButtons.Transport(Distance)

	canvas_app : CanvasApp.CanvasApp(BirdWidgetApp.Model)
	canvas_app = VcrButtons.canvas_app({
		title: "The bird taking off",
		range: closing_gap,
		opens_at: closing_gap.first,
		frame_shapes: shapes_at,
	})
}

## The rider's approach, from a gap past where the bird takes off down to zero, in
## ten seconds.
closing_gap : VcrButtons.NumberRange(Distance)
closing_gap = VcrButtons.gap_range({ farthest: Distance.metres(75.0), metres_a_frame: 0.125 })

## The rider's speed: the cruising speed the bird's flap is set by.
rider_speed : Speed
rider_speed = Speed.metres_a_step(1.25)

## The bird's flight on a segment that has one.
segment_flight : Segment -> Try(BirdFlight.Flight, [NoFlight])
segment_flight = |segment|
	match segment.encounter {
		BirdHere(bird_flight) => Ok(bird_flight)
		CatCrosses(_) | QuietRoad => Err(NoFlight)
	}

## The ride's clock with the rider `gap` from the bird's first tree: the whole
## steps since the far end of the range, at step 0.
clock_at : Distance -> Clock
clock_at = |gap| Clock.at_step(closing_gap.first.minus(gap).portion(rider_speed.step_length()).to_u32_wrap())

## The flight's timing with the rider `gap` from the bird's first tree: planned
## as the ride plans it, on the first step from the far end of the range that the
## rider comes within reach.
flight_timing : Distance -> Animation.Timing
flight_timing = |gap| {
	now = clock_at(gap)
	var $step = Clock.start
	var $start = Unplanned
	while $start == Unplanned and !(now < $step) {
		$start = Animation.planned_start(
			BirdFlight.flight_span,
			{
				gap: closing_gap.first.minus(rider_speed.distance_in($step.steps_since(Clock.start))),
				speed: rider_speed,
				now: $step,
			},
		)
		$step = $step.next()
	}
	Animation.timing_of($start, now)
}

## Where the flight has got to with the rider `gap` from the bird's first tree.
stage_at : Distance -> Animation.Stage
stage_at = |gap| BirdFlight.flight_stage(flight_timing(gap))

## The first flight on the route.
flight : BirdFlight.Flight
flight =
	World.route.route_segments().keep_oks(segment_flight).first()
		?? crash "BirdWidgetApp.flight: the route has a bird that flies"

## How far the picture's eye stands short of the first tree: far enough for
## the bird perched on top of it to fit.
eye_to_first_tree : Distance
eye_to_first_tree = Distance.metres(18.0)

## How far ahead of the picture's eye a place on the road is.
forward_of : Along -> Distance
forward_of = |along| {
	past_first_tree = along.distance_from(flight.from.road_point.along)
	eye_to_first_tree.plus(past_first_tree)
}

## How far ahead the road is drawn.
road_end_forward : Distance
road_end_forward = Distance.metres(2000.0)

## Everything on the canvas.
shapes_at : BirdWidgetApp.Model -> List(Shapes.Shape)
shapes_at = |transport|
	VcrButtons.frame_shapes(
		transport,
		{ range: closing_gap, picture_shapes: picture_shapes(transport.at), status_lines: status_lines(transport.at) },
	)

## The road and the two trees, far things first, and the bird at `gap`.
picture_shapes : Distance -> List(Shapes.Shape)
picture_shapes = |gap|
	ScrubWidget.ride_shapes({
		backdrop: { sky_colors: Sky.colors_at(Clock.start), sun_sighting: OutOfView },
		ride_shapes: [
			road,
			tree_shapes(flight.to),
			tree_shapes(flight.from),
			bird_shapes(gap),
		].join(),
		roll: Angle.upright,
	})

## The road, running up the picture from under the eye.
road : List(Shapes.Shape)
road = {
	half = Geom.road_half_width
	road_start = Distance.metres(1.0)
	on_ground = |right, forward| { right, forward, height: Distance.zero }
	corners = [
		on_ground(half.opposite(), road_start),
		on_ground(half, road_start),
		on_ground(half, road_end_forward),
		on_ground(half.opposite(), road_end_forward),
	]
	[Camera.clipped_polygon({ color: RgbColor.of(0x8a8a8a), corners }, Lens.resting_focal)].keep_oks(|shape| shape)
}

## The spot of a thing standing at `along` and `across`, `lift` off the ground,
## if it is in front of the picture's eye.
spot_of : { along : Along, across : Across, lift : Distance, .. } -> Try(Spot, [BehindCamera])
spot_of = |{ along, across, lift, .. }|
	Spot.straight_ahead({ road_point: { along, across }, lift, forward: forward_of(along) })

tree_shapes : Trees.RoadsideTree -> List(Shapes.Shape)
tree_shapes = |tree|
	match spot_of({ along: tree.road_point.along, across: tree.road_point.across, lift: tree.lift }) {
		Ok(spot) =>
			tree.kind.scenery_picture({
				spot,
				cam_focal: Lens.resting_focal,
				context: { nearer_tree_count: 0 },
			}).to_shapes()
		Err(BehindCamera) => []
	}

## The bird as `gap` finds it, drawn by Safari's own stills.
bird_shapes : Distance -> List(Shapes.Shape)
bird_shapes = |gap| {
	instant = BirdFlight.instant_at(flight, stage_at(gap))
	bird : PosedBird
	bird = { pose: instant.pose }
	match spot_of(instant.location) {
		Ok(spot) =>
			bird.scenery_picture({
				spot,
				cam_focal: Lens.resting_focal,
				context: {},
			}).to_shapes()
		Err(BehindCamera) => []
	}
}

## What BirdFlight says at `gap`, a line each.
status_lines : Distance -> List(Str)
status_lines = |gap| {
	stage = stage_at(gap)
	instant = BirdFlight.instant_at(flight, stage)
	[
		ReadoutText.stage_text(stage),
		"Pose: ${pose_name(instant.pose)}",
		"Gap: ${ReadoutText.tenths_text(gap.to_metres())} m",
		"Height: ${ReadoutText.tenths_text(instant.location.lift.to_metres())} m",
	]
}

pose_name : PosedBird.BirdPose -> Str
pose_name = |pose|
	match pose {
		Perched => "Perched"
		Side(beat) => "Side on, ${beat_name(beat)}"
		Away(beat) => "Flying away, ${beat_name(beat)}"
		Diving => "Diving"
	}

beat_name : PosedBird.WingBeat -> Str
beat_name = |beat|
	match beat {
		WingsUp => "wings up"
		WingsDown => "wings down"
	}

## The gap the flight starts at, for a rider at `rider_speed`: 15 m for the gap
## it lands at and 45 m for its 36 steps.
takeoff_gap : Distance
takeoff_gap = Animation.planning_gap(BirdFlight.flight_span, rider_speed)

# The whole flight is on the range, with some road to spare at the far end.
expect takeoff_gap < closing_gap.first
expect BirdFlight.flight_span.ends_at > closing_gap.last

expect
	status_lines(Distance.metres(61.0))
		== [
			"Waiting",
			"Pose: Perched",
			"Gap: 61.0 m",
			"Height: 6.4 m",
		]

expect
	status_lines(Distance.metres(58.0))
		== [
			"Playing: frame 2",
			"Pose: Side on, wings up",
			"Gap: 58.0 m",
			"Height: 6.9 m",
		]

expect
	status_lines(Distance.metres(30.0))
		== [
			"Playing: frame 25",
			"Pose: Flying away, wings up",
			"Gap: 30.0 m",
			"Height: 9.6 m",
		]

expect
	status_lines(Distance.metres(4.7))
		== [
			"Past",
			"Pose: Perched",
			"Gap: 4.7 m",
			"Height: 4.9 m",
		]

# It takes off at 60 m, a step before is perched, and lands at 15 m.
expect stage_at(Distance.metres(60.0)) == Playing(Steps.zero)
expect stage_at(Distance.metres(60.125)) == Waiting
expect stage_at(Distance.metres(15.0)) == Past(Steps.zero)
expect stage_at(Distance.metres(15.125)) == Playing(Steps.of(35))

## The bird at each step of the ride through its flight, from the far end of the
## range at 1.25 m a step.
flight_seen : List(BirdFlight.BirdInstant)
flight_seen =
	List.from_iter(U32.until(12, 48)).map(
		|step| {
			gap = closing_gap.first.minus(rider_speed.distance_in(Steps.of(step)))
			BirdFlight.instant_at(flight, stage_at(gap))
		},
	)

# Each step of the ride shows the next frame of the flight, and the bird moves
# on along the road at every one.
expect flight_seen.map(|instant| instant.pose) == BirdFlight.flight_poses
expect {
	alongs = flight_seen.map(|instant| instant.location.along)
	alongs.map2(alongs.drop_first(1), |before, after| before < after).all(|is_on_the_way| is_on_the_way)
}

# The picture depends on the gap, and it doesn't change once the bird is down.
expect picture_shapes(Distance.metres(30.0)) != picture_shapes(Distance.metres(31.0))
expect picture_shapes(Distance.metres(5.0)) == picture_shapes(Distance.metres(4.0))
