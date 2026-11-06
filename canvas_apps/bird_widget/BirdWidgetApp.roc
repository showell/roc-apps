## The widget for the Safari tutorial's chapter on the Roc bird. Dragging across
## the canvas sets how far the rider is from the tree the bird starts on, and
## each frame is worked out from that gap alone, so the flight plays forward and
## backward under the pointer. The picture stays still, looking up the road from
## a place short of the first tree, so the bird shrinks as it flies off. It is
## drawn by Safari's own Tree and RocBird. Below it, a ruler shows the gap, and
## four lines of text say what BirdFlight makes of it.
import game.Along
import game.Animation
import game.BirdFlight
import game.Camera
import game.Clock
import game.Distance
import game.Fraction
import game.SceneDraw
import game.Lens
import game.Paint
import game.RocBird
import game.Scenery
import game.Screen
import game.TreeDraw
import game.World
import lib.CanvasApp
import lib.Shapes
import widget.ScrubWidget

BirdWidgetApp :: [].{

	## The whole state of the widget: the gap from the rider to the bird's first
	## tree.
	Model : { gap : Distance }

	canvas_app : CanvasApp.CanvasApp(BirdWidgetApp.Model)
	canvas_app = ScrubWidget.canvas_app({
		title: "The bird taking off",
		init: { gap: farthest_gap },
		model_at: |share| { gap: ScrubWidget.gap_at(share, { farthest: farthest_gap }) },
		frame: |model| frame_at(model.gap),
	})
}

## The gap at the canvas's left edge, past where the bird takes off. At its right
## edge the gap is zero.
farthest_gap : Distance
farthest_gap = Distance.metres(75.0)

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
eye_to_first_tree : F64
eye_to_first_tree = 18.0

## How far ahead of the picture's eye a place on the road is.
forward_of : Along -> F64
forward_of = |along| {
	past_first_tree = along.from_start().minus(flight.from.along.from_start())
	eye_to_first_tree + past_first_tree.to_metres()
}

## How far ahead the road is drawn.
road_end_forward : F64
road_end_forward = 2000.0

## Everything on the canvas at `gap`.
frame_at : Distance -> List(Shapes.Shape)
frame_at = |gap|
	ScrubWidget.frame_shapes({
		picture: picture(gap),
		dot_at: ScrubWidget.gap_share(gap, { farthest: farthest_gap }),
		marked: [flight_stretch],
		status: status_lines(gap),
	})

## The road and the two trees, far things first, and the bird at `gap`.
picture : Distance -> List(Shapes.Shape)
picture = |gap|
	ScrubWidget.ride_picture(
		[
			lane,
			tree_shapes(flight.to),
			tree_shapes(flight.from),
			bird_shapes(gap),
		].join(),
		{ clock: Clock.start, sun: OutOfView },
	)

## The lane, running up the picture from under the eye.
lane : List(Shapes.Shape)
lane = {
	half = Scenery.lane_width.to_metres() / 2.0
	on_ground = |right, forward|
		Camera.project(
			{
				right,
				forward,
				height: 0.0,
			},
			Lens.focal,
		)
	Paint.push_poly(
		0x8a8a8a,
		[
			on_ground(0.0 - half, 1.0),
			on_ground(half, 1.0),
			on_ground(half, road_end_forward),
			on_ground(0.0 - half, road_end_forward),
		],
	)
}

tree_shapes : Scenery.Tree -> List(Shapes.Shape)
tree_shapes = |tree| {
	forward = forward_of(tree.along)
	TreeDraw.draw({
		right: tree.across.to_metres(),
		forward,
		height: tree.height.to_metres(),
		color: tree.color,
		cam_focal: Lens.focal,
		trunk: RoundCorners,
		crown: Cones,
		shade: SceneDraw.crown_shade(forward),
	})
}

## The bird as `gap` finds it, drawn by Safari's own stills.
bird_shapes : Distance -> List(Shapes.Shape)
bird_shapes = |gap| {
	instant = BirdFlight.instant_at(flight, gap)
	RocBird.draw(
		{
			right: instant.spot.across.to_metres(),
			forward: forward_of(instant.spot.along),
			lift: Distance.metres(instant.spot.lift),
			pose: instant.pose,
		},
		Lens.focal,
	)
}

## The stretch of the ruler where the bird is in the air.
flight_stretch : ScrubWidget.Stretch
flight_stretch = {
	from: ScrubWidget.gap_share(BirdFlight.takeoff_gap, { farthest: farthest_gap }),
	to: ScrubWidget.gap_share(BirdFlight.landing_gap, { farthest: farthest_gap }),
}

## What BirdFlight says at `gap`, a line each.
status_lines : Distance -> List(Str)
status_lines = |gap| {
	instant = BirdFlight.instant_at(flight, gap)
	[
		ScrubWidget.stage_text(BirdFlight.flight_stage(gap)),
		"Pose: ${pose_name(instant.pose)}",
		"Gap: ${ScrubWidget.tenths_text(gap.to_metres())} m",
		"Height: ${ScrubWidget.tenths_text(instant.spot.lift)} m",
	]
}

pose_name : BirdFlight.Pose -> Str
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

expect forward_of(flight.from.along) == 18.0
expect forward_of(flight.to.along) == 48.0

expect
	[
		(flight_stretch.from, 0.2),
		(flight_stretch.to, 0.8),
	].all(|(share, want)| (share.to_f64() - want).abs() <= 0.0000001)

expect
	status_lines(Distance.metres(61.0))
		== [
			"Waiting",
			"Pose: Perched",
			"Gap: 61.0 m",
			"Height: 5.9 m",
		]

expect
	status_lines(Distance.metres(58.0))
		== [
			"Playing: 4%",
			"Pose: Side on, wings up",
			"Gap: 58.0 m",
			"Height: 6.7 m",
		]

expect
	status_lines(Distance.metres(30.0))
		== [
			"Playing: 66%",
			"Pose: Flying away, wings down",
			"Gap: 30.0 m",
			"Height: 9.3 m",
		]

expect
	status_lines(Distance.metres(4.7))
		== [
			"Past",
			"Pose: Perched",
			"Gap: 4.7 m",
			"Height: 4.5 m",
		]

expect pose_name(Side(WingsDown)) == "Side on, wings down"
expect pose_name(Away(WingsUp)) == "Flying away, wings up"
expect pose_name(Diving) == "Diving"

expect BirdFlight.instant_at(flight, Distance.metres(16.0)).pose == Diving

# The picture depends on the gap, and it doesn't change once the bird is down.
expect picture(Distance.metres(30.0)) != picture(Distance.metres(31.0))
expect picture(Distance.metres(5.0)) == picture(Distance.metres(4.0))
