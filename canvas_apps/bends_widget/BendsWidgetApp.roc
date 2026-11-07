## The widget for the Safari tutorial's chapter on the road: a still picture of
## three bends side by side, with no controls. Each is a two-segment road seen
## from above, with the rider's way up the picture. The paving and the guard rail
## come from GroundSighting and RailSighting, and the apex from BendInView's outer
## corner, and the lines under each bend read out what those three say of it.
import game.Across
import game.Along
import game.Angle
import game.Distance
import game.RoadAhead
import game.Route
import game.SegmentPlace
import game.Geom
import game.GroundSighting
import game.BendInView
import game.RailSighting
import game.World
import lib.Brush
import lib.RgbColor
import lib.CanvasApp
import lib.Shapes
import widget.PlanView
import widget.ReadoutText
import widget.WidgetPage

BendsWidgetApp :: [].{

	## A still picture has no state.
	Model : {}

	canvas_app : CanvasApp.CanvasApp(BendsWidgetApp.Model)
	canvas_app = WidgetPage.still_app({ title: "Three bends in the road", shapes: still_shapes })
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

## A route of two segments of the route, cut to length, with `turn` between.
two_segments : Angle.Turn -> Route
two_segments = |turn|
	Route.from_segments(
		World.route.route_segments().take_first(2).map_with_index(
			|segment, index| {
				..segment,
				length: segment_length,
				ending: if index == 0 {
					Bends({ turn, bend_life: Quiet })
				} else {
					RouteEnds
				},
			},
		),
	)

## The road ahead of a rider on the first segment.
road_with : Angle.Turn -> RoadAhead.RoadView
road_with = |turn| RoadAhead.RoadView.ahead_of(two_segments(turn), Route.SegmentIndex.first)

## The camera the road is seen from, on the first segment, looking along it.
camera : { vantage : Geom.Vantage }
camera = {
	vantage: {
		along: Along.at(segment_length.minus(rider_before_bend)),
		across: Across.middle,
		yaw: Angle.straight_ahead,
	},
}

## The one bend on that road.
bend_of : RoadAhead.RoadView -> BendInView
bend_of = |road|
	BendInView.of_in_view(RoadAhead.segment_in_view_at(road, SegmentPlace.Position.first))

## The apex of a bend of `turn`, as the camera sees it.
apex_of : Angle.Turn -> Geom.RiderPoint
apex_of = |turn| {
	road = road_with(turn)
	bend_in_view = bend_of(road)
	RoadAhead.rider_point_at(
		road,
		{
			vantage: camera.vantage,
			place: bend_in_view.place_before(),
			road_point: bend_in_view.outer_corner().apex,
		},
	)
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
	plan : PlanView
	plan = { origin: { x: canvas_x, y: rider_y }, pixels_a_metre }
	plan.canvas_point({ metres_right: right.to_metres(), metres_down: 0.0 - forward.to_metres() })
}

rail_color : RgbColor
rail_color = RgbColor.of(0xe8805a)

apex_color : RgbColor
apex_color = RgbColor.of(0xf0d040)

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
		fill: Brush.flat(PlanView.road_color),
	})

## The low edge of a rail's quad, which lies along the ground.
foot_shape : ShownBend, { low_start : Geom.RaisedPoint, low_end : Geom.RaisedPoint, .. } -> Shapes.Shape
foot_shape = |bend, { low_start, low_end, .. }| {
	from = canvas_point(bend, { right: low_start.right, forward: low_start.forward })
	to = canvas_point(bend, { right: low_end.right, forward: low_end.forward })
	Shapes.line({ from, to, width: 2.0 }, Brush.flat(rail_color))
}

## A disc at a place on the road.
spot : ShownBend, { at : Geom.RiderPoint, color : RgbColor } -> Shapes.Shape
spot = |bend, { at, color }| {
	{ x, y } = canvas_point(bend, at)
	Disc({
		x,
		y,
		radius: 4.0,
		fill: Brush.flat(color),
	})
}

## One bend from above: what GroundSighting and RailSighting say of it, the apex
## BendInView finds, and where the view is from.
bend_shapes : ShownBend -> List(Shapes.Shape)
bend_shapes = |bend| {
	road = road_with(bend.turn)
	[
		GroundSighting.patches_in_view(road, camera).map(|patch| patch_shape(bend, patch.corners())),
		RailSighting.rail_quads_in_view(road, camera).map(|rail| foot_shape(bend, rail.corners)),
		[
			spot(bend, { at: apex_of(bend.turn), color: apex_color }),
			spot(bend, { at: rider, color: PlanView.standout_color }),
		],
	].join()
}

## Which edge a bend's outer edge is, in words.
edge_text : BendInView -> Str
edge_text = |bend_in_view|
	match Geom.outer_side(bend_in_view.turn()) {
		LeftSide => "left"
		RightSide => "right"
	}

## How far past the end of the segment before `bend_in_view` its apex lies.
apex_past_end : BendInView -> F64
apex_past_end = |bend_in_view| {
	corner = bend_in_view.outer_corner()
	corner.apex.along.distance_from(corner.end_before.along).to_metres()
}

## What the three modules say of a bend, a line each.
caption_lines : Angle.Turn -> List(Str)
caption_lines = |turn| {
	road = road_with(turn)
	[
		ReadoutText.turn_text(turn),
		"rail on the ${edge_text(bend_of(road))} edge",
		"apex ${ReadoutText.tenths_text(apex_past_end(bend_of(road)))} m past the end",
		"${GroundSighting.patches_in_view(road, camera).len().to_str()} patches, ${RailSighting.rail_quads_in_view(road, camera).len().to_str()} rail pieces",
	]
}

## A line of a caption, centered under its bend, on row `row` of the panel.
caption_line : ShownBend, { text : Str, row : U64 } -> Shapes.Shape
caption_line = |bend, { text, row }|
	WidgetPage.readout({
		text,
		color: WidgetPage.ink_color,
		row,
		style: {
			..WidgetPage.panel_readout,
			x: bend.canvas_x,
			first_baseline: 246.0,
			size: 13.0,
			align: Center,
		},
	})

caption_shapes : ShownBend -> List(Shapes.Shape)
caption_shapes = |bend|
	caption_lines(bend.turn).map_with_index(|text, row| caption_line(bend, { text, row }))

still_shapes : List(Shapes.Shape)
still_shapes = {
	picture_shapes = [WidgetPage.picture_backdrop(PlanView.ground_color)].concat(shown_bends.join_map(bend_shapes))
	WidgetPage.frame_shapes({ picture_shapes, status_lines: [] }).concat(shown_bends.join_map(caption_shapes))
}

# The captions read what the modules say, and the middle bend has the book's
# numbers.
expect
	caption_lines(right_bend.turn)
		== [
			"45 deg right",
			"rail on the left edge",
			"apex 1.7 m past the end",
			"3 patches, 49 rail pieces",
		]

# The sharp bend is on the route, and nothing on the route is sharper.
expect World.bending_plans.any(|plan| plan.turn == sharp_bend.turn)
expect World.bending_plans.all(|plan| plan.turn.abs() <= sharp_bend.turn)

# Each bend's rider and apex are in the picture, in the bend's own third.
expect
	shown_bends.all(
		|bend| {
			apex = canvas_point(bend, apex_of(bend.turn))
			rider_on_canvas = canvas_point(bend, rider)
			third = WidgetPage.canvas_width / 3.0
			(apex.x - bend.canvas_x).abs() < third / 2.0
				and apex.y > 0.0
				and rider_on_canvas.y < WidgetPage.picture_bottom_y
		},
	)

# The captions go down last, so they show over the panel.
expect still_shapes.ends_with(shown_bends.join_map(caption_shapes))
