## The widget for the Safari tutorial's chapter on the road. Dragging across the
## canvas sets how far one bend turns, from hard left to hard right. The paving
## and the guard rail come from GroundSighting and RailSighting, asked about a
## two-segment road with that bend in it, and they're drawn from above. The rail
## swaps sides as the bend does, because it follows the outer edge.
import game.Across
import game.Along
import game.Angle
import game.Distance
import game.Fraction
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

BendsWidgetApp :: [].{

	## The whole state of the widget: how far the bend turns, in degrees,
	## positive to the right.
	Model : { degrees : F64 }

	canvas_app : CanvasApp.CanvasApp(BendsWidgetApp.Model)
	canvas_app = ScrubWidget.canvas_app({
		title: "A bend in the road",
		init: { degrees: 50.0 },
		model_at: |share| { degrees: degrees_at(share) },
		frame: |model| frame_at(model.degrees),
	})
}

## The ruler runs from this far left to this far right. The route's sharpest
## bend is 80 degrees.
widest_turn : F64
widest_turn = 80.0

## The gentlest bend on the ruler. Two edges that don't turn at all never meet,
## so a road with no bend has no apex.
gentlest_turn : F64
gentlest_turn = 5.0

## The turn with the pointer `share` of the way along the ruler.
degrees_at : Fraction -> F64
degrees_at = |share| {
	degrees = (share.to_f64() - 0.5) * 2.0 * widest_turn
	if degrees >= 0.0 {
		degrees.max(gentlest_turn)
	} else {
		degrees.min(-gentlest_turn)
	}
}

## How far along the ruler a turn of `degrees` sits.
share_of : F64 -> Fraction
share_of = |degrees| Fraction.clamp(degrees / (2.0 * widest_turn) + 0.5)

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
		{
			before: InChain(Chain.Position.first),
			after: InChain(Chain.Position.first.next()),
		},
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

## Where the route's own bends sit on the ruler.
route_marks : List(ScrubWidget.Stretch)
route_marks =
	World.plans.keep_if(|plan| plan.turn.to_radians().abs() > 0.0).map(
		|plan| {
			centre = share_of(plan.turn.to_radians() / Trig.deg).to_f64()
			{
				from: Fraction.clamp(centre - 0.004),
				to: Fraction.clamp(centre + 0.004),
			}
		},
	)

## Everything on the canvas at a turn of `degrees`.
frame_at : F64 -> List(Shapes.Shape)
frame_at = |degrees|
	ScrubWidget.frame_shapes({
		picture: picture(degrees),
		dot_at: share_of(degrees),
		marked: route_marks,
		status: status_lines(degrees),
	})

# The ruler reaches both ends, and steps over the bend that has no apex.
expect degrees_at(Fraction.zero) == -widest_turn
expect degrees_at(Fraction.whole) == widest_turn
expect degrees_at(Fraction.of(0.5)) == gentlest_turn
expect degrees_at(Fraction.of(0.49)) == -gentlest_turn
expect degrees_at(Fraction.of(0.75)) == 40.0

expect share_of(-widest_turn) == Fraction.zero
expect share_of(widest_turn) == Fraction.whole

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

# The bend's paving and its rail are both there, at both ends of the ruler.
expect GroundSighting.in_view(road_with(widest_turn)).len() > 2
expect GroundSighting.in_view(road_with(-widest_turn)).len() > 2
expect RailSighting.in_view(road_with(widest_turn)).len() > 0
expect RailSighting.in_view(road_with(-widest_turn)).len() > 0

expect turn_text(50.0) == "50 deg right"
expect turn_text(-50.0) == "50 deg left"

expect apex_text({ right: Distance.metres(-2.0), forward: Distance.metres(27.5) }) == "Apex: 2.5 m past the segment end"

# Each of the route's bends gets a mark.
expect route_marks.len() == World.plans.len() - 1

expect picture(50.0) == picture(50.0)
expect picture(50.0) != picture(51.0)
