## The widget for the Safari tutorial's chapter on the road: a still picture of
## three bends side by side, with no controls. Each is a two-segment road seen
## from above, with the rider's way up the picture. The paving and the guard rail
## come from GroundSighting and RailSighting, and the apex from BendView, and the
## lines under each bend read out what those three say of it.
import game.Across
import game.Along
import game.Angle
import game.Distance
import game.RoadAhead
import game.SegmentPlace
import game.Geom
import game.GroundSighting
import game.BendView
import game.RailSighting
import game.World
import lib.Brush
import lib.RgbColor
import lib.CanvasApp
import lib.Shapes
import widget.ReadoutText
import widget.ScrubWidget

BendsWidgetApp :: [].{

	## A still picture has no state.
	Model : {}

	canvas_app : CanvasApp.CanvasApp(BendsWidgetApp.Model)
	canvas_app = ScrubWidget.canvas_app({
		title: "Three bends in the road",
		init: {},
		model_at_next_step: |model, _input| model,
		frame_shapes: |_model| still_shapes,
	})
}

## A bend in the picture: how far it turns, and the x on the canvas of the
## middle of its third.
ShownBend : { turn : Angle.Turn, canvas_x : F64 }

## The bend the book works through, turned the other way, to show the rail swap
## sides.
left_bend : ShownBend
left_bend = { turn: Angle.Turn.degrees(-45.0), canvas_x: 107.0 }

## The bend whose numbers the book works through.
right_bend : ShownBend
right_bend = { turn: Angle.Turn.degrees(45.0), canvas_x: 320.0 }

## The sharpest bend on the route, whose apex lies furthest out.
sharp_bend : ShownBend
sharp_bend = { turn: Angle.Turn.degrees(80.0), canvas_x: 533.0 }

shown_bends : List(ShownBend)
shown_bends = [left_bend, right_bend, sharp_bend]

## How long each of the two segments is.
segment_length : Distance
segment_length = Distance.metres(60.0)

## How far before the bend the view is taken from.
rider_before_bend : Distance
rider_before_bend = Distance.metres(25.0)

## Two segments of the route, cut to length, with `turn` between.
two_segments : Angle.Turn -> List(World.Segment)
two_segments = |turn|
	World.segments.take_first(2).map_with_index(
		|segment, index| {
			..segment,
			length: segment_length,
			exit_turn: if index == 0 {
				turn
			} else {
				Angle.Turn.degrees(0.0)
			},
		},
	)

## The road as seen from the first segment, looking along it.
road_with : Angle.Turn -> RoadAhead.RoadView
road_with = |turn| {
	route_segments: two_segments(turn),
	segments_ahead: [World.SegmentIndex.number(0), World.SegmentIndex.number(1)],
	vantage: {
		along: Along.at(segment_length.minus(rider_before_bend)),
		across: Across.middle,
		yaw: Angle.straight_ahead,
	},
}

## The one bend on that road.
bend_of : RoadAhead.RoadView -> BendView
bend_of = |road|
	BendView.of_segment(
		RoadAhead.segment_at(road, SegmentPlace.Position.first),
		Ahead(SegmentPlace.Position.first),
	)

## The apex of a bend of `turn`.
apex_of : Angle.Turn -> Geom.RiderPoint
apex_of = |turn| {
	road = road_with(turn)
	BendView.apex(road, bend_of(road))
}

## Where the view is from, and so where every point is measured from.
rider : Geom.RiderPoint
rider = { right: Distance.zero, forward: Distance.zero }

## How many pixels a metre takes up.
pixels_a_metre : F64
pixels_a_metre = 5.0

## Where the rider sits on the canvas, near the foot of the picture.
rider_y : F64
rider_y = 198.0

## Where `point` falls on the canvas. The rider faces up the picture, so the
## rider's right is the reader's right.
canvas_point : ShownBend, Geom.RiderPoint -> { x : F64, y : F64 }
canvas_point = |{ canvas_x, .. }, { right, forward }| {
	x: canvas_x + right.to_metres() * pixels_a_metre,
	y: rider_y - forward.to_metres() * pixels_a_metre,
}

ground_color : RgbColor
ground_color = RgbColor.of(0x6f9a55)

road_color : RgbColor
road_color = RgbColor.of(0x4a4a46)

rail_color : RgbColor
rail_color = RgbColor.of(0xe8805a)

apex_color : RgbColor
apex_color = RgbColor.of(0xf0d040)

rider_color : RgbColor
rider_color = RgbColor.of(0xf2efe4)

ground : Shapes.Shape
ground = Rect({
	x: 0.0,
	y: 0.0,
	width: ScrubWidget.canvas_width,
	height: ScrubWidget.picture_bottom_y,
	fill: ScrubWidget.flat(ground_color),
})

## A patch of paving, as a polygon on the canvas.
patch_shape : ShownBend, List(Geom.RiderPoint) -> Shapes.Shape
patch_shape = |bend, corners|
	Poly({
		coordinates: corners.join_map(
			|corner| {
				{ x, y } = canvas_point(bend, corner)
				[x, y]
			},
		),
		fill: ScrubWidget.flat(road_color),
	})

## The first two corners of a rail's quad, which lie along the ground.
foot_shapes : ShownBend, List(Geom.RaisedPoint) -> List(Shapes.Shape)
foot_shapes = |bend, corners|
	match corners {
		[a, b, ..] => {
			from = canvas_point(bend, { right: a.right, forward: a.forward })
			to = canvas_point(bend, { right: b.right, forward: b.forward })
			[
				Shapes.line({ from, to, width: 2.0 }, ScrubWidget.flat(rail_color)),
			]
		}
		_ => []
	}

## A disc at a place on the road.
spot : ShownBend, { at : Geom.RiderPoint, color : RgbColor } -> Shapes.Shape
spot = |bend, { at, color }| {
	{ x, y } = canvas_point(bend, at)
	Disc({
		x,
		y,
		radius: 4.0,
		fill: ScrubWidget.flat(color),
	})
}

## One bend from above: what GroundSighting and RailSighting say of it, the apex
## BendView finds, and where the view is from.
bend_shapes : ShownBend -> List(Shapes.Shape)
bend_shapes = |bend| {
	road = road_with(bend.turn)
	[
		GroundSighting.patches_in_view(road).map(|patch| patch_shape(bend, patch.corners)),
		RailSighting.rails_in_view(road).join_map(|rail| foot_shapes(bend, rail.corners)),
		[
			spot(bend, { at: apex_of(bend.turn), color: apex_color }),
			spot(bend, { at: rider, color: rider_color }),
		],
	].join()
}

## A whole number of degrees and which way.
turn_text : Angle.Turn -> Str
turn_text = |turn| {
	degrees = turn.abs().portion(Angle.Turn.degrees(1.0))
	side = if turn.is_right() {
		"right"
	} else {
		"left"
	}
	"${(degrees + 0.5).to_i64_wrap().to_str()} deg ${side}"
}

## Which edge a bend's outer edge is, in words.
edge_text : Angle.Turn -> Str
edge_text = |turn|
	if BendView.outer_edge(turn) == Geom.left_edge {
		"left"
	} else {
		"right"
	}

## How far past the end of the first segment the apex lies.
apex_past_end : Geom.RiderPoint -> F64
apex_past_end = |apex| apex.forward.minus(rider_before_bend).to_metres()

## What the three modules say of a bend, a line each.
caption_lines : Angle.Turn -> List(Str)
caption_lines = |turn| {
	road = road_with(turn)
	[
		turn_text(turn),
		"rail on the ${edge_text(turn)} edge",
		"apex ${ReadoutText.tenths_text(apex_past_end(apex_of(turn)))} m past the end",
		"${GroundSighting.patches_in_view(road).len().to_str()} patches, ${RailSighting.rails_in_view(road).len().to_str()} rail pieces",
	]
}

## A line of a caption, centered under its bend, on row `row` of the panel.
caption_line : ShownBend, { text : Str, row : U64 } -> Shapes.Shape
caption_line = |bend, { text, row }|
	Text({
		text,
		x: bend.canvas_x,
		y: 246.0 + row.to_f64() * 26.0,
		size: 13.0,
		face: Code,
		align: Center,
		color: Brush.opaque(RgbColor.of(0x202020)),
	})

caption_shapes : ShownBend -> List(Shapes.Shape)
caption_shapes = |bend|
	caption_lines(bend.turn).map_with_index(|text, row| caption_line(bend, { text, row }))

still_shapes : List(Shapes.Shape)
still_shapes = {
	picture_shapes = [ground].concat(shown_bends.join_map(bend_shapes))
	ScrubWidget.frame_shapes({ picture_shapes, status_lines: [] }).concat(shown_bends.join_map(caption_shapes))
}

# The captions read what the modules say: the rail swaps sides with the turn, the
# apex goes out as the turn sharpens, and the middle bend has the book's numbers.
expect
	caption_lines(left_bend.turn)
		== [
			"45 deg left",
			"rail on the right edge",
			"apex 1.7 m past the end",
			"8 patches, 49 rail pieces",
		]
expect
	caption_lines(right_bend.turn)
		== [
			"45 deg right",
			"rail on the left edge",
			"apex 1.7 m past the end",
			"8 patches, 49 rail pieces",
		]
expect
	caption_lines(sharp_bend.turn)
		== [
			"80 deg right",
			"rail on the left edge",
			"apex 3.4 m past the end",
			"8 patches, 53 rail pieces",
		]

# The sharp bend is on the route, and nothing on the route is sharper.
expect World.plans.any(|plan| plan.turn == sharp_bend.turn)
expect World.plans.all(|plan| plan.turn.abs() <= sharp_bend.turn)

# The apex lies on the outer edge carried straight on, on either side.
expect (apex_of(left_bend.turn).right.to_metres() - Geom.right_edge.to_metres()).abs() < 0.000001
expect (apex_of(right_bend.turn).right.to_metres() - Geom.left_edge.to_metres()).abs() < 0.000001

# Each bend's rider and apex are in the picture, in the bend's own third.
expect
	shown_bends.all(
		|bend| {
			apex = canvas_point(bend, apex_of(bend.turn))
			rider_on_canvas = canvas_point(bend, rider)
			third = ScrubWidget.canvas_width / 3.0
			(apex.x - bend.canvas_x).abs() < third / 2.0
				and apex.y > 0.0
				and rider_on_canvas.y < ScrubWidget.picture_bottom_y
		},
	)

# The captions go down last, so they show over the panel.
expect still_shapes.ends_with(shown_bends.join_map(caption_shapes))
