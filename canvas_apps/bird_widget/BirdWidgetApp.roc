## The widget for the Safari tutorial's chapter on the Roc bird. Video recorder
## buttons run how far the rider is from the tree the bird starts on, and each
## frame is worked out from that gap alone, so the flight plays forward and
## backward. The picture stays still, looking up the road from a place short of
## the first tree, so the bird shrinks as it flies off. It is drawn by Safari's own
## Tree and PosedBird. Below it, the buttons and four lines of text that say what
## BirdFlight makes of the gap.
import game.Across
import game.Along
import game.Animation
import game.BirdFlight
import game.Camera
import game.Clock
import game.Distance
import game.Lens
import game.Polygon
import game.PosedBird
import game.Geom
import game.Trees
import game.Screen
import game.World
import lib.CanvasApp
import lib.Shapes
import lib.RgbColor
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

## The bird's flight on a segment that has one.
segment_flight : World.Segment -> Try(BirdFlight.Flight, [NoFlight])
segment_flight = |segment|
	match segment.crossing {
		BirdHere(Flies(flight)) => Ok(flight)
		BirdHere(Sits(_)) | CatCrosses(_) | QuietRoad => Err(NoFlight)
	}

## The first flight on the route.
flight : BirdFlight.Flight
flight = {
	first_flying = World.segments.find_first(|segment| segment_flight(segment).is_ok())
		?? crash "BirdWidgetApp.flight: the route has birds"
	segment_flight(first_flying) ?? crash "BirdWidgetApp.flight: this segment has a flight"
}

## How far the picture's eye stands short of the first tree: far enough for
## the bird perched on top of it to fit.
eye_to_first_tree : Distance
eye_to_first_tree = Distance.metres(18.0)

## How far ahead of the picture's eye a place on the road is.
forward_of : Along -> Distance
forward_of = |along| {
	past_first_tree = along.from_start().minus(flight.from.along.from_start())
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
	ScrubWidget.ride_shapes(
		[
			road,
			tree_shapes(flight.to),
			tree_shapes(flight.from),
			bird_shapes(gap),
		].join(),
		{ clock: Clock.start, sun: OutOfView },
	)

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

## Where a thing standing at `along` and `across` is from the picture's eye, if
## it is in front of the camera.
foot_at : Along, Across -> Try(Geom.AheadPoint, [BehindCamera])
foot_at = |along, across|
	Geom.ahead_on_level({ right: Distance.metres(across.to_metres()), forward: forward_of(along) })

tree_shapes : Trees.RoadsideTree -> List(Shapes.Shape)
tree_shapes = |tree|
	match foot_at(tree.along, tree.across) {
		Ok(foot) =>
			tree.kind.scenery_picture({ foot, cam_focal: Lens.resting_focal, context: { nearer_tree_count: 0 } })
				.to_shapes()
		Err(BehindCamera) => []
	}

## The bird as `gap` finds it, drawn by Safari's own stills.
bird_shapes : Distance -> List(Shapes.Shape)
bird_shapes = |gap| {
	instant = BirdFlight.instant_at(flight, { gap: gap })
	bird : PosedBird
	bird = { pose: instant.pose, lift: instant.spot.lift }
	match foot_at(instant.spot.along, instant.spot.across) {
		Ok(foot) => bird.scenery_picture({ foot, cam_focal: Lens.resting_focal, context: {} }).to_shapes()
		Err(BehindCamera) => []
	}
}

## What BirdFlight says at `gap`, a line each.
status_lines : Distance -> List(Str)
status_lines = |gap| {
	instant = BirdFlight.instant_at(flight, { gap: gap })
	[
		ScrubWidget.stage_text(BirdFlight.flight_stage({ gap: gap })),
		"Pose: ${pose_name(instant.pose)}",
		"Gap: ${ScrubWidget.tenths_text(gap.to_metres())} m",
		"Height: ${ScrubWidget.tenths_text(instant.spot.lift.to_metres())} m",
	]
}

pose_name : BirdFlight.BirdPose -> Str
pose_name = |pose|
	match pose {
		Perched => "Perched"
		Side(beat) => "Side on, ${beat_name(beat)}"
		Away(beat) => "Flying away, ${beat_name(beat)}"
		Diving => "Diving"
	}

beat_name : BirdFlight.WingBeat -> Str
beat_name = |beat|
	match beat {
		WingsUp => "wings up"
		WingsDown => "wings down"
	}

expect forward_of(flight.from.along).to_metres() == 18.0
expect forward_of(flight.to.along).to_metres() == 48.0

# The whole flight is on the range, with some road to spare at the far end.
expect BirdFlight.takeoff_gap < closing_gap.first
expect BirdFlight.landing_gap > closing_gap.last

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
			"Playing: 4%",
			"Pose: Side on, wings up",
			"Gap: 58.0 m",
			"Height: 7.2 m",
		]

expect
	status_lines(Distance.metres(30.0))
		== [
			"Playing: 66%",
			"Pose: Flying away, wings up",
			"Gap: 30.0 m",
			"Height: 9.7 m",
		]

expect
	status_lines(Distance.metres(4.7))
		== [
			"Past",
			"Pose: Perched",
			"Gap: 4.7 m",
			"Height: 4.9 m",
		]

expect pose_name(Side(WingsDown)) == "Side on, wings down"
expect pose_name(Away(WingsUp)) == "Flying away, wings up"
expect pose_name(Diving) == "Diving"

expect BirdFlight.instant_at(flight, { gap: Distance.metres(16.0) }).pose == Diving

## How far along the bird is with the rider at each step of the buttons through
## the flight.
flight_alongs : List(Along)
flight_alongs = {
	gaps = List.from_iter(U64.until(1, BirdFlight.flight_poses.len())).map(
		|step| BirdFlight.takeoff_gap.minus(Distance.metres(step.to_f64() / 8.0)),
	)
	gaps.map(|gap| BirdFlight.instant_at(flight, { gap: gap }).spot.along)
}

# Every step of the buttons shows a frame of its own, so the bird never stalls
# or jumps however slowly the flight is played.
expect flight_alongs.len() == 359
expect
	flight_alongs.map2(flight_alongs.drop_first(1), |before, after| before < after)
		.all(|is_on_the_way| is_on_the_way)

# The picture depends on the gap, and it doesn't change once the bird is down.
expect picture_shapes(Distance.metres(30.0)) != picture_shapes(Distance.metres(31.0))
expect picture_shapes(Distance.metres(5.0)) == picture_shapes(Distance.metres(4.0))
