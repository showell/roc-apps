## The widget for the Safari tutorial's tour of the world: a fixed map of the
## whole route, with no controls. Each stretch is one record of
## `World.segment_plans`, and a mark shows where a plan has a cat cross or a
## bird fly. The route gives the bearing each segment sets off on
## (`Route.bearing_of`), and the widget lays the road out along those bearings,
## with the whole map turned so the road lies along the wide picture. The book
## shows a plan's record as Roc code, so the canvas holds the map alone.
import game.Angle
import game.Distance
import game.Route
import game.World
import lib.Brush
import lib.CanvasApp
import lib.Shapes
import lib.RgbColor
import lib.Pixels
import lib.Point
import widget.PlanView
import widget.WidgetPage
import widget.WidgetPalette

RouteWidgetApp :: [].{

	## A fixed picture has no state.
	Model : {}

	canvas_app : CanvasApp.CanvasApp(RouteWidgetApp.Model)
	canvas_app = {
		..WidgetPage.fixed_picture_app({ title: "The route", shapes: picture_shapes }),
		size: { width: canvas_width, height: canvas_height },
	}
}

canvas_width : F64
canvas_width = WidgetPage.canvas_width

## As tall as the road needs when it spans the canvas's width, margins
## included. The book's frame for this widget has the same aspect.
canvas_height : F64
canvas_height = 220.0

## A place on the map, by how far east and north of the route's start it is;
## either can be negative.
MapPoint : { east : Distance, north : Distance }

## The route's start, where the map is laid out from.
map_start : MapPoint
map_start = { east: Distance.zero, north: Distance.zero }

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
	end = {
		east: Distance.metres(at.east.to_metres() + metres * bearing.sin()),
		north: Distance.metres(at.north.to_metres() + metres * bearing.cos()),
	}
	{ laid: laid.append({ plan, start: at, end }), at: end }
}

segments : List(LaidSegment)
segments =
	World.segment_plans
		.fold_with_index(
			{ laid: [], at: map_start },
			|layout, plan, at| laid_onto(
				layout,
				{ plan, index: Route.SegmentIndex.from_count_before(at) },
			),
		)
		.laid

## Every corner of the road.
corners : List(MapPoint)
corners = segments.map(|segment| segment.end).prepend(map_start)

## The extent of the road on the map, each edge by how far east or north of the
## route's start it is.
Extent : {
	west : Distance,
	east : Distance,
	south : Distance,
	north : Distance,
}

extent : Extent
extent =
	corners.fold(
		{
			west: Distance.zero,
			east: Distance.zero,
			south: Distance.zero,
			north: Distance.zero,
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
	road_width = extent.east.minus(extent.west).to_metres()
	road_height = extent.north.minus(extent.south).to_metres()
	{
		origin: Point.at(canvas_width / 2.0, canvas_height / 2.0),
		pixels_a_metre: F64.min(
			(canvas_width - 2.0 * map_margin) / road_width,
			(canvas_height - 2.0 * map_margin) / road_height,
		),
	}
}

## Where `point` falls on the canvas. North is up the picture.
canvas_point : MapPoint -> Point.Point
canvas_point = |{ east, north }| {
	west_edge = extent.west.to_metres()
	east_edge = extent.east.to_metres()
	south_edge = extent.south.to_metres()
	north_edge = extent.north.to_metres()
	map_plan.canvas_point({
		metres_right: east.to_metres() - (west_edge + east_edge) / 2.0,
		metres_down: (south_edge + north_edge) / 2.0 - north.to_metres(),
	})
}

cat_color : RgbColor
cat_color = WidgetPalette.accent_color

bird_color : RgbColor
bird_color = RgbColor.of(0x7a5cc0)

## A disc on the map.
spot : MapPoint, { radius : F64, color : RgbColor } -> Shapes.Shape
spot = |point, { radius, color }| {
	Disc({
		center: canvas_point(point),
		radius: Pixels.of(radius),
		fill: Brush.flat(color),
	})
}

## How many pixels wide the road is drawn.
road_width_pixels : F64
road_width_pixels = 5.0

## One segment of road, with a round end at each corner.
piece_shapes : LaidSegment -> List(Shapes.Shape)
piece_shapes = |{ start, end, .. }| {
	color = WidgetPalette.plan_road_color
	radius = road_width_pixels / 2.0
	[
		Shapes.line(
			{
				from: canvas_point(start),
				to: canvas_point(end),
				width: Pixels.of(road_width_pixels),
			},
			Brush.flat(color),
		),
		spot(start, { radius, color }),
		spot(end, { radius, color }),
	]
}

## The middle of a segment.
middle_of : LaidSegment -> MapPoint
middle_of = |{ start, end, .. }| {
	east: start.east.plus(end.east).divided_by(2.0),
	north: start.north.plus(end.north).divided_by(2.0),
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
			center: Point.at(470.0, y),
			radius: Pixels.of(6.0),
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
road_shapes = segments.join_map(piece_shapes)

ground : Shapes.Shape
ground = Shapes.rectangle({
	top_left: Point.at(0.0, 0.0),
	width: Pixels.of(canvas_width),
	height: Pixels.of(canvas_height),
	fill: Brush.flat(WidgetPalette.plan_ground_color),
})

picture_shapes : List(Shapes.Shape)
picture_shapes =
	[[ground], road_shapes, segments.join_map(mark_shapes), legend_shapes].join()

## Whether `point` is on the canvas, edges included.
is_on_canvas : Point.Point -> Bool
is_on_canvas = |point| {
	x = point.x.to_f64()
	y = point.y.to_f64()
	x >= 0.0 and x <= canvas_width and y >= 0.0 and y <= canvas_height
}

expect segments.len() == World.segment_plans.len()

# Each segment starts where the one before it ends.
expect {
	starts = segments.map(|segment| segment.start)
	ends = segments.map(|segment| segment.end)
	starts.drop_first(1) == ends.drop_last(1)
}

# The road stays on the canvas, on all four sides.
expect corners.all(|corner| is_on_canvas(canvas_point(corner)))

# The road spans the canvas's width, between its margins, so the canvas is no
# wider than the map needs.
expect {
	road_width = extent.east.minus(extent.west).to_metres()
	map_plan.pixels_a_metre == (canvas_width - 2.0 * map_margin) / road_width
}

# Nor is it much taller: less than one margin is left over above and below.
expect {
	road_height = extent.north.minus(extent.south).to_metres() * map_plan.pixels_a_metre
	canvas_height - 2.0 * map_margin - road_height < map_margin
}

# The canvas is the map alone, at the size the app gives the page.
expect {
	frame_shapes = RouteWidgetApp.canvas_app.frame_shapes
	frame_shapes({}) == picture_shapes
}
expect RouteWidgetApp.canvas_app.size == { width: 640.0, height: 220.0 }
