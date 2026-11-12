## The widget for `CowHerd.is_calf`, the Safari tutorial's first function with
## a body: a fixed picture of a herd of twenty cows standing in a row on the
## grass, each with its number under it, and no controls. The cows are the
## billboards CowHerd gives a herd of twenty, so the calves, half as tall, are
## the cows `is_calf` picks. They all stand one distance from the camera, so
## every grown cow is one size.
import game.Across
import game.Along
import game.Angle
import game.Billboard
import game.Clock
import game.CowHerd
import game.Distance
import game.FrameView
import game.Geom
import game.Lens
import game.Pipeline
import game.Screen
import game.SegmentFromRider
import game.Sky
import game.World
import lib.CanvasApp
import lib.Font
import lib.Pixels
import lib.Point
import lib.Shapes
import widget.WidgetPage
import widget.WidgetPalette

HerdWidgetApp :: [].{

	## A fixed picture has no state.
	Model : {}

	canvas_app : CanvasApp.CanvasApp(HerdWidgetApp.Model)
	canvas_app = {
		size: { width: canvas_width, height: canvas_height },
		frames_a_second: WidgetPage.fixed_picture_frames_a_second,
		init: {},
		model_at_next_step: |model, _input, _seconds| model,
		frame_shapes: |_model| picture_shapes,
		sounds: |_model| 0,
		tones: [],
		title: "A herd of twenty cows",
	}
}

## As wide as every widget page, so the labels read at the usual size.
canvas_width : F64
canvas_width = WidgetPage.canvas_width

## Just tall enough for some sky, the row of cows and their numbers under them.
canvas_height : F64
canvas_height = 116.0

## How many cows the herd has.
cow_count : U64
cow_count = 20

## The herd's cows, in a single row, so cow number `n` is the `n`th billboard.
herd_billboards : List(Billboard)
herd_billboards = {
	herd = CowHerd.herd({ cow_count, rows_behind_front: 0 })
	herd.herd_cows({ herd_along: Along.start, bull: NoBull }).map(|placed| placed.kind)
}

## How far down the road every cow stands: near enough that a grown cow is a
## good size, and far enough that twenty of them fit across the picture.
herd_forward : Distance
herd_forward = Distance.metres(24.0)

## The x on the canvas of the middle of the cow at `cow_number`: the canvas is
## cut into one equal slot a cow, and each cow stands in the middle of its own.
cow_canvas_x : U64 -> F64
cow_canvas_x = |cow_number| (cow_number.to_f64() + 0.5) * canvas_width / cow_count.to_f64()

## The cow at `cow_number`, standing `herd_forward` down the road and as far
## across it as puts its middle on its `cow_canvas_x`.
placed_cow : { kind : Billboard, cow_number : U64 } -> Geom.Placed(Billboard)
placed_cow = |{ kind, cow_number }| {
	screen_x = WidgetPage.screen_x_at_canvas_x(cow_canvas_x(cow_number))
	slope = Lens.slope_at_x({ x: screen_x, focal_length: Lens.resting_focal_length })
	{
		road_point: {
			along: Along.at(herd_forward),
			across: Across.right_of_middle(herd_forward.times(slope)),
		},
		lift: Distance.zero,
		kind,
	}
}

## The camera, at the start of the road, looking down it through the lens at
## rest.
camera : Pipeline.SightingCamera
camera = {
	vantage: {
		along: Along.start,
		across: Across.middle,
		yaw: Angle.straight_ahead,
	},
	focal_length: Lens.resting_focal_length,
}

## What the camera shows of a cow, as the ride sights and draws a billboard.
## Every cow stands in front of the camera, well above the size the ride drops.
placed_cow_shapes : Geom.Placed(Billboard) -> List(Shapes.Shape)
placed_cow_shapes = |placed|
	match Pipeline.scenery_sighting_of(
		placed,
		{
			road: World.road_at_start,
			camera,
			from_rider: Ahead(SegmentFromRider.Position.first),
		},
	) {
		Ok(sighting) => {
			rendered = Pipeline.rendering_of(
				sighting,
				{ focal_length: camera.focal_length, darkness: Sky.darkness_at(Clock.start) },
			)
			rendered.sprite().to_shapes()
		}
		Err(OutOfSight) => crash "HerdWidgetApp.placed_cow_shapes: every cow stands in plain sight"
	}

## Each cow's shapes, from cow 0 at the left to cow 19 at the right, in the
## ride's screen.
cow_shape_lists : List(List(Shapes.Shape))
cow_shape_lists =
	herd_billboards.map_with_index(
		|kind, cow_number| placed_cow_shapes(placed_cow({ kind, cow_number })),
	)

## How many canvas pixels the picture gives a pixel of the ride's screen, as
## on every widget page.
canvas_per_screen : F64
canvas_per_screen = canvas_width / Screen.width.to_f64()

## Where the horizon crosses the canvas, chosen by eye: enough sky over the
## herd to read as sky.
canvas_horizon_y : F64
canvas_horizon_y = 56.0

## The ride's screen at the widget pages' scale, raised so its horizon crosses
## the canvas at `canvas_horizon_y`.
herd_space : Shapes.Space
herd_space = Shapes.world_space({
	target: { x: Pixels.zero, y: Screen.horizon_y },
	offset: Point.at(0.0, canvas_horizon_y),
	rotation: 0.0,
	zoom: canvas_per_screen,
})

## Where `herd_space` puts a point of the ride's screen on the canvas.
canvas_point_of_screen : Point -> Point
canvas_point_of_screen = |{ x, y }| {
	x: x.times(canvas_per_screen),
	y: Pixels.of(canvas_horizon_y).plus(y.minus(Screen.horizon_y).times(canvas_per_screen)),
}

## The baseline of the numbers, a little below the cows' feet.
label_baseline : F64
label_baseline = 101.0

## How the numbers under the cows are set: centered under each cow, at the size
## of the tree widget's captions.
label_rows : WidgetPage.ReadoutRows
label_rows = {
	x: 0.0,
	first_baseline: label_baseline,
	row_spacing: 0.0,
	size: 13.0,
	align: Center,
}

## The number of the cow at `cow_number`, centered under it.
cow_label : U64 -> Shapes.Shape
cow_label = |cow_number|
	WidgetPage.readout_line({
		text: cow_number.to_str(),
		color: WidgetPalette.ink_color,
		row: 0,
		style: { ..label_rows, x: cow_canvas_x(cow_number) },
	})

## Every cow's number, from 0 to 19.
label_shapes : List(Shapes.Shape)
label_shapes = List.from_iter(U64.until(0, cow_count)).map(cow_label)

## The ride's sky at the start of the ride, with the sun out of the picture.
backdrop : FrameView.Backdrop
backdrop = {
	sky_colors: Sky.colors_at(Clock.start),
	sun_sighting: OutOfView,
	darkness: Sky.darkness_at(Clock.start),
}

## The herd over the backdrop in `herd_space`, and the numbers on top.
picture_shapes : List(Shapes.Shape)
picture_shapes =
	FrameView.painted_shapes({
		backdrop,
		ride_shape_lists: cow_shape_lists,
		space: herd_space,
	}).concat(label_shapes)

## Every corner of `shapes`' straight-edged regions on the canvas, or none if
## any shape has no corners.
canvas_corners : List(Shapes.Shape) -> Try(List(Point), [NotPolygon])
canvas_corners = |shapes| {
	polygons = shapes.keep_oks(Shapes.region_corners)
	if polygons.len() == shapes.len() and !polygons.is_empty() {
		Ok(polygons.join().map(canvas_point_of_screen))
	} else {
		Err(NotPolygon)
	}
}

## A cow's top and its feet on the canvas.
Upright : { top : F64, bottom : F64 }

## The top and the feet of the cow drawn by `shapes`, on the canvas.
cow_upright : List(Shapes.Shape) -> Try(Upright, [NotPolygon, NoCorners])
cow_upright = |shapes| {
	ys = canvas_corners(shapes)?.map(|corner| corner.y.to_f64())
	match (ys.min(), ys.max()) {
		(Ok(top), Ok(bottom)) => Ok({ top, bottom })
		_ => Err(NoCorners)
	}
}

## How tall the cow drawn by `shapes` stands on the canvas.
cow_height : List(Shapes.Shape) -> F64
cow_height = |shapes|
	match cow_upright(shapes) {
		Ok({ top, bottom }) => bottom - top
		Err(_) => crash "HerdWidgetApp.cow_height: a cow is drawn in polygons"
	}

## Whether every corner of the cow drawn by `shapes` is on the canvas.
is_cow_on_canvas : List(Shapes.Shape) -> Bool
is_cow_on_canvas = |shapes|
	match canvas_corners(shapes) {
		Ok(corners) =>
			corners.all(
				|corner| {
					x = corner.x.to_f64()
					y = corner.y.to_f64()
					x >= 0.0 and x <= canvas_width and y >= 0.0 and y <= canvas_height
				},
			)
		Err(NotPolygon) => False
	}

## Whether `label` is a line of type wholly on the canvas and below every cow's
## feet, given the room the font asks for.
is_label_on_canvas : Shapes.Shape -> Bool
is_label_on_canvas = |label|
	match label {
		Text(line) => {
			half_room = Font.room_for(line.text, line.size) / 2.0
			feet = cow_shape_lists.keep_oks(cow_upright).map(|upright| upright.bottom)
			match feet.max() {
				Ok(lowest_feet) =>
					line.x - half_room >= 0.0
						and line.x + half_room <= canvas_width
						and line.y - line.size > lowest_feet
						and line.y <= canvas_height
				Err(ListWasEmpty) => False
			}
		}
		Triangle(_) | Polygon(_) | Disc(_) | Quad(_) | Blend(_) | View(_) | Image(_) => False
	}

## The words of `shapes`' lines of type.
label_texts : List(Shapes.Shape) -> List(Str)
label_texts = |shapes|
	shapes.keep_oks(
		|shape|
			match shape {
				Text(line) => Ok(line.text)
				Triangle(_)
				| Polygon(_)
				| Disc(_)
				| Quad(_)
				| Blend(_)
				| View(_)
				| Image(_) => Err(NotText)
			},
	)

## How tall a grown cow stands on the canvas: cow 0's height.
grown_height : F64
grown_height =
	match cow_shape_lists {
		[first, ..] => cow_height(first)
		[] => crash "HerdWidgetApp.grown_height: the herd has twenty cows"
	}

## The numbers of the cows drawn `height` tall.
cow_numbers_of_height : F64 -> List(U64)
cow_numbers_of_height = |height|
	cow_shape_lists
		.map_with_index(|shapes, cow_number| (cow_number, cow_height(shapes)))
		.keep_if(|(_, drawn)| (drawn - height).abs() <= 0.000000001)
		.map(|(cow_number, _)| cow_number)

# Cows 1, 5, 9, 13 and 17 are the calves, drawn half as tall as a grown cow,
# and the other fifteen are grown cows, all one size.
expect cow_numbers_of_height(grown_height / 2.0) == [1, 5, 9, 13, 17]
expect
	cow_numbers_of_height(grown_height)
		== [0, 2, 3, 4, 6, 7, 8, 10, 11, 12, 14, 15, 16, 18, 19]

# A grown cow is big enough to see, and its calf plainly smaller.
expect grown_height >= 20.0 and grown_height <= 32.0

# Every cow faces the same way.
expect herd_billboards.all(|billboard| billboard.facing() == FacesRight)

# Every cow is wholly on the canvas, but a twenty-first in the next slot would
# stand partly off its right edge.
expect cow_shape_lists.len() == 20 and cow_shape_lists.all(is_cow_on_canvas)
expect
	match herd_billboards {
		[kind, ..] => !is_cow_on_canvas(placed_cow_shapes(placed_cow({ kind, cow_number: 20 })))
		[] => False
	}

## Cow 0's number with its baseline at `baseline`.
first_label_at : F64 -> Shapes.Shape
first_label_at = |baseline|
	WidgetPage.readout_line({
		text: "0",
		color: WidgetPalette.ink_color,
		row: 0,
		style: {
			..label_rows,
			x: cow_canvas_x(0),
			first_baseline: baseline,
		},
	})

# Every number is on the canvas, under the cows. One more past the last would
# run off the right edge, one set lower than the canvas off its bottom, and one
# set on the feet's line would cover them.
expect label_shapes.all(is_label_on_canvas)
expect first_label_at(label_baseline) == cow_label(0)
expect !is_label_on_canvas(cow_label(20))
expect !is_label_on_canvas(first_label_at(canvas_height + 1.0))
expect !is_label_on_canvas(first_label_at(canvas_horizon_y + 20.0))

# The labels are the cows' numbers, in order.
expect
	label_texts(label_shapes)
		== [
			"0",
			"1",
			"2",
			"3",
			"4",
			"5",
			"6",
			"7",
			"8",
			"9",
			"10",
			"11",
			"12",
			"13",
			"14",
			"15",
			"16",
			"17",
			"18",
			"19",
		]

# The picture is the backdrop, the twenty cows and their twenty numbers, and
# nothing else.
expect
	picture_shapes
		== Shapes.lists_in_space(
			herd_space,
			[FrameView.backdrop_shapes(backdrop)].concat(cow_shape_lists),
		).concat(label_shapes)
expect label_texts(picture_shapes).len() == 20
expect cow_shape_lists.all(|shapes| !shapes.is_empty())
