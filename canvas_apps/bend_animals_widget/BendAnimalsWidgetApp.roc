## The widget for the Safari tutorial's chapter on billboards: a fixed picture of
## the ride's four bend animals in a row on the grass, each with its baby, and no
## controls. Each pair is the grown and the young billboard of its animal's
## species from BendAnimal. The elephant and the giraffe face right, and the
## zebra and the rhino face left, so the two halves of the row face each other.
## Every billboard stands one distance from the camera, so the sizes compare.
import game.Across
import game.Along
import game.Angle
import game.BendAnimal
import game.Billboard
import game.Clock
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
import lib.Pixels
import lib.Point
import lib.Shapes
import widget.WidgetPage

BendAnimalsWidgetApp :: [].{

	## A fixed picture has no state.
	Model : {}

	canvas_app : CanvasApp.CanvasApp(BendAnimalsWidgetApp.Model)
	canvas_app = {
		size: { width: canvas_width, height: canvas_height },
		frames_a_second: WidgetPage.fixed_picture_frames_a_second,
		init: {},
		model_at_next_step: |model, _input, _seconds| model,
		frame_shapes: |_model| picture_shapes,
		sounds: |_model| 0,
		tones: [],
		title: "Four bend animals and their babies",
	}
}

## As wide as every widget page.
canvas_width : F64
canvas_width = WidgetPage.canvas_width

## Just tall enough for some sky over the giraffe and some grass under the feet.
canvas_height : F64
canvas_height = 160.0

## An animal in the row and the way it and its baby face.
Pair : { animal : BendAnimal, facing : Billboard.Facing }

## The row's pairs from left to right.
pairs : List(Pair)
pairs = [
	{ animal: Elephant, facing: FacesRight },
	{ animal: Giraffe, facing: FacesRight },
	{ animal: Zebra, facing: FacesLeft },
	{ animal: Rhino, facing: FacesLeft },
]

## A pair's two billboards, from left to right. The baby follows its mother, so
## it stands on the side she faces away from.
pair_billboards : Pair -> { left : Billboard, right : Billboard }
pair_billboards = |{ animal, facing }| {
	species = animal.species_of()
	adult = Billboard.adult_billboard(species, facing)
	young = Billboard.young_billboard(species, facing)
	match facing {
		FacesRight => { left: young, right: adult }
		FacesLeft => { left: adult, right: young }
	}
}

## The room between a baby and its mother.
sibling_gap : Distance
sibling_gap = Distance.metres(0.9)

## The room between one pair and the next.
pair_gap : Distance
pair_gap = Distance.metres(2.5)

## How far down the road every billboard stands: near enough that the babies
## are a good size, and far enough that the whole row fits across the picture.
row_forward : Distance
row_forward = Distance.metres(21.0)

## A billboard and how far its middle is from the row's left edge.
RowSpot : { billboard : Billboard, from_left_edge : Distance }

## Every billboard in the row with its spot, and the row's width.
row_layout : { spots : List(RowSpot), width : Distance }
row_layout = {
	var $left_edge = Distance.zero
	var $spots = []
	for pair in pairs {
		{ left, right } = pair_billboards(pair)
		left_middle = $left_edge.plus(left.half_width())
		gap_end = left_middle.plus(left.half_width()).plus(sibling_gap)
		right_middle = gap_end.plus(right.half_width())
		$spots = $spots.concat([
			{ billboard: left, from_left_edge: left_middle },
			{ billboard: right, from_left_edge: right_middle },
		])
		$left_edge = right_middle.plus(right.half_width()).plus(pair_gap)
	}
	{ spots: $spots, width: $left_edge.minus(pair_gap) }
}

## A billboard at its spot, with the row centered on the road's middle.
placed_billboard : RowSpot -> Geom.Placed(Billboard)
placed_billboard = |{ billboard, from_left_edge }| {
	row_left = Across.left_of_middle(row_layout.width.divided_by(2.0))
	{
		road_point: { along: Along.at(row_forward), across: row_left.plus(from_left_edge) },
		lift: Distance.zero,
		kind: billboard,
	}
}

## The row's billboards from left to right.
row_billboards : List(Billboard)
row_billboards = row_layout.spots.map(|spot| spot.billboard)

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

## What the camera shows of a billboard, as the ride sights and draws one.
## Every billboard stands in front of the camera, well above the size the ride
## drops.
placed_billboard_shapes : Geom.Placed(Billboard) -> List(Shapes.Shape)
placed_billboard_shapes = |placed|
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
		Err(BehindCamera) | Err(BelowHorizon) | Err(TooSmall) => crash "BendAnimalsWidgetApp.placed_billboard_shapes: every billboard stands in plain sight"
	}

## Each billboard's shapes, from left to right, in the ride's screen.
billboard_shape_lists : List(List(Shapes.Shape))
billboard_shape_lists = row_layout.spots.map(|spot| placed_billboard_shapes(placed_billboard(spot)))

## How many canvas pixels the picture gives a pixel of the ride's screen, as
## on every widget page.
canvas_per_screen : F64
canvas_per_screen = canvas_width / Screen.width.to_f64()

## Where the horizon crosses the canvas, chosen by eye: enough sky over the
## giraffe to read as sky.
canvas_horizon_y : F64
canvas_horizon_y = 112.0

## The ride's screen at the widget pages' scale, raised so its horizon crosses
## the canvas at `canvas_horizon_y`.
row_space : Shapes.Space
row_space = Shapes.world_space({
	target: { x: Pixels.zero, y: Screen.horizon_y },
	offset: Point.at(0.0, canvas_horizon_y),
	rotation: 0.0,
	zoom: canvas_per_screen,
})

## Where `row_space` puts a point of the ride's screen on the canvas.
canvas_point_of_screen : Point.Point -> Point.Point
canvas_point_of_screen = |{ x, y }| {
	x: x.times(canvas_per_screen),
	y: Pixels.of(canvas_horizon_y).plus(y.minus(Screen.horizon_y).times(canvas_per_screen)),
}

## The ride's sky at the start of the ride, with the sun out of the picture.
backdrop : FrameView.Backdrop
backdrop = {
	sky_colors: Sky.colors_at(Clock.start),
	sun_sighting: OutOfView,
	darkness: Sky.darkness_at(Clock.start),
}

## The row over the backdrop in `row_space`.
picture_shapes : List(Shapes.Shape)
picture_shapes = FrameView.painted_shapes({
	backdrop,
	ride_shape_lists: billboard_shape_lists,
	space: row_space,
})

## Where on the canvas the billboard drawn by `shapes` reaches.
Extent : {
	left : F64,
	right : F64,
	top : F64,
	bottom : F64,
}

## Every corner on the canvas of the billboard drawn by `shapes`. A billboard is
## drawn in polygons alone.
canvas_corners : List(Shapes.Shape) -> List(Point.Point)
canvas_corners = |shapes|
	shapes
		.map(|shape| Shapes.region_corners(shape) ?? crash "BendAnimalsWidgetApp.canvas_corners: a billboard is drawn in polygons")
		.join()
		.map(canvas_point_of_screen)

## How far the billboard drawn by `shapes` reaches on the canvas.
extent : List(Shapes.Shape) -> Extent
extent = |shapes| {
	corners = canvas_corners(shapes)
	xs = corners.map(|corner| corner.x.to_f64())
	ys = corners.map(|corner| corner.y.to_f64())
	match (xs.min(), xs.max(), ys.min(), ys.max()) {
		(
			Ok(left),
			Ok(right),
			Ok(top),
			Ok(bottom),
		) => { left, right, top, bottom }
		_ => crash "BendAnimalsWidgetApp.extent: every billboard is drawn"
	}
}

## Each billboard's extent on the canvas, from left to right.
extents : List(Extent)
extents = billboard_shape_lists.map(extent)

## Whether `reach` is wholly on the canvas.
is_on_canvas : Extent -> Bool
is_on_canvas = |reach|
	reach.left >= 0.0
		and reach.right <= canvas_width
		and reach.top >= 0.0
		and reach.bottom <= canvas_height

## The facings of the row's billboards, from left to right.
row_facings : List(Billboard.Facing)
row_facings = row_billboards.map(|billboard| billboard.facing())

# Every animal and every baby is drawn, eight billboards in all, and each is
# wholly on the canvas.
expect billboard_shape_lists.len() == 8
expect billboard_shape_lists.all(|shapes| !shapes.is_empty())
expect extents.all(is_on_canvas)

# The row fills the canvas: a row a fifth wider would run off its sides.
expect
	match (extents.first(), extents.last()) {
		(Ok(first), Ok(last)) => {
			spare = first.left + canvas_width - last.right
			spare > 0.0 and spare < (last.right - first.left) / 5.0
		}
		_ => False
	}

# The canvas is no taller than the row needs: the giraffe reaches into its top
# third, and every billboard's feet are on the grass below the horizon.
expect
	match extents.map(|reach| reach.top).min() {
		Ok(tallest_top) =>
			tallest_top < canvas_height / 3.0
				and extents.all(|reach| reach.bottom > canvas_horizon_y)
		Err(ListWasEmpty) => False
	}

# The billboards are the ride's own: each pair holds its species' grown and young
# billboards, and the baby is half as tall as its mother.
expect
	row_billboards
		== [
			Billboard.young_billboard(BendAnimal.Elephant.species_of(), FacesRight),
			Billboard.adult_billboard(BendAnimal.Elephant.species_of(), FacesRight),
			Billboard.young_billboard(BendAnimal.Giraffe.species_of(), FacesRight),
			Billboard.adult_billboard(BendAnimal.Giraffe.species_of(), FacesRight),
			Billboard.adult_billboard(BendAnimal.Zebra.species_of(), FacesLeft),
			Billboard.young_billboard(BendAnimal.Zebra.species_of(), FacesLeft),
			Billboard.adult_billboard(BendAnimal.Rhino.species_of(), FacesLeft),
			Billboard.young_billboard(BendAnimal.Rhino.species_of(), FacesLeft),
		]

# The left half of the row faces right and the right half faces left, so the
# two facings meet in the middle.
expect
	row_facings
		== [
			FacesRight,
			FacesRight,
			FacesRight,
			FacesRight,
			FacesLeft,
			FacesLeft,
			FacesLeft,
			FacesLeft,
		]

# A baby walks behind its mother: on her left when they face right, on her right
# when they face left.
expect
	pairs.all(
		|pair| {
			{ left, right } = pair_billboards(pair)
			match pair.facing {
				FacesRight => left.scenery_height() == right.scenery_height().divided_by(2.0)
				FacesLeft => right.scenery_height() == left.scenery_height().divided_by(2.0)
			}
		},
	)

## The mean x on the canvas of every corner of the billboard drawn by `shapes`,
## which leans toward the side its emoji has more of.
mean_corner_x : List(Shapes.Shape) -> F64
mean_corner_x = |shapes| {
	xs = canvas_corners(shapes).map(|corner| corner.x.to_f64())
	xs.sum() / xs.len().to_f64()
}

# A billboard facing right is drawn as the mirror of the one facing left, about
# the middle of where it stands, and the mirror shows: the elephant's corners
# lean well to one side of that middle.
expect {
	species = BendAnimal.Elephant.species_of()
	placed_facing = |facing| {
		billboard = Billboard.adult_billboard(species, facing)
		placed_billboard({ billboard, from_left_edge: Distance.zero })
	}
	slope = placed_facing(FacesLeft).road_point.across.to_metres() / row_forward.to_metres()
	middle = Lens.x_for_slope({
		slope,
		focal_length: camera.focal_length,
	}).to_f64() * canvas_per_screen
	facing_right = mean_corner_x(placed_billboard_shapes(placed_facing(FacesRight)))
	facing_left = mean_corner_x(placed_billboard_shapes(placed_facing(FacesLeft)))
	(facing_right + facing_left - 2.0 * middle).abs() <= 0.000001 and facing_right - middle > 1.0
}

# The billboards stand in order from left to right without touching, and the
# gap between pairs is plainly wider than the gap inside one.
expect {
	gaps = extents.map2(extents.drop_first(1), |reach, next| next.left - reach.right)
	match gaps {
		[
			in_elephant,
			between_one,
			in_giraffe,
			between_two,
			in_zebra,
			between_three,
			in_rhino,
		] => {
			insides = [in_elephant, in_giraffe, in_zebra, in_rhino]
			betweens = [between_one, between_two, between_three]
			match (insides.min(), insides.max(), betweens.min()) {
				(
					Ok(inside_least),
					Ok(inside_most),
					Ok(between_least),
				) =>
					inside_least > 0.0 and between_least > 1.5 * inside_most
				_ => False
			}
		}
		_ => False
	}
}

# Every baby is drawn half as tall as its mother, and every billboard stands on
# one line of grass, to a twentieth of a pixel.
expect {
	heights = extents.map(|reach| reach.bottom - reach.top)
	is_half_of = |young, adult| (young - adult / 2.0).abs() <= 0.05
	feet = extents.map(|reach| reach.bottom)
	is_one_line = feet.all(|bottom| feet.all(|other| (bottom - other).abs() <= 0.05))
	match heights {
		[
			elephant_calf,
			elephant,
			giraffe_calf,
			giraffe,
			zebra,
			zebra_foal,
			rhino,
			rhino_calf,
		] =>
			is_one_line
				and is_half_of(elephant_calf, elephant)
				and is_half_of(giraffe_calf, giraffe)
				and is_half_of(zebra_foal, zebra)
				and is_half_of(rhino_calf, rhino)
		_ => False
	}
}

# The picture is the backdrop and the eight billboards, and nothing else.
expect
	picture_shapes
		== Shapes.lists_in_space(
			row_space,
			[FrameView.backdrop_shapes(backdrop)].concat(billboard_shape_lists),
		)
