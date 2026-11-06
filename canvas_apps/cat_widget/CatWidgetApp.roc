## The widget for the Safari tutorial's chapter on the cat. Dragging across the
## canvas sets how far the rider is from the cat, and each frame is worked out
## from that gap alone, so the crossing plays forward and backward under the
## pointer. The picture looks down the road at the cat, with the road's width
## to scale. Below it, a ruler shows the gap, and four lines of text say what
## Cat and CrossingReaction make of it.
import game.Cat
import game.CatDraw
import game.CatStills
import game.CrossingReaction
import game.Distance
import game.Fraction
import game.Scenery
import game.Speed
import game.World
import lib.CanvasApp
import lib.Shapes
import widget.ScrubWidget

CatWidgetApp :: [].{

	## The whole state of the widget: the gap from the rider to the cat.
	Model : { gap : Distance }

	canvas_app : CanvasApp.CanvasApp(CatWidgetApp.Model)
	canvas_app = ScrubWidget.canvas_app({
		title: "The cat crossing",
		init: { gap: farthest_gap },
		model_at: |share| { gap: ScrubWidget.gap_at(share, { farthest: farthest_gap }) },
		frame: |model| frame_at(model.gap),
	})
}

## The gap at the canvas's left edge. At its right edge the gap is zero.
farthest_gap : Distance
farthest_gap = Distance.metres(50.0)

## How far along the ruler `gap` sits.
gap_share : Distance -> Fraction
gap_share = |gap| ScrubWidget.gap_share(gap, { farthest: farthest_gap })

## A typical speed on the ride. At one metre a step, the crossing's beats read
## as metres on the ruler.
rider_speed : Speed
rider_speed = Speed.metres_a_step(1.0)

## The cat's crossing on a segment that has one.
cat_crossing : World.Segment -> Try(Cat.Crossing, [NoCat])
cat_crossing = |segment|
	match segment.crossing {
		CatCrosses(crossing) => Ok(crossing)
		BirdHere(_) | QuietRoad => Err(NoCat)
	}

## The first segment of the route with a cat.
cat_segment : World.Segment
cat_segment =
	World.segments.find_first(|segment| cat_crossing(segment).is_ok())
		?? crash "CatWidgetApp.cat_segment: the route has cats"

crossing : Cat.Crossing
crossing = cat_crossing(cat_segment) ?? crash "CatWidgetApp.crossing: this segment has a cat"

## Everything on the canvas at `gap`.
frame_at : Distance -> List(Shapes.Shape)
frame_at = |gap|
	ScrubWidget.frame_shapes({
		picture: road.concat(cat_shapes(gap)),
		dot_at: gap_share(gap),
		marked: [crossing_stretch],
		status: status_lines(gap),
	})

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

## The sky, the grass, and the lane between the verges.
road : List(Shapes.Shape)
road = {
	lane_width_px = Scenery.road_width.to_metres() * pixels_a_metre
	ground_height = ground_bottom_y - ground_top_y
	[
		Rect({
			x: 0.0,
			y: 0.0,
			w: ScrubWidget.canvas_width,
			h: ScrubWidget.picture_bottom_y,
			fill: ScrubWidget.flat(0xdcecf5),
		}),
		Rect({
			x: 0.0,
			y: ground_top_y,
			w: ScrubWidget.canvas_width,
			h: ground_height,
			fill: ScrubWidget.flat(0x7fa650),
		}),
		Rect({
			x: lane_middle_x - lane_width_px / 2.0,
			y: ground_top_y,
			w: lane_width_px,
			h: ground_height,
			fill: ScrubWidget.flat(0x8a8a8a),
		}),
	]
}

## The cat as `gap` finds it, drawn by Safari's own stills.
cat_shapes : Distance -> List(Shapes.Shape)
cat_shapes = |gap| {
	instant = Cat.instant_at(crossing, { gap, speed: rider_speed })
	CatDraw.polygons(
		{
			feet: {
				x: lane_middle_x + instant.spot.across.to_metres() * pixels_a_metre,
				y: feet_y,
			},
			height_px: crossing.height.to_metres() * pixels_a_metre,
			lift: instant.spot.lift,
		},
		CatStills.pose_polys(instant.pose),
	)
}

## The stretch of the ruler where the cat crosses.
crossing_stretch : ScrubWidget.Stretch
crossing_stretch = {
	crossing_length = rider_speed.distance_in(Cat.crossing_beats)
	{
		from: gap_share(Cat.road_buffer.plus(crossing_length)),
		to: gap_share(Cat.road_buffer),
	}
}

## What the crossing and the rider's reaction to it are at `gap`, a line each.
status_lines : Distance -> List(Str)
status_lines = |gap| {
	approach = { gap, speed: rider_speed }
	instant = Cat.instant_at(crossing, approach)
	reaction = CrossingReaction.reaction_to(
		cat_segment,
		{ along: crossing.along.minus(gap), speed: rider_speed },
	)
	[
		ScrubWidget.stage_text(Cat.crossing_stage(approach)),
		"Pose: ${pose_name(instant.pose)}",
		"Gap: ${ScrubWidget.tenths_text(gap.to_metres())} m",
		throttle_text(reaction.throttle),
	]
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

expect crossing_stretch.from.to_f64() < crossing_stretch.to.to_f64()

expect
	status_lines(Distance.metres(50.0))
		== [
			"Waiting",
			"Pose: Rest",
			"Gap: 50.0 m",
			"The rider may accelerate",
		]

expect
	status_lines(Distance.metres(21.0))
		== [
			"Playing: 52%",
			"Pose: Frozen",
			"Gap: 21.0 m",
			"The rider may not accelerate",
		]

expect
	status_lines(Distance.metres(1.5))
		== [
			"Past",
			"Pose: Collapse",
			"Gap: 1.5 m",
			"The rider may accelerate",
		]
