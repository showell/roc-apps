## The widget for the Safari tutorial's chapter on the road. Video recorder
## buttons turn one bend, from hard left to hard right. The paving and the guard
## rail come from GroundSighting and RailSighting, asked about a two-segment road
## with that bend in it, and they're drawn from above. The rail swaps sides as the
## bend does, because it follows the outer edge.
import game.Across
import game.Along
import game.Angle
import game.Distance
import game.Chain
import game.Geom
import game.GroundSighting
import game.BendView
import game.RailSighting
import game.Scenery
import game.World
import lib.CanvasApp
import lib.Shapes
import lib.Trig
import widget.ScrubWidget
import widget.VcrButtons

BendsWidgetApp :: [].{

	## The whole state of the widget: the buttons, which hold how far the bend
	## turns, in degrees, positive to the right.
	Model : VcrButtons.Transport(F64)

	canvas_app : CanvasApp.CanvasApp(BendsWidgetApp.Model)
	canvas_app = VcrButtons.canvas_app({
		title: "A bend in the road",
		range: turning,
		opens_at: 50.0,
		frame: frame_at,
	})
}

## The buttons range from this far left to this far right. The route's sharpest bend
## is 80 degrees.
widest_turn : F64
widest_turn = 80.0

## The gentlest bend. Two edges that don't turn at all never meet, so a road with
## no bend has no apex.
gentlest_turn : F64
gentlest_turn = 5.0

## The turn from hard left to hard right in five seconds. A step is five degrees,
## so the steps stop on every bend of the route.
turning : VcrButtons.NumberRange(F64)
turning = {
	first: -widest_turn,
	last: widest_turn,
	place_of: place_of_turn,
	number_at: turn_at,
	one_step: 5.0,
	playing: Plays(0.5),
}

## How far along the turning a turn of `degrees` is. The range closes the gap around
## straight, so it goes from just left of the gentlest turn left to the gentlest
## turn right.
place_of_turn : F64 -> F64
place_of_turn = |degrees|
	if degrees < 0.0 {
		degrees + gentlest_turn
	} else {
		degrees - gentlest_turn
	}

## The turn at a place along the turning.
turn_at : F64 -> F64
turn_at = |place|
	if place < 0.0 {
		place - gentlest_turn
	} else {
		place + gentlest_turn
	}

## How long each of the two segments is.
segment_length : Distance
segment_length = Distance.metres(60.0)

## How far before the bend the view is taken from.
rider_before_bend : Distance
rider_before_bend = Distance.metres(25.0)

## Two segments of the route, cut to length, with a bend of `degrees` between.
two_segments : F64 -> List(World.Segment)
two_segments = |degrees|
	World.segments.take_first(2).map_with_index(
		|segment, index| {
			..segment,
			length: segment_length,
			exit_turn: if index == 0 {
				Angle.Turn.degrees(degrees)
			} else {
				Angle.Turn.degrees(0.0)
			},
		},
	)

## The road as seen from the first segment, looking along it.
road_with : F64 -> Chain.RoadView
road_with = |degrees| {
	route: two_segments(degrees),
	chain: [World.SegmentIndex.number(0), World.SegmentIndex.number(1)],
	vantage: {
		along: Along.at(segment_length.minus(rider_before_bend)),
		across: Across.middle,
		yaw: Angle.straight_ahead,
		half_width: Scenery.road_half_width,
	},
}

## The one bend on that road.
bend_of : Chain.RoadView -> BendView
bend_of = |road|
	BendView.of_segment(
		Chain.Position.first.index_in(road.chain).segment_in(road.route),
		{ before: InChain(Chain.Position.first), after: InChain(Chain.Position.first.next()) },
	)

## How many pixels a metre takes up.
pixels_a_metre : F64
pixels_a_metre = 11.0

## Where the rider sits on the canvas.
rider_x : F64
rider_x = 40.0

## The road runs left to right from above, so the rider's right is down.
canvas_x : Geom.RiderPoint -> F64
canvas_x = |{ forward, .. }| rider_x + forward.to_metres() * pixels_a_metre

canvas_y : Geom.RiderPoint -> F64
canvas_y = |{ right, .. }| ScrubWidget.picture_bottom_y / 2.0 + right.to_metres() * pixels_a_metre

ground_color : I64
ground_color = 0x6f9a55

road_color : I64
road_color = 0x4a4a46

rail_color : I64
rail_color = 0xe8805a

apex_color : I64
apex_color = 0xf0d040

rider_color : I64
rider_color = 0xf2efe4

ground : Shapes.Shape
ground = Rect({
	x: 0.0,
	y: 0.0,
	w: ScrubWidget.canvas_width,
	h: ScrubWidget.picture_bottom_y,
	fill: ScrubWidget.flat(ground_color),
})

## A patch of paving, as a polygon on the canvas.
patch_shape : List(Geom.RiderPoint) -> Shapes.Shape
patch_shape = |corners|
	Poly({
		pts: corners.join_map(|corner| [canvas_x(corner), canvas_y(corner)]),
		fill: ScrubWidget.flat(road_color),
	})

## The first two corners of a rail's quad, which lie along the ground.
rail_foot : List(Geom.RaisedPoint) -> List(Shapes.Shape)
rail_foot = |corners|
	match corners {
		[a, b, ..] => {
			from = { right: a.right, forward: a.forward }
			to = { right: b.right, forward: b.forward }
			[
				Shapes.line(
					canvas_x(from),
					canvas_y(from),
					canvas_x(to),
					canvas_y(to),
					3.0,
					ScrubWidget.flat(rail_color),
				),
			]
		}
		_ => []
	}

## A disc at a place on the road.
spot : Geom.RiderPoint, { r : F64, color : I64 } -> Shapes.Shape
spot = |point, { r, color }|
	Disc({
		x: canvas_x(point),
		y: canvas_y(point),
		r,
		fill: ScrubWidget.flat(color),
		clip: Anywhere,
	})

## The bend from above: what GroundSighting and RailSighting say of it, the apex
## BendView finds, and where the view is from.
picture : F64 -> List(Shapes.Shape)
picture = |degrees| {
	road = road_with(degrees)
	[
		[ground],
		GroundSighting.in_view(road).map(|patch| patch_shape(patch.corners)),
		RailSighting.in_view(road).join_map(|rail| rail_foot(rail.corners)),
		[
			spot(BendView.apex(road, bend_of(road)), { r: 5.0, color: apex_color }),
			spot({ right: Distance.zero, forward: Distance.zero }, { r: 6.0, color: rider_color }),
		],
	].join()
}

## A whole number of degrees and which way.
turn_text : F64 -> Str
turn_text = |degrees|
	if degrees < 0.0 {
		"${(0.5 - degrees).to_i64_wrap().to_str()} deg left"
	} else {
		"${(degrees + 0.5).to_i64_wrap().to_str()} deg right"
	}

## Which edge a bend's outer edge is, in words.
edge_text : Angle.Turn -> Str
edge_text = |turn|
	if BendView.outer_edge(turn) == Scenery.left_edge {
		"left"
	} else {
		"right"
	}

## How far past the end of the first segment the apex lies.
apex_past_end : Geom.RiderPoint -> F64
apex_past_end = |apex| apex.forward.minus(rider_before_bend).to_metres()

## Where the apex lies, in words.
apex_text : Geom.RiderPoint -> Str
apex_text = |apex| "Apex: ${ScrubWidget.tenths_text(apex_past_end(apex))} m past the segment end"

## What the three modules say of this bend, a line each.
status_lines : F64 -> List(Str)
status_lines = |degrees| {
	road = road_with(degrees)
	bend = bend_of(road)
	[
		"Turn: ${turn_text(degrees)}",
		"Rail on the outer edge: ${edge_text(bend.turn)}",
		apex_text(BendView.apex(road, bend)),
		"${GroundSighting.in_view(road).len().to_str()} patches, ${RailSighting.in_view(road).len().to_str()} pieces of rail",
	]
}

## Everything on the canvas.
frame_at : BendsWidgetApp.Model -> List(Shapes.Shape)
frame_at = |transport|
	VcrButtons.frame_shapes(
		transport,
		{
			range: turning,
			picture: picture(transport.at),
			status: status_lines(transport.at),
		},
	)

## What a press of `control` does at a turn of `degrees`, after that frame.
turn_after_press : F64, VcrButtons.Control -> F64
turn_after_press = |degrees, control|
	VcrButtons.next_transport(
		VcrButtons.transport_at(degrees),
		{ input: VcrButtons.click_on(control, turning.playing), range: turning },
	).at

# The buttons reach both ends, and a step is five degrees.
expect turn_after_press(50.0, ToStart) == -widest_turn
expect turn_after_press(50.0, ToEnd) == widest_turn
expect turn_after_press(50.0, StepForward) == 55.0
expect turn_after_press(50.0, StepBack) == 45.0
expect turn_after_press(-50.0, StepForward) == -45.0
expect turn_after_press(-50.0, StepBack) == -55.0
expect turn_after_press(widest_turn, StepForward) == widest_turn
expect turn_after_press(-widest_turn, StepBack) == -widest_turn

# Steps and play go over the bend that has no apex, either way, and stop short of
# nothing else.
expect turn_after_press(-10.0, StepForward) == gentlest_turn
expect turn_after_press(gentlest_turn, StepBack) == -10.0
expect turn_after_press(-5.5, Play) == gentlest_turn
expect turn_after_press(gentlest_turn, PlayBack) == -5.5
expect turn_after_press(10.0, StepBack) == gentlest_turn

# A place and its turn are inverses on either side of straight.
expect [-80.0, -10.0, 5.0, 80.0].all(|degrees| turn_at(place_of_turn(degrees)) == degrees)

# A step stops on every bend of the route, from the buttons' left end.
expect
	World.plans.keep_if(|plan| plan.turn.to_radians().abs() > 0.0).all(
		|plan| {
			place = place_of_turn(plan.turn.to_radians() / Trig.deg)
			steps_from_left = (place - place_of_turn(-widest_turn)) / turning.one_step
			(steps_from_left - (steps_from_left + 0.5).to_i64_wrap().to_f64()).abs() < 0.000001
		},
	)

# The rail follows the outer edge, on either side.
expect edge_text(Angle.Turn.degrees(50.0)) == "left"
expect edge_text(Angle.Turn.degrees(-50.0)) == "right"

## The apex of a bend of `degrees`.
apex_of : F64 -> Geom.RiderPoint
apex_of = |degrees| {
	road = road_with(degrees)
	BendView.apex(road, bend_of(road))
}

# The apex lies on the outer edge carried straight on, on either side.
expect (apex_of(50.0).right.to_metres() - Scenery.left_edge.to_metres()).abs() < 0.000001
expect (apex_of(-50.0).right.to_metres() - Scenery.right_edge.to_metres()).abs() < 0.000001

# A sharper bend pushes the apex further past the segment's end.
expect apex_past_end(apex_of(20.0)) > 0.0
expect apex_past_end(apex_of(70.0)) > apex_past_end(apex_of(20.0))
expect apex_past_end(apex_of(-70.0)) > apex_past_end(apex_of(-20.0))

# The bend's paving and its rail are both there, at both ends of the turning.
expect GroundSighting.in_view(road_with(widest_turn)).len() > 2
expect GroundSighting.in_view(road_with(-widest_turn)).len() > 2
expect RailSighting.in_view(road_with(widest_turn)).len() > 0
expect RailSighting.in_view(road_with(-widest_turn)).len() > 0

expect turn_text(50.0) == "50 deg right"
expect turn_text(-50.0) == "50 deg left"

expect apex_text({
	right: Distance.metres(-2.0),
	forward: Distance.metres(27.5),
}) == "Apex: 2.5 m past the segment end"

expect picture(50.0) == picture(50.0)
expect picture(50.0) != picture(51.0)
