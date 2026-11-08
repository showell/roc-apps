## The widget for the Safari tutorial's chapter on what never changes: a still
## map of the whole route, with no controls. Each stretch is one record of
## `World.segment_plans`, and the lines of text read out the record of the stretch in
## white. The route gives the bearing each segment sets off on
## (`Route.bearing_of`), and the widget lays the road out along those bearings,
## with the whole map turned so the road lies along the wide picture.
import game.Angle
import game.Route
import game.World
import lib.Brush
import lib.CanvasApp
import lib.Shapes
import lib.RgbColor
import lib.Point
import widget.PlanView
import widget.ReadoutText
import widget.WidgetPage

RouteWidgetApp :: [].{

	## A still picture has no state.
	Model : {}

	canvas_app : CanvasApp.CanvasApp(RouteWidgetApp.Model)
	canvas_app = WidgetPage.still_app({ title: "The route", shapes: still_shapes })
}

## A place on the map, in metres from the route's start.
MapPoint : { east : F64, north : F64 }

## One segment of the route, laid out on the map.
LaidSegment : {
	plan : World.SegmentPlan,
	start : MapPoint,
	end : MapPoint,
}

## Where the road has reached while the map is being laid out.
Layout : { laid : List(LaidSegment), at : MapPoint }

## How far the map is turned from the ride's north, to lay the road along the
## wide picture.
map_rotation : Angle.Turn
map_rotation = Angle.Turn.degrees(150.0)

## The bearing on the map of the segment at `index`: the route's bearing for
## it, turned with the map.
map_bearing : Route.SegmentIndex -> Angle.Bearing
map_bearing = |index| World.route.bearing_of(index).plus(map_rotation)

## `layout` with the segment at `index` on the end.
laid_onto : Layout, { plan : World.SegmentPlan, index : Route.SegmentIndex } -> Layout
laid_onto = |{ laid, at }, { plan, index }| {
	metres = plan.length.to_metres()
	bearing = map_bearing(index).to_radians()
	end = { east: at.east + metres * bearing.sin(), north: at.north + metres * bearing.cos() }
	{ laid: laid.append({ plan, start: at, end }), at: end }
}

segments : List(LaidSegment)
segments =
	World.segment_plans
		.fold_with_index(
			{ laid: [], at: { east: 0.0, north: 0.0 } },
			|layout, plan, at| laid_onto(
				layout,
				{ plan, index: Route.SegmentIndex.number(at.to_u32_wrap()) },
			),
		)
		.laid

## The segment read out under the map, counted from 1. It's the longest on the
## route, the first of them if two tie, and the one the book quotes in its
## chapter on the math layer.
read_out_number : U64
read_out_number = {
	longest = segments.fold_with_index(
		{ number: 0, metres: 0.0 },
		|best, segment, index| {
			metres = segment.plan.length.to_metres()
			if metres > best.metres {
				{ number: index + 1, metres }
			} else {
				best
			}
		},
	)
	longest.number
}

read_out_segment : LaidSegment
read_out_segment =
	segments.get(read_out_number - 1) ?? crash "RouteWidgetApp.read_out_segment: the route has this segment"

## The plan of the segment read out, with the bend at its end.
read_out_plan : World.BendingPlan
read_out_plan =
	World.bending_plans.get(read_out_number - 1)
		?? crash "RouteWidgetApp.read_out_plan: the segment read out bends into the next"

## Every corner of the road.
corners : List(MapPoint)
corners = segments.map(|segment| segment.end).prepend({ east: 0.0, north: 0.0 })

## The extent of the road on the map.
Extent : {
	west : F64,
	east : F64,
	south : F64,
	north : F64,
}

extent : Extent
extent =
	corners.fold(
		{
			west: 0.0,
			east: 0.0,
			south: 0.0,
			north: 0.0,
		},
		|{ west, east, south, north }, corner| {
			west: west.min(corner.east),
			east: east.max(corner.east),
			south: south.min(corner.north),
			north: north.max(corner.north),
		},
	)

## The space kept clear around the map, in pixels.
map_margin : F64
map_margin = 18.0

## The map, with the middle of the road's extent in the middle of the picture,
## and as many pixels a metre as let the whole road fit.
map_plan : PlanView
map_plan = {
	origin: { x: WidgetPage.canvas_width / 2.0, y: WidgetPage.picture_bottom_y / 2.0 },
	pixels_a_metre: F64.min(
		(WidgetPage.canvas_width - 2.0 * map_margin) / (extent.east - extent.west),
		(WidgetPage.picture_bottom_y - 2.0 * map_margin) / (extent.north - extent.south),
	),
}

## Where `point` falls on the canvas. North is up the picture.
canvas_point : MapPoint -> Point.Point
canvas_point = |{ east, north }|
	map_plan.canvas_point({
		metres_right: east - (extent.west + extent.east) / 2.0,
		metres_down: (extent.south + extent.north) / 2.0 - north,
	})

read_out_color : RgbColor
read_out_color = PlanView.standout_color

cat_color : RgbColor
cat_color = PlanView.accent_color

bird_color : RgbColor
bird_color = RgbColor.of(0x7a5cc0)

## A disc on the map.
spot : MapPoint, { radius : F64, color : RgbColor } -> Shapes.Shape
spot = |point, { radius, color }| {
	{ x, y } = canvas_point(point)
	Disc({
		x,
		y,
		radius,
		fill: Brush.flat(color),
	})
}

## One segment of road, `width` pixels wide with a round end at each corner.
piece_shapes : LaidSegment, { width : F64, color : RgbColor } -> List(Shapes.Shape)
piece_shapes = |{ start, end, .. }, { width, color }| {
	a = canvas_point(start)
	b = canvas_point(end)
	[
		Shapes.line({ from: a, to: b, width }, Brush.flat(color)),
		spot(start, { radius: width / 2.0, color }),
		spot(end, { radius: width / 2.0, color }),
	]
}

## The middle of a segment.
middle_of : LaidSegment -> MapPoint
middle_of = |{ start, end, .. }| {
	east: (start.east + end.east) / 2.0,
	north: (start.north + end.north) / 2.0,
}

## The colour that marks what the rider meets on a segment, if anything.
encounter_color : World.SegmentPlan -> Try(RgbColor, [NoEncounter])
encounter_color = |plan|
	match plan.encounter {
		CatCrosses => Ok(cat_color)
		BirdHere => Ok(bird_color)
		QuietRoad => Err(NoEncounter)
	}

## A mark on the map where the rider meets something on a segment.
mark_shapes : LaidSegment -> List(Shapes.Shape)
mark_shapes = |segment|
	match encounter_color(segment.plan) {
		Ok(color) => [spot(middle_of(segment), { radius: 6.0, color })]
		Err(NoEncounter) => []
	}

## A coloured spot and the word for it, in the picture's empty corner.
row_shapes : {
	y : F64,
	color : RgbColor,
	word : Str,
} -> List(Shapes.Shape)
row_shapes = |{ y, color, word }|
	[
		Disc({
			x: 470.0,
			y,
			radius: 6.0,
			fill: Brush.flat(color),
		}),
		WidgetPage.label({
			text: word,
			x: 482.0,
			y: y + 5.0,
		}),
	]

legend_shapes : List(Shapes.Shape)
legend_shapes =
	[
		row_shapes({
			y: 160.0,
			color: read_out_color,
			word: "segment ${read_out_number.to_str()}",
		}),
		row_shapes({
			y: 178.0,
			color: cat_color,
			word: "a cat crosses",
		}),
		row_shapes({
			y: 196.0,
			color: bird_color,
			word: "a bird flies",
		}),
	].join()

road_shapes : List(Shapes.Shape)
road_shapes = segments.join_map(
	|each| piece_shapes(each, { width: 5.0, color: PlanView.road_color }),
)

## The stretch that the lines under the map read out.
read_out_shapes : List(Shapes.Shape)
read_out_shapes = piece_shapes(read_out_segment, { width: 7.0, color: read_out_color })

picture_shapes : List(Shapes.Shape)
picture_shapes =
	[
		[WidgetPage.picture_backdrop(PlanView.ground_color)],
		road_shapes,
		read_out_shapes,
		segments.join_map(mark_shapes),
		legend_shapes,
	].join()

## The segment's record, a few fields a line, with its tags as Roc writes them.
status_lines : List(Str)
status_lines = {
	plan = read_out_plan.segment_plan
	metres = ReadoutText.whole_text(plan.length.to_metres())
	turn = ReadoutText.turn_text(read_out_plan.turn)
	[
		"Segment ${read_out_number.to_str()} of ${segments.len().to_str()}: ${metres} m, ${turn}",
		"encounter: ${Str.inspect(plan.encounter)}, pigs: ${Str.inspect(plan.pigs)}",
		"bull: ${Str.inspect(plan.bull)}, scheme: ${Str.inspect(plan.scheme)}",
		"bend_life: ${Str.inspect(read_out_plan.bend_life)}",
	]
}

still_shapes : List(Shapes.Shape)
still_shapes = WidgetPage.frame_shapes({ picture_shapes, status_lines })

expect segments.len() == World.segment_plans.len()

# Each segment starts where the one before it ends.
expect {
	starts = segments.map(|segment| segment.start)
	ends = segments.map(|segment| segment.end)
	starts.drop_first(1) == ends.drop_last(1)
}

# The road stays inside the picture, on all four sides.
expect corners.all(|corner| canvas_point(corner).x >= 0.0)
expect corners.all(|corner| canvas_point(corner).x <= WidgetPage.canvas_width)
expect corners.all(|corner| canvas_point(corner).y >= 0.0)
expect corners.all(|corner| canvas_point(corner).y <= WidgetPage.picture_bottom_y)

# It is the longest segment, so it is plain on the map.
expect {
	longest = read_out_segment.plan.length.to_metres()
	segments.all(|segment| segment.plan.length.to_metres() <= longest)
}

# The stretch that's read out goes down over the road.
expect picture_shapes.drop_first(1 + road_shapes.len()).starts_with(read_out_shapes)

# The lines go on the panel, over the picture.
expect still_shapes.starts_with(picture_shapes)
