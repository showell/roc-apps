## The widget for the Safari tutorial's chapter on what never changes. Dragging
## across the canvas walks along the route, and the lines of text read out the
## record in `World.plans` for the segment under the pointer. The picture is a
## map of the road. The ride has no such map: a segment knows only its length
## and its turn, so this widget lays the map out itself by adding up the turns.
import game.Angle
import game.Distance
import game.Fraction
import game.Scenery
import game.World
import lib.Brush
import lib.CanvasApp
import lib.Font
import lib.Shapes
import lib.Trig
import widget.ScrubWidget

RouteWidgetApp :: [].{

	## The whole state of the widget: how far along the route the pointer is.
	Model : { reached : Distance }

	canvas_app : CanvasApp.CanvasApp(RouteWidgetApp.Model)
	canvas_app = ScrubWidget.canvas_app({
		title: "The route",
		init: { reached: Distance.zero },
		model_at: |share| { reached: route_length.times(share.to_f64()) },
		frame: |model| frame_at(model.reached),
	})
}

route_length : Distance
route_length = World.route_length(World.segments)

## A place on the map, in metres from the route's start.
MapPoint : { east : F64, north : F64 }

## One segment of the route, laid out on the map.
LaidSegment : {
	plan : World.SegmentPlan,
	number : U64,
	from : Distance,
	to : Distance,
	start : MapPoint,
	end : MapPoint,
}

## Where the road has reached while the map is being laid out.
Layout : {
	laid : List(LaidSegment),
	reached : Distance,
	at : MapPoint,
	heading : F64,
}

## The compass bearing the road sets off on. Nothing in the ride says which way
## is north, so this one is chosen to lay the road along the wide picture.
start_heading : F64
start_heading = 150.0 * Trig.deg

## `layout` with one more segment on the end.
laid_onto : Layout, World.SegmentPlan -> Layout
laid_onto = |{ laid, reached, at, heading }, plan| {
	metres = plan.length.to_metres()
	end = {
		east: at.east + metres * heading.sin(),
		north: at.north + metres * heading.cos(),
	}
	to = reached.plus(plan.length)
	{
		laid: laid.append({
			plan,
			number: laid.len() + 1,
			from: reached,
			to,
			start: at,
			end,
		}),
		reached: to,
		at: end,
		heading: heading + plan.turn.to_radians(),
	}
}

segments : List(LaidSegment)
segments =
	World.plans.fold(
		{
			laid: [],
			reached: Distance.zero,
			at: { east: 0.0, north: 0.0 },
			heading: start_heading,
		},
		laid_onto,
	).laid

## Every corner of the road.
corners : List(MapPoint)
corners = segments.map(|segment| segment.end).prepend({ east: 0.0, north: 0.0 })

## The extent of the road on the map.
Extent : { west : F64, east : F64, south : F64, north : F64 }

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
			west: F64.min(west, corner.east),
			east: F64.max(east, corner.east),
			south: F64.min(south, corner.north),
			north: F64.max(north, corner.north),
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
on_canvas : MapPoint -> { x : F64, y : F64 }
on_canvas = |{ east, north }| {
	x: ScrubWidget.canvas_width / 2.0 + (east - (extent.west + extent.east) / 2.0) * map_scale,
	y: ScrubWidget.picture_bottom_y / 2.0 - (north - (extent.south + extent.north) / 2.0) * map_scale,
}

## The segment under `reached`.
segment_at : Distance -> LaidSegment
segment_at = |reached|
	segments.find_first(|segment| reached < segment.to)
		?? (segments.last() ?? crash "RouteWidgetApp.segment_at: the route has segments")

## The place `reached` metres along the route.
place_at : Distance -> MapPoint
place_at = |reached| {
	{ from, to, start, end, .. } = segment_at(reached)
	share = reached.minus(from).ratio_to(to.minus(from))
	{
		east: start.east + (end.east - start.east) * share,
		north: start.north + (end.north - start.north) * share,
	}
}

ground_color : I64
ground_color = 0x6f9a55

road_color : I64
road_color = 0x4a4a46

here_color : I64
here_color = 0xf2efe4

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
	{ x, y } = on_canvas(point)
	Disc({
		x,
		y,
		r,
		fill: ScrubWidget.flat(color),
		clip: Anywhere,
	})
}

## One segment of road, `width` pixels wide with a round end at each corner.
road_piece : LaidSegment, { width : F64, color : I64 } -> List(Shapes.Shape)
road_piece = |{ start, end, .. }, { width, color }| {
	a = on_canvas(start)
	b = on_canvas(end)
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
crossing_mark : LaidSegment -> List(Shapes.Shape)
crossing_mark = |segment|
	match crossing_color(segment.plan) {
		Ok(color) => [spot(middle_of(segment), { r: 6.0, color })]
		Err(NothingCrosses) => []
	}

## A coloured spot and the word for it, in the picture's empty corner.
legend_row : { y : F64, color : I64, word : Str } -> List(Shapes.Shape)
legend_row = |{ y, color, word }|
	Font.text(
		word,
		482.0,
		y - 6.0,
		12.0,
		Brush.opaque(0x202020),
	).prepend(
		Disc({
			x: 470.0,
			y,
			r: 6.0,
			fill: ScrubWidget.flat(color),
			clip: Anywhere,
		}),
	)

legend : List(Shapes.Shape)
legend =
	[
		legend_row({ y: 178.0, color: cat_color, word: "a cat crosses" }),
		legend_row({ y: 196.0, color: bird_color, word: "a bird flies" }),
	].join()

## The map with the place on the route and its segment picked out.
picture : Distance -> List(Shapes.Shape)
picture = |reached|
	[
		[ground],
		segments.join_map(|segment| road_piece(segment, { width: 5.0, color: road_color })),
		road_piece(segment_at(reached), { width: 7.0, color: here_color }),
		segments.join_map(crossing_mark),
		[spot(place_at(reached), { r: 5.0, color: 0x202020 })],
		legend,
	].join()

## A segment's stretch of the ruler.
stretch_of : LaidSegment -> ScrubWidget.Stretch
stretch_of = |{ from, to, .. }| {
	from: Fraction.clamp(from.ratio_to(route_length)),
	to: Fraction.clamp(to.ratio_to(route_length)),
}

## The segments with something crossing them.
crossed_stretches : List(ScrubWidget.Stretch)
crossed_stretches =
	segments.keep_if(|segment| crossing_color(segment.plan).is_ok()).map(stretch_of)

## Everything on the canvas at `reached`.
frame_at : Distance -> List(Shapes.Shape)
frame_at = |reached|
	ScrubWidget.frame_shapes({
		picture: picture(reached),
		dot_at: Fraction.clamp(reached.ratio_to(route_length)),
		marked: crossed_stretches,
		status: status_lines(segment_at(reached)),
	})

## A whole number of metres.
metres_text : Distance -> Str
metres_text = |distance| (distance.to_metres() + 0.5).to_i64_wrap().to_str()

## A turn in words.
turn_text : Angle.Turn -> Str
turn_text = |turn| {
	degrees = turn.to_radians() / Trig.deg
	if degrees > 0.0 {
		"${(degrees + 0.5).to_i64_wrap().to_str()} deg right"
	} else if degrees < 0.0 {
		"${(0.5 - degrees).to_i64_wrap().to_str()} deg left"
	} else {
		"straight on"
	}
}

crossing_text : World.SegmentPlan -> Str
crossing_text = |plan|
	match plan.crossing {
		CatCrosses => "CatCrosses"
		BirdHere => "BirdHere"
		QuietRoad => "QuietRoad"
	}

pigs_text : World.SegmentPlan -> Str
pigs_text = |plan|
	match plan.pigs {
		WithPigs => "WithPigs"
		NoPigs => "NoPigs"
	}

bull_text : World.SegmentPlan -> Str
bull_text = |plan|
	match plan.bull {
		WithBull => "WithBull"
		NoBull => "NoBull"
	}

scheme_text : Scenery.Scheme -> Str
scheme_text = |scheme|
	match scheme {
		AllGreen => "AllGreen"
		YellowGreen => "YellowGreen"
		RedGreen => "RedGreen"
	}

bend_life_text : Scenery.BendLife -> Str
bend_life_text = |bend_life|
	match bend_life {
		Quiet => "Quiet"
		Animal(Elephant) => "Elephant"
		Animal(Giraffe) => "Giraffe"
		Animal(Zebra) => "Zebra"
		Animal(Rhino) => "Rhino"
		DuckPond => "DuckPond"
	}

## The segment's record, a few fields a line.
status_lines : LaidSegment -> List(Str)
status_lines = |{ plan, number, .. }|
	[
		"Segment ${number.to_str()} of ${segments.len().to_str()}: ${metres_text(plan.length)} m, ${turn_text(plan.turn)}",
		"crossing: ${crossing_text(plan)}, pigs: ${pigs_text(plan)}",
		"bull: ${bull_text(plan)}, scheme: ${scheme_text(plan.scheme)}",
		"bend_life: ${bend_life_text(plan.bend_life)}",
	]

expect segments.len() == World.plans.len()

# The segments end to end make up the route, with no gap between any two.
expect segment_at(Distance.zero).number == 1
expect segment_at(route_length).number == segments.len()
expect segment_at(Distance.metres(499.0)).number == 1
expect segment_at(Distance.metres(500.0)).number == 2

# A place is `reached` metres from the start along the first segment, and the
# end of that segment is where the second begins.
expect place_at(Distance.zero).east.abs() < 0.001
expect place_at(Distance.zero).north.abs() < 0.001
expect {
	{ east, north } = place_at(Distance.metres(100.0))
	(F64.sqrt(east * east + north * north) - 100.0).abs() < 0.001
}
expect {
	{ east, north } = place_at(Distance.metres(500.0))
	first = segment_at(Distance.zero)
	(east - first.end.east).abs() < 0.001 and (north - first.end.north).abs() < 0.001
}

# The road stays inside the picture, on all four sides.
expect corners.all(|corner| on_canvas(corner).x >= 0.0)
expect corners.all(|corner| on_canvas(corner).x <= ScrubWidget.canvas_width)
expect corners.all(|corner| on_canvas(corner).y >= 0.0)
expect corners.all(|corner| on_canvas(corner).y <= ScrubWidget.picture_bottom_y)

expect turn_text(Angle.Turn.degrees(80.0)) == "80 deg right"
expect turn_text(Angle.Turn.degrees(-70.0)) == "70 deg left"
expect turn_text(Angle.Turn.degrees(0.0)) == "straight on"

expect metres_text(Distance.metres(1200.0)) == "1200"

expect
	status_lines(segment_at(Distance.zero))
		== [
			"Segment 1 of 19: 500 m, 50 deg right",
			"crossing: BirdHere, pigs: NoPigs",
			"bull: NoBull, scheme: AllGreen",
			"bend_life: Elephant",
		]

# The map doesn't change along the road, and the picked-out part does.
expect picture(Distance.zero) == picture(Distance.zero)
expect picture(Distance.zero) != picture(Distance.metres(600.0))

# Only the segments that something crosses are marked on the ruler.
expect crossed_stretches.len() == 6
