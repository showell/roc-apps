## The widget for the Safari tutorial's chapter on the cat. Video recorder buttons
## run how far the rider is from the cat, coming at a metre a step, and each frame
## is worked out from that gap alone: the step of the ride it is, and the start the
## ride plans for the crossing, so the crossing plays forward and backward. The
## picture looks down the road at the cat, with the road's width to scale. Below
## it, the buttons and four lines of text that say what Cat and EncounterReaction
## make of the gap.
import game.EncounterPlan
import game.Cat
import game.EncounterReaction
import game.Distance
import game.Pixels
import game.PosedCat
import game.Geom
import game.Speed
import game.StillShapes
import game.VehicleLimits
import game.World
import lib.Brush
import lib.CanvasApp
import lib.RgbColor
import lib.Shapes
import widget.ReadoutText
import widget.WidgetPage
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

## Everything on the canvas.
shapes_at : CatWidgetApp.Model -> List(Shapes.Shape)
shapes_at = |transport| {
	gap = transport.at
	timing = crossing_timing(gap)
	VcrButtons.frame_shapes(
		transport,
		{
			range: closing_gap,
			picture_shapes: road_shapes.concat(cat_shapes(timing)),
			status_lines: status_lines({ gap, timing }),
		},
	)
}

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
	road_width = Geom.road_half_width.to_metres() * 2.0 * pixels_a_metre
	ground_height = ground_bottom_y - ground_top_y
	[
		Rect({
			x: 0.0,
			y: 0.0,
			width: WidgetPage.canvas_width,
			height: WidgetPage.picture_bottom_y,
			fill: Brush.flat(WidgetPage.panel_color),
		}),
		Rect({
			x: 0.0,
			y: ground_top_y,
			width: WidgetPage.canvas_width,
			height: ground_height,
			fill: Brush.flat(RgbColor.of(0x7fa650)),
		}),
		Rect({
			x: road_middle_x - road_width / 2.0,
			y: ground_top_y,
			width: road_width,
			height: ground_height,
			fill: Brush.flat(WidgetPage.side_road_color),
		}),
	]
}

## The crossing's timing with the rider `gap` short of the cat.
crossing_timing : Distance -> EncounterPlan.Timing
crossing_timing = |gap|
	EncounterPlan.steady_approach_timing(
		Cat.crossing_span,
		{ gap_at_start: closing_gap.first, speed: rider_speed, gap },
	)

## The cat at the crossing's `timing`, drawn by Safari's own stills.
cat_shapes : EncounterPlan.Timing -> List(Shapes.Shape)
cat_shapes = |timing| {
	instant = Cat.instant_at(World.first_cat_crossing, Cat.crossing_stage(timing))
	StillShapes.still_shapes(
		{
			foot: {
				x: Pixels.of(road_middle_x + instant.location.across.to_metres() * pixels_a_metre),
				y: Pixels.of(feet_y - instant.location.lift.to_metres() * pixels_a_metre),
			},
			flip: AsDrawn,
			height_on_screen: Pixels.of(PosedCat.cat_height.to_metres() * pixels_a_metre),
		},
		PosedCat.pose_still(instant.pose),
	)
}

## What the crossing and the rider's reaction to it are at `gap`, with the
## crossing at `timing`, a line each.
status_lines : { gap : Distance, timing : EncounterPlan.Timing } -> List(Str)
status_lines = |{ gap, timing }| {
	stage = Cat.crossing_stage(timing)
	instant = Cat.instant_at(World.first_cat_crossing, stage)
	throttle = EncounterReaction.encounter_throttle(World.first_cat_segment, timing)
	[
		ReadoutText.stage_text(stage),
		"Pose: ${ReadoutText.cat_pose_text(instant.pose)}",
		"Gap: ${ReadoutText.tenths_text(gap.to_metres())} m",
		throttle_text(throttle),
	]
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
expect EncounterPlan.planning_gap(Cat.crossing_span, rider_speed) < closing_gap.first
expect Cat.crossing_span.ends_at > closing_gap.last

## The lines at `gap`, with the crossing timed as the widget times it.
lines_at : Distance -> List(Str)
lines_at = |gap| status_lines({ gap, timing: crossing_timing(gap) })

expect
	lines_at(Distance.metres(50.0))
		== ["Waiting", "Pose: Rest", "Gap: 50.0 m", "The rider may accelerate"]

expect
	lines_at(Distance.metres(1.5))
		== ["Past", "Pose: Collapse", "Gap: 1.5 m", "The rider may accelerate"]

# The crossing starts 41 m short of the cat, 3 m for the gap it ends at and 38
# for its steps, and plays a frame a metre.
expect
	lines_at(Distance.metres(41.0))
		== ["Playing: frame 1", "Pose: Stride", "Gap: 41.0 m", "The rider may not accelerate"]
expect
	lines_at(Distance.metres(41.125))
		== ["Waiting", "Pose: Rest", "Gap: 41.1 m", "The rider may accelerate"]
expect
	lines_at(Distance.metres(3.5))
		== ["Playing: frame 38", "Pose: Land", "Gap: 3.5 m", "The rider may not accelerate"]
expect
	lines_at(Distance.metres(3.0))
		== ["Past", "Pose: Collapse", "Gap: 3.0 m", "The rider may accelerate"]
