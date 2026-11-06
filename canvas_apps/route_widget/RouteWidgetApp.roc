## The widget for the Safari tutorial's chapter on what never changes: a still
## map of the whole route, with no controls. Each stretch is one record of
## `World.plans`, and the lines of text read out the record of the stretch in
## white. The ride has no such map: a segment knows only its length and its
## turn, so this widget lays the map out itself by adding up the turns.
import game.Angle
import game.Distance
import game.World
import lib.CanvasApp
import lib.Shapes
import lib.Trig
import widget.ScrubWidget

RouteWidgetApp :: [].{

	## A still picture has no state.
	Model : {}

	canvas_app : CanvasApp.CanvasApp(RouteWidgetApp.Model)
	canvas_app = ScrubWidget.canvas_app({
		title: "The route",
		init: {},
		model_at_next_step: |model, _input| model,
		frame_shapes: |_model| still_shapes,
	})
}

## A place on the map, in metres from the route's start.
MapPoint : { east : F64, north : F64 }

## One segment of the route, laid out on the map.
LaidSegment : { plan : World.SegmentPlan, start : MapPoint, end : MapPoint }

## Where the road has reached while the map is being laid out.
Layout : {
	laid : List(LaidSegment),
	at : MapPoint,
	heading : F64,
}

## The compass bearing the road sets off on. Nothing in the ride says which way
## is north, so this one is chosen to lay the road along the wide picture.
start_heading : F64
start_heading = 150.0 * Trig.deg

## `layout` with one more segment on the end.
laid_onto : Layout, World.SegmentPlan -> Layout
laid_onto = |{ laid, at, heading }, plan| {
	metres = plan.length.to_metres()
	end = { east: at.east + metres * heading.sin(), north: at.north + metres * heading.cos() }
	{
		laid: laid.append({ plan, start: at, end }),
		at: end,
		heading: heading + plan.turn.to_radians(),
	}
}

segments : List(LaidSegment)
segments =
	World.plans.fold(
		{
			laid: [],
			at: { east: 0.0, north: 0.0 },
			heading: start_heading,
		},
		laid_onto,
	).laid

## The segment read out under the map, counted from 1. It's the longest on the
## route, and the one the book quotes in its chapter on the math layer.
read_out_number : U64
read_out_number = 7

read_out_segment : LaidSegment
read_out_segment =
	segments.get(read_out_number - 1) ?? crash "RouteWidgetApp.read_out_segment: the route has this segment"

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

## How many pixels a metre takes up on the map.
map_scale : F64
map_scale = F64.min(
	(ScrubWidget.canvas_width - 2.0 * map_margin) / (extent.east - extent.west),
	(ScrubWidget.picture_bottom_y - 2.0 * map_margin) / (extent.north - extent.south),
)

## Where `point` falls on the canvas, with the road centred in the picture.
canvas_point : MapPoint -> { x : F64, y : F64 }
canvas_point = |{ east, north }| {
	x: ScrubWidget.canvas_width / 2.0 + (east - (extent.west + extent.east) / 2.0) * map_scale,
	y: ScrubWidget.picture_bottom_y / 2.0 - (north - (extent.south + extent.north) / 2.0) * map_scale,
}

ground_color : I64
ground_color = 0x6f9a55

road_color : I64
road_color = 0x4a4a46

read_out_color : I64
read_out_color = 0xf2efe4

cat_color : I64
cat_color = 0xd0603a

bird_color : I64
bird_color = 0x7a5cc0

ground : Shapes.Shape
ground = Rect({
	x: 0.0,
	y: 0.0,
	w: ScrubWidget.canvas_width,
	h: ScrubWidget.picture_bottom_y,
	fill: ScrubWidget.flat(ground_color),
})

## A disc on the map.
spot : MapPoint, { r : F64, color : I64 } -> Shapes.Shape
spot = |point, { r, color }| {
	{ x, y } = canvas_point(point)
	Disc({
		x,
		y,
		r,
		fill: ScrubWidget.flat(color),
		clip: Anywhere,
	})
}

## One segment of road, `width` pixels wide with a round end at each corner.
piece_shapes : LaidSegment, { width : F64, color : I64 } -> List(Shapes.Shape)
piece_shapes = |{ start, end, .. }, { width, color }| {
	a = canvas_point(start)
	b = canvas_point(end)
	[
		Shapes.line(
			a.x,
			a.y,
			b.x,
			b.y,
			width,
			ScrubWidget.flat(color),
		),
		spot(start, { r: width / 2.0, color }),
		spot(end, { r: width / 2.0, color }),
	]
}

## The middle of a segment.
middle_of : LaidSegment -> MapPoint
middle_of = |{ start, end, .. }| {
	east: (start.east + end.east) / 2.0,
	north: (start.north + end.north) / 2.0,
}

## The colour that marks what crosses a segment, if anything does.
crossing_color : World.SegmentPlan -> Try(I64, [NothingCrosses])
crossing_color = |plan|
	match plan.crossing {
		CatCrosses => Ok(cat_color)
		BirdHere => Ok(bird_color)
		QuietRoad => Err(NothingCrosses)
	}

## A mark on the map where something crosses a segment.
mark_shapes : LaidSegment -> List(Shapes.Shape)
mark_shapes = |segment|
	match crossing_color(segment.plan) {
		Ok(color) => [spot(middle_of(segment), { r: 6.0, color })]
		Err(NothingCrosses) => []
	}

## A coloured spot and the word for it, in the picture's empty corner.
row_shapes : {
	y : F64,
	color : I64,
	word : Str,
} -> List(Shapes.Shape)
row_shapes = |{ y, color, word }|
	[
		Disc({
			x: 470.0,
			y,
			r: 6.0,
			fill: ScrubWidget.flat(color),
			clip: Anywhere,
		}),
		ScrubWidget.label({
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
road_shapes = segments.join_map(|each| piece_shapes(each, { width: 5.0, color: road_color }))

## The stretch that the lines under the map read out.
read_out_shapes : List(Shapes.Shape)
read_out_shapes = piece_shapes(read_out_segment, { width: 7.0, color: read_out_color })

picture_shapes : List(Shapes.Shape)
picture_shapes =
	[
		[ground],
		road_shapes,
		read_out_shapes,
		segments.join_map(mark_shapes),
		legend_shapes,
	].join()

## A turn in words.
turn_text : Angle.Turn -> Str
turn_text = |turn| {
	degrees = turn.abs().ratio_to(Angle.Turn.degrees(1.0))
	side = if turn.is_right() {
		"right"
	} else {
		"left"
	}
	"${(degrees + 0.5).to_i64_wrap().to_str()} deg ${side}"
}

## The segment's record, a few fields a line, with its tags as Roc writes them.
status_lines : List(Str)
status_lines = {
	plan = read_out_segment.plan
	metres = (plan.length.to_metres() + 0.5).to_i64_wrap()
	[
		"Segment ${read_out_number.to_str()} of ${segments.len().to_str()}: ${metres.to_str()} m, ${turn_text(plan.turn)}",
		"crossing: ${Str.inspect(plan.crossing)}, pigs: ${Str.inspect(plan.pigs)}",
		"bull: ${Str.inspect(plan.bull)}, scheme: ${Str.inspect(plan.scheme)}",
		"bend_life: ${Str.inspect(plan.bend_life)}",
	]
}

still_shapes : List(Shapes.Shape)
still_shapes = ScrubWidget.frame_shapes({ picture_shapes, status_lines: status_lines })

expect segments.len() == World.plans.len()

# The first segment is as long as its record says, and each one starts where the
# one before it ends.
expect {
	{ east, north } = (segments.first() ?? crash "the route has segments").end
	((east * east + north * north).sqrt() - 500.0).abs() < 0.001
}
expect segments.map(|segment| segment.start).drop_first(1) == segments.map(|segment| segment.end).drop_last(1)

# The road stays inside the picture, on all four sides.
expect corners.all(|corner| canvas_point(corner).x >= 0.0)
expect corners.all(|corner| canvas_point(corner).x <= ScrubWidget.canvas_width)
expect corners.all(|corner| canvas_point(corner).y >= 0.0)
expect corners.all(|corner| canvas_point(corner).y <= ScrubWidget.picture_bottom_y)

expect turn_text(Angle.Turn.degrees(80.0)) == "80 deg right"
expect turn_text(Angle.Turn.degrees(-70.0)) == "70 deg left"

# The lines read the same record the book quotes, and no other.
expect
	status_lines
		== [
			"Segment 7 of 19: 1200 m, 80 deg right",
			"crossing: QuietRoad, pigs: NoPigs",
			"bull: WithBull, scheme: RedGreen",
			"bend_life: Animal(Rhino)",
		]

# It is the longest segment, so it is plain on the map.
expect segments.all(|segment| segment.plan.length.to_metres() <= read_out_segment.plan.length.to_metres())

# The stretch that's read out goes down over the road.
expect picture_shapes.drop_first(1 + road_shapes.len()).starts_with(read_out_shapes)

# Only the segments that something crosses are marked on the map.
expect segments.keep_if(|segment| crossing_color(segment.plan).is_ok()).len() == 6

# The lines go on the panel, over the picture.
expect still_shapes.starts_with(picture_shapes)
expect still_shapes.len() == picture_shapes.len() + 5
