## The widget for the Safari tutorial's chapter on the cat. Video recorder buttons
## run how far the rider is from the cat, and each frame is worked out from that
## gap alone, so the crossing plays forward and backward. The picture looks down
## the road at the cat, with the road's width to scale. Below it, the buttons and
## four lines of text that say what Cat and EncounterReaction make of the gap.
import game.Cat
import game.CatCrossing
import game.EncounterReaction
import game.Distance
import game.Pixels
import game.PosedCat
import game.Geom
import game.Segment
import game.Speed
import game.StillShapes
import game.VehicleLimits
import game.World
import lib.Brush
import lib.CanvasApp
import lib.RgbColor
import lib.Shapes
import widget.ReadoutText
import widget.ScrubWidget
import widget.VcrButtons

CatWidgetApp :: [].{

	## The whole state of the widget: the buttons, which hold the gap from the
	## rider to the cat.
	Model : VcrButtons.Transport(Distance)

	canvas_app : CanvasApp.CanvasApp(CatWidgetApp.Model)
	canvas_app = VcrButtons.canvas_app({
		title: "The cat crossing",
		range: closing_gap,
		opens_at: closing_gap.first,
		frame_shapes: shapes_at,
	})
}

## The rider's approach, in about seven seconds.
closing_gap : VcrButtons.NumberRange(Distance)
closing_gap = VcrButtons.gap_range({ farthest: Distance.metres(50.0), metres_a_frame: 0.125 })

## A typical speed on the ride. At one metre a step, a step of the buttons is a
## step of the ride, and the crossing's steps read as metres.
rider_speed : Speed
rider_speed = Speed.metres_a_step(1.0)

## The cat's crossing on a segment that has one.
cat_crossing : Segment -> Try(CatCrossing, [NoCat])
cat_crossing = |segment|
	match segment.encounter {
		CatCrosses(crossing) => Ok(crossing)
		BirdHere(_) | QuietRoad => Err(NoCat)
	}

## The first segment of the route with a cat.
cat_segment : Segment
cat_segment =
	World.route.route_segments().find_first(|segment| cat_crossing(segment).is_ok())
		?? crash "CatWidgetApp.cat_segment: the route has cats"

crossing : CatCrossing
crossing = cat_crossing(cat_segment) ?? crash "CatWidgetApp.crossing: this segment has a cat"

## Everything on the canvas.
shapes_at : CatWidgetApp.Model -> List(Shapes.Shape)
shapes_at = |transport|
	VcrButtons.frame_shapes(
		transport,
		{
			range: closing_gap,
			picture_shapes: road_shapes.concat(cat_shapes(transport.at)),
			status_lines: status_lines(transport.at),
		},
	)

## How many pixels a metre across the road takes up.
pixels_a_metre : F64
pixels_a_metre = 48.0

## Where the middle of the road is, on screen.
road_middle_x : F64
road_middle_x = 290.0

ground_top_y : F64
ground_top_y = 150.0

ground_bottom_y : F64
ground_bottom_y = 215.0

## The line the cat's feet stand on.
feet_y : F64
feet_y = 190.0

## The sky, the grass, and the road between the verges.
road_shapes : List(Shapes.Shape)
road_shapes = {
	road_width_px = Geom.road_half_width.to_metres() * 2.0 * pixels_a_metre
	ground_height = ground_bottom_y - ground_top_y
	[
		Rect({
			x: 0.0,
			y: 0.0,
			width: ScrubWidget.canvas_width,
			height: ScrubWidget.picture_bottom_y,
			fill: Brush.flat(RgbColor.of(0xdcecf5)),
		}),
		Rect({
			x: 0.0,
			y: ground_top_y,
			width: ScrubWidget.canvas_width,
			height: ground_height,
			fill: Brush.flat(RgbColor.of(0x7fa650)),
		}),
		Rect({
			x: road_middle_x - road_width_px / 2.0,
			y: ground_top_y,
			width: road_width_px,
			height: ground_height,
			fill: Brush.flat(RgbColor.of(0x8a8a8a)),
		}),
	]
}

## The cat as `gap` finds it, drawn by Safari's own stills.
cat_shapes : Distance -> List(Shapes.Shape)
cat_shapes = |gap| {
	instant = Cat.instant_at(crossing, { gap, speed: rider_speed })
	StillShapes.still_shapes(
		{
			feet: {
				x: Pixels.of(road_middle_x + instant.location.across.to_metres() * pixels_a_metre),
				y: Pixels.of(feet_y - instant.location.lift.to_metres() * pixels_a_metre),
			},
			flip: AsDrawn,
			height_on_screen: Pixels.of(PosedCat.cat_height.to_metres() * pixels_a_metre),
		},
		PosedCat.pose_polygons(instant.pose),
	)
}

## What the crossing and the rider's reaction to it are at `gap`, a line each.
status_lines : Distance -> List(Str)
status_lines = |gap| {
	approach = { gap, speed: rider_speed }
	instant = Cat.instant_at(crossing, approach)
	throttle = EncounterReaction.encounter_throttle(
		cat_segment,
		{ along: crossing.along.minus(gap), speed: rider_speed },
	)
	[
		ReadoutText.stage_text(Cat.crossing_stage(approach)),
		"Pose: ${pose_name(instant.pose)}",
		"Gap: ${ReadoutText.tenths_text(gap.to_metres())} m",
		throttle_text(throttle),
	]
}

pose_name : PosedCat.CatPose -> Str
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

## What the crossing asks of the throttle, in words. A crossing only ever holds
## the acceleration at none.
throttle_text : VehicleLimits.Limit -> Str
throttle_text = |throttle|
	match throttle {
		NoLimit => "The rider may accelerate"
		AtMost(_) => "The rider may not accelerate"
	}

# The whole crossing is on the range, with some road to spare at the far end.
expect Cat.clear_gap.plus(rider_speed.distance_in(Cat.crossing_steps)) < closing_gap.first
expect Cat.clear_gap > closing_gap.last

expect
	status_lines(Distance.metres(50.0))
		== ["Waiting", "Pose: Rest", "Gap: 50.0 m", "The rider may accelerate"]

expect
	status_lines(Distance.metres(1.5))
		== ["Past", "Pose: Collapse", "Gap: 1.5 m", "The rider may accelerate"]
