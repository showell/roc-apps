## The widget for the Safari tutorial's chapter on what never changes. Four video
## recorder buttons step along the route a segment at a time, and the lines of text
## read out that segment's record in `World.plans`. Nothing here runs by itself, so
## the buttons have no play. The picture is a map of the road. The ride has no such
## map: a segment knows only its length and its turn, so this widget lays the map
## out itself by adding up the turns.
import game.Angle
import game.Distance
import game.Scenery
import game.World
import lib.CanvasApp
import lib.Shapes
import lib.Trig
import widget.ScrubWidget
import widget.VcrButtons

RouteWidgetApp :: [].{

	## The whole state of the widget: the buttons, which hold the number of the
	## segment on show, from 1.
	Model : VcrButtons.Transport(U64)

	canvas_app : CanvasApp.CanvasApp(RouteWidgetApp.Model)
	canvas_app = VcrButtons.canvas_app({
		title: "The route",
		range: segment_steps,
		opens_at: segment_steps.first,
		frame: frame_at,
	})
}

## A step is one segment, from the first to the last.
segment_steps : VcrButtons.NumberRange(U64)
segment_steps = {
	first: 1,
	last: segments.len(),
	place_of: |number| number.to_f64(),
	number_at: |place| place.to_u64_wrap(),
	one_step: 1.0,
	playing: StepsOnly,
}

## A place on the map, in metres from the route's start.
MapPoint : { east : F64, north : F64 }

## One segment of the route, laid out on the map.
LaidSegment : {
	plan : World.SegmentPlan,
	number : U64,
	start : MapPoint,
	end : MapPoint,
}

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
		laid: laid.append({
			plan,
			number: laid.len() + 1,
			start: at,
			end,
		}),
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

## The segment with this number.
segment_numbered : U64 -> LaidSegment
segment_numbered = |number|
	segments.get(number - 1) ?? crash "RouteWidgetApp.segment_numbered: the buttons stay on the route"

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
road_piece : LaidSegment, { width : F64, color : I64 } -> List(Shapes.Shape)
road_piece = |{ start, end, .. }, { width, color }| {
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
crossing_mark : LaidSegment -> List(Shapes.Shape)
crossing_mark = |segment|
	match crossing_color(segment.plan) {
		Ok(color) => [spot(middle_of(segment), { r: 6.0, color })]
		Err(NothingCrosses) => []
	}

## A coloured spot and the word for it, in the picture's empty corner.
legend_row : {
	y : F64,
	color : I64,
	word : Str,
} -> List(Shapes.Shape)
legend_row = |{ y, color, word }|
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

legend : List(Shapes.Shape)
legend =
	[
		legend_row({
			y: 178.0,
			color: cat_color,
			word: "a cat crosses",
		}),
		legend_row({
			y: 196.0,
			color: bird_color,
			word: "a bird flies",
		}),
	].join()

## The map with `segment` picked out.
picture : LaidSegment -> List(Shapes.Shape)
picture = |segment|
	[
		[ground],
		segments.join_map(|each| road_piece(each, { width: 5.0, color: road_color })),
		road_piece(segment, { width: 7.0, color: here_color }),
		segments.join_map(crossing_mark),
		legend,
	].join()

## Everything on the canvas.
frame_at : RouteWidgetApp.Model -> List(Shapes.Shape)
frame_at = |transport| {
	segment = segment_numbered(transport.at)
	VcrButtons.frame_shapes(
		transport,
		{
			range: segment_steps,
			picture: picture(segment),
			status: status_lines(segment),
		},
	)
}

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
		GoldGreen => "GoldGreen"
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

# Each segment answers to its own number, at both ends of the route.
expect segment_numbered(1).number == 1
expect segment_numbered(2).number == 2
expect segment_numbered(segments.len()).number == segments.len()

# The first segment is as long as its record says, and the second starts where it
# ends.
expect {
	first = segment_numbered(1)
	{ east, north } = first.end
	((east * east + north * north).sqrt() - first.plan.length.to_metres()).abs() < 0.001
}
expect segment_numbered(2).start == segment_numbered(1).end

## What a press of `control` does on segment `number`, after that frame.
number_after_press : U64, VcrButtons.Control -> U64
number_after_press = |number, control|
	VcrButtons.next_transport(
		VcrButtons.transport_at(number),
		{ input: VcrButtons.click_on(control, segment_steps.playing), range: segment_steps },
	).at

# A step is a segment, and the buttons stop at the route's two ends.
expect number_after_press(5, StepForward) == 6
expect number_after_press(5, StepBack) == 4
expect number_after_press(5, ToStart) == 1
expect number_after_press(5, ToEnd) == segments.len()
expect number_after_press(1, StepBack) == 1
expect number_after_press(segments.len(), StepForward) == segments.len()

# The road stays inside the picture, on all four sides.
expect corners.all(|corner| canvas_point(corner).x >= 0.0)
expect corners.all(|corner| canvas_point(corner).x <= ScrubWidget.canvas_width)
expect corners.all(|corner| canvas_point(corner).y >= 0.0)
expect corners.all(|corner| canvas_point(corner).y <= ScrubWidget.picture_bottom_y)

expect turn_text(Angle.Turn.degrees(80.0)) == "80 deg right"
expect turn_text(Angle.Turn.degrees(-70.0)) == "70 deg left"
expect turn_text(Angle.Turn.degrees(0.0)) == "straight on"

expect metres_text(Distance.metres(1200.0)) == "1200"

expect
	status_lines(segment_numbered(1))
		== [
			"Segment 1 of 19: 500 m, 50 deg right",
			"crossing: BirdHere, pigs: NoPigs",
			"bull: NoBull, scheme: AllGreen",
			"bend_life: Elephant",
		]

# The map doesn't change along the road, and the picked-out part does.
expect picture(segment_numbered(1)) == picture(segment_numbered(1))
expect picture(segment_numbered(1)) != picture(segment_numbered(2))

# Only the segments that something crosses are marked on the map.
expect segments.keep_if(|segment| crossing_color(segment.plan).is_ok()).len() == 6
