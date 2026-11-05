## The widget for the Safari tutorial's chapter on the cat. Dragging across the
## canvas sets how far the rider is from the cat, and each frame is worked out
## from that gap alone, so the crossing plays forward and backward under the
## pointer. The picture looks down the road at the cat, with the road's width
## to scale. Below it, a ruler shows the gap, and four lines of text say what
## Cat and CrossingReaction make of it.
import game.Animation
import game.Cat
import game.CatDraw
import game.CatStills
import game.CrossingReaction
import game.Scenery
import game.Speed
import game.World
import lib.Brush
import lib.CanvasApp
import lib.Font
import lib.Input
import lib.Mouse
import lib.Shapes

CatWidgetApp :: [].{

	## The whole state of the widget: the gap from the rider to the cat, in
	## metres.
	Model : { gap : F64 }

	canvas_app : CanvasApp.CanvasApp(CatWidgetApp.Model)
	canvas_app = {
		size: { width: canvas_width, height: canvas_height },
		fps: 60,
		init: { gap: farthest_gap },
		advance: |
			model,
			input,
			_seconds,
		| followed_pointer(model, input),
		frame: |model| frame_at(model.gap),
		sounds: |_model| 0,
		tones: [],
		title: "The cat crossing",
	}
}

canvas_width : F64
canvas_width = 640.0

canvas_height : F64
canvas_height = 360.0

## The gap at the canvas's left edge. At its right edge the gap is zero.
farthest_gap : F64
farthest_gap = 50.0

## A typical speed on the ride. At one metre a step, the crossing's beats read
## as metres on the ruler.
rider_speed : Speed
rider_speed = Speed.metres_a_step(1.0)

## The model after one step: a pointer held down sets the gap, and the gap
## stays where it is left.
followed_pointer : CatWidgetApp.Model, Input.Snapshot -> CatWidgetApp.Model
followed_pointer = |model, input|
	if input.mouse.button_down(Left) {
		{ gap: gap_under(input.mouse.position().x.to_f64()) }
	} else {
		model
	}

## The gap under a pointer at `x`, which may be off the canvas during a drag.
gap_under : F64 -> F64
gap_under = |x|
	farthest_gap * (1.0 - Brush.clamp01(x / canvas_width))

## Where `gap` sits on the ruler.
ruler_x : F64 -> F64
ruler_x = |gap| canvas_width * (1.0 - gap / farthest_gap)

## The cat's crossing on a segment that has one.
cat_crossing : World.Segment -> Try(Cat.Crossing, [NoCat])
cat_crossing = |segment|
	match segment.crossing {
		CatCrosses(crossing) => Ok(crossing)
		BirdFlies(_) | QuietRoad => Err(NoCat)
	}

## The first segment of the route with a cat.
cat_segment : World.Segment
cat_segment =
	World.segments.find_first(|segment| cat_crossing(segment).is_ok())
		?? crash "CatWidgetApp.cat_segment: the route has cats"

crossing : Cat.Crossing
crossing = cat_crossing(cat_segment) ?? crash "CatWidgetApp.crossing: this segment has a cat"

## Everything on the canvas at `gap`.
frame_at : F64 -> List(Shapes.Shape)
frame_at = |gap|
	[
		road,
		cat_shapes(gap),
		ruler(gap),
		status_lines(gap).map_with_index(status_line).join(),
	].join()

## How many pixels a metre across the road takes up.
pixels_a_metre : F64
pixels_a_metre = 48.0

## Where the middle of the lane is, on screen.
lane_middle_x : F64
lane_middle_x = 290.0

ground_top_y : F64
ground_top_y = 150.0

ground_bottom_y : F64
ground_bottom_y = 215.0

## The line the cat's feet stand on.
feet_y : F64
feet_y = 190.0

flat : I64 -> Brush.Fill
flat = |color| Flat(Brush.opaque(color))

## The sky, the grass, and the lane between the verges.
road : List(Shapes.Shape)
road = {
	lane_width_px = Scenery.lane_width * pixels_a_metre
	ground_height = ground_bottom_y - ground_top_y
	[
		Rect({
			x: 0.0,
			y: 0.0,
			w: canvas_width,
			h: canvas_height,
			fill: flat(0xdcecf5),
		}),
		Rect({
			x: 0.0,
			y: ground_top_y,
			w: canvas_width,
			h: ground_height,
			fill: flat(0x7fa650),
		}),
		Rect({
			x: lane_middle_x - lane_width_px / 2.0,
			y: ground_top_y,
			w: lane_width_px,
			h: ground_height,
			fill: flat(0x8a8a8a),
		}),
	]
}

## The cat as `gap` finds it, drawn by Safari's own stills.
cat_shapes : F64 -> List(Shapes.Shape)
cat_shapes = |gap| {
	moment = Cat.moment_at(crossing, { gap, speed: rider_speed })
	CatDraw.polygons(
		{
			feet: { x: lane_middle_x + moment.spot.across * pixels_a_metre, y: feet_y },
			height_px: crossing.height * pixels_a_metre,
			lift: moment.spot.lift,
		},
		CatStills.pose_polys(moment.pose),
	)
}

ruler_y : F64
ruler_y = 232.0

## A bar with the stretch where the cat crosses marked on it, and a dot for
## the rider.
ruler : F64 -> List(Shapes.Shape)
ruler = |gap| {
	crossing_starts_x = ruler_x(Cat.road_buffer + rider_speed.distance_in(Cat.crossing_beats))
	[
		Rect({
			x: 0.0,
			y: ruler_y - 3.0,
			w: canvas_width,
			h: 6.0,
			fill: flat(0xb8b8b8),
		}),
		Rect({
			x: crossing_starts_x,
			y: ruler_y - 3.0,
			w: ruler_x(Cat.road_buffer) - crossing_starts_x,
			h: 6.0,
			fill: flat(0xd0603a),
		}),
		Disc({
			x: ruler_x(gap),
			y: ruler_y,
			r: 8.0,
			fill: flat(0x303030),
			clip: Anywhere,
		}),
	]
}

## What the crossing and the rider's reaction to it are at `gap`, a line each.
status_lines : F64 -> List(Str)
status_lines = |gap| {
	approach = { gap, speed: rider_speed }
	moment = Cat.moment_at(crossing, approach)
	reaction = CrossingReaction.reaction_to(
		cat_segment,
		{ along: crossing.along - gap, speed: rider_speed },
	)
	[
		stage_text(Cat.crossing_stage(approach)),
		"Pose: ${pose_name(moment.pose)}",
		"Gap: ${tenths_text(gap)} m",
		throttle_text(reaction.throttle),
	]
}

status_line : Str, U64 -> List(Shapes.Shape)
status_line = |text, row|
	Font.text(
		text,
		20.0,
		252.0 + row.to_f64() * 26.0,
		16.0,
		Brush.opaque(0x202020),
	)

stage_text : Animation.Stage -> Str
stage_text = |stage|
	match stage {
		Waiting => "Waiting"
		Playing(progress) => "Playing: ${(progress * 100.0).to_i64_wrap().to_str()}%"
		Past(_) => "Past"
	}

pose_name : Cat.Pose -> Str
pose_name = |pose|
	match pose {
		Rest => "Rest"
		Stride => "Stride"
		Frozen => "Frozen"
		Coil => "Coil"
		Flight => "Flight"
		Land => "Land"
		Collapse => "Collapse"
	}

## What a reaction's throttle means for the rider, in words.
throttle_text : [MayAccelerate, NoAcceleration] -> Str
throttle_text = |throttle|
	match throttle {
		MayAccelerate => "The rider may accelerate"
		NoAcceleration => "The rider may not accelerate"
	}

## A number of at least zero, to one decimal place.
tenths_text : F64 -> Str
tenths_text = |metres| {
	tenths = (metres * 10.0 + 0.5).to_i64_wrap()
	"${(tenths // 10).to_str()}.${(tenths % 10).to_str()}"
}

expect gap_under(0.0 - 5.0) == farthest_gap and gap_under(0.0) == farthest_gap
expect gap_under(canvas_width) == 0.0 and gap_under(canvas_width + 5.0) == 0.0
expect gap_under(canvas_width / 2.0) == 25.0
expect ruler_x(gap_under(160.0)) == 160.0

## A snapshot with the left button held or not, the pointer mid-canvas.
pointer_at_middle : U32 -> Input.Snapshot
pointer_at_middle = |held| Input.none.with_mouse(
	Mouse.of(
		held,
		0,
		320.0,
		0.0,
		0.0,
	),
)

expect followed_pointer({ gap: 7.0 }, pointer_at_middle(1)).gap == 25.0
expect followed_pointer({ gap: 7.0 }, pointer_at_middle(0)).gap == 7.0

expect
	status_lines(50.0)
		== [
			"Waiting",
			"Pose: Rest",
			"Gap: 50.0 m",
			"The rider may accelerate",
		]

expect
	status_lines(21.0)
		== [
			"Playing: 52%",
			"Pose: Frozen",
			"Gap: 21.0 m",
			"The rider may not accelerate",
		]

expect
	status_lines(1.5)
		== [
			"Past",
			"Pose: Collapse",
			"Gap: 1.5 m",
			"The rider may accelerate",
		]
